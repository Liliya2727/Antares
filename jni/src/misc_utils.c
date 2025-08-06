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

/***********************************************************************************
 * Function Name      : trim_newline
 * Inputs             : str (char *) - string to trim newline from
 * Returns            : char * - string without newline
 * Description        : Trims a newline character at the end of a string if
 *                      present.
 ***********************************************************************************/
[[gnu::always_inline]] char* trim_newline(char* string) {
    if (string == NULL)
        return NULL;

    char* end;
    if ((end = strchr(string, '\n')) != NULL)
        *end = '\0';

    return string;
}

/***********************************************************************************
 * Function Name      : notify
 * Inputs             : message (char *) - Message to display
 * Returns            : None
 * Description        : Push a notification.
 ***********************************************************************************/
void notify(const char* message) {
    int exit = systemv("su -lp 2000 -c \"/system/bin/cmd notification post "
                       "-t '%s' "
                       "-i file:///data/local/tmp/AZenith_icon.png "
                       "-I file:///data/local/tmp/AZenith_icon.png "
                       "'AZenith' '%s'\" >/dev/null",
                       NOTIFY_TITLE, message);

    if (exit != 0) [[clang::unlikely]] {
        log_zenith(LOG_ERROR, "Unable to post push notification, message: %s", message);
    }
}

/***********************************************************************************
 * Function Name      : timern
 * Inputs             : None
 * Returns            : char * - pointer to a statically allocated string
 *                      with the formatted time.
 * Description        : Generates a timestamp with the format
 *                      [YYYY-MM-DD HH:MM:SS.milliseconds].
 ***********************************************************************************/
char* timern(void) {
    static char timestamp[64];
    struct timeval tv;
    time_t current_time;
    struct tm* local_time;

    gettimeofday(&tv, NULL);
    current_time = tv.tv_sec;
    local_time = localtime(&current_time);

    if (local_time == NULL) [[clang::unlikely]] {
        strcpy(timestamp, "[TimeError]");
        return timestamp;
    }

    size_t format_result = strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", local_time);
    if (format_result == 0) [[clang::unlikely]] {
        strcpy(timestamp, "[TimeFormatError]");
        return timestamp;
    }

    // Append milliseconds
    snprintf(timestamp + strlen(timestamp), sizeof(timestamp) - strlen(timestamp), ".%03ld", tv.tv_usec / 1000);

    return timestamp;
}

/***********************************************************************************
 * Function Name      : sighandler
 * Inputs             : int signal - exit signal
 * Returns            : None
 * Description        : Handle exit signal.
 ***********************************************************************************/
[[noreturn]] void sighandler(const int signal) {
    switch (signal) {
    case SIGTERM:
        log_zenith(LOG_INFO, "Received SIGTERM, exiting.");
        break;
    case SIGINT:
        log_zenith(LOG_INFO, "Received SIGINT, exiting.");
        break;
    }

    // Exit gracefully
    _exit(EXIT_SUCCESS);
}

/***********************************************************************************
 * Function Name      : toast
 * Inputs             : message (const char *) - Message to display
 * Returns            : None
 * Description        : Display a toast notification using bellavita.toast app.
 ***********************************************************************************/
void toast(const char* message) {
    int exit = systemv("su -lp 2000 -c \"/system/bin/am start -a android.intent.action.MAIN "
                       "-e toasttext '%s' -n bellavita.toast/.MainActivity >/dev/null 2>&1\"",
                       message);

    if (exit != 0) [[clang::unlikely]] {
        log_zenith(LOG_WARN, "Unable to show toast message: %s", message);
    }
}

/***********************************************************************************
 * Function Name      : is_kanged
 * Inputs             : None
 * Returns            : None
 * Description        : Checks if the module renamed/modified by 3rd party.
 ***********************************************************************************/
void is_kanged(void) {
    if (systemv("grep -q '^name=AZenith火$' %s", MODULE_PROP) != 0) [[clang::unlikely]] {
        goto doorprize;
    }

    if (systemv("grep -q '^author=@Zexshia X @kanaochar$' %s", MODULE_PROP) != 0) [[clang::unlikely]] {
        goto doorprize;
    }

    return;

doorprize:
    log_zenith(LOG_FATAL, "Module modified by 3rd party, exiting.");
    notify("Trying to rename me?");
    exit(EXIT_FAILURE);
}

/***********************************************************************************
 * Function Name      : return_true
 * Inputs             : None
 * Returns            : bool - only true
 * Description        : Will be used for error fallback.
 * Note               : Never call this function.
 ***********************************************************************************/
bool return_true(void) {
    return true;
}

/***********************************************************************************
 * Function Name      : return_false
 * Inputs             : None
 * Returns            : bool - only false
 * Description        : Will be used for error fallback.
 * Note               : Never call this function.
 ***********************************************************************************/
bool return_false(void) {
    return false;
}

/***********************************************************************************
 * Function Name      : cleanup
 * Inputs             : None
 * Returns            : None (exits the program)
 * Description        : Terminates vmt processes and exits cleanly with logging.
 ***********************************************************************************/
void cleanup_vmt(void) {
    log_zenith(LOG_INFO, "Cleaning up vmt Process...");
    systemv("pkill -x vmt");
    systemv("pkill -x vmt2");
}

void cleanup(void) {
    log_zenith(LOG_INFO, "Stop Preloading, Killing vmt process...");
    systemv("pkill -x vmt");
    systemv("pkill -x vmt2");
}
