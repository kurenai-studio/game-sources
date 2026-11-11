#!/bin/sh
set -eu
destination="${XDG_DATA_HOME:-$HOME/.local/share}/horse-racing-sd"
menu_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
# Remove only this release's installed files. Never remove user saves or unknown files.
for name in horse-racing horse-racing.pck LICENSE THIRD_PARTY_NOTICES.md README.txt uninstall.sh; do
  rm -f -- "$destination/$name"
done
for name in QUICK_START.html USER_MANUAL.html; do rm -f -- "$destination/docs/$name"; done
for name in GODOT-LICENSE.txt GODOT-COPYRIGHT.txt NSIS-COPYING.txt AUDIO-NOTICE.txt; do
  rm -f -- "$destination/licenses/$name"
done
rm -f -- "$menu_dir/horse-racing-sd.desktop"
rmdir -- "$destination/docs" "$destination/licenses" "$destination" 2>/dev/null || true
printf 'Horse Racing removed. Saved games and any extra files were preserved.\n'
