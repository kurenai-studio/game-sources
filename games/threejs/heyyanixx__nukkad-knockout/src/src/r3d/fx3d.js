import * as THREE from 'three';
import { toX, toY, dotTex, starTex, toon, canvasTex, OUTLINE } from './common.js';

const tmpM = new THREE.Matrix4(), tmpQ = new THREE.Quaternion(), tmpS = new THREE.Vector3(), tmpP = new THREE.Vector3(), tmpC = new THREE.Color(), rollQ = new THREE.Quaternion(), Z = new THREE.Vector3(0, 0, 1);
const hash = (n) => { const s = Math.sin(n * 12.9898) * 43758.5453; return s - Math.floor(s); };

// Billboarded instanced particles. Mirrors the sim's 2D particles into 3D and adds 3D-only bursts.
class Particles {
  constructor(scene, max, additive) {
    this.max = max;
    const mat = additive
      ? new THREE.MeshBasicMaterial({ map: dotTex(), transparent: true, blending: THREE.AdditiveBlending, depthWrite: false })
      : new THREE.MeshBasicMaterial({ transparent: true, depthWrite: false, side: THREE.DoubleSide });
    this.mesh = new THREE.InstancedMesh(new THREE.PlaneGeometry(1, 1), mat, max);
    this.mesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    this.mesh.setColorAt(0, new THREE.Color());
    this.mesh.frustumCulled = false; this.mesh.renderOrder = 5;
    scene.add(this.mesh); this.n = 0;
  }
  begin() { this.n = 0; }
  push(x, y, z, size, color, fade = 1, roll = 0, camQ) {
    if (this.n >= this.max) return;
    tmpP.set(x, y, z); tmpS.set(size, size, size);
    if (roll) { rollQ.setFromAxisAngle(Z, roll); tmpQ.copy(camQ).multiply(rollQ); } else tmpQ.copy(camQ);
    tmpM.compose(tmpP, tmpQ, tmpS);
    this.mesh.setMatrixAt(this.n, tmpM);
    tmpC.set(color).multiplyScalar(fade);
    this.mesh.setColorAt(this.n, tmpC);
    this.n++;
  }
  end() { this.mesh.count = this.n; this.mesh.instanceMatrix.needsUpdate = true; if (this.mesh.instanceColor) this.mesh.instanceColor.needsUpdate = true; }
}

// ribbon trail behind a moving point
class Trail {
  constructor(scene, color, width = 0.22, n = 14) {
    this.n = n; this.pts = []; this.width = width;
    const geo = new THREE.BufferGeometry();
    this.pos = new Float32Array(n * 2 * 3); this.col = new Float32Array(n * 2 * 3);
    geo.setAttribute('position', new THREE.BufferAttribute(this.pos, 3)); geo.setAttribute('color', new THREE.BufferAttribute(this.col, 3));
    const idx = []; for (let i = 0; i < n - 1; i++) { const a = i * 2; idx.push(a, a + 1, a + 2, a + 1, a + 3, a + 2); }
    geo.setIndex(idx);
    this.mesh = new THREE.Mesh(geo, new THREE.MeshBasicMaterial({ vertexColors: true, transparent: true, blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide }));
    this.mesh.frustumCulled = false; this.mesh.renderOrder = 6;
    this.color = new THREE.Color(color); scene.add(this.mesh);
  }
  update(p, on) {
    if (on && p) this.pts.unshift(p.clone()); else this.pts.pop();
    if (this.pts.length > this.n) this.pts.length = this.n;
    const pts = this.pts, m = pts.length;
    this.mesh.visible = m > 1;
    if (m < 2) return;
    for (let i = 0; i < this.n; i++) {
      const a = pts[Math.min(i, m - 1)], b = pts[Math.min(i + 1, m - 1)] || a;
      let dx = a.x - b.x, dy = a.y - b.y; const l = Math.hypot(dx, dy) || 1; dx /= l; dy /= l;
      const w = this.width * (1 - i / this.n);
      const k = (1 - i / this.n) * (i < m ? 1 : 0);
      this.pos.set([a.x - dy * w, a.y + dx * w, a.z, a.x + dy * w, a.y - dx * w, a.z], i * 6);
      const r = this.color.r * k, g = this.color.g * k, bb = this.color.b * k;
      this.col.set([r, g, bb, r * 0.6 + k * 0.4, g * 0.6 + k * 0.4, bb * 0.6 + k * 0.4], i * 6);
    }
    this.mesh.geometry.attributes.position.needsUpdate = true; this.mesh.geometry.attributes.color.needsUpdate = true;
  }
}

