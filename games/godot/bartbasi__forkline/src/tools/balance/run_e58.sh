#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# The jobs of task E5.5 and E8.2 (docs/balance/region5-8-2026-10-30.md) that the pass scripts do not write. Run it from the repo root of a clean
# copy of the commit measured, after `godot --headless --path . --import`:
#     OUT=docs/balance/raw/2026-10-30-e58 bash tools/balance/run_e58.sh T4 2      # tier 4 runs, seeds 1 to 100, default bots and the two options
#     OUT=... bash tools/balance/run_e58.sh TP 2                                   # Glimmertoad's packs forced, and the new tier 4 packs forced
#     OUT=... bash tools/balance/run_e58.sh PK 2                                   # the most crowded wave of regions 5 and 8 as a saved game
#     OUT=... bash tools/balance/run_e58.sh TS 2                                   # Glimmertoad's boss waves weaker, forced
#     OUT=... bash tools/balance/run_e58.sh HU 2                                   # more any-tower searches where the first found no three-star build
#     OUT=... bash tools/balance/run_e58.sh WI 2                                   # 8-6 wave what-ifs (level files in tools/balance/variants/)
# The campaign pass itself is `SEED_SHIFT=100000 bash tools/balance/run_pass.sh DATE N r5_l1 ... r8_l6` (r5_l5 and r5_l6 with EVALS=6000)
# and run_pass_post.sh. The list is written to $OUT/jobs_e58_PHASE.txt and played by run_list.sh. DRY=1 only writes the list.
#
# T4. mode=rates, tier 4, seeds 1 to 100 (two jobs of 50), Normal, base cards, leaks=1, in five folders: runs_t4 (the bots without the two habits, which
# were the default until E5.5), runs_t4_air55 (air_floor=55 alone), runs_t4_sc9 (scarecrow_from=9 alone), runs_t4_both (both habits: the default from
# tier 2 up since E5.5) and runs_t4_nocards (both habits, and the tower cards of tiers 2 to 4 and their perks out of the pool: the second reading of
# RULES 14.8). The files are named rates_base_r0_FIRST.json, so runs_summary.gd reads each folder with tier=4. Every folder names both options, so
# the result does not depend on the bots' defaults. (The jobs of runs_t4, _air55, _sc9 and _both were played on bots whose defaults were off, with only
# the options that were non-zero on the line: the same plays.)
# TP. The two Glimmertoad packs forced onto seeds 1 to 100 (the runs that start wave 18 are the bar: 50% to 75%) without the habits, with both habits
# and with both habits and the tower cards out; and the three new tier 4 packs of bands 3 to 5 (b3_blinking_lanes, b4_blinking_watch, b5_hoot_siege)
# forced, stopped when the pack is done (stop = 3 times the band), with both habits. Files force_pack_ID_FIRST.json in the folders above.
# PK. perf_peak.gd on r5_l1 to r5_l6 and r8_l1 to r8_l6 (150 strategies a level at each of the 3 biggest waves and pairs), the Twists that change a
# wave's size (5-6 and 8-6 Double Trouble, 8-4 Twice the Wings), and the tier 4 run packs with the risk cards that make a wave biggest.

