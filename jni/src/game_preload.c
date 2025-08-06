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

/*
 * Copyright (C) 2024-2025 Zexshia
 * Licensed under the Apache License, Version 2.0
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

void GamePreload(const char* package) {
    if (!package || strlen(package) == 0) {
        log_preload(LOG_WARN, "Package is null or empty");
        return;
    }

    FILE* ap = fopen(PRELOAD_ENABLED, "r");
    if (!ap) {
        log_preload(LOG_DEBUG, "GamePreload file not found");
        return;
    }
    char val = fgetc(ap);
    fclose(ap);
    if (val != '1') {
        log_preload(LOG_DEBUG, "Game Preload is disabled");
        return;
    }

    // Resolve APK path
    char apk_path[256] = {0};
    char cmd_apk[512];
    snprintf(cmd_apk, sizeof(cmd_apk), "cmd package path %s | head -n1 | cut -d: -f2", package);
    FILE* apk = popen(cmd_apk, "r");
    if (!apk || !fgets(apk_path, sizeof(apk_path), apk)) {
        log_preload(LOG_WARN, "Failed to get apk path for %s", package);
        if (apk)
            pclose(apk);
        return;
    }
    pclose(apk);
    apk_path[strcspn(apk_path, "\n")] = 0;

    // ==== lib path preload (vmt -dL /path/to/lib.so) ====
    char* last_slash = strrchr(apk_path, '/');
    if (!last_slash)
        return;
    *last_slash = '\0';

    char lib_path[300];
    snprintf(lib_path, sizeof(lib_path), "%s/lib/arm64", apk_path);
    bool lib_found = access(lib_path, F_OK) == 0;

    FILE* processed = fopen(PROCESSED_FILE_LIST, "a+");
    if (!processed) {
        log_preload(LOG_ERROR, "Cannot open processed file list");
        return;
    }

    regex_t regex;
    if (regcomp(&regex, GAME_LIB, REG_EXTENDED | REG_NOSUB) != 0) {
        log_preload(LOG_ERROR, "Regex compile failed");
        fclose(processed);
        return;
    }

    if (lib_found) {
        char find_cmd[512];
        snprintf(find_cmd, sizeof(find_cmd), "find %s -type f -name '*.so' 2>/dev/null", lib_path);
        FILE* pipe = popen(find_cmd, "r");
        if (pipe) {
            char lib[512];
            while (fgets(lib, sizeof(lib), pipe)) {
                lib[strcspn(lib, "\n")] = 0;

                // Check already processed
                rewind(processed);
                char check[512];
                bool already_done = false;
                while (fgets(check, sizeof(check), processed)) {
                    check[strcspn(check, "\n")] = 0;
                    if (strcmp(lib, check) == 0) {
                        already_done = true;
                        break;
                    }
                }
                if (already_done)
                    continue;

                if (regexec(&regex, lib, 0, NULL, 0) == 0) {
                    char preload_cmd[600];
                    snprintf(preload_cmd, sizeof(preload_cmd), "vmt -dL \"%s\"", lib);
                    if (systemv(preload_cmd) == 0) {
                        fprintf(processed, "%s\n", lib);
                        log_preload(LOG_INFO, "Preloaded native: %s", lib);
                    }
                }
            }
            pclose(pipe);
        }
    }

    // ==== split apk streaming preload (vmt -dL - via systemv) ====
    char split_cmd[512];
    snprintf(split_cmd, sizeof(split_cmd), "ls %s/*.apk 2>/dev/null", apk_path);
    FILE* apk_list = popen(split_cmd, "r");
    if (!apk_list) {
        log_preload(LOG_WARN, "Could not list split APKs");
        regfree(&regex);
        fclose(processed);
        return;
    }

    char apk_file[512];
    while (fgets(apk_file, sizeof(apk_file), apk_list)) {
        apk_file[strcspn(apk_file, "\n")] = 0;

        char list_cmd[600];
        snprintf(list_cmd, sizeof(list_cmd), "unzip -l \"%s\" | awk '{print $4}' | grep '\\.so$'", apk_file);
        FILE* liblist = popen(list_cmd, "r");
        if (!liblist)
            continue;

        char innerlib[512];
        while (fgets(innerlib, sizeof(innerlib), liblist)) {
            innerlib[strcspn(innerlib, "\n")] = 0;

            // Check match using strings/regex
            char check_cmd[768];
            snprintf(check_cmd, sizeof(check_cmd), "unzip -p \"%s\" \"%s\" | strings | grep -Eq \"%s\"", apk_file, innerlib, GAME_LIB);
            int match = system(check_cmd);
            bool match_regex = (regexec(&regex, innerlib, 0, NULL, 0) == 0);

            if (match == 0 || match_regex) {
                char cmd[1024];
                snprintf(cmd, sizeof(cmd), "unzip -p \"%s\" \"%s\" | vmt -dL -", apk_file, innerlib);
                if (systemv(cmd) == 0) {
                    log_preload(LOG_INFO, "Preloaded Game libs %s -> %s", apk_file, innerlib);
                }
            }
        }
        pclose(liblist);
    }

    pclose(apk_list);
    fclose(processed);
    regfree(&regex);
}
