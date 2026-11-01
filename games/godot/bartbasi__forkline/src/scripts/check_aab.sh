#!/usr/bin/env bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# Checks a built release app bundle (AAB). Run from any folder, in Git Bash:
#   scripts/check_aab.sh [path-to-aab]     (default: build/forkline-release.aab)
#
# bundletool is not used. An AAB is a zip, so the script reads it with unzip and
# turns the base module into a plain APK with aapt2 convert, only to read its
# manifest and resources. Nothing is installed or downloaded.
#
# It prints everything the bundle holds, then checks that:
#   1. the bundle requests no permissions at all (manifest elements, and the raw
#      manifest bytes of the base module and of the asset pack);
#   2. only arm64-v8a native code is inside;
#   3. LICENSE, NOTICE and the font license are inside, every file under data/
#      is inside, and tools, tests, docs, prototypes and scripts are not;
#   4. the package is io.github.bartbasi.forkline and the version code and name
#      match export_presets.cfg;
#   5. the manifest has targetSdkVersion 36, portrait, resizeable, appCategory
#      game, allowBackup false, the configChanges ARCHITECTURE 7.6 lists, and is
#      not debuggable;
#   6. the launcher icons are Forkline's, not Godot's stock icon;
#   7. the bundle is signed, not with the Android debug certificate, and the
#      signature verifies. If the upload key folder is on this machine, the
#      certificate must be the upload key's;
#   8. every bundled third party part is credited in NOTICE and README.md.
# Exit code 0 means every check passed. 1 means a permission, a missing or wrong
# file or value, or a missing tool. 2 means a bundled part is not credited.
#
# The game files sit in the bundle's install time asset pack, under
# assetPackInstallTime/assets/. That is how Godot's Gradle build lays them out.
# Needs aapt2 and dexdump from the Android SDK build-tools (C:\Android\Sdk, or set
# ANDROID_SDK), plus unzip, jar, jarsigner and keytool from the JDK.
# The credit table below matches check_apk.sh. Keep the two in step.

set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
aab="${1:-$root/build/forkline-release.aab}"
sdk="${ANDROID_SDK:-C:/Android/Sdk}"
failed=0
uncredited=0
missing=""

if [ ! -f "$aab" ]; then
	echo "There is no AAB at $aab. Build it first (scripts/build_release.sh)."
	exit 1
fi
aab="$(cd "$(dirname "$aab")" && pwd)/$(basename "$aab")"
tools_dir="$(ls -d "$sdk"/build-tools/* 2> /dev/null | sort -V | tail -n 1)"
aapt2="$tools_dir/aapt2.exe"
dexdump="$tools_dir/dexdump.exe"
[ -f "$aapt2" ] || aapt2="$tools_dir/aapt2"
[ -f "$dexdump" ] || dexdump="$tools_dir/dexdump"
if [ -z "$tools_dir" ] || [ ! -f "$aapt2" ] || [ ! -f "$dexdump" ]; then
	echo "aapt2 and dexdump were not found in $sdk/build-tools. Install Android SDK Build-Tools, or set ANDROID_SDK."
	exit 1
fi
java_bin=""
for t in jar jarsigner keytool; do
	if ! command -v "$t" > /dev/null 2>&1; then
		if [ -n "${JAVA_HOME:-}" ] && [ -f "$JAVA_HOME/bin/$t.exe" ]; then
			java_bin="$JAVA_HOME/bin/"
		else
			echo "$t (JDK) was not found. Put the JDK on PATH or set JAVA_HOME."
			exit 1
		fi
	fi
done
for t in unzip; do
	command -v "$t" > /dev/null 2>&1 || { echo "$t was not found. Run this in Git Bash."; exit 1; }
done

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

echo "AAB: $aab"
echo
echo "== Everything the bundle holds (unzip -l) =="
unzip -l "$aab"
entries="$(unzip -Z1 "$aab")"
if ! unzip -q "$aab" -d "$work/x"; then
	echo "FAIL: the bundle could not be unpacked."
	exit 1
fi

