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
pid_t pidof(const char* name) {
    if (!name || !name[0])
        return 0;

    FILE* fp = popen("dumpsys activity activities", "r");
    if (!fp)
        return 0;

    char line[4096];
    pid_t pid = 0;

    while (fgets(line, sizeof(line), fp)) {

        // We only want ProcessRecord and our package name
        if (!strstr(line, "ProcessRecord{"))
            continue;
        if (!strstr(line, name))
            continue;

        char* colon = strstr(line, ":");
        if (!colon)
            continue;

        // Go backward to find the start of the PID number
        char* p = colon - 1;
        while (p > line && isdigit((unsigned char)*p)) {
            p--;
        }
        p++; // Move to first digit

        if (!isdigit((unsigned char)p[0]))
            continue;

        long val = strtol(p, NULL, 10);
        if (val > 0) {
            pid = (pid_t)val;
            break;
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
