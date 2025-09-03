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
#include <ftw.h>
#include <miniz.h>
#include <regex.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>


/***********************************************************************************
 * Function Name      : so_visitor
 * Inputs             : fpath (const char *)  - Path of the current file
 *                      sb (const struct stat *) - File status
 *                      typeflag (int)        - Type of the file (FTW_F, FTW_D, etc.)
 *                      ftwbuf (struct FTW *) - Additional info from nftw
 * Returns            : int (0 to continue, non-zero to stop traversal)
 * Description        : nftw() callback used to scan .so files in directories.
 *                      Matches library filenames against GAME_LIB patterns and
 *                      preloads valid entries while avoiding duplicates.
 * Notes              :
 *   - Called automatically by nftw() during directory traversal.
 *   - Only processes files ending with ".so".
 *   - Skips already processed entries listed in PROCESSED_FILE_LIST.
 ***********************************************************************************/
int so_visitor(const char* fpath, const struct stat* sb, int typeflag, struct FTW* ftwbuf) {
    (void)sb;
    (void)ftwbuf;

    if (typeflag == FTW_F && strstr(fpath, ".so")) {
        if (!is_processed(fpath) && regexec(&g_regex, fpath, 0, NULL, 0) == 0) {
            char cmd[600];
            snprintf(cmd, sizeof(cmd), "sys.azenith-preloadbin -dL \"%s\"", fpath);
            if (systemv(cmd) == 0) {
                add_processed(fpath);
                log_preload(LOG_INFO, "Preloaded native: %s", fpath);
            }
        }
    }
    return 0;
}

/***********************************************************************************
 * Function Name      : scan_split_apk
 * Inputs             : apk_file (const char *) - Path to the APK file
 * Returns            : void
 * Description        : Opens the APK (ZIP) with miniz, iterates over all entries,
 *                      and checks for .so libraries. Matches against GAME_LIB regex,
 *                      and preloads valid shared libraries.
 * Notes              :
 *   - Avoids libzip/unzip external dependencies.
 *   - Uses in-memory buffer for reading .so entries.
 *   - Spawns preload binary through a pipe.
 ***********************************************************************************/
void scan_split_apk(const char* apk_file) {
    mz_zip_archive zip;
    memset(&zip, 0, sizeof(zip));

    if (!mz_zip_reader_init_file(&zip, apk_file, 0)) {
        fprintf(stderr, "Failed to open APK: %s\n", apk_file);
        return;
    }

    int num_files = (int)mz_zip_reader_get_num_files(&zip);
    for (int i = 0; i < num_files; i++) {
        mz_zip_archive_file_stat st;
        if (!mz_zip_reader_file_stat(&zip, i, &st))
            continue;

        const char* name = st.m_filename;
        if (!name || !strstr(name, ".so"))
            continue;

        size_t size = 0;
        void* buf = mz_zip_reader_extract_to_heap(&zip, i, &size, 0);
        if (!buf)
            continue;

        // Regex match on path or file contents
        bool match = (regexec(&g_regex, name, 0, NULL, 0) == 0);
        if (!match) {
            if (regexec(&g_regex, buf, 0, NULL, 0) == 0)
                match = true;
        }

        if (match) {
            int fds[2];
            if (pipe(fds) == 0) {
                pid_t pid = fork();
                if (pid == 0) {
                    dup2(fds[0], STDIN_FILENO);
                    close(fds[0]);
                    close(fds[1]);
                    execlp("sys.azenith-preloadbin2", "sys.azenith-preloadbin2", "-dL", "-", NULL);
                    _exit(1);
                } else if (pid > 0) {
                    close(fds[0]);
                    write(fds[1], buf, size);
                    close(fds[1]);
                    waitpid(pid, NULL, 0);
                    printf("Preloaded Game libs %s -> %s\n", apk_file, name);
                }
            }
        }

        mz_free(buf);
    }

    mz_zip_reader_end(&zip);
}

/***********************************************************************************
 * Function Name      : GamePreload
 * Inputs             : const char* package - target application package name
 * Returns            : void
 * Description        : Preloads running games native libraries (.so) into memory to
 *                      optimize performance and reduce runtime loading overhead.
 *
 *                      Workflow:
 *                      1. Resolves the APK installation path for the given package.
 *                      2. Searches for native libraries in the app's `lib/arm64`
 *                         directory, filters them using regex (GAME_LIB), and preloads
 *                         via `sys.azenith-preloadbin`.
 *                      3. Maintains a processed file list to avoid redundant preloading.
 *                      4. Handles split APKs:
 *                          - Scans embedded `.so` files inside split APKs using unzip.
 *                          - Matches libraries via regex or string scan.
 *                          - Streams matching libs directly into
 *                            `sys.azenith-preloadbin2` for preloading.
 *
 *                      This ensures that critical GPU/engine-related libraries are
 *                      loaded into memory before gameplay begins, minimizing stutter
 *                      and improving frame consistency.
 *
 * Note               : - Uses systemv() for executing preload commands.
 *                      - Maintains `PROCESSED_FILE_LIST` to prevent duplicate loads.
 *                      - Regex expression GAME_LIB defines which libs are considered for preloading.
 ***********************************************************************************/
void GamePreload(const char* package) {
    if (!package || strlen(package) == 0) {
        log_preload(LOG_WARN, "Package is null or empty");
        return;
    }

    // Get apk base path (via cmd tool, minimal parsing)
    char apk_path[256] = {0};
    {
        char cmd[256];
        snprintf(cmd, sizeof(cmd), "cmd package path %s", package);
        FILE* pipe = popen(cmd, "r");
        if (!pipe || !fgets(apk_path, sizeof(apk_path), pipe)) {
            log_preload(LOG_WARN, "Failed to get apk path for %s", package);
            if (pipe)
                pclose(pipe);
            return;
        }
        pclose(pipe);
        apk_path[strcspn(apk_path, "\n")] = 0;

        char* colon = strchr(apk_path, ':');
        if (colon)
            memmove(apk_path, colon + 1, strlen(colon));
    }

    // Chop to base dir
    char* last_slash = strrchr(apk_path, '/');
    if (!last_slash)
        return;
    *last_slash = '\0';

    // Open processed list (append+read like old version)
    FILE* processed = fopen(PROCESSED_FILE_LIST, "a+");
    if (!processed) {
        log_preload(LOG_ERROR, "Cannot open processed file list");
        return;
    }

    // Compile regex
    regex_t regex;
    if (regcomp(&regex, GAME_LIB, REG_EXTENDED | REG_NOSUB) != 0) {
        log_preload(LOG_ERROR, "Regex compile failed");
        fclose(processed);
        return;
    }

    // Scan lib/arm64 with nftw
    char lib_path[300];
    snprintf(lib_path, sizeof(lib_path), "%s/lib/arm64", apk_path);
    if (access(lib_path, F_OK) == 0) {
        nftw(lib_path, so_visitor, 10, FTW_PHYS);
    }

    // Scan split APKs with libzip
    DIR* d = opendir(apk_path);
    if (d) {
        struct dirent* de;
        while ((de = readdir(d))) {
            if (strstr(de->d_name, ".apk")) {
                char full_apk[512];
                snprintf(full_apk, sizeof(full_apk), "%s/%s", apk_path, de->d_name);
                scan_split_apk(full_apk);
            }
        }
        closedir(d);
    }

    // Cleanup
    regfree(&regex);
    fclose(processed);

    return 0;
}
