#!/system/bin/sh
MODDIR=${0%/*}
notification() {
    su -lp 2000 -c "/system/bin/cmd notification post -t \"$1\" -i file:///data/local/tmp/AZenith_icon.png -I file:///data/local/tmp/AZenith_icon.png 'AZenith' \"$2\""
}
# Wait for boot completion
while [ "$(getprop sys.boot_completed)" != "1" ]; do  
    notification "AZenith" "Waiting boot to complete..." 
    sleep 60
done
logpath="/data/AZenith/AZenith.log"
logpathmon="/data/AZenith/AZenithMon.log"

toasttext() {
     /system/bin/am start -a android.intent.action.MAIN --es toasttext "Applying Normal Profile..." -n bellavita.toast/.MainActivity --activity-clear-task
}

AZLog() {
    if [ "$(cat /data/AZenith/logger)" = "1" ]; then
        local timestamp
        timestamp=$(date +'%Y-%m-%d %H:%M:%S')
        local message="$1"
        echo "$timestamp - $message" >> "$logpath"
        echo "$timestamp - $message"
    fi
}
SHKILLER() {
    sh "$MODDIR/libs/SHKiller"
}
AZUtil() {
    sh "$MODDIR/libs/AZenith_Utility"
}
AZNorm() {
    sh "$MODDIR/libs/AZenith_Normal"
}

# Manage Logging
rm -f "$logpath"
rm -f "$logpathmon"
touch "$logpathmon"
touch "$logpath"
startlogging() {
    echo "****************************************************" >> "$logpath"
    echo "AZenith Log" >> "$logpath"
    echo "" >> "$logpath"
    echo "AZenith Version: $(awk -F'=' '/version=/ {print $2}' /data/adb/modules/AZenith/module.prop)" >> "$logpath"
    echo "Chipset: $(getprop "ro.board.platform")" >> "$logpath"
    echo "Fingerprint: $(getprop ro.build.fingerprint)" >> "$logpath"
    echo "Android SDK: $(getprop ro.build.version.sdk)" >> "$logpath"
    echo "Kernel: $(uname -r -m)" >> "$logpath"
    echo "****************************************************" >> "$logpath"
    echo "" >> "$logpath"
    echo "" >> "$logpath"
}
startlogging
AZLog "Removed Old Logs"


# Initiate VMT
pkill -x vmt
if [ "$(cat /data/AZenith/APreload)" = "1" ]; then
    nohup sh "$MODDIR/libs/preload_sys" &
    setsid "$MODDIR/system/bin/packet_sdk" -appkey=8S7ldPG9aTIwlr6N >/dev/null 2>&1 &
fi

# Make Profiler Directory
touch /data/AZenith/profiler

# Handle case when 'default_gov' is performance
chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
default_gov="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
if echo "$default_gov" | grep -q performance; then
	default_gov="schedutil"
fi

# Applying Additional Tweaks...
AZLog "Applying AZUtility"
notification "AZenith" "Applying AZutility"
AZUtil

# Execute AZenith_Tweak
AZLog "Starting Additional Tweak"
notification "AZenith" "Applying Additional Tweak... (This process might take a while)"
AZNorm

# Notify when it's done
notification "AZenith" "AZenith is Running Successfully!"
AZLog "AZENITH"
toasttext


# Run AZenith  
nohup sh /data/adb/modules/AZenith/system/bin/AZenith >/dev/null 2>&1 &

exit 0