function textSprite(text, bg, fg, w = 256, h = 128, font = 64) {
  const t = canvasTex(w, h, (c) => {
    c.fillStyle = bg; c.beginPath(); c.roundRect(6, 6, w - 12, h - 12, 26); c.fill();
    c.lineWidth = 6; c.strokeStyle = '#111'; c.stroke();
    c.fillStyle = fg; c.font = `900 ${font}px Anton, Impact, "Arial Black", sans-serif`; c.textAlign = 'center'; c.textBaseline = 'middle'; c.fillText(text, w / 2, h / 2 + 3);
  });
  return new THREE.Sprite(new THREE.SpriteMaterial({ map: t, transparent: true }));
}

function heartShape() {
  const s = new THREE.Shape(); s.moveTo(0, -0.25);
  s.bezierCurveTo(-0.5, 0.05, -0.28, 0.42, 0, 0.18); s.bezierCurveTo(0.28, 0.42, 0.5, 0.05, 0, -0.25);
  return s;
}

function makeProjectile(p) {
  const g = new THREE.Group();
  const outline = (m) => { const o = new THREE.Mesh(m.geometry, OUTLINE); o.scale.setScalar(1.07); m.add(o); return m; };
  switch (p.type) {
    case 'chai': {
      const mat = new THREE.MeshToonMaterial({ color: 0xb8742f, transparent: true, opacity: 0.88, emissive: 0x3a1a00 });
      const wave = new THREE.Mesh(new THREE.SphereGeometry(0.55, 14, 10, 0, Math.PI * 2, 0, Math.PI * 0.6), mat); wave.scale.set(1, 1.5, 0.8); g.add(wave);
      const foam = new THREE.Mesh(new THREE.TorusGeometry(0.42, 0.08, 6, 16), new THREE.MeshBasicMaterial({ color: 0xfff1d6 })); foam.rotation.x = Math.PI / 2; foam.position.y = 0.42; g.add(foam);
      const kulhad = outline(new THREE.Mesh(new THREE.CylinderGeometry(0.16, 0.11, 0.24, 10), toon('#b5532a'))); kulhad.position.y = 0.85; g.add(kulhad);
      g.userData.spin = 'wobble'; g.position.y = -0.45; break;
    }
    case 'auto': {
      const yel = toon('#f2d43c'), grn = toon('#2e8b3a'), blk = toon('#1a1a1a');
      const body = outline(new THREE.Mesh(new THREE.BoxGeometry(1.4, 0.55, 0.9), grn)); body.position.y = 0.45; g.add(body);
      const cab = outline(new THREE.Mesh(new THREE.BoxGeometry(1.0, 0.55, 0.88), yel)); cab.position.set(-0.1, 0.95, 0); g.add(cab);
      const roof = outline(new THREE.Mesh(new THREE.CylinderGeometry(0.45, 0.45, 0.9, 10, 1, false, 0, Math.PI), blk)); roof.rotation.x = Math.PI / 2; roof.rotation.z = Math.PI / 2; roof.position.set(-0.1, 1.2, 0); roof.scale.set(1.25, 1, 0.4); g.add(roof);
      const nose = outline(new THREE.Mesh(new THREE.BoxGeometry(0.3, 0.7, 0.5), yel)); nose.position.set(0.75, 0.6, 0); g.add(nose);
      const lamp = new THREE.Mesh(new THREE.SphereGeometry(0.1, 8, 6), new THREE.MeshBasicMaterial({ color: 0xfff6b0 })); lamp.position.set(0.92, 0.85, 0); g.add(lamp);
      g.wheels = [];
      for (const [x, z] of [[-0.45, 0.42], [-0.45, -0.42], [0.72, 0]]) { const w = new THREE.Mesh(new THREE.CylinderGeometry(0.2, 0.2, 0.12, 12), blk); w.rotation.x = Math.PI / 2; w.position.set(x, 0.2, z); g.add(w); g.wheels.push(w); }
      g.position.y = -0.6; g.userData.flipX = true; break;
    }
    case 'chappal': {
      const sole = outline(new THREE.Mesh(new THREE.CylinderGeometry(0.22, 0.22, 0.06, 14), toon('#7a4b2a'))); sole.scale.set(1, 1, 0.55); g.add(sole);
      const strap = new THREE.Mesh(new THREE.TorusGeometry(0.1, 0.025, 5, 12, Math.PI), toon('#2b6cd8')); strap.position.y = 0.03; strap.rotation.x = -Math.PI / 2; g.add(strap);
      g.userData.spin = 'z'; break;
    }
    case 'reticle': {
      const m = new THREE.MeshBasicMaterial({ color: 0xe3b65a, transparent: true, depthTest: false });
      const ring = new THREE.Mesh(new THREE.RingGeometry(0.28, 0.33, 32), m); g.add(ring);
      for (let i = 0; i < 4; i++) { const b = new THREE.Mesh(new THREE.PlaneGeometry(0.04, 0.22), m); b.position.set(Math.cos(i * Math.PI / 2) * 0.4, Math.sin(i * Math.PI / 2) * 0.4, 0); b.rotation.z = i * Math.PI / 2 + Math.PI / 2; g.add(b); }
      const dotm = new THREE.Mesh(new THREE.CircleGeometry(0.04, 12), new THREE.MeshBasicMaterial({ color: 0xff3030, depthTest: false })); g.add(dotm);
      g.renderOrder = 20; g.userData.spin = 'reticle'; break;
    }
    case 'jelly': {
      const m = new THREE.MeshToonMaterial({ color: 0x7fe6ff, transparent: true, opacity: 0.55, emissive: 0x1a6a8a });
      const w = new THREE.Mesh(new THREE.BoxGeometry(0.45, 1.7, 1.4, 1, 4, 3), m); g.add(w);
      const edge = new THREE.LineSegments(new THREE.EdgesGeometry(w.geometry), new THREE.LineBasicMaterial({ color: 0xbff6ff })); w.add(edge);
      g.userData.spin = 'jelly'; g.userData.box = w; break;
    }
    case 'pan': {
      const pan = outline(new THREE.Mesh(new THREE.CylinderGeometry(0.22, 0.19, 0.05, 14), toon('#3a3a3a'))); pan.rotation.x = Math.PI / 2; g.add(pan);
      const h = new THREE.Mesh(new THREE.BoxGeometry(0.06, 0.3, 0.05), toon('#6b4a2b')); h.position.y = -0.33; g.add(h);
      g.userData.spin = 'z'; break;
    }
    case 'like': {
      const m = new THREE.Mesh(new THREE.ExtrudeGeometry(heartShape(), { depth: 0.12, bevelEnabled: false }), new THREE.MeshToonMaterial({ color: 0xff3b6b, emissive: 0x801030 }));
      m.scale.setScalar(1.2); m.position.z = -0.06; outline(m); g.add(m); g.userData.spin = 'y'; break;
    }
    case 'ringlight': {
      const ring = new THREE.Mesh(new THREE.TorusGeometry(0.5, 0.08, 8, 32), new THREE.MeshBasicMaterial({ color: 0xffffff })); g.add(ring);
      const glow = new THREE.Sprite(new THREE.SpriteMaterial({ map: dotTex(), color: 0xffffff, blending: THREE.AdditiveBlending, transparent: true, depthWrite: false })); glow.scale.set(5, 5, 1); g.add(glow);
      g.userData.spin = 'pulse'; break;
    }
    case 'scream': {
      const m = new THREE.MeshBasicMaterial({ color: 0xff5a1f, transparent: true, opacity: 0.55, blending: THREE.AdditiveBlending, side: THREE.DoubleSide, depthWrite: false });
      for (let i = 0; i < 3; i++) { const r = new THREE.Mesh(new THREE.TorusGeometry(0.4 + i * 0.25, 0.06, 6, 24), m); r.rotation.y = Math.PI / 2; r.position.x = -i * 0.25; g.add(r); }
      g.userData.spin = 'scream'; break;
    }
    case 'lol': { const s = textSprite('LOL 😂', '#ffd23f', '#111', 256, 128, 60); s.scale.set(0.9, 0.45, 1); g.add(s); g.userData.spin = 'bob'; break; }
    case 'roastwave': { const s = textSprite('ROAST 🔥', '#ff5a1f', '#fff', 256, 128, 54); s.scale.set(1.0, 0.5, 1); g.add(s); g.userData.spin = 'bob'; break; }
    default: { const s = new THREE.Mesh(new THREE.SphereGeometry(0.2, 8, 6), new THREE.MeshBasicMaterial({ color: 0xffffff })); g.add(s); }
  }
  return g;
}

