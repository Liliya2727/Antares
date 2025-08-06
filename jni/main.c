/*
 * Copyright (C) 2024-2025 Rem01Gaming
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <AZenith.h>
#include <libgen.h>

unsigned int LOOP_INTERVAL = 15;

void start_preload_if_needed(const char* pkg, unsigned int* LOOP_INTERVAL) {
    if (!pkg)
        return;

    FILE* fp = fopen(PRELOAD_ENABLED, "r");
    if (fp) {
        char val = fgetc(fp);
        fclose(fp);

        if (val == '1') {

            // Fork the preload task to run in a separate process
            pid_t pid = fork();
            if (pid == 0) {
                // In the child process
                GamePreload(pkg); // Run the preload logic in the background
                _exit(0);         // Ensure the child exits cleanly without affecting the parent
            } else if (pid > 0) {
                // In the parent process
                *LOOP_INTERVAL = 35; // Increase the loop interval for performance profile
                preload_active = true;
            } else {
                // Fork failed
                log_zenith(LOG_ERROR, "Failed to fork process for GamePreload");
            }
        } else {
            *LOOP_INTERVAL = 15; // Reset the loop interval if preload is disabled
            preload_active = false;
        }
    }
}

void stop_preload_if_active(unsigned int* LOOP_INTERVAL) {
    if (preload_active) {
        cleanup();
        preload_active = false;
        *LOOP_INTERVAL = 15; // reset
    }
}

void startpr(const char* pkg) {
    if (!pkg)
        return;

    FILE* fp = fopen(PRELOAD_ENABLED, "r");
    if (fp) {
        char val = fgetc(fp);
        fclose(fp);

        if (val == '1') {
            log_zenith(LOG_INFO, "Start Preloading game package %s", pkg);
        }
    }
}

char* gamestart = NULL;
pid_t game_pid = 0;

int main(int argc, char* argv[]) {
    // Handle case when not running on root
    if (getuid() != 0) {
        fprintf(stderr, "\033[31mERROR:\033[0m Please run this program as root\n");
        exit(EXIT_FAILURE);
    }

    // Expose logging interface for other modules
    char* base_name = basename(argv[0]);
    if (strcmp(base_name, "AZenith_log") == 0) {
        if (argc < 3) {
            fprintf(stderr, "Usage: AZenith_log <TAG> <LEVEL> <MESSAGE>\n");
            fprintf(stderr, "Levels: 0=DEBUG, 1=INFO, 2=WARN, 3=ERROR, 4=FATAL\n");
            return EXIT_FAILURE;
        }

        // Parse log level
        int level = atoi(argv[2]);
        if (level < LOG_DEBUG || level > LOG_FATAL) {
            fprintf(stderr, "Invalid log level. Use 0-4.\n");
            return EXIT_FAILURE;
        }

        // Combine message arguments
        size_t message_len = 0;
        for (int i = 3; i < argc; i++) {
            message_len += strlen(argv[i]) + 1;
        }

        char message[message_len];
        message[0] = '\0';

        for (int i = 3; i < argc; i++) {
            strcat(message, argv[i]);
            if (i < argc - 1)
                strcat(message, " ");
        }

        external_log(level, argv[1], message);
        return EXIT_SUCCESS;
    }

    // Make sure only one instance is running
    if (create_lock_file() != 0) {
        fprintf(stderr, "\033[31mERROR:\033[0m Another instance of Daemon is already running!\n");
        exit(EXIT_FAILURE);
    }

    // Handle case when module modified by 3rd party
    is_kanged();

    // Daemonize service
    if (daemon(0, 0)) {
        log_zenith(LOG_FATAL, "Unable to daemonize service");
        exit(EXIT_FAILURE);
    }

    // Register signal handlers
    signal(SIGINT, sighandler);
    signal(SIGTERM, sighandler);

    // Initialize variables
    bool need_profile_checkup = false;
    MLBBState mlbb_is_running = MLBB_NOT_RUNNING;
    ProfileMode cur_mode = PERFCOMMON;

    log_zenith(LOG_INFO, "Daemon started as PID %d", getpid());
    notify("Initializing...");
    run_profiler(PERFCOMMON); // exec perfcommon
    static bool did_notify_start = false;

    // Cleanup VMT before initiate it Again
    cleanup_vmt(); // kill any leftover preload processes

    while (1) {
        sleep(LOOP_INTERVAL);

        // Handle case when module gets updated
        if (access(MODULE_UPDATE, F_OK) == 0) [[clang::unlikely]] {
            log_zenith(LOG_INFO, "Module update detected, exiting.");
            notify("Please reboot your device to complete module update.");
            break;
        }

        // Only fetch gamestart when user not in-game
        // prevent overhead from dumpsys commands.
        if (!gamestart) {
            gamestart = get_gamestart();
        } else if (game_pid != 0 && kill(game_pid, 0) == -1) [[clang::unlikely]] {
            log_zenith(LOG_INFO, "Game %s exited, resetting profile...", gamestart);
            stop_preload_if_active(&LOOP_INTERVAL);
            game_pid = 0;
            free(gamestart);
            gamestart = get_gamestart();

            // Force profile recheck to make sure new game session get boosted
            need_profile_checkup = true;
        }

        if (gamestart)
            mlbb_is_running = handle_mlbb(gamestart);

        if (gamestart && get_screenstate() && mlbb_is_running != MLBB_RUN_BG) {
            // Bail out if we already on performance profile
            start_preload_if_needed(gamestart, &LOOP_INTERVAL);
            if (!need_profile_checkup && cur_mode == PERFORMANCE_PROFILE)
                continue;

            // Get PID and check if the game is "real" running program
            // Handle weird behavior of MLBB
            game_pid = (mlbb_is_running == MLBB_RUNNING) ? mlbb_pid : pidof(gamestart);
            if (game_pid == 0) [[clang::unlikely]] {
                log_zenith(LOG_ERROR, "Unable to fetch PID of %s", gamestart);
                free(gamestart);
                gamestart = NULL;
                continue;
            }

            cur_mode = PERFORMANCE_PROFILE;
            need_profile_checkup = false;
            log_zenith(LOG_INFO, "Applying performance profile for %s", gamestart);
            toast("Applying Performance Profile");
            run_profiler(PERFORMANCE_PROFILE);
            set_priority(game_pid);
            startpr(gamestart);
        } else if (get_low_power_state()) {
            // Bail out if we already on powersave profile
            if (cur_mode == ECO_MODE)
                continue;

            cur_mode = ECO_MODE;
            need_profile_checkup = false;
            log_zenith(LOG_INFO, "Applying ECO Mode");
            toast("Applying Eco Mode");
            run_profiler(ECO_MODE);
        } else {
            // Bail out if we already on normal profile
            if (cur_mode == BALANCED_PROFILE)
                continue;

            cur_mode = BALANCED_PROFILE;
            need_profile_checkup = false;
            log_zenith(LOG_INFO, "Applying Balanced profile");
            toast("Applying Balanced profile");
            if (!did_notify_start) {
                notify("AZenith is running successfully");
                did_notify_start = true;
            }
            run_profiler(BALANCED_PROFILE);
        }
    }

    return 0;
}
