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

bool (*get_screenstate)(void) = get_screenstate_normal;
bool (*get_low_power_state)(void) = get_low_power_state_normal;

/***********************************************************************************
 * Function Name      : run_profiler
 * Inputs             : int - 0 for perfcommon
 *                            1 for performance
 *                            2 for normal
 *                            3 for powersave
 * Returns            : None
 * Description        : Switch to specified performance profile.
 ***********************************************************************************/
void run_profiler(const int profile) {
    is_kanged();

    if (profile == 1) {
        write2file(GAME_INFO, false, false, "%s %d %d\n", gamestart, game_pid, uidof(game_pid));
    } else {
        write2file(GAME_INFO, false, false, "NULL 0 0\n");
    }

    write2file(PROFILE_MODE, false, false, "%d\n", profile);
    (void)systemv("sys.azenith-profilesettings %d", profile);
}

/************************************************************
 * Function Name   : get_visible_package
 *
 * Description       : Reads "dumpsys activity activities" and extracts the
 *                      package name of the currently visible (foreground) app.
 *
 * Returns.          : Returns a malloc()'d string containing the package name,
 *                     or NULL if none is found. Caller must free().
 ************************************************************/
char* get_visible_package(void) {
    FILE *fp = popen("dumpsys window displays", "r");
    if (!fp) {
        log_zenith(0, "Failed to run dumpsys window displays");
        return NULL;
    }

    char line[MAX_LINE];
    char last_task_line[MAX_LINE] = {0};
    char pkg[MAX_PACKAGE] = {0};
    bool in_task_section = false;
    while (fgets(line, sizeof(line), fp)) {
        line[strcspn(line, "\n")] = 0; // remove newline
        if (!in_task_section && strstr(line, "Application tokens in top down Z order:")) {
            in_task_section = true;
            continue;
        }
        if (!in_task_section) continue;
        if (strlen(line) == 0) break;
        // Save last task line
        if (strstr(line, "* Task{") && strstr(line, "type=standard")) {
            strcpy(last_task_line, line);
            continue;
        }
        // Look for activity under the last task
        if (strstr(line, "* ActivityRecord{") && last_task_line[0] != '\0') {
            bool visible = strstr(last_task_line, "visible=true") != NULL;
            if (visible) {
                // Extract package from ActivityRecord line
                char *u0 = strstr(line, " u0 ");
                if (u0) {
                    u0 += 4; // skip " u0 "
                    char *slash = strchr(u0, '/');
                    if (slash) {
                        size_t len = slash - u0;
                        if (len >= MAX_PACKAGE) len = MAX_PACKAGE - 1;
                        memcpy(pkg, u0, len);
                        pkg[len] = 0;
                        log_zenith(1, "Detected visible package: %s", pkg);
                        break;
                    }
                }
            }
            last_task_line[0] = 0; // reset task line
        }
    }
    pclose(fp);
    if (pkg[0] == '\0') {
        log_zenith(0, "No visible topActivity found");
        return NULL;
    }
    return strdup(pkg); // caller must free
}

/***********************************************************************************
 * Function Name      : get_gamestart
 * Inputs             : None
 * Returns            : char* (dynamically allocated string with the game package name)
 * Description        : Searches for the currently visible application that matches
 *                      any package name listed in gamelist.
 *                      This helps identify if a specific game is running in the foreground.
 *                      Uses dumpsys to retrieve visible apps and filters by packages
 *                      listed in Gamelist.
 * Note               : Caller is responsible for freeing the returned string.
 ***********************************************************************************/
char* get_gamestart(void) {
    char *pkg = get_visible_package();
    if (!pkg) return NULL;
    FILE *gf = fopen(GAMELIST, "r");
    if (!gf) {
        log_zenith(LOG_WARN, "Gamelist file not found: %s", GAMELIST);
        free(pkg);
        return NULL;
    }
    char entry[128];
    while (fgets(entry, sizeof(entry), gf)) {
        entry[strcspn(entry, "\n")] = 0;
        if (strcmp(entry, pkg) == 0) {
            log_zenith(1, "Game detected in foreground: %s", pkg);
            fclose(gf);
            return pkg; // caller must free
        }
    }
    log_zenith(LOG_INFO, "No matching game in foreground (current: %s)", pkg);
    fclose(gf);
    free(pkg);
    return NULL;
}

/***********************************************************************************
 * Function Name      : get_screenstate_normal
 * Inputs             : None
 * Returns            : bool - true if screen was awake
 *                             false if screen was asleep
 * Description        : Retrieves the current screen wakefulness state from dumpsys command.
 * Note               : In repeated failures up to 6, this function will skip fetch routine
 *                      and just return true all time using function pointer.
 *                      Never call this function, call get_screenstate() instead.
 ***********************************************************************************/
bool get_screenstate_normal(void) {
    static char fetch_failed = 0;

    char* screenstate = execute_command("dumpsys power | grep -Eo 'mWakefulness=Awake|mWakefulness=Asleep' "
                                        "| awk -F'=' '{print $2}'");

    if (screenstate) [[clang::likely]] {
        fetch_failed = 0;
        return IS_AWAKE(screenstate);
    }

    fetch_failed++;
    log_zenith(LOG_ERROR, "Unable to fetch current screenstate");

    if (fetch_failed == 6) {
        log_zenith(LOG_FATAL, "get_screenstate is out of order!");

        // Set default state after too many failures via function pointer
        get_screenstate = return_true;
    }

    return true;
}

/***********************************************************************************
 * Function Name      : get_low_power_state_normal
 * Inputs             : None
 * Returns            : bool - true if Battery Saver is enabled
 *                             false otherwise
 * Description        : Checks if the device's Battery Saver mode is enabled by using
 *                      global db or dumpsys power.
 * Note               : In repeated failures up to 6, this function will skip fetch routine
 *                      and just return false all time using function pointer.
 *                      Never call this function, call get_low_power_state() instead.
 ***********************************************************************************/
bool get_low_power_state_normal(void) {
    static char fetch_failed = 0;

    char* low_power = execute_direct("/system/bin/settings", "settings", "get", "global", "low_power", NULL);
    if (!low_power) {
        low_power = execute_command("dumpsys power | grep -Eo "
                                    "'mSettingBatterySaverEnabled=true|mSettingBatterySaverEnabled=false' | "
                                    "awk -F'=' '{print $2}'");
    }

    if (low_power) [[clang::likely]] {
        fetch_failed = 0;
        return IS_LOW_POWER(low_power);
    }

    fetch_failed++;
    log_zenith(LOG_ERROR, "Unable to fetch battery saver status");

    if (fetch_failed == 6) {
        log_zenith(LOG_FATAL, "get_low_power_state is out of order!");

        // Set default state after too many failures via function pointer
        get_low_power_state = return_false;
    }

    return false;
}
