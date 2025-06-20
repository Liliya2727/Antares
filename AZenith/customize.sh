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

# Configuration flags
SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=true
LATESTARTSERVICE=true

# Get module version and author from module.prop
MODVER=$(grep "^version=" "$MODPATH/module.prop" | cut -d '=' -f2)
AUTHOR=$(grep "^author=" "$MODPATH/module.prop" | cut -d '=' -f2)
device_codename=$(getprop ro.product.board)
chip=$(getprop ro.hardware)

# List of system paths to replace (if any)
REPLACE=""

checkpath() {
    if [ -e "$1" ]; then
        return 0 
    fi
    return 1  
}

# List of paths
bypasslist="
/sys/devices/platform/charger/bypass_charger
/sys/devices/platform/charger/tran_aichg_disable_charger
/proc/mtk_battery_cmd/current_cmd
/sys/devices/platform/mt-battery/disable_charger"
"

# Display banner
ui_print ""
ui_print "              AZenith              "
ui_print ""
ui_print "- Build Date  : 17/06/2025"
ui_print "- Author        : ${AUTHOR}"
ui_print "- Version       : ${MODVER}"
ui_print "- Device        : $(getprop ro.product.board)"
ui_print "- Build Date    : $(getprop ro.build.date)"
sleep 1
ui_print "- Installing AZenith..."

# Extracting module files
ui_print "- Creating necessary directories..."
mkdir -p /data/AZenith
ui_print "- Extracting system directories..."
extract -o "$ZIPFILE" 'system/*' -d "$MODPATH" >&2
ui_print "- Extracting libs directories..."
extract -o "$ZIPFILE" 'libs/*' -d "$MODPATH" >&2
ui_print "- Extracting service.sh..."
unzip -o "$ZIPFILE" 'service.sh' -d "$MODPATH" >&2
ui_print "- Extracting gamelist..."
unzip -qo "$ZIPFILE" 'gamelist.txt' -d "/data/AZenith" >&2
ui_print "- Extracting module Icon..."
unzip -qo "$ZIPFILE" 'AZenith_icon.png' -d "/data/local/tmp" >&2
sleep 1

# Checking bypass
ui_print "- Checking Bypass compatibility..."
sleep 3
bypasspath=""
for path in $bypasslist; do
    if checkpath "$path"; then
        bypasspath="$path"
        break 
    fi
done

# Fallback to nb html if bypass unsupported
if [ -z "$bypasspath" ]; then
    ui_print "- Skip installing bypasscharge..."
    mv "$MODPATH/assets/indexnbhtml" "$MODPATH/webroot/index.html"
    mv "$MODPATH/assets/fn762agnbjs" "$MODPATH/webroot/fn762ag.js"
    else
    ui_print "- start installing bypasscharge addon"
    ui_print "- path: $path"
    mv "$MODPATH/assets/indexbphtml" "$MODPATH/webroot/index.html"
    mv "$MODPATH/assets/fn762agbpjs" "$MODPATH/webroot/fn762ag.js"
fi

# Installing toast
if pm list packages | grep -q bellavita.toast; then
    ui_print "- Bellavita Toast is already installed."
else
    ui_print "- Extracting Bellavita Toast..."
    unzip -o "$ZIPFILE" 'toast.apk' -d "$MODPATH" >&2
    ui_print "- Installing Bellavita Toast..."
    pm install "$MODPATH/toast.apk"
    rm "$MODPATH/toast.apk"
fi

# Check device chipset
chipset=$(grep "Hardware" /proc/cpuinfo | uniq | cut -d ':' -f 2 | sed 's/^[ \t]*//')
[ -z "$chipset" ] && chipset="$(getprop ro.board.platform) $(getprop ro.hardware)"
case "$chipset" in
    *mt* | *MT*) 
        soc=1
        ui_print "- Implementing tweaks for MediaTek $chip"
        
        ;;
    *)  
        ui_print "! Unsupported chipset detected: $chipset"
        ui_print "! This is Only for MediaTek."
        abort
        ;;
esac

# Move Important File to run Azenith 
mv "$MODPATH/assets/availableFreq" "/data/AZenith/availableFreq"
mv "$MODPATH/assets/customFreqOffset" "/data/AZenith/customFreqOffset"

# Cleanup file
rm -rf "$MODPATH/assets"
rm -rf "$MODPATH/gamelist.txt"
rm -rf "$MODPATH/toast.apk"

# Final permission setup
ui_print "- Setting Permissions..."
set_perm_recursive "$MODPATH/system/bin" 0 2000 0777 0777
chmod +x "$MODPATH/system/bin/AZenith" 
chmod +x "$MODPATH/system/bin/AZenith_Normal" 
chmod +x "$MODPATH/system/bin/AZenith_Utility" 
chmod +x "$MODPATH/system/bin/AZenith_Performance" 
chmod +x "$MODPATH/system/bin/AZenith_Powersave" 
chmod +x "$MODPATH/system/bin/bypassCharge" 
chmod +x "$MODPATH/system/bin/preload_sys" 
ui_print "- Installation complete!"
