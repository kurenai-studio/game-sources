#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# Runs every balance job for region 1, several Godot processes at a time, then the timing runs
# one by one, and writes one JSON file per job to docs/balance/raw/<date>/. Run it from the repo root:
#     bash tools/balance/run_region1.sh 2026-10-23 6
# Arguments: the date folder name, then how many jobs run at once (default 6).
# The seeds are fixed below, so a second run gives the same files (except the "seconds" field).
# Only processes this script starts are used. Nothing is ended by name.

DATE="${1:-2026-10-23}"
JOBS="${2:-6}"
OUT="docs/balance/raw/$DATE"
mkdir -p "$OUT"
LIST="$OUT/jobs.txt"
: > "$LIST"
N=0
for LEVEL in r1_l1 r1_l2 r1_l3 r1_l4 r1_l5 r1_l6; do
  N=$((N + 1))
  S=$((N * 100))
  echo "mode=search level=$LEVEL seed=$((2000 + S)) evals=3000 only=any out=$OUT/${LEVEL}_search_any.json" >> "$LIST"
  echo "mode=search level=$LEVEL seed=$((3000 + S)) evals=2500 only=sling_post out=$OUT/${LEVEL}_search_sling_post.json" >> "$LIST"
  CAT_EVALS=2500
  # Levels 1-5 and 1-6 have flyers, which a Catapult cannot hit, so a shorter search is enough.
  if [ "$LEVEL" = "r1_l5" ] || [ "$LEVEL" = "r1_l6" ]; then CAT_EVALS=800; fi
  echo "mode=search level=$LEVEL seed=$((4000 + S)) evals=$CAT_EVALS only=pumpkin_catapult out=$OUT/${LEVEL}_search_pumpkin_catapult.json" >> "$LIST"
  echo "mode=spread level=$LEVEL seed=$((1000 + S)) n=250 out=$OUT/${LEVEL}_spread.json" >> "$LIST"
  if [ "$LEVEL" = "r1_l5" ] || [ "$LEVEL" = "r1_l6" ]; then
    echo "mode=search level=$LEVEL seed=12000 evals=3000 only=any early=off out=$OUT/${LEVEL}_search_any_noearly.json" >> "$LIST"
  fi
  echo "mode=recipes level=$LEVEL out=$OUT/${LEVEL}_recipes.json" >> "$LIST"
  echo "mode=det level=$LEVEL seed=$((5000 + S)) out=$OUT/${LEVEL}_det.json" >> "$LIST"
done
# Longest jobs first would be better, but the list order keeps the output stable.
cat "$LIST" | xargs -P "$JOBS" -I{} bash -c 'timeout 3000 godot --headless --path . --script res://tools/balance/run.gd -- {} > /dev/null 2>> '"$OUT"'/errors.txt'
# The timing runs go last and one at a time, so the other jobs do not slow them down.
for LEVEL in r1_l1 r1_l2 r1_l3 r1_l4 r1_l5 r1_l6; do
  timeout 3000 godot --headless --path . --script res://tools/balance/benchmark.gd -- level=$LEVEL \
    build="$OUT/${LEVEL}_search_any.json,$OUT/${LEVEL}_spread.json" out="$OUT/${LEVEL}_bench.json" > /dev/null 2>> "$OUT/errors.txt"
done
echo "done: $(ls "$OUT" | wc -l) files in $OUT"
