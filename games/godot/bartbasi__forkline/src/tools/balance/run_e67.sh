#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# The jobs of task E6.2 and E7.2 (docs/balance/region6-7-2026-10-29.md) that the pass scripts do not write. Run it from the repo root of a
# clean copy of the commit measured, after `godot --headless --path . --import`:
#     OUT=docs/balance/raw/2026-10-29-e67 bash tools/balance/run_e67.sh WI 3     # 6-4 wave and star 3 what-ifs, 7-4 star 3 what-ifs
#     OUT=... bash tools/balance/run_e67.sh WI2 2                                 # lone Sling Post what-ifs again on the seeds that found three-star builds
#     OUT=... bash tools/balance/run_e67.sh AIR 3                                 # tier 2 and 3 runs with leaks, and the anti-air floor
#     OUT=... bash tools/balance/run_e67.sh NB 2                                  # the any-tower search with the Bramble Cottage left out
#     OUT=... bash tools/balance/run_e67.sh PW 3                                  # the first wave of b3_sleepy_rows and b3_snowballs with fewer Pips and Scamps
#     OUT=... bash tools/balance/run_e67.sh FP 3                                  # the new tier 2 and 3 packs forced onto seeds 1 to 100
#     OUT=... bash tools/balance/run_e67.sh ST 4                                  # the bridge stacks that lost the most runs by wave 6, forced
#     OUT=... bash tools/balance/run_e67.sh T0 2                                  # tier 0 with leaks, the baseline for the anti-air check
#     OUT=... bash tools/balance/run_e67.sh WT 2                                  # a stronger Scarecrow at tier 2, a stronger Snow Fort at tier 3
#     OUT=... bash tools/balance/run_e67.sh SC 2                                  # a bot that builds its Scarecrow late
#     OUT=... bash tools/balance/run_e67.sh NC 2                                  # tier 2 and 3 with the new tower cards out of the pool
#     OUT=... bash tools/balance/run_e67.sh PB 2                                  # Old Hayrick's packs forced, with the boss wave 40 and 80 stronger
#     OUT=... bash tools/balance/run_e67.sh PK 3                                  # the most crowded new wave as a saved game
# The campaign pass itself is `SEED_SHIFT=100000 bash tools/balance/run_pass.sh 2026-10-29-e67 4 r6_l1 ... r7_l6` and run_pass_post.sh, the
# runs are `TIER=2 OUT=.../runs_t2 bash tools/balance/run_b4.sh A 2` (and TIER=3). The list is written to $OUT/jobs_e67_PHASE.txt and played by
# run_list.sh (a lock folder per job, so several copies can work on one list). DRY=1 only writes the list.
#
# WI. Seeds 980000 + 1000 * R + 100 * K + A: K = 10 * region + level number, R the number of the variant or rule below, A 0 for the search
# with every tower the rule leaves (3000 builds) and 1 for the lone Sling Post search (2500 builds, stopping dry at 2500; a later check uses 6000
# builds and the seeds + 500). A wave variant of 6-4 is a level file in tools/balance/variants/ (run.gd level_file=); a star 3 rule is
# run.gd tweak=star3:KIND;N, in memory only.
#   6-4 v1  wave 11: strength 125 to 190, Pips 36 to 48.            6-4 v2  v1, and wave 5: strength 105 to 160, Pips 40 to 48.
#   6-4 v5  wave 5: strength 105 to 160, Pips 40 to 56.             6-4 v6  wave 11: strength 125 to 200, Pips 36 to 56.
#   6-4 and 7-4 star 3 rules: at most 5 towers, at most 4 towers, build no Sling Posts; 7-4 also at most 3 kinds of tower.
# AIR. mode=rates on tiers 1 to 3, seeds 1 to 100, Normal, base cards, leaks=1 (the lives lost by creature type in every row), with the default
# bots and with the anti-air floor (air_floor=55, about the share the bots keep at tier 0), at tiers 1, 2 and 3.