PHASE="${1:-T4}"
JOBS="${2:-2}"
OUT="${OUT:-docs/balance/raw/2026-10-30-e58}"
mkdir -p "$OUT"
LIST="$OUT/jobs_e58_$PHASE.txt"
: > "$LIST"
NOCARDS="pool=minus:tower_scarecrow,big_hat,tower_snow_fort,packed_snow,tower_moth_lantern,bright_wick"
if [ "$PHASE" = "T4" ]; then
  for CASE in "runs_t4:air_floor=0 scarecrow_from=0" "runs_t4_air55:air_floor=55 scarecrow_from=0" "runs_t4_sc9:air_floor=0 scarecrow_from=9" "runs_t4_both:air_floor=55 scarecrow_from=9" "runs_t4_nocards:air_floor=55 scarecrow_from=9"; do
    DIR=${CASE%%:*}
    OPTS=${CASE#*:}
    POOL="pool=base"
    [ "$DIR" = "runs_t4_nocards" ] && POOL="$NOCARDS"
    for FIRST in 1 51; do
      echo "SCRIPT=runs.gd mode=rates first=$FIRST count=50 $POOL relaxed=0 tier=4 leaks=1 $OPTS out=$OUT/$DIR/rates_base_r0_$FIRST.json" >> "$LIST"
    done
  done
elif [ "$PHASE" = "TP" ]; then
  for CASE in "runs_t4:air_floor=0 scarecrow_from=0" "runs_t4_both:air_floor=55 scarecrow_from=9" "runs_t4_nocards:air_floor=55 scarecrow_from=9"; do
    DIR=${CASE%%:*}
    OPTS=${CASE#*:}
    POOL="pool=base"
    [ "$DIR" = "runs_t4_nocards" ] && POOL="$NOCARDS"
    for PACK in b6_toad_glen b6_toad_hollow; do
      for FIRST in 1 51; do
        echo "SCRIPT=runs.gd mode=rates first=$FIRST count=50 $POOL relaxed=0 tier=4 pack=$PACK $OPTS out=$OUT/$DIR/force_pack_${PACK}_$FIRST.json" >> "$LIST"
      done
    done
  done
  for CASE in "b3_blinking_lanes 9" "b4_blinking_watch 12" "b5_hoot_siege 15"; do
    set -- $CASE
    for FIRST in 1 51; do
      echo "SCRIPT=runs.gd mode=rates first=$FIRST count=50 pool=base relaxed=0 tier=4 pack=$1 stop=$2 air_floor=55 scarecrow_from=9 out=$OUT/runs_t4_both/force_pack_$1_$FIRST.json" >> "$LIST"
    done
  done
elif [ "$PHASE" = "HU" ]; then
  # Three stars hunts: the any-tower search of 3000 builds found no three-star build on 5-3, 5-6 and 8-5 (all three have a tower or kind limit; the
  # level designer's own searches found them). Two more any-tower searches of 6000 builds each, seeds 940000 + 100 K + 0 and + 1 (K = 53, 56, 85).
  for LEVEL in r5_l3 r5_l6 r8_l5; do
    K=${LEVEL:1:1}${LEVEL:4:1}
    echo "mode=search level=$LEVEL seed=$((940000 + 100 * K)) evals=6000 only=any out=$OUT/hunt/${LEVEL}_search_any_h0.json" >> "$LIST"
    echo "mode=search level=$LEVEL seed=$((940000 + 100 * K + 1)) evals=6000 only=any out=$OUT/hunt/${LEVEL}_search_any_h1.json" >> "$LIST"
  done
elif [ "$PHASE" = "W86" ]; then
  # 8-6 wave what-ifs (level files tools/balance/variants/r8_l6_NAME.json, run.gd level_file=). VARS (default b65 b80 c240 c240b65) and KINDS (default
  # plain; plain, twist, any, solo, tsearch) choose the jobs. plain: the plain recipe on Normal over every placement; twist: the plain recipe with the Twist;
  # any: search of 3000 builds, any tower; solo: the lone Sling Post on the pass seeds 838601 and 868601 (6000 builds, stopping dry at 2500); tsearch: the
  # Twist search of 1500 builds (seed 986000 + 1000 N + 600 ... below). Variants: b65 and b80 are the boss wave (wave 12) at strength 65 and 80 (50 as built);
  # c240 is wave 7 at strength 200 and wave 10 at 240 (160 and 195 as built); c240b65 is both.
  mkdir -p "$OUT/whatif86"
  N=0
  for V in ${VARS:-b65 b80 c240 c240b65}; do
    N=$((N + 1))
    F=res://tools/balance/variants/r8_l6_$V.json
    for K in ${KINDS:-plain}; do
      case "$K" in
        plain) echo "mode=plain level=r8_l6 level_file=$F out=$OUT/whatif86/${V}_plain.json" >> "$LIST" ;;
        twist) echo "mode=plain level=r8_l6 level_file=$F twist=1 out=$OUT/whatif86/${V}_plain_twist.json" >> "$LIST" ;;
        any) echo "mode=search level=r8_l6 level_file=$F seed=$((986000 + 1000 * N)) evals=3000 only=any out=$OUT/whatif86/${V}_any.json" >> "$LIST" ;;
        solo)
          echo "mode=search level=r8_l6 level_file=$F seed=838601 evals=6000 stop_dry=2500 only=solo:sling_post out=$OUT/whatif86/${V}_solo_a.json" >> "$LIST"
          echo "mode=search level=r8_l6 level_file=$F seed=868601 evals=6000 stop_dry=2500 only=solo:sling_post out=$OUT/whatif86/${V}_solo_b.json" >> "$LIST" ;;
        tdeep)
          echo "mode=search level=r8_l6 level_file=$F twist=1 seed=$((989000 + 1000 * N)) evals=6000 only=any out=$OUT/whatif86/${V}_twist_deep_a.json" >> "$LIST"
          echo "mode=search level=r8_l6 level_file=$F twist=1 seed=$((989500 + 1000 * N)) evals=6000 only=any out=$OUT/whatif86/${V}_twist_deep_b.json" >> "$LIST" ;;
        tsearch) echo "mode=search level=r8_l6 level_file=$F twist=1 seed=$((987000 + 1000 * N)) evals=1500 only=any out=$OUT/whatif86/${V}_twist_search.json" >> "$LIST" ;;
      esac
    done
  done
