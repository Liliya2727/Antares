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
#include <sys/system_properties.h>

/***********************************************************************************
 * Function Name      : GamePreload
 * Inputs             : const char* package - target application package name
 * Returns            : void
 * Description        : Preloads all native libraries (.so) inside lib/arm64
 ***********************************************************************************/
void GamePreload(const char *package) {
    if (!package || strlen(package) == 0) {
        log_zenith(LOG_WARN, "Package is null or empty");
        return;
    }

    char apk_path[256] = {0};
    char cmd_apk[512];
    snprintf(cmd_apk, sizeof(cmd_apk),
             "cmd package path %s | head -n1 | cut -d: -f2", package);

    FILE *apk = popen(cmd_apk, "r");
    if (!apk || !fgets(apk_path, sizeof(apk_path), apk)) {
        log_zenith(LOG_WARN, "Failed to get APK path for %s", package);
        if (apk) pclose(apk);
        return;
    }
    pclose(apk);
    apk_path[strcspn(apk_path, "\n")] = 0;

    char *last_slash = strrchr(apk_path, '/');
    if (!last_slash) {
        log_zenith(LOG_WARN, "Failed to determine APK folder from path: %s", apk_path);
        return;
    }
    *last_slash = '\0';

    char lib_path[300];
    snprintf(lib_path, sizeof(lib_path), "%s", apk_path);

    if (access(lib_path, F_OK) != 0) {
        log_zenith(LOG_WARN, "Library path does not exist: %s", lib_path);
        return;
    }

    char budget[32] = {0};
    __system_property_get("persist.sys.azenithconf.preloadbudget", budget);
    if (strlen(budget) == 0) {
        strcpy(budget, "500M"); // default
    }

    char preload_cmd[512];
    snprintf(preload_cmd, sizeof(preload_cmd),
             "sys.azenith-preloadbin -v -t -m %s \"%s/lib/arm64\"", budget, lib_path);

    FILE *fp = popen(preload_cmd, "r");
    if (!fp) {
        log_zenith(LOG_WARN, "Failed to run preloadbin for %s", package);
        return;
    }
    
    log_zenith(LOG_INFO, "Preloading game %s", package);
    log_preload(LOG_INFO, "Preloading libs %s/lib/arm64 with budget %s", lib_path, budget);
    
    char line[1024];
    int total_pages = 0;
    char total_size[32] = {0};
    
    while (fgets(line, sizeof(line), fp)) {
        line[strcspn(line, "\n")] = 0; // remove newline
    
        log_preload(LOG_DEBUG, "[PRELOAD OUTPUT] %s", line); // verbose output of preloadbin
    
        char *p_pages = strstr(line, "Touched Pages:");
        if (p_pages) {
            int pages = 0;
            char size[32] = {0};
    
            if (sscanf(p_pages, "Touched Pages: %d (%31[^)])", &pages, size) == 2) {
                total_pages += pages;
                strncpy(total_size, size, sizeof(total_size) - 1);
    
                log_zenith(LOG_DEBUG, "Preloading complete: %d memory pages touched", pages);
                log_zenith(LOG_DEBUG, "Total memory used for preloaded libraries: %s", size);
            } else {
                log_zenith(LOG_WARN, "Failed to parse Touched Pages");
            }
        }
    
        // Optional: log each library loaded if sys.azenith-preloadbin prints paths
        if (strstr(line, ".so")) {
            log_preload(LOG_DEBUG, "Library touched: %s", line);
        }
    }
    
    log_preload(LOG_INFO, "Game %s preloaded all libs: total %d pages touched (~%s)", package, total_pages, total_size);
    
    pclose(fp);
}
