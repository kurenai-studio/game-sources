#!/usr/bin/env bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# Checks the Google Play material in docs/store/:
#   - the listing's character counts (stated and real) against Google's limits
#   - plain ASCII only (no em dashes, no curly quotes) in the listing and policy
#   - no double hyphens in the prose, outside code fences
#   - the required wording is in the full description and the policy
#   - the image files exist and have the sizes Play needs
#   - docs/store/site/ matches tools/store/make_site.gd and loads nothing external
# Run from anywhere:  bash tools/store/check_store.sh
# Exit 0 when everything passes, 1 otherwise.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1

LISTING=docs/store/listing.md
POLICY=docs/store/privacy-policy.md
GFX=docs/store/graphics
failed=0

fail() { echo "FAIL: $*"; failed=$((failed + 1)); }
ok() { echo "ok:   $*"; }

# The text of the first fenced block under the heading that starts with $1.
block_after() {
	awk -v h="$1" '
		index($0, h) == 1 { inh = 1; next }
		inh && /^```/ { if (!infence) { infence = 1; next } else { exit } }
		inh && infence { print }
	' "$LISTING"
}

# The "Characters: N of L." line under the heading.
stated_after() {
	awk -v h="$1" '
		index($0, h) == 1 { inh = 1; next }
		inh && /^Characters: / { print; exit }
	' "$LISTING"
}

check_field() {
	local heading="$1" limit="$2" text count line stated
	if [ ! -f "$LISTING" ]; then fail "$LISTING is missing"; return; fi
	text="$(block_after "$heading")"
	if [ -z "$text" ]; then fail "no text found under '$heading'"; return; fi
	count=${#text}
	line="$(stated_after "$heading")"
	stated="$(echo "$line" | sed -n 's/^Characters: \([0-9]*\) of \([0-9]*\)\.$/\1/p')"
	if [ "$count" -gt "$limit" ]; then
		fail "$heading: $count characters, limit $limit"
	elif [ "$stated" != "$count" ]; then
		fail "$heading: the listing says '${line:-nothing}' but the text has $count characters"
	else
		ok "$heading: $count of $limit"
	fi
}

check_field "## App name" 30
check_field "## Short description" 80
check_field "## Full description" 4000
check_field "## What's new" 500

# Plain ASCII, and no double hyphens in prose.
check_text() {
	local file="$1"
	if [ ! -f "$file" ]; then fail "$file is missing"; return; fi
	if LC_ALL=C grep -n -P '[^\x00-\x7F]' "$file" >/dev/null; then
		fail "$file has characters outside plain ASCII:"
		LC_ALL=C grep -n -P '[^\x00-\x7F]' "$file" | head -5
	else
		ok "$file is plain ASCII"
	fi
	if awk '/^```/ { f = !f; next } !f && !/^[|: -]+$/ && /--/ { print FILENAME ":" NR ": " $0; bad = 1 } END { exit bad }' "$file"; then
		ok "$file has no double hyphens in prose"
	else
		fail "$file has a double hyphen in prose (shown above)"
	fi
}
check_text "$LISTING"
check_text "$POLICY"

# Required wording.
need() {
	local file="$1" phrase="$2"
	if grep -q -i -F "$phrase" "$file" 2>/dev/null; then ok "$file has '$phrase'"; else fail "$file lacks '$phrase'"; fi
}
for phrase in "no ads" "no in-app purchases" "no accounts" "no tracking" "fully offline" "free software under the GNU GPL version 3" "github.com/bartbasi/forkline"; do
	need "$LISTING" "$phrase"
done
for phrase in "Play, Inc." "Copyright 2026 Play, Inc." "bartbasi@gmail.com" "buymeacoffee.com" "github.com/bartbasi/forkline" "Send feedback" "no Android permissions"; do
	need "$POLICY" "$phrase"
done