elif [ "$PHASE" = "TS" ]; then
  # Glimmertoad's boss waves at strength 50, the lowest a band 6 pack allows (tweak=pack_strength:PACK;N, in memory): b6_toad_glen 80 to 50, b6_toad_hollow 70 to 50. Forced onto
  # seeds 1 to 100, both habits, Normal, base cards (the folder runs_t4_both's reading). The slope of the other bosses is about 0.6 points of win rate for each point.
  mkdir -p "$OUT/packs"
  for CASE in "b6_toad_glen 50" "b6_toad_hollow 50"; do
    set -- $CASE
    echo "SCRIPT=runs.gd mode=rates first=1 count=100 pool=base relaxed=0 tier=4 pack=$1 air_floor=55 scarecrow_from=9 tweak=pack_strength:$1;$2 out=$OUT/packs/$1_s$2.json" >> "$LIST"
  done
elif [ "$PHASE" = "NB" ]; then
  # The Bramble Cottage watch item (RULES 5.10, as edited by E6.3/E7.3): the any-tower search again with the cottage left out, on the region 8 levels
  # where it stands in more than 9 of 10 three-star builds (8-2, 8-3, 8-4). Seeds 960000 + 100 * K, 3000 builds, a star 3 ban applied (8-2 no Sling Post,
  # 8-4 no Lullaby Bell). For 8-3, whose with-cottage search found only 105 three-star builds in 3000, the search is 6000 builds.
  mkdir -p "$OUT/nobramble"
  ALL="sling_post,pumpkin_catapult,lullaby_bell,longbow_loft,firework_tower,bakery,scarecrow,snow_fort,moth_lantern"
  echo "mode=search level=r8_l2 seed=$((960000 + 8200)) evals=3000 only=$(echo "$ALL" | sed 's/sling_post,//') out=$OUT/nobramble/r8_l2_search_no_bramble.json" >> "$LIST"
  echo "mode=search level=r8_l3 seed=$((960000 + 8300)) evals=6000 only=$ALL out=$OUT/nobramble/r8_l3_search_no_bramble.json" >> "$LIST"
  echo "mode=search level=r8_l4 seed=$((960000 + 8400)) evals=3000 only=$(echo "$ALL" | sed 's/lullaby_bell,//') out=$OUT/nobramble/r8_l4_search_no_bramble.json" >> "$LIST"
