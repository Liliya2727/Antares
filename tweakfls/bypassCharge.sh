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

MODDIR=${0%/*}
logpath="/data/adb/.config/AZenith/AZenithVerbose.log"

AZLog() {
    if [ "$(cat /data/adb/.config/AZenith/logger)" = "1" ]; then
        local timestamp
        timestamp=$(date +'%Y-%m-%d %H:%M:%S')
        local message="$1"
        echo "$timestamp - $message" >>"$logpath"
        echo "$timestamp - $message"
    fi
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
            AZLog "Wrote to $path, but fallback different values (output: $current)"
        fi
    fi
    chmod 444 "$path" 2>/dev/null
}

# Bypass Charge
enableBypass() {
    applypath() {
        if [ -e "$2" ]; then
            zeshia "$1" "$2"
            return 0
        fi
        return 1
    }
    applypath "1" "/sys/devices/platform/charger/bypass_charger" && return
    applypath "0 1" "/proc/mtk_battery_cmd/current_cmd" && return
    applypath "1" "/sys/devices/platform/charger/tran_aichg_disable_charger" && return
    applypath "1" "/sys/devices/platform/mt-battery/disable_charger" && return
}

disableBypass() {
    # Disable Bypass Charge
    applypath() {
        if [ -e "$2" ]; then
            zeshia "$1" "$2"
            return 0
        fi
        return 1
    }
    applypath "0" "/sys/devices/platform/charger/bypass_charger" && return
    applypath "0 0" "/proc/mtk_battery_cmd/current_cmd" && return
    applypath "0" "/sys/devices/platform/charger/tran_aichg_disable_charger" && return
    applypath "0" "/sys/devices/platform/mt-battery/disable_charger" && return
}

###############################################

###############################################

case "$1" in
0) disableBypass ;;
1) enableBypass ;;
esac

wait
exit 0
