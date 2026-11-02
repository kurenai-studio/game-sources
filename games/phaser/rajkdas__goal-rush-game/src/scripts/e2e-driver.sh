#!/bin/bash
# GOAL RUSH — background E2E driver (headless, canvas renderer).
# Plays balls until game over, keeps spinning the reels, then stops.
LOG=/tmp/goalrush-e2e.log
: > "$LOG"
for i in $(seq 1 240); do
  PHASE=$(agent-browser eval "window.__goalrush ? window.__goalrush.phase() : 'nogame'" 2>/dev/null | tr -d '"')
  if [ "$PHASE" = "nogame" ] || [ -z "$PHASE" ]; then
    echo "[$i] not ready" >> "$LOG"; sleep 2; continue
  fi
  if [ "$PHASE" = "title" ]; then
    agent-browser eval "window.__goalrush.start(); 'started'" >> "$LOG" 2>&1
    sleep 1; continue
  fi
  if [ "$PHASE" = "over" ]; then
    echo "[$i] GAME OVER" >> "$LOG"
    agent-browser eval "JSON.stringify(window.__goalrush.state())" >> "$LOG" 2>&1
    break
  fi
  # playing: plunge when in lane, flip occasionally, spin when reels idle
  RES=$(agent-browser eval "(() => { const g = window.__goalrush; const r = {}; const p = g.ballPos(); if (p && p.x > 490 && p.y > 820) r.plunged = g.plunge(1.0); r.spun = g.spin('golden'); g.flip(Math.random() < 0.5 ? 'left' : 'right', true); g.flip('left', false); g.flip('right', false); return JSON.stringify(r); })()" 2>/dev/null)
  STATE=$(agent-browser eval "JSON.stringify(window.__goalrush.state())" 2>/dev/null)
  echo "[$i] $RES $STATE" >> "$LOG"
  sleep 4
done
echo "DONE" >> "$LOG"
