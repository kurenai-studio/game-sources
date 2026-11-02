#!/bin/bash
# GOAL RUSH — spin lifecycle tracer: polls the test bridge ~2x/sec.
LOG=/tmp/spin-trace.log
: > "$LOG"
for i in $(seq 1 60); do
  agent-browser eval "(() => { const g = window.__goalrush; if (!g) return 'nogame'; const d = g.debug(); const b = g.ballPos(); const o = g.slotOutcome(); return JSON.stringify({ t: $i, slot: d.slotState, busy: d.slotBusy, ball: b ? [Math.round(b.x), Math.round(b.y)] : null, win: o ? o.baseWin : null, st: g.state() }); })()" >> "$LOG" 2>&1
  sleep 0.5
done
echo "TRACE_DONE" >> "$LOG"
