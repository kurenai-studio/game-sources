// vhs.mjs — tratamiento VHS: pase fullscreen a WebGLRenderTarget con ShaderMaterial
// propio (scanline, grain, tracking, aberracion cromatica, vignette) + overlay 2D
// (timestamp de fx-logic.vhsTimestamp, punto REC parpadeante, marco PLAY).
// Sin three/addons: quad ortografico con shader inyectado a mano.
import { vhsTimestamp } from './fx-logic.mjs';

const VERT = `
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = vec4(position.xy, 0.0, 1.0);
}`;

// Fragmento: cada efecto queda como variable nombrada (scanline/grain/tracking/vignette).
const FRAG = `
precision highp float;
varying vec2 vUv;
uniform sampler2D tDiffuse;
uniform float uTime;
uniform vec2 uRes;
float rand(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void main() {
  vec2 uv = vUv;
  // tracking: banda horizontal desplazada de vez en cuando (cinta gastada)
  float band = step(0.986, rand(vec2(floor(uTime * 3.0), floor(uv.y * 14.0))));
  float tracking = band * (rand(vec2(uTime, uv.y)) - 0.5) * 0.07;
  uv.x += tracking;
  // aberracion cromatica leve: separar canales
  float ca = 0.0016 + band * 0.004;
  float r = texture2D(tDiffuse, uv + vec2(ca, 0.0)).r;
  float g = texture2D(tDiffuse, uv).g;
  float b = texture2D(tDiffuse, uv - vec2(ca, 0.0)).b;
  vec3 col = vec3(r, g, b);
  // scanline: modulacion vertical fina animada
  float scanline = 0.88 + 0.12 * sin(uv.y * uRes.y * 1.4 + uTime * 9.0);
  col *= scanline;
  // grain: ruido animado por pixel
  float grain = (rand(uv * uRes * 0.5 + uTime) - 0.5) * 0.13;
  col += grain;
  // vignette: oscurecer bordes
  vec2 d = uv - 0.5;
  float vignette = smoothstep(0.9, 0.32, length(d));
  col *= vignette;
  // tinte verdoso enfermizo de camcorder
  col *= vec3(0.9, 1.03, 0.93);
  gl_FragColor = vec4(col, 1.0);
}`;

function makeHud(GAME, mount) {
  const el = document.createElement('div');
  el.style.cssText = 'position:fixed;inset:0;pointer-events:none;z-index:30;' +
    'font-family:"Courier New",monospace;color:#e8e8d0;text-shadow:0 0 4px #000;';
  const rec = document.createElement('div');
  rec.style.cssText = 'position:absolute;top:18px;right:22px;font-size:22px;letter-spacing:3px;';
  const play = document.createElement('div');
  play.textContent = '▶ PLAY';
  play.style.cssText = 'position:absolute;top:18px;left:22px;font-size:16px;letter-spacing:2px;opacity:0.8;';
  const ts = document.createElement('div');
  ts.style.cssText = 'position:absolute;bottom:18px;left:22px;font-size:16px;letter-spacing:1px;';
  el.appendChild(rec);
  el.appendChild(play);
  el.appendChild(ts);
  mount.appendChild(el);
  return { root: el, rec, ts, recText: (GAME.platform.texts.rec || 'REC') };
}

function updateHud(hud) {
  const now = Date.now();
  const t = vhsTimestamp(now);
  hud.ts.textContent = t.date + '  ' + t.time;
  const on = (now % 1000) < 600; // parpadeo ~1Hz
  hud.rec.textContent = (on ? '● ' : '  ') + hud.recText;
}

export function createVHS(THREE, renderer, mount, GAME) {
  const w = window.innerWidth, h = window.innerHeight;
  const rt = new THREE.WebGLRenderTarget(w, h, { minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter });
  const uniforms = {
    tDiffuse: { value: rt.texture },
    uTime: { value: 0 },
    uRes: { value: new THREE.Vector2(w, h) },
  };
  const mat = new THREE.ShaderMaterial({ uniforms, vertexShader: VERT, fragmentShader: FRAG, depthTest: false, depthWrite: false });
  const scene = new THREE.Scene();
  const cam = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
  const quad = new THREE.Mesh(new THREE.PlaneGeometry(2, 2), mat);
  quad.frustumCulled = false;
  scene.add(quad);
  const hud = makeHud(GAME, mount);

  function setSize(nw, nh) {
    rt.setSize(nw, nh);
    uniforms.uRes.value.set(nw, nh);
  }

  function render(world, camera, tMs) {
    renderer.setRenderTarget(rt);
    renderer.clear();
    renderer.render(world, camera);
    renderer.setRenderTarget(null);
    uniforms.uTime.value = tMs / 1000;
    renderer.render(scene, cam);
    updateHud(hud);
  }

  function dispose() {
    rt.dispose();
    mat.dispose();
    quad.geometry.dispose();
    if (hud.root.parentNode) hud.root.parentNode.removeChild(hud.root);
  }

  return { render, setSize, dispose };
}
