#!/bin/sh
# Debug-only screenshots of every game screen at the three phone sizes in both themes.
# Run through `make game-shots`. Needs a window and a GPU (not headless); output goes to
# apps/game/build/shots/<screen>-<theme>-<size>.png, which is git-ignored.
# The shot arguments are read by scripts/main.gd and exist only in debug builds.
set -e
GODOT="${GODOT:-godot}"
OUT="${OUT:-build/shots}"
cd "$(dirname "$0")/.."
mkdir -p "$OUT"

shot() {
	name="$1"
	screen="$2"
	theme="$3"
	size="$4"
	shift 4
	# ONLY=depth renders just the shots whose name contains "depth".
	if [ -n "$ONLY" ] && [ "${name#*"$ONLY"}" = "$name" ]; then
		return
	fi
	# The plain shots are the flat look; a shot that passes --look chooses its own.
	look="--look=flat"
	for argument in "$@"; do
		case "$argument" in --look=*) look="" ;; esac
	done
	# A bad argument can leave Godot running; a watchdog ends it after a minute.
	"$GODOT" --path . --resolution 200x200 -- \
		--shot="$OUT/$name-$theme-$size.png" --screen="$screen" --theme="$theme" --size="$size" $look "$@" >/dev/null &
	pid=$!
	(sleep 60 && kill -9 "$pid" 2>/dev/null) &
	watchdog=$!
	wait "$pid" || true
	kill "$watchdog" 2>/dev/null || true
}