PHASE="${1:-WI}"
JOBS="${2:-3}"
OUT="${OUT:-docs/balance/raw/2026-10-29-e67}"
mkdir -p "$OUT"
LIST="$OUT/jobs_e67_$PHASE.txt"
: > "$LIST"
if [ "$PHASE" = "WI" ]; then
  mkdir -p "$OUT/whatif"
  T64="lullaby_bell,pumpkin_catapult,longbow_loft,firework_tower,bakery,bramble_cottage,scarecrow"
  T74="$T64,snow_fort"
  for V in v1 v2 v5 v6; do
    R=$(echo "$V" | sed 's/v//')
    echo "mode=plain level=r6_l4 level_file=res://tools/balance/variants/r6_l4_$V.json out=$OUT/whatif/r6_l4_${V}_plain.json" >> "$LIST"
    echo "mode=search level=r6_l4 level_file=res://tools/balance/variants/r6_l4_$V.json seed=$((980000 + 1000 * R + 6400)) evals=3000 only=any out=$OUT/whatif/r6_l4_${V}_any.json" >> "$LIST"
    echo "mode=search level=r6_l4 level_file=res://tools/balance/variants/r6_l4_$V.json seed=$((980000 + 1000 * R + 6401)) evals=6000 stop_dry=2500 only=solo:sling_post out=$OUT/whatif/r6_l4_${V}_solo_sling_post.json" >> "$LIST"
  done
  for LEVEL in r6_l4 r7_l4; do
    K=$(echo "$LEVEL" | sed 's/r\([0-9]\)_l\([0-9]\)/\1\2/')
    if [ "$LEVEL" = "r6_l4" ]; then T="$T64"; else T="$T74"; fi
    R=10
    for RULE in "towers_at_most;5" "towers_at_most;4" "tower_ban;sling_post" "kinds_at_most;3"; do
      R=$((R + 1))
      if [ "$LEVEL" = "r6_l4" ] && [ "$RULE" = "kinds_at_most;3" ]; then continue; fi
      NAME=$(echo "$RULE" | sed 's/;/_/')
      if [ "$RULE" = "tower_ban;sling_post" ]; then
        echo "mode=search level=$LEVEL seed=$((980000 + 1000 * R + K * 100)) evals=3000 only=$T tweak=star3:$RULE out=$OUT/whatif/${LEVEL}_star3_${NAME}_any.json" >> "$LIST"
      else
        echo "mode=search level=$LEVEL seed=$((980000 + 1000 * R + K * 100)) evals=3000 only=any tweak=star3:$RULE out=$OUT/whatif/${LEVEL}_star3_${NAME}_any.json" >> "$LIST"
        echo "mode=search level=$LEVEL seed=$((980000 + 1000 * R + K * 100 + 1)) evals=6000 stop_dry=2500 only=solo:sling_post tweak=star3:$RULE out=$OUT/whatif/${LEVEL}_star3_${NAME}_solo_sling_post.json" >> "$LIST"
      fi
    done
  done
elif [ "$PHASE" = "AIR" ]; then
  mkdir -p "$OUT/air"
  for T in 1 2 3; do
    for FLOOR in 0 55; do
      for FIRST in 1 51; do
        echo "SCRIPT=runs.gd mode=rates first=$FIRST count=50 pool=base relaxed=0 tier=$T leaks=1 air_floor=$FLOOR out=$OUT/air/t${T}_floor${FLOOR}_$FIRST.json" >> "$LIST"
      done
    done
  done
elif [ "$PHASE" = "WI2" ]; then
  # The lone Sling Post searches again with the seeds of the campaign pass that found three-star builds: a lone search is very seed dependent
  # (6-4: seed 836401 found none in 6000 builds, 866401 found 1216; 7-4: 837401 found 1200, 867401 won nothing in 2500). Each variant and rule
  # is played on the seed that found them: 866401 on 6-4, 837401 on 7-4.
  mkdir -p "$OUT/whatif"
  for V in v1 v2 v5 v6; do
    echo "mode=search level=r6_l4 level_file=res://tools/balance/variants/r6_l4_$V.json seed=866401 evals=6000 stop_dry=2500 only=solo:sling_post out=$OUT/whatif/r6_l4_${V}_solo_sling_post_s2.json" >> "$LIST"
  done
  for RULE in "towers_at_most;5" "towers_at_most;4"; do
    NAME=$(echo "$RULE" | sed 's/;/_/')
    echo "mode=search level=r6_l4 seed=866401 evals=6000 stop_dry=2500 only=solo:sling_post tweak=star3:$RULE out=$OUT/whatif/r6_l4_star3_${NAME}_solo_sling_post_s2.json" >> "$LIST"
    echo "mode=search level=r7_l4 seed=837401 evals=6000 stop_dry=2500 only=solo:sling_post tweak=star3:$RULE out=$OUT/whatif/r7_l4_star3_${NAME}_solo_sling_post_s2.json" >> "$LIST"
  done
  echo "mode=search level=r7_l4 seed=837401 evals=6000 stop_dry=2500 only=solo:sling_post tweak=star3:kinds_at_most;3 out=$OUT/whatif/r7_l4_star3_kinds_at_most_3_solo_sling_post_s2.json" >> "$LIST"
