#!/bin/sh
set -eu
source_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
destination="${XDG_DATA_HOME:-$HOME/.local/share}/horse-racing-sd"
menu_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
mkdir -p "$destination/docs" "$destination/licenses" "$menu_dir"
for name in horse-racing horse-racing.pck LICENSE THIRD_PARTY_NOTICES.md README.txt uninstall.sh; do
  cp "$source_dir/$name" "$destination/$name"
done
cp "$source_dir/docs/QUICK_START.html" "$source_dir/docs/USER_MANUAL.html" "$destination/docs/"
for name in GODOT-LICENSE.txt GODOT-COPYRIGHT.txt NSIS-COPYING.txt AUDIO-NOTICE.txt; do
  cp "$source_dir/licenses/$name" "$destination/licenses/$name"
done
chmod +x "$destination/horse-racing" "$destination/uninstall.sh"
# Quote the executable path for the desktop entry and escape desktop field codes.
escaped=$(printf '%s' "$destination/horse-racing" | sed 's/\\/\\\\/g; s/"/\\"/g; s/`/\\`/g; s/\$/\\$/g; s/%/%%/g')
cat > "$menu_dir/horse-racing-sd.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Horse Racing
Comment=SD mode horse racing game
Exec="$escaped"
Terminal=false
Categories=Game;SportsGame;
EOF
printf 'Installed Horse Racing in %s\nSaved games remain separate.\n' "$destination"
