// Dump flipper image vs Matter body state, twice, 1s apart.
(() => {
  const game = window.__goalrushGame;
  const scene = game.scene.getScene('Play');
  const f = scene.children.list.find((o) => o.frame && o.frame.name === 'flipper');
  const dump = (tag) => {
    const b = f.body;
    return JSON.stringify({
      tag,
      img: { x: Math.round(f.x), y: Math.round(f.y), ang: Math.round(f.angle) },
      body: b
        ? {
            x: Math.round(b.position.x),
            y: Math.round(b.position.y),
            vx: +b.velocity.x.toFixed(2),
            vy: +b.velocity.y.toFixed(2),
            av: +b.angularVelocity.toFixed(4),
            ang: +b.angle.toFixed(3),
            static: b.isStatic,
            ignoreGravity: b.ignoreGravity,
          }
        : null,
    });
  };
  const out = [dump('t0')];
  setTimeout(() => {
    out.push(dump('t1'));
    console.log('FLIPPER_DUMP ' + out.join(' | '));
    const div = document.createElement('div');
    div.id = 'flipper-dump-result';
    div.textContent = out.join(' | ');
    document.body.appendChild(div);
  }, 1000);
  return 'scheduled';
})()
