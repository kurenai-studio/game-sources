#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# Builds the folder `final` of the B7 report (docs/balance/final-2026-10-30.md) from the raw folders, so `summary.gd pass=1 dir=.../final`
# prints the campaign tables of all 48 levels. Run it from the repo root. Arguments: the B7 raw folder (default
# docs/balance/raw/2026-10-30-b7), then the raw folder of the E5.5 pass (regions 5 and 8), of the E6.2 pass (regions 6 and 7) and of the B3 pass.
#
# Where each level's files come from (the report's section 1 gives the proof for each reuse):
#   cheap jobs (plain, random play, Twist, determinism), all 48 levels: a/ (this pass, SEED_SHIFT=100000)
#   long searches (any tower, lone attackers, hunts):
#       regions 1 to 4: b/ (this pass, new seeds, SEED_SHIFT=300000)
#       5-6, 6-4, 7-4, 8-6 (level files changed since the last pass): a/ (this pass, SEED_SHIFT=100000)
#       5-1 to 5-5 and 8-1 to 8-5: the E5.5 folder (f31b761)
#       6-1 to 6-3, 6-5, 6-6, 7-1 to 7-3, 7-5, 7-6: the E6.2 folder (3fb2285 with the E5.3 patch)
# The copy keeps the file names. reused.txt lists every copied file and its source folder.

B7="${1:-docs/balance/raw/2026-10-30-b7}"
E58="${2:-docs/balance/raw/2026-10-30-e58}"
E67="${3:-docs/balance/raw/2026-10-29-e67}"
B3="${4:-docs/balance/raw/2026-10-25-b3}"
OUT="$B7/final"
rm -rf "$OUT"
mkdir -p "$OUT"
: > "$OUT/reused.txt"
copy() {  # SOURCE_FOLDER LEVEL PATTERN-SUFFIX...
  local SRC="$1" L="$2"
  shift 2
  for SUFFIX in "$@"; do
    for F in "$SRC/${L}_${SUFFIX}"*.json; do
      [ -f "$F" ] || continue
      cp "$F" "$OUT/$(basename "$F")"
      echo "$(basename "$F") <- $SRC" >> "$OUT/reused.txt"
    done
  done
}
for F in "$B7"/a/*.json; do
  case "$(basename "$F")" in
    *_plain*|*_spread*|*_det*|*_need*|*_search_twist*|*_bench*) cp "$F" "$OUT/$(basename "$F")" ;;
  esac
done
for L in $(grep -o '"r[0-9]*_l[0-9]*"' data/levels/campaign.json | tr -d '"'); do
  case "$L" in
    r1_*|r2_*|r3_*|r4_*) SRC="$B7/b" ;;
    r5_l6|r6_l4|r7_l4|r8_l6) SRC="$B7/a" ;;
    r5_*|r8_*) SRC="$E58" ;;
    r6_*|r7_*) SRC="$E67" ;;
  esac
  copy "$SRC" "$L" search_any solo_
  # Regions 1 to 4: a lone search that this pass did not finish is taken from B3 (the report says which, and why it stands).
  case "$L" in
    r1_*|r2_*|r3_*|r4_*)
      for TOWER in $(jq -r ".search_needed[]" "$B7/a/${L}_need.json"); do
        for AB in a b; do
          if [ ! -f "$OUT/${L}_solo_${TOWER}_$AB.json" ] && [ -f "$B3/${L}_solo_${TOWER}_$AB.json" ]; then
            cp "$B3/${L}_solo_${TOWER}_$AB.json" "$OUT/${L}_solo_${TOWER}_$AB.json"
            echo "${L}_solo_${TOWER}_$AB.json <- $B3 (B3, not played again)" >> "$OUT/reused.txt"
          fi
        done
      done ;;
  esac
  # The hunts (RULES 12.6): searches of 6000 builds after a first search that found no three-star build.
  for F in "$SRC"/hunt/${L}_search_any_h*.json; do
    [ -f "$F" ] || continue
    cp "$F" "$OUT/$(basename "$F")"
    echo "$(basename "$F") <- $SRC/hunt" >> "$OUT/reused.txt"
  done
done
echo "final: $(ls "$OUT" | wc -l) files in $OUT"
