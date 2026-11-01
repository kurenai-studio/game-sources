#!/usr/bin/env bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# Builds the signed release files with Godot's Gradle build:
#   build/forkline-release.aab   the app bundle for Play (upload key signed)
#   build/forkline-release.apk   a release APK for side loading (same key)
# Run from any folder, in Git Bash:
#   scripts/build_release.sh
#
# The upload key lives outside the repo, in %APPDATA%\Forkline\release\
# (forkline-upload.keystore and forkline-upload.password). Set FORKLINE_RELEASE_DIR
# to use another folder. The script gives the key to Godot through the
# GODOT_ANDROID_KEYSTORE_RELEASE_* environment variables, only for the export
# commands, and never prints the password. No key, user or password is in
# export_presets.cfg.
#
# The first run installs Godot's Android build template into android/ (ignored by
# git) and Gradle downloads its build tools into your Gradle cache. That is build
# tooling only. Godot 4.7.2 must be on PATH as "godot", or set GODOT. The Android
# SDK and the JDK come from Godot's Editor Settings, never from this repo.
#
# It builds only from a clean git checkout and has no way to skip that. Use a
# clean clone of the tagged commit (docs/release.md). Never run it with --verbose.
#
# Any failure prints "BUILD FAILED: ..." and exits 1.

set -euo pipefail
# Never trace: a trace would print the password.
set +x

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot="${GODOT:-godot}"
class_cache="$root/.godot/global_script_class_cache.cfg"
want_version="4.7.2.stable"
alias_name="forkline-upload"
attempts=3
started="$(date +%s)"

fail() {
	echo "BUILD FAILED: $1"
	exit 1
}

[ "$#" -eq 0 ] || fail "this script takes no options. A release is always built from a clean commit."

for tool in timeout unzip cygpath; do
	command -v "$tool" > /dev/null 2>&1 || fail "'$tool' was not found. Run this script in Git Bash."
done
command -v "$godot" > /dev/null 2>&1 || fail "Godot was not found as '$godot'. Install Godot $want_version or set GODOT to the full path of its exe."

version="$("$godot" --version | tr -d '\r' | tail -n 1)"
case "$version" in
	"$want_version"*) echo "Godot $version" ;;
	*) fail "This project needs Godot $want_version, but '$godot' is version '$version'." ;;
esac

# A release is built only from a commit, never from a dirty tree and never from
# a folder that git cannot check. There is no option to skip this.
bash "$root/scripts/check_clean.sh" || fail "the release must be built from a clean git checkout. Commit first, or build from a clean clone of the tagged commit."

# The upload key. Read it here, hand it to Godot only for the export commands.
key_dir="${FORKLINE_RELEASE_DIR:-}"
if [ -z "$key_dir" ]; then
	[ -n "${APPDATA:-}" ] || fail "APPDATA is not set, so the key folder cannot be found. Set FORKLINE_RELEASE_DIR."
	key_dir="$(cygpath -u "$APPDATA")/Forkline/release"
fi
keystore="$key_dir/forkline-upload.keystore"
pass_file="$key_dir/forkline-upload.password"
[ -f "$keystore" ] || fail "the upload keystore was not found in the key folder (forkline-upload.keystore). See docs/release.md."
[ -f "$pass_file" ] || fail "the password file was not found in the key folder (forkline-upload.password). See docs/release.md."
store_pass="$(head -n 1 "$pass_file" | tr -d '\r\n')"
[ -n "$store_pass" ] || fail "the password file is empty."
keystore_native="$(cygpath -w "$keystore")"

# The tracked files must hold no key or password before we build.
if ! bash "$root/scripts/check_secrets.sh" > /dev/null 2>&1; then
	bash "$root/scripts/check_secrets.sh" || true
	fail "a tracked file holds a keystore password or path. Fix it first."
fi

# Import until Godot has written its class cache (see build.sh).
echo "Importing the project..."
imported=0
for n in $(seq 1 "$attempts"); do
	rm -f "$class_cache"
	code=0
	timeout 300 "$godot" --headless --path "$root" --import || code=$?
	if [ "$code" -eq 0 ] && [ -s "$class_cache" ]; then
		imported=1
		break
	fi
	echo "Import attempt $n of $attempts did not finish (exit code $code)."
done
[ "$imported" -eq 1 ] || fail "the import did not finish after $attempts attempts. Read the Godot output above."

# Install Godot's Android build template into android/ (git ignores it). Godot
# checks android/.build_version against its own version.
tpl="$(cygpath -u "${APPDATA:-}")/Godot/export_templates/$want_version/android_source.zip"
[ -f "$tpl" ] || fail "Godot's Android source template was not found at $tpl. Install the export templates."
if [ ! -d "$root/android/build" ] || [ "$(cat "$root/android/.build_version" 2> /dev/null || true)" != "$want_version" ]; then
	echo "Installing the Android build template into android/ ..."
	rm -rf "$root/android"
	mkdir -p "$root/android/build"
	unzip -q "$tpl" -d "$root/android/build"
	: > "$root/android/.gdignore"
	: > "$root/android/build/.gdignore"
	printf '%s' "$want_version" > "$root/android/.build_version"
fi

mkdir -p "$root/build"
# Note: unlike build.sh, this script does not give Godot a private temp folder. Gradle's
# background process keeps its temp folder from the first run, so a folder that is deleted
# afterwards makes the next build fail ("NoSuchFileException ... tempdir"). Godot's Gradle
# export does not use the shared name that the private folder works around.

# export_one <preset name> <output file> <kind>
export_one() {
	local preset="$1" out="$2" kind="$3" n code
	echo "Exporting the $kind ..."
	for n in $(seq 1 "$attempts"); do
		rm -f "$out" "$out.idsig"
		code=0
		GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$keystore_native" \
			GODOT_ANDROID_KEYSTORE_RELEASE_USER="$alias_name" \
			GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$store_pass" \
			timeout 1200 "$godot" --headless --path "$root" --export-release "$preset" "$out" || code=$?
		if [ "$code" -eq 0 ] && [ -f "$out" ] \
			&& [ "$(stat -c %Y "$out")" -ge "$started" ] \
			&& [ "$(wc -c < "$out")" -gt 1048576 ] \
			&& unzip -tq "$out" > /dev/null 2>&1; then
			echo "Built $out (about $(( $(wc -c < "$out") / 1048576 )) MB)"
			return 0
		fi
		echo "Export attempt $n of $attempts failed (exit code $code)."
		rm -f "$out"
	done
	fail "the $kind export did not produce a good file after $attempts attempts. Read the Godot output above."
}

export_one "Android Release AAB" "$root/build/forkline-release.aab" "app bundle (AAB)"
export_one "Android Release APK" "$root/build/forkline-release.apk" "release APK"

echo
echo "Check them with:"
echo "  scripts/check_aab.sh"
echo "  scripts/check_apk.sh --release"
