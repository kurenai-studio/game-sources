#!/usr/bin/env bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# Checks that no signing key or password is in the repo. Run from any folder, in
# Git Bash:
#   scripts/check_secrets.sh
#
# It looks at every file git tracks and every file git would add (untracked files
# that are not ignored). It fails if it finds:
#   1. a file whose name is a key file (.keystore, .jks, .p12, .pfx, .pk8, .pem,
#      .key, .password) or Godot's export_credentials.cfg;
#   2. a keystore path, user or password set in an export preset (any
#      keystore/... line with a value);
#   3. a GODOT_ANDROID_KEYSTORE_* variable set to a literal value (setting it
#      from a shell variable such as "$store_pass" is fine);
#   4. a keytool or apksigner password given on the command line as text
#      (-storepass:file and file: forms are fine);
#   5. an absolute path to a keystore file;
#   6. the real upload password, if the key folder exists on this machine.
# It prints only file names and line numbers, never the matching text.
# Exit code 0 means clean. 1 means a finding.

set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 1
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
	echo "This check needs a git work tree."
	exit 1
fi

failed=0
self="scripts/check_secrets.sh"

files="$(git ls-files --cached --others --exclude-standard | grep -vxF "$self" || true)"

echo "== Key files by name =="
named="$(printf '%s\n' "$files" | grep -E '(\.(keystore|jks|p12|pfx|pk8|pem|key|password)$|(^|/)export_credentials\.cfg$|(^|/)keystore\.properties$)' || true)"
if [ -n "$named" ]; then
	printf '%s\n' "$named"
	echo "FAIL: key files are in the repo."
	failed=1
else
	echo "None."
fi

# scan <label> <regex>: lists file:line of matches, never the text.
scan() {
	local label="$1" regex="$2" hits
	echo
	echo "== $label =="
	hits="$(printf '%s\n' "$files" | tr '\n' '\0' | xargs -0 grep -I -n -E -e "$regex" 2> /dev/null | cut -d: -f1,2 || true)"
	if [ -n "$hits" ]; then
		printf '%s\n' "$hits"
		echo "FAIL: $label."
		failed=1
	else
		echo "None."
	fi
}

scan "A keystore setting with a value in an export preset" 'keystore/[a-z_]+[[:space:]]*=[[:space:]]*"?[^"[:space:]]'
scan "A GODOT_ANDROID_KEYSTORE variable set to a literal value" 'GODOT_ANDROID_KEYSTORE_[A-Z_]+=([^"$[:space:]]|"[^$"])'
scan "A password given on a command line as text" '(-storepass|-keypass|-deststorepass|-srcstorepass|--ks-pass|--key-pass)[[:space:]=]+([^$"'"'"'f[:space:]]|f[^i])|(^|[[:space:]=])pass:[A-Za-z0-9]'
scan "An absolute path to a keystore file" '([A-Za-z]:[\\/]|/(Users|home)/)[^[:space:]"'"'"']*\.(keystore|jks|p12|pfx)'

echo
echo "== The real upload password =="
key_dir="${FORKLINE_RELEASE_DIR:-}"
if [ -z "$key_dir" ] && [ -n "${APPDATA:-}" ]; then
	key_dir="$(cygpath -u "$APPDATA" 2> /dev/null || echo "$APPDATA")/Forkline/release"
fi
pass_file="$key_dir/forkline-upload.password"
if [ -n "$key_dir" ] && [ -f "$pass_file" ]; then
	secret="$(head -n 1 "$pass_file" | tr -d '\r\n')"
	if [ -n "$secret" ]; then
		hits="$(printf '%s\n' "$files" | tr '\n' '\0' | xargs -0 grep -I -n -F -e "$secret" 2> /dev/null | cut -d: -f1,2 || true)"
		if [ -n "$hits" ]; then
			printf '%s\n' "$hits"
			echo "FAIL: the upload password is written in the repo."
			failed=1
		else
			echo "The upload password is not in any tracked or addable file."
		fi
	fi
else
	echo "Note: no key folder on this machine, so the real password was not searched for."
fi

echo
if [ "$failed" -ne 0 ]; then
	echo "RESULT: FAILED. Remove the lines above. If a real password was ever committed, treat it as leaked and ask the DM."
	exit 1
fi
echo "RESULT: OK. No keystore, key file or password is in the repo."
