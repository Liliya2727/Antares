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
logpath2="/data/adb/.config/AZenith/debug/AZenith.log"
limiter=$(getprop persist.sys.azenithconf.freqoffset | sed -e 's/Disabled/100/' -e 's/%//g')
curprofile=$(<"/data/adb/.config/AZenith/API/current_profile")

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

	chmod 644 "$path" 2>/dev/null

	if ! echo "$value" >"$path" 2>/dev/null; then
		AZLog "Cannot write to /$pathname (permission denied)"
		chmod 444 "$path" 2>/dev/null
		return
	fi

	local current
	current="$(cat "$path" 2>/dev/null)"
	if [ "$current" = "$value" ]; then
		AZLog "Set /$pathname to $value"
	else
		echo "$value" >"$path" 2>/dev/null || true
		current="$(cat "$path" 2>/dev/null)"
		if [ "$current" = "$value" ]; then
			AZLog "Set /$pathname to $value (after retry)"
		else
			AZLog "Failed to set /$pathname to $value"
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

	chmod 644 "$path" 2>/dev/null

	if ! echo "$value" >"$path" 2>/dev/null; then
		AZLog "Cannot write to /$pathname (permission denied)"
		chmod 444 "$path" 2>/dev/null
		return
	fi

	local current
	current="$(cat "$path" 2>/dev/null)"
	if [ "$current" = "$value" ]; then
		AZLog "Set /$pathname to $value"
	else
		echo "$value" >"$path" 2>/dev/null || true
		current="$(cat "$path" 2>/dev/null)"
		if [ "$current" = "$value" ]; then
			AZLog "Set /$pathname to $value (after retry)"
		else
			AZLog "Failed to set /$pathname to $value"
		fi
	fi

}

applyppmnfreqsets() {
	[ ! -f "$2" ] && return 1
	chmod 644 "$2" 2>/dev/null
	echo "$1" >"$2" 2>/dev/null
	chmod 444 "$2" 2>/dev/null
}

which_maxfreq() {
	tr ' ' '\n' <"$1" | sort -nr | head -n 1
}

which_minfreq() {
	tr ' ' '\n' <"$1" | grep -v '^[[:space:]]*$' | sort -n | head -n 1
}

which_midfreq() {
	total_opp=$(wc -w <"$1")
	mid_opp=$(((total_opp + 1) / 2))
	tr ' ' '\n' <"$1" | grep -v '^[[:space:]]*$' | sort -nr | head -n $mid_opp | tail -n 1
}

