#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# The job lists of task B7 (docs/balance/final-2026-10-30.md): the final pass of version 1. Run it from the repo root of a clean copy of
# the commit measured (git archive, then godot --headless --path . --import):
#     OUT=docs/balance/raw/2026-10-30-b7 bash tools/balance/run_b7.sh PHASE        # appends the phase's jobs to $OUT/queue.txt
#     OUT=... bash tools/balance/run_queue.sh $OUT/queue.txt 8                       # plays the queue, 8 jobs at once, until its sentinel is killed
# DRY=1 prints the phase's jobs instead of appending them. A job whose output file exists is skipped, so a phase can be added twice.
#
# Folders under $OUT: a (campaign jobs on the seeds of the 2025-10-25 pass, SEED_SHIFT=100000), b (campaign searches on new seeds, SEED_SHIFT=300000),
# r/tN (runs and dailies at content tier N), r/tN_nocards and r/t4_* (the card readings of RULES 14.8).
#
# Phases:
#   NEED   the need file of all 48 levels, in a and b (no plays)
#   CA     campaign, folder a: long searches of the changed levels (5-6, 6-4, 7-4, 8-6), then the cheap jobs of all 48 levels
#          (plain on Normal and Relaxed, plain with the Twist, Twist search of 1500 builds, random play, determinism)
#   CB     campaign, folder b: any-tower and lone-attacker searches of regions 1 to 4 and of the changed levels, on new seeds
#   R      runs: the 16 named strategies on run seeds 1 to 200 at tiers 0 to 4 (base cards, Relaxed at tiers 0 and 4, every card, the second
#          reading at tiers 2 to 4, the three newer tower cards one at a time at tier 4), and the same-seed checks
#   D      the daily: 400 days at each of the five tiers
#   POST   what the first jobs call for: a lone search played in full when its partner won, the Twist searches of 6000 builds, the three
#          stars hunts, the determinism jobs of the levels again in a new process
#   RPOST  the random search for run seeds 1 to 50 that no named strategy won, at each tier
#   X      cheaper extras: every card at tiers 1 to 3
#   NB     the Bramble Cottage watch item: an any-tower search with the cottage left out (SKIP="levels" leaves some out)
# Seeds are those of run_pass.sh (SEED_SHIFT) and run_b4.sh (run i has the seed i * 2654435761 mod 2^32; day n is 2026-10-25 plus n days).

PHASE="${1:-CA}"
OUT="${OUT:-docs/balance/raw/2026-10-30-b7}"
Q="${QUEUE:-$OUT/queue.txt}"
mkdir -p "$OUT/a" "$OUT/b" "$OUT/r"
CHANGED="r5_l6 r6_l4 r7_l4 r8_l6"
ALL_LEVELS=$(grep -o '"r[0-9]*_l[0-9]*"' data/levels/campaign.json | tr -d '"')
NOCARDS="tower_scarecrow,big_hat,tower_snow_fort,packed_snow,tower_moth_lantern,bright_wick"
SC="tower_scarecrow,big_hat"
SF="tower_snow_fort,packed_snow"
ML="tower_moth_lantern,bright_wick"
TMP="$OUT/.lines_$PHASE.txt"
: > "$TMP"

emit() { echo "$1" >> "$TMP"; }

if [ "$PHASE" = "NEED" ]; then
  for L in $ALL_LEVELS; do
    for D in a b; do
      [ -f "$OUT/$D/${L}_need.json" ] || timeout 300 godot --headless --path . --script res://tools/balance/run.gd -- mode=need level=$L out="$OUT/$D/${L}_need.json" > /dev/null 2>> "$OUT/errors.txt"
    done
  done
  echo "need files: $(ls "$OUT/a" | grep -c need) and $(ls "$OUT/b" | grep -c need)"
  exit 0
fi

if [ "$PHASE" = "CA" ] || [ "$PHASE" = "CB" ]; then
  [ "$PHASE" = "CA" ] && D=a && SHIFT=100000
  [ "$PHASE" = "CB" ] && D=b && SHIFT=300000
  DRY=1 SEED_SHIFT=$SHIFT bash tools/balance/run_pass.sh "${OUT#docs/balance/raw/}/$D" 8 > /dev/null
  JOBS="$OUT/$D/jobs.txt"
  if [ "$PHASE" = "CA" ]; then
    for L in $CHANGED; do
      grep "level=$L " "$JOBS" | grep 'mode=search' | grep -v 'twist=1' | while read -r LINE; do emit "$LINE"; done
    done
    grep 'twist=1' "$JOBS" | grep 'mode=search' | while read -r LINE; do emit "$LINE"; done
    grep 'mode=spread' "$JOBS" | while read -r LINE; do emit "$LINE"; done
    grep -E 'mode=(plain|det)' "$JOBS" | while read -r LINE; do emit "$LINE"; done
  else
    for L in r1_l1 r1_l2 r1_l3 r1_l4 r1_l5 r1_l6 r2_l1 r2_l2 r2_l3 r2_l4 r2_l5 r2_l6 r3_l1 r3_l2 r3_l3 r3_l4 r3_l5 r3_l6 r4_l1 r4_l2 r4_l3 r4_l4 r4_l5 r4_l6 $CHANGED; do
      grep "level=$L " "$JOBS" | grep 'mode=search' | grep -v 'twist=1' | while read -r LINE; do emit "$LINE"; done
    done
  fi
