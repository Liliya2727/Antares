#!/system/bin/sh

# Configuration flags
SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=true
LATESTARTSERVICE=true

# Get module version and author from module.prop
MODVER=$(grep "^version=" "$MODPATH/module.prop" | cut -d '=' -f2)
AUTHOR=$(grep "^author=" "$MODPATH/module.prop" | cut -d '=' -f2)

# List of system paths to replace (if any)
REPLACE=""

# Display banner
ui_print
ui_print "              AZenith              "
ui_print
ui_print "- Release Date  : 14/03/2025"
ui_print "- Author          : ${AUTHOR}"
ui_print "- Version         : ${MODVER}"
ui_print "- Device          : $(getprop ro.product.board) $(getprop ro.product.cpu.abi)"
ui_print "- Build Date    : $(getprop ro.build.date)"
sleep 1
ui_print "- Installing AZenith..."
sleep 1

# Extracting module files
ui_print "- Creating necessary directories..."
mkdir -p /data/AZenith

ui_print "- Extracting system files..."
extract -o "$ZIPFILE" 'system/*' -d "$MODPATH" >&2

ui_print "- Extracting libs files..."
extract -o "$ZIPFILE" 'libs/*' -d "$MODPATH" >&2

ui_print "- Extracting webroot files..."
extract -o "$ZIPFILE" 'webroot/*' -d "$MODPATH" >&2

ui_print "- Extracting service script..."
unzip -o "$ZIPFILE" 'service.sh' -d "$MODPATH" >&2

ui_print "- Extracting gamelist.txt..."
unzip -qo "$ZIPFILE" 'gamelist.txt' -d "/data/AZenith" >&2

ui_print "- Extracting icon..."
unzip -qo "$ZIPFILE" 'AZenith_icon.png' -d "/data/local/tmp" >&2
sleep 1

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

# Setting permissions
ui_print "- Setting permissions..."
set_perm_recursive "$MODPATH/system/bin/*" 0 0 0777 0755
set_perm_recursive "$MODPATH/libs/*" 0 0 0777 0755
set_perm_recursive "/data/AZenith" 0 0 0777 0755

# Final permission setup
ui_print "- Finalizing installation..."
set_perm_recursive "$MODPATH" 0 0 0777 0777
sleep 2

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