# Turn the base module into a plain APK, only to read its manifest and resources.
mkdir -p "$work/conv"
cp "$work/x/base/resources.pb" "$work/conv/resources.pb"
cp -r "$work/x/base/res" "$work/conv/res"
cp "$work/x/base/manifest/AndroidManifest.xml" "$work/conv/AndroidManifest.xml"
"${java_bin}jar" cMf "$work/proto.zip" -C "$work/conv" .
if ! "$aapt2" convert -o "$work/base.apk" --output-format binary "$work/proto.zip" > "$work/convert.log" 2>&1; then
	cat "$work/convert.log"
	echo "FAIL: aapt2 could not read the base module."
	exit 1
fi
base_apk="$work/base.apk"

echo
echo "== Modules =="
printf '%s\n' "$entries" | grep -E '^[^/]+/manifest/AndroidManifest.xml$'

echo
echo "== Native libraries =="
libs="$(printf '%s\n' "$entries" | grep -E '(^|/)lib/' || true)"
printf '%s\n' "$libs"
if printf '%s\n' "$libs" | grep -v '^base/lib/arm64-v8a/' | grep -q .; then
	echo "FAIL: native code for another architecture is inside. Only arm64-v8a is allowed."
	failed=1
fi

echo
echo "== Files that must not be inside =="
leaked="$(printf '%s\n' "$entries" | grep -E '^[^/]+/assets/(tools|tests|docs|prototypes|scripts)/' || true)"
if [ -n "$leaked" ]; then
	printf '%s\n' "$leaked"
	echo "FAIL: left-out folders are inside the bundle."
	failed=1
else
	echo "None of tools/, tests/, docs/, prototypes/, scripts/ is inside."
fi
pack="assetPackInstallTime/assets"
for f in LICENSE NOTICE src/theme/fonts/OFL.txt; do
	if printf '%s\n' "$entries" | grep -qxF "$pack/$f"; then
		echo "$pack/$f is inside."
	else
		echo "FAIL: $pack/$f is missing from the bundle."
		failed=1
	fi
done

echo
echo "== Files under data/ =="
data_files="$(cd "$root" 2> /dev/null && find data -type f ! -name '*.uid' 2> /dev/null | sort || true)"
if [ -z "$data_files" ]; then
	echo "Note: data/ has no files, so there is nothing to check."
else
	data_count=0
	data_missing=0
	while IFS= read -r f; do
		[ -n "$f" ] || continue
		data_count=$((data_count + 1))
		if ! printf '%s\n' "$entries" | grep -qxF "$pack/$f"; then
			echo "FAIL: $pack/$f is missing from the bundle."
			data_missing=1
			failed=1
		fi
	done <<< "$data_files"
	echo "$data_count file(s) under data/ checked."
	[ "$data_missing" -eq 0 ] && echo "Every file under data/ is inside."
fi

echo
echo "== Permissions in the manifests =="
perm_out="$("$aapt2" dump permissions "$base_apk" 2> /dev/null | tr -d '\r')"
perm_rc=$?
perm_lines="$(printf '%s\n' "$perm_out" | grep -v '^package:' | grep -v '^$' || true)"
manifest="$("$aapt2" dump xmltree --file AndroidManifest.xml "$base_apk" 2> /dev/null | tr -d '\r')"
manifest_perms="$(printf '%s\n' "$manifest" | grep -E 'E: (uses-permission|permission|uses-permission-sdk-23)' || true)"
raw_perms=""
for m in "$work"/x/*/manifest/AndroidManifest.xml; do
	if grep -a -q 'uses-permission' "$m"; then
		raw_perms="$raw_perms$m"$'\n'
	fi
done
if [ "$perm_rc" -ne 0 ] || [ -z "$manifest" ]; then
	echo "FAIL: aapt2 could not read the manifest."
	failed=1
elif [ -n "$perm_lines" ] || [ -n "$manifest_perms" ] || [ -n "$raw_perms" ]; then
	printf '%s\n' "$perm_lines"
	printf '%s\n' "$manifest_perms"
	printf '%s' "$raw_perms" | sed "s|$work/x/||"
	echo "FAIL: the bundle requests permissions. Forkline must request none."
	failed=1
else
	echo "None. No module requests a permission."
fi
other_perm_attr="$(printf '%s\n' "$manifest" | grep -E 'android:permission\(' | sed 's/^ *//; s|http://schemas.android.com/apk/res/android:||' || true)"
if [ -n "$other_perm_attr" ]; then
	echo "Note: a component asks its callers for a permission (this is not a request by the app):"
	printf '%s\n' "$other_perm_attr"