fi

if [ "$PHASE" = "R" ] || [ "$PHASE" = "X" ]; then
  R="$OUT/r"
  rates() {  # DIR FIRST POOL RELAXED TIER [extra options] -> a rates job
    local T=""
    [ "$5" != "0" ] && T=" tier=$5"
    emit "SCRIPT=runs.gd mode=rates first=$2 count=50 pool=$3 relaxed=$4$T leaks=1 $6 out=$R/$1/rates_${3%%:*}_r$4_$2.json"
  }
  if [ "$PHASE" = "R" ]; then
    for FIRST in 1 51 101 151; do
      for T in 4 3 2 1 0; do rates "t$T" $FIRST base 0 $T; done
    done
    for FIRST in 1 51 101 151; do
      for T in 4 3 2; do emit "SCRIPT=runs.gd mode=rates first=$FIRST count=50 pool=minus:$NOCARDS relaxed=0 tier=$T leaks=1 out=$R/t${T}_nocards/rates_base_r0_$FIRST.json"; done
    done
    for FIRST in 1 51 101 151; do
      emit "SCRIPT=runs.gd mode=rates first=$FIRST count=50 pool=minus:$SC relaxed=0 tier=4 leaks=1 out=$R/t4_out_scarecrow/rates_base_r0_$FIRST.json"
      emit "SCRIPT=runs.gd mode=rates first=$FIRST count=50 pool=minus:$SF relaxed=0 tier=4 leaks=1 out=$R/t4_out_snowfort/rates_base_r0_$FIRST.json"
      emit "SCRIPT=runs.gd mode=rates first=$FIRST count=50 pool=minus:$ML relaxed=0 tier=4 leaks=1 out=$R/t4_out_mothlantern/rates_base_r0_$FIRST.json"
    done
    for FIRST in 1 51 101 151; do
      emit "SCRIPT=runs.gd mode=rates first=$FIRST count=50 pool=minus:$SF,$ML relaxed=0 tier=4 leaks=1 out=$R/t4_only_scarecrow/rates_base_r0_$FIRST.json"
      emit "SCRIPT=runs.gd mode=rates first=$FIRST count=50 pool=minus:$SC,$ML relaxed=0 tier=4 leaks=1 out=$R/t4_only_snowfort/rates_base_r0_$FIRST.json"
      emit "SCRIPT=runs.gd mode=rates first=$FIRST count=50 pool=minus:$SC,$SF relaxed=0 tier=4 leaks=1 out=$R/t4_only_mothlantern/rates_base_r0_$FIRST.json"
    done
    for FIRST in 1 51 101 151; do
      for T in 4 0; do rates "t$T" $FIRST base 1 $T; done
      for T in 4 0; do rates "t$T" $FIRST all 1 $T; done
      for T in 4 0; do rates "t$T" $FIRST all 0 $T; done
    done
    for T in 4 3 2 1 0; do
      TF=""; [ "$T" != "0" ] && TF=" tier=$T"
      emit "SCRIPT=runs.gd mode=det first=1 count=50$TF out=$R/t$T/det.json"
      emit "SCRIPT=runs.gd mode=det first=51 count=150 days=100 day_from=50$TF out=$R/t$T/det_more.json"
    done
  else
    for FIRST in 1 51 101 151; do
      for T in 3 2 1; do rates "t$T" $FIRST all 0 $T; done
    done
  fi
fi

if [ "$PHASE" = "D" ]; then
  for FROM in 0 50 100 150 200 250 300 350; do
    for T in 4 3 2 1 0; do
      TF=""; [ "$T" != "0" ] && TF=" tier=$T"
      emit "SCRIPT=runs.gd mode=daily from=$FROM count=50 extra=400$TF out=$OUT/r/t$T/daily_$FROM.json"
    done
  done
fi

if [ "$PHASE" = "RPOST" ]; then
  # Run seeds 1 to 50 that no named strategy won (Normal, base cards): 100 random strategies each (RULES 14.8).
  for T in 0 1 2 3 4; do
    DIR="$OUT/r/t$T"
    [ -f "$DIR/rates_base_r0_1.json" ] || continue
    LIST=$(jq -r '[.rows[] | select(.i <= 50 and .won)] | map(.i) | unique | join(",")' "$DIR/rates_base_r0_1.json" 2> /dev/null)
    MISS=""
    for I in $(seq 1 50); do
      case ",$LIST," in *",$I,"*) ;; *) MISS="$MISS,$I" ;; esac
    done
    MISS="${MISS#,}"
    TF=""; [ "$T" != "0" ] && TF=" tier=$T"
    [ -n "$MISS" ] && emit "SCRIPT=runs.gd mode=search list=$MISS n=100 pool=base relaxed=0$TF out=$DIR/search_base_r0_list.json"
  done
fi