elif [ "$PHASE" = "NB" ]; then
  # The Bramble Cottage watch item (RULES 5.10): the any-tower search again with the cottage left out, on the levels where it stands in more than
  # 9 of 10 three-star builds. Seeds 960000 + 100 * K, 3000 builds. A level whose star 3 bans a tower leaves that tower out too.
  mkdir -p "$OUT/nobramble"
  BASE="sling_post,pumpkin_catapult,lullaby_bell,longbow_loft,firework_tower,bakery"
  for LEVEL in r6_l1 r6_l3 r6_l4 r6_l5 r6_l6 r7_l2 r7_l3 r7_l5; do
    K=$(echo "$LEVEL" | sed 's/r\([0-9]\)_l\([0-9]\)/\1\2/')
    TOWERS="$BASE"
    [ "$LEVEL" != "r6_l1" ] && [ "$LEVEL" != "r6_l2" ] && TOWERS="$TOWERS,scarecrow"
    [ "${LEVEL:1:1}" = "7" ] && TOWERS="$TOWERS,snow_fort"
    [ "$LEVEL" = "r6_l3" ] && TOWERS=$(echo "$TOWERS" | sed 's/longbow_loft,//')
    [ "$LEVEL" = "r7_l2" ] && TOWERS=$(echo "$TOWERS" | sed 's/pumpkin_catapult,//')
    echo "mode=search level=$LEVEL seed=$((960000 + 100 * K)) evals=3000 only=$TOWERS out=$OUT/nobramble/${LEVEL}_search_no_bramble.json" >> "$LIST"
  done
elif [ "$PHASE" = "PW" ]; then
  # What the first wave of the two new band 3 packs needs (E5.2 did this for b3_mossy_ruts): b3_sleepy_rows (tier 2) with its first wave's Pips 16 to 10 and
  # Scamps 12 to 8, with its Sleepyheads 5 to 3, and with all three; b3_snowballs (tier 3) with its first wave's Pips 16 to 10 and Scamps 12 to 8. Forced onto seeds 1 to 100,
  # stopped when the pack is done (stop 9), the 16 strategies. Compare with runs_t2/force_pack_b3_sleepy_rows_* and runs_t3/force_pack_b3_snowballs_*.
  mkdir -p "$OUT/packs"
  for FIRST in 1 51; do
    echo "SCRIPT=runs.gd mode=rates first=$FIRST count=50 pool=base relaxed=0 tier=2 pack=b3_sleepy_rows stop=9 tweak=pack_count:b3_sleepy_rows;1;pip;10,pack_count:b3_sleepy_rows;1;scamp;8 out=$OUT/packs/sleepy_rows_pips10_scamps8_$FIRST.json" >> "$LIST"
    echo "SCRIPT=runs.gd mode=rates first=$FIRST count=50 pool=base relaxed=0 tier=2 pack=b3_sleepy_rows stop=9 tweak=pack_count:b3_sleepy_rows;1;sleepyhead;3 out=$OUT/packs/sleepy_rows_sleepyheads3_$FIRST.json" >> "$LIST"
    echo "SCRIPT=runs.gd mode=rates first=$FIRST count=50 pool=base relaxed=0 tier=3 pack=b3_snowballs stop=9 tweak=pack_count:b3_snowballs;1;pip;10,pack_count:b3_snowballs;1;scamp;8 out=$OUT/packs/snowballs_pips10_scamps8_$FIRST.json" >> "$LIST"
    echo "SCRIPT=runs.gd mode=rates first=$FIRST count=50 pool=base relaxed=0 tier=2 pack=b3_sleepy_rows stop=9 tweak=pack_count:b3_sleepy_rows;1;pip;10,pack_count:b3_sleepy_rows;1;scamp;8,pack_count:b3_sleepy_rows;1;sleepyhead;3 out=$OUT/packs/sleepy_rows_pips10_scamps8_sleepyheads3_$FIRST.json" >> "$LIST"
  done
