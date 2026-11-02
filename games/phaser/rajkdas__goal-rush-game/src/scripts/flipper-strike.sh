#!/bin/bash
# GOAL RUSH — flipper strike test: plunge, wait for the ball to reach the
# flipper zone, flip, and sample the ball's velocity response.
LOG=/tmp/flipper-strike.log
: > "$LOG"
agent-browser eval "window.__goalrush.plunge(1.0)" >> "$LOG" 2>&1

# Wait for the ball to descend into the flipper zone (y > 700, in play).
for i in $(seq 1 40); do
  P=$(agent-browser eval "(() => { const p = window.__goalrush.ballPos(); return p ? Math.round(p.y) : -1; })()" 2>/dev/null | tr -d '"')
  echo "[$i] ballY=$P" >> "$LOG"
  if [ "$P" -ge 700 ] 2>/dev/null && [ "$P" -le 900 ]; then
    echo "  -> flipper zone reached" >> "$LOG"
    break
  fi
  sleep 1
done

# Press BOTH flippers and sample the ball velocity right after.
agent-browser eval "(() => { const g = window.__goalrush; g.flip('left', true); g.flip('right', true); return 'flipping'; })()" >> "$LOG" 2>&1
for i in 1 2 3 4; do
  sleep 0.7
  agent-browser eval "(() => { const d = window.__goalrush.debug(); return JSON.stringify({ y: Math.round(d.imgY), vx: Math.round(d.ballVx*10)/10, vy: Math.round(d.ballVy*10)/10 }); })()" >> "$LOG" 2>&1
done
agent-browser eval "(() => { const g = window.__goalrush; g.flip('left', false); g.flip('right', false); return 'released'; })()" >> "$LOG" 2>&1
sleep 2
agent-browser eval "(() => { const g = window.__goalrush; const d = g.debug(); return JSON.stringify({ flippers: g.dumpBodies().filter(b => String(b.label).startsWith('flipper')).map(f => f.angle), state: g.state() }); })()" >> "$LOG" 2>&1
cat "$LOG"
