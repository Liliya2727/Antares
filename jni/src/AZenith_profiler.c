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
    fseek(gf, 0, SEEK_END);
    long size = ftell(gf);
    rewind(gf);
    if (size <= 0) {
        fclose(gf);
        free(pkg);
        return NULL;
    }
    char *line = malloc(size + 1);
    if (!line) {
        fclose(gf);
        free(pkg);
        return NULL;
    }
    fread(line, 1, size, gf);
    fclose(gf);
    line[size] = '\0';
    char *token = strtok(line, "|");
    while (token) {
        if (strcmp(token, pkg) == 0) {
            free(line);
            return pkg;
        }
        token = strtok(NULL, "|");
    }
    free(line);
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

    char *output = execute_command("dumpsys power");
    if (!output) {
        goto fetch_fail;
    }
    char *p = strstr(output, "mWakefulness=");
    if (p) {
        p += strlen("mWakefulness=");

        char state[16] = {0};
        int i = 0;

        while (p[i] && p[i] != '\n' && i < 15) {
            state[i] = p[i];
            i++;
        }
        state[i] = 0;
        free(output);
        fetch_failed = 0;
        return IS_AWAKE(state);
    }

    free(output);
fetch_fail:
    fetch_failed++;
    log_zenith(LOG_ERROR, "Unable to fetch current screenstate");

    if (fetch_failed == 6) {
        log_zenith(LOG_FATAL, "get_screenstate is out of order!");
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

    // First try: settings get global low_power
    char *low_power = execute_direct("/system/bin/settings",
                                     "settings", "get", "global", "low_power", NULL);

    if (low_power) {
        // Trim whitespace/newlines
        char *p = low_power;
        while (*p == ' ' || *p == '\t') p++;
        for (int i = strlen(p) - 1; i >= 0 && (p[i] == '\n' || p[i] == '\r'); i--)
            p[i] = 0;

        fetch_failed = 0;
        return IS_LOW_POWER(p);
    }
    // Fallback: dumpsys power
    char *output = execute_command("dumpsys power");
    if (output) {
        char *p = strstr(output, "mSettingBatterySaverEnabled=");
        if (p) {
            p += strlen("mSettingBatterySaverEnabled=");
            char value[8] = {0};
            int i = 0;
            while (p[i] && p[i] != '\n' && i < 7) {
                value[i] = p[i];
                i++;
            }
            value[i] = 0;
            free(output);
            fetch_failed = 0;
            return IS_LOW_POWER(value);
        }
        free(output);
    }

    // Both failed
    fetch_failed++;
    log_zenith(LOG_ERROR, "Unable to fetch battery saver status");

    if (fetch_failed == 6) {
        log_zenith(LOG_FATAL, "get_low_power_state is out of order!");
        get_low_power_state = return_false;
    }

    return false;
}
