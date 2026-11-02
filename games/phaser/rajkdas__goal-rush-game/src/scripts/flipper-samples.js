// Sample the left flipper every 120ms for ~1.5s to see if it is frozen,
// oscillating, or slowly returning.
(() => {
  const g = window.__goalrushGame;
  const s = g.scene.getScene('Play');
  const f = s.children.list.filter((o) => o.frame && o.frame.name === 'flipper');
  const samples = [];
  const take = () => {
    const L = f[0];
    const b = L.body;
    samples.push({
      x: Math.round(L.x),
      y: Math.round(L.y),
      a: Math.round(L.angle),
      av: +b.angularVelocity.toFixed(3),
      vx: +b.velocity.x.toFixed(2),
      vy: +b.velocity.y.toFixed(2),
    });
  };
  take();
  const iv = setInterval(take, 120);
  setTimeout(() => {
    clearInterval(iv);
    const div = document.createElement('div');
    div.id = 'flipper-samples';
    div.textContent = JSON.stringify(samples);
    document.body.appendChild(div);
  }, 1500);
  return 'sampling';
})()
