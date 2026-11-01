#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# What-ifs for the report's suggestions. Plays the same bots on edited copies of levels 1-1 to 1-6
# (the data files are never touched; run.gd rebuilds the level in memory from a `tweak`).
# Run it from the repo root after run_region1.sh:
#     bash tools/balance/run_whatif.sh 2026-10-23 8
# Output: docs/balance/raw/<date>/whatif/<level>_<tweak>_<job>.json, one per job.
# A tweak the level checks refuse (for example more than 120 creatures in a wave) writes no file.

DATE="${1:-2026-10-23}"
JOBS="${2:-6}"
OUT="docs/balance/raw/$DATE/whatif"
mkdir -p "$OUT"
LIST="$OUT/jobs.txt"
: > "$LIST"
N=0
for LEVEL in r1_l1 r1_l2 r1_l3 r1_l4 r1_l5; do
  N=$((N + 1))
  for C in 150 200 250 300 400; do
    T="count_pct:$C"
    F="$OUT/${LEVEL}_count${C}"
    echo "mode=search level=$LEVEL seed=$((6000 + N * 100 + C / 50)) evals=800 only=any tweak=$T out=${F}_any.json" >> "$LIST"
    echo "mode=search level=$LEVEL seed=$((7000 + N * 100 + C / 50)) evals=800 only=sling_post tweak=$T out=${F}_sling_post.json" >> "$LIST"
    if [ "$LEVEL" != "r1_l5" ]; then
      echo "mode=search level=$LEVEL seed=$((8000 + N * 100 + C / 50)) evals=800 only=pumpkin_catapult tweak=$T out=${F}_pumpkin_catapult.json" >> "$LIST"
    fi
    echo "mode=spread level=$LEVEL seed=$((9000 + N * 100 + C / 50)) n=100 tweak=$T out=${F}_spread.json" >> "$LIST"
  done
done
# Level 1-6: a weaker boss, more gold, or both.
for S in 110 90 70 50; do
  for G in 350 450 550; do
    # 110 and 350 are the level as it is: run_region1.sh has that.
    if [ "$S" = "110" ] && [ "$G" = "350" ]; then continue; fi
    T="last_strength:$S,gold:$G"
    F="$OUT/r1_l6_boss${S}_gold${G}"
    echo "mode=search level=r1_l6 seed=$((10000 + S + G)) evals=1500 only=any tweak=$T out=${F}_any.json" >> "$LIST"
    echo "mode=spread level=r1_l6 seed=$((11000 + S + G)) n=100 tweak=$T out=${F}_spread.json" >> "$LIST"
  done
done
# Level 1-6: one more build spot, at four different cells (column;row).
for CELL in "4;5" "1;5" "2;8" "3;1"; do
  T="add_spot:$CELL"
  F="$OUT/r1_l6_spot${CELL/;/_}"
  echo "mode=search level=r1_l6 seed=17001 evals=1500 only=any tweak=$T out=${F}_any.json" >> "$LIST"
  echo "mode=spread level=r1_l6 seed=17002 n=100 tweak=$T out=${F}_spread.json" >> "$LIST"
done
# One job per line; the words of a line become the arguments, so a ; inside one stays inside it.
cat "$LIST" | xargs -P "$JOBS" -L1 bash -c 'timeout 3000 godot --headless --path . --script res://tools/balance/run.gd -- "$@" > /dev/null 2>> '"$OUT"'/errors.txt' _
echo "done: $(ls "$OUT" | wc -l) files in $OUT"