setfreqs() {
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

devfreq_max_perf() {
	[ ! -f "$1/available_frequencies" ] && return 1
	max_freq=$(which_maxfreq "$1/available_frequencies")
	zeshia "$max_freq" "$1/max_freq"
	zeshia "$max_freq" "$1/min_freq"
}

devfreq_mid_perf() {
	[ ! -f "$1/available_frequencies" ] && return 1
	max_freq=$(which_maxfreq "$1/available_frequencies")
	mid_freq=$(which_midfreq "$1/available_frequencies")
	zeshia "$max_freq" "$1/max_freq"
	zeshia "$mid_freq" "$1/min_freq"
}

devfreq_unlock() {
	[ ! -f "$1/available_frequencies" ] && return 1
	max_freq=$(which_maxfreq "$1/available_frequencies")
	min_freq=$(which_minfreq "$1/available_frequencies")
	zeshiax "$max_freq" "$1/max_freq"
	zeshiax "$min_freq" "$1/min_freq"
}

devfreq_min_perf() {
	[ ! -f "$1/available_frequencies" ] && return 1
	freq=$(which_minfreq "$1/available_frequencies")
	zeshia "$freq" "$1/min_freq"
	zeshia "$freq" "$1/max_freq"
}

qcom_cpudcvs_max_perf() {
	[ ! -f "$1/available_frequencies" ] && return 1
	freq=$(which_maxfreq "$1/available_frequencies")
	zeshia "$freq" "$1/hw_max_freq"
	zeshia "$freq" "$1/hw_min_freq"
}

qcom_cpudcvs_mid_perf() {
	[ ! -f "$1/available_frequencies" ] && return 1
	max_freq=$(which_maxfreq "$1/available_frequencies")
	mid_freq=$(which_midfreq "$1/available_frequencies")
	zeshia "$max_freq" "$1/hw_max_freq"
	zeshia "$mid_freq" "$1/hw_min_freq"
}

qcom_cpudcvs_unlock() {
	[ ! -f "$1/available_frequencies" ] && return 1
	max_freq=$(which_maxfreq "$1/available_frequencies")
	min_freq=$(which_minfreq "$1/available_frequencies")
	zeshiax "$max_freq" "$1/hw_max_freq"
	zeshiax "$min_freq" "$1/hw_min_freq"
}

qcom_cpudcvs_min_perf() {
	[ ! -f "$1/available_frequencies" ] && return 1
	freq=$(which_minfreq "$1/available_frequencies")
	zeshia "$freq" "$1/hw_min_freq"
	zeshia "$freq" "$1/hw_max_freq"
}

setgov() {
	chmod 644 /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	echo "$1" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
	chmod 444 /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	chmod 444 /sys/devices/system/cpu/cpufreq/policy*/scaling_governor
}

setsIO() {
	for block in sda sdb sdc mmcblk0 mmcblk1; do
		if [ -e "/sys/block/$block/queue/scheduler" ]; then
			chmod 644 "/sys/block/$block/queue/scheduler"
			echo "$1" | tee "/sys/block/$block/queue/scheduler" >/dev/null
			chmod 444 "/sys/block/$block/queue/scheduler"
		fi
	done
}

setfreqppm() {
	if [ -d /proc/ppm ]; then
		limiter=$(getprop persist.sys.azenithconf.freqoffset | sed -e 's/Disabled/100/' -e 's/%//g')
		curprofile=$(<"/data/adb/.config/AZenith/API/current_profile")
		cluster=0
		for path in /sys/devices/system/cpu/cpufreq/policy*; do
			cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
			cpu_minfreq=$(<"$path/cpuinfo_min_freq")
			new_max_target=$((cpu_maxfreq * limiter / 100))
			new_maxfreq=$(setfreqs "$path/scaling_available_frequencies" "$new_max_target")
			[ "$curprofile" = "3" ] && {
				target_min_target=$((cpu_maxfreq * 40 / 100))
				new_minfreq=$(setfreqs "$path/scaling_available_frequencies" "$target_min_target")
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
}

setfreq() {
	limiter=$(getprop persist.sys.azenithconf.freqoffset | sed -e 's/Disabled/100/' -e 's/%//g')
	curprofile=$(<"/data/adb/.config/AZenith/API/current_profile")
	for path in /sys/devices/system/cpu/*/cpufreq; do
		cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
		cpu_minfreq=$(<"$path/cpuinfo_min_freq")
		new_max_target=$((cpu_maxfreq * limiter / 100))
		new_maxfreq=$(setfreqs "$path/scaling_available_frequencies" "$new_max_target")
		[ "$curprofile" = "3" ] && {
			target_min_target=$((cpu_maxfreq * 40 / 100))
			new_minfreq=$(setfreqs "$path/scaling_available_frequencies" "$target_min_target")
			zeshia "$new_maxfreq" "$path/scaling_max_freq"
			zeshia "$new_minfreq" "$path/scaling_min_freq"
			continue
		}
		zeshia "$new_maxfreq" "$path/scaling_max_freq"
		zeshia "$cpu_minfreq" "$path/scaling_min_freq"
		chmod -f 444 /sys/devices/system/cpu/cpufreq/policy*/scaling_*_freq
	done
}

setgamefreqppm() {
	if [ -d /proc/ppm ]; then
		cluster=-1
		for path in /sys/devices/system/cpu/cpufreq/policy*; do
			((cluster++))
			cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
			cpu_minfreq=$(<"$path/cpuinfo_max_freq")
			new_midtarget=$((cpu_maxfreq * 90 / 100))
			new_midfreq=$(setfreqs "$path/scaling_available_frequencies" "$new_midtarget")
			[ "$(getprop persist.sys.azenithconf.cpulimit)" -eq 1 ] && {
				new_maxtarget=$((cpu_maxfreq * 90 / 100))
				new_midtarget=$((cpu_maxfreq * 50 / 100))
				new_midfreq=$(setfreqs "$path/scaling_available_frequencies" "$new_midtarget")
				new_maxfreq=$(setfreqs "$path/scaling_available_frequencies" "$new_maxtarget")
				zeshia "$cluster $new_maxfreq" "/proc/ppm/policy/hard_userlimit_max_cpu_freq"
				zeshia "$cluster $new_midfreq" "/proc/ppm/policy/hard_userlimit_min_cpu_freq"
				continue
			}
			zeshia "$cluster $cpu_maxfreq" "/proc/ppm/policy/hard_userlimit_max_cpu_freq"
			zeshia "$cluster $new_midfreq" "/proc/ppm/policy/hard_userlimit_min_cpu_freq"
		done
	fi
}

setgamefreq() {
	for path in /sys/devices/system/cpu/*/cpufreq; do
		cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
		cpu_minfreq=$(<"$path/cpuinfo_max_freq")
		new_midtarget=$((cpu_maxfreq * 90 / 100))
		new_midfreq=$(setfreqs "$path/scaling_available_frequencies" "$new_midtarget")
		[ "$(getprop persist.sys.azenithconf.cpulimit)" -eq 1 ] && {
			new_maxtarget=$((cpu_maxfreq * 90 / 100))
			new_midtarget=$((cpu_maxfreq * 50 / 100))
			new_midfreq=$(setfreqs "$path/scaling_available_frequencies" "$new_midtarget")
			new_maxfreq=$(setfreqs "$path/scaling_available_frequencies" "$new_maxtarget")
			zeshia "$new_maxfreq" "$path/scaling_max_freq"
			zeshia "$new_midfreq" "$path/scaling_min_freq"
			continue
		}
		zeshia "$cpu_maxfreq" "$path/scaling_max_freq"
		zeshia "$new_midfreq" "$path/scaling_min_freq"
		chmod -f 444 /sys/devices/system/cpu/cpufreq/policy*/scaling_*_freq
	done
}

## For Daemon Calls
Dsetfreqppm() {
	if [ -d /proc/ppm ]; then
		limiter=$(getprop persist.sys.azenithconf.freqoffset | sed -e 's/Disabled/100/' -e 's/%//g')
		curprofile=$(<"/data/adb/.config/AZenith/API/current_profile")
		cluster=0
		for path in /sys/devices/system/cpu/cpufreq/policy*; do
			cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
			cpu_minfreq=$(<"$path/cpuinfo_min_freq")
			new_max_target=$((cpu_maxfreq * limiter / 100))
			new_maxfreq=$(setfreqs "$path/scaling_available_frequencies" "$new_max_target")
			[ "$curprofile" = "3" ] && {
				target_min_target=$((cpu_maxfreq * 40 / 100))
				new_minfreq=$(setfreqs "$path/scaling_available_frequencies" "$target_min_target")
				applyppmnfreqsets "$cluster $new_maxfreq" "/proc/ppm/policy/hard_userlimit_max_cpu_freq"
				applyppmnfreqsets "$cluster $new_minfreq" "/proc/ppm/policy/hard_userlimit_min_cpu_freq"
				((cluster++))
				continue
			}
			applyppmnfreqsets "$cluster $new_maxfreq" "/proc/ppm/policy/hard_userlimit_max_cpu_freq"
			applyppmnfreqsets "$cluster $cpu_minfreq" "/proc/ppm/policy/hard_userlimit_min_cpu_freq"
			((cluster++))
		done
	fi
}

Dsetfreq() {
	limiter=$(getprop persist.sys.azenithconf.freqoffset | sed -e 's/Disabled/100/' -e 's/%//g')
	curprofile=$(<"/data/adb/.config/AZenith/API/current_profile")
	for path in /sys/devices/system/cpu/*/cpufreq; do
		cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
		cpu_minfreq=$(<"$path/cpuinfo_min_freq")
		new_max_target=$((cpu_maxfreq * limiter / 100))
		new_maxfreq=$(setfreqs "$path/scaling_available_frequencies" "$new_max_target")
		[ "$curprofile" = "3" ] && {
			target_min_target=$((cpu_maxfreq * 40 / 100))
			new_minfreq=$(setfreqs "$path/scaling_available_frequencies" "$target_min_target")
			applyppmnfreqsets "$new_maxfreq" "$path/scaling_max_freq"
			applyppmnfreqsets "$new_minfreq" "$path/scaling_min_freq"
			continue
		}
		applyppmnfreqsets "$new_maxfreq" "$path/scaling_max_freq"
		applyppmnfreqsets "$cpu_minfreq" "$path/scaling_min_freq"
		chmod -f 444 /sys/devices/system/cpu/cpufreq/policy*/scaling_*_freq
	done
}

Dsetgamefreqppm() {
	if [ -d /proc/ppm ]; then
		cluster=-1
		for path in /sys/devices/system/cpu/cpufreq/policy*; do
			((cluster++))
			cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
			cpu_minfreq=$(<"$path/cpuinfo_max_freq")
			new_midtarget=$((cpu_maxfreq * 90 / 100))
			new_midfreq=$(setfreqs "$path/scaling_available_frequencies" "$new_midtarget")
			[ "$(getprop persist.sys.azenithconf.cpulimit)" -eq 1 ] && {
				new_maxtarget=$((cpu_maxfreq * 90 / 100))
				new_midtarget=$((cpu_maxfreq * 50 / 100))
				new_midfreq=$(setfreqs "$path/scaling_available_frequencies" "$new_midtarget")
				new_maxfreq=$(setfreqs "$path/scaling_available_frequencies" "$new_maxtarget")
				applyppmnfreqsets "$cluster $new_maxfreq" "/proc/ppm/policy/hard_userlimit_max_cpu_freq"
				applyppmnfreqsets "$cluster $new_midfreq" "/proc/ppm/policy/hard_userlimit_min_cpu_freq"
				continue
			}
			applyppmnfreqsets "$cluster $cpu_maxfreq" "/proc/ppm/policy/hard_userlimit_max_cpu_freq"
			applyppmnfreqsets "$cluster $new_midfreq" "/proc/ppm/policy/hard_userlimit_min_cpu_freq"
		done
	fi
}

Dsetgamefreq() {
	for path in /sys/devices/system/cpu/*/cpufreq; do
		cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
		cpu_minfreq=$(<"$path/cpuinfo_max_freq")
		new_midtarget=$((cpu_maxfreq * 90 / 100))
		new_midfreq=$(setfreqs "$path/scaling_available_frequencies" "$new_midtarget")
		[ "$(getprop persist.sys.azenithconf.cpulimit)" -eq 1 ] && {
			new_maxtarget=$((cpu_maxfreq * 90 / 100))
			new_midtarget=$((cpu_maxfreq * 50 / 100))
			new_midfreq=$(setfreqs "$path/scaling_available_frequencies" "$new_midtarget")
			new_maxfreq=$(setfreqs "$path/scaling_available_frequencies" "$new_maxtarget")
			applyppmnfreqsets "$new_maxfreq" "$path/scaling_max_freq"
			applyppmnfreqsets "$new_midfreq" "$path/scaling_min_freq"
			continue
		}
		applyppmnfreqsets "$cpu_maxfreq" "$path/scaling_max_freq"
		applyppmnfreqsets "$new_midfreq" "$path/scaling_min_freq"
		chmod -f 444 /sys/devices/system/cpu/cpufreq/policy*/scaling_*_freq
	done
}

applyfreqbalance() {
	[ -d /proc/ppm ] && Dsetfreqppm || Dsetfreq
}

applyfreqgame() {
	[ -d /proc/ppm ] && Dsetgamefreqppm || Dsetgamefreq
}

###############################################
# # # # # # #  MEDIATEK BALANCE # # # # # # #
###############################################
mediatek_balance() {
	# PPM Settings
	if [ -d /proc/ppm ]; then
		if [ -f /proc/ppm/policy_status ]; then
			for idx in $(grep -E 'FORCE_LIMIT|PWR_THRO|THERMAL|USER_LIMIT' /proc/ppm/policy_status | awk -F'[][]' '{print $2}'); do
				zeshia "$idx 1" "/proc/ppm/policy_status"
			done

			for dx in $(grep -E 'SYS_BOOST' /proc/ppm/policy_status | awk -F'[][]' '{print $2}'); do
				zeshia "$dx 0" "/proc/ppm/policy_status"
			done
		fi
	fi

	# CPU POWER MODE
	zeshia "0" "/proc/cpufreq/cpufreq_cci_mode"
	zeshia "1" "/proc/cpufreq/cpufreq_power_mode"

	# GPU Frequency
	if [ -d /proc/gpufreq ]; then
		zeshia "0" /proc/gpufreq/gpufreq_opp_freq
	elif [ -d /proc/gpufreqv2 ]; then
		zeshia "-1" /proc/gpufreqv2/fix_target_opp_index
	fi

	# EAS/HMP Switch
	zeshia "1" /sys/devices/system/cpu/eas/enable

	# GPU Power limiter
	[ -f "/proc/gpufreq/gpufreq_power_limited" ] && {
		for setting in ignore_batt_oc ignore_batt_percent ignore_low_batt ignore_thermal_protect ignore_pbm_limited; do
			zeshia "$setting 0" /proc/gpufreq/gpufreq_power_limited
		done
	}

	# Batoc Throttling and Power Limiter>
	zeshia "0" /proc/perfmgr/syslimiter/syslimiter_force_disable
	zeshia "stop 0" /proc/mtk_batoc_throttling/battery_oc_protect_stop
	# Enable Power Budget management for new 5.x mtk kernels
	zeshia "stop 0" /proc/pbm/pbm_stop

	# Enable battery current limiter
	zeshia "stop 0" /proc/mtk_batoc_throttling/battery_oc_protect_stop

	# Eara Thermal
	zeshia "1" /sys/kernel/eara_thermal/enable

	# Restore UFS governor
	zeshia "-1" "/sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_req_ddr_opp"
	zeshia "-1" "/sys/kernel/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp"
	zeshia "userspace" "/sys/class/devfreq/mtk-dvfsrc-devfreq/governor"
	zeshia "userspace" "/sys/devices/platform/soc/1c00f000.dvfsrc/mtk-dvfsrc-devfreq/devfreq/mtk-dvfsrc-devfreq/governor"
	
	mali_sysfs=$(find /sys/devices/platform/ -iname "*.mali" -print -quit 2>/dev/null)
	zeshia coarse_demand "$mali_sysfs/power_policy"
}

###############################################
# # # # # # # SNAPDRAGON BALANCE # # # # # # #
###############################################
snapdragon_balance() {
	# Qualcomm CPU Bus and DRAM frequencies
	for path in /sys/class/devfreq/*cpu-ddr-latfloor*; do
		zeshia "compute" $path/governor
	done &

	for path in /sys/class/devfreq/*cpu*-lat; do
		zeshia "mem_latency" $path/governor
	done &

	for path in /sys/class/devfreq/*cpu-cpu-ddr-bw; do
		zeshia "bw_hwmon" $path/governor
	done &

	for path in /sys/class/devfreq/*cpu-cpu-llcc-bw; do
		zeshia "bw_hwmon" $path/governor
	done &

	if [ -d /sys/devices/system/cpu/bus_dcvs/LLCC ]; then
		max_freq=$(cat /sys/devices/system/cpu/bus_dcvs/LLCC/available_frequencies | tr ' ' '\n' | sort -nr | head -n 1)
		min_freq=$(cat /sys/devices/system/cpu/bus_dcvs/LLCC/available_frequencies | tr ' ' '\n' | sort -n | head -n 1)
		for path in /sys/devices/system/cpu/bus_dcvs/LLCC/*/max_freq; do
			zeshia $max_freq $path
		done &
		for path in /sys/devices/system/cpu/bus_dcvs/LLCC/*/min_freq; do
			zeshia $min_freq $path
		done &
	fi

	if [ -d /sys/devices/system/cpu/bus_dcvs/L3 ]; then
		max_freq=$(cat /sys/devices/system/cpu/bus_dcvs/L3/available_frequencies | tr ' ' '\n' | sort -nr | head -n 1)
		min_freq=$(cat /sys/devices/system/cpu/bus_dcvs/L3/available_frequencies | tr ' ' '\n' | sort -n | head -n 1)
		for path in /sys/devices/system/cpu/bus_dcvs/L3/*/max_freq; do
			zeshia $max_freq $path
		done &
		for path in /sys/devices/system/cpu/bus_dcvs/L3/*/min_freq; do
			zeshia $min_freq $path
		done &
	fi

	if [ -d /sys/devices/system/cpu/bus_dcvs/DDR ]; then
		max_freq=$(cat /sys/devices/system/cpu/bus_dcvs/DDR/available_frequencies | tr ' ' '\n' | sort -nr | head -n 1)
		min_freq=$(cat /sys/devices/system/cpu/bus_dcvs/DDR/available_frequencies | tr ' ' '\n' | sort -n | head -n 1)
		for path in /sys/devices/system/cpu/bus_dcvs/DDR/*/max_freq; do
			zeshia $max_freq $path
		done &
		for path in /sys/devices/system/cpu/bus_dcvs/DDR/*/min_freq; do
			zeshia $min_freq $path
		done &
	fi

	if [ -d /sys/devices/system/cpu/bus_dcvs/DDRQOS ]; then
		max_freq=$(cat /sys/devices/system/cpu/bus_dcvs/DDRQOS/available_frequencies | tr ' ' '\n' | sort -nr | head -n 1)
		min_freq=$(cat /sys/devices/system/cpu/bus_dcvs/DDRQOS/available_frequencies | tr ' ' '\n' | sort -n | head -n 1)
		for path in /sys/devices/system/cpu/bus_dcvs/DDRQOS/*/max_freq; do
			zeshia $max_freq $path
		done &
		for path in /sys/devices/system/cpu/bus_dcvs/DDRQOS/*/min_freq; do
			zeshia $min_freq $path
		done &
	fi

	# GPU Frequency
	gpu_path="/sys/class/kgsl/kgsl-3d0/devfreq"

	if [ -d $gpu_path ]; then
		max_freq=$(cat $gpu_path/available_frequencies | tr ' ' '\n' | sort -nr | head -n 1)
		min_freq=$(cat $gpu_path/available_frequencies | tr ' ' '\n' | sort -n | head -n 2)
		zeshia $min_freq $gpu_path/min_freq
		zeshia $max_freq $gpu_path/max_freq
	fi

	# GPU Bus
	for path in /sys/class/devfreq/*gpubw*; do
		zeshia "bw_vbif" $path/governor
	done &

	# Adreno Boost
	zeshia 1 /sys/class/kgsl/kgsl-3d0/devfreq/adrenoboost
}

###############################################
# # # # # # # EXYNOS BALANCE # # # # # # #
###############################################
exynos_balance() {
	# GPU Frequency
	gpu_path="/sys/kernel/gpu"
	[ -d "$gpu_path" ] && {
		max_freq=$(which_maxfreq "$gpu_path/gpu_available_frequencies")
		min_freq=$(which_minfreq "$gpu_path/gpu_available_frequencies")
		zeshia "$max_freq" "$gpu_path/gpu_max_clock"
		zeshia "$min_freq" "$gpu_path/gpu_min_clock"
	}

	mali_sysfs=$(find /sys/devices/platform/ -iname "*.mali" -print -quit 2>/dev/null)
	zeshia coarse_demand "$mali_sysfs/power_policy"

	# DRAM frequency
	[ $DEVICE_MITIGATION -eq 0 ] && {
		for path in /sys/class/devfreq/*devfreq_mif*; do
			devfreq_unlock "$path"
		done &
	}
}

###############################################
# # # # # # # UNISOC BALANCE # # # # # # #
###############################################
unisoc_balance() {
	# GPU Frequency
	gpu_path=$(find /sys/class/devfreq/ -type d -iname "*.gpu" -print -quit 2>/dev/null)
	[ -n "$gpu_path" ] && devfreq_unlock "$gpu_path"
}

###############################################
# # # # # # # TENSOR BALANCE # # # # # # #
###############################################
tensor_balance() {
	# GPU Frequency
	gpu_path=$(find /sys/devices/platform/ -type d -iname "*.mali" -print -quit 2>/dev/null)
	[ -n "$gpu_path" ] && {
		max_freq=$(which_maxfreq "$gpu_path/available_frequencies")
		min_freq=$(which_minfreq "$gpu_path/available_frequencies")
		zeshia "$max_freq" "$gpu_path/scaling_max_freq"
		zeshia "$min_freq" "$gpu_path/scaling_min_freq"
	}

	# DRAM frequency
	[ $DEVICE_MITIGATION -eq 0 ] && {
		for path in /sys/class/devfreq/*devfreq_mif*; do
			devfreq_unlock "$path"
		done &
	}
}

###############################################
# # # # # # # MEDIATEK PERFORMANCE # # # # # # #
###############################################
mediatek_performance() {
	# PPM Settings
	if [ -d /proc/ppm ]; then
		if [ -f /proc/ppm/policy_status ]; then
			for idx in $(grep -E 'FORCE_LIMIT|PWR_THRO|THERMAL|USER_LIMIT' /proc/ppm/policy_status | awk -F'[][]' '{print $2}'); do
				zeshia "$idx 0" "/proc/ppm/policy_status"
			done

			for dx in $(grep -E 'SYS_BOOST' /proc/ppm/policy_status | awk -F'[][]' '{print $2}'); do
				zeshia "$dx 1" "/proc/ppm/policy_status"
			done
		fi
	fi

	# CPU Power Mode
	zeshia "1" "/proc/cpufreq/cpufreq_cci_mode"
	zeshia "3" "/proc/cpufreq/cpufreq_power_mode"

	# Max GPU Frequency
	if [ -d /proc/gpufreq ]; then
		gpu_freq="$(cat /proc/gpufreq/gpufreq_opp_dump | grep -o 'freq = [0-9]*' | sed 's/freq = //' | sort -nr | head -n 1)"
		zeshia "$gpu_freq" /proc/gpufreq/gpufreq_opp_freq
	elif [ -d /proc/gpufreqv2 ]; then
		zeshia 0 /proc/gpufreqv2/fix_target_opp_index
	fi

	# EAS/HMP Switch
	zeshia "0" /sys/devices/system/cpu/eas/enable

	# Disable GPU Power limiter
	[ -f "/proc/gpufreq/gpufreq_power_limited" ] && {
		for setting in ignore_batt_oc ignore_batt_percent ignore_low_batt ignore_thermal_protect ignore_pbm_limited; do
			zeshia "$setting 1" /proc/gpufreq/gpufreq_power_limited
		done
	}

	# Batoc battery and Power Limiter
	zeshia "0" /proc/perfmgr/syslimiter/syslimiter_force_disable
	zeshia "stop 1" /proc/mtk_batoc_throttling/battery_oc_protect_stop

	# Disable battery current limiter
	zeshia "stop 1" /proc/mtk_batoc_throttling/battery_oc_protect_stop

	# Eara Thermal
	zeshia "0" /sys/kernel/eara_thermal/enable

	# UFS Governor's
	zeshia "0" "/sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_req_ddr_opp"
	zeshia "0" "/sys/kernel/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp"
	zeshia "performance" "/sys/class/devfreq/mtk-dvfsrc-devfreq/governor"
	zeshia "performance" "/sys/devices/platform/soc/1c00f000.dvfsrc/mtk-dvfsrc-devfreq/devfreq/mtk-dvfsrc-devfreq/governor"
	
	mali_sysfs=$(find /sys/devices/platform/ -iname "*.mali" -print -quit 2>/dev/null)
	zeshia always_on "$mali_sysfs/power_policy"

}

###############################################
# # # # # # # SNAPDRAGON PERFORMANCE # # # # # # #
###############################################
snapdragon_performance() {
	# Qualcomm CPU Bus and DRAM frequencies
	for path in /sys/class/devfreq/*cpu-ddr-latfloor*; do
		zeshia "performance" $path/governor
	done &

	for path in /sys/class/devfreq/*cpu*-lat; do
		zeshia "performance" $path/governor
	done &

	for path in /sys/class/devfreq/*cpu-cpu-ddr-bw; do
		zeshia "performance" $path/governor
	done &

	for path in /sys/class/devfreq/*cpu-cpu-llcc-bw; do
		zeshia "performance" $path/governor
	done &

	if [ -d /sys/devices/system/cpu/bus_dcvs/LLCC ]; then
		freq=$(cat /sys/devices/system/cpu/bus_dcvs/LLCC/available_frequencies | tr ' ' '\n' | sort -nr | head -n 1)
		for path in /sys/devices/system/cpu/bus_dcvs/LLCC/*/max_freq; do
			zeshia $freq $path
		done &
		for path in /sys/devices/system/cpu/bus_dcvs/LLCC/*/min_freq; do
			zeshia $freq $path
		done &
	fi

	if [ -d /sys/devices/system/cpu/bus_dcvs/L3 ]; then
		freq=$(cat /sys/devices/system/cpu/bus_dcvs/L3/available_frequencies | tr ' ' '\n' | sort -nr | head -n 1)
		for path in /sys/devices/system/cpu/bus_dcvs/L3/*/max_freq; do
			zeshia $freq $path
		done &
		for path in /sys/devices/system/cpu/bus_dcvs/L3/*/min_freq; do
			zeshia $freq $path
		done &
	fi

	if [ -d /sys/devices/system/cpu/bus_dcvs/DDR ]; then
		freq=$(cat /sys/devices/system/cpu/bus_dcvs/DDR/available_frequencies | tr ' ' '\n' | sort -nr | head -n 1)
		for path in /sys/devices/system/cpu/bus_dcvs/DDR/*/max_freq; do
			zeshia $freq $path
		done &
		for path in /sys/devices/system/cpu/bus_dcvs/DDR/*/min_freq; do
			zeshia $freq $path
		done &
	fi

	if [ -d /sys/devices/system/cpu/bus_dcvs/DDRQOS ]; then
		freq=$(cat /sys/devices/system/cpu/bus_dcvs/DDRQOS/available_frequencies | tr ' ' '\n' | sort -nr | head -n 1)
		for path in /sys/devices/system/cpu/bus_dcvs/DDRQOS/*/max_freq; do
			zeshia $freq $path
		done &
		for path in /sys/devices/system/cpu/bus_dcvs/DDRQOS/*/min_freq; do
			zeshia $freq $path
		done &
	fi

	# GPU Frequency
	gpu_path="/sys/class/kgsl/kgsl-3d0/devfreq"

	if [ -d $gpu_path ]; then
		freq=$(cat $gpu_path/available_frequencies | tr ' ' '\n' | sort -nr | head -n 1)
		zeshia $freq $gpu_path/min_freq
		zeshia $freq $gpu_path/max_freq
	fi

	# GPU Bus
	for path in /sys/class/devfreq/*gpubw*; do
		zeshia "performance" $path/governor
	done &

	# Adreno Boost
	zeshia 3 /sys/class/kgsl/kgsl-3d0/devfreq/adrenoboost
}

###############################################
# # # # # # # EXYNOS PERFORMANCE # # # # # # #
###############################################
exynos_performance() {
	# GPU Frequency
	gpu_path="/sys/kernel/gpu"
	[ -d "$gpu_path" ] && {
		max_freq=$(which_maxfreq "$gpu_path/gpu_available_frequencies")
		zeshia "$max_freq" "$gpu_path/gpu_max_clock"

		if [ $LITE_MODE -eq 1 ]; then
			mid_freq=$(which_midfreq "$gpu_path/gpu_available_frequencies")
			zeshia "$mid_freq" "$gpu_path/gpu_min_clock"
		else
			zeshia "$max_freq" "$gpu_path/gpu_min_clock"
		fi
	}

	mali_sysfs=$(find /sys/devices/platform/ -iname "*.mali" -print -quit 2>/dev/null)
	zeshia always_on "$mali_sysfs/power_policy"

	# DRAM and Buses Frequency
	[ $DEVICE_MITIGATION -eq 0 ] && {
		for path in /sys/class/devfreq/*devfreq_mif*; do
			[ $LITE_MODE -eq 1 ] &&
				devfreq_mid_perf "$path" ||
				devfreq_max_perf "$path"
		done &
	}
}

###############################################
# # # # # # # UNISOC PERFORMANCE # # # # # # #
###############################################
unisoc_performance() {
	# GPU Frequency
	gpu_path=$(find /sys/class/devfreq/ -type d -iname "*.gpu" -print -quit 2>/dev/null)
	[ -n "$gpu_path" ] && {
		if [ $LITE_MODE -eq 0 ]; then
			devfreq_max_perf "$gpu_path"
		else
			devfreq_mid_perf "$gpu_path"
		fi
	}
}

###############################################
# # # # # # # TENSOR PERFORMANCE # # # # # # #
###############################################
tensor_performance() {
	# GPU Frequency
	gpu_path=$(find /sys/devices/platform/ -type d -iname "*.mali" -print -quit 2>/dev/null)
	[ -n "$gpu_path" ] && {
		max_freq=$(which_maxfreq "$gpu_path/available_frequencies")
		zeshia "$max_freq" "$gpu_path/scaling_max_freq"

		if [ $LITE_MODE -eq 1 ]; then
			mid_freq=$(which_midfreq "$gpu_path/available_frequencies")
			zeshia "$mid_freq" "$gpu_path/scaling_min_freq"
		else
			zeshia "$max_freq" "$gpu_path/scaling_min_freq"
		fi
	}

	# DRAM frequency
	[ $DEVICE_MITIGATION -eq 0 ] && {
		for path in /sys/class/devfreq/*devfreq_mif*; do
			[ $LITE_MODE -eq 1 ] &&
				devfreq_mid_perf "$path" ||
				devfreq_max_perf "$path"
		done &
	}
}

###############################################
# # # # # # # MEDIATEK POWERSAVE # # # # # # #
###############################################
mediatek_powersave() {
	# PPM Settings
	if [ -d /proc/ppm ]; then
		if [ -f /proc/ppm/policy_status ]; then
			for idx in $(grep -E 'FORCE_LIMIT|PWR_THRO|THERMAL|USER_LIMIT' /proc/ppm/policy_status | awk -F'[][]' '{print $2}'); do
				zeshia "$idx 1" "/proc/ppm/policy_status"
			done

			for dx in $(grep -E 'SYS_BOOST' /proc/ppm/policy_status | awk -F'[][]' '{print $2}'); do
				zeshia "$dx 0" "/proc/ppm/policy_status"
			done
		fi
	fi

	# UFS governor
	zeshia "0" "/sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_req_ddr_opp"
	zeshia "0" "/sys/kernel/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp"
	zeshia "powersave" "/sys/class/devfreq/mtk-dvfsrc-devfreq/governor"
	zeshia "powersave" "/sys/devices/platform/soc/1c00f000.dvfsrc/mtk-dvfsrc-devfreq/devfreq/mtk-dvfsrc-devfreq/governor"

	# GPU Power limiter - Performance mode (not for Powersave)
	[ -f "/proc/gpufreq/gpufreq_power_limited" ] && {
		for setting in ignore_batt_oc ignore_batt_percent ignore_low_batt ignore_thermal_protect ignore_pbm_limited; do
			zeshia "$setting 1" /proc/gpufreq/gpufreq_power_limited
		done

	}

	# Batoc Throttling and Power Limiter>
	zeshia "0" /proc/perfmgr/syslimiter/syslimiter_force_disable
	zeshia "stop 0" /proc/mtk_batoc_throttling/battery_oc_protect_stop
	# Enable Power Budget management for new 5.x mtk kernels
	zeshia "stop 0" /proc/pbm/pbm_stop

	# Enable battery current limiter
	zeshia "stop 0" /proc/mtk_batoc_throttling/battery_oc_protect_stop

	# Eara Thermal
	zeshia "1" /sys/kernel/eara_thermal/enable
	
	mali_sysfs=$(find /sys/devices/platform/ -iname "*.mali" -print -quit 2>/dev/null)
	zeshia coarse_demand "$mali_sysfs/power_policy"

}

###############################################
# # # # # # # SNAPDRAGON POWERSAVE # # # # # # #
###############################################
snapdragon_powersave() {
	# Qualcomm CPU Bus and DRAM frequencies
	for path in /sys/class/devfreq/*cpu-ddr-latfloor*; do
		zeshia "powersave" $path/governor
	done &

	for path in /sys/class/devfreq/*cpu*-lat; do
		zeshia "powersave" $path/governor
	done &

	for path in /sys/class/devfreq/*cpu-cpu-ddr-bw; do
		zeshia "powersave" $path/governor
	done &

	for path in /sys/class/devfreq/*cpu-cpu-llcc-bw; do
		zeshia "powersave" $path/governor
	done &

	if [ -d /sys/devices/system/cpu/bus_dcvs/LLCC ]; then
		freq=$(cat /sys/devices/system/cpu/bus_dcvs/LLCC/available_frequencies | tr ' ' '\n' | sort -n | head -n 1)
		for path in /sys/devices/system/cpu/bus_dcvs/LLCC/*/max_freq; do
			zeshia $freq $path
		done &
		for path in /sys/devices/system/cpu/bus_dcvs/LLCC/*/min_freq; do
			zeshia $freq $path
		done &
	fi

	if [ -d /sys/devices/system/cpu/bus_dcvs/L3 ]; then
		freq=$(cat /sys/devices/system/cpu/bus_dcvs/L3/available_frequencies | tr ' ' '\n' | sort -n | head -n 1)
		for path in /sys/devices/system/cpu/bus_dcvs/L3/*/max_freq; do
			zeshia $freq $path
		done &
		for path in /sys/devices/system/cpu/bus_dcvs/L3/*/min_freq; do
			zeshia $freq $path
		done &
	fi

	if [ -d /sys/devices/system/cpu/bus_dcvs/DDR ]; then
		freq=$(cat /sys/devices/system/cpu/bus_dcvs/DDR/available_frequencies | tr ' ' '\n' | sort -n | head -n 1)
		for path in /sys/devices/system/cpu/bus_dcvs/DDR/*/max_freq; do
			zeshia $freq $path
		done &
		for path in /sys/devices/system/cpu/bus_dcvs/DDR/*/min_freq; do
			zeshia $freq $path
		done &
	fi

	if [ -d /sys/devices/system/cpu/bus_dcvs/DDRQOS ]; then
		freq=$(cat /sys/devices/system/cpu/bus_dcvs/DDRQOS/available_frequencies | tr ' ' '\n' | sort -n | head -n 1)
		for path in /sys/devices/system/cpu/bus_dcvs/DDRQOS/*/max_freq; do
			zeshia $freq $path
		done &
		for path in /sys/devices/system/cpu/bus_dcvs/DDRQOS/*/min_freq; do
			zeshia $freq $path
		done &
	fi

	# GPU Frequency
	gpu_path="/sys/class/kgsl/kgsl-3d0/devfreq"

	if [ -d $gpu_path ]; then
		freq=$(cat $gpu_path/available_frequencies | tr ' ' '\n' | sort -n | head -n 2)
		zeshia $freq $gpu_path/min_freq
		zeshia $freq $gpu_path/max_freq
	fi

	# GPU Bus
	for path in /sys/class/devfreq/*gpubw*; do
		zeshia "powersave" $path/governor
	done &

	# Adreno Boost
	zeshia 0 /sys/class/kgsl/kgsl-3d0/devfreq/adrenoboost
}

###############################################
# # # # # # # EXYNOS POWERSAVE # # # # # # #
###############################################
exynos_powersave() {
	# GPU Frequency
	gpu_path="/sys/kernel/gpu"
	[ -d "$gpu_path" ] && {
		freq=$(which_minfreq "$gpu_path/gpu_available_frequencies")
		zeshia "$freq" "$gpu_path/gpu_min_clock"
		zeshia "$freq" "$gpu_path/gpu_max_clock"
	}
}

###############################################
# # # # # # # UNISOC POWERSAVE # # # # # # #
###############################################
unisoc_powersave() {
	# GPU Frequency
	gpu_path=$(find /sys/class/devfreq/ -type d -iname "*.gpu" -print -quit 2>/dev/null)
	[ -n "$gpu_path" ] && devfreq_min_perf "$gpu_path"
}

###############################################
# # # # # # # TENSOR POWERSAVE # # # # # # #
###############################################
tensor_powersave() {
	# GPU Frequency
	gpu_path=$(find /sys/devices/platform/ -type d -iname "*.mali" -print -quit 2>/dev/null)
	[ -n "$gpu_path" ] && {
		freq=$(which_minfreq "$gpu_path/available_frequencies")
		zeshia "$freq" "$gpu_path/scaling_min_freq"
		zeshia "$freq" "$gpu_path/scaling_max_freq"
	}
}

###############################################

###############################################

###############################################
###############################################
# # # # # # # PROFILESCRIPT # # # # # # #
###############################################

###############################################
# # # # # # # PERFORMANCE PROFILE! # # # # # # #
###############################################

performance_profile() {

	# Power level settings
	for pl in /sys/devices/system/cpu/perf; do
		zeshia 1 "$pl/gpu_pmu_enable"
		zeshia 1 "$pl/fuel_gauge_enable"
		zeshia 1 "$pl/enable"
		zeshia 1 "$pl/charger_enable"
	done

	# Set DND Mode
	if [ "$(getprop persist.sys.azenithconf.dnd)" -eq 1 ]; then
		cmd notification set_dnd priority && dlog "DND enabled" || dlog "Failed to enable DND"
	fi

	if [ "$(getprop persist.sys.azenithconf.bypasschg)" -eq 1 ]; then
		sys.azenith-utilityconf enableBypass
		dlog "Bypass Charge Enabled"
	fi

	clear_background_apps() {

		# Get the list of running apps sorted by CPU usage (excluding system processes and the script itself)
		app_list=$(top -n 1 -o %CPU | awk 'NR>7 {print $1}' | while read -r pid; do
			pkg=$(cmd package list packages -U | awk -v pid="$pid" '$2 == pid {print $1}' | cut -d':' -f2)
			if [ -n "$pkg" ] && ! echo "$pkg" | grep -qE "com.android.systemui|com.android.settings|$(basename "$0")"; then
				echo "$pkg"
			fi
		done)

		# Kill apps in order of highest CPU usage
		for app in $app_list; do
			am force-stop "$app"
			AZLog "Stopped app: $app"
		done

		# force stop
		am force-stop com.instagram.android
		am force-stop com.android.vending
		am force-stop app.grapheneos.camera
		am force-stop com.google.android.gm
		am force-stop com.google.android.apps.youtube.creator
		am force-stop com.dolby.ds1appUI
		am force-stop com.google.android.youtube
		am force-stop com.twitter.android
		am force-stop nekox.messenger
		am force-stop com.shopee.id
		am force-stop com.vanced.android.youtube
		am force-stop com.speedsoftware.rootexplorer
		am force-stop com.bukalapak.android
		am force-stop org.telegram.messenger
		am force-stop ru.zdevs.zarchiver
		am force-stop com.android.chrome
		am force-stop com.whatsapp.messenger
		am force-stop com.google.android.GoogleCameraEng
		am force-stop com.facebook.orca
		am force-stop com.lazada.android
		am force-stop com.android.camera
		am force-stop com.android.settings
		am force-stop com.franco.kernel
		am force-stop com.telkomsel.telkomselcm
		am force-stop com.facebook.katana
		am force-stop com.instagram.android
		am force-stop com.facebook.lite
		am kill-all

		dlog "Cleared background apps"
	}
	if [ "$(getprop persist.sys.azenithconf.clearbg)" -eq 1 ]; then
		clear_background_apps $
	fi

	# Load Default Governor
	load_default_governor() {
		if [ -n "$(getprop persist.sys.azenith.custom_default_cpu_gov)" ]; then
			getprop persist.sys.azenith.custom_default_cpu_gov
		elif [ -n "$(getprop persist.sys.azenith.default_cpu_gov)" ]; then
			getprop persist.sys.azenith.default_cpu_gov
		else
			echo "schedutil"
		fi
	}

	# Load Default I/O Scheduler
	load_default_iosched() {
		if [ -n "$(getprop persist.sys.azenith.custom_default_balanced_IO)" ]; then
			getprop persist.sys.azenith.custom_default_balanced_IO
		elif [ -n "$(getprop persist.sys.azenith.default_balanced_IO)" ]; then
			getprop persist.sys.azenith.default_balanced_IO
		else
			echo "none"
		fi
	}

	# Apply Game Governor
	default_cpu_gov=$(load_default_governor)
	if [ "$(getprop persist.sys.azenithconf.cpulimit)" -eq 0 ]; then
		setgov "performance" && dlog "Applying governor to : performance"
	else
		setgov "$default_cpu_gov" && dlog "Applying governor to : $default_cpu_gov"
	fi

	# Apply Game I/O Scheduler
	default_iosched=$(load_default_iosched)
	if [ -n "$(getprop persist.sys.azenith.custom_performance_IO)" ]; then
		game_iosched=$(getprop persist.sys.azenith.custom_performance_IO)
		setsIO "$game_iosched" && dlog "Applying I/O scheduler to : $game_iosched"
	else
		setsIO "$default_iosched" && dlog "Applying I/O scheduler to : $default_iosched"
	fi

	# Fix Target OPP Index
	[ -d /proc/ppm ] && setgamefreqppm || setgamefreq
	dlog "Set CPU freq to max available Frequencies"

	# VM Cache Pressure
	zeshia "40" "/proc/sys/vm/vfs_cache_pressure"
	zeshia "3" "/proc/sys/vm/drop_caches"

	# Workqueue settings
	zeshia "N" /sys/module/workqueue/parameters/power_efficient
	zeshia "N" /sys/module/workqueue/parameters/disable_numa
	zeshia "0" /sys/kernel/eara_thermal/enable
	zeshia "0" /sys/devices/system/cpu/eas/enable
	zeshia "1" /sys/devices/system/cpu/cpu2/online
	zeshia "1" /sys/devices/system/cpu/cpu3/online

	# Schedtune Settings
	for path in /dev/stune/*; do
		base=$(basename "$path")
		if [[ "$base" == "top-app" || "$base" == "foreground" ]]; then
			zeshia 30 "$path/schedtune.boost"
			zeshia 1 "$path/schedtune.sched_boost_enabled"
		else
			zeshia 30 "$path/schedtune.boost"
			zeshia 1 "$path/schedtune.sched_boost_enabled"
		fi
		zeshia 0 "$path/schedtune.prefer_idle"
		zeshia 0 "$path/schedtune.colocate"
	done

	# Power level settings
	for pl in /sys/devices/system/cpu/perf; do
		zeshia 1 "$pl/gpu_pmu_enable"
		zeshia 1 "$pl/fuel_gauge_enable"
		zeshia 1 "$pl/enable"
		zeshia 1 "$pl/charger_enable"
	done

	# CPU max tune percent
	zeshia 1 /proc/sys/kernel/perf_cpu_time_max_percent

	# Sched Energy Aware
	zeshia 1 /proc/sys/kernel/sched_energy_aware

	# CPU Core control Boost
	for cpucore in /sys/devices/system/cpu/cpu*; do
		zeshia 0 "$cpucore/core_ctl/enable"
		zeshia 0 "$cpucore/core_ctl/core_ctl_boost"
	done

	# Disable battery saver module
	[ -f /sys/module/battery_saver/parameters/enabled ] && {
		if grep -qo '[0-9]\+' /sys/module/battery_saver/parameters/enabled; then
			zeshia 0 /sys/module/battery_saver/parameters/enabled
		else
			zeshia N /sys/module/battery_saver/parameters/enabled
		fi
	}

	# Disable split lock mitigation
	zeshia 0 /proc/sys/kernel/split_lock_mitigate

	# Schedfeatures settings
	if [ -f "/sys/kernel/debug/sched_features" ]; then
		zeshia NEXT_BUDDY /sys/kernel/debug/sched_features
		zeshia NO_TTWU_QUEUE /sys/kernel/debug/sched_features
	fi

	if [ "$(getprop persist.sys.azenithconf.scale)" -eq 1 ]; then
		hg=$(getprop persist.sys.azenithconf.hgsize)
		wd=$(getprop persist.sys.azenithconf.wdsize)
		wm size "$wd"x"$hg"
	fi

	if [ "$(getprop persist.sys.azenithconf.cpulimit)" -eq 0 ]; then
		case "$(getprop persist.sys.azenithdebug.soctype)" in
		1) mediatek_performance ;;
		2) snapdragon_performance ;;
		3) exynos_performance ;;
		4) unisoc_performance ;;
		5) tensor_performance ;;
		esac
	fi

	AZLog "Performance Profile Applied Successfully!"

}

###############################################
# # # # # # #  BALANCED PROFILES! # # # # # # #
###############################################
balanced_profile() {
	# Load Default Governor
	load_default_governor() {
		if [ -n "$(getprop persist.sys.azenith.custom_default_cpu_gov)" ]; then
			getprop persist.sys.azenith.custom_default_cpu_gov
		elif [ -n "$(getprop persist.sys.azenith.default_cpu_gov)" ]; then
			getprop persist.sys.azenith.default_cpu_gov
		else
			echo "schedutil"
		fi
	}

	# Load Default I/O Scheduler
	load_default_iosched() {
		if [ -n "$(getprop persist.sys.azenith.custom_default_balanced_IO)" ]; then
			getprop persist.sys.azenith.custom_default_balanced_IO
		elif [ -n "$(getprop persist.sys.azenith.default_balanced_IO)" ]; then
			getprop persist.sys.azenith.default_balanced_IO
		else
			echo "none"
		fi
	}

	# Load default cpu governor
	default_cpu_gov=$(load_default_governor)

	# Load default I/O scheduler
	default_iosched=$(load_default_iosched)

	# Power level settings
	for pl in /sys/devices/system/cpu/perf; do
		zeshia 0 "$pl/gpu_pmu_enable"
		zeshia 0 "$pl/fuel_gauge_enable"
		zeshia 0 "$pl/enable"
		zeshia 1 "$pl/charger_enable"
	done

	# Disable DND
	if [ "$(getprop persist.sys.azenithconf.dnd)" -eq 1 ]; then
		cmd notification set_dnd off && dlog "DND disabled" || dlog "Failed to disable DND"
	fi

	if [ "$(getprop persist.sys.azenithconf.bypasschg)" -eq 1 ]; then
		sys.azenith-utilityconf disableBypass
		dlog "Bypass Charge Disabled"
	fi

	# Restore CPU Scaling Governor
	setgov "$default_cpu_gov"
	dlog "Applying governor to : $default_cpu_gov"

	# Restore I/O Scheduler
	setsIO "$default_iosched"
	dlog "Applying I/O scheduler to : $default_iosched"

	# Limit cpu freq
	[ -d /proc/ppm ] && setfreqppm || setfreq
	dlog "Set CPU freq to normal Frequencies"

	# vm cache pressure
	zeshia "120" "/proc/sys/vm/vfs_cache_pressure"

	# Workqueue settings
	zeshia "Y" /sys/module/workqueue/parameters/power_efficient
	zeshia "Y" /sys/module/workqueue/parameters/disable_numa
	zeshia "1" /sys/kernel/eara_thermal/enable
	zeshia "1" /sys/devices/system/cpu/eas/enable

	for path in /dev/stune/*; do
		base=$(basename "$path")
		if [[ "$base" == "top-app" || "$base" == "foreground" ]]; then
			zeshia 0 "$path/schedtune.boost"
			zeshia 0 "$path/schedtune.sched_boost_enabled"
		else
			zeshia 0 "$path/schedtune.boost"
			zeshia 0 "$path/schedtune.sched_boost_enabled"
		fi
		zeshia 0 "$path/schedtune.prefer_idle"
		zeshia 0 "$path/schedtune.colocate"
	done

	# Power level settings
	for pl in /sys/devices/system/cpu/perf; do
		zeshia 0 "$pl/gpu_pmu_enable"
		zeshia 0 "$pl/fuel_gauge_enable"
		zeshia 0 "$pl/enable"
		zeshia 1 "$pl/charger_enable"
	done

	# CPU Max Time Percent
	zeshia 100 /proc/sys/kernel/perf_cpu_time_max_percent

	zeshia 2 /proc/sys/kernel/perf_cpu_time_max_percent
	# Sched Energy Aware
	zeshia 1 /proc/sys/kernel/sched_energy_aware

	for cpucore in /sys/devices/system/cpu/cpu*; do
		zeshia 0 "$cpucore/core_ctl/enable"
		zeshia 0 "$cpucore/core_ctl/core_ctl_boost"
	done

	#  Disable battery saver module
	[ -f /sys/module/battery_saver/parameters/enabled ] && {
		if grep -qo '[0-9]\+' /sys/module/battery_saver/parameters/enabled; then
			zeshia 0 /sys/module/battery_saver/parameters/enabled
		else
			zeshia N /sys/module/battery_saver/parameters/enabled
		fi
	}

	#  Enable split lock mitigation
	zeshia 1 /proc/sys/kernel/split_lock_mitigate

	if [ -f "/sys/kernel/debug/sched_features" ]; then
		#  Consider scheduling tasks that are eager to run
		zeshia NEXT_BUDDY /sys/kernel/debug/sched_features
		#  Schedule tasks on their origin CPU if possible
		zeshia TTWU_QUEUE /sys/kernel/debug/sched_features
	fi

	if [ "$(getprop persist.sys.azenithconf.scale)" -eq 1 ]; then
		wm size reset
	fi

	if [ "$(getprop persist.sys.azenithconf.cpulimit)" -eq 0 ]; then
		case "$(getprop persist.sys.azenithdebug.soctype)" in
		1) mediatek_balance ;;
		2) snapdragon_balance ;;
		3) exynos_balance ;;
		4) unisoc_balance ;;
		5) tensor_balance ;;
		esac
	fi

	AZLog "Balanced Profile applied successfully!"

}

###############################################
# # # # # # # POWERSAVE PROFILE # # # # # # #
###############################################

eco_mode() {
	# Load Powersave Governor
	load_powersave_governor() {
		if [ -n "$(getprop persist.sys.azenith.custom_powersave_cpu_gov)" ]; then
			getprop persist.sys.azenith.custom_powersave_cpu_gov
		else
			echo "powersave"
		fi
	}
	powersave_cpu_gov=$(load_powersave_governor)

	# Apply Powersave CPU Governor
	setgov "$powersave_cpu_gov"
	dlog "Applying governor to : $powersave_cpu_gov"

	# Load Powersave I/O Scheduler
	load_powersave_iosched() {
		if [ -n "$(getprop persist.sys.azenith.custom_powersave_IO)" ]; then
			getprop persist.sys.azenith.custom_powersave_IO
		else
			echo "none"
		fi
	}
	powersave_iosched=$(load_powersave_iosched)
	setsIO "$powersave_iosched"
	dlog "Applying I/O scheduler to : $powersave_iosched"

	# Power level settings
	for pl in /sys/devices/system/cpu/perf; do
		zeshia 0 "$pl/gpu_pmu_enable"
		zeshia 0 "$pl/fuel_gauge_enable"
		zeshia 0 "$pl/enable"
		zeshia 1 "$pl/charger_enable"
	done

	# Disable DND
	if [ "$(getprop persist.sys.azenithconf.dnd)" -eq 1 ]; then
		cmd notification set_dnd off && dlog "DND disabled" || dlog "Failed to disable DND"
	fi

	if [ "$(getprop persist.sys.azenithconf.bypasschg)" -eq 1 ]; then
		sys.azenith-utilityconf disableBypass
		dlog "Bypass Charge Disabled"
	fi

	# Limit cpu freq
	[ -d /proc/ppm ] && setfreqppm || setfreq
	dlog "Set CPU freq to low Frequencies"

	# VM Cache Pressure
	zeshia "120" "/proc/sys/vm/vfs_cache_pressure"

	zeshia 0 /proc/sys/kernel/perf_cpu_time_max_percent
	zeshia 0 /proc/sys/kernel/sched_energy_aware

	#  Enable battery saver module
	[ -f /sys/module/battery_saver/parameters/enabled ] && {
		if grep -qo '[0-9]\+' /sys/module/battery_saver/parameters/enabled; then
			zeshia 1 /sys/module/battery_saver/parameters/enabled
		else
			zeshia Y /sys/module/battery_saver/parameters/enabled
		fi
	}

	# Schedfeature settings
	if [ -f "/sys/kernel/debug/sched_features" ]; then
		zeshia NO_NEXT_BUDDY /sys/kernel/debug/sched_features
		zeshia NO_TTWU_QUEUE /sys/kernel/debug/sched_features
	fi

	case "$(getprop persist.sys.azenithdebug.soctype)" in
	1) mediatek_powersave ;;
	2) snapdragon_powersave ;;
	3) exynos_powersave ;;
	4) unisoc_powersave ;;
	5) tensor_powersave ;;
	esac

	AZLog "ECO Mode applied successfully!"

}

###############################################
# # # # # # # INITIALIZE # # # # # # #
###############################################

initialize() {

	# Disable all kernel panic mechanisms
	for param in hung_task_timeout_secs panic_on_oom panic_on_oops panic softlockup_panic; do
		zeshia "0" "/proc/sys/kernel/$param"
	done

	# Tweaking scheduler to reduce latency
	zeshia 500000 /proc/sys/kernel/sched_migration_cost_ns
	zeshia 1000000 /proc/sys/kernel/sched_min_granularity_ns
	zeshia 500000 /proc/sys/kernel/sched_wakeup_granularity_ns
	# Disable read-ahead for swap devices
	zeshia 0 /proc/sys/vm/page-cluster
	# Update /proc/stat less often to reduce jitter
	zeshia 20 /proc/sys/vm/stat_interval
	# Disable compaction_proactiveness
	zeshia 0 /proc/sys/vm/compaction_proactiveness
	zeshia 255 /proc/sys/kernel/sched_lib_mask_force

	CPU="/sys/devices/system/cpu/cpu0/cpufreq"
	chmod 644 "$CPU/scaling_governor"
	default_gov=$(cat "$CPU/scaling_governor")
	setprop persist.sys.azenith.default_cpu_gov "$default_gov"
	dlog "Default CPU governor detected: $default_gov"

	# Fallback if default is performance
	if [ "$default_gov" == "performance" ] && [ -z "$(getprop persist.sys.azenith.custom_default_cpu_gov)" ]; then
		dlog "Default governor is 'performance'"
		for gov in scx schedhorizon walt sched_pixel sugov_ext uag schedplus energy_step ondemand schedutil interactive conservative powersave; do
			if grep -q "$gov" "$CPU/scaling_available_governors"; then
				setprop persist.sys.azenith.default_cpu_gov "$gov"
				default_gov="$gov"
				dlog "Fallback governor to: $gov"
				break
			fi
		done
	fi

	# Revert to custom default if exists
	[ -n "$(getprop persist.sys.azenith.custom_default_cpu_gov)" ] && default_gov=$(getprop persist.sys.azenith.custom_default_cpu_gov)
	dlog "Using CPU governor: $default_gov"

	chmod 644 /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	echo "$default_gov" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
	chmod 444 /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	chmod 444 /sys/devices/system/cpu/cpufreq/policy*/scaling_governor
	[ -z "$(getprop persist.sys.azenith.custom_powersave_cpu_gov)" ] && setprop persist.sys.azenith.custom_powersave_cpu_gov "$default_gov"
	dlog "Parsing CPU Governor complete"

	IO="/sys/block/sda/queue"
	chmod 644 "$IO/scheduler"
	default_io=$(grep -o '\[.*\]' "$IO/scheduler" | tr -d '[]')
	setprop persist.sys.azenith.default_balanced_IO "$default_io"
	dlog "Default IO Scheduler detected: $default_io"

	# Set Default IO Scheduler
	[ -n "$(getprop persist.sys.azenith.custom_default_balanced_IO)" ] && default_io=$(getprop persist.sys.azenith.custom_default_balanced_IO)
	chmod 644 /sys/block/sda/queue/scheduler
	echo "$default_io" | tee /sys/block/sda/queue/scheduler >/dev/null
	chmod 444 /sys/block/sda/queue/scheduler
	[ -z "$(getprop persist.sys.azenith.custom_powersave_IO)" ] && setprop persist.sys.azenith.custom_powersave_IO "$default_io"
	[ -z "$(getprop persist.sys.azenith.custom_performance_IO)" ] && setprop persist.sys.azenith.custom_performance_IO "$default_io"
	dlog "Parsing IO Scheduler complete"

	RESO_PROP="persist.sys.azenithconf.resosettings"
	RESO=$(wm size | grep -oE "[0-9]+x[0-9]+" | head -n 1)

	if [ -z "$(getprop $RESO_PROP)" ]; then
		if [ -n "$RESO" ]; then
			setprop "$RESO_PROP" "$RESO"
			dlog "Detected resolution: $RESO"
			dlog "Property $RESO_PROP set successfully"
		else
			dlog "Failed to detect physical resolution"
		fi
	fi

	if [ "$(getprop persist.sys.azenithconf.schemeconfig)" != "1000 1000 1000 1000" ]; then
		# Restore saved display boost
		val=$(getprop persist.sys.azenithconf.schemeconfig)
		r=$(echo $val | awk '{print $1}')
		g=$(echo $val | awk '{print $2}')
		b=$(echo $val | awk '{print $3}')
		s=$(echo $val | awk '{print $4}')
		rf=$(awk "BEGIN {print $r/1000}")
		gf=$(awk "BEGIN {print $g/1000}")
		bf=$(awk "BEGIN {print $b/1000}")
		sf=$(awk "BEGIN {print $s/1000}")
		service call SurfaceFlinger 1015 i32 1 f $rf f 0 f 0 f 0 f 0 f $gf f 0 f 0 f 0 f 0 f $bf f 0 f 0 f 0 f 0 f 1
		service call SurfaceFlinger 1022 f $sf
	fi

	jit() {
		for app in $(cmd package list packages | cut -f 2 -d ":"); do
			{
				echo "$app | $(cmd package compile -m speed-profile "$app")"
				AZLog "$app | Success"
			} &
		done
		disown
	}

	schedtunes() {
		settunes() {
			local policy_path="$1"

			# Check if the policy path exists
			if [ ! -d "$policy_path" ]; then
				AZLog "Skipped: $policy_path (not available)"
				return
			fi

			# Read available frequencies
			local available_freqs=$(cat "$policy_path/scaling_available_frequencies" 2>/dev/null)
			if [ -z "$available_freqs" ]; then
				AZLog "Skipped: No available frequencies for $policy_path"
				return
			fi

			# Select the 6 highest frequencies
			local selected_freqs=$(echo "$available_freqs" | tr ' ' '\n' | sort -rn | head -n 6 | tr '\n' ' ' | sed 's/ $//')

			# Generate up_delay values dynamically
			local num_freqs=$(echo "$selected_freqs" | wc -w)
			local up_delay=""
			for i in $(seq 1 $num_freqs); do
				up_delay="$up_delay $((50 * i))"
			done
			up_delay=$(echo "$up_delay" | sed 's/^ //')

			# Define universal rate values
			local up_rate=7500
			local down_rate=14000

			# Check for schedhorizon and schedutil paths
			local schedhorizon_path="$policy_path/schedhorizon"
			local schedutil_path="$policy_path/schedutil"

			if [ -d "$schedhorizon_path" ]; then
				zeshia "$up_delay" "$schedhorizon_path/up_delay"
				zeshia "$selected_freqs" "$schedhorizon_path/efficient_freq"
				zeshia "$up_rate" "$schedhorizon_path/up_rate_limit_us"
				zeshia "$down_rate" "$schedhorizon_path/down_rate_limit_us"
			fi

			if [ -d "$schedutil_path" ]; then
				zeshia "$up_rate" "$schedutil_path/up_rate_limit_us"
				zeshia "$down_rate" "$schedutil_path/down_rate_limit_us"
			fi
		}
		for policy in /sys/devices/system/cpu/cpufreq/policy*; do
			settunes "$policy"
		done
	}

	fpsgoandgedparams() {
		# GED parameters
		ged_params="ged_smart_boost 1
boost_upper_bound 100
enable_gpu_boost 1
enable_cpu_boost 1
ged_boost_enable 1
boost_gpu_enable 1
gpu_dvfs_enable 1
gx_frc_mode 1
gx_dfps 1
gx_force_cpu_boost 1
gx_boost_on 1
gx_game_mode 1
gx_3D_benchmark_on 1
gpu_loading 0
cpu_boost_policy 1
boost_extra 1
is_GED_KPI_enabled 0"

		zeshia "$ged_params" | while read -r param value; do
			zeshia "$value" "/sys/module/ged/parameters/$param"
		done

		# FPSGO Configuration Tweaks
		zeshia "0" /sys/kernel/fpsgo/fbt/boost_ta
		zeshia "1" /sys/kernel/fpsgo/fbt/enable_switch_down_throttle
		zeshia "1" /sys/kernel/fpsgo/fstb/adopt_low_fps
		zeshia "1" /sys/kernel/fpsgo/fstb/fstb_self_ctrl_fps_enable
		zeshia "0" /sys/kernel/fpsgo/fstb/boost_ta
		zeshia "1" /sys/kernel/fpsgo/fstb/enable_switch_sync_flag
		zeshia "0" /sys/kernel/fpsgo/fbt/boost_VIP
		zeshia "1" /sys/kernel/fpsgo/fstb/gpu_slowdown_check
		zeshia "1" /sys/kernel/fpsgo/fbt/thrm_limit_cpu
		zeshia "0" /sys/kernel/fpsgo/fbt/thrm_temp_th
		zeshia "0" /sys/kernel/fpsgo/fbt/llf_task_policy
		zeshia "100" /sys/module/mtk_fpsgo/parameters/uboost_enhance_f
		zeshia "0" /sys/module/mtk_fpsgo/parameters/isolation_limit_cap
		zeshia "1" /sys/pnpmgr/fpsgo_boost/boost_enable
		zeshia "1" /sys/pnpmgr/fpsgo_boost/boost_mode
		zeshia "1" /sys/pnpmgr/install
		zeshia "100" /sys/kernel/ged/hal/gpu_boost_level

	}

	malisched() {
		# GPU Mali Scheduling
		mali_dir=$(ls -d /sys/devices/platform/soc/*mali*/scheduling 2>/dev/null | head -n 1)
		mali1_dir=$(ls -d /sys/devices/platform/soc/*mali* 2>/dev/null | head -n 1)
		if [ -n "$mali_dir" ]; then
			zeshia "full" "$mali_dir/serialize_jobs"
		fi
		if [ -n "$mali1_dir" ]; then
			zeshia "1" "$mali1_dir/js_ctx_scheduling_mode"
		fi
	}

	SFL() {
		get_stable_refresh_rate() {
			i=0
			while [ $i -lt 5 ]; do
				period=$(dumpsys SurfaceFlinger --latency 2>/dev/null | head -n1 | awk 'NR==1 {print $1}')
				case $period in
				'' | *[!0-9]*) ;;
				*)
					if [ "$period" -gt 0 ]; then
						rate=$(((1000000000 + (period / 2)) / period))
						if [ "$rate" -ge 30 ] && [ "$rate" -le 240 ]; then
							samples="$samples $rate"
						fi
					fi
					;;
				esac
				i=$((i + 1))
				sleep 0.05
			done

			if [ -z "$samples" ]; then
				echo 60
				return
			fi

			sorted=$(echo "$samples" | tr ' ' '\n' | sort -n)
			count=$(echo "$sorted" | wc -l)
			mid=$((count / 2))

			if [ $((count % 2)) -eq 1 ]; then
				median=$(echo "$sorted" | sed -n "$((mid + 1))p")
			else
				val1=$(echo "$sorted" | sed -n "$mid p")
				val2=$(echo "$sorted" | sed -n "$((mid + 1))p")
				median=$(((val1 + val2) / 2))
			fi

			echo "$median"
		}
		refresh_rate=$(get_stable_refresh_rate)

		frame_duration_ns=$(awk -v r="$refresh_rate" 'BEGIN { printf "%.0f", 1000000000 / r }')

		calculate_dynamic_margin() {
			base_margin=0.07
			cpu_load=$(top -n 1 -b 2>/dev/null | grep "Cpu(s)" | awk '{print $2 + $4}')
			margin=$base_margin
			awk -v load="$cpu_load" -v base="$base_margin" 'BEGIN {
			if (load > 70) {
				print base + 0.01
			} else {
				print base
			}
		}'
		}

		margin_ratio=$(calculate_dynamic_margin)
		min_margin=$(awk -v fd="$frame_duration_ns" -v m="$margin_ratio" 'BEGIN { printf "%.0f", fd * m }')

		if [ "$refresh_rate" -ge 120 ]; then
			app_phase_ratio=0.68
			sf_phase_ratio=0.85
			app_duration_ratio=0.58
			sf_duration_ratio=0.32
		elif [ "$refresh_rate" -ge 90 ]; then
			app_phase_ratio=0.66
			sf_phase_ratio=0.82
			app_duration_ratio=0.60
			sf_duration_ratio=0.30
		elif [ "$refresh_rate" -ge 75 ]; then
			app_phase_ratio=0.64
			sf_phase_ratio=0.80
			app_duration_ratio=0.62
			sf_duration_ratio=0.28
		else
			app_phase_ratio=0.62
			sf_phase_ratio=0.75
			app_duration_ratio=0.65
			sf_duration_ratio=0.25
		fi

		app_phase_offset_ns=$(awk -v fd="$frame_duration_ns" -v r="$app_phase_ratio" 'BEGIN { printf "%.0f", -fd * r }')
		sf_phase_offset_ns=$(awk -v fd="$frame_duration_ns" -v r="$sf_phase_ratio" 'BEGIN { printf "%.0f", -fd * r }')

		app_duration=$(awk -v fd="$frame_duration_ns" -v r="$app_duration_ratio" 'BEGIN { printf "%.0f", fd * r }')
		sf_duration=$(awk -v fd="$frame_duration_ns" -v r="$sf_duration_ratio" 'BEGIN { printf "%.0f", fd * r }')

		app_end_time=$(awk -v offset="$app_phase_offset_ns" -v dur="$app_duration" 'BEGIN { print offset + dur }')
		dead_time=$(awk -v app_end="$app_end_time" -v sf_offset="$sf_phase_offset_ns" 'BEGIN { print -(app_end + sf_offset) }')

		adjust_needed=$(awk -v dt="$dead_time" -v mm="$min_margin" 'BEGIN { print (dt < mm) ? 1 : 0 }')
		if [ "$adjust_needed" -eq 1 ]; then
			adjustment=$(awk -v mm="$min_margin" -v dt="$dead_time" 'BEGIN { print mm - dt }')
			new_app_duration=$(awk -v app_dur="$app_duration" -v adj="$adjustment" 'BEGIN { res = app_dur - adj; print (res > 0) ? res : 0 }')
			echo "Optimization: Adjusted app duration by -${adjustment}ns for dynamic margin"
			app_duration=$new_app_duration
		fi

		min_phase_duration=$(awk -v fd="$frame_duration_ns" 'BEGIN { printf "%.0f", fd * 0.12 }')

		app_too_short=$(awk -v dur="$app_duration" -v min="$min_phase_duration" 'BEGIN { print (dur < min) ? 1 : 0 }')
		if [ "$app_too_short" -eq 1 ]; then
			app_duration=$min_phase_duration
		fi

		sf_too_short=$(awk -v dur="$sf_duration" -v min="$min_phase_duration" 'BEGIN { print (dur < min) ? 1 : 0 }')
		if [ "$sf_too_short" -eq 1 ]; then
			sf_duration=$min_phase_duration
		fi

		resetprop -n debug.sf.early.app.duration "$app_duration"
		resetprop -n debug.sf.earlyGl.app.duration "$app_duration"
		resetprop -n debug.sf.late.app.duration "$app_duration"

		resetprop -n debug.sf.early.sf.duration "$sf_duration"
		resetprop -n debug.sf.earlyGl.sf.duration "$sf_duration"
		resetprop -n debug.sf.late.sf.duration "$sf_duration"

		resetprop -n debug.sf.early_app_phase_offset_ns "$app_phase_offset_ns"
		resetprop -n debug.sf.high_fps_early_app_phase_offset_ns "$app_phase_offset_ns"
		resetprop -n debug.sf.high_fps_late_app_phase_offset_ns "$app_phase_offset_ns"
		resetprop -n debug.sf.early_phase_offset_ns "$sf_phase_offset_ns"
		resetprop -n debug.sf.high_fps_early_phase_offset_ns "$sf_phase_offset_ns"
		resetprop -n debug.sf.high_fps_late_sf_phase_offset_ns "$sf_phase_offset_ns"
		if [ "$refresh_rate" -ge 120 ]; then
			threshold_ratio=0.28
		elif [ "$refresh_rate" -ge 90 ]; then
			threshold_ratio=0.32
		elif [ "$refresh_rate" -ge 75 ]; then
			threshold_ratio=0.35
		else
			threshold_ratio=0.38
		fi

		phase_offset_threshold_ns=$(awk -v fd="$frame_duration_ns" -v tr="$threshold_ratio" 'BEGIN { printf "%.0f", fd * tr }')

		max_threshold=$(awk -v fd="$frame_duration_ns" 'BEGIN { printf "%.0f", fd * 0.45 }')
		min_threshold=$(awk -v fd="$frame_duration_ns" 'BEGIN { printf "%.0f", fd * 0.22 }')

		phase_offset_threshold_ns=$(awk -v val="$phase_offset_threshold_ns" -v max="$max_threshold" -v min="$min_threshold" '
		BEGIN {
			if (val > max) {
				print max
			} else if (val < min) {
				print min
			} else {
				print val
			}
		}')

		resetprop -n debug.sf.phase_offset_threshold_for_next_vsync_ns "$phase_offset_threshold_ns"

		resetprop -n debug.sf.enable_advanced_sf_phase_offset 1
		resetprop -n debug.sf.predict_hwc_composition_strategy 1
		resetprop -n debug.sf.use_phase_offsets_as_durations 1
		resetprop -n debug.sf.disable_hwc_vds 1
		resetprop -n debug.sf.show_refresh_rate_overlay_spinner 0
		resetprop -n debug.sf.show_refresh_rate_overlay_render_rate 0
		resetprop -n debug.sf.show_refresh_rate_overlay_in_middle 0
		resetprop -n debug.sf.kernel_idle_timer_update_overlay 0
		resetprop -n debug.sf.dump.enable 0
		resetprop -n debug.sf.dump.external 0
		resetprop -n debug.sf.dump.primary 0
		resetprop -n debug.sf.treat_170m_as_sRGB 0
		resetprop -n debug.sf.luma_sampling 0
		resetprop -n debug.sf.showupdates 0
		resetprop -n debug.sf.disable_client_composition_cache 0
		resetprop -n debug.sf.treble_testing_override false
		resetprop -n debug.sf.enable_layer_caching false
		resetprop -n debug.sf.enable_cached_set_render_scheduling true
		resetprop -n debug.sf.layer_history_trace false
		resetprop -n debug.sf.edge_extension_shader false
		resetprop -n debug.sf.enable_egl_image_tracker false
		resetprop -n debug.sf.use_phase_offsets_as_durations false
		resetprop -n debug.sf.layer_caching_highlight false
		resetprop -n debug.sf.enable_hwc_vds false
		resetprop -n debug.sf.vsp_trace false
		resetprop -n debug.sf.enable_transaction_tracing false
		resetprop -n debug.hwui.filter_test_overhead false
		resetprop -n debug.hwui.show_layers_updates false
		resetprop -n debug.hwui.capture_skp_enabled false
		resetprop -n debug.hwui.trace_gpu_resources false
		resetprop -n debug.hwui.skia_tracing_enabled false
		resetprop -n debug.hwui.nv_profiling false
		resetprop -n debug.hwui.skia_use_perfetto_track_events false
		resetprop -n debug.hwui.show_dirty_regions false
		resetprop -n debug.hwui.profile false
		resetprop -n debug.hwui.overdraw false
		resetprop -n debug.hwui.show_non_rect_clip hide
		resetprop -n debug.hwui.webview_overlays_enabled false
		resetprop -n debug.hwui.skip_empty_damage true
		resetprop -n debug.hwui.use_gpu_pixel_buffers true
		resetprop -n debug.hwui.use_buffer_age true
		resetprop -n debug.hwui.use_partial_updates true
		resetprop -n debug.hwui.skip_eglmanager_telemetry true
		resetprop -n debug.hwui.level 0

	}

	DThermal() {

		propfile() {
			while read -r key value; do
				resetprop -n "$key" "$value"
				echo "[$(date)] Reset $key to $value"
			done <<EOF
debug.thermal.throttle.support no
ro.vendor.mtk_thermal_2_0 0
persist.thermal_config.mitigation 0
ro.mtk_thermal_monitor.enabled false
ro.vendor.tran.hbm.thermal.temp.clr 49000
ro.vendor.tran.hbm.thermal.temp.trig 46000
vendor.thermal.link_ready 0
dalvik.vm.dexopt.thermal-cutoff 0
persist.vendor.thermal.engine.enable 0
persist.vendor.thermal.config 0
EOF
		}

		thermal() {
			find /system/etc/init /vendor/etc/init /odm/etc/init -type f 2>/dev/null | xargs grep -h "^service" | awk '{print $2}' | grep thermal
		}

		for svc in $(thermal); do
			stop "$svc"
		done

		# Freeze all running thermal processes
		for pid in $(pgrep thermal); do
			kill -SIGSTOP "$pid"
		done

		# Clear init.svc_ properties only if they exist
		for prop in $(getprop | awk -F '[][]' '/init\.svc_/ {print $2}'); do
			if [ -n "$prop" ]; then
				resetprop -n "$prop" ""
			fi
		done

		for dead in \
			android.hardware.thermal-service.mediatek android.hardware.thermal@2.0-service.mtk; do
			stop "$dead"
			pid=$(pidof "$dead")
			if [ -n "$pid" ]; then
				kill -SIGSTOP "$pid"
			fi
		done

		# Disable thermal zones
		chmod 644 /sys/class/thermal/thermal_zone*/mode
		for zone in /sys/class/thermal/thermal_zone*/mode; do
			[ -f "$zone" ] && echo "disabled" >"$zone"
		done

		for zone2 in /sys/class/thermal/thermal_zone*/policy; do
			[ -f "$zone2" ] && echo "userspace" >"$zone2"
		done

		# Disable GPU Power Limitations
		if [ -f "/proc/gpufreq/gpufreq_power_limited" ]; then
			for setting in ignore_batt_oc ignore_batt_percent ignore_low_batt ignore_thermal_protect ignore_pbm_limited; do
				echo "$setting 1" >/proc/gpufreq/gpufreq_power_limited
			done
		fi

		# Set CPU limits based on max frequency
		if [ -f /sys/devices/virtual/thermal/thermal_message/cpu_limits ]; then
			for cpu in 0 2 4 6 7; do
				maxfreq_path="/sys/devices/system/cpu/cpu$cpu/cpufreq/cpuinfo_max_freq"
				if [ -f "$maxfreq_path" ]; then
					maxfreq=$(cat "$maxfreq_path")
					[ -n "$maxfreq" ] && [ "$maxfreq" -gt 0 ] && echo "cpu$cpu $maxfreq" >/sys/devices/virtual/thermal/thermal_message/cpu_limits
				fi
			done
		fi

		# Disable PPM (Power Policy Manager) Limits
		if [ -d /proc/ppm ]; then
			if [ -f /proc/ppm/policy_status ]; then
				for idx in $(grep -E 'FORCE_LIMIT|PWR_THRO|THERMAL' /proc/ppm/policy_status | awk -F'[][]' '{print $2}'); do
					echo "$idx 0" >/proc/ppm/policy_status
				done
			fi
		fi

		# Hide and disable monitoring of thermal zones
		find /sys/devices/virtual/thermal -type f -exec chmod 000 {} +

		# Disable Thermal Stats
		cmd thermalservice override-status 0

		# Disable Battery Overcharge Thermal Throttling
		if [ -f "/proc/mtk_batoc_throttling/battery_oc_protect_stop" ]; then
			echo "stop 1" >/proc/mtk_batoc_throttling/battery_oc_protect_stop
		fi

		AZLog "Thermal service Disabled"
	}

	if [ "$(getprop persist.sys.azenithconf.disabletrace)" -eq 1 ]; then
		dlog "Applying disable trace"
		for trace_file in \
			/sys/kernel/tracing/instances/mmstat/trace \
			/sys/kernel/tracing/trace \
			$(find /sys/kernel/tracing/per_cpu/ -name trace 2>/dev/null); do
			zeshia "" "$trace_file"
		done
		zeshia "0" /sys/kernel/tracing/options/overwrite
		zeshia "0" /sys/kernel/tracing/options/record-tgids
		for f in /sys/kernel/tracing/*; do
			[ -w "$f" ] && echo "0" >"$f" 2>/dev/null
		done
		cmd accessibility stop-trace 2>/dev/null
		cmd input_method tracing stop 2>/dev/null
		cmd window tracing stop 2>/dev/null
		cmd window tracing size 0 2>/dev/null
		cmd migard dump-trace false 2>/dev/null
		cmd migard start-trace false 2>/dev/null
		cmd migard stop-trace true 2>/dev/null
		cmd migard trace-buffer-size 0 2>/dev/null
	else
		for trace_file in \
			/sys/kernel/tracing/instances/mmstat/trace \
			/sys/kernel/tracing/trace \
			$(find /sys/kernel/tracing/per_cpu/ -name trace 2>/dev/null); do
			[ -w "$trace_file" ] && : >"$trace_file" 2>/dev/null
		done
		#zeshia "1" /sys/kernel/tracing/options/overwrite
		#zeshia "1" /sys/kernel/tracing/options/record-tgids
		for f in /sys/kernel/tracing/*; do
			[ -w "$f" ] && echo "1" >"$f" 2>/dev/null
		done
		cmd accessibility start-trace 2>/dev/null
		cmd input_method tracing start 2>/dev/null
		cmd window tracing start 2>/dev/null
		cmd window tracing size 8192 2>/dev/null
		cmd migard dump-trace true 2>/dev/null
		cmd migard start-trace true 2>/dev/null
		cmd migard stop-trace false 2>/dev/null
		cmd migard trace-buffer-size 8192 2>/dev/null
	fi

	kill_logd() {
		zeshia 0 /sys/kernel/ccci/debug
		zeshia 0 /sys/kernel/tracing/tracing_on
		zeshia 0 /proc/sys/kernel/perf_event_paranoid
		zeshia 0 /proc/sys/kernel/debug_locks
		zeshia 0 /proc/sys/kernel/perf_cpu_time_max_percent
		zeshia off /proc/sys/kernel/printk_devkmsg
	}
	# List of logging services
	list_logger="
    logd
    traced
    statsd
    tcpdump
    cnss_diag
    subsystem_ramdump
    charge_logger
    wlan_logging
    "

	if [ "$(getprop persist.sys.azenithconf.logd)" -eq 1 ]; then
		for logger in $list_logger; do
			stop "$logger" 2>/dev/null
		done
		dlog "Applying Kill Logd"
	else
		for logger in $list_logger; do
			start "$logger" 2>/dev/null
		done
	fi

	if [ "$(getprop persist.sys.azenithconf.DThermal)" -eq 1 ]; then
		dlog "Applying Disable Thermal"
		DThermal
	fi
	if [ "$(getprop persist.sys.azenithconf.SFL)" -eq 1 ]; then
		dlog "Applying SurfaceFlinger Latency"
		SFL
	fi
	if [ "$(getprop persist.sys.azenithconf.malisched)" -eq 1 ]; then
		dlog "Applying GPU Mali Sched"
		malisched
	fi
	if [ "$(getprop persist.sys.azenithconf.fpsged)" -eq 1 ]; then
		dlog "Applying FPSGO Parameters"
		fpsgoandgedparams
	fi
	if [ "$(getprop persist.sys.azenithconf.schedtunes)" -eq 1 ]; then
		dlog "Applying Schedtunes for Schedutil and Schedhorizon"
		schedtunes
	fi
	if [ "$(getprop persist.sys.azenithconf.justintime)" -eq 1 ]; then
		dlog "Applying JIT Compiler"
		jit
	fi
	if [ "$(getprop persist.sys.azenithconf.bypasschg)" -eq 1 ]; then
		sys.azenith-utilityconf disableBypass
	fi
	# Set up disable vsync
	sys.azenith-utilityconf
	sync
	AZLog "Initializing Complete"
	dlog "Initializing Complete"
}

###############################################
# # # # # # # MAIN FUNCTION! # # # # # # #
###############################################

case "$1" in
0) initialize ;;
1) performance_profile ;;
2) balanced_profile ;;
3) eco_mode ;;
esac
$@
wait
exit 0
