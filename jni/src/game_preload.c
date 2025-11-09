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
    {
        char cmd[256];
        snprintf(cmd, sizeof(cmd), "cmd package path %s 2>/dev/null", package);
        FILE *fp = popen(cmd, "r");
        if (!fp) return;

        if (fgets(apk_path, sizeof(apk_path), fp)) {
            char *pos = strstr(apk_path, ":/");
            if (pos) memmove(apk_path, pos + 1, strlen(pos));
        }
        pclose(fp);
    }
    apk_path[strcspn(apk_path, "\n")] = 0;
    if (apk_path[0] == 0) return;

    char *base_path = strdup(apk_path);
    if (!base_path) return;
    char *slash = strrchr(base_path, '/');
    if (slash) *slash = '\0';

    const char *abi_list[] = { "arm64-v8a", "arm64", NULL };
    char lib_path[300] = {0};
    bool abi_found = false;

    for (int i = 0; abi_list[i]; i++) {
        snprintf(lib_path, sizeof(lib_path), "%s/lib/%s", base_path, abi_list[i]);
        if (access(lib_path, F_OK) == 0) {
            log_preload(LOG_INFO, "ABI detected: %s", abi_list[i]);
            abi_found = true;
            break;
        }
    }

    if (!abi_found) {
        log_preload(LOG_WARN, "No ABI folder found under %s/lib", base_path);
        free(base_path);
        return;
    }

    DIR *dir = opendir(lib_path);
    if (!dir) {
        log_preload(LOG_WARN, "Cannot open directory %s", lib_path);
        free(base_path);
        return;
    }
    struct dirent *entry;
    bool found_so = false;
    char cmd[1200] = {0};
    snprintf(cmd, sizeof(cmd), "sys.azenith-preloadbin -mt 500M");
    while ((entry = readdir(dir)) != NULL) {
        if (strstr(entry->d_name, ".so")) {
            found_so = true;
            strncat(cmd, " ", sizeof(cmd) - strlen(cmd) - 1);
            strncat(cmd, lib_path, sizeof(cmd) - strlen(cmd) - 1);
            strncat(cmd, "/", sizeof(cmd) - strlen(cmd) - 1);
            strncat(cmd, entry->d_name, sizeof(cmd) - strlen(cmd) - 1);
        }
    }
    closedir(dir);
    if (!found_so) {
        log_preload(LOG_WARN, "No .so libraries found in %s — skipping preload", lib_path);
        free(base_path);
        return;
    }
    log_preload(LOG_INFO, "Preloading all .so in %s", lib_path);
    int ret = systemv("%s", cmd);
    if (ret != 0) {
        log_preload(LOG_ERROR, "Preload for %s failed with code %d", package, ret);
    }

    free(base_path);
}
