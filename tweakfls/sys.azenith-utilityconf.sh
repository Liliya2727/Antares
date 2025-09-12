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
logpath="/data/adb/.config/AZenith/debug/AZenithVerbose.log"

AZLog() {
	if [ "$(getprop persist.sys.azenith.debugmode)" = "true" ]; then
		local timestamp message log_tag
		timestamp=$(date +"%Y-%m-%d %H:%M:%S.%3N")
		message="$1"
		log_tag="AZenith"
		echo "$timestamp I $log_tag: $message" >>"$logpath"
		log -t "$log_tag" "$message"
	fi
}

dlog() {
	local message log_tag
	message="$1"
	log_tag="AZenith"
	sys.azenith-service_log "$log_tag" 1 "$message"
}

zeshia() {
	local value="$1"
	local path="$2"
	local pathname
	pathname="$(echo "$path" | awk -F'/' '{print $(NF-1)"/"$NF}')"
	if [ ! -e "$path" ]; then
		AZLog "File /$pathname not found, skipping..."
		return
	fi
	if [ ! -w "$path" ] && ! chmod 644 "$path" 2>/dev/null; then
		AZLog "Cannot write to /$pathname (permission denied)"
		return
	fi
	echo "$value" >"$path" 2>/dev/null
	local current
	current="$(cat "$path" 2>/dev/null)"
	if [ "$current" = "$value" ]; then
		AZLog "Set /$pathname to $value"
	else
		echo "$value" >"$path" 2>/dev/null
		current="$(cat "$path" 2>/dev/null)"
		if [ "$current" = "$value" ]; then
			AZLog "Set /$pathname to $value (after retry)"
		else
			AZLog "Set /$pathname to $value"
		fi
	fi
	chmod 444 "$path" 2>/dev/null
}

zeshiax() {
	local value="$1"
	local path="$2"
	local pathname
	pathname="$(echo "$path" | awk -F'/' '{print $(NF-1)"/"$NF}')"
	if [ ! -e "$path" ]; then
		AZLog "File /$pathname not found, skipping..."
		return
	fi
	if [ ! -w "$path" ] && ! chmod 644 "$path" 2>/dev/null; then
		AZLog "Cannot write to /$pathname (permission denied)"
		return
	fi
	echo "$value" >"$path" 2>/dev/null
	local current
	current="$(cat "$path" 2>/dev/null)"
	if [ "$current" = "$value" ]; then
		AZLog "Set /$pathname to $value"
	else
		echo "$value" >"$path" 2>/dev/null
		current="$(cat "$path" 2>/dev/null)"
		if [ "$current" = "$value" ]; then
			AZLog "Set $pathname to $value (after retry)"
		else
			AZLog "Set /$pathname to $value"
		fi
	fi
}

setsgov() {
	chmod 644 /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	echo "$1" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	chmod 444 /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
}

