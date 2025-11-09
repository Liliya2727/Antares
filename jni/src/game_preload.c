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
#define GPU_RENDER_REGEX "GPU|Render"
#define MAX_PROCESSED_FILES 512
#define MAX_PATH_LEN 512
static char processed_list[MAX_PROCESSED_FILES][MAX_PATH_LEN];
static int processed_count = 0;

/************************************************************************************
 * Function Name      : is_already_processed
 * Description        : Efficiently checks if a library is in our in-memory cache.
 ************************************************************************************/
bool is_already_processed(const char *lib_path) {
    for (int i = 0; i < processed_count; i++) {
        if (strcmp(processed_list[i], lib_path) == 0) {
            return true;
        }
    }
    return false;
}

/***********************************************************************************
 * Function Name      : GamePreload
 * Inputs             : const char* package - target application package name
 * Returns            : void
 * Description        : Preloads running games native libraries (.so) into memory
 ***********************************************************************************/
void GamePreload(const char *package) {
    if (!package || strlen(package) == 0) {
        log_preload(LOG_WARN, "Package is null or empty");
        return;
    }

    processed_count = 0;
    FILE *processed_file = fopen(PROCESSED_FILE_LIST, "r");
    if (processed_file) {
        while (processed_count < MAX_PROCESSED_FILES &&
               fgets(processed_list[processed_count], MAX_PATH_LEN, processed_file)) {
            processed_list[processed_count][strcspn(processed_list[processed_count], "\n")] = 0;
            processed_count++;
        }
        fclose(processed_file);
    }

    FILE *processed_out = fopen(PROCESSED_FILE_LIST, "a");
    if (!processed_out) {
        log_preload(LOG_ERROR, "Cannot open processed file list for writing");
        return;
    }

    regex_t game_lib_regex;
    if (regcomp(&game_lib_regex, GAME_LIB, REG_EXTENDED | REG_NOSUB | REG_ICASE) != 0) {
        log_preload(LOG_ERROR, "Game Lib Regex compile failed");
        fclose(processed_out);
        return;
    }

    char apk_path[256] = {0};
    char cmd_apk[512];
    snprintf(cmd_apk, sizeof(cmd_apk),
             "cmd package path %s | head -n1 | cut -d: -f2", package);

    FILE *apk = popen(cmd_apk, "r");
    if (!apk || !fgets(apk_path, sizeof(apk_path), apk)) {
        if (apk) pclose(apk);
        fclose(processed_out);
        regfree(&game_lib_regex);
        return;
    }
    pclose(apk);

    apk_path[strcspn(apk_path, "\n")] = 0;

    char *base_path = strdup(apk_path);
    char *last_slash = strrchr(base_path, '/');
    if (last_slash) *last_slash = '\0';

    char lib_path[300];
    snprintf(lib_path, sizeof(lib_path), "%s/lib/arm64", base_path);

    bool should_process_split = false;
    if (access(lib_path, F_OK) == 0) {
    
        bool found_any_so = false;
    
        char find_cmd[512];
        snprintf(find_cmd, sizeof(find_cmd),
                 "find \"%s\" -type f -name '*.so' 2>/dev/null", lib_path);
    
        FILE *pipe = popen(find_cmd, "r");
    
        if (pipe) {
            char lib[MAX_PATH_LEN];
    
            while (fgets(lib, sizeof(lib), pipe)) {
                found_any_so = true;
                lib[strcspn(lib, "\n")] = 0;
    
                if (is_already_processed(lib))
                    continue;
    
                bool filename_match =
                    (regexec(&game_lib_regex, lib, 0, NULL, 0) == 0);
    
                bool content_match = false;
    
                if (!filename_match) {
                    int ret = systemv("strings \"%s\" | grep -qE \"%s\"",
                                      lib, GPU_RENDER_REGEX);
                    if (ret == 0)
                        content_match = true;
                }
    
                if (filename_match || content_match) {
                    int ret = systemv("sys.azenith-preloadbin -dL \"%s\"", lib);
                    if (ret == 0) {
                        fprintf(processed_out, "%s\n", lib);
                        fflush(processed_out);
                    }
                }
            }
    
            pclose(pipe);
        }
    
        if (!found_any_so)
            should_process_split = true;
    
    } else {
        should_process_split = true;
    }
    
    if (should_process_split) {
    
        char split_cmd[512];
        snprintf(split_cmd, sizeof(split_cmd),
                 "ls \"%s\"/*.apk 2>/dev/null", base_path);
    
        FILE *apk_list = popen(split_cmd, "r");
        if (apk_list) {
            char apk_file[512];
    
            while (fgets(apk_file, sizeof(apk_file), apk_list)) {
                apk_file[strcspn(apk_file, "\n")] = 0;
    
                char list_cmd[600];
                snprintf(list_cmd, sizeof(list_cmd),
                         "unzip -l \"%s\" | awk '{print $4}' | grep '\\.so$'",
                         apk_file);
    
                FILE *liblist = popen(list_cmd, "r");
                if (!liblist) continue;
    
                char innerlib[512];
                while (fgets(innerlib, sizeof(innerlib), liblist)) {
    
                    innerlib[strcspn(innerlib, "\n")] = 0;
    
                    bool filename_match =
                        (regexec(&game_lib_regex, innerlib, 0, NULL, 0) == 0);
    
                    bool content_match = false;
    
                    if (!filename_match) {
                        int ret = systemv(
                            "unzip -p \"%s\" \"%s\" | strings | grep -qE \"%s\"",
                            apk_file, innerlib, GPU_RENDER_REGEX
                        );
                        if (ret == 0)
                            content_match = true;
                    }
    
                    if (filename_match || content_match) {
                        systemv(
                            "unzip -p \"%s\" \"%s\" | sys.azenith-preloadbin -dL -",
                            apk_file, innerlib
                        );
                    }
                }
    
                pclose(liblist);
            }
    
            pclose(apk_list);
        }
    }

    free(base_path);
    fclose(processed_out);
    regfree(&game_lib_regex);
}
