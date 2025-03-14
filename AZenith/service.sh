#!/system/bin/sh

while [ -z "$(getprop sys.boot_completed)" ]; do
    sleep 30
done

su -lp 2000 -c "/system/bin/cmd notification post -t 'AZenith!' -i file:///data/local/tmp/AZenith_icon.png -I file:///data/local/tmp/AZenith_icon.png 'AZenith' 'Starting AZenith...'"
# Applying Additional Tweaks...
sleep 2
sh /data/adb/modules/AZenith/system/bin/AZenith_Utility
sleep 5
sh /data/adb/modules/AZenith/system/bin/AZenith_Tweak
sleep 5
# AZenith Running!
nohup sh /data/adb/modules/AZenith/libs/AZenith > /dev/null 2>&1 &