fi

echo
echo "== Package and version =="
want_package="io.github.bartbasi.forkline"
want_code="$(sed -n 's/^version\/code=//p' "$root/export_presets.cfg" | head -n 1 | tr -d '\r')"
want_name="$(sed -n 's/^version\/name="\(.*\)"$/\1/p' "$root/export_presets.cfg" | head -n 1 | tr -d '\r')"
badge="$("$aapt2" dump badging "$base_apk" 2> /dev/null | tr -d '\r' | grep -m1 '^package:' || true)"
got_package="$(printf '%s\n' "$badge" | sed -n "s/^package: name='\([^']*\)'.*/\1/p")"
got_code="$(printf '%s\n' "$badge" | sed -n "s/.*versionCode='\([^']*\)'.*/\1/p")"
got_name="$(printf '%s\n' "$badge" | sed -n "s/.*versionName='\([^']*\)'.*/\1/p")"
if [ "$got_package" = "$want_package" ] && [ -n "$want_code" ] && [ "$got_code" = "$want_code" ] && [ -n "$want_name" ] && [ "$got_name" = "$want_name" ]; then
	echo "OK: package $got_package, version code $got_code, version name $got_name (the code and name match export_presets.cfg)."
else
	echo "FAIL: package '$got_package' code '$got_code' name '$got_name'. Expected $want_package, code '$want_code', name '$want_name' (from export_presets.cfg)."
	failed=1
fi

echo
echo "== Manifest values (ARCHITECTURE 7.6) =="
printf '%s\n' "$manifest" | grep -E 'android:(icon|appCategory|isGame|allowBackup|debuggable|targetSdkVersion|screenOrientation|resizeableActivity|configChanges)\(' | sed 's/^ *//; s|http://schemas.android.com/apk/res/android:||'
manifest_value() {
	printf '%s\n' "$manifest" | grep -m1 -E "android:$1\(" | sed 's/.*)=//; s/ (Raw:.*//'
}
expect_value() { # attribute, expected value, meaning
	local got
	got="$(manifest_value "$1")"
	if [ "$got" = "$2" ]; then
		echo "OK: $1 is $got ($3)."
	else
		echo "FAIL: $1 is '$got', expected $2 ($3)."
		failed=1
	fi
}
expect_value targetSdkVersion 36 "target API 36"
expect_value screenOrientation 1 "portrait"
expect_value resizeableActivity true "resizable"
expect_value appCategory 0 "game"
expect_value allowBackup false "no backup of saves"
debuggable="$(manifest_value debuggable)"
case "$debuggable" in
	""|false|"(type 0x12)0x0") echo "OK: debuggable is absent or false (not debuggable)." ;;
	*) echo "FAIL: android:debuggable is '$debuggable'. A release bundle must not be debuggable."; failed=1 ;;
esac
changes="$(manifest_value configChanges)"
if [ -n "$changes" ] && [ $(( changes & 0x1d80 )) -eq $(( 0x1d80 )) ]; then
	echo "OK: configChanges is $changes, it includes 0x1d80 (orientation, screenLayout, screenSize, smallestScreenSize, density)."
else
	echo "FAIL: configChanges is '$changes', it must include 0x1d80."
	failed=1
fi

echo
echo "== Launcher icons are Forkline's, not Godot's stock icon =="
tpl_dir="${APPDATA:-}/Godot/export_templates/4.7.2.stable"
command -v cygpath > /dev/null 2>&1 && tpl_dir="$(cygpath -u "$tpl_dir")"
tpl="$tpl_dir/android_debug.apk"
if [ ! -f "$tpl" ]; then
	echo "FAIL: Godot's export template was not found at $tpl, so the icons cannot be compared."
	failed=1
