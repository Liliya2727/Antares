#!/system/bin/sh

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
"

# Display banner
ui_print ""
ui_print "              AZenith              "
ui_print ""
ui_print "- Release Date  : 27/03/2025"
ui_print "- Author        : ${AUTHOR}"
ui_print "- Version       : ${MODVER}"
ui_print "- Device        : $(getprop ro.product.board)"
ui_print "- Build Date    : $(getprop ro.build.date)"
sleep 1
ui_print "- Installing AZenith..."
sleep 1

# Extracting module files
ui_print "- Creating necessary directories..."
mkdir -p /data/AZenith

ui_print "- Extracting functions.sh"
extract -qjo "$ZIPFILE" 'common/functions.sh' -d $TMPDIR >&2
$TMPDIR/functions.sh

ui_print "- Extracting system files..."
extract -o "$ZIPFILE" 'system/*' -d "$MODPATH" >&2

ui_print "- Extracting system.prop..."
extract -o "$ZIPFILE" 'system.prop*' -d "$MODPATH" >&2

ui_print "- Extracting libs files..."
extract -o "$ZIPFILE" 'libs/*' -d "$MODPATH" >&2

ui_print "- Extracting service script..."
unzip -o "$ZIPFILE" 'service.sh' -d "$MODPATH" >&2

ui_print "- Extracting gamelist.txt..."
unzip -qo "$ZIPFILE" 'gamelist.txt' -d "/data/AZenith" >&2

ui_print "- Extracting icon..."
unzip -qo "$ZIPFILE" 'AZenith_icon.png' -d "/data/local/tmp" >&2
sleep 1

# Checking path
ui_print "- Checking Bypass compatibility..."
sleep 3

# Check Bypass Path
bypasspath=""
for path in $bypasslist; do
    if checkpath "$path"; then
        bypasspath="$path"
        break 
    fi
done

# Notify User
if [ -z "$bypasspath" ]; then
    ui_print "- Bypass Charging is Unsupported!"
    mv "$MODPATH/assets/indexnbhtml" "$MODPATH/webroot/index.html"
    mv "$MODPATH/assets/fn762agnbjs" "$MODPATH/webroot/fn762ag.js"
    else
    ui_print "- Bypass Charging is Supported!"
    ui_print "- Using path: $path"
    mv "$MODPATH/assets/indexbphtml" "$MODPATH/webroot/index.html"
    mv "$MODPATH/assets/fn762agbpjs" "$MODPATH/webroot/fn762ag.js"
fi


# Installing toast notification
if pm list packages | grep -q bellavita.toast; then
    ui_print "- Bellavita Toast is already installed."
else
    ui_print "- Extracting Bellavita Toast..."
    unzip -o "$ZIPFILE" 'toast.apk' -d "$MODPATH" >&2
    ui_print "- Installing Bellavita Toast..."
    pm install "$MODPATH/toast.apk"
    rm "$MODPATH/toast.apk"
fi

# Determine Chipset
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

# Cihuy
mv "$MODPATH/assets/availableFreq" "/data/AZenith/availableFreq"
mv "$MODPATH/assets/customFreqOffset" "/data/AZenith/customFreqOffset"

# Extract WebUI
ui_print "- Extracting WebUI"
mv "$MODPATH/assets/indexhtml" "$MODPATH/webroot/index.html"
sleep 2

# Remove File
rm -rf "$MODPATH/assets"

# Final permission setup
ui_print "- Setting Permissions..."
set_perm_recursive "$MODPATH" 0 0 0755 0644
sleep 2

# Setting permissions
ui_print "- Finalizing Installations..."
set_perm_recursive "$MODPATH/system/bin" 0 2000 0777 0777
chmod +x "$MODPATH/system/bin/AZenith" 
set_perm_recursive $MODPATH/vendor 0 0 0755 0755

ui_print "- Installation complete!"

# Random message 
case "$((RANDOM % 14 + 1))" in
  1)  ui_print "- 勝利を掴め! (Shōri o tsukame!)" ;;
  2)  ui_print "- 逃げるな! 反撃せよ! (Nigeru na! Hangeki seyo!)" ;;
  3)  ui_print "- 初撃! (Shogeki!)" ;;
  4)  ui_print "- 全滅! (Zemmetsu!)" ;;
  5)  ui_print "- 伝説だ! 誰も止められない! (Densetsu da! Daremo tomerarenai!)" ;;
  6)  ui_print "- 亀が復活するぞ! (Kame ga fukkatsu suru zo!)" ;;
  7)  ui_print "- 我々の砲塔が攻撃されている! (Wareware no hōtō ga kōgeki sa rete iru!)" ;;
  8)  ui_print "- 敵を撃破! (Teki o gekiha!)" ;;
  9)  ui_print "- 勇者に勝利あり! (Yūsha ni shōri ari!)" ;;
  10) ui_print "- 止めた! もう支配させない! (Tometa! Mō shihai sasenai!)" ;;
  11) ui_print "- 撤退せよ! (Tettai seyo!)" ;;
  12) ui_print "- 戦場に嵐を呼べ! (Senjō ni arashi o yobe!)" ;;
  13) ui_print "- よくやった! だが戦いは続く! (Yoku yatta! Daga tatakai wa tsuzuku!)" ;;
  14) ui_print "- 最強のチームが勝つ! (Saikyō no chīmu ga katsu!)" ;;
esac