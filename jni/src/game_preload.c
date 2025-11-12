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

    // Determine lib path
    char lib_path[300];
    snprintf(lib_path, sizeof(lib_path), "%s/lib/arm64", apk_path);
    bool lib_exists = access(lib_path, F_OK) == 0;

    // Check preload splits property
    char preload_splits[PROP_VALUE_MAX] = {0};
    __system_property_get("persist.sys.azenithconf.preloadsplitsapk", preload_splits);
    bool splits_enabled = (strcmp(preload_splits, "true") == 0);

    char budget[32] = {0};
    __system_property_get("persist.sys.azenithconf.preloadbudget", budget);
    if (strlen(budget) == 0) strcpy(budget, "500M");
    
    FILE *fp = NULL;

    if (lib_exists && splits_enabled) {
        // Preload both .so and splits APKs
        char preload_cmd[512];
        snprintf(preload_cmd, sizeof(preload_cmd),
                 "sys.azenith-preloadbin -v -t -m %s \"%s\"", budget, lib_path);
        fp = popen(preload_cmd, "r");
        log_zenith(LOG_INFO, "Preloading .so libs %s with budget %s", lib_path, budget);
        // handle logging here...
        pclose(fp);

        snprintf(preload_cmd, sizeof(preload_cmd),
                 "sys.azenith-preloadbin -v -t -m %s \"%s\"", budget, apk_path);
        fp = popen(preload_cmd, "r");
        log_zenith(LOG_INFO, "Preloading split APKs %s with budget %s", apk_path, budget);
    } else if (lib_exists) {
        char preload_cmd[512];
        snprintf(preload_cmd, sizeof(preload_cmd),
                 "sys.azenith-preloadbin -v -t -m %s \"%s\"", budget, lib_path);
        fp = popen(preload_cmd, "r");
        log_zenith(LOG_INFO, "Preloading .so libs %s with budget %s", lib_path, budget);
    } else {
        // fallback to split APKs only
        char preload_cmd[512];
        snprintf(preload_cmd, sizeof(preload_cmd),
                 "sys.azenith-preloadbin -v -t -m %s \"%s\"", budget, apk_path);
        fp = popen(preload_cmd, "r");
        log_zenith(LOG_INFO, "Preloading split APKs %s with budget %s", apk_path, budget);
    }

    if (!fp) {
        log_zenith(LOG_WARN, "Failed to run preloadbin for %s", package);
        return;
    }

    // Now parse the output
    char line[1024];
    int total_pages = 0;
    char total_size[32] = {0};

    while (fgets(line, sizeof(line), fp)) {
        line[strcspn(line, "\n")] = 0; // remove newline

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

        if (strstr(line, ".so") || strstr(line, ".apk") || strstr(line, ".dm") || strstr(line, ".art") || strstr(line, ".odex") || strstr(line, ".vdex")) {
            log_preload(LOG_DEBUG, "Library touched: %s", line);
        }
    }

    log_preload(LOG_INFO, "Game %s preloaded all libs: total %d pages touched (~%s)",
                package, total_pages, total_size);

    pclose(fp);
}
