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

    // Resolve APK path
    char apk_path[256] = {0};
    char cmd_apk[512];
    snprintf(cmd_apk, sizeof(cmd_apk), "cmd package path %s | head -n1 | cut -d: -f2", package);
    FILE *apk = popen(cmd_apk, "r");
    if (!apk || !fgets(apk_path, sizeof(apk_path), apk)) {
        log_preload(LOG_WARN, "Failed to get apk path for %s", package);
        if (apk) pclose(apk);
        return;
    }
    pclose(apk);
    apk_path[strcspn(apk_path, "\n")] = 0;

    // ==== lib path preload (vmt -dL /path/to/lib.so) ====
    char *last_slash = strrchr(apk_path, '/');
    if (!last_slash) return;
    *last_slash = '\0';

    char lib_path[300];
    snprintf(lib_path, sizeof(lib_path), "%s/lib/arm64", apk_path);
    bool lib_found = access(lib_path, F_OK) == 0;

    if (lib_found) {
        char find_cmd[512];
        snprintf(find_cmd, sizeof(find_cmd), "find %s -type f -name '*.so' 2>/dev/null", lib_path);
        FILE *pipe = popen(find_cmd, "r");
        if (pipe) {
            char lib[512];
            while (fgets(lib, sizeof(lib), pipe)) {
                lib[strcspn(lib, "\n")] = 0;

                // Preload the .so file
                char preload_cmd[600];
                snprintf(preload_cmd, sizeof(preload_cmd), "sys.azenith-preloadbin -mt 500M \"%s\"", lib);
                if (systemv(preload_cmd) == 0) {
                    log_preload(LOG_INFO, "Preloaded native: %s", lib);
                }
            }
            pclose(pipe);
        }
    }
}
