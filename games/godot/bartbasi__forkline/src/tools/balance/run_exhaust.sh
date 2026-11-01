#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# The extra jobs of the 2026-10-24 rerun, after run_rerun.sh. Run from the repo root:
#     bash tools/balance/run_exhaust.sh 2026-10-24 10
# 1. Level 1-3 (star 3: at most 2 towers), one tower type at a time: every build of one or two
#    towers (run.gd mode=exhaust), split over 10 shards.
# 2. Longer searches (8000 builds) with one tower type on the levels where the first searches
#    came closest to three stars.
# 3. Small what-ifs: 1-3 with tier 1 only, 1-5 with other star 3 rules (run.gd level_file=).
# 4. The guided style on every level (run.gd style=guided).
# Only processes this script starts are used. Nothing is ended by name.

DATE="${1:-2026-10-24}"
JOBS="${2:-6}"
OUT="docs/balance/raw/$DATE"
mkdir -p "$OUT/exhaust"
LIST="$OUT/exhaust/jobs.txt"
: > "$LIST"
for ONLY in sling_post pumpkin_catapult; do
  for SHARD in 0 1 2 3 4 5 6 7 8 9; do
    echo "mode=exhaust level=r1_l3 only=$ONLY max_towers=2 shard=$SHARD shards=10 out=$OUT/exhaust/r1_l3_${ONLY}_s$SHARD.json" >> "$LIST"
  done
done
# Longer searches: level, tower, seed.
echo "mode=search level=r1_l3 seed=31300 evals=8000 only=pumpkin_catapult out=$OUT/exhaust/r1_l3_long_pumpkin_catapult.json" >> "$LIST"
echo "mode=search level=r1_l3 seed=32300 evals=8000 only=sling_post out=$OUT/exhaust/r1_l3_long_sling_post.json" >> "$LIST"
echo "mode=search level=r1_l1 seed=34100 evals=8000 only=pumpkin_catapult out=$OUT/exhaust/r1_l1_long_pumpkin_catapult.json" >> "$LIST"
echo "mode=search level=r1_l1 seed=35100 evals=8000 only=sling_post out=$OUT/exhaust/r1_l1_long_sling_post.json" >> "$LIST"
echo "mode=search level=r1_l4 seed=36400 evals=8000 only=pumpkin_catapult out=$OUT/exhaust/r1_l4_long_pumpkin_catapult.json" >> "$LIST"
echo "mode=search level=r1_l5 seed=37500 evals=8000 only=sling_post out=$OUT/exhaust/r1_l5_long_sling_post.json" >> "$LIST"
echo "mode=search level=r1_l2 seed=38200 evals=8000 only=pumpkin_catapult out=$OUT/exhaust/r1_l2_long_pumpkin_catapult.json" >> "$LIST"
echo "mode=search level=r1_l6 seed=39600 evals=8000 only=sling_post out=$OUT/exhaust/r1_l6_long_sling_post.json" >> "$LIST"
# 3. Small what-ifs: 1-3 with tier 1 towers only (the Twist "No Upgrades"), 1-5 with other star 3 rules.
W="$OUT/whatif"
mkdir -p "$W"
for SHARD in 0 1 2 3; do
  echo "mode=exhaust level=r1_l3 only=any max_towers=4 depth_max=0 aims=first shard=$SHARD shards=4 out=$W/r1_l3_tier1_only_s$SHARD.json" >> "$LIST"
done
for N in 4 3; do
  sed "s/\"star3\": {\"kind\": \"tier_at_most\", \"value\": 2}/\"star3\": {\"kind\": \"towers_at_most\", \"value\": $N}/" data/levels/r1_l5.json > "$W/r1_l5_towers$N.json"
  echo "mode=search level=r1_l5 level_file=$W/r1_l5_towers$N.json seed=4150$N evals=3000 only=any out=$W/r1_l5_towers${N}_any.json" >> "$LIST"
done
# 4. The guided style (every spot, both kinds, all tier 2, random places and gate), 400 plays a level.
mkdir -p "$OUT/guided"
for N in 1 2 3 4 5 6; do
  echo "mode=spread style=guided level=r1_l$N seed=$((51000 + N * 100)) n=400 out=$OUT/guided/r1_l${N}_guided.json" >> "$LIST"
done
cat "$LIST" | xargs -P "$JOBS" -I{} bash -c 'timeout 7200 godot --headless --path . --script res://tools/balance/run.gd -- {} > /dev/null 2>> '"$OUT"'/exhaust/errors.txt'
echo "done: $(ls "$OUT/exhaust" | wc -l) files in $OUT/exhaust"
