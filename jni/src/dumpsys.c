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
        log_zenith(LOG_INFO, "Failed to run dumpsys window displays");
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
static bool extract_and_compare(const char *line, const char *start_token, const char *gamestart) {
    const char *token_pos = strstr(line, start_token);
    if (!token_pos) {
        return false; // Token not found
    }

    // Move the pointer past the token itself
    token_pos += strlen(start_token);

    // Handle the UID:package format (like "A=10123:com.example")
    const char *colon = strchr(token_pos, ':');
    if (colon && (colon - token_pos < 10)) { // Check if colon is close (likely a UID)
        token_pos = colon + 1; // Skip the UID and colon
    }

    // Now, extract the package name
    char pkg[MAX_PACKAGE] = {0};
    size_t i = 0;
    
    // Package names stop at a '/' (for activity), a ' ' (space), or end of line
    while (token_pos[i] != '/' && token_pos[i] != ' ' && token_pos[i] != '\0' && i < MAX_PACKAGE - 1) {
        pkg[i] = token_pos[i];
        i++;
    }
    pkg[i] = '\0'; // Null terminate

    // Check if we extracted anything and if it matches
    if (i > 0 && strcmp(pkg, gamestart) == 0) {
        return true;
    }
    
    return false;
}

bool get_recent_package(const char* gamestart) {
    if (!gamestart) {
        return false;
    }

    FILE *fp = popen("dumpsys activity recents", "r");
    if (!fp) {
        // log_zenith(LOG_INFO, "Failed to run dumpsys activity recents");
        perror("popen failed"); // Using perror for system call failures is good
        return false;
    }

    char line[MAX_LINE];
    bool found = false;

    // List of tokens to search for. Most specific (realActivity) first.
    const char *tokens[] = {
        "realActivity=", // Common on modern Android
        "baseActivity=", // Common on older Android
        "A=",            // Your original check
        "app="           // Another possible variant
    };
    int num_tokens = sizeof(tokens) / sizeof(tokens[0]);

    while (fgets(line, sizeof(line), fp)) {
        // We only care about lines that might contain activity info
        // Your "* Recent #" check is good, but let's also check for "Task{"
        // as a fallback, since the line prefix can also change.
        if (strncmp(line, "* Recent #", 10) != 0 && !strstr(line, "Task{")) {
            continue;
        }

        // Try to find the package using any of our known tokens
        for (int i = 0; i < num_tokens; i++) {
            if (extract_and_compare(line, tokens[i], gamestart)) {
                found = true;
                break; // Found it, no need to check other tokens on this line
            }
        }

        if (found) {
            break; // Found it, no need to read more lines
        }
    }

    pclose(fp);
    return found;
}

