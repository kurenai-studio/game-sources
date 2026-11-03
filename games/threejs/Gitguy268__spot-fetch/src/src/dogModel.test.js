import test from 'node:test';
import assert from 'node:assert/strict';
import * as THREE from 'three';
import { createDog } from './dogModel.js';
import { SPOT } from './dogs.js';

// Laat de hond rechtuit lopen en meet per poot hoeveel hij over de grond schuift terwijl hij plat staat,
// en welk deel van de tijd hij aan de grond is. Dat laatste hoort bij de gang te passen: is het minder,
// dan zweeft de poot tijdens de stand omdat het been er niet bij kan.
function loop(v, sec = 4) {
  const model = createDog(SPOT, 2);
  const d = { pos: { x: 0, z: 0 }, heading: 0, speed: v, pose: 'sta', swim: false, look: null, headDown: 0, sniff: false, pant: 0, wag: 0.5, alert: 0, hasBall: false };
  const paws = [];
  model.group.traverse((o) => { if (o.rotation.order === 'ZXY') paws.push(o.children[1].children[1].children[1]); });
  const p = new THREE.Vector3(), prev = paws.map(() => null);
  let ergste = 0, grond = 0, n = 0, laag = Infinity, hoog = 0;
  for (let i = 0; i < sec * 120; i++) {
    d.pos.z += v / 120;
    model.update(1 / 120, d);
    model.group.updateMatrixWorld(true);
    paws.forEach((paw, k) => {
      paw.getWorldPosition(p);
      laag = Math.min(laag, p.y); hoog = Math.max(hoog, p.y);
      const staat = p.y < 0.0235; // plat op de grond; rusthoogte van het pootmidden is 0,022
      if (i > 120) { n++; grond += p.y < 0.03; }
      // verschuiving ten opzichte van waar de poot neerkwam
      if (i > 120 && staat && prev[k]) ergste = Math.max(ergste, Math.hypot(p.x - prev[k].x, p.z - prev[k].z));
      if (!staat) prev[k] = null;
      else prev[k] ||= p.clone();
    });
  }
  return { ergste, grond: grond / n, laag, hoog };
}

// [gang, snelheid, deel van de pas dat een poot hoort te staan]
for (const [naam, v, stand] of [['stap', 1.2, 0.6], ['draf', 2.5, 0.45], ['galop', 5, 0.24], ['sprint', 7.5, 0.24]])
  test(`${naam} (${v} m/s): poten schuiven niet en staan de hele standfase aan de grond`, () => {
    const r = loop(v);
    assert.ok(r.grond > stand - 0.06, `poten zweven: ${r.grond.toFixed(2)} van de tijd aan de grond, verwacht ${stand}`);
    assert.ok(r.hoog > 0.04, 'poten worden niet opgetild');
    assert.ok(r.ergste < 0.01, `poot schuift ${(r.ergste * 100).toFixed(1)} cm tijdens de stand`);
  });