elif [ "$PHASE" = "FP" ]; then
  # The new packs of tiers 2 and 3 (bands 3 to 5) forced onto seeds 1 to 100 at their own tier, the 16 strategies, stopped when the pack is done
  # (stop = 3 times the band). The files are named force_pack_ID_FIRST.json in the tier's run folder, so runs_summary.gd part=forced reads them.
  for CASE in "2 b3_sleepy_rows 9" "2 b4_glowing_watch 12" "2 b5_harvest_siege 15" "3 b3_snowballs 9" "3 b4_yawning_watch 12" "3 b5_frost_siege 15"; do
    set -- $CASE
    for FIRST in 1 51; do
      echo "SCRIPT=runs.gd mode=rates first=$FIRST count=50 pool=base relaxed=0 tier=$1 pack=$2 stop=$3 out=$OUT/runs_t$1/force_pack_$2_$FIRST.json" >> "$LIST"
    done
  done
elif [ "$PHASE" = "ST" ]; then
  # The stacks with a tier 2 or tier 3 map piece that lost the most runs by wave 6 on natural seeds (bar: at most 10%), forced onto seeds 1 to 100
  # (1600 plays each, stop=6, Normal, base cards): the bridge middles mid_planks and mid_cart. The two tiers play them at their own content tier.
  mkdir -p "$OUT/stacks"
  for CASE in "2 top_side,mid_planks,bot_yard" "3 top_side,mid_planks,bot_yard" "3 top_wing,mid_cart,bot_square" "3 top_wing,mid_cart,bot_porch"; do
    set -- $CASE
    NAME=$(echo "$2" | sed 's/,/_/g')
    echo "SCRIPT=runs.gd mode=rates first=1 count=100 pool=base relaxed=0 tier=$1 stack=$2 stop=6 out=$OUT/stacks/t$1_$NAME.json" >> "$LIST"
  done
elif [ "$PHASE" = "T0" ]; then
  # Tier 0 with leaks=1 on seeds 1 to 100 (the same plays as B5's rates files, now with the lives lost by creature type): the baseline for the
  # anti-air share and the share of lives lost to flyers.
  mkdir -p "$OUT/air"
  for FIRST in 1 51; do
    echo "SCRIPT=runs.gd mode=rates first=$FIRST count=50 pool=base relaxed=0 leaks=1 out=$OUT/air/t0_floor0_$FIRST.json" >> "$LIST"
  done
elif [ "$PHASE" = "WT" ]; then
  # What the new towers need (the same seeds as air/t2_floor0_1 and air/t3_floor0_1): tier 2 with every Scarecrow fright 10 points higher
  # (15, 25, 40, 25 become 25, 35, 50, 35), tier 3 with the Snow Fort's damage 1.5 times (16, 28, 64, 24 become 24, 42, 96, 36). The stat files are copies of
  # data/stats/towers.json of the measured commit (with the E5.3 cottage) in tools/balance/variants/. Seeds 1 to 50, Normal, base cards, leaks=1.
  mkdir -p "$OUT/towers"
  echo "SCRIPT=runs.gd mode=rates first=1 count=50 pool=base relaxed=0 tier=2 leaks=1 towers=res://tools/balance/variants/towers_scarecrow_plus10.json out=$OUT/towers/t2_scarecrow_plus10_1.json" >> "$LIST"
  echo "SCRIPT=runs.gd mode=rates first=1 count=50 pool=base relaxed=0 tier=3 leaks=1 towers=res://tools/balance/variants/towers_snow_fort_x15.json out=$OUT/towers/t3_snow_fort_x15_1.json" >> "$LIST"
elif [ "$PHASE" = "SC" ]; then
  # A bot that builds its Scarecrow late (scarecrow_from=W, like the Bakery's bakery_from=9): tier 2 with W 6 and 9, tier 3 with W 9, and with W 9 and the
  # anti-air floor 55. Seeds 1 to 50 (800 plays each), Normal, base cards, leaks=1. Compare with air/t2_floor0_1, air/t3_floor0_1 and air/t3_floor55_1.
  mkdir -p "$OUT/scarecrow"
  for W in 6 9; do
    echo "SCRIPT=runs.gd mode=rates first=1 count=50 pool=base relaxed=0 tier=2 leaks=1 scarecrow_from=$W out=$OUT/scarecrow/t2_from${W}_1.json" >> "$LIST"
  done
  echo "SCRIPT=runs.gd mode=rates first=1 count=50 pool=base relaxed=0 tier=3 leaks=1 scarecrow_from=9 out=$OUT/scarecrow/t3_from9_1.json" >> "$LIST"
  echo "SCRIPT=runs.gd mode=rates first=1 count=50 pool=base relaxed=0 tier=3 leaks=1 scarecrow_from=9 air_floor=55 out=$OUT/scarecrow/t3_from9_floor55_1.json" >> "$LIST"