setfreq() {
	local file="$1" target="$2" chosen=""
	if [ -f "$file" ]; then
		chosen=$(tr -s ' ' '\n' <"$file" |
			awk -v t="$target" '
                {diff = (t - $1 >= 0 ? t - $1 : $1 - t)}
                NR==1 || diff < mindiff {mindiff = diff; val=$1}
                END {print val}')
	else
		chosen="$target"
	fi
	echo "$chosen"
}

setsfreqs() {
	setfreq() {
		local file="$1" target="$2" chosen=""
		if [ -f "$file" ]; then
			chosen=$(tr -s ' ' '\n' <"$file" |
				awk -v t="$target" '
                {diff = (t - $1 >= 0 ? t - $1 : $1 - t)}
                NR==1 || diff < mindiff {mindiff = diff; val=$1}
                END {print val}')
		else
			chosen="$target"
		fi
		echo "$chosen"
	}
	limiter=$(getprop persist.sys.azenithconf.freqoffset | sed -e 's/Disabled/100/' -e 's/%//g')
	curprofile=$(cat /data/adb/.config/AZenith/API/current_profile 2>/dev/null)
	if [ -d /proc/ppm ]; then
		cluster=0
		for path in /sys/devices/system/cpu/cpufreq/policy*; do
			cpu_maxfreq=$(cat "$path/cpuinfo_max_freq")
			cpu_minfreq=$(cat "$path/cpuinfo_min_freq")
			new_max_target=$((cpu_maxfreq * limiter / 100))
			new_maxfreq=$(setfreq "$path/scaling_available_frequencies" "$new_max_target")
			[ "$curprofile" = "3" ] && {
				target_min_target=$((cpu_maxfreq * 40 / 100))
				new_minfreq=$(setfreq "$path/scaling_available_frequencies" "$target_min_target")
				zeshia "$cluster $new_maxfreq" "/proc/ppm/policy/hard_userlimit_max_cpu_freq"
				zeshia "$cluster $new_minfreq" "/proc/ppm/policy/hard_userlimit_min_cpu_freq"
				((cluster++))
				continue
			}
			zeshia "$cluster $new_maxfreq" "/proc/ppm/policy/hard_userlimit_max_cpu_freq"
			zeshia "$cluster $cpu_minfreq" "/proc/ppm/policy/hard_userlimit_min_cpu_freq"
			((cluster++))
		done
	fi
	for path in /sys/devices/system/cpu/*/cpufreq; do
		cpu_maxfreq=$(cat "$path/cpuinfo_max_freq")
		cpu_minfreq=$(cat "$path/cpuinfo_min_freq")
		new_max_target=$((cpu_maxfreq * limiter / 100))
		new_maxfreq=$(setfreq "$path/scaling_available_frequencies" "$new_max_target")
		[ "$curprofile" = "3" ] && {
			target_min_target=$((cpu_maxfreq * 40 / 100))
			new_minfreq=$(setfreq "$path/scaling_available_frequencies" "$target_min_target")
			zeshia "$new_maxfreq" "$path/scaling_max_freq"
			zeshia "$new_minfreq" "$path/scaling_min_freq"
			continue
		}
		zeshia "$new_maxfreq" "$path/scaling_max_freq"
		zeshia "$cpu_minfreq" "$path/scaling_min_freq"
		chmod -f 444 /sys/devices/system/cpu/cpufreq/policy*/scaling_*_freq
	done
}

apply_game_freqs() {
	setfreq() {
		local file="$1" target="$2" chosen=""
		if [ -f "$file" ]; then
			chosen=$(tr -s ' ' '\n' <"$file" |
				awk -v t="$target" '
                {diff = (t - $1 >= 0 ? t - $1 : $1 - t)}
                NR==1 || diff < mindiff {mindiff = diff; val=$1}
                END {print val}')
		else
			chosen="$target"
		fi
		echo "$chosen"
	}
	# Fix Target OPP Index
	if [ -d /proc/ppm ]; then
		cluster=-1
		for path in /sys/devices/system/cpu/cpufreq/policy*; do
			((cluster++))
			cpu_maxfreq=$(cat "$path/cpuinfo_max_freq")
			cpu_minfreq=$(cat "$path/cpuinfo_max_freq")
			[ "$(getprop persist.sys.azenithconf.cpulimit)" -eq 1 ] && {
				new_maxtarget=$((cpu_maxfreq * 90 / 100))
				new_midtarget=$((cpu_maxfreq * 50 / 100))
				new_midfreq=$(setfreq "$path/scaling_available_frequencies" "$new_midtarget")
				new_maxfreq=$(setfreq "$path/scaling_available_frequencies" "$new_maxtarget")
				zeshiax "$cluster $new_maxfreq" "/proc/ppm/policy/hard_userlimit_max_cpu_freq"
				zeshiax "$cluster $new_midfreq" "/proc/ppm/policy/hard_userlimit_min_cpu_freq"
				continue
			}
			zeshiax "$cluster $cpu_maxfreq" "/proc/ppm/policy/hard_userlimit_max_cpu_freq"
			zeshiax "$cluster $cpu_minfreq" "/proc/ppm/policy/hard_userlimit_min_cpu_freq"
		done
	fi
	for path in /sys/devices/system/cpu/*/cpufreq; do
		cpu_maxfreq=$(cat "$path/cpuinfo_max_freq")
		cpu_minfreq=$(cat "$path/cpuinfo_max_freq")
		[ "$(getprop persist.sys.azenithconf.cpulimit)" -eq 1 ] && {
			new_maxtarget=$((cpu_maxfreq * 90 / 100))
			new_midtarget=$((cpu_maxfreq * 50 / 100))
			new_midfreq=$(setfreq "$path/scaling_available_frequencies" "$new_midtarget")
			new_maxfreq=$(setfreq "$path/scaling_available_frequencies" "$new_maxtarget")
			zeshiax "$new_maxfreq" "$path/scaling_max_freq"
			zeshiax "$new_midfreq" "$path/scaling_min_freq"
			continue
		}
		zeshiax "$cpu_maxfreq" "$path/scaling_max_freq"
		zeshiax "$cpu_minfreq" "$path/scaling_min_freq"
		chmod -f 644 /sys/devices/system/cpu/cpufreq/policy*/scaling_*_freq
	done
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

vsync_value="$(getprop persist.sys.azenithconf.vsync)"
case "$vsync_value" in
60hz | 90hz | 120hz)
	disablevsync "$vsync_value"
	dlog "VSync Restored: $vsync_value"
	;;
Disabled) ;;
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

$(</data/adb/.config/AZenith/debug/AZenith.log)
EOF
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

$@

exit 0