elif [ "$PHASE" = "WH" ]; then
  # 5-6 under "Have at most 5 towers.": the any-tower search of 3000 builds found no three-star build (WI), so two more of 6000 builds (seeds 971000 + 0 and 1),
  # to see whether the rule can be reached at all.
  mkdir -p "$OUT/whatif"
  for A in 0 1; do
    echo "mode=search level=r5_l6 seed=$((971000 + A)) evals=6000 only=any tweak=star3:towers_at_most;5 out=$OUT/whatif/r5_l6_star3_towers_at_most_5_any_h$A.json" >> "$LIST"
  done
elif [ "$PHASE" = "PK" ]; then
  mkdir -p "$OUT/perf"
  for NUM in 1 2 3 4 5 6; do
    for R in 5 8; do
      echo "SCRIPT=perf_peak.gd level=r${R}_l$NUM seeds=150 targets=3 out=$OUT/perf/perf_r${R}_l$NUM.json save=$OUT/perf/save_r${R}_l$NUM" >> "$LIST"
    done
  done
  for L in r5_l6 r8_l4 r8_l6; do
    echo "SCRIPT=perf_peak.gd level=$L twist=1 seeds=150 targets=3 out=$OUT/perf/perf_${L}_twist.json save=$OUT/perf/save_${L}_twist" >> "$LIST"
  done
  for CASE in "b5_hoot_siege 13" "b6_toad_glen 16" "b6_toad_hollow 16"; do
    set -- $CASE
    for CARD in crowded_night pip_parade; do
      echo "SCRIPT=perf_peak.gd tier=4 run=$1 wave=$2 card=$CARD seeds=25 out=$OUT/perf/perf_run_$1_w$2_$CARD.json save=$OUT/perf/save_run_$1_w$2_$CARD" >> "$LIST"
    done
  done
elif [ "$PHASE" = "WI" ]; then
  # 5-6: the lone Sling Post earned three stars on one seed under "Have at most 6 towers." (E5.5). Other star 3 rules in memory only (run.gd
  # tweak=star3:KIND;N). Seeds 980000 + 1000 R + 100 K + A: K = 56, R the rule's number (21 to 24), A 0 for the search with the towers the rule
  # leaves (3000 builds) and 1 for the lone Sling Post (6000 builds, stopping dry at 2500). The lone Sling Post is also played on seed 835601,
  # the pass seed that found the three-star builds. A rule that bans the Sling Post needs no lone search.
  mkdir -p "$OUT/whatif"
  NOSLING="lullaby_bell,pumpkin_catapult,longbow_loft,firework_tower,bakery,bramble_cottage"
  R=20
  for RULE in "towers_at_most;5" "towers_at_most;4" "tower_ban;sling_post" "tier_at_most;2"; do
    R=$((R + 1))
    NAME=$(echo "$RULE" | sed 's/;/_/')
    if [ "$RULE" = "tower_ban;sling_post" ]; then
      echo "mode=search level=r5_l6 seed=$((980000 + 1000 * R + 5600)) evals=3000 only=$NOSLING tweak=star3:$RULE out=$OUT/whatif/r5_l6_star3_${NAME}_any.json" >> "$LIST"
    else
      echo "mode=search level=r5_l6 seed=$((980000 + 1000 * R + 5600)) evals=3000 only=any tweak=star3:$RULE out=$OUT/whatif/r5_l6_star3_${NAME}_any.json" >> "$LIST"
      echo "mode=search level=r5_l6 seed=$((980000 + 1000 * R + 5601)) evals=6000 stop_dry=2500 only=solo:sling_post tweak=star3:$RULE out=$OUT/whatif/r5_l6_star3_${NAME}_solo_sling_post.json" >> "$LIST"
      echo "mode=search level=r5_l6 seed=835601 evals=6000 stop_dry=2500 only=solo:sling_post tweak=star3:$RULE out=$OUT/whatif/r5_l6_star3_${NAME}_solo_sling_post_s2.json" >> "$LIST"
    fi
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
