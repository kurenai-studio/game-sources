/* Checkpoint pads and the finish/start gates. */
'use strict';

class Checkpoint {
  constructor(scene, opts) {
    this.index = opts.index;
    this.pos = new THREE.Vector3(opts.x, opts.y, opts.z);
    this.spawnPos = new THREE.Vector3(opts.x, opts.y + 0.55, opts.z);
    this.radius = 2.4;
    this.activated = false;

    this.padMat = new THREE.MeshPhongMaterial({ color: 0x9fb7c9, shininess: 60 });
    this.ringMat = new THREE.MeshPhongMaterial({ color: 0xcfd9e3, shininess: 80 });
    this.flagMat = new THREE.MeshPhongMaterial({
      color: 0xcfd9e3, shininess: 40, side: THREE.DoubleSide
    });

    const g = new THREE.Group();
    const pad = new THREE.Mesh(new THREE.CylinderGeometry(2.1, 2.2, 0.14, 28), this.padMat);
    pad.position.y = 0.07;
    pad.receiveShadow = true;

    this.ring = new THREE.Mesh(new THREE.TorusGeometry(2.3, 0.09, 10, 36), this.ringMat);
    this.ring.rotation.x = Math.PI / 2;
    this.ring.position.y = 0.18;

    const pole = new THREE.Mesh(
      new THREE.CylinderGeometry(0.06, 0.06, 2.6, 8),
      new THREE.MeshPhongMaterial({ color: 0xffffff, shininess: 60 })
    );
    pole.position.set(0, 1.3, 1.9);
    pole.castShadow = true;
    this.flag = new THREE.Mesh(new THREE.PlaneGeometry(1.15, 0.72), this.flagMat);
    this.flag.position.set(0.6, 2.2, 1.9);

    g.add(pad, this.ring, pole, this.flag);
    g.position.copy(this.pos);
    scene.add(g);
    this.group = g;
  }

  activate() {
    this.activated = true;
    this.padMat.color.setHex(0x51e08a);
    this.ringMat.color.setHex(0xffd93d);
    this.flagMat.color.setHex(0x51e08a);
  }

  reset() {
    this.activated = false;
    this.padMat.color.setHex(0x9fb7c9);
    this.ringMat.color.setHex(0xcfd9e3);
    this.flagMat.color.setHex(0xcfd9e3);
  }

  update(dt, t) {
    this.ring.rotation.z = t * 0.8;
    this.flag.rotation.y = Math.sin(t * 2.2 + this.index) * 0.25;
  }

  check(p) {
    if (this.activated) return false;
    const dx = p.pos.x - this.pos.x;
    const dz = p.pos.z - this.pos.z;
    return dx * dx + dz * dz < this.radius * this.radius &&
           Math.abs(p.pos.y - this.pos.y) < 1.6;
  }
}

/* ------------------------------------------------------------------ */

function makeBannerTexture(text, bgHex, checkered) {
  const c = document.createElement('canvas');
  c.width = 512; c.height = 128;
  const ctx = c.getContext('2d');
  ctx.fillStyle = bgHex;
  ctx.fillRect(0, 0, 512, 128);
  if (checkered) {
    const s = 32;
    for (let row = 0; row < 2; row++) {
      for (let i = 0; i < 16; i++) {
        ctx.fillStyle = (i + row) % 2 ? '#ffffff' : '#23235e';
        ctx.fillRect(i * s, row === 0 ? 0 : 128 - s / 2, s, s / 2);
        ctx.fillRect(i * s, row === 0 ? s / 2 : 128 - s, s, s / 2);
        ctx.fillStyle = (i + row) % 2 ? '#23235e' : '#ffffff';
        ctx.fillRect(i * s, row === 0 ? s / 2 : 128 - s, s, s / 2);
      }
    }
  }
  ctx.fillStyle = '#ffffff';
  ctx.font = 'bold 64px "Arial Rounded MT Bold", "Trebuchet MS", Verdana, sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.strokeStyle = 'rgba(0,0,0,0.25)';
  ctx.lineWidth = 8;
  ctx.strokeText(text, 256, 66);
  ctx.fillText(text, 256, 66);
  return new THREE.CanvasTexture(c);
}

/* ------------------------------------------------------------------ */

class Gate {
  constructor(scene, opts) {
    // opts: { x, z, y (platform top), span, color, label, checkered }
    this.x = opts.x || 0;
    this.z = opts.z;
    this.y = opts.y;
    this.halfWidth = opts.span / 2;

    const pillarMat = new THREE.MeshPhongMaterial({ color: opts.color, shininess: 70 });
    const whiteMat = new THREE.MeshPhongMaterial({ color: 0xffffff, shininess: 80 });
    const g = new THREE.Group();

    for (const side of [-1, 1]) {
      const pillar = new THREE.Mesh(new THREE.CylinderGeometry(0.38, 0.46, 4.4, 16), pillarMat);
      pillar.position.set(side * this.halfWidth, 2.2, 0);
      pillar.castShadow = true;
      const ball = new THREE.Mesh(new THREE.SphereGeometry(0.55, 16, 12), whiteMat);
      ball.position.set(side * this.halfWidth, 4.7, 0);
      ball.castShadow = true;
      g.add(pillar, ball);
    }

    const beam = new THREE.Mesh(new THREE.BoxGeometry(opts.span + 1.1, 0.5, 0.6), pillarMat);
    beam.position.y = 4.55;
    beam.castShadow = true;
    g.add(beam);

    const banner = new THREE.Mesh(
      new THREE.PlaneGeometry(opts.span, 1.5),
      new THREE.MeshBasicMaterial({
        map: makeBannerTexture(opts.label, opts.bannerBg, opts.checkered),
        side: THREE.DoubleSide
      })
    );
    banner.position.y = 3.6;
    g.add(banner);
    this.banner = banner;

    g.position.set(this.x, this.y, this.z);
    scene.add(g);
    this.group = g;
  }

  update(dt, t) {
    this.banner.rotation.y = Math.sin(t * 1.6) * 0.05;
  }

  /* Has the player crossed the gate plane (heading -Z) inside the arch? */
  checkFinish(p) {
    return p.pos.z < this.z &&
           Math.abs(p.pos.x - this.x) <= this.halfWidth + 0.6 &&
           p.pos.y > this.y - 1;
  }
}