else
	base_entries="$(unzip -Z1 "$base_apk")"
	icon_files="$(unzip -Z1 "$tpl" | grep -E '^res/mipmap(-[a-z0-9]+-v4)?/icon(_background|_foreground|_monochrome)?\.webp$' || true)"
	res_table="$("$aapt2" dump resources "$base_apk" 2> /dev/null | tr -d '\r')"
	icon_path() { # resource name, density ("" for the default)
		printf '%s\n' "$res_table" | awk -v want="mipmap/$1" -v dens="($2)" '
			$1 == "resource" { on = ($3 == want); next }
			on && $1 == dens && $2 == "(file)" { print $3; exit }'
	}
	icon_count=0
	icon_bad=0
	while IFS= read -r f; do
		[ -n "$f" ] || continue
		icon_count=$((icon_count + 1))
		name="$(basename "$f" .webp)"
		dens="$(printf '%s\n' "$f" | sed -n 's|^res/mipmap-\([a-z0-9]*\)-v4/.*|\1|p')"
		in_apk="$(icon_path "$name" "$dens")"
		stock="$(unzip -p "$tpl" "$f" | md5sum | cut -d' ' -f1)"
		if [ -z "$in_apk" ] || ! printf '%s\n' "$base_entries" | grep -qxF "$in_apk"; then
			echo "FAIL: the $name icon for '${dens:-default}' is missing from the bundle."
			icon_bad=1
		else
			mine="$(unzip -p "$base_apk" "$in_apk" 2> /dev/null | md5sum | cut -d' ' -f1)"
			if [ "$mine" = "$stock" ]; then
				echo "FAIL: $in_apk ($name, ${dens:-default}) is Godot's stock icon (md5 $stock)."
				icon_bad=1
			fi
		fi
	done <<< "$icon_files"
	if [ -z "$(icon_path icon anydpi-v26)" ]; then
		echo "FAIL: the adaptive icon (mipmap/icon for anydpi-v26) is missing."
		icon_bad=1
	fi
	if [ "$icon_count" -eq 0 ]; then
		echo "FAIL: no stock icon files were found in the template, so nothing was compared."
		icon_bad=1
	fi
	if [ "$icon_bad" -eq 0 ]; then
		echo "OK: all $icon_count launcher icon files differ from Godot's template, and the adaptive icon is present."
	else
		failed=1
	fi
fi

echo
echo "== Signature =="
jarsigner_out="$("${java_bin}jarsigner" -verify "$aab" < /dev/null 2>&1 | tr -d '\r')"
if printf '%s\n' "$jarsigner_out" | grep -q '^jar verified'; then
	echo "OK: the signature verifies (jarsigner -verify)."
else
	printf '%s\n' "$jarsigner_out" | head -n 5
	echo "FAIL: the bundle is not signed, or the signature does not verify."
	failed=1
fi
certs="$("${java_bin}keytool" -printcert -jarfile "$aab" < /dev/null 2>&1 | tr -d '\r')"
dn="$(printf '%s\n' "$certs" | grep -m1 -E 'Owner:' || true)"
sha="$(printf '%s\n' "$certs" | grep -m1 -E 'SHA256:' | sed 's/^ *//' || true)"
if [ -z "$dn" ]; then
	echo "FAIL: no signing certificate could be read from the bundle."
	failed=1
elif printf '%s\n' "$dn" | grep -qi 'CN=Android Debug'; then
	echo "$dn"
	echo "FAIL: the bundle is signed with the Android debug certificate. Play needs the upload key."
	failed=1
else
	echo "OK: not signed with the Android debug certificate."
	echo "$dn"
	echo "$sha"
fi
key_dir="${FORKLINE_RELEASE_DIR:-}"
if [ -z "$key_dir" ] && [ -n "${APPDATA:-}" ]; then
	key_dir="$(cygpath -u "$APPDATA" 2> /dev/null || echo "$APPDATA")/Forkline/release"
fi
if [ -f "$key_dir/forkline-upload.keystore" ] && [ -f "$key_dir/forkline-upload.password" ]; then
	key_sha="$("${java_bin}keytool" -list -v -keystore "$key_dir/forkline-upload.keystore" -storepass:file "$key_dir/forkline-upload.password" < /dev/null 2> /dev/null | tr -d '\r' | grep -m1 'SHA256:' | sed 's/^ *//' || true)"
	if [ -n "$key_sha" ] && [ "$key_sha" = "$sha" ]; then
		echo "OK: the certificate is the upload key in the key folder."
	else
		echo "FAIL: the certificate is not the upload key in the key folder."
		failed=1
	fi
