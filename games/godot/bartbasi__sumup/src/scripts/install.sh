#!/usr/bin/env bash
# Installs build/sumup-debug.apk on the Android phone connected by USB.
# An installed copy is replaced and its saved game is kept.
#
# Run from any folder, in Git Bash:
#   scripts/install.sh
#
# adb comes from C:\Android\Sdk\platform-tools. Set the ADB environment
# variable to use another adb.exe. With more than one device connected, set
# ANDROID_SERIAL to the serial number "adb devices" shows for the phone.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
adb="${ADB:-C:/Android/Sdk/platform-tools/adb.exe}"
apk="$root/build/sumup-debug.apk"

if [ ! -f "$adb" ]; then
	echo "adb was not found at $adb. Install Android SDK Platform-Tools there, or set ADB to the full path of adb.exe."
	exit 1
fi
if [ ! -f "$apk" ]; then
	echo "There is no APK at $apk. Build it first: scripts/build.sh"
	exit 1
fi

# "adb devices" prints a header, then one "serial<TAB>state" line per device.
if ! listing="$("$adb" devices | tr -d '\r')"; then
	echo "adb could not list devices."
	exit 1
fi
devices="$(printf '%s\n' "$listing" | tail -n +2 | awk 'NF >= 2 { print $1, $2 }')"
if [ -n "${ANDROID_SERIAL:-}" ]; then
	devices="$(printf '%s\n' "$devices" | awk -v s="$ANDROID_SERIAL" '$1 == s')"
fi
ready="$(printf '%s\n' "$devices" | awk '$2 == "device" { print $1 }')"

if [ -z "$devices" ]; then
	echo "No Android device is connected."
	echo "Plug the phone in with a USB data cable, unlock it, and check that USB debugging is on (README.md, \"Install on a phone\"). Then run this again."
	exit 1
fi
if [ -z "$ready" ]; then
	echo "A device is connected but not ready: $(printf '%s\n' "$devices" | awk '{ printf "%s%s is %s", (NR > 1 ? ", " : ""), $1, $2 }')."
	echo "If it says unauthorized: unlock the phone and tap Allow on the \"Allow USB debugging?\" prompt. If it says offline: unplug the cable and plug it in again. Then run this again."
	exit 1
fi
if [ "$(printf '%s\n' "$ready" | wc -l)" -gt 1 ]; then
	echo "More than one device is ready. Unplug the others, or set ANDROID_SERIAL to the phone's serial number:"
	printf '  %s\n' $ready
	exit 1
fi

echo "Installing on $ready..."
if ! "$adb" -s "$ready" install -r "$apk"; then
	echo "The install failed. If adb says INSTALL_FAILED_UPDATE_INCOMPATIBLE, the copy on the phone was signed by another computer: uninstall SumUp on the phone (this deletes its saved game) and run this again."
	exit 1
fi
echo "Installed. Open SumUp from the phone's app list."
