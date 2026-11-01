#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# The star 3 what-ifs of the B1 report (docs/balance/region2-2026-10-24.md). On the region 2 levels where one
# attacking tower earned three stars, it plays other star 3 rules (run.gd tweak=star3:KIND;N, in memory only):
# one any-tower search and one search per attacking tower the level offers (only=solo:...), one seed each.
# Run it from the repo root after run_pass.sh:
#     bash tools/balance/run_whatif_b1.sh 2026-10-24-b1 4
# Seeds: 790000 + 1000 * R + 100 * K + A, with R the rule's number below, K = 10 * region + level number and
# A the attacking tower's number (1 Sling Post, 2 Catapult, 3 Longbow; 0 for the any-tower search).
# Output: docs/balance/raw/<date>/whatif/<level>_r<R>_<job>.json. A job whose file exists is skipped.
# Rules: up to 5 per level, as listed in RULES below (level, then rule 1, rule 2 and so on).

DATE="${1:-2026-10-24-b1}"
JOBS="${2:-4}"
EVALS="${EVALS:-2500}"
OUT="docs/balance/raw/$DATE/whatif"
mkdir -p "$OUT"
LIST="$OUT/jobs.txt"
: > "$LIST"
RULES=(
  "r2_l1 star3:tier_at_most;2 star3:towers_at_most;5"
  "r2_l3 star3:towers_at_most;5 star3:tier_at_most;1 star3:tower_ban;pumpkin_catapult"
  "r2_l4 star3:tier_at_most;2 star3:towers_at_most;5"
  "r2_l5 star3:tier_at_most;2 star3:towers_at_most;5"
  "r2_l6 star3:tier_at_most;2 star3:no_lives_lost star3:tower_ban;sling_post star3:towers_at_most;4 star3:tower_ban;lullaby_bell"
)
for LINE in "${RULES[@]}"; do
  set -- $LINE
  LEVEL=$1
  NUM=$(echo "$LEVEL" | sed 's/.*_l//')
  REGION=$(echo "$LEVEL" | sed 's/^r\([0-9]*\)_l.*/\1/')
  S=$(((REGION * 10 + NUM) * 100))
  TOWERS=$(grep -o '"towers": *\[[^]]*\]' "data/levels/$LEVEL.json" | head -1)
  for R in 1 2 3 4 5; do
    RULE=$((R + 1))
    RULE=${!RULE}
    if [ -z "$RULE" ]; then continue; fi
    echo "mode=search level=$LEVEL seed=$((790000 + 1000 * R + S)) evals=$EVALS only=any tweak=$RULE out=$OUT/${LEVEL}_r${R}_any.json" >> "$LIST"
    A=0
    for TOWER in sling_post pumpkin_catapult longbow_loft; do
      A=$((A + 1))
      if echo "$TOWERS" | grep -q "\"$TOWER\""; then
        echo "mode=search level=$LEVEL seed=$((790000 + 1000 * R + S + A)) evals=$EVALS only=solo:$TOWER tweak=$RULE out=$OUT/${LEVEL}_r${R}_solo_${TOWER}.json" >> "$LIST"
      fi
    done
  done
done
# Level 2-3 with Flitters added (waves 4, 6 and 8 get 4, 5 and 6; the Catapult cannot hit flyers) and its own star 3 rule
# (No tower above tier 2), from the file docs/balance/raw/<date>/whatif/levels/r2_l3_flitters.json. Seeds 797300 + A.
A=0
for TOWER in sling_post pumpkin_catapult longbow_loft; do
  A=$((A + 1))
  echo "mode=search level=r2_l3 seed=$((797300 + A)) evals=$EVALS only=solo:$TOWER level_file=$OUT/levels/r2_l3_flitters.json out=$OUT/r2_l3_flitters_solo_${TOWER}.json" >> "$LIST"
done
echo "mode=search level=r2_l3 seed=797300 evals=$EVALS only=any level_file=$OUT/levels/r2_l3_flitters.json out=$OUT/r2_l3_flitters_any.json" >> "$LIST"
# The same with fewer Flitters (2, 3 and 4), from levels/r2_l3_flitters_b.json. Seeds 798300 + A.
A=0
for TOWER in sling_post pumpkin_catapult longbow_loft; do
  A=$((A + 1))
  echo "mode=search level=r2_l3 seed=$((798300 + A)) evals=$EVALS only=solo:$TOWER level_file=$OUT/levels/r2_l3_flitters_b.json out=$OUT/r2_l3_flitters_b_solo_${TOWER}.json" >> "$LIST"
done
echo "mode=search level=r2_l3 seed=798300 evals=$EVALS only=any level_file=$OUT/levels/r2_l3_flitters_b.json out=$OUT/r2_l3_flitters_b_any.json" >> "$LIST"
# Longer checks (6000 builds) of the rules and the level file this report recommends, with a lone attacker, because a 2500
# build search can miss (2-2: a lone Sling Post found nothing in two 2500 build searches and 252 three-star builds in one
# 6000 build search, docs/balance/raw/<date>/extra/). Seeds 799000 + 100 K + A + 10 N (N is the search's number, 0 or 1).
# Output: whatif/check_<level>_<tag>_<tower>[_<N>].json. Level 2-2 gets its own two rules, an any-tower search and two lone Sling Post searches each.
check() {  # level tag tower A extra-args N evals
  echo "mode=search level=$1 seed=$((799000 + (10 * ${1:1:1} + ${1:4:1}) * 100 + $4 + 10 * $6)) evals=$7 only=solo:$3 $5 out=$OUT/check_$1_$2_$3_$6.json" >> "$LIST"
}
check r2_l1 tier2 sling_post 1 "tweak=star3:tier_at_most;2" 0 6000
check r2_l4 tier2 sling_post 1 "tweak=star3:tier_at_most;2" 0 6000
check r2_l5 tier2 sling_post 1 "tweak=star3:tier_at_most;2" 0 6000
check r2_l6 nobell sling_post 1 "tweak=star3:tower_ban;lullaby_bell" 0 6000
check r2_l3 flitters_b pumpkin_catapult 2 "level_file=$OUT/levels/r2_l3_flitters_b.json" 0 6000
for N in 0 1; do
  check r2_l2 tier2 sling_post 1 "tweak=star3:tier_at_most;2" $N 6000
  check r2_l2 towers4 sling_post 1 "tweak=star3:towers_at_most;4" $N 6000
done
for RULE in "tier2 star3:tier_at_most;2" "towers4 star3:towers_at_most;4"; do
  set -- $RULE
  echo "mode=search level=r2_l2 seed=$((799000 + 2200 + 50)) evals=$EVALS only=any tweak=$2 out=$OUT/check_r2_l2_$1_any.json" >> "$LIST"
done
if [ -n "$DRY" ]; then
  echo "wrote $(wc -l < "$LIST") jobs to $LIST"
  exit 0
fi
run_one() {
  OUTFILE=$(echo "$1" | sed 's/.*out=//')
  if [ -f "$OUTFILE" ]; then return; fi
  timeout 5400 godot --headless --path . --script res://tools/balance/run.gd -- $1 > /dev/null 2>> "$2/errors.txt"
}
export -f run_one
cat "$LIST" | xargs -P "$JOBS" -I{} bash -c 'run_one "{}" '"$OUT"
echo "done: $(ls "$OUT" | wc -l) files in $OUT"