else
	echo "Note: no upload key folder on this machine, so the certificate was not compared with it."
fi

echo
echo "== Libraries Gradle added (META-INF/*.version) =="
printf '%s\n' "$entries" | grep -E '^base/root/META-INF/[^/]+\.version$' | sed 's|.*/META-INF/||; s|\.version$||'

echo
echo "== Java packages defined in classes*.dex (class count, package) =="
if ! ls "$work"/x/base/dex/classes*.dex > /dev/null 2>&1; then
	echo "FAIL: no classes*.dex is in the base module, so its Java packages cannot be checked."
	exit 1
fi
descriptors="$("$dexdump" -f "$work"/x/base/dex/classes*.dex | tr -d '\r' | grep 'Class descriptor' | sed "s/.*'L\(.*\);'.*/\1/")"
if [ -z "$descriptors" ]; then
	echo "FAIL: dexdump read no classes from the bundle, so its Java packages cannot be checked."
	exit 1
fi
roots="$(printf '%s\n' "$descriptors" | awk -F/ '
	{
		if ($1 == "org" || $1 == "com" || $1 == "net" || $1 == "io" || $1 == "android") { print $1 "/" $2 } else { print $1 }
	}' | sort | uniq -c | sort -rn)"
printf '%s\n' "$roots"

credit_for() {
	case "$1" in
		org/godotengine|com/godot|libgodot_android.so) echo "Godot Engine|Godot Engine" ;;
		androidx|android/support) echo "AndroidX (Android Open Source Project)|AndroidX" ;;
		kotlin) echo "Kotlin standard library (JetBrains)|Kotlin" ;;
		kotlinx) echo "kotlinx.coroutines (JetBrains)|kotlinx.coroutines" ;;
		org/jetbrains|org/intellij) echo "JetBrains Java Annotations|JetBrains" ;;
		org/jspecify) echo "JSpecify annotations|JSpecify" ;;
		com/google) echo "Google Guava ListenableFuture|Guava" ;;
		libc++_shared.so) echo "LLVM libc++|libc++" ;;
		*) echo "UNKNOWN|" ;;
	esac
}

echo
echo "== Bundled third party parts, compared with NOTICE and README.md =="
parts="$(printf '%s\n' "$roots" | awk '{ print $2 }'; printf '%s\n' "$libs" | sed 's|.*/||' | grep .)"
printf '%-28s %-44s %-8s %s\n' "package or file" "part" "NOTICE" "README.md"
while IFS= read -r part; do
	[ -n "$part" ] || continue
	entry="$(credit_for "$part")"
	label="${entry%%|*}"
	word="${entry##*|}"
	in_notice="no"
	in_readme="no"
	if [ -n "$word" ]; then
		grep -qi -- "$word" "$root/NOTICE" 2> /dev/null && in_notice="yes"
		grep -qi -- "$word" "$root/README.md" 2> /dev/null && in_readme="yes"
	fi
	printf '%-28s %-44s %-8s %s\n' "$part" "$label" "$in_notice" "$in_readme"
	if [ "$in_notice" != "yes" ] || [ "$in_readme" != "yes" ]; then
		uncredited=1
		missing="$missing$part"$'\n'
	fi
done <<< "$parts"
if [ -n "$missing" ]; then
	echo
	echo "Not credited in both files. The classes inside these packages:"
	while IFS= read -r part; do
		[ -n "$part" ] || continue
		printf '%s\n' "$descriptors" | grep "^$part/" | sed 's/^/  /'
	done <<< "$missing"
fi

echo
if [ "$failed" -ne 0 ]; then
	echo "RESULT: FAILED. Read the FAIL lines above."
	exit 1
fi
if [ "$uncredited" -ne 0 ]; then
	echo "RESULT: a bundled part is not credited in NOTICE and README.md (see the table). Ask the DM to update NOTICE, README and About."
	exit 2
fi
echo "RESULT: OK. No permissions, arm64-v8a only, package and version right, signed with the upload key, every bundled part is credited."