export class Fx3D {
  constructor(scene, q) {
    this.scene = scene; this.q = q;
    this.glow = new Particles(scene, q.level === 'low' ? 300 : 700, true);
    this.solid = new Particles(scene, q.level === 'low' ? 200 : 420, false);
    this.extra = [];       // 3D-only particles { x,y,z,vx,vy,vz,life,max,size,color,add }
    // rings + impact stars (pooled)
    this.rings = []; this.stars = []; this.shocks = [];
    for (let i = 0; i < 10; i++) {
      const r = new THREE.Mesh(new THREE.RingGeometry(0.88, 1, 40), new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide }));
      r.visible = false; r.renderOrder = 7; scene.add(r); this.rings.push(r);
      const st = new THREE.Sprite(new THREE.SpriteMaterial({ map: starTex(), transparent: true, blending: THREE.AdditiveBlending, depthWrite: false }));
      st.visible = false; st.renderOrder = 8; scene.add(st); this.stars.push(st);
      const sh = new THREE.Mesh(new THREE.RingGeometry(0.85, 1, 40), new THREE.MeshBasicMaterial({ color: 0xffe2a0, transparent: true, blending: THREE.AdditiveBlending, depthWrite: false }));
      sh.rotation.x = -Math.PI / 2; sh.position.y = 0.02; sh.visible = false; scene.add(sh); this.shocks.push(sh);
    }
    this.ringI = 0; this.starI = 0; this.shockI = 0;
    this.proj = new Map();
    this.trails = [];
    this.camQ = new THREE.Quaternion();
  }

  setTrails(fighterModels) {
    for (const t of this.trails) t.forEach((x) => this.scene.remove(x.mesh));
    this.trails = fighterModels.map((m) => [new Trail(this.scene, m.char.superColor || m.char.color, 0.13), new Trail(this.scene, m.char.color, 0.16)]);
  }

  // big 3D impact at a sim position
  impact(x, y, { big = false, blocked = false, color = 0xffe28a, dir = 1, superHit = false } = {}) {
    const X = toX(x), Y = toY(y);
    const st = this.stars[this.starI++ % this.stars.length];
    st.position.set(X, Y, 0.35); st.material.color.set(blocked ? 0x9fd8ff : color); st.userData = { life: big ? 14 : 9, max: big ? 14 : 9, size: big ? 1.7 : 1.0 }; st.visible = true; st.material.rotation = Math.random() * 6;
    const n = this.q.level === 'low' ? (big ? 14 : 6) : big ? 34 : 14;
    for (let i = 0; i < n; i++) {
      const a = (Math.random() - 0.5) * Math.PI * 1.4 + (dir > 0 ? 0 : Math.PI), sp = (big ? 0.09 : 0.06) * (0.4 + Math.random());
      this.extra.push({ x: X, y: Y, z: 0.2 + (Math.random() - 0.5) * 0.6, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp + 0.02, vz: (Math.random() - 0.5) * 0.06, life: 16 + Math.random() * 12, max: 28, size: 0.07 + Math.random() * 0.08, color: blocked ? 0x9fd8ff : Math.random() < 0.5 ? 0xffd36b : 0xff7a2c, add: true, g: 0.004, streak: true });
    }
    if (big || superHit) this.shock(x, superHit ? 0xffd36b : 0xffe2a0);
  }
  shock(x, color = 0xffe2a0) { const s = this.shocks[this.shockI++ % this.shocks.length]; s.position.x = toX(x); s.material.color.set(color); s.userData = { life: 22, max: 22 }; s.visible = true; }
  burst(X, Y, color, n = 40, speed = 0.12) { // super start, KO
    for (let i = 0; i < n; i++) { const a = Math.random() * Math.PI * 2, sp = speed * (0.3 + Math.random()); this.extra.push({ x: X, y: Y, z: (Math.random() - 0.5) * 0.5, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp, vz: (Math.random() - 0.5) * 0.08, life: 30 + Math.random() * 20, max: 50, size: 0.08 + Math.random() * 0.12, color, add: true, g: 0 }); }
  }
  embers(X, Y, color) { if (Math.random() < 0.5) this.extra.push({ x: X + (Math.random() - 0.5) * 0.8, y: Y + Math.random() * 0.4, z: (Math.random() - 0.5) * 0.6, vx: 0, vy: 0.02 + Math.random() * 0.02, vz: 0, life: 30, max: 30, size: 0.06 + Math.random() * 0.07, color, add: true, g: 0 }); }

  update(game, camera, dt, models) {
    this.camQ.copy(camera.quaternion);
    const k = Math.min(3, dt * 60);
    this.glow.begin(); this.solid.begin();
    if (game) {
      // sim particles (2D) -> 3D
      for (const p of game.fx.parts) {
        const fade = Math.max(0, p.life / p.max), id = (p.seed ??= Math.random());
        const X = toX(p.x), Y = toY(p.y), z = (hash(id * 99) - 0.5) * (p.confetti ? 3 : 0.8);
        if (p.confetti) this.solid.push(X, Y, z + 0.5, p.size / 90, p.color, 1, p.rot, this.camQ);
        else if (p.soft) this.solid.push(X, Y + 0.05, z, (p.size / 80) * (1.5 - fade * 0.5), '#9a8c78', fade * 0.8, 0, this.camQ);
        else this.glow.push(X, Y, z + 0.3, p.size / 70, p.color, fade, 0, this.camQ);
      }
      // rings from sim
      for (const r of game.fx.rings) {
        if (!r.mesh) {
          const m = this.rings[this.ringI++ % this.rings.length]; r.mesh = m; m.userData = { owner: r };
        }
        const m = r.mesh; if (m.userData.owner !== r) continue;
        m.visible = true; m.position.set(toX(r.x), toY(r.y), 0.4); m.quaternion.copy(this.camQ);
        m.scale.setScalar(r.r / 150 + 0.05); m.material.color.set(r.color).multiplyScalar(0.7 * r.life / 14); m.userData.seen = game.frame;
      }
      for (const m of this.rings) if (m.visible && (!m.userData.owner || m.userData.owner.life <= 0 || m.userData.seen !== game.frame)) m.visible = false;
      // projectiles
      const seen = new Set();
      for (const p of game.projectiles) {
        let o = this.proj.get(p);
        if (!o) { o = makeProjectile(p); this.proj.set(p, o); this.scene.add(o); o.userData.base = o.position.y; }
        seen.add(p);
        const dir = Math.sign(p.vx || p.owner.facing || 1);
        o.position.x = toX(p.x); o.position.y = toY(p.y) + (o.userData.base || 0); o.position.z = 0.1;
        const u = o.userData, t = (p.age || 0);
        if (u.flipX) o.scale.x = dir; if (o.wheels) o.wheels.forEach((w) => (w.rotation.y += 0.4));
        if (u.spin === 'z') o.rotation.z += 0.45 * k * -dir;
        if (u.spin === 'y') o.rotation.y += 0.2 * k;
        if (u.spin === 'wobble') { o.scale.set(1 + Math.sin(t * 0.5) * 0.08, 1 + Math.cos(t * 0.4) * 0.1, 1); this.embers(o.position.x, o.position.y, 0xfff1d6); }
        if (u.spin === 'reticle') { o.rotation.z = t * 0.12; o.scale.setScalar(Math.max(0.6, 1.6 - t / 30)); o.quaternion.multiplyQuaternions(this.camQ, new THREE.Quaternion().setFromAxisAngle(Z, t * 0.12)); }
        if (u.spin === 'jelly') { u.box.scale.y = Math.min(1, (p.h || 170) / 170); u.box.position.y = 0; o.scale.set(1 + Math.sin(t * 0.6) * 0.06, 1, 1); }
        if (u.spin === 'pulse') o.scale.setScalar(1 + Math.sin(t * 0.6) * 0.2);
        if (u.spin === 'scream') { o.scale.set(dir, (p.h || 170) / 170, (p.h || 170) / 170); this.embers(o.position.x, o.position.y, 0xff5a1f); }
        if (u.spin === 'bob') o.position.y += Math.sin(t * 0.3) * 0.05;
        if (p.isSuper && this.q.level !== 'low') this.embers(o.position.x, o.position.y, new THREE.Color(p.owner.char.superColor).getHex());
      }
      for (const [p, o] of this.proj) if (!seen.has(p)) { this.scene.remove(o); this.proj.delete(p); }
      // trails on specials / supers / heavy moves
      if (models) models.forEach((mdl, i) => {
        const f = game.f[i], m = f.attack && f.attack.move;
        const tr = this.trails[i]; if (!tr) return;
        const on = (m && (m.special || m.kd || m.id === 'round' || m.id === 'upper') && f.attackPhase !== 'recovery') || f.state === 'super' || f.state === 'badla' || f.state === 'throw';
        let hand = null, foot = null;
        if (on) {
          const tips = mdl.tips(f);
          const usesLeg = m && ['kick', 'round', 'sweep', 'fly', 'airk'].includes(m.id);
          const leg = m && m.id === 'round' ? tips.ff : tips.fn;
          if (usesLeg) foot = leg; else hand = m && m.id === 'jab2' ? tips.hf : tips.hn;
          if (f.state === 'badla' || f.state === 'super') { hand = tips.hn; foot = tips.hf; }
        }
        tr[0].update(hand, !!hand); tr[1].update(foot, !!foot);
      });
    }
    // 3D-only particles
    for (const p of this.extra) {
      p.x += p.vx * k; p.y += p.vy * k; p.z += p.vz * k; p.vy -= (p.g || 0) * k; p.life -= k;
      const fade = Math.max(0, p.life / p.max);
      (p.add ? this.glow : this.solid).push(p.x, p.y, p.z, p.size * (0.5 + fade * 0.7), p.color, fade, 0, this.camQ);
    }
    this.extra = this.extra.filter((p) => p.life > 0);
    if (this.extra.length > 900) this.extra.splice(0, this.extra.length - 900);
    this.glow.end(); this.solid.end();
    for (const st of this.stars) if (st.visible) { const u = st.userData; u.life -= k; const t = 1 - u.life / u.max; st.scale.setScalar(u.size * (0.5 + t * 0.9)); st.material.opacity = Math.max(0, 1 - t); if (u.life <= 0) st.visible = false; }
    for (const s of this.shocks) if (s.visible) { const u = s.userData; u.life -= k; const t = 1 - u.life / u.max; s.scale.setScalar(0.3 + t * 2.6); s.material.opacity = Math.max(0, 1 - t); if (u.life <= 0) s.visible = false; }
  }

  clear() { for (const [, o] of this.proj) this.scene.remove(o); this.proj.clear(); this.extra = []; for (const t of this.trails) t.forEach((x) => { x.pts = []; x.mesh.visible = false; }); }
}
