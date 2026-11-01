#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# Checks that the bots after the B1 changes (six towers, Twists, gate sets, the plain recipe of
# RULES 12.6) still give the region 1 numbers of the 2026-10-24 report. It plays the same jobs with
# the same seeds as run_rerun.sh, into a new folder. Then compare each file with the old one:
#     bash tools/balance/run_bots_check.sh 2026-10-24-bots 4
#     godot --headless --path . --script res://tools/balance/compare_raw.gd -- old=res://docs/balance/raw/2026-10-24 new=res://docs/balance/raw/2026-10-24-bots
# Arguments: the folder name under docs/balance/raw/, then how many jobs run at once (default 4).
# A job whose output file exists is skipped. Only processes this script starts are used.

NAME="${1:-2026-10-24-bots}"
JOBS="${2:-4}"
OUT="docs/balance/raw/$NAME"
mkdir -p "$OUT"
LIST="$OUT/jobs.txt"
: > "$LIST"
# The slow single tower searches go first, then the rest.
for N in 3 5; do
  LEVEL="r1_l$N"
  S=$((N * 100))
  echo "mode=search level=$LEVEL seed=$((23000 + S)) evals=3000 only=sling_post out=$OUT/${LEVEL}_search_sling_post.json" >> "$LIST"
  echo "mode=search level=$LEVEL seed=$((24000 + S)) evals=3000 only=pumpkin_catapult out=$OUT/${LEVEL}_search_pumpkin_catapult.json" >> "$LIST"
done
for N in 1 2 3 4 5 6; do
  LEVEL="r1_l$N"
  S=$((N * 100))
  echo "mode=search level=$LEVEL seed=$((22000 + S)) evals=3000 only=any out=$OUT/${LEVEL}_search_any.json" >> "$LIST"
  echo "mode=spread level=$LEVEL seed=$((21000 + S)) n=250 out=$OUT/${LEVEL}_spread.json" >> "$LIST"
  echo "mode=recipes level=$LEVEL out=$OUT/${LEVEL}_recipes.json" >> "$LIST"
  echo "mode=det level=$LEVEL seed=$((25000 + S)) out=$OUT/${LEVEL}_det.json" >> "$LIST"
  echo "mode=plain level=$LEVEL compare_old=1 out=$OUT/${LEVEL}_plain.json" >> "$LIST"
done
run_one() {
  OUTFILE=$(echo "$1" | sed 's/.*out=//')
  if [ -f "$OUTFILE" ]; then return; fi
  timeout 5400 godot --headless --path . --script res://tools/balance/run.gd -- $1 > /dev/null 2>> "$2/errors.txt"
}
export -f run_one
cat "$LIST" | xargs -P "$JOBS" -I{} bash -c 'run_one "{}" '"$OUT"
echo "done: $(ls "$OUT" | wc -l) files in $OUT"
