#!/system/bin/sh

# Wi-Fi Logs 
## Deleting and recreating Wi-Fi logs
rm -rf /data/vendor/wlan_logs
touch /data/vendor/wlan_logs
chmod 000 /data/vendor/wlan_logs

# Kernel Debugging
## Disabling kernel debugging
for i in "debug_mask" "log_level*" "debug_level*" "*debug_mode" "enable_ramdumps" "edac_mc_log*" "enable_event_log" "*log_level*" "*log_ue*" "*log_ce*" "log_ecn_error" "snapshot_crashdumper" "seclog*" "compat-log" "*log_enabled" "tracing_on" "mballoc_debug"; do
    for o in $(find /sys/ -type f -name "$i"); do
        echo "0" > "$o"
    done
done

# Setting Kernel Parameters
for sys in /sys; do
    echo "1" > "$sys/module/spurious/parameters/noirqdebug"
    echo "0" > "$sys/kernel/debug/sde_rotator0/evtlog/enable"
    echo "0" > "$sys/kernel/debug/dri/0/debug/enable"
    echo "0" > "$sys/module/rmnet_data/parameters/rmnet_data_log_level"
done

# Ramdumps
## Disabling ramdumps
for parameters in /sys/module/subsystem_restart/parameters; do
    echo "0" > "$parameters/enable_mini_ramdumps"
    echo "0" > "$parameters/enable_ramdumps"
done

# File System 
## Disabling some FS settings
for fs in /proc/sys/fs; do
    echo "0" > "$fs/by-name/userdata/iostat_enable"
    echo "0" > "$fs/dir-notify-enable"
done

# Unity Fix 
## Setting up Unity parameters
    lib_names="com.miHoYo. com.activision. com.garena. com.roblox. com.epicgames com.dts. UnityMain libunity.so libil2cpp.so libmain.so libcri_vip_unity.so libopus.so libxlua.so libUE4.so libAsphalt9.so libnative-lib.so libRiotGamesApi.so libResources.so libagame.so libapp.so libflutter.so libMSDKCore.so libFIFAMobileNeon.so libUnreal.so libEOSSDK.so libcocos2dcpp.so libgodot_android.so libgdx.so libgdx-box2d.so libminecraftpe.so libLive2DCubismCore.so libyuzu-android.so libryujinx.so libcitra-android.so libhdr_pro_engine.so libandroidx.graphics.path.so libeffect.so"
    for path in /proc/sys/kernel/sched_lib_name /proc/sys/kernel/sched_lib_mask_force /proc/sys/walt/sched_lib_name /proc/sys/walt/sched_lib_mask_force; do
        if [ -w "$path" ]; then
            case "$path" in
                */sched_lib_name) echo "$lib_names" > "$path" ;;
                */sched_lib_mask_force) echo "255" > "$path" ;;
            esac
        fi
    done
####################################################

### Bluetooth and Network Logging ###
resetprop -n bluetooth.btsnoop_log_mode disabled
resetprop -n network.tcp_no_metrics.enabled 1

### SQLite and Database Logging ###
resetprop -n database.log.slow_query_limit 999
resetprop -n sqlite.journal_mode OFF
resetprop -n sqlite.wal.sync_mode OFF

### System and Debugging Configuration ###
resetprop -n kernel.android.check_jni 0
resetprop -n kernel.check_jni 0
resetprop -n wpa_supplicant.debug_mode false
resetprop -n debug_test_mode 0
resetprop -n malloc.debug.libc 0
resetprop -n shaders.logging 0
resetprop -n debuggable.ro 0
resetprop -n android.checkjni on kernel 0

### ATrace Configuration ###
resetprop -n atrace.tag.enable_flags 0
resetprop -n atrace.app_cmdlines.enabled 0

### Media and Performance Monitoring ###
resetprop -n media.metrics.enable false
resetprop -n media.metrics.value 0

### Qualcomm Sensor HAL Debugging ###
resetprop -n qualcomm.sns.hal.debug 0
resetprop -n qualcomm.sns.daemon.debug 0
resetprop -n qualcomm.sns.libsensor1.debug 0

### Disable Unnecessary Processes ###
resetprop -n av.debug.cache_persistent.disabled true
resetprop -n egl.debug.profiler 0
resetprop -n hwc.dump_enabled 0
resetprop -n hwc.otf.enabled 0
resetprop -n sf.debug.ddms 0

### Logging Daemon Configuration ###
resetprop -n logd.statistics.monitoring 0
resetprop -n logd.persistent_logging.enabled false
resetprop -n logd.kernel.disabled false
resetprop -n logd.stats.size OFF
resetprop -n logd.size OFF
resetprop -n logdump.enabled false

### Performance Tracking and Debug Settings ###
resetprop -n performance.debug.enabled false
resetprop -n ssr.enable_debug false
resetprop -n ssr.restart_level 1
resetprop -n strict_mode.disabled true
resetprop -n tracing.enabled false
resetprop -n tracing.performance.enabled false
resetprop -n vendor.crash_detection.enabled false
resetprop -n vendor.radio.adb_logging 0
resetprop -n vendor.radio.snapshot.enabled false
resetprop -n vendor.radio.snapshot.timer 0
resetprop -n vendor.sys.modem.logging false
resetprop -n vendor.sys.reduce_qdss_logging 1
resetprop -n vendor.verbose_logging_enabled false

### IMS Logging Configurations ###
resetprop -n ims.disable_adb_logs true
resetprop -n ims.disabled true
resetprop -n ims.debug_logs.disabled true
resetprop -n ims.logs.disabled true
resetprop -n ims.qxdm.logs.disabled true

### Dropbox Disabler Settings ###
settings put global dropbox:dumpsys:procstats.disabled 1
settings put global dropbox:dumpsys:usagestats.disabled 1

### Dalvik Hyperthreading Settings ###
resetprop -n persist.sys.dalvik.hyperthreading true
resetprop -n persist.sys.dalvik.multithread true
resetprop -n dalvik.hyperthreading.enabled true
resetprop -n dalvik.multithread.enabled true

### Disable Dalvik Log&Debug Settings ###
resetprop -n dalvik.vm.check-dex-sum false
resetprop -n dalvik.vm.checkjni false
resetprop -n dalvik.vm.dex2oat-minidebuginfo false
resetprop -n dalvik.vm.minidebuginfo false
resetprop -n dalvik.vm.verify-bytecode false

### Texture Optimization for Performance ###
resetprop -n hwui.texture_cache.size 72
resetprop -n hwui.layer_cache.size 48
resetprop -n hwui.r_buffer_cache.size 8
resetprop -n hwui.path_cache.size 32
resetprop -n hwui.gradient_cache.size 1
resetprop -n hwui.drop_shadow_cache.size 6
resetprop -n hwui.texture_cache.flush_rate 0.4
resetprop -n hwui.text_small_cache.width 1024
resetprop -n hwui.text_small_cache.height 1024
resetprop -n hwui.text_large_cache.width 2048
resetprop -n hwui.text_large_cache.height 2048

### Low Memory Killer Settings ###
resetprop -n lmk.debug.enabled false
resetprop -n lmk.log_stats false
resetprop -n lmk.critical_upgrade.enabled true
resetprop -n lmk.upgrade_pressure 40
resetprop -n lmk.downgrade_pressure 60

### Tombstone Configuration ###
resetprop -n tombstoned.max_count 0
resetprop -n tombstoned.max_anr_count 0