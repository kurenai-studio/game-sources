#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# Plays a job queue that grows while it runs (B7). Run it from the repo root of a clean copy, after `godot --headless --path . --import`:
#     bash tools/balance/run_queue.sh QUEUEFILE 8
# Each line of the queue is a job as in run_list.sh (`SCRIPT=runs.gd mode=... out=PATH`, or run.gd arguments with no SCRIPT=). Lines can be
# appended to the file at any time. A job whose output file exists is skipped, and a job is taken by making a lock folder beside its output
# file, so a job never runs twice. The queue never ends by itself: it reads until its sentinel (a `sleep` this script starts; its PID is in
# QUEUEFILE.sentinel) is ended. End it by that PID when the last job has been added (`kill $(cat QUEUEFILE.sentinel)`); the jobs that already
# run finish. Errors go to errors.txt beside the first output. The time limit is 4 hours a job. Only processes this script starts are ended.
#
# The second argument is a cap on the Godot processes on the whole machine, not a count of workers: before a job starts, its worker waits until
# fewer than that many `Godot_v` processes run (other jobs of mine, started before this queue, count too), and only one worker at a time starts
# a process, so the cap holds exactly.

QUEUE="$1"
CAP="${2:-8}"
LOCKDIR="$(dirname "$QUEUE")/.slot_lock"
export CAP LOCKDIR
run_one() {
  LINE="$1"
  case "$LINE" in
    SCRIPT=*) SCRIPT_NAME=$(echo "$LINE" | sed 's/^SCRIPT=\([^ ]*\) .*/\1/'); ARGS=$(echo "$LINE" | sed 's/^SCRIPT=[^ ]* //') ;;
    *) SCRIPT_NAME=run.gd; ARGS="$LINE" ;;
  esac
  OUTFILE=$(echo "$ARGS" | sed 's/ save=.*//; s/.*out=//')
  DIR=$(dirname "$OUTFILE")
  mkdir -p "$DIR"
  if [ -f "$OUTFILE" ]; then return; fi
  if ! mkdir "$DIR/.lock_$(basename "$OUTFILE")" 2> /dev/null; then return; fi
  # One worker at a time checks the cap and starts its process, then waits until that process shows before letting the next worker look.
  while ! mkdir "$LOCKDIR" 2> /dev/null; do sleep 1; done
  while [ "$(tasklist 2> /dev/null | grep -c 'Godot_v')" -ge "$CAP" ]; do sleep 10; done
  BEFORE=$(tasklist 2> /dev/null | grep -c 'Godot_v')
  timeout 14400 godot --headless --path . --script "res://tools/balance/$SCRIPT_NAME" -- $ARGS > /dev/null 2>> "$DIR/errors.txt" &
  JOB=$!
  for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    sleep 1
    [ "$(tasklist 2> /dev/null | grep -c 'Godot_v')" -gt "$BEFORE" ] && break
  done
  rmdir "$LOCKDIR"
  wait "$JOB"
}
export -f run_one
rmdir "$LOCKDIR" 2> /dev/null
touch "$QUEUE"
sleep 864000 &
SENTINEL=$!
echo "$SENTINEL" > "$QUEUE.sentinel"
tail -n +1 -f --pid="$SENTINEL" "$QUEUE" | grep --line-buffered -v '^#' | grep --line-buffered -v '^$' | xargs -P "$((CAP + 1))" -d '\n' -I{} bash -c 'run_one "{}"'
echo "queue done: $QUEUE"
