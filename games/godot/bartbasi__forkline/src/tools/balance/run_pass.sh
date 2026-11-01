#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# The job list of one balance pass (docs/ARCHITECTURE.md 13, RULES 12.6 as revised by G2): every check for the
# levels given, the Twists included. Run it from the repo root (a clean checkout of the commit measured):
#     bash tools/balance/run_pass.sh 2026-10-26 4                    # every level in campaign.json
#     bash tools/balance/run_pass.sh 2026-10-26 4 r2_l1 r2_l2        # only these levels
# Arguments: the date folder name under docs/balance/raw/, how many jobs run at once (default 4;
# the machine is shared, so keep it at 3 or fewer), then the levels (default: all of campaign.json).
# Environment:
#   EVALS        builds per any-tower search (default 3000)
#   EVALS_SOLO   builds per lone attacker search (default 6000, RULES 12.6 as revised by G2)
#   STOP_DRY     a lone attacker search stops when this many builds are tried and none has won (default 2500)
#   SEED_SHIFT   added to every seed (default 0, which gives the seeds of the 2026-10-24 pass; the 2026-10-25 pass used 100000)
#   SKIP_SOLO=1  no lone attacker searches (a re-run of levels whose lone searches stand)
#   DRY=1        only write jobs.txt
#   FIXTURE=1    (B6) play the fixture levels r5_fx1 to r8_fx2 on the test catalog (tools/balance/fixtures.gd) instead of campaign.json
#                and add fixture=1 to every job. Regions 5 to 8 need no flag once their data is in data/.
# Several copies of this script can work on one folder: a job is taken by making a lock folder, so no job runs twice.
# If a copy is stopped, remove its lock folders (docs/balance/raw/DATE/.lock_*) before starting it again.
#
# Which lone attackers get searches is decided by `mode=need` (RULES 12.6): a tower that cannot hit flyers needs no
# search on a level whose flyers cost 6 lives or more, a tower that cannot hit walkers likewise for walkers, and the tower
# a level's star 3 bans needs none (it can never earn star 3). The same file gives the towers of the "All three stars"
# search (`all_three_only`): every tower, or on a level with a ban only the towers the ban leaves.
#
# Per level L, with key K = 10 * region + level number (11 to 46) and A the attacking tower's
# number (1 Sling Post, 2 Catapult, 3 Longbow, 4 Firework, 5 Bramble Cottage, 6 Snow Fort, 7 Moth Lantern), every seed is SEED_SHIFT
# plus a base plus 100 * K + A (K runs from 11 to 86 since regions 5 to 8; the Scarecrow is a support tower and has no search):
#   search any tower         base 720000   all three stars (the towers a ban leaves, if the star 3 bans one), tower use, level length
#   search one attacker      base 730000 and 760000, two seeds   no super tower: that attacker plus the
#                            level's Bells and Bakeries (only=solo:...), for each attacking tower that needs it
#   spread                   base 710000   random play, 250 per style
#   plain                    no seed       the plain mixed recipe of RULES 12.6 (compare_old=1 on region 1)
#   det                      base 750000, and again in a new process   same inputs, same result
# And for the level's Twist (twist=1):
#   plain, search any (1500 builds, base 770000), det (base 780000). run_pass_post.sh adds two searches of 6000 builds
#   (bases 772000 and 774000) for a Twist whose 1500 build search won nothing (RULES 12.6).
# Then run_pass_post.sh (the dry pairs again, the determinism jobs again, the timing runs). Only processes this
# script starts are used. Nothing is ended by name. A job whose output file exists is skipped.