elif [ "$PHASE" = "NC" ]; then
  # The new tower cards out of the pool (E5.2 did this for the Bramble Cottage): tier 2 without the Scarecrow card and its perk, tier 3 without the
  # Snow Fort card and its perk, and tier 3 without both new towers. Seeds 1 to 100, Normal, the 16 strategies, leaks=1. Compare with air/t2_floor0_* and
  # air/t3_floor0_* (the same seeds with the default pool).
  mkdir -p "$OUT/nocard"
  for FIRST in 1 51; do
    echo "SCRIPT=runs.gd mode=rates first=$FIRST count=50 pool=minus:tower_scarecrow,big_hat relaxed=0 tier=2 leaks=1 out=$OUT/nocard/t2_no_scarecrow_$FIRST.json" >> "$LIST"
    echo "SCRIPT=runs.gd mode=rates first=$FIRST count=50 pool=minus:tower_snow_fort,packed_snow relaxed=0 tier=3 leaks=1 out=$OUT/nocard/t3_no_snow_fort_$FIRST.json" >> "$LIST"
    echo "SCRIPT=runs.gd mode=rates first=$FIRST count=50 pool=minus:tower_snow_fort,packed_snow,tower_scarecrow,big_hat relaxed=0 tier=3 leaks=1 out=$OUT/nocard/t3_no_new_towers_$FIRST.json" >> "$LIST"
  done
elif [ "$PHASE" = "PB" ]; then
  # Old Hayrick's two packs at tier 2 (140 and 130), forced onto seeds 1 to 100 (the 16 strategies, Normal, base cards), with the boss wave's strength
  # as built, 40 higher and 80 higher (tweak=pack_strength:PACK;N, in memory). Win rate of the runs that start wave 18 is the bar (50% to 75%).
  mkdir -p "$OUT/packs"
  for CASE in "b6_hayrick_field 140" "b6_hayrick_barn 130"; do
    set -- $CASE
    for ADD in 0 40 80; do
      N=$(($2 + ADD))
      if [ "$ADD" = "0" ]; then TW=""; else TW=" tweak=pack_strength:$1;$N"; fi
      echo "SCRIPT=runs.gd mode=rates first=1 count=100 pool=base relaxed=0 tier=2 pack=$1$TW out=$OUT/packs/$1_s$N.json" >> "$LIST"
    done
  done
elif [ "$PHASE" = "PK" ]; then
  # The most crowded new wave as a saved game (perf_peak.gd): every level of regions 6 and 7 (300 strategies a level at each of the 3 biggest
  # waves and pairs), the Twists that change a wave's size (6-3 Twice the Wings, 6-6 and 7-6 Double Trouble), and the tier 2 and 3 run packs
  # with the risk cards that make their waves biggest (Crowded Night, Pip Parade), 25 seeds times 16 strategies.
  mkdir -p "$OUT/perf"
  for NUM in 1 2 3 4 5 6; do
    for R in 6 7; do
      echo "SCRIPT=perf_peak.gd level=r${R}_l$NUM seeds=300 targets=3 out=$OUT/perf/perf_r${R}_l$NUM.json save=$OUT/perf/save_r${R}_l$NUM" >> "$LIST"
    done
  done
  for L in r6_l3 r6_l6 r7_l6; do
    echo "SCRIPT=perf_peak.gd level=$L twist=1 seeds=300 targets=3 out=$OUT/perf/perf_${L}_twist.json save=$OUT/perf/save_${L}_twist" >> "$LIST"
  done
  for CASE in "2 b5_harvest_siege 13" "2 b6_hayrick_field 16" "2 b6_hayrick_barn 16" "3 b5_frost_siege 13" "3 b6_snore_ridge 16" "3 b6_snore_drift 16"; do
    set -- $CASE
    for CARD in crowded_night pip_parade; do
      echo "SCRIPT=perf_peak.gd tier=$1 run=$2 wave=$3 card=$CARD seeds=25 out=$OUT/perf/perf_run_$2_w$3_$CARD.json save=$OUT/perf/save_run_$2_w$3_$CARD" >> "$LIST"
    done
  done
else
  echo "unknown phase $PHASE"
  exit 1
fi
if [ -n "$DRY" ]; then
  echo "wrote $(wc -l < "$LIST") jobs to $LIST"
  exit 0
fi
bash "$(dirname "$0")/run_list.sh" "$LIST" "$JOBS"
