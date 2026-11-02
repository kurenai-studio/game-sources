// Press the left flipper, release, and sample its angle every 60ms to trace
// the return trajectory (should reach 30 degrees within ~100ms).
(() => {
  const g = window.__goalrushGame;
  const s = g.scene.getScene('Play');
  const f = s.children.list.filter((o) => o.frame && o.frame.name === 'flipper');
  const samples = [];
  window.__goalrush.flip('left', true);
  setTimeout(() => {
    window.__goalrush.flip('left', false);
    const t0 = performance.now();
    const iv = setInterval(() => {
      const L = f[0];
      samples.push({
        t: Math.round(performance.now() - t0),
        a: Math.round(L.angle),
        x: Math.round(L.x),
        y: Math.round(L.y),
      });
      if (samples.length >= 12) {
        clearInterval(iv);
        const div = document.createElement('div');
        div.id = 'return-trace';
        div.textContent = JSON.stringify(samples);
        document.body.appendChild(div);
      }
    }, 60);
  }, 250);
  return 'tracing';
})()
