// Dev-only nav overlay (toggle with F3). The engine only constructs this when
// process.env.NODE_ENV !== "production", so it is dead code in a production build.
import * as THREE from "three";
import type { NavGrid, PathAgent } from "./nav";

const LAYER_COLORS = [0x3fbf6f, 0x4aa3ff, 0xffb347, 0xd96bff, 0xff6b6b, 0x7be0d6, 0xe0e06b];

export class NavDebug {
  readonly group = new THREE.Group();
  private pathLines: THREE.Line[] = [];

  constructor(private nav: NavGrid) {
    this.group.visible = false;
    this.group.renderOrder = 998;
    // walkable cells as points, one colour per layer
    for (let l = 0; l < nav.layers; l++) {
      const pts: number[] = [];
      for (let iz = 0; iz < nav.h; iz += 1)
        for (let ix = 0; ix < nav.w; ix += 1) if (nav.isWalkable(l, ix, iz)) pts.push(nav.cx(ix), nav.heights[l] + 0.08, nav.cz(iz));
      const geo = new THREE.BufferGeometry();
      geo.setAttribute("position", new THREE.Float32BufferAttribute(pts, 3));
      const m = new THREE.PointsMaterial({ color: LAYER_COLORS[l % LAYER_COLORS.length], size: 0.12, depthTest: false, transparent: true, opacity: 0.8 });
      const points = new THREE.Points(geo, m);
      points.renderOrder = 998;
      this.group.add(points);
    }
    // climb links
    const lp: number[] = [];
    for (const l of nav.allLinks) {
      if (!l.up) continue;
      for (let i = 1; i < l.keys.length; i++) lp.push(l.keys[i - 1].x, l.keys[i - 1].y + 0.1, l.keys[i - 1].z, l.keys[i].x, l.keys[i].y + 0.1, l.keys[i].z);
    }
    const lg = new THREE.BufferGeometry();
    lg.setAttribute("position", new THREE.Float32BufferAttribute(lp, 3));
    const links = new THREE.LineSegments(lg, new THREE.LineBasicMaterial({ color: 0xff2fd0, depthTest: false }));
    links.renderOrder = 999;
    this.group.add(links);
  }

  get visible() {
    return this.group.visible;
  }
  toggle() {
    this.group.visible = !this.group.visible;
  }

  /** Redraw guard paths (cheap: a handful of short polylines). */
  updatePaths(agents: { agent: PathAgent; x: number; y: number; z: number }[]) {
    if (!this.group.visible) return;
    for (const l of this.pathLines) {
      this.group.remove(l);
      l.geometry.dispose();
    }
    this.pathLines = [];
    for (const g of agents) {
      const path = g.agent.path;
      if (!path) continue;
      const v: THREE.Vector3[] = [new THREE.Vector3(g.x, g.y + 0.3, g.z)];
      for (let i = g.agent.idx; i < path.points.length; i++) {
        const p = path.points[i];
        v.push(new THREE.Vector3(p.x, p.y + 0.3, p.z));
      }
      if (v.length < 2) continue;
      const line = new THREE.Line(new THREE.BufferGeometry().setFromPoints(v), new THREE.LineBasicMaterial({ color: path.found ? 0xffee33 : 0xff4444, depthTest: false }));
      line.renderOrder = 1000;
      this.group.add(line);
      this.pathLines.push(line);
    }
  }
}
