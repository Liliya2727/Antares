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
#include <errno.h>
#include <fcntl.h>
#include <regex.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>


/***********************************************************************************
 * Function Name      : GamePreload
 * Inputs             : const char* package - target application package name
 * Returns            : void
 * Description        : Preloads all native libraries (.so) inside lib/arm64
 ***********************************************************************************/
void GamePreload(const char *package) {
    if (!package || strlen(package) == 0) {
        log_preload(LOG_WARN, "Package is null or empty");
        return;
    }
    
    char apk_path[256] = {0};
    char cmd_apk[512];
    snprintf(cmd_apk, sizeof(cmd_apk),
             "cmd package path %s | head -n1 | cut -d: -f2", package);
    FILE *apk = popen(cmd_apk, "r");
    if (!apk || !fgets(apk_path, sizeof(apk_path), apk)) {
        log_preload(LOG_ERROR, "Failed to get APK path");
        if (apk) pclose(apk);
        return;
    }
    
    pclose(apk);
    apk_path[strcspn(apk_path, "\n")] = 0;
    char *base_path = strdup(apk_path);
    char *slash = strrchr(base_path, '/');
    if (slash) *slash = '\0';
    char lib_path[300];
    snprintf(lib_path, sizeof(lib_path), "%s/lib/arm64", base_path);
    if (access(lib_path, F_OK) != 0) {
        log_zenith(LOG_WARN, "Directory %s does not exist — skipping preload", lib_path);
        free(base_path);
        return;
    }
    
    bool found_so = false;
    DIR *dir = opendir(lib_path);
    if (dir) {
        struct dirent *entry;
        while ((entry = readdir(dir)) != NULL) {
            if (strstr(entry->d_name, ".so")) {
                found_so = true;
                break;
            }
        }
        closedir(dir);
    }
    
    if (!found_so) {
        log_zenith(LOG_WARN, "No .so libraries found in %s — skipping preload", lib_path);
        free(base_path);
        return;
    }
    
    char cmd[600];
    snprintf(cmd, sizeof(cmd),
            "sys.azenith-preloadbin -mt 500M \"%s\"/*", lib_path);
    log_preload(LOG_INFO, "Preloading libs : \"%s\"/*", lib_path);
    int ret = system(cmd);
    if (ret != 0) {
        log_zenith(LOG_ERROR, "Preload failed for %s", package);
    }
    
    free(base_path);
}
