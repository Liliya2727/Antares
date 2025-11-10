/*
 * Copyright (C) 2024-2025 Zexshia
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

/************************************************************
 * Function Name   : get_visible_package
 *
 * Description       : Reads "dumpsys window displays" and extracts the
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
        line[strcspn(line, "\n")] = 0;
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
                        break;
                    }
                }
            }
            last_task_line[0] = 0; // reset task line
        }
    }
    pclose(fp);
    if (pkg[0] == '\0') {
        return NULL;
    }
    return strdup(pkg); // caller must free
}

/************************************************************
 * Function Name   : get_recent_package
 *
 * Description       : Reads "dumpsys activity activities" and extracts the
 *                      package name of the currently visible (recent) app.
 *
 * Returns.          : Returns a malloc()'d string containing the package name,
 *                     or NULL if none is found. Caller must free().
 ************************************************************/
bool get_recent_package(const char* gamestart) {
    if (!gamestart) return false;

    FILE *fp = popen("dumpsys activity activities", "r");
    if (!fp) {
        log_zenith(LOG_ERROR, "Failed to run dumpsys activity activities");
        return false;
    }

    char line[MAX_LINE];
    bool in_task_section = false;

    while (fgets(line, sizeof(line), fp)) {
        line[strcspn(line, "\n")] = 0;

        // Start parsing after "Run #"
        if (!in_task_section && strstr(line, "Run #")) {
            in_task_section = true;
            continue;
        }
        if (!in_task_section) continue;

        // End of relevant section
        if (strlen(line) == 0) break;

        // Look for package name
        char *pkg_pos = strstr(line, gamestart);
        if (pkg_pos) {
            // Check if task is not finishing or destroyed
            if (!strstr(line, "finishing=true") && !strstr(line, "state=DESTROYED")) {
                pclose(fp);
                return true;
            }
        }
    }

    pclose(fp);
    return false;
}