for size in 390x844 360x640 412x915; do
	for theme in light dark; do
		shot home home "$theme" "$size"
		shot depth-kit depth_kit "$theme" "$size"
		shot world-tiles world "$theme" "$size" --done=91 --world=16
		shot world-tiles-depth world "$theme" "$size" --done=91 --world=16 --look=depth
		shot world-big-boards world "$theme" "$size" --done=30 --world=10
		shot worlds worlds "$theme" "$size" --done=4
		shot world world "$theme" "$size" --done=4 --world=1
		shot world-stars world "$theme" "$size" --done=6 --world=0
		shot settings settings "$theme" "$size"
		shot how-to-play how_to_play "$theme" "$size"
		shot load-error load_error "$theme" "$size" --title="Loops"
		shot update-required update_required "$theme" "$size" --title="Level 14"
		shot sign-in sign_in "$theme" "$size"
		shot account account "$theme" "$size" --done=4 --account=you@example.com
		shot play-tutorial play "$theme" "$size" --level=first-step
		shot play-hint play "$theme" "$size" --level=first-step --overlay=hint
		# first-turn: start (0,4) facing north; MMMRMMM is its shortest solution.
		shot play-pause play "$theme" "$size" --level=first-turn --program=MMMRM --overlay=pause
		shot play-ready play "$theme" "$size" --level=first-turn --program=MMMRM
		shot play-running play "$theme" "$size" --level=first-turn --program=MMMRMMM --steps=5
		shot play-failed play "$theme" "$size" --level=first-turn --program=MMMMMM --steps=-1
		shot play-solved play "$theme" "$size" --level=first-turn --program=MMMRMMM --steps=-1
		# cross-the-beat: a guard walks column 3; MMMM meets it on the third move.
		shot play-patrol play "$theme" "$size" --level=cross-the-beat --program=MMLMRMM --steps=2
		shot play-patrol-failed play "$theme" "$size" --level=cross-the-beat --program=MMMM --steps=-1
		shot play-patrol-depth play "$theme" "$size" --level=cross-the-beat --program=MMLMRMM --steps=2 --look=depth
		shot play-patrol-failed-depth play "$theme" "$size" --level=cross-the-beat --program=MMMM --steps=-1 --look=depth
		# two-doors: the key of the first door is taken (M R M L L M); the second key is next.
		shot play-keys play "$theme" "$size" --level=two-doors --program=MRMLLMRMMMMMLM --steps=6
		shot play-keys-failed play "$theme" "$size" --level=two-doors --program=MMMM --steps=-1
		shot play-keys-depth play "$theme" "$size" --level=two-doors --program=MRMLLMRMMMMMLM --steps=6 --look=depth
		shot play-keys-failed-depth play "$theme" "$size" --level=two-doors --program=MMMM --steps=-1 --look=depth
		shot play-delivery play "$theme" "$size" --level=full-hands --program=MMMMRMRM --steps=8
		shot play-delivery-carry play "$theme" "$size" --level=full-hands --program=MMMMRMRM --steps=3
		shot play-delivery-carry-depth play "$theme" "$size" --level=full-hands --program=MMMMRMRM --steps=3 --look=depth
		shot play-switch play "$theme" "$size" --level=flip-flop --program=MMMLLMMMMM --steps=4
		shot play-switch-failed play "$theme" "$size" --level=first-switch --program=MMMM --steps=-1
		shot play-switch-depth play "$theme" "$size" --level=flip-flop --program=MMMLLMMMMM --steps=4 --look=depth
		shot play-switch-failed-depth play "$theme" "$size" --level=first-switch --program=MMMM --steps=-1 --look=depth
		shot play-ice play "$theme" "$size" --level=three-ice-cells --program=MMRMRMMM --steps=2
		shot play-belts play "$theme" "$size" --level=belt-line --program=RMLMLMLM --steps=3
		shot play-ice-depth play "$theme" "$size" --level=three-ice-cells --program=MMRMRMMM --steps=2 --look=depth
		shot play-belts-depth play "$theme" "$size" --level=belt-line --program=RMLMLMLM --steps=3 --look=depth
		shot play-teleport play "$theme" "$size" --level=two-pairs --program=MMMLMMRMM --steps=4
		shot play-teleport-depth play "$theme" "$size" --level=two-pairs --program=MMMLMMRMM --steps=4 --look=depth
		shot play-recursion play "$theme" "$size" --level=hall-and-turn --program=P{M@A?}@A --steps=0
		shot play-recursion-depth play "$theme" "$size" --level=hall-and-turn --program=P{M@A?}@A --steps=0 --look=depth
		shot play-capstone play "$theme" "$size" --level=everything --program=MM --steps=2
		shot play-capstone-depth play "$theme" "$size" --level=everything --program=MM --steps=2 --look=depth
		shot play-delivery-failed play "$theme" "$size" --level=first-parcel --program=MMMM --steps=-1
		shot play-delivery-depth play "$theme" "$size" --level=full-hands --program=MMMMRMRM --steps=8 --look=depth
		shot play-delivery-failed-depth play "$theme" "$size" --level=first-parcel --program=MMMM --steps=-1 --look=depth
		# The depth board (Look: depth), on a small board and on the biggest one.
		shot play-ready-depth play "$theme" "$size" --level=first-turn --program=MMMRM --look=depth
		shot play-running-depth play "$theme" "$size" --level=first-turn --program=MMMRMMM --steps=5 --look=depth
		shot play-failed-depth play "$theme" "$size" --level=first-turn --program=MMMMMM --steps=-1 --look=depth
		shot play-solved-depth play "$theme" "$size" --level=first-turn --program=MMMRMMM --steps=-1 --look=depth
		shot play-big-depth play "$theme" "$size" --level=big-spiral --look=depth
		shot home-depth home "$theme" "$size" --look=depth
		shot worlds-depth worlds "$theme" "$size" --done=4 --look=depth
		shot world-depth world "$theme" "$size" --done=4 --world=0 --look=depth
		shot settings-depth settings "$theme" "$size" --look=depth
		shot play-tutorial-depth play "$theme" "$size" --level=first-step --look=depth
		shot play-hint-depth play "$theme" "$size" --level=first-step --overlay=hint --look=depth
		shot play-pause-depth play "$theme" "$size" --level=first-turn --program=MMMRM --overlay=pause --look=depth
		shot sign-in-depth sign_in "$theme" "$size" --look=depth
		shot badges-depth badges "$theme" "$size" --account=you@example.com --newbadges=1 --look=depth
		shot leaderboard-depth leaderboard "$theme" "$size" --account=you@example.com --look=depth
		shot daily-depth daily "$theme" "$size" --account=you@example.com --daily-slots=9 --streak=3,5 --look=depth
		# The social screens answer from canned data (ShotServer), no network.
		who="--account=you@example.com"
		shot profile profile "$theme" "$size" $who
		shot profile-notopted profile "$theme" "$size" $who --fake=notopted
		shot profile-offline profile "$theme" "$size" $who --fake=offline
		shot profile-error profile "$theme" "$size" $who --fake=error
		shot badges badges "$theme" "$size" $who --newbadges=1
		shot badges-offline badges "$theme" "$size" $who --fake=offline
		shot leaderboard leaderboard "$theme" "$size" $who
		shot leaderboard-off-page leaderboard "$theme" "$size" $who --fake=off_page --period=week
		shot leaderboard-level leaderboard "$theme" "$size" $who --scope=level --key=first-turn --title="First turn"
		shot leaderboard-daily leaderboard "$theme" "$size" $who --scope=daily --key=2026-10-20 --fake=off_page
		shot leaderboard-notopted leaderboard "$theme" "$size" $who --fake=notopted
		shot leaderboard-empty leaderboard "$theme" "$size" $who --fake=empty
		shot leaderboard-offline leaderboard "$theme" "$size" $who --fake=offline
		shot leaderboard-signed-out leaderboard "$theme" "$size"
		shot daily daily "$theme" "$size" $who --daily-slots=9 --streak=3,5
		shot daily-fresh daily "$theme" "$size" $who
		shot daily-signed-out daily "$theme" "$size"
		shot daily-offline-cached daily "$theme" "$size" $who --cached --fake=offline
		shot daily-offline-empty daily "$theme" "$size" $who --fake=offline
		shot play-daily play "$theme" "$size" --daily=2026-10-20 --program=MMMRM
		shot play-daily-solved play "$theme" "$size" --daily=2026-10-20 --program=MMMRMMM --steps=-1 $who
		shot play-big play "$theme" "$size" --level=gauntlet --program=MMMMMM
	done
done
echo "Screenshots written to apps/game/$OUT"
