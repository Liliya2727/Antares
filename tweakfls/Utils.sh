#!/system/bin/sh

#
# Copyright (C) 2024-2025 Zexshia
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# shellcheck disable=SC2013

MODDIR=${0%/*}

AZLog() {
    if [ "$(cat /data/adb/.config/AZenith/logger)" = "1" ]; then
        local timestamp
        timestamp=$(date +'%Y-%m-%d %H:%M:%S')
        local message="$1"
        echo "$timestamp - $message" >>"$logpath"
        echo "$timestamp - $message"
    fi
}

dlog() {
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S.%3N")
    local message="$1"
    echo "$timestamp I AZenith: $message" >>"$logdaemonpath"
}

zeshia() {
    local value="$1"
    local path="$2"
    if [ ! -e "$path" ]; then
        AZLog "File $path not found, skipping..."
        return
    fi
    if [ ! -w "$path" ] && ! chmod 644 "$path" 2>/dev/null; then
        AZLog "Cannot write to $path (permission denied)"
        return
    fi
    echo "$value" >"$path" 2>/dev/null
    local current
    current="$(cat "$path" 2>/dev/null)"
    if [ "$current" = "$value" ]; then
        AZLog "Set $path to $value"
    else
        echo "$value" >"$path" 2>/dev/null
        current="$(cat "$path" 2>/dev/null)"
        if [ "$current" = "$value" ]; then
            AZLog "Set $path to $value (after retry)"
        else
            AZLog "Set $path to $value (can't confirm)"
        fi
    fi
    chmod 444 "$path" 2>/dev/null
}

setsgov() {
	chmod 644 /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	echo "$1" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	chmod 444 /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
}

FSTrim() {
    for mount in /system /vendor /data /cache /metadata /odm /system_ext /product; do
        if mountpoint -q "$mount"; then
            fstrim -v "$mount"
            AZLog "Trimmed: $mount"
        else
            AZLog "Skipped (not mounted): $mount"
        fi
    done
}

disablevsync() {
    case "$1" in
    60hz) service call SurfaceFlinger 1035 i32 2 ;;
    90hz) service call SurfaceFlinger 1035 i32 1 ;;
    120hz) service call SurfaceFlinger 1035 i32 0 ;;
    Disabled) service call SurfaceFlinger 1035 i32 2 ;;
    esac
}

vsync_value="$(cat /data/adb/.config/AZenith/customVsync)"
case "$vsync_value" in
60hz | 90hz | 120hz)
    disablevsync "$vsync_value"
    ;;
Disabled)
    AZLog "disable vsync disabled"
    ;;
esac

saveLog() {
    log_file="/sdcard/AZenithLog$(date +"%Y-%m-%d_%H_%M").txt"
    echo "$log_file"

    module_ver=$(awk -F'=' '/version=/ {print $2}' /data/adb/modules/AZenith/module.prop)
    android_sdk=$(getprop ro.build.version.sdk)
    kernel_info=$(uname -r -m)
    fingerprint=$(getprop ro.build.fingerprint)

    cat <<EOF >"$log_file"
##########################################
             AZenith Process Log
    
    Module: $module_ver
    Android: $android_sdk
    Kernel: $kernel_info
    Fingerprint: $fingerprint
##########################################

$(</data/adb/.config/AZenith/AZenith.log)
EOF
}

$@
