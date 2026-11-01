#!/usr/bin/env bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# Tests the dirty tree refusal of check_clean.sh, build.sh and build_release.sh
# in a scratch git repo. It never touches the real repo and never runs the real
# Godot (a stand in prints the version and fails on anything else).
#   scripts/test_check_clean.sh [scratch folder]
# With no argument it uses a new folder from mktemp and removes it afterwards.
# Exit code 0 means every case passed.

set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -n "${1:-}" ]; then
	work="$1"
	mkdir -p "$work"
else
	work="$(mktemp -d)"
	trap 'rm -rf "$work"' EXIT
fi
repo="$work/repo"
rm -rf "$repo"
mkdir -p "$repo/scripts"
cp "$here/check_clean.sh" "$here/build.sh" "$here/build_release.sh" "$here/check_secrets.sh" "$repo/scripts/"
printf 'build/\n' > "$repo/.gitignore"
printf 'a\n' > "$repo/tracked.txt"
fake="$work/fake_godot.sh"
cat > "$fake" <<'EOS'
#!/usr/bin/env bash
if [ "${1:-}" = "--version" ]; then echo "4.7.2.stable.test"; exit 0; fi
exit 1
EOS
chmod +x "$fake"

git -C "$repo" init -q
git -C "$repo" add -A
git -C "$repo" -c user.name=test -c user.email=test@example.invalid commit -q -m scratch

passed=0
failed=0
# expect <name> <wanted exit code> <command...>: runs the command, checks the exit code.
expect() {
	local name="$1" want="$2" code=0
	shift 2
	"$@" > "$work/out.txt" 2>&1 || code=$?
	if [ "$code" -eq "$want" ]; then
		passed=$((passed + 1))
		echo "ok   $name"
	else
		failed=$((failed + 1))
		echo "FAIL $name (exit $code, wanted $want)"
		sed 's/^/     /' "$work/out.txt"
	fi
}
# says <name> <text>: the last run printed the text.
says() {
	if grep -q -- "$2" "$work/out.txt"; then
		passed=$((passed + 1))
		echo "ok   $1"
	else
		failed=$((failed + 1))
		echo "FAIL $1 (output lacks: $2)"
		sed 's/^/     /' "$work/out.txt"
	fi
}
check() { bash "$repo/scripts/check_clean.sh"; }
build() { GODOT="$fake" bash "$repo/scripts/build.sh" "$@"; }
release() { GODOT="$fake" bash "$repo/scripts/build_release.sh" "$@"; }

expect "clean tree passes" 0 check
says "clean tree prints the commit" "Commit: "

mkdir -p "$repo/build" && printf 'x\n' > "$repo/build/out.apk"
expect "an ignored file is not a change" 0 check
rm -rf "$repo/build"

printf 'b\n' >> "$repo/tracked.txt"
expect "a changed tracked file fails" 1 check
says "the change is listed" "tracked.txt"
expect "build.sh refuses a changed tracked file" 1 build
says "build.sh says why" "working tree is not clean"
expect "build_release.sh refuses a changed tracked file" 1 release
says "build_release.sh says why" "clean git checkout"
git -C "$repo" checkout -q -- tracked.txt

printf 'new\n' > "$repo/new.txt"
expect "an untracked file fails" 1 check
expect "build.sh refuses an untracked file" 1 build
expect "build_release.sh refuses an untracked file" 1 release

# --allow-dirty gets build.sh past the check (it then fails at the stand in import).
expect "build.sh --allow-dirty goes on" 1 build --allow-dirty
says "--allow-dirty warns" "WARNING: building from a dirty tree"
says "--allow-dirty went past the check" "Importing the project"
expect "build_release.sh has no skip option" 1 release --allow-dirty
says "build_release.sh rejects the option" "takes no options"
expect "build.sh rejects unknown options" 1 build --nope
rm -f "$repo/new.txt"

expect "clean again passes" 0 check
expect "clean build.sh gets to the import" 1 build
says "clean build.sh did not refuse" "Importing the project"

# A copy without .git (git archive): check_clean says 2, build.sh goes on, release refuses.
rm -rf "$work/archive"
mkdir -p "$work/archive"
git -C "$repo" archive HEAD | tar -x -C "$work/archive"
cp "$repo/scripts/check_clean.sh" "$work/archive/scripts/" 2> /dev/null || true
expect "a copy without .git gives exit 2" 2 bash "$work/archive/scripts/check_clean.sh"
expect "build.sh goes on in a copy without .git" 1 env GODOT="$fake" bash "$work/archive/scripts/build.sh"
says "build.sh builds the copy" "Importing the project"
expect "build_release.sh refuses a copy without .git" 1 env GODOT="$fake" bash "$work/archive/scripts/build_release.sh"
says "build_release.sh says why" "clean git checkout"

echo
echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
