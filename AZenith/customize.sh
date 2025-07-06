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


SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=true

# Paths
MODULE_CONFIG="/data/adb/.config/AZenith"
MODVER=$(grep "^version=" "$MODPATH/module.prop" | cut -d '=' -f2)
AUTHOR=$(grep "^author=" "$MODPATH/module.prop" | cut -d '=' -f2)
device_codename=$(getprop ro.product.board)
chip=$(getprop ro.hardware)

# Create File
make_node() {
    [ ! -f "$2" ] && echo "$1" > "$2"
}


# Displaybanner
ui_print ""
ui_print "              AZenith              "
ui_print ""
ui_print "- Release Date : 05/07/2025"
ui_print "- Author       : ${AUTHOR}"
ui_print "- Version      : ${MODVER}"
ui_print "- Device       : ${device_codename}"
ui_print "- Installing AZenith..."

# Extract Module Directiories
mkdir -p "$MODULE_CONFIG"

# Extract Module files
ui_print "- Extracting system directories..."
extract -o "$ZIPFILE" 'system/*' -d "$MODPATH" >&2
unzip -qo "$ZIPFILE" service.sh -d "$MODPATH" >&2
unzip -qo "$ZIPFILE" gamelist.txt -d "$MODULE_CONFIG" >&2
unzip -qo "$ZIPFILE" AZenith_icon.png -d /data/local/tmp >&2

# Apply Tweaks Based on Chipset
chipset=$(grep -i 'hardware' /proc/cpuinfo | uniq | cut -d ':' -f2 | sed 's/^[ \t]*//')
[ -z "$chipset" ] && chipset="$(getprop ro.board.platform) $(getprop ro.hardware)"

case "$chipset" in
    *mt* | *MT* | *mediatek* | *Mediatek*)
        soc="MediaTek"
        ui_print "- Applying Tweaks for MediaTek $chipset"
        make_node 1 "$MODULE_CONFIG/soctype"
        
        ;;
    *sdm* | *SM* | *sm* | *Snapdragon* | *qcom* | *QCOM*)
        soc="Snapdragon"
        ui_print "- Applying Tweak for Snapdragon $chipset"
        make_node 2 "$MODULE_CONFIG/soctype"
        
        ;;
    *)
        soc="Unknown"
        ui_print "- Unsupported Chipset: $chipset, Skipping some tweaks"
        make_node 0 "$MODULE_CONFIG/soctype"
        
        ;;
esac
# Soc Type
# 1) MediaTek
# 2) Snapdragon 
# 0) Unknown/No Unsupported
# /// More chipset will be added soon ////

# Inflate WebUI Based on SoC
case "$soc" in
    "MediaTek")
        ui_print "- Inflating WebUI for MediaTek"
        mv "$MODPATH/webroot/include/mtkhtml" "$MODPATH/webroot/assets/index.html"
        mv "$MODPATH/assets/include/mtkjs" "$MODPATH/webroot/assets/fn762ag.js"
        ;;
    "Snapdragon")
        ui_print "- Inflating WebUI for Snapdragon"
        mv "$MODPATH/assets/include/sdmhtml" "$MODPATH/webroot/index.html"
        mv "$MODPATH/assets/include/sdmjs" "$MODPATH/webroot/fn762ag.js"
        ;;
    *)
        ui_print "- Inflating Universal WebUI"
        mv "$MODPATH/assets/include/bschtml" "$MODPATH/webroot/index.html"
        mv "$MODPATH/assets/include/bscjs" "$MODPATH/webroot/fn762ag.js"
        ;;
esac
# I made 3 differs WebUI for this to match every Chipsets
# # # # # # 

# Install toast if not installed
if pm list packages | grep -q bellavita.toast; then
    ui_print "- Bellavita Toast is already installed."
else
    ui_print "- Extracting Bellavita Toast..."
    unzip -qo "$ZIPFILE" toast.apk -d "$MODPATH" >&2
    ui_print "- Installing Bellavita Toast..."
    pm install "$MODPATH/toast.apk"
    rm "$MODPATH/toast.apk"
fi


# Make module config 
make_node 0 "$MODULE_CONFIG/clearbg"
make_node 0 "$MODULE_CONFIG/bypass"
make_node 0 "$MODULE_CONFIG/APreload"
make_node 0 "$MODULE_CONFIG/logger"
make_node 0 "$MODULE_CONFIG/logd"
make_node 0 "$MODULE_CONFIG/DThermal"
make_node 0 "$MODULE_CONFIG/dnd"
make_node 0 "$MODULE_CONFIG/schedtunes"
make_node 0 "$MODULE_CONFIG/fpsged"
make_node 0 "$MODULE_CONFIG/iosched"
make_node 0 "$MODULE_CONFIG/SFL"
make_node 0 "$MODULE_CONFIG/malisched"
make_node 0 "$MODULE_CONFIG/cpulimit"
make_node "1000 1000 1000 1000" "$MODULE_CONFIG/color_scheme"
make_node "Disabled 90% 80% 70% 60% 50% 40%" "$MODULE_CONFIG/availableFreq"
make_node "Disabled" "$MODULE_CONFIG/customFreqOffset"
make_node "Disabled 60hz 90hz 120hz" "$MODULE_CONFIG/availableValue"
make_node "Disabled" "$MODULE_CONFIG/customVsync"

# Make sure to enable Auto Every installment and Update
echo 1 > "$MODULE_CONFIG/AIenabled"

# Remove useless files
ui_print "- Cleaning up files..."
rm -rf "$MODPATH/webroot/include" "$MODPATH/gamelist.txt" "$MODPATH/toast.apk"

# Set Permissions
ui_print "- Setting Permissions..."
set_perm_recursive "$MODPATH/system/bin" 0 2000 0777 0777
chmod +x "$MODPATH/system/bin/AZenith"
chmod +x "$MODPATH/system/bin/AZenith_Profiler"
chmod +x "$MODPATH/system/bin/bypassCharge"
chmod +x "$MODPATH/system/bin/vmt"

ui_print "- Installation complete!"