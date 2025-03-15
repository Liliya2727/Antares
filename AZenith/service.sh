#!/system/bin/sh

MODDIR=${0%/*}
logpath="/data/AZenith/AZenith.log"
notification="su -lp 2000 -c \"/system/bin/cmd notification post -t 'AZenith!' -i file:///data/local/tmp/AZenith_icon.png -I file:///data/local/tmp/AZenith_icon.png 'AZenith' 'Starting AZenith, This Process Might Take Some Time...'\""
notification1="su -lp 2000 -c \"/system/bin/cmd notification post -t 'AZenith!' -i file:///data/local/tmp/AZenith_icon.png -I file:///data/local/tmp/AZenith_icon.png 'AZenith' 'Applying AZutility...'\""
notification2="su -lp 2000 -c \"/system/bin/cmd notification post -t 'AZenith!' -i file:///data/local/tmp/AZenith_icon.png -I file:///data/local/tmp/AZenith_icon.png 'AZenith' 'Applying Tweak...'\""
notification3="su -lp 2000 -c \"/system/bin/cmd notification post -t 'AZenith!' -i file:///data/local/tmp/AZenith_icon.png -I file:///data/local/tmp/AZenith_icon.png 'AZenith' 'Applying Normal Profile...'\""
notificationdone="su -lp 2000 -c \"/system/bin/cmd notification post -t 'AZenith!' -i file:///data/local/tmp/AZenith_icon.png -I file:///data/local/tmp/AZenith_icon.png 'AZenith' 'AZenith is Running Successfully!'\""

AZLog() {
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    local message="$1"
    echo "$timestamp - $message" >> "$logpath"
    echo "$timestamp - $message"
}

AZENITH() {
    nohup sh "$MODDIR/libs/AZenith" >/dev/null 2>&1 &
}

# Remove Old Logs
rm -f "$logpath"
sleep 0.5
AZLog "Removing Old Logs..."

# Wait for boot completion
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    AZLog "Waiting boot for complete..."
    sleep 30
done

# Logging File
touch "$logpath"
AZLog "Starting Script..."

# Send notification
eval "$notification"
sleep 4
# Kill old services without terminating this script
AZLog "Stopping old services..."
pgrep -f AZenith | grep -v "$$" | xargs kill -9 2>/dev/null
pgrep -f AZenith_Performance | grep -v "$$" | xargs kill -9 2>/dev/null

# Applying Additional Tweaks...
AZLog "Applying AZUtility"
eval "$notification1"
sh "$MODDIR/system/bin/AZenith_Utility"

# Start Monitoring Service
AZLog "Applying Normal Profiles"
eval "$notification3"
sh "$MODDIR/system/bin/AZenith_Normal"

# Execute AZenith_Tweak
AZLog "Starting Additional Tweak"
eval "$notification2"
sh "$MODDIR/system/bin/AZenith_Tweak"

# Start Monitoring Service 
AZLog "AZENITHED"
AZENITH
eval "$notificationdone"

exit 0
