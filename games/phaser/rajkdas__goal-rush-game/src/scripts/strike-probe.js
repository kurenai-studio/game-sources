// GOAL RUSH — in-page flipper strike probe.
// Plunges, watches the ball at 100 ms cadence, flips BOTH bats the moment
// the ball enters the flipper zone, and reports the strongest ball speed
// seen during the 1.2 s after the flip (the strike impulse).
(() => {
  const g = window.__goalrush;
  return new Promise((resolve) => {
    const t0 = performance.now();
    let flipped = false;
    let flipAt = 0;
    let maxSpeed = 0;
    let maxSample = null;
    let samples = [];
    g.plunge(1.0);

    const tick = () => {
      const p = g.ballPos();
      const d = g.debug();
      const speed = Math.hypot(d.ballVx, d.ballVy);
      samples.push(Math.round(d.imgY));
      if (flipped && performance.now() - flipAt < 1400) {
        if (speed > maxSpeed) {
          maxSpeed = speed;
          maxSample = { y: Math.round(d.imgY), vx: Math.round(d.ballVx * 10) / 10, vy: Math.round(d.ballVy * 10) / 10 };
        }
      }
      if (!flipped && p && p.y > 690 && p.y < 905 && p.x > 60 && p.x < 480) {
        g.flip('left', true);
        g.flip('right', true);
        flipped = true;
        flipAt = performance.now();
      }
      if (flipped && performance.now() - flipAt > 1250) {
        g.flip('left', false);
        g.flip('right', false);
      }
      if (performance.now() - t0 > 16000 || (flipped && performance.now() - flipAt > 6000)) {
        resolve(JSON.stringify({
          flipped,
          maxSpeed: Math.round(maxSpeed * 10) / 10,
          maxSample,
          ballTrack: samples.filter((_, i) => i % 3 === 0).slice(-14),
          state: g.state(),
        }));
        return;
      }
      setTimeout(tick, 100);
    };
    tick();
  });
})()
