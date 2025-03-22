#!/system/bin/sh
MODDIR=${0%/*}
# Wait for boot completion
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sh -c "$notification"
    sleep 45
done
logpath="/data/AZenith/AZenith.log"
notification="su -lp 2000 -c \"/system/bin/cmd notification post -t 'AZenith!' -i file:///data/local/tmp/AZenith_icon.png -I file:///data/local/tmp/AZenith_icon.png 'AZenith' 'Starting AZenith...'\""
notification1="su -lp 2000 -c \"/system/bin/cmd notification post -t 'AZenith!' -i file:///data/local/tmp/AZenith_icon.png -I file:///data/local/tmp/AZenith_icon.png 'AZenith' 'Applying AZutility...'\""
notification2="su -lp 2000 -c \"/system/bin/cmd notification post -t 'AZenith!' -i file:///data/local/tmp/AZenith_icon.png -I file:///data/local/tmp/AZenith_icon.png 'AZenith' 'Applying Additional Tweak... | This May Take a while...'\""
notificationdone="su -lp 2000 -c \"/system/bin/cmd notification post -t 'AZenith!' -i file:///data/local/tmp/AZenith_icon.png -I file:///data/local/tmp/AZenith_icon.png 'AZenith' 'AZenith is Running Successfully!'\""

AZLog() {
    if [ "$(cat /data/AZenith/logger 2>/dev/null)" = "1" ]; then
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

rm -f "$logpath"

touch "$logpath"
AZLog "Removed Old Logs"

toasttext() {
     /system/bin/am start -a android.intent.action.MAIN --es toasttext "Applying Normal Profile..." -n bellavita.toast/.MainActivity --activity-clear-task
}

# Profiler
touch /data/AZenith/profiler

# Handle case when 'default_gov' is performance
chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
default_gov="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
if echo "$default_gov" | grep -q performance; then
	default_gov="schedutil"
fi

# Applying Additional Tweaks...
AZLog "Applying AZUtility"
sh -c "$notification1"
AZUtil

# Execute AZenith_Tweak
AZLog "Starting Additional Tweak"
sh -c "$notification2"
AZNorm

# Notify when it's done
sh -c "$notificationdone"
AZLog "AZENITH"
toasttext

# Run AZenith  
nohup sh /data/adb/modules/AZenith/system/bin/AZenith > /dev/null 2>&1 &

exit 0