DATE="${1:-2026-10-26}"
JOBS="${2:-4}"
shift $(( $# < 2 ? $# : 2 ))
LEVELS="$*"
FX=""
if [ "$FIXTURE" = "1" ]; then FX=" fixture=1"; fi
if [ -z "$LEVELS" ] && [ "$FIXTURE" = "1" ]; then
  LEVELS="r5_fx1 r6_fx1 r7_fx1 r8_fx1 r8_fx2"
fi
if [ -z "$LEVELS" ]; then
  LEVELS=$(grep -o '"r[0-9]*_l[0-9]*"' data/levels/campaign.json | tr -d '"')
fi
EVALS="${EVALS:-3000}"
EVALS_SOLO="${EVALS_SOLO:-6000}"
STOP_DRY="${STOP_DRY:-2500}"
SHIFT="${SEED_SHIFT:-0}"
OUT="docs/balance/raw/$DATE"
mkdir -p "$OUT"
LIST="$OUT/jobs.txt"
GODOT="godot --headless --path . --script res://tools/balance/run.gd --"

# Phase 0: which lone attackers each level needs (instant, no plays).
for LEVEL in $LEVELS; do
  if [ ! -f "$OUT/${LEVEL}_need.json" ] && [ -z "$DRY" ]; then
    $GODOT mode=need level=$LEVEL$FX out="$OUT/${LEVEL}_need.json" > /dev/null 2>> "$OUT/errors.txt"
  fi
done

: > "$LIST.new"
# The slow lone attacker searches go first, then the rest.
for LEVEL in $LEVELS; do
  REGION=$(echo "$LEVEL" | sed 's/^r\([0-9]*\)_.*/\1/')
  NUM=$(echo "$LEVEL" | sed 's/.*_l//; s/.*_fx//')
  S=$((SHIFT + (REGION * 10 + NUM) * 100))
  NEEDED=$(tr -d '[:space:]' < "$OUT/${LEVEL}_need.json" 2>/dev/null | grep -o '"search_needed":\[[^]]*\]')
  A=0
  for TOWER in sling_post pumpkin_catapult longbow_loft firework_tower bramble_cottage snow_fort moth_lantern; do
    A=$((A + 1))
    if [ -z "$SKIP_SOLO" ] && echo "$NEEDED" | grep -q "\"$TOWER\""; then
      echo "mode=search level=$LEVEL seed=$((730000 + S + A)) evals=$EVALS_SOLO stop_dry=$STOP_DRY only=solo:$TOWER$FX out=$OUT/${LEVEL}_solo_${TOWER}_a.json" >> "$LIST.new"
      echo "mode=search level=$LEVEL seed=$((760000 + S + A)) evals=$EVALS_SOLO stop_dry=$STOP_DRY only=solo:$TOWER$FX out=$OUT/${LEVEL}_solo_${TOWER}_b.json" >> "$LIST.new"
    fi
  done
done
for LEVEL in $LEVELS; do
  REGION=$(echo "$LEVEL" | sed 's/^r\([0-9]*\)_.*/\1/')
  NUM=$(echo "$LEVEL" | sed 's/.*_l//; s/.*_fx//')
  S=$((SHIFT + (REGION * 10 + NUM) * 100))
  OPT=""
  if [ "$REGION" = "1" ]; then OPT="compare_old=1"; fi
  # "All three stars": any tower, or on a level whose star 3 bans a tower, only the towers the ban leaves (RULES 12.6, G4).
  ALL3=$(tr -d '[:space:]' < "$OUT/${LEVEL}_need.json" 2>/dev/null | grep -o '"all_three_only":"[^"]*"' | sed 's/.*:"//; s/"$//')
  if [ -z "$ALL3" ]; then ALL3="any"; fi
  echo "mode=search level=$LEVEL seed=$((720000 + S)) evals=$EVALS only=$ALL3$FX out=$OUT/${LEVEL}_search_any.json" >> "$LIST.new"
  echo "mode=spread level=$LEVEL seed=$((710000 + S)) n=250$FX out=$OUT/${LEVEL}_spread.json" >> "$LIST.new"
  echo "mode=plain level=$LEVEL $OPT$FX out=$OUT/${LEVEL}_plain.json" >> "$LIST.new"
  echo "mode=det level=$LEVEL seed=$((750000 + S))$FX out=$OUT/${LEVEL}_det.json" >> "$LIST.new"
  if grep -q '"twist"' "data/levels/$LEVEL.json" 2> /dev/null; then
    echo "mode=plain level=$LEVEL twist=1$FX out=$OUT/${LEVEL}_plain_twist.json" >> "$LIST.new"
    echo "mode=search level=$LEVEL twist=1 seed=$((770000 + S)) evals=1500 only=any$FX out=$OUT/${LEVEL}_search_twist.json" >> "$LIST.new"
    echo "mode=det level=$LEVEL twist=1 seed=$((780000 + S))$FX out=$OUT/${LEVEL}_det_twist.json" >> "$LIST.new"
  fi
done
mv "$LIST.new" "$LIST"
if [ -n "$DRY" ]; then
  echo "wrote $(wc -l < "$LIST") jobs to $LIST"
  exit 0
fi
run_one() {
  OUTFILE=$(echo "$1" | sed 's/.*out=//')
  if [ -f "$OUTFILE" ]; then return; fi
  if ! mkdir "$2/.lock_$(basename "$OUTFILE")" 2> /dev/null; then return; fi
  timeout 7200 godot --headless --path . --script res://tools/balance/run.gd -- $1 > /dev/null 2>> "$2/errors.txt"
}
export -f run_one
cat "$LIST" | xargs -P "$JOBS" -I{} bash -c 'run_one "{}" '"$OUT"
echo "jobs done: $(ls "$OUT" | wc -l) files in $OUT. Next: bash tools/balance/run_pass_post.sh $DATE $JOBS"