# Image sizes, read from the PNG header (width and height are at bytes 16 to 23).
png_dim() {
	od -An -t u1 -j "$2" -N 4 "$1" | awk '{ print $1 * 16777216 + $2 * 65536 + $3 * 256 + $4 }'
}
check_png() {
	local f="$GFX/$1" want_w="$2" want_h="$3" sig w h bytes
	if [ ! -f "$f" ]; then fail "$f is missing"; return; fi
	sig="$(od -An -t x1 -N 8 "$f" | tr -d ' \n')"
	if [ "$sig" != "89504e470d0a1a0a" ]; then fail "$f is not a PNG"; return; fi
	w="$(png_dim "$f" 16)"
	h="$(png_dim "$f" 20)"
	bytes=$(wc -c < "$f")
	if [ "$w" != "$want_w" ] || [ "$h" != "$want_h" ]; then
		fail "$f is $w x $h, wanted $want_w x $want_h"
	elif [ "$bytes" -gt 8388608 ]; then
		fail "$f is $bytes bytes, over Play's limit"
	else
		ok "$f is $want_w x $want_h, $bytes bytes"
	fi
}
check_png icon_512.png 512 512
check_png feature_1024x500.png 1024 500
for n in screen_1_front_door screen_2_modes screen_3_levels screen_4_build_phase screen_5_wave; do
	check_png "$n.png" 1080 2160
done

# The Pages site in docs/store/site/ must match what tools/store/make_site.gd
# writes now, and its pages may load nothing from anywhere.
SITE=docs/store/site
check_site() {
	local godot="${GODOT:-godot}" tmp out f href
	if [ ! -f "$SITE/index.html" ] || [ ! -f "$SITE/privacy-policy/index.html" ] || [ ! -f "$SITE/.nojekyll" ]; then
		fail "$SITE is incomplete (needs index.html, privacy-policy/index.html and .nojekyll). Run make_site.gd."
		return
	fi
	if [ -s "$SITE/.nojekyll" ]; then fail "$SITE/.nojekyll should be empty"; fi

	# Up to date: regenerate into a temp folder and compare.
	if ! command -v "$godot" >/dev/null 2>&1; then
		fail "Godot was not found as '$godot', so the site cannot be compared. Set GODOT to its full path."
	else
		tmp="$(mktemp -d)"
		out="$tmp"
		if command -v cygpath >/dev/null 2>&1; then out="$(cygpath -m "$tmp")"; fi
		if timeout 120 "$godot" --headless --path . --script res://tools/store/make_site.gd -- --out="$out/site" >/dev/null 2>&1; then
			if diff -r "$tmp/site" "$SITE" >/dev/null 2>&1; then
				ok "$SITE matches the generator output"
			else
				fail "$SITE is out of date. Run: godot --headless --path . --script res://tools/store/make_site.gd"
			fi
		else
			fail "make_site.gd did not run cleanly"
		fi
		rm -rf "$tmp"
	fi

	# Nothing external: no loaded resources, and links only to the two constants.
	local bad=0
	for f in "$SITE/index.html" "$SITE/privacy-policy/index.html"; do
		if grep -n -i -E 'src=|@import|url\(|<script|<link|<img|<iframe|<form|<object|<embed|<base|http-equiv|<meta[^>]*refresh' "$f"; then
			fail "$f loads or may load an external resource (shown above)"
			bad=1
		fi
		if LC_ALL=C grep -n -P '[^\x00-\x7F]' "$f" >/dev/null; then
			fail "$f has characters outside plain ASCII"
			bad=1
		fi
		if grep -n -E -e '--' "$f" >/dev/null; then
			fail "$f has a double hyphen"
			bad=1
		fi
		# Every href sits on an <a> tag and is a relative path or an allowed address.
		if [ "$(grep -o -i 'href=' "$f" | wc -l)" -ne "$(grep -o -i '<a href=' "$f" | wc -l)" ]; then
			fail "$f has an href that is not on an <a> link"
			bad=1
		fi
		for href in $(grep -o -E 'href="[^"]*"' "$f" | sed 's/^href="//; s/"$//'); do
			case "$href" in
				https://github.com/bartbasi/forkline | https://github.com/bartbasi/forkline/releases) ;;
				*:* | //*) fail "$f links to '$href', which is not an allowed address"; bad=1 ;;
			esac
		done
		# Any address written in the text must be one of the allowed ones too.
		if grep -o -E 'https?://[^"<> ]*' "$f" | grep -v -x -E 'https://github.com/bartbasi/forkline(/releases)?' >/dev/null; then
			fail "$f has an address that is not allowed"
			bad=1
		fi
	done
	if [ "$bad" -eq 0 ]; then ok "$SITE pages load nothing external"; fi
}
check_site

if [ "$failed" -gt 0 ]; then
	echo "STORE CHECK FAILED: $failed problem(s)"
	exit 1
fi
echo "Store check passed."
