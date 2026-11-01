#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# The extra jobs of the campaign pass of 2026-10-25 (B3/B4): who costs the lives, the Moon Moth's health along its
# path, the Dusk Moths against low tier Fireworks, and random play under each Twist. Run it from the repo root:
#     bash tools/balance/run_special.sh 2026-10-25-b3 1 1     # part 1 with 1 worker; needs nothing else
#     bash tools/balance/run_special.sh 2026-10-25-b3 2 3     # part 2 with 3 workers; needs the any-tower and Twist searches of run_pass.sh
#     bash tools/balance/run_special.sh 2026-10-25-b3 3 1     # part 3: any-tower searches with the banned tower left out (3-4, 4-2)
# Arguments: the raw folder name, the part (1 or 2), how many jobs run at once. Results go to docs/balance/raw/NAME/special/.
# Part 1: for every level the plain recipe at every gate placement, watched (mode=replay from=plain: lives lost by
#   creature type, flying boss health along its line), the same for 3-6 with its Twist, the plain recipe with no tower
#   above tier 2 and above tier 1 on 3-4 and 3-5, and random play under every Twist (mode=spread twist=1).
# Part 5: the 3-4 champions of part 3 played again at tiers 3, 2 and 1 (delete the empty r3_l4_replay_champions*.json of part 2 first).
# Part 3: any-tower searches with the banned tower left out, for 3-4 and 4-2. Part 4: longer Twist searches for 3-2.
# Part 2: the saved three-star champions of 3-4, 3-5 and 3-6 played again watched, and again with no tower above tier 2 and
#   above tier 1; the Twist champions of 3-6 watched. A job whose output file exists is skipped.

NAME="${1:-2026-10-25-b3}"
PART="${2:-1}"
JOBS="${3:-1}"
SHIFT="${SEED_SHIFT:-100000}"
OUT="docs/balance/raw/$NAME"
SPECIAL="$OUT/special"
mkdir -p "$SPECIAL"
LIST="$SPECIAL/jobs_part$PART.txt"
: > "$LIST"
LEVELS=$(grep -o '"r[0-9]*_l[0-9]*"' data/levels/campaign.json | tr -d '"')
if [ "$PART" = "1" ]; then
  for LEVEL in $LEVELS; do
    REGION=$(echo "$LEVEL" | sed 's/^r\([0-9]*\)_l.*/\1/')
    NUM=$(echo "$LEVEL" | sed 's/.*_l//')
    S=$((SHIFT + (REGION * 10 + NUM) * 100))
    echo "mode=replay level=$LEVEL from=plain out=$SPECIAL/${LEVEL}_replay_plain.json" >> "$LIST"
    echo "mode=spread level=$LEVEL twist=1 seed=$((790000 + S)) n=250 out=$SPECIAL/${LEVEL}_spread_twist.json" >> "$LIST"
  done
  echo "mode=replay level=r3_l6 twist=1 from=plain out=$SPECIAL/r3_l6_replay_plain_twist.json" >> "$LIST"
  for LEVEL in r3_l4 r3_l5; do
    echo "mode=replay level=$LEVEL from=plain max_tier=2 out=$SPECIAL/${LEVEL}_replay_plain_t2.json" >> "$LIST"
    echo "mode=replay level=$LEVEL from=plain max_tier=1 out=$SPECIAL/${LEVEL}_replay_plain_t1.json" >> "$LIST"
  done
elif [ "$PART" = "3" ]; then
  # Levels whose star 3 bans a tower: the any-tower search found no win that met the rule, so search again with only the
  # towers the rule leaves (two seeds, 6000 builds each).
  echo "mode=search level=r3_l4 seed=$((SHIFT + 841001)) evals=6000 only=pumpkin_catapult,lullaby_bell,longbow_loft,firework_tower out=$SPECIAL/r3_l4_nosling_a.json" >> "$LIST"
  echo "mode=search level=r3_l4 seed=$((SHIFT + 841002)) evals=6000 only=pumpkin_catapult,lullaby_bell,longbow_loft,firework_tower out=$SPECIAL/r3_l4_nosling_b.json" >> "$LIST"
  echo "mode=search level=r4_l2 seed=$((SHIFT + 842001)) evals=6000 only=sling_post,lullaby_bell,longbow_loft,firework_tower,bakery out=$SPECIAL/r4_l2_nocatapult_a.json" >> "$LIST"
  echo "mode=search level=r4_l2 seed=$((SHIFT + 842002)) evals=6000 only=sling_post,lullaby_bell,longbow_loft,firework_tower,bakery out=$SPECIAL/r4_l2_nocatapult_b.json" >> "$LIST"
elif [ "$PART" = "4" ]; then
  # A Twist whose 1500 build search won nothing: longer searches (3-2, No Catapults).
  echo "mode=search level=r3_l2 twist=1 seed=$((SHIFT + 851001)) evals=6000 only=any out=$SPECIAL/r3_l2_twist_deep_a.json" >> "$LIST"
  echo "mode=search level=r3_l2 twist=1 seed=$((SHIFT + 851002)) evals=6000 only=any out=$SPECIAL/r3_l2_twist_deep_b.json" >> "$LIST"
elif [ "$PART" = "5" ]; then
  # 3-4: the three-star champions of the search without the Sling Post (part 3), played again as they are and with no tower
  # above tier 2 and above tier 1. They take the place of the empty part 2 files for 3-4.
  echo "mode=replay level=r3_l4 from=$SPECIAL/r3_l4_nosling_a.json pick=three_star_best out=$SPECIAL/r3_l4_replay_champions.json" >> "$LIST"
  echo "mode=replay level=r3_l4 from=$SPECIAL/r3_l4_nosling_a.json pick=three_star_best max_tier=2 out=$SPECIAL/r3_l4_replay_champions_t2.json" >> "$LIST"
  echo "mode=replay level=r3_l4 from=$SPECIAL/r3_l4_nosling_a.json pick=three_star_best max_tier=1 out=$SPECIAL/r3_l4_replay_champions_t1.json" >> "$LIST"
else
  for LEVEL in r3_l4 r3_l5 r3_l6; do
    echo "mode=replay level=$LEVEL from=$OUT/${LEVEL}_search_any.json pick=three_star_best out=$SPECIAL/${LEVEL}_replay_champions.json" >> "$LIST"
    echo "mode=replay level=$LEVEL from=$OUT/${LEVEL}_search_any.json pick=three_star_best max_tier=2 out=$SPECIAL/${LEVEL}_replay_champions_t2.json" >> "$LIST"
    echo "mode=replay level=$LEVEL from=$OUT/${LEVEL}_search_any.json pick=three_star_best max_tier=1 out=$SPECIAL/${LEVEL}_replay_champions_t1.json" >> "$LIST"
  done
  echo "mode=replay level=r3_l6 twist=1 from=$OUT/r3_l6_search_twist.json pick=best_win out=$SPECIAL/r3_l6_replay_twist_champion.json" >> "$LIST"
fi
run_one() {
  OUTFILE=$(echo "$1" | sed 's/.*out=//')
  if [ -f "$OUTFILE" ]; then return; fi
  if ! mkdir "$2/.lock_$(basename "$OUTFILE")" 2> /dev/null; then return; fi
  timeout 7200 godot --headless --path . --script res://tools/balance/run.gd -- $1 > /dev/null 2>> "$2/errors.txt"
}
export -f run_one
cat "$LIST" | xargs -P "$JOBS" -I{} bash -c 'run_one "{}" '"$SPECIAL"
echo "done: $(ls "$SPECIAL" | wc -l) files in $SPECIAL"
