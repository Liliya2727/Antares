#!/system/bin/sh

MODDIR=${0%/*}
logpath="/data/AZenith/AZenith.log"
notification="su -lp 2000 -c \"/system/bin/cmd notification post -t 'AZenith!' -i file:///data/local/tmp/AZenith_icon.png -I file:///data/local/tmp/AZenith_icon.png 'AZenith' 'Starting AZenith...'\""
notification1="su -lp 2000 -c \"/system/bin/cmd notification post -t 'AZenith!' -i file:///data/local/tmp/AZenith_icon.png -I file:///data/local/tmp/AZenith_icon.png 'AZenith' 'Applying AZutility...'\""
notification2="su -lp 2000 -c \"/system/bin/cmd notification post -t 'AZenith!' -i file:///data/local/tmp/AZenith_icon.png -I file:///data/local/tmp/AZenith_icon.png 'AZenith' 'Applying Additional Tweak... | This May Take a while...'\""
notification3="su -lp 2000 -c \"/system/bin/cmd notification post -t 'AZenith!' -i file:///data/local/tmp/AZenith_icon.png -I file:///data/local/tmp/AZenith_icon.png 'AZenith' 'Killing Old Service...'\""
notificationdone="su -lp 2000 -c \"/system/bin/cmd notification post -t 'AZenith!' -i file:///data/local/tmp/AZenith_icon.png -I file:///data/local/tmp/AZenith_icon.png 'AZenith' 'AZenith is Running Successfully!'\""
toasttext() {
     /system/bin/am start -a android.intent.action.MAIN --es toasttext "Applying Normal Profile..." -n bellavita.toast/.MainActivity
}
#!/system/bin/sh

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
    sh "$MODDIR/system/bin/SHKiller"
}
AZENITH() {
    nohup sh "$MODDIR/libs/AZenith" >/dev/null 2>&1 &
}
AZUtil() {
    sh "$MODDIR/system/bin/AZenith_Utility"
}
AZNorm() {
    sh "$MODDIR/system/bin/AZenith_Normal"
}

# Remove Old Logs
rm -f "$logpath"

# Logging File
touch "$logpath"
sleep 0.5
AZLog "Removing Old Logs..."

# Wait for boot completion
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    AZLog "Waiting boot for complete..."
    sleep 40
done
AZLog "Starting Script..."
eval "$notification"
chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
default_gov="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"

# Handle case when 'default_gov' is performance
if echo $default_gov | grep -q performance; then
	default_gov="schedutil"
fi

# Kill old services without terminating this script
AZLog "Stopping old services..."
eval "$notification3"
SHKILLER
sleep 4

# Applying Additional Tweaks...
AZLog "Applying AZUtility"
eval "$notification1"
sleep 4
AZUtil

# Execute AZenith_Tweak
AZLog "Starting Additional Tweak"
eval "$notification2"
AZNorm

# Start Monitoring Service 
AZLog "Starting AZenith"
# Wait Everything to Done
sleep 2
AZENITH
eval "$notificationdone"
AZLog "AZENITHED"
toasttext

exit 0