if [ "$PHASE" = "POST" ]; then
  EV="${EVALS_SOLO:-6000}"; STOP="${STOP_DRY:-2500}"
  for D in a b; do
    SHIFT=100000; [ "$D" = "b" ] && SHIFT=300000
    # A lone search that stopped dry while its partner won something is played again in full.
    for FILE in "$OUT/$D"/*_solo_*_a.json; do
      [ -f "$FILE" ] || continue
      B_FILE="${FILE%_a.json}_b.json"
      [ -f "$B_FILE" ] || continue
      A_DRY=$(tr -d '[:space:]' < "$FILE" | grep -c '"evals":'"$STOP"',.*"wins":0[,}]')
      B_DRY=$(tr -d '[:space:]' < "$B_FILE" | grep -c '"evals":'"$STOP"',.*"wins":0[,}]')
      if [ "$A_DRY" != "$B_DRY" ]; then
        if [ "$A_DRY" = "1" ]; then DRY_FILE="$FILE"; else DRY_FILE="$B_FILE"; fi
        LEVEL=$(basename "$DRY_FILE" | sed 's/_solo_.*//')
        TOWER=$(basename "$DRY_FILE" | sed 's/.*_solo_\(.*\)_[ab].json/\1/')
        SEED=$(grep -o '"seed": [0-9]*' "$DRY_FILE" | head -1 | grep -o '[0-9]*')
        emit "mode=search level=$LEVEL seed=$SEED evals=$EV only=solo:$TOWER out=${DRY_FILE%.json}_full.json"
      fi
    done
    if [ "$D" = "a" ]; then
      for L in $ALL_LEVELS; do
        REGION=$(echo "$L" | sed 's/^r\([0-9]*\)_.*/\1/'); NUM=$(echo "$L" | sed 's/.*_l//')
        S=$((SHIFT + (REGION * 10 + NUM) * 100))
        emit "mode=det level=$L seed=$((750000 + S)) out=$OUT/a/${L}_det_again.json"
        if [ -f "$OUT/a/${L}_search_twist.json" ] && tr -d '[:space:]' < "$OUT/a/${L}_search_twist.json" | grep -q '"wins":0[,}]'; then
          emit "mode=search level=$L twist=1 seed=$((772000 + S)) evals=$EV only=any out=$OUT/a/${L}_search_twist_deep_a.json"
          emit "mode=search level=$L twist=1 seed=$((774000 + S)) evals=$EV only=any out=$OUT/a/${L}_search_twist_deep_b.json"
        fi
      done
    fi
  done
  # Three stars hunts (RULES 12.6): a first search of 3000 builds that found no three-star build, on a level whose star 3 is a tower or kinds
  # limit, is followed by up to two searches of 6000 builds with other seeds. Any level that found none gets them.
  for D in a b; do
    for FILE in "$OUT/$D"/*_search_any.json; do
      [ -f "$FILE" ] || continue
      L=$(basename "$FILE" | sed 's/_search_any.json//')
      N=$(jq -r '.three_star_found' "$FILE")
      if [ "$N" = "0" ]; then
        REGION=$(echo "$L" | sed 's/^r\([0-9]*\)_.*/\1/'); NUM=$(echo "$L" | sed 's/.*_l//')
        K=$((REGION * 10 + NUM))
        ONLY=$(jq -r '.only' "$FILE")
        emit "mode=search level=$L seed=$((940000 + 100 * K)) evals=6000 only=$ONLY out=$OUT/$D/hunt/${L}_search_any_h0.json"
        emit "mode=search level=$L seed=$((940000 + 100 * K + 1)) evals=6000 only=$ONLY out=$OUT/$D/hunt/${L}_search_any_h1.json"
      fi
    done
  done
fi

if [ "$PHASE" = "NB" ]; then
  # The Bramble Cottage watch item (RULES 5.10): an any-tower search of 3000 builds with the cottage left out (and the tower the level's star 3
  # bans, if any), on every level that offers the cottage, except the levels named in SKIP (those with a file of E5.5 or E6.2 that still stands).
  for L in $ALL_LEVELS; do
    case " $SKIP " in *" $L "*) continue ;; esac
    jq -e '.towers | index("bramble_cottage")' "data/levels/$L.json" > /dev/null 2>&1 || continue
    REGION=$(echo "$L" | sed 's/^r\([0-9]*\)_.*/\1/'); NUM=$(echo "$L" | sed 's/.*_l//')
    K=$((REGION * 10 + NUM))
    ONLY=$(jq -r '(.star3.tower // "") as $ban | .towers | map(select(. != "bramble_cottage" and . != $ban)) | join(",")' "data/levels/$L.json")
    emit "mode=search level=$L seed=$((960000 + 100 * K)) evals=3000 only=$ONLY out=$OUT/a/nobramble/${L}_search_no_bramble.json"
  done
fi

if [ -n "$DRY" ]; then
  cat "$TMP"
  rm -f "$TMP"
  exit 0
fi
cat "$TMP" >> "$Q"
echo "$PHASE: $(wc -l < "$TMP") jobs appended to $Q"
rm -f "$TMP"
