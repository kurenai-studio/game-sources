#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# The job list of the 2026-10-24 rerun on the tuned region 1 (commit 473d768): fresh seeds, two
# single tower searches per tower and level, and no search with early calls off (no region 1
# star 3 needs early calls any more). Run it from the repo root:
#     bash tools/balance/run_rerun.sh 2026-10-24 10
# Arguments: the date folder name, then how many jobs run at once (default 6).
# Only processes this script starts are used. Nothing is ended by name.

DATE="${1:-2026-10-24}"
JOBS="${2:-6}"
OUT="docs/balance/raw/$DATE"
mkdir -p "$OUT"
LIST="$OUT/jobs.txt"
: > "$LIST"
N=0
for LEVEL in r1_l1 r1_l2 r1_l3 r1_l4 r1_l5 r1_l6; do
  N=$((N + 1))
  S=$((N * 100))
  echo "mode=search level=$LEVEL seed=$((22000 + S)) evals=3000 only=any out=$OUT/${LEVEL}_search_any.json" >> "$LIST"
  echo "mode=search level=$LEVEL seed=$((23000 + S)) evals=3000 only=sling_post out=$OUT/${LEVEL}_search_sling_post.json" >> "$LIST"
  echo "mode=search level=$LEVEL seed=$((24000 + S)) evals=3000 only=pumpkin_catapult out=$OUT/${LEVEL}_search_pumpkin_catapult.json" >> "$LIST"
  echo "mode=search level=$LEVEL seed=$((26000 + S)) evals=3000 only=sling_post out=$OUT/${LEVEL}_search_sling_post_b.json" >> "$LIST"
  echo "mode=search level=$LEVEL seed=$((27000 + S)) evals=3000 only=pumpkin_catapult out=$OUT/${LEVEL}_search_pumpkin_catapult_b.json" >> "$LIST"
  echo "mode=spread level=$LEVEL seed=$((21000 + S)) n=250 out=$OUT/${LEVEL}_spread.json" >> "$LIST"
  echo "mode=recipes level=$LEVEL out=$OUT/${LEVEL}_recipes.json" >> "$LIST"
  echo "mode=det level=$LEVEL seed=$((25000 + S)) out=$OUT/${LEVEL}_det.json" >> "$LIST"
done
cat "$LIST" | xargs -P "$JOBS" -I{} bash -c 'timeout 5400 godot --headless --path . --script res://tools/balance/run.gd -- {} > /dev/null 2>> '"$OUT"'/errors.txt'
# The same determinism jobs again, in new processes: the chain hashes must match the first set.
for LEVEL in r1_l1 r1_l2 r1_l3 r1_l4 r1_l5 r1_l6; do
  S=$(( ${LEVEL#r1_l} * 100 ))
  timeout 3000 godot --headless --path . --script res://tools/balance/run.gd -- mode=det level=$LEVEL seed=$((25000 + S)) \
    out="$OUT/${LEVEL}_det_again.json" > /dev/null 2>> "$OUT/errors.txt"
done
# The timing runs go last and one at a time, so the other jobs do not slow them down.
for LEVEL in r1_l1 r1_l2 r1_l3 r1_l4 r1_l5 r1_l6; do
  timeout 3000 godot --headless --path . --script res://tools/balance/benchmark.gd -- level=$LEVEL \
    build="$OUT/${LEVEL}_search_any.json,$OUT/${LEVEL}_spread.json" out="$OUT/${LEVEL}_bench.json" > /dev/null 2>> "$OUT/errors.txt"
done
echo "done: $(ls "$OUT" | wc -l) files in $OUT"
