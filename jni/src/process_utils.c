/*
 * Copyright (C) 2024-2025 Rem01Gaming
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
 * Function Name      : pidof
 * Inputs             : name (char *) - Name of process
 * Returns            : pid (pid_t) - PID of process
 * Description        : Fetch PID from a process name.
 * Note               : You can input inexact process name.
 ***********************************************************************************/
pid_t pidof(const char *package_name) {
    if (!package_name) return 0;
    FILE *fp = popen("dumpsys activity top", "r");
    if (!fp) {
        fprintf(stderr, "popen failed: %s\n", strerror(errno));
        return 0;
    }
    char line[1024];
    pid_t pid = 0;
    while (fgets(line, sizeof(line), fp)) {
        if (strstr(line, "ACTIVITY") && strstr(line, package_name)) {
            char *pid_str = strstr(line, "pid=");
            if (pid_str) {
                pid_str += 4;
                char buf[16] = {0};
                size_t i = 0;
                while (isdigit((unsigned char)pid_str[i]) && i < sizeof(buf)-1) {
                    buf[i] = pid_str[i];
                    i++;
                }
                buf[i] = 0;
                pid = (pid_t)atoi(buf);
                break;
            }
        }
    }
    pclose(fp);
    return pid;
}

/***********************************************************************************
 * Function Name      : uidof
 * Inputs             : pid (pid_t) - PID of process
 * Returns            : uid (int) - UID of process
 * Description        : Fetch UID from a process id.
 * Note               : Returns -1 on error.
 ***********************************************************************************/
int uidof(pid_t pid) {
    char path[MAX_PATH_LENGTH];
    char line[MAX_DATA_LENGTH];
    FILE* status_file;
    int uid = -1;

    snprintf(path, sizeof(path), "/proc/%d/status", (int)pid);
    status_file = fopen(path, "r");
    if (!status_file) {
        perror("fopen");
        return -1;
    }

    while (fgets(line, sizeof(line), status_file) != NULL) {
        if (strncmp(line, "Uid:", 4) == 0) {
            sscanf(line + 4, "%d", &uid);
            break;
        }
    }

    fclose(status_file);
    return uid;
}

/***********************************************************************************
 * Function Name      : set_priority
 * Inputs             : pid (pid_t) - PID to be boosted
 * Returns            : None
 * Description        : Sets the maximum CPU nice priority and I/O priority of a
 *                      given process.
 ***********************************************************************************/
void set_priority(const pid_t pid) {
    char val[PROP_VALUE_MAX] = {0};
    if (__system_property_get("persist.sys.azenithconf.iosched", val) > 0) {
        if (val[0] == '1') {
            log_zenith(LOG_DEBUG, "Applying priority settings for PID %d", pid);

            if (setpriority(PRIO_PROCESS, pid, -20) == -1)
                log_zenith(LOG_ERROR, "Unable to set nice priority for %d", pid);

            if (syscall(SYS_ioprio_set, 1, pid, (1 << 13) | 0) == -1)
                log_zenith(LOG_ERROR, "Unable to set IO priority for %d", pid);
        }
    }
}
