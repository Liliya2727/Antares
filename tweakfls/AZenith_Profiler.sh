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
logpath="/data/adb/.config/AZenith/AZenithVerbose.log"
logdaemonpath="/data/adb/.config/AZenith/AZenith.log"
GAME_GOV_FILE="/data/adb/.config/AZenith/custom_game_cpu_gov"
DEFAULT_GOV_FILE="/data/adb/.config/AZenith/custom_default_cpu_gov"
POWERSAVE_GOV_FILE="/data/adb/.config/AZenith/custom_powersave_cpu_gov"


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

zeshiax() {
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
cpufreq_ppm_max_perf() {
	cluster=-1
	for path in /sys/devices/system/cpu/cpufreq/policy*; do
		((cluster++))
		cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
		zeshia "$cluster $cpu_maxfreq" /proc/ppm/policy/hard_userlimit_max_cpu_freq

		[ $LITE_MODE -eq 1 ] && {
			cpu_midfreq=$(which_midfreq "$path/scaling_available_frequencies")
			zeshia "$cluster $cpu_midfreq" /proc/ppm/policy/hard_userlimit_min_cpu_freq
			continue
		}

		zeshia "$cluster $cpu_maxfreq" /proc/ppm/policy/hard_userlimit_min_cpu_freq
	done
}

cpufreq_max_perf() {
	for path in /sys/devices/system/cpu/*/cpufreq; do
		cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
		zeshia "$cpu_maxfreq" "$path/scaling_max_freq"

		[ $LITE_MODE -eq 1 ] && {
			cpu_midfreq=$(which_midfreq "$path/scaling_available_frequencies")
			zeshia "$cpu_midfreq" "$path/scaling_min_freq"
			continue
		}

	    zeshia "$cpu_maxfreq" "$path/scaling_min_freq"
	done
	chmod -f 444 /sys/devices/system/cpu/cpufreq/policy*/scaling_*_freq
}

cpufreq_ppm_unlock() {
	cluster=0
	for path in /sys/devices/system/cpu/cpufreq/policy*; do
		cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
		cpu_minfreq=$(<"$path/cpuinfo_min_freq")
		zeshiax "$cluster $cpu_maxfreq" /proc/ppm/policy/hard_userlimit_max_cpu_freq
		zeshiax "$cluster $cpu_minfreq" /proc/ppm/policy/hard_userlimit_min_cpu_freq
		((cluster++))
	done
}

cpufreq_unlock() {
	for path in /sys/devices/system/cpu/*/cpufreq; do
		cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
		cpu_minfreq=$(<"$path/cpuinfo_min_freq")
		zeshiax "$cpu_maxfreq" "$path/scaling_max_freq"
		zeshiax "$cpu_minfreq" "$path/scaling_min_freq"
	done
	chmod -f 644 /sys/devices/system/cpu/cpufreq/policy*/scaling_*_freq
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

sync

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
# # # # # # #  BALANCED PROFILES! # # # # # # #
###############################################
balanced_profile() {
    load_default_governor() {
        if [ -f "$DEFAULT_GOV_FILE" ]; then
            cat "$DEFAULT_GOV_FILE"
        else
            echo "schedutil"
        fi
    }

    # Load default cpu governor
    default_cpu_gov=$(load_default_governor)

    # Power level settings
    for pl in /sys/devices/system/cpu/perf; do
        zeshia 0 "$pl/gpu_pmu_enable"
        zeshia 0 "$pl/fuel_gauge_enable"
        zeshia 0 "$pl/enable"
        zeshia 1 "$pl/charger_enable"
    done

    # Disable DND
    if [ "$(cat /data/adb/.config/AZenith/dnd)" -eq 1 ]; then
        cmd notification set_dnd off && AZLog "DND disabled" || AZLog "Failed to disable DND"
    fi

    # Restore CPU Scaling Governor
    setgov "$default_cpu_gov"
    dlog "Applying governor to : $default_cpu_gov"

    # Restore Max CPU Frequency if its from ECO Mode or using Limit Frequency
    if [ -d /proc/ppm ]; then
        cluster=0
        for path in /sys/devices/system/cpu/cpufreq/policy*; do
            [ -f "$path/cpuinfo_max_freq" ] || continue

            cpu_maxfreq=$(cat "$path/cpuinfo_max_freq")
            cpu_minfreq=$(cat "$path/cpuinfo_min_freq")

            zeshia "$cluster $cpu_maxfreq" "/proc/ppm/policy/hard_userlimit_max_cpu_freq"
            zeshia "$cluster $cpu_minfreq" "/proc/ppm/policy/hard_userlimit_min_cpu_freq"

            policy_name=$(basename "$path")
            dlog "Set $policy_name minfreq to $cpu_minfreq"

            ((cluster++))
        done
    fi

    for path in /sys/devices/system/cpu/*/cpufreq; do
        [ -f "$path/cpuinfo_max_freq" ] || continue

        cpu_maxfreq=$(cat "$path/cpuinfo_max_freq")
        cpu_minfreq=$(cat "$path/cpuinfo_min_freq")

        zeshia "$cpu_maxfreq" "$path/scaling_max_freq"
        zeshia "$cpu_minfreq" "$path/scaling_min_freq"
    done

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

    if [ "$(cat /data/adb/.config/AZenith/bypass_charge)" -eq 1 ]; then
        bypassCharge 0
    fi

    case "$(cat /data/adb/.config/AZenith/soctype)" in
    1) mediatek_balance ;;
    2) snapdragon_balance ;;
    3) exynos_balance ;;
    4) unisoc_balance ;;
    5) tensor_balance ;;
    esac

    AZLog "Balanced Profile applied successfully!"

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
# # # # # # # PERFORMANCE PROFILE! # # # # # # #
###############################################

performance_profile() {
    load_game_governor() {
        if [ -f "$GAME_GOV_FILE" ]; then
            cat "$GAME_GOV_FILE"
        else
            echo "schedutil"
        fi
    }

    # Load default cpu governor
    game_cpu_gov=$(load_game_governor)

    # Power level settings
    for pl in /sys/devices/system/cpu/perf; do
        zeshia 1 "$pl/gpu_pmu_enable"
        zeshia 1 "$pl/fuel_gauge_enable"
        zeshia 1 "$pl/enable"
        zeshia 1 "$pl/charger_enable"
    done

    # Set DND Mode
    if [ "$(cat /data/adb/.config/AZenith/dnd)" -eq 1 ]; then
        cmd notification set_dnd priority && AZLog "DND enabled" || AZLog "Failed to enable DND"
    else
        AZLog "DND not enabled."
    fi

    # Set Governor Game
    setgov "$game_cpu_gov"
    dlog "Applying governor to : $game_cpu_gov"

    # Restore Max CPU Frequency if its from ECO Mode or using Limit Frequency
    if [ "$(cat /data/adb/.config/AZenith/cpulimit)" -eq 1 ]; then
        if [ -d /proc/ppm ]; then
            cluster=0
            for path in /sys/devices/system/cpu/cpufreq/policy*; do
                cpu_maxfreq=$(cat "$path/cpuinfo_max_freq")

                zeshia "$cluster $cpu_maxfreq" "/proc/ppm/policy/hard_userlimit_max_cpu_freq"
                zeshia "$cluster $cpu_maxfreq" "/proc/ppm/policy/hard_userlimit_min_cpu_freq"
                policy_name=$(basename "$path")
                dlog "Set $policy_name minfreq to $cpu_maxfreq"
                ((cluster++))

            done
        fi
        for path in /sys/devices/system/cpu/*/cpufreq; do
            cpu_maxfreq=$(cat "$path/cpuinfo_max_freq")

            zeshia "$cpu_maxfreq" "$path/scaling_max_freq"
            zeshia "$cpu_maxfreq" "$path/scaling_min_freq"

        done
    else
        if [ -d /proc/ppm ]; then
            cluster=0
            for path in /sys/devices/system/cpu/cpufreq/policy*; do
                cpu_maxfreq=$(cat "$path/cpuinfo_max_freq")
                cpu_minfreq=$(cat "$path/cpuinfo_min_freq")

                zeshia "$cluster $cpu_maxfreq" "/proc/ppm/policy/hard_userlimit_max_cpu_freq"
                zeshia "$cluster $cpu_minfreq" "/proc/ppm/policy/hard_userlimit_min_cpu_freq"
                policy_name=$(basename "$path")
                dlog "Set $policy_name minfreq to $cpu_minfreq"
                ((cluster++))

            done
        fi
        for path in /sys/devices/system/cpu/*/cpufreq; do
            cpu_maxfreq=$(cat "$path/cpuinfo_max_freq")
            cpu_minfreq=$(cat "$path/cpuinfo_min_freq")

            zeshia "$cpu_maxfreq" "$path/scaling_max_freq"
            zeshia "$cpu_minfreq" "$path/scaling_min_freq"

        done
    fi

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

    clear_background_apps() {
        AZLog "Clearing background apps..."

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
    }
    if [ "$(cat /data/adb/.config/AZenith/clearbg)" -eq 1 ]; then
        clear_background_apps
        AZLog "Clearing apps"
    fi

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

    if [ "$(cat /data/adb/.config/AZenith/bypass_charge)" -eq 1 ]; then
        bypassCharge 1
    fi

    case "$(cat /data/adb/.config/AZenith/soctype)" in
    1) mediatek_performance ;;
    2) snapdragon_performance ;;
    3) exynos_performance ;;
    4) unisoc_performance ;;
    5) tensor_performance ;;
    esac

    AZLog "Performance Profile Applied Successfully!"

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
# # # # # # # POWERSAVE PROFILE # # # # # # #
###############################################

eco_mode() {
    # Load Powersave Governor
    load_powersave_governor() {
        if [ -f "$POWERSAVE_GOV_FILE" ]; then
            cat "$POWERSAVE_GOV_FILE"
        else
            echo "powersave"
        fi
    }
    powersave_cpu_gov=$(load_powersave_governor)

    setgov "$powersave_cpu_gov"
    dlog "Applying governor to : $powersave_cpu_gov"

    # Power level settings
    for pl in /sys/devices/system/cpu/perf; do
        zeshia 0 "$pl/gpu_pmu_enable"
        zeshia 0 "$pl/fuel_gauge_enable"
        zeshia 0 "$pl/enable"
        zeshia 1 "$pl/charger_enable"
    done

    # Disable DND
    if [ "$(cat /data/adb/.config/AZenith/dnd)" -eq 1 ]; then
        cmd notification set_dnd off && AZLog "DND disabled" || AZLog "Failed to disable DND"
    fi

    # CPU Freq Limiter
    limiter=$(cat /data/adb/.config/AZenith/customFreqOffset | sed -e 's/Disabled/100/' -e 's/%//g')
    AZLog "Cpu limit is set to $limiter"

    # Limit cpu freq
    if [ -d /proc/ppm ]; then
        cluster=0
        for path in /sys/devices/system/cpu/cpufreq/policy*; do
            cpu_maxfreq=$(cat "$path/cpuinfo_max_freq")
            cpu_minfreq=$(cat "$path/cpuinfo_min_freq")

            new_maxfreq=$((cpu_maxfreq * $limiter / 100))
            new_minfreq=$((cpu_maxfreq * 40 / 100))

            zeshia "$cluster $new_maxfreq" "/proc/ppm/policy/hard_userlimit_max_cpu_freq"
            zeshia "$cluster $cpu_minfreq" "/proc/ppm/policy/hard_userlimit_min_cpu_freq"
            policy_name=$(basename "$path")
            dlog "Set $policy_name maxfreq to $limiter% of maxfreq $new_maxfreq and minfreq $cpu_minfreq"
            ((cluster++))
        done
    fi
    for path in /sys/devices/system/cpu/cpufreq/policy*; do
        cpu_maxfreq=$(cat "$path/cpuinfo_max_freq")
        cpu_minfreq=$(cat "$path/cpuinfo_min_freq")

        new_maxfreq=$((cpu_maxfreq * $limiter / 100))
        new_minfreq=$((cpu_maxfreq * 40 / 100))

        zeshia "$new_maxfreq" "$path/scaling_max_freq"
        zeshia "$cpu_minfreq" "$path/scaling_min_freq"
    done

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

    if [ "$(cat /data/adb/.config/AZenith/bypass_charge)" -eq 1 ]; then
        bypassCharge 0
    fi

    case "$(cat /data/adb/.config/AZenith/soctype)" in
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

    sync

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
        resetprop -n debug.sf.disable_backpressure 1
        resetprop -n debug.sf.latch_unsignaled 1
        resetprop -n debug.sf.enable_hwc_vds 1
        resetprop -n debug.sf.early_phase_offset_ns 300000
        resetprop -n debug.sf.early_app_phase_offset_ns 300000
        resetprop -n debug.sf.early_gl_phase_offset_ns 2000000
        resetprop -n debug.sf.early_gl_app_phase_offset_ns 10000000
        resetprop -n debug.sf.high_fps_early_phase_offset_ns 5000000
        resetprop -n debug.sf.high_fps_early_gl_phase_offset_ns 500000
        resetprop -n debug.sf.high_fps_late_app_phase_offset_ns 80000
        resetprop -n debug.sf.phase_offset_threshold_for_next_vsync_ns 5000000
        resetprop -n debug.sf.showupdates 0
        resetprop -n debug.sf.showcpu 0
        resetprop -n debug.sf.showbackground 0
        resetprop -n debug.sf.showfps 0
        resetprop -n debug.sf.hw 1
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

        for prop in $(getprop | grep thermal | cut -f1 -d] | cut -f2 -d[ | grep -F init.svc.); do
            setprop "$prop" stopped
        done

        for prop in $(getprop | grep thermal | cut -f1 -d] | cut -f2 -d[ | grep -F init.svc_); do
            setprop "$prop" ""
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

    # Logd
    if [ -f /data/adb/.config/AZenith/logd ] && [ "$(cat /data/adb/.config/AZenith/logd)" -eq 1 ]; then
        for logger in $list_logger; do
            stop "$logger" 2>/dev/null
        done
    else
        for logger in $list_logger; do
            start "$logger" 2>/dev/null
        done
    fi

    if [ "$(cat /data/adb/.config/AZenith/logd)" -eq 1 ]; then
        kill_logd
    fi
    if [ "$(cat /data/adb/.config/AZenith/DThermal)" -eq 1 ]; then
        DThermal
    fi
    if [ "$(cat /data/adb/.config/AZenith/SFL)" -eq 1 ]; then
        SFL
    fi
    if [ "$(cat /data/adb/.config/AZenith/malisched)" -eq 1 ]; then
        malisched
    fi
    if [ "$(cat /data/adb/.config/AZenith/fpsged)" -eq 1 ]; then
        fpsgoandgedparams
    fi
    if [ "$(cat /data/adb/.config/AZenith/schedtunes)" -eq 1 ]; then
        schedtunes
    fi

    vsync_value="$(cat /data/adb/.config/AZenith/customVsync)"
    case "$vsync_value" in
    60hz | 90hz | 120hz)
        disablevsync "$vsync_value"
        ;;
    Disabled)
        AZLog "disable vsync disabled"
        ;;
    esac

    sync

    if [ "$(cat /data/adb/.config/AZenith/bypass_charge)" -eq 1 ]; then
        bypassCharge 0
    fi

}

###############################################

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
