import { Bodies } from 'matter-js';
import { SLINGSHOTS } from '../src/game/config/table.config';

for (const s of SLINGSHOTS) {
  const cx = s.points.reduce((a, p) => a + p.x, 0) / 3;
  const cy = s.points.reduce((a, p) => a + p.y, 0) / 3;
  const verts = s.points.map((p) => ({ x: p.x - cx, y: p.y - cy }));
  const body = Bodies.fromVertices(cx, cy, verts, { isStatic: true });
  console.log(`${s.label}: requested center=(${cx.toFixed(1)}, ${cy.toFixed(1)})`);
  console.log(`  actual body pos=(${body.position.x.toFixed(1)}, ${body.position.y.toFixed(1)})`);
  console.log(
    `  bounds: x ${body.bounds.min.x.toFixed(1)}..${body.bounds.max.x.toFixed(1)}, y ${body.bounds.min.y.toFixed(1)}..${body.bounds.max.y.toFixed(1)}`
  );
  console.log(
    `  expected: x ${Math.min(...s.points.map((p) => p.x))}..${Math.max(...s.points.map((p) => p.x))}, y ${Math.min(...s.points.map((p) => p.y))}..${Math.max(...s.points.map((p) => p.y))}`
  );
}
