// The ground remembers. Blood, scorch marks, casings, footprints and corpses are stamped into a
// render target that is never cleared during a run. Colour is stored gamma-encoded (sqrt) and
// premultiplied, so 8 bits are enough for deep reds without banding.
import * as THREE from 'three/webgpu';
import { attribute, positionGeometry, vec2, vec3, vec4, cos, sin, sqrt, texture, uv, mod, floor, Fn, varying } from 'three/tsl';
import { ARENA } from '../config.js';

const CAPACITY = 4096;
const CELLS = 4;
export const DECAL_HALF = ARENA + 10;
const GRID = 128;

export class Decals {
  constructor(stage, atlas, size) {
    this.stage = stage;
    this.size = size;
    this.rt = new THREE.RenderTarget(size, size, {
      depthBuffer: false, type: THREE.UnsignedByteType, format: THREE.RGBAFormat,
      minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter, generateMipmaps: false,
    });
    this.rt.texture.name = 'decals';
    this.scene = new THREE.Scene();
    const H = DECAL_HALF;
    this.camera = new THREE.OrthographicCamera(-H, H, H, -H, 0.1, 10);
    this.camera.position.set(0, 0, 5);
    this.camera.updateMatrixWorld();
    this.count = 0;
    this.blood = new Float32Array(GRID * GRID);
    this.xform = new Float32Array(CAPACITY * 4);
    this.extra = new Float32Array(CAPACITY * 2);
    this.color = new Float32Array(CAPACITY * 4);
    this.buildStampMesh(atlas);
    this.bakers = [];
  }

  buildStampMesh(atlas) {
    const quad = new THREE.PlaneGeometry(1, 1);
    const g = this.geo = new THREE.InstancedBufferGeometry();
    g.index = quad.index;
    g.setAttribute('position', quad.getAttribute('position'));
    g.setAttribute('uv', quad.getAttribute('uv'));
    const dyn = (arr, n) => new THREE.InstancedBufferAttribute(arr, n).setUsage(THREE.DynamicDrawUsage);
    g.setAttribute('iXform', dyn(this.xform, 4));
    g.setAttribute('iExtra', dyn(this.extra, 2));
    g.setAttribute('iColor', dyn(this.color, 4));
    g.instanceCount = 0;

    const iXform = attribute('iXform', 'vec4'), iExtra = attribute('iExtra', 'vec2'), iColor = attribute('iColor', 'vec4');
    const m = new THREE.MeshBasicNodeMaterial({ transparent: true, depthTest: false, depthWrite: false });
    m.blending = THREE.CustomBlending;
    m.blendEquation = THREE.AddEquation;
    m.blendSrc = THREE.OneFactor; m.blendDst = THREE.OneMinusSrcAlphaFactor;
    m.blendSrcAlpha = THREE.OneFactor; m.blendDstAlpha = THREE.OneMinusSrcAlphaFactor;
    m.positionNode = Fn(() => {
      const c = cos(iExtra.x), s = sin(iExtra.x);
      const q = positionGeometry.xy.mul(iXform.zw);
      return vec3(q.x.mul(c).sub(q.y.mul(s)).add(iXform.x), q.x.mul(s).add(q.y.mul(c)).add(iXform.y), 0);
    })();
    const cell = varying(vec2(mod(iExtra.y, CELLS), floor(iExtra.y.div(CELLS))));
    const t = texture(atlas, vec2(uv().x, uv().y.oneMinus()).add(cell).div(CELLS));
    const a = t.a.mul(iColor.a);
    m.colorNode = vec4(sqrt(iColor.rgb).mul(t.r.mul(0.55).add(0.62)).mul(a), 1);
    m.opacityNode = a;
    const mesh = new THREE.Mesh(g, m);
    mesh.frustumCulled = false;
    this.scene.add(mesh);
    this.mesh = mesh;
  }

  addBaker(bakeMesh) { this.bakers.push(bakeMesh); this.scene.add(bakeMesh.mesh); }

  clear() {
    const { renderer } = this.stage;
    const prev = renderer.getRenderTarget();
    const col = renderer.getClearColor(new THREE.Color()), al = renderer.getClearAlpha();
    renderer.setRenderTarget(this.rt);
    renderer.setClearColor(0x000000, 0);
    renderer.clear();
    renderer.setRenderTarget(prev);
    renderer.setClearColor(col, al);
    this.blood.fill(0);
    this.count = 0;
  }

  stamp(cell, x, z, sx, sy, rot, r, g, b, a, wet = 0) {
    const n = this.count;
    if (n >= CAPACITY) return;
    if (x < -DECAL_HALF || x > DECAL_HALF || z < -DECAL_HALF || z > DECAL_HALF) return;
    const X = this.xform, E = this.extra, C = this.color;
    const i4 = n * 4, i2 = n * 2;
    X[i4] = x; X[i4 + 1] = z; X[i4 + 2] = sx; X[i4 + 3] = sy;
    E[i2] = rot; E[i2 + 1] = cell;
    C[i4] = r; C[i4 + 1] = g; C[i4 + 2] = b; C[i4 + 3] = a;
    this.count = n + 1;
    if (wet > 0) this.wet(x, z, sx * 0.5, wet);
  }

  wet(x, z, radius, amount) {
    const s = GRID / (DECAL_HALF * 2);
    const cx = (x + DECAL_HALF) * s, cz = (z + DECAL_HALF) * s, r = Math.max(1, radius * s);
    const x0 = Math.max(0, Math.floor(cx - r)), x1 = Math.min(GRID - 1, Math.ceil(cx + r));
    const z0 = Math.max(0, Math.floor(cz - r)), z1 = Math.min(GRID - 1, Math.ceil(cz + r));
    for (let gz = z0; gz <= z1; gz++) {
      for (let gx = x0; gx <= x1; gx++) {
        const i = gz * GRID + gx;
        this.blood[i] = Math.min(1, this.blood[i] + amount);
      }
    }
  }

  bloodAt(x, z) {
    const s = GRID / (DECAL_HALF * 2);
    const gx = Math.floor((x + DECAL_HALF) * s), gz = Math.floor((z + DECAL_HALF) * s);
    if (gx < 0 || gz < 0 || gx >= GRID || gz >= GRID) return 0;
    return this.blood[gz * GRID + gx];
  }

  flush() {
    let pending = this.count > 0;
    for (const b of this.bakers) if (b.prepare()) pending = true;
    if (!pending) return;
    const g = this.geo;
    g.instanceCount = this.count;
    if (this.count) {
      g.getAttribute('iXform').needsUpdate = true;
      g.getAttribute('iExtra').needsUpdate = true;
      g.getAttribute('iColor').needsUpdate = true;
    }
    const { renderer } = this.stage;
    const prev = renderer.getRenderTarget(), autoClear = renderer.autoClear;
    renderer.autoClear = false;
    renderer.setRenderTarget(this.rt);
    renderer.render(this.scene, this.camera);
    renderer.setRenderTarget(prev);
    renderer.autoClear = autoClear;
    this.count = 0;
    g.instanceCount = 0;
    for (const b of this.bakers) b.finish();
  }
}
