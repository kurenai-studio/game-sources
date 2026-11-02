// Arena Runner — WebGL edition (part 1: engine, arena, FX, player)
// Built into docs/index.html by Web/build_web.py — see that file for the pipeline.
(function () {
'use strict';

// =============================================================================
// 0. Quality / config
// =============================================================================
var IS_TOUCH = ('ontouchstart' in window) || navigator.maxTouchPoints > 0 ||
  window.matchMedia('(pointer: coarse)').matches || /[?&]touch=1/.test(location.search);

var WEAK_GPU = (function () {
  var r = IS_TOUCH ? 0.82 : 1;
  try {
    var gl = document.createElement('canvas').getContext('webgl2');
    if (!gl) return 1;
    var dbg = gl.getExtension('WEBGL_debug_renderer_info');
    var name = dbg ? String(gl.getParameter(dbg.UNMASKED_RENDERER_WEBGL)) : '';
    if (/mali-4|mali-t[0-7]|adreno \(tm\) [2-4]|powervr sgx|swiftshader|software/i.test(name)) return 1;
    return r;
  } catch (e) { return r; }
})();

var QUALITY = {
  pixelRatio: Math.min(window.devicePixelRatio || 1, WEAK_GPU >= 1 ? 1.35 : 2),
  bloom: true,
  bloomScale: IS_TOUCH ? 0.32 : 0.45,
  shadows: true,
  shadowMap: IS_TOUCH ? 512 : 1024,
  particles: IS_TOUCH ? 220 : 520,
  dust: !IS_TOUCH
};

var CFG = {
  arenaRadius: 19.0,
  wallHeight: 5.2,
  wallSegments: 40,

  // player
  maxHealth: 100,
  walkSpeed: 4.4,
  sprintSpeed: 7.9,
  jumpVel: 6.6,
  gravity: 12.6,
  playerRadius: 0.42,
  cameraDist: 6.1,
  cameraHeight: 1.62,
  regen: 2.2,
  regenDelay: 5.0,
  damageCooldown: 0.62,
  knockback: 4.0,
  dashSpeed: 22.0,
  dashTime: 0.17,
  dashCooldown: 1.5,
  dashInvuln: 0.24,

  // combat
  attackDamage: 26,
  attackRange: 2.75,
  attackArc: 105,
  attackCooldown: 0.42,
  attackComboWindow: 0.85,
  hitStop: 0.055,
  comboWindow: 3.5,
  comboStep: 0.18,
  comboMax: 6,

  // spawning
  coreCount0: 5,
  corePerWave: 1.5,
  maxCores: 14,
  scorePerCore: 30,
  scorePerKill: 45,
  waveBonus: 120,
  bossEvery: 5,

  // enemies
  spawnInterval0: 3.4,
  spawnIntervalMin: 1.15,
  maxAliveBase: 3,
  maxAliveCap: IS_TOUCH ? 7 : 10,

  hunterHp: 55, hunterSpeed: 2.75, hunterDamage: 11, hunterRadius: 0.62, hunterScore: 45,
  chargerHp: 95, chargerSpeed: 2.1, chargerDash: 11.5, chargerDamage: 20, chargerRadius: 0.72, chargerScore: 70,
  spitterHp: 60, spitterSpeed: 2.35, spitterDamage: 10, spitterRadius: 0.58, spitterScore: 65,
  bossHp: 950, bossSpeed: 1.85, bossDamage: 24, bossRadius: 1.45, bossScore: 1200
};

// =============================================================================
// 1. Small helpers
// =============================================================================
var TAU = Math.PI * 2;
function clamp(v, a, b) { return v < a ? a : (v > b ? b : v); }
function lerp(a, b, t) { return a + (b - a) * t; }
function damp(a, b, lambda, dt) { return lerp(a, b, 1 - Math.exp(-lambda * dt)); }
function rand(a, b) { return a + Math.random() * (b - a); }
function randInt(a, b) { return Math.floor(rand(a, b + 1)); }
function pick(arr) { return arr[Math.floor(Math.random() * arr.length)]; }
function angleDelta(from, to) { return ((to - from + Math.PI * 3) % TAU) - Math.PI; }
function pad(n, len) { var s = String(n); while (s.length < len) s = '0' + s; return s; }

// =============================================================================
// 2. Renderer / scene / camera
// =============================================================================
var canvas = document.getElementById('view');
var renderer = new THREE.WebGLRenderer({ canvas: canvas, antialias: true, powerPreference: 'high-performance' });
renderer.setPixelRatio(QUALITY.pixelRatio);
renderer.shadowMap.enabled = QUALITY.shadows;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.15;
if ('outputColorSpace' in renderer) renderer.outputColorSpace = THREE.SRGBColorSpace;

var scene = new THREE.Scene();
scene.fog = new THREE.Fog(0x061019, 30, 78);

var camera = new THREE.PerspectiveCamera(72, 1, 0.1, 260);
camera.position.set(0, 3, 7);

// sky dome (cheap gradient, sells the neon night)
(function sky() {
  var geo = new THREE.SphereGeometry(140, 32, 20);
  var mat = new THREE.ShaderMaterial({
    side: THREE.BackSide, depthWrite: false, fog: false,
    uniforms: {
      top: { value: new THREE.Color(0x0a1c33) },
      bottom: { value: new THREE.Color(0x03060a) },
      glow: { value: new THREE.Color(0x1b6d8f) }
    },
    vertexShader: [
      'varying vec3 vPos;',
      'void main(){ vPos = position; gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.0); }'
    ].join('\n'),
    fragmentShader: [
      'uniform vec3 top; uniform vec3 bottom; uniform vec3 glow; varying vec3 vPos;',
      'void main(){',
      '  float h = clamp(normalize(vPos).y * 0.5 + 0.5, 0.0, 1.0);',
      '  vec3 c = mix(bottom, top, pow(h, 0.85));',
      '  float band = exp(-pow((h - 0.52) * 9.0, 2.0));',
      '  c += glow * band * 0.55;',
      '  gl_FragColor = vec4(c, 1.0);',
      '}'
    ].join('\n')
  });
  scene.add(new THREE.Mesh(geo, mat));
})();

var hemi = new THREE.HemisphereLight(0x9fc8ff, 0x101a26, 1.15);
scene.add(hemi);

var keyLight = new THREE.DirectionalLight(0xdff0ff, 2.5);
keyLight.position.set(14, 22, 9);
keyLight.castShadow = QUALITY.shadows;
keyLight.shadow.mapSize.set(QUALITY.shadowMap, QUALITY.shadowMap);
keyLight.shadow.camera.left = -26;
keyLight.shadow.camera.right = 26;
keyLight.shadow.camera.top = 26;
keyLight.shadow.camera.bottom = -26;
keyLight.shadow.camera.near = 2;
keyLight.shadow.camera.far = 70;
keyLight.shadow.bias = -0.0008;
scene.add(keyLight);

var rimLight = new THREE.DirectionalLight(0x2f7bff, 1.35);
rimLight.position.set(-16, 8, -14);
scene.add(rimLight);

// =============================================================================
// 3. Post-processing (bloom) — hand rolled so the page stays a single file
// =============================================================================
var PostFX = (function () {
  var isWebGL2 = renderer.capabilities.isWebGL2;
  var enabled = QUALITY.bloom && isWebGL2;

  var quadScene = new THREE.Scene();
  var quadCam = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
  var quad = new THREE.Mesh(new THREE.PlaneGeometry(2, 2), null);
  quad.frustumCulled = false;
  quadScene.add(quad);

  var vert = [
    'varying vec2 vUv;',
    'void main(){ vUv = uv; gl_Position = vec4(position.xy, 0.0, 1.0); }'
  ].join('\n');

  var brightMat = new THREE.ShaderMaterial({
    uniforms: { tDiffuse: { value: null }, threshold: { value: 0.82 } },
    vertexShader: vert,
    fragmentShader: [
      'uniform sampler2D tDiffuse; uniform float threshold; varying vec2 vUv;',
      'void main(){',
      '  vec3 c = texture2D(tDiffuse, vUv).rgb;',
      '  float l = max(c.r, max(c.g, c.b));',
      '  float k = max(l - threshold, 0.0) / max(l, 0.0001);',
      '  gl_FragColor = vec4(c * k, 1.0);',
      '}'
    ].join('\n'),
    depthTest: false, depthWrite: false
  });

  var blurMat = new THREE.ShaderMaterial({
    uniforms: { tDiffuse: { value: null }, dir: { value: new THREE.Vector2(1, 0) } },
    vertexShader: vert,
    fragmentShader: [
      'uniform sampler2D tDiffuse; uniform vec2 dir; varying vec2 vUv;',
      'void main(){',
      '  vec3 s = texture2D(tDiffuse, vUv).rgb * 0.2270270;',
      '  s += (texture2D(tDiffuse, vUv + dir * 1.3846154).rgb + texture2D(tDiffuse, vUv - dir * 1.3846154).rgb) * 0.3162162;',
      '  s += (texture2D(tDiffuse, vUv + dir * 3.2307692).rgb + texture2D(tDiffuse, vUv - dir * 3.2307692).rgb) * 0.0702702;',
      '  gl_FragColor = vec4(s, 1.0);',
      '}'
    ].join('\n'),
    depthTest: false, depthWrite: false
  });

  var compMat = new THREE.ShaderMaterial({
    uniforms: {
      tScene: { value: null }, tBloom: { value: null },
      strength: { value: 0.82 }, exposure: { value: 1.02 }
    },
    vertexShader: vert,
    fragmentShader: [
      'uniform sampler2D tScene; uniform sampler2D tBloom; uniform float strength; uniform float exposure;',
      'varying vec2 vUv;',
      'vec3 toSRGB(vec3 c){ return pow(max(c, vec3(0.0)), vec3(1.0 / 2.2)); }',
      'void main(){',
      '  vec3 c = texture2D(tScene, vUv).rgb;',
      '  vec3 b = texture2D(tBloom, vUv).rgb;',
      '  c = (c + b * strength) * exposure;',
      '  float d = distance(vUv, vec2(0.5));',
      '  c *= mix(0.62, 1.0, smoothstep(0.92, 0.34, d));',
      '  gl_FragColor = vec4(toSRGB(c), 1.0);',
      '}'
    ].join('\n'),
    depthTest: false, depthWrite: false
  });

  var rtScene = null, rtA = null, rtB = null;
  var size = { w: 1, h: 1 };

  function makeTargets(w, h) {
    var opts = { type: THREE.HalfFloatType, format: THREE.RGBAFormat, depthBuffer: true, stencilBuffer: false };
    rtScene = new THREE.WebGLRenderTarget(w, h, opts);
    var bw = Math.max(2, Math.floor(w * QUALITY.bloomScale));
    var bh = Math.max(2, Math.floor(h * QUALITY.bloomScale));
    var bopts = { type: THREE.HalfFloatType, format: THREE.RGBAFormat, depthBuffer: false, stencilBuffer: false };
    rtA = new THREE.WebGLRenderTarget(bw, bh, bopts);
    rtB = new THREE.WebGLRenderTarget(bw, bh, bopts);
    rtA.texture.minFilter = THREE.LinearFilter;
    rtB.texture.minFilter = THREE.LinearFilter;
  }

  function setSize(w, h) {
    if (!enabled) return;
    size.w = w;
    size.h = h;
    if (!rtScene) makeTargets(w, h);
    else {
      rtScene.setSize(w, h);
      var bw = Math.max(2, Math.floor(w * QUALITY.bloomScale));
      var bh = Math.max(2, Math.floor(h * QUALITY.bloomScale));
      rtA.setSize(bw, bh);
      rtB.setSize(bw, bh);
    }
  }

  function drawQuad(rendererRef, material, target) {
    quad.material = material;
    rendererRef.setRenderTarget(target);
    rendererRef.clear();
    rendererRef.render(quadScene, quadCam);
  }

  function render(dt) {
    if (!enabled || !QUALITY.bloom || !rtScene) {
      renderer.setRenderTarget(null);
      renderer.render(scene, camera);
      return;
    }

    renderer.setRenderTarget(rtScene);
    renderer.clear();
    renderer.render(scene, camera);

    brightMat.uniforms.tDiffuse.value = rtScene.texture;
    drawQuad(renderer, brightMat, rtA);

    var bw = rtA.width, bh = rtA.height;
    blurMat.uniforms.tDiffuse.value = rtA.texture;
    blurMat.uniforms.dir.value.set(1.4 / bw, 0);
    drawQuad(renderer, blurMat, rtB);

    blurMat.uniforms.tDiffuse.value = rtB.texture;
    blurMat.uniforms.dir.value.set(0, 1.4 / bh);
    drawQuad(renderer, blurMat, rtA);

    // second, wider pass (cheap two-level bloom)
    blurMat.uniforms.tDiffuse.value = rtA.texture;
    blurMat.uniforms.dir.value.set(2.6 / bw, 0);
    drawQuad(renderer, blurMat, rtB);

    blurMat.uniforms.tDiffuse.value = rtB.texture;
    blurMat.uniforms.dir.value.set(0, 2.6 / bh);
    drawQuad(renderer, blurMat, rtA);

    compMat.uniforms.tScene.value = rtScene.texture;
    compMat.uniforms.tBloom.value = rtA.texture;
    drawQuad(renderer, compMat, null);
  }

  return { setSize: setSize, render: render, enabled: enabled };
})();

// =============================================================================
// 4. Procedural textures
// =============================================================================
function makeGlowTexture(inner, outer, size) {
  var s = size || 128;
  var c = document.createElement('canvas');
  c.width = c.height = s;
  var g = c.getContext('2d');
  var grad = g.createRadialGradient(s / 2, s / 2, 0, s / 2, s / 2, s / 2);
  grad.addColorStop(0, inner);
  grad.addColorStop(0.45, outer);
  grad.addColorStop(1, 'rgba(0,0,0,0)');
  g.fillStyle = grad;
  g.fillRect(0, 0, s, s);
  var t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.SRGBColorSpace;
  return t;
}

function makeFloorTexture() {
  var s = 512;
  var c = document.createElement('canvas');
  c.width = c.height = s;
  var g = c.getContext('2d');

  g.fillStyle = '#0a1119';
  g.fillRect(0, 0, s, s);

  // faint panel noise
  for (var i = 0; i < 2600; i++) {
    var a = Math.random() * 0.05;
    g.fillStyle = 'rgba(120,190,255,' + a + ')';
    g.fillRect(Math.random() * s, Math.random() * s, 2, 2);
  }

  // grid
  g.strokeStyle = 'rgba(70,150,210,0.55)';
  g.lineWidth = 3;
  g.strokeRect(0, 0, s, s);
  g.strokeStyle = 'rgba(60,130,190,0.22)';
  g.lineWidth = 1;
  for (var k = 1; k < 4; k++) {
    var p = (s / 4) * k;
    g.beginPath(); g.moveTo(p, 0); g.lineTo(p, s); g.stroke();
    g.beginPath(); g.moveTo(0, p); g.lineTo(s, p); g.stroke();
  }

  var t = new THREE.CanvasTexture(c);
  t.wrapS = t.wrapT = THREE.RepeatWrapping;
  t.repeat.set(10, 10);
  t.anisotropy = 4;
  t.colorSpace = THREE.SRGBColorSpace;
  return t;
}

var glowTex = makeGlowTexture('rgba(180,250,255,0.95)', 'rgba(60,200,255,0.28)');
var sparkTex = makeGlowTexture('rgba(255,255,255,1)', 'rgba(255,200,120,0.35)', 64);

// =============================================================================
// 5. Particles
// =============================================================================
function ParticleSystem(max) {
  var positions = new Float32Array(max * 3);
  var colors = new Float32Array(max * 3);
  var sizes = new Float32Array(max);
  var alphas = new Float32Array(max);
  var vel = new Float32Array(max * 3);
  var life = new Float32Array(max);
  var lifeMax = new Float32Array(max);
  var gravity = new Float32Array(max);
  var drag = new Float32Array(max);
  var cursor = 0;

  var geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
  geo.setAttribute('aColor', new THREE.BufferAttribute(colors, 3));
  geo.setAttribute('aSize', new THREE.BufferAttribute(sizes, 1));
  geo.setAttribute('aAlpha', new THREE.BufferAttribute(alphas, 1));

  var mat = new THREE.ShaderMaterial({
    transparent: true,
    depthWrite: false,
    blending: THREE.AdditiveBlending,
    uniforms: { uTex: { value: sparkTex } },
    vertexShader: [
      'attribute vec3 aColor; attribute float aSize; attribute float aAlpha;',
      'varying vec3 vColor; varying float vAlpha;',
      'void main(){',
      '  vColor = aColor; vAlpha = aAlpha;',
      '  vec4 mv = modelViewMatrix * vec4(position, 1.0);',
      '  gl_PointSize = aSize * (340.0 / max(0.001, -mv.z));',
      '  gl_Position = projectionMatrix * mv;',
      '}'
    ].join('\n'),
    fragmentShader: [
      'uniform sampler2D uTex; varying vec3 vColor; varying float vAlpha;',
      'void main(){',
      '  vec4 t = texture2D(uTex, gl_PointCoord);',
      '  gl_FragColor = vec4(vColor * t.rgb * 1.6, t.a * vAlpha);',
      '}'
    ].join('\n')
  });

  var points = new THREE.Points(geo, mat);
  points.frustumCulled = false;
  scene.add(points);

  this.burst = function (pos, color, count, opts) {
    opts = opts || {};
    var speed = opts.speed != null ? opts.speed : 5.5;
    var size = opts.size != null ? opts.size : 0.5;
    var lifeS = opts.life != null ? opts.life : 0.55;
    var grav = opts.gravity != null ? opts.gravity : 8;
    var spread = opts.spread != null ? opts.spread : 1;
    var c = new THREE.Color(color);

    for (var i = 0; i < count; i++) {
      var idx = cursor;
      cursor = (cursor + 1) % max;

      var dir = new THREE.Vector3(rand(-1, 1), rand(-0.35, 1), rand(-1, 1)).normalize();
      var sp = speed * rand(0.35, 1.15);

      positions[idx * 3] = pos.x + rand(-0.1, 0.1) * spread;
      positions[idx * 3 + 1] = pos.y + rand(-0.1, 0.1) * spread;
      positions[idx * 3 + 2] = pos.z + rand(-0.1, 0.1) * spread;

      vel[idx * 3] = dir.x * sp;
      vel[idx * 3 + 1] = dir.y * sp;
      vel[idx * 3 + 2] = dir.z * sp;

      colors[idx * 3] = c.r;
      colors[idx * 3 + 1] = c.g;
      colors[idx * 3 + 2] = c.b;

      sizes[idx] = size * rand(0.6, 1.35);
      alphas[idx] = 1;
      life[idx] = lifeS * rand(0.7, 1.25);
      lifeMax[idx] = life[idx];
      gravity[idx] = grav;
      drag[idx] = opts.drag != null ? opts.drag : 2.2;
    }
  };

  this.stream = function (pos, color, dt, opts) {
    opts = opts || {};
    var rate = opts.rate || 40;
    var n = Math.max(1, Math.round(rate * dt));
    for (var i = 0; i < n; i++) {
      var idx = cursor;
      cursor = (cursor + 1) % max;
      var c = new THREE.Color(color);

      positions[idx * 3] = pos.x + rand(-0.12, 0.12);
      positions[idx * 3 + 1] = pos.y + rand(-0.12, 0.12);
      positions[idx * 3 + 2] = pos.z + rand(-0.12, 0.12);

      vel[idx * 3] = rand(-0.6, 0.6);
      vel[idx * 3 + 1] = rand(0.2, 1.4);
      vel[idx * 3 + 2] = rand(-0.6, 0.6);

      colors[idx * 3] = c.r;
      colors[idx * 3 + 1] = c.g;
      colors[idx * 3 + 2] = c.b;

      sizes[idx] = (opts.size || 0.32) * rand(0.6, 1.2);
      alphas[idx] = 0.9;
      life[idx] = (opts.life || 0.5) * rand(0.7, 1.2);
      lifeMax[idx] = life[idx];
      gravity[idx] = opts.gravity != null ? opts.gravity : -1.0;
      drag[idx] = 1.6;
    }
  };

  this.update = function (dt) {
    var any = false;
    for (var i = 0; i < max; i++) {
      if (life[i] <= 0) {
        if (alphas[i] !== 0) { alphas[i] = 0; any = true; }
        continue;
      }
      any = true;
      life[i] -= dt;
      var k = Math.max(0, life[i] / lifeMax[i]);

      var d = Math.exp(-drag[i] * dt);
      vel[i * 3] *= d;
      vel[i * 3 + 1] = vel[i * 3 + 1] * d - gravity[i] * dt;
      vel[i * 3 + 2] *= d;

      positions[i * 3] += vel[i * 3] * dt;
      positions[i * 3 + 1] += vel[i * 3 + 1] * dt;
      positions[i * 3 + 2] += vel[i * 3 + 2] * dt;

      if (positions[i * 3 + 1] < 0.04) {
        positions[i * 3 + 1] = 0.04;
        vel[i * 3 + 1] *= -0.32;
      }

      alphas[i] = k * k;
    }
    if (any) {
      geo.attributes.position.needsUpdate = true;
      geo.attributes.aColor.needsUpdate = true;
      geo.attributes.aSize.needsUpdate = true;
      geo.attributes.aAlpha.needsUpdate = true;
    }
  };
}

var FX = new ParticleSystem(QUALITY.particles);

// =============================================================================
// 6. Arena
// =============================================================================
var arena = { pulse: 0, rings: [], pillars: [] };

(function buildArena() {
  var R = CFG.arenaRadius;
  var floorTex = makeFloorTexture();

  var floorMat = new THREE.MeshStandardMaterial({
    map: floorTex,
    color: 0x9fb6cc,
    roughness: 0.82,
    metalness: 0.28,
    emissive: 0x0e3550,
    emissiveIntensity: 0.55,
    emissiveMap: floorTex
  });

  var floor = new THREE.Mesh(new THREE.CylinderGeometry(R + 0.2, R + 0.2, 0.7, 88), floorMat);
  floor.position.y = -0.35;
  floor.receiveShadow = true;
  scene.add(floor);

  // outer skirt so the arena reads as a disc floating in the dark
  var skirt = new THREE.Mesh(
    new THREE.CylinderGeometry(R + 0.2, R + 1.6, 1.6, 88, 1, true),
    new THREE.MeshStandardMaterial({ color: 0x0b1420, roughness: 0.7, metalness: 0.5, side: THREE.DoubleSide })
  );
  skirt.position.y = -1.4;
  scene.add(skirt);

  // walls
  var wallGeoSeg = (TAU * R) / (CFG.wallSegments * 2) + 0.5;
  var wallGeo = new THREE.BoxGeometry(wallGeoSeg, CFG.wallHeight, 0.55);
  var wallMat = new THREE.MeshStandardMaterial({ color: 0x223047, roughness: 0.65, metalness: 0.35 });
  var accentMat = new THREE.MeshStandardMaterial({
    color: 0x1b4f8a, emissive: 0x2fa8ff, emissiveIntensity: 1.5, roughness: 0.35, metalness: 0.4
  });

  var total = CFG.wallSegments * 2;
  for (var i = 0; i < total; i++) {
    var a = (TAU * i) / total;
    var accent = (i % 5) === 0;
    var seg = new THREE.Mesh(wallGeo, accent ? accentMat : wallMat);
    seg.position.set(Math.cos(a) * (R + 0.28), CFG.wallHeight / 2, Math.sin(a) * (R + 0.28));
    seg.rotation.y = -a;
    seg.castShadow = true;
    seg.receiveShadow = true;
    scene.add(seg);
  }

  // glowing top rail
  var rail = new THREE.Mesh(
    new THREE.TorusGeometry(R + 0.3, 0.09, 8, 120),
    new THREE.MeshStandardMaterial({ color: 0x0a2a44, emissive: 0x35d8ff, emissiveIntensity: 2.2, roughness: 0.3 })
  );
  rail.rotation.x = Math.PI / 2;
  rail.position.y = CFG.wallHeight;
  scene.add(rail);

  // pillars
  var pylonMat = new THREE.MeshStandardMaterial({
    color: 0x2a1a10, emissive: 0xff7a1f, emissiveIntensity: 1.05, roughness: 0.5, metalness: 0.45
  });
  var pylonGeo = new THREE.CylinderGeometry(0.52, 0.62, 3.2, 18);
  for (var p = 0; p < 12; p++) {
    var pa = (TAU * p) / 12;
    var px = Math.cos(pa) * (R - 2.7);
    var pz = Math.sin(pa) * (R - 2.7);
    var pyl = new THREE.Mesh(pylonGeo, pylonMat);
    pyl.position.set(px, 1.6, pz);
    pyl.castShadow = true;
    pyl.receiveShadow = true;
    scene.add(pyl);
    arena.pillars.push({ x: px, z: pz, r: 0.62 });
  }

  // marker rings on the floor
  var ringMat = new THREE.MeshBasicMaterial({
    color: 0x2fb4e0, transparent: true, opacity: 0.30, side: THREE.DoubleSide
  });
  [4.5, 9.5, 14.2].forEach(function (r) {
    var ring = new THREE.Mesh(new THREE.RingGeometry(r, r + 0.055, 128), ringMat);
    ring.rotation.x = -Math.PI / 2;
    ring.position.y = 0.02;
    scene.add(ring);
  });

  var centre = new THREE.Mesh(new THREE.RingGeometry(1.0, 1.12, 64), ringMat);
  centre.rotation.x = -Math.PI / 2;
  centre.position.y = 0.02;
  scene.add(centre);

  // arena pulse ring (used on wave start / pickup)
  var pulseMat = new THREE.MeshBasicMaterial({
    color: 0x54e8ff, transparent: true, opacity: 0, side: THREE.DoubleSide, blending: THREE.AdditiveBlending
  });
  var pulseRing = new THREE.Mesh(new THREE.RingGeometry(0.96, 1.0, 96), pulseMat);
  pulseRing.rotation.x = -Math.PI / 2;
  pulseRing.position.y = 0.03;
  scene.add(pulseRing);
  arena.pulseMesh = pulseRing;
  arena.pulseMat = pulseMat;

  // dust motes for depth
  if (QUALITY.dust) {
    var dustGeo = new THREE.BufferGeometry();
    var dustCount = 260;
    var dp = new Float32Array(dustCount * 3);
    for (var d = 0; d < dustCount; d++) {
      var ang = rand(0, TAU);
      var rad = rand(2, R - 1);
      dp[d * 3] = Math.cos(ang) * rad;
      dp[d * 3 + 1] = rand(0.4, 7);
      dp[d * 3 + 2] = Math.sin(ang) * rad;
    }
    dustGeo.setAttribute('position', new THREE.BufferAttribute(dp, 3));
    var dustMat = new THREE.PointsMaterial({
      size: 0.06, color: 0x8fd8ff, transparent: true, opacity: 0.5,
      blending: THREE.AdditiveBlending, depthWrite: false, sizeAttenuation: true
    });
    var dust = new THREE.Points(dustGeo, dustMat);
    scene.add(dust);
    arena.dust = dust;
  }
})();

function arenaPulse(color) {
  arena.pulse = 1;
  arena.pulseMat.color.set(color || 0x54e8ff);
}

// =============================================================================
// 7. Player
// =============================================================================
function Player() {
  this.root = new THREE.Group();
  scene.add(this.root);

  var skin = new THREE.MeshStandardMaterial({ color: 0x2456c8, roughness: 0.4, metalness: 0.45, emissive: 0x0a2a6a, emissiveIntensity: 0.35 });
  var trim = new THREE.MeshStandardMaterial({ color: 0x14203a, roughness: 0.55, metalness: 0.6, emissive: 0x143a6a, emissiveIntensity: 0.28 });
  var glow = new THREE.MeshStandardMaterial({ color: 0x8ff4ff, emissive: 0x5be9ff, emissiveIntensity: 1.7, roughness: 0.2 });

  this.materials = [skin, trim];

  var hips = new THREE.Group();
  hips.position.y = 0.92;
  this.root.add(hips);
  this.hips = hips;

  var torso = new THREE.Mesh(new THREE.CapsuleGeometry(0.27, 0.42, 6, 14), skin);
  torso.position.y = 0.26;
  torso.castShadow = true;
  hips.add(torso);
  this.torso = torso;

  var chestLight = new THREE.Mesh(new THREE.SphereGeometry(0.06, 10, 8), glow);
  chestLight.position.set(0, 0.34, 0.24);
  hips.add(chestLight);

  var head = new THREE.Mesh(new THREE.SphereGeometry(0.23, 20, 16), trim);
  head.position.y = 0.72;
  head.castShadow = true;
  hips.add(head);
  this.head = head;

  var visor = new THREE.Mesh(new THREE.BoxGeometry(0.3, 0.07, 0.06), glow);
  visor.position.set(0, 0.74, 0.19);
  hips.add(visor);

  // arms
  this.arms = [];
  for (var s = -1; s <= 1; s += 2) {
    var shoulder = new THREE.Group();
    shoulder.position.set(0.31 * s, 0.42, 0);
    var upper = new THREE.Mesh(new THREE.CapsuleGeometry(0.075, 0.28, 4, 8), trim);
    upper.position.y = -0.19;
    upper.castShadow = true;
    shoulder.add(upper);
    var hand = new THREE.Mesh(new THREE.SphereGeometry(0.085, 10, 8), skin);
    hand.position.y = -0.4;
    shoulder.add(hand);
    hips.add(shoulder);
    this.arms.push(shoulder);
  }

  // weapon arm gets a blade of light
  var blade = new THREE.Mesh(new THREE.BoxGeometry(0.07, 0.85, 0.07), glow);
  blade.position.y = -0.72;
  this.arms[0].add(blade);
  this.blade = blade;

  // legs
  this.legs = [];
  for (var l = -1; l <= 1; l += 2) {
    var hip = new THREE.Group();
    hip.position.set(0.13 * l, 0.0, 0);
    var leg = new THREE.Mesh(new THREE.CapsuleGeometry(0.085, 0.4, 4, 8), trim);
    leg.position.y = -0.28;
    leg.castShadow = true;
    hip.add(leg);
    var foot = new THREE.Mesh(new THREE.BoxGeometry(0.16, 0.08, 0.26), skin);
    foot.position.set(0, -0.5, 0.05);
    hip.add(foot);
    hips.add(hip);
    this.legs.push(hip);
  }

  // ground ring
  var ring = new THREE.Mesh(
    new THREE.RingGeometry(0.5, 0.6, 40),
    new THREE.MeshBasicMaterial({ color: 0x54e8ff, transparent: true, opacity: 0.55, side: THREE.DoubleSide })
  );
  ring.rotation.x = -Math.PI / 2;
  ring.position.y = 0.035;
  this.root.add(ring);
  this.ring = ring;

  // soft glow sprite
  var spr = new THREE.Sprite(new THREE.SpriteMaterial({
    map: glowTex, color: 0x2f9dff, transparent: true, opacity: 0.22,
    blending: THREE.AdditiveBlending, depthWrite: false
  }));
  spr.scale.set(2.1, 2.1, 1);
  spr.position.y = 0.9;
  this.root.add(spr);

  this.pos = new THREE.Vector3(0, 0, 0);
  this.vel = new THREE.Vector3();
  this.knock = new THREE.Vector3();
  this.yaw = Math.PI;
  this.onGround = true;
  this.grounded = true;

  this.stats = {
    maxHealth: CFG.maxHealth,
    health: CFG.maxHealth,
    damage: CFG.attackDamage,
    attackCooldown: CFG.attackCooldown,
    moveSpeed: CFG.walkSpeed,
    sprintSpeed: CFG.sprintSpeed,
    dashCooldown: CFG.dashCooldown,
    lifesteal: 0,
    range: CFG.attackRange,
    arc: CFG.attackArc,
    comboWindow: CFG.comboWindow
  };

  this.dead = false;
  this.sprinting = false;
  this.lastDamage = -999;
  this.attackTimer = 0;
  this.queuedAttack = false;
  this.comboIndex = 0;
  this.comboTimer = 0;
  this.dashTimer = 0;
  this.dashCd = 0;
  this.invuln = 0;
  this.runPhase = 0;
  this.attackAnim = 0;
  this.squash = 1;
  this.flash = 0;
}

Player.prototype.forward = function () {
  return new THREE.Vector3(-Math.sin(camYaw), 0, -Math.cos(camYaw));
};
Player.prototype.right = function () {
  return new THREE.Vector3(Math.cos(camYaw), 0, -Math.sin(camYaw));
};

Player.prototype.hurt = function (amount, fromX, fromZ) {
  if (this.dead || this.invuln > 0) return false;
  if (game.time - this.lastDamage < CFG.damageCooldown) return false;

  this.lastDamage = game.time;
  this.stats.health = Math.max(0, this.stats.health - amount);
  this.flash = 1;
  game.shake = Math.min(1.2, game.shake + 0.35);
  game.hitStop = Math.max(game.hitStop, 0.05);
  breakCombo();

  var dx = this.pos.x - fromX;
  var dz = this.pos.z - fromZ;
  var len = Math.hypot(dx, dz) || 1;
  this.knock.set((dx / len) * CFG.knockback, 2.2, (dz / len) * CFG.knockback);

  FX.burst(new THREE.Vector3(this.pos.x, this.pos.y + 1.0, this.pos.z), 0xff4a3a, 16, { speed: 5, size: 0.5, life: 0.5 });
  sfxHurt();
  flashHurt();

  if (this.stats.health <= 0) this.die();
  return true;
};

Player.prototype.die = function () {
  this.dead = true;
  this.stats.health = 0;
  this.root.visible = false;
  game.hitStop = 0.18;
  game.shake = 1.4;
  FX.burst(new THREE.Vector3(this.pos.x, this.pos.y + 0.9, this.pos.z), 0x6fd8ff, 70, { speed: 9, size: 0.8, life: 1.1, gravity: 5 });
  sfxDeath();
  onPlayerDied();
};

Player.prototype.tryAttack = function () {
  if (this.dead) return;
  if (this.attackTimer > 0) {
    // buffer the input: if it lands in the last 45% of the cooldown it still fires
    if (this.attackTimer < this.stats.attackCooldown * 0.45) this.queuedAttack = true;
    return;
  }

  this.attackTimer = this.stats.attackCooldown;
  this.comboIndex = this.attackTimerCombo();
  this.attackAnim = 1;
  this.comboTimer = this.stats.comboWindow;

  var dmg = this.stats.damage * (this.comboIndex === 2 ? 1.45 : 1);
  var range = this.stats.range * (this.comboIndex === 2 ? 1.12 : 1);

  var fwd = new THREE.Vector3(Math.sin(this.yaw), 0, Math.cos(this.yaw));
  var hitAny = false;

  for (var i = enemies.length - 1; i >= 0; i--) {
    var e = enemies[i];
    var dx = e.pos.x - this.pos.x;
    var dz = e.pos.z - this.pos.z;
    var dist = Math.hypot(dx, dz);
    if (dist > range + e.radius) continue;

    var ang = Math.atan2(dx, dz);
    var diff = Math.abs(angleDelta(this.yaw, ang));
    if (diff > (this.stats.arc * Math.PI / 180) * 0.5) continue;

    var heavy = this.comboIndex === 2;
    e.hurt(dmg, this.pos.x, this.pos.z, heavy);
    hitAny = true;

    if (this.stats.lifesteal > 0 && !this.dead) {
      this.stats.health = Math.min(this.stats.maxHealth, this.stats.health + this.stats.lifesteal);
    }
  }

  // swing arc vfx
  var arc = new THREE.Mesh(
    new THREE.RingGeometry(range * 0.55, range, 26, 1, -this.stats.arc * Math.PI / 360, this.stats.arc * Math.PI / 180),
    new THREE.MeshBasicMaterial({
      color: this.comboIndex === 2 ? 0xffc46b : 0x7fe9ff,
      transparent: true, opacity: 0.85, side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending, depthWrite: false
    })
  );
  arc.rotation.x = -Math.PI / 2;
  arc.rotation.z = -this.yaw + Math.PI / 2;
  arc.position.set(this.pos.x, this.pos.y + 0.95, this.pos.z);
  scene.add(arc);
  vfx.push({ mesh: arc, life: 0.18, max: 0.18, kind: 'arc' });

  FX.burst(new THREE.Vector3(this.pos.x + fwd.x * 1.1, this.pos.y + 1.0, this.pos.z + fwd.z * 1.1),
    this.comboIndex === 2 ? 0xffb347 : 0x7fe9ff, hitAny ? 16 : 8, { speed: 4.5, size: 0.42, life: 0.3, gravity: 2 });

  if (hitAny) {
    game.hitStop = Math.max(game.hitStop, CFG.hitStop + (this.comboIndex === 2 ? 0.03 : 0));
    game.shake = Math.min(1.3, game.shake + 0.22);
    sfxHit(this.comboIndex === 2);
  } else {
    sfxSwing();
  }
};

Player.prototype.attackTimerCombo = function () {
  var idx = this.comboTimer > 0 ? (this.comboIndex + 1) % 3 : 0;
  return idx;
};

Player.prototype.tryDash = function () {
  if (this.dead || this.dashCd > 0 || this.dashTimer > 0) return;

  this.dashTimer = CFG.dashTime;
  this.dashCd = this.stats.dashCooldown;
  this.invuln = CFG.dashInvuln;
  game.shake = Math.min(1.0, game.shake + 0.12);
  game.fovKick = Math.max(game.fovKick, 9);
  sfxDash();

  FX.burst(new THREE.Vector3(this.pos.x, this.pos.y + 0.6, this.pos.z), 0x4ad8ff, 22, { speed: 6, size: 0.55, life: 0.35, gravity: 0 });
};

Player.prototype.jump = function () {
  if (this.dead || !this.onGround) return;
  this.vel.y = CFG.jumpVel;
  this.onGround = false;
  this.squash = 0.82;
  FX.burst(new THREE.Vector3(this.pos.x, this.pos.y + 0.1, this.pos.z), 0x9fe9ff, 10, { speed: 2.5, size: 0.35, life: 0.3, gravity: 2 });
  sfxJump();
};

Player.prototype.update = function (dt, moveX, moveZ, sprinting) {
  if (this.dead) return;

  this.invuln = Math.max(0, this.invuln - dt);
  this.attackTimer = Math.max(0, this.attackTimer - dt);
  if (this.attackTimer === 0 && this.queuedAttack) {
    this.queuedAttack = false;
    this.tryAttack();
  }
  this.comboTimer = Math.max(0, this.comboTimer - dt);
  this.dashCd = Math.max(0, this.dashCd - dt);
  this.attackAnim = Math.max(0, this.attackAnim - dt * 5.5);
  this.flash = Math.max(0, this.flash - dt * 4);

  var speed = sprinting ? this.stats.sprintSpeed : this.stats.moveSpeed;
  this.sprinting = sprinting;

  var dir = new THREE.Vector3()
    .addScaledVector(this.forward(), moveZ)
    .addScaledVector(this.right(), moveX);

  var mag = Math.min(1, dir.length());
  if (mag > 0.01) dir.normalize();

  if (this.dashTimer > 0) {
    this.dashTimer -= dt;
    var dashDir = new THREE.Vector3(this.vel.x, 0, this.vel.z);
    if (dashDir.lengthSq() < 0.01) dashDir.copy(this.forward());
    dashDir.normalize();
    this.vel.x = dashDir.x * CFG.dashSpeed;
    this.vel.z = dashDir.z * CFG.dashSpeed;
    FX.stream(new THREE.Vector3(this.pos.x, this.pos.y + 0.8, this.pos.z), 0x3fd8ff, dt, { rate: 60, size: 0.5, life: 0.35, gravity: 0 });
  } else {
    var targetVX = dir.x * speed * mag;
    var targetVZ = dir.z * speed * mag;
    var accel = this.onGround ? 16 : 6;
    this.vel.x = damp(this.vel.x, targetVX, accel, dt);
    this.vel.z = damp(this.vel.z, targetVZ, accel, dt);
  }

  if (mag > 0.05 && this.dashTimer <= 0) {
    var targetYaw = Math.atan2(dir.x, dir.z);
    this.yaw += angleDelta(this.yaw, targetYaw) * Math.min(1, 16 * dt);
  }

  this.vel.y -= CFG.gravity * dt;

  this.pos.x += (this.vel.x + this.knock.x) * dt;
  this.pos.z += (this.vel.z + this.knock.z) * dt;
  this.pos.y += (this.vel.y + this.knock.y) * dt;

  this.knock.multiplyScalar(Math.exp(-6 * dt));

  if (this.pos.y <= 0) {
    if (!this.onGround && this.vel.y < -6) {
      this.squash = 1.18;
      FX.burst(new THREE.Vector3(this.pos.x, 0.1, this.pos.z), 0x9fe9ff, 12, { speed: 3, size: 0.4, life: 0.32, gravity: 4 });
      game.shake = Math.min(1, game.shake + 0.08);
    }
    this.pos.y = 0;
    this.vel.y = 0;
    this.knock.y = 0;
    this.onGround = true;
  } else {
    this.onGround = false;
  }

  // arena bounds + pillars
  var flat = Math.hypot(this.pos.x, this.pos.z);
  var maxR = CFG.arenaRadius - 0.9;
  if (flat > maxR) {
    this.pos.x *= maxR / flat;
    this.pos.z *= maxR / flat;
    this.vel.x *= 0.35;
    this.vel.z *= 0.35;
  }
  for (var i = 0; i < arena.pillars.length; i++) {
    var p = arena.pillars[i];
    var dx = this.pos.x - p.x;
    var dz = this.pos.z - p.z;
    var d = Math.hypot(dx, dz);
    var min = p.r + CFG.playerRadius;
    if (d < min && d > 0.0001) {
      this.pos.x = p.x + (dx / d) * min;
      this.pos.z = p.z + (dz / d) * min;
    }
  }

  // regen out of combat
  if (this.stats.health < this.stats.maxHealth && (game.time - this.lastDamage) > CFG.regenDelay) {
    this.stats.health = Math.min(this.stats.maxHealth, this.stats.health + CFG.regen * dt);
  }

  // ---- animation ----
  var planarSpeed = Math.hypot(this.vel.x, this.vel.z);
  var speedNorm = clamp(planarSpeed / this.stats.sprintSpeed, 0, 1);

  this.root.position.copy(this.pos);
  this.root.rotation.y = this.yaw;

  this.squash = damp(this.squash, 1, 9, dt);
  this.root.scale.set(1 / Math.sqrt(this.squash), this.squash, 1 / Math.sqrt(this.squash));

  if (this.onGround) {
    this.runPhase += dt * (4 + speedNorm * 11);
    var swing = Math.sin(this.runPhase) * (0.15 + speedNorm * 0.85);
    this.legs[0].rotation.x = swing;
    this.legs[1].rotation.x = -swing;
    this.arms[1].rotation.x = -swing * 0.8;
    this.arms[0].rotation.x = swing * 0.8;
    this.hips.position.y = 0.92 + Math.abs(Math.sin(this.runPhase * 2)) * 0.03 * speedNorm;
    this.torso.rotation.x = -0.1 * speedNorm;
  } else {
    this.legs[0].rotation.x = damp(this.legs[0].rotation.x, -0.55, 9, dt);
    this.legs[1].rotation.x = damp(this.legs[1].rotation.x, 0.3, 9, dt);
    this.arms[0].rotation.x = damp(this.arms[0].rotation.x, -0.7, 9, dt);
    this.arms[1].rotation.x = damp(this.arms[1].rotation.x, -0.7, 9, dt);
  }

  // attack swing overrides the weapon arm
  if (this.attackAnim > 0) {
    var t = 1 - this.attackAnim;
    var swingT = Math.sin(t * Math.PI);
    this.arms[0].rotation.x = -1.9 * swingT;
    this.arms[0].rotation.z = 0.9 * swingT;
    this.hips.rotation.y = 0.35 * swingT;
  } else {
    this.hips.rotation.y = damp(this.hips.rotation.y, 0, 10, dt);
    this.arms[0].rotation.z = damp(this.arms[0].rotation.z, 0, 10, dt);
  }

  this.ring.material.opacity = 0.35 + speedNorm * 0.35;
  this.ring.rotation.z += dt * (1 + speedNorm * 3);

  // hit flash
  var flash = this.flash;
  for (var m = 0; m < this.materials.length; m++) {
    this.materials[m].emissive.setRGB(0.04 + flash * 0.9, 0.2 + flash * 0.1, 0.5);
    this.materials[m].emissiveIntensity = 0.35 + flash * 3.2;
  }
};

var player = new Player();

// =============================================================================
// 8. Game state
// =============================================================================
var game = {
  state: 'menu',            // menu | playing | upgrade | dead | paused
  time: 0,
  score: 0,
  best: 0,
  wave: 1,
  cores: 0, coresTotal: 0,
  combo: 0,
  comboTimer: 0,
  comboMult: 1,
  shake: 0,
  hitStop: 0,
  fovKick: 0,
  slowmo: 0,
  spawnTimer: 0,
  upgrades: {},
  boss: null,
  waveBanner: 0
};

try {
  var stored = parseInt(localStorage.getItem('arenaRunnerBestV2') || '0', 10);
  if (!isNaN(stored)) game.best = stored;
} catch (e) { /* ignore */ }

var enemies = [];
var cores = [];
var projectiles = [];
var vfx = [];

var camYaw = Math.PI;
var camPitch = 0.26;
var camPos = new THREE.Vector3(0, 3, 7);
var camLook = new THREE.Vector3(0, 1.4, 0);

// NOTE: breakCombo / onPlayerDied / sfx* / flashHurt live in part 2.
// They are function declarations, so they are hoisted across the whole bundle.

// Arena Runner — WebGL edition (part 2: enemies, waves, upgrades, HUD, input, loop)

// =============================================================================
// 9. Audio — procedural, no asset files
// =============================================================================
var audioCtx = null;

function initAudio() {
  if (audioCtx) return;
  try {
    var Ctx = window.AudioContext || window.webkitAudioContext;
    if (Ctx) audioCtx = new Ctx();
  } catch (e) { audioCtx = null; }
}

function tone(freq, dur, type, gain, slideTo) {
  if (!audioCtx) return;
  try {
    var t0 = audioCtx.currentTime;
    var osc = audioCtx.createOscillator();
    var amp = audioCtx.createGain();
    osc.type = type || 'sine';
    osc.frequency.setValueAtTime(freq, t0);
    if (slideTo) osc.frequency.exponentialRampToValueAtTime(Math.max(20, slideTo), t0 + dur);
    amp.gain.setValueAtTime(0.0001, t0);
    amp.gain.exponentialRampToValueAtTime(gain || 0.05, t0 + 0.012);
    amp.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    osc.connect(amp).connect(audioCtx.destination);
    osc.start(t0);
    osc.stop(t0 + dur + 0.03);
  } catch (e) { /* ignore */ }
}

function noiseBurst(dur, gain, filterFreq) {
  if (!audioCtx) return;
  try {
    var t0 = audioCtx.currentTime;
    var len = Math.floor(audioCtx.sampleRate * dur);
    var buf = audioCtx.createBuffer(1, len, audioCtx.sampleRate);
    var data = buf.getChannelData(0);
    for (var i = 0; i < len; i++) data[i] = (Math.random() * 2 - 1) * (1 - i / len);
    var src = audioCtx.createBufferSource();
    src.buffer = buf;
    var filter = audioCtx.createBiquadFilter();
    filter.type = 'bandpass';
    filter.frequency.value = filterFreq || 1200;
    var amp = audioCtx.createGain();
    amp.gain.value = gain || 0.05;
    src.connect(filter).connect(amp).connect(audioCtx.destination);
    src.start(t0);
  } catch (e) { /* ignore */ }
}

function sfxPickup() { tone(760, 0.10, 'triangle', 0.045, 1180); tone(1520, 0.09, 'sine', 0.025); }
function sfxWave() { tone(392, 0.16, 'square', 0.035); setTimeout(function () { tone(587, 0.2, 'square', 0.035); }, 120); setTimeout(function () { tone(784, 0.26, 'square', 0.03); }, 240); }
function sfxHurt() { tone(180, 0.18, 'sawtooth', 0.06, 90); noiseBurst(0.14, 0.05, 900); }
function sfxDeath() { tone(220, 0.5, 'sawtooth', 0.07, 60); noiseBurst(0.5, 0.06, 500); }
function sfxHit(heavy) { noiseBurst(0.09, heavy ? 0.075 : 0.05, heavy ? 700 : 1400); tone(heavy ? 120 : 220, 0.09, 'square', 0.035, heavy ? 70 : 160); }
function sfxSwing() { noiseBurst(0.06, 0.022, 2600); }
function sfxDash() { tone(520, 0.12, 'sine', 0.035, 220); noiseBurst(0.12, 0.03, 1800); }
function sfxJump() { tone(420, 0.1, 'sine', 0.028, 620); }
function sfxKill() { tone(150, 0.16, 'square', 0.045, 80); noiseBurst(0.16, 0.045, 800); }
function sfxBoss() { tone(70, 0.9, 'sawtooth', 0.07, 45); noiseBurst(0.8, 0.05, 300); }
function sfxUpgrade() { tone(523, 0.12, 'triangle', 0.04); setTimeout(function () { tone(784, 0.16, 'triangle', 0.04); }, 110); setTimeout(function () { tone(1046, 0.22, 'triangle', 0.035); }, 220); }

// =============================================================================
// 10. Enemies
// =============================================================================
function makeHunterMesh() {
  var g = new THREE.Group();
  var core = new THREE.MeshStandardMaterial({
    color: 0x8f160c, emissive: 0xff3a1a, emissiveIntensity: 1.5, roughness: 0.35, metalness: 0.4
  });
  var body = new THREE.Mesh(new THREE.SphereGeometry(0.55, 20, 16), core);
  body.castShadow = true;
  g.add(body);
  var ring = new THREE.Mesh(
    new THREE.TorusGeometry(0.82, 0.035, 8, 36),
    new THREE.MeshBasicMaterial({ color: 0xff7a33, transparent: true, opacity: 0.9 })
  );
  ring.rotation.x = Math.PI / 2;
  g.add(ring);
  return { group: g, ring: ring, body: body, material: core };
}

function makeChargerMesh() {
  var g = new THREE.Group();
  var mat = new THREE.MeshStandardMaterial({
    color: 0x8a4a08, emissive: 0xff9a20, emissiveIntensity: 1.2, roughness: 0.42, metalness: 0.45
  });
  var body = new THREE.Mesh(new THREE.OctahedronGeometry(0.62, 0), mat);
  body.castShadow = true;
  g.add(body);
  for (var i = 0; i < 3; i++) {
    var spike = new THREE.Mesh(new THREE.ConeGeometry(0.13, 0.5, 8), mat);
    var a = (TAU * i) / 3;
    spike.position.set(Math.cos(a) * 0.42, 0.1, Math.sin(a) * 0.42);
    spike.rotation.z = Math.PI / 2;
    spike.rotation.y = -a;
    g.add(spike);
  }
  var ring = new THREE.Mesh(
    new THREE.TorusGeometry(0.9, 0.03, 8, 32),
    new THREE.MeshBasicMaterial({ color: 0xffb066, transparent: true, opacity: 0.75 })
  );
  ring.rotation.x = Math.PI / 2;
  g.add(ring);
  return { group: g, ring: ring, body: body, material: mat };
}

function makeSpitterMesh() {
  var g = new THREE.Group();
  var mat = new THREE.MeshStandardMaterial({
    color: 0x4a1460, emissive: 0xc23bff, emissiveIntensity: 1.35, roughness: 0.3, metalness: 0.5
  });
  var body = new THREE.Mesh(new THREE.IcosahedronGeometry(0.5, 0), mat);
  body.castShadow = true;
  g.add(body);
  var orbits = [];
  for (var i = 0; i < 3; i++) {
    var orb = new THREE.Mesh(
      new THREE.SphereGeometry(0.09, 8, 6),
      new THREE.MeshBasicMaterial({ color: 0xf0a6ff })
    );
    g.add(orb);
    orbits.push(orb);
  }
  return { group: g, orbits: orbits, body: body, material: mat };
}

function makeBossMesh() {
  var g = new THREE.Group();
  var mat = new THREE.MeshStandardMaterial({
    color: 0x3a0a14, emissive: 0xff1f4a, emissiveIntensity: 1.25, roughness: 0.35, metalness: 0.6
  });
  var core = new THREE.Mesh(new THREE.SphereGeometry(1.25, 28, 22), mat);
  core.castShadow = true;
  g.add(core);

  var ringA = new THREE.Mesh(
    new THREE.TorusGeometry(1.85, 0.09, 10, 64),
    new THREE.MeshBasicMaterial({ color: 0xff6a8a, transparent: true, opacity: 0.85 })
  );
  ringA.rotation.x = Math.PI / 2.4;
  g.add(ringA);

  var ringB = new THREE.Mesh(
    new THREE.TorusGeometry(2.15, 0.05, 8, 64),
    new THREE.MeshBasicMaterial({ color: 0xffb04a, transparent: true, opacity: 0.6 })
  );
  ringB.rotation.x = Math.PI / 1.7;
  g.add(ringB);

  var crown = new THREE.Group();
  for (var i = 0; i < 6; i++) {
    var spike = new THREE.Mesh(new THREE.ConeGeometry(0.16, 0.75, 8), mat);
    var a = (TAU * i) / 6;
    spike.position.set(Math.cos(a) * 1.15, 0.85, Math.sin(a) * 1.15);
    spike.rotation.z = -Math.cos(a) * 0.4;
    spike.rotation.x = Math.sin(a) * 0.4;
    crown.add(spike);
  }
  g.add(crown);

  return { group: g, ringA: ringA, ringB: ringB, crown: crown, body: core, material: mat };
}

function Enemy(type, x, z) {
  this.type = type;
  this.pos = new THREE.Vector3(x, 0, z);
  this.vel = new THREE.Vector3();
  this.hitFlash = 0;
  this.dead = false;
  this.t = rand(0, 10);
  this.state = 'idle';
  this.stateTimer = 0;
  this.attackTimer = rand(0.6, 2.0);

  if (type === 'hunter') {
    this.radius = CFG.hunterRadius;
    this.hp = this.maxHp = CFG.hunterHp + Math.max(0, game.wave - 1) * 5;
    this.speed = CFG.hunterSpeed + Math.max(0, game.wave - 1) * 0.07;
    this.damage = CFG.hunterDamage;
    this.score = CFG.hunterScore;
    this.mesh = makeHunterMesh();
    this.hover = 1.05;
  } else if (type === 'charger') {
    this.radius = CFG.chargerRadius;
    this.hp = this.maxHp = CFG.chargerHp + Math.max(0, game.wave - 1) * 9;
    this.speed = CFG.chargerSpeed;
    this.damage = CFG.chargerDamage;
    this.score = CFG.chargerScore;
    this.mesh = makeChargerMesh();
    this.hover = 0.85;
  } else if (type === 'spitter') {
    this.radius = CFG.spitterRadius;
    this.hp = this.maxHp = CFG.spitterHp + Math.max(0, game.wave - 1) * 7;
    this.speed = CFG.spitterSpeed;
    this.damage = CFG.spitterDamage;
    this.score = CFG.spitterScore;
    this.mesh = makeSpitterMesh();
    this.hover = 1.35;
  } else {
    this.radius = CFG.bossRadius;
    this.hp = this.maxHp = CFG.bossHp + Math.max(0, game.wave - CFG.bossEvery) * 120;
    this.speed = CFG.bossSpeed;
    this.damage = CFG.bossDamage;
    this.score = CFG.bossScore;
    this.mesh = makeBossMesh();
    this.hover = 1.9;
    this.shockTimer = 3.2;
    this.summonTimer = 6.5;
    this.state = 'idle';
  }

  this.mesh.group.position.copy(this.pos);
  scene.add(this.mesh.group);
}

Enemy.prototype.hurt = function (amount, fromX, fromZ, heavy) {
  if (this.dead) return;
  this.hp -= amount;
  this.hitFlash = 1;

  var dx = this.pos.x - fromX;
  var dz = this.pos.z - fromZ;
  var len = Math.hypot(dx, dz) || 1;
  var push = heavy ? 4.2 : 2.4;
  if (this.type !== 'boss') {
    this.vel.x += (dx / len) * push;
    this.vel.z += (dz / len) * push;
  }

  FX.burst(new THREE.Vector3(this.pos.x, this.hover, this.pos.z), this.type === 'boss' ? 0xff5c7a : 0xffd08a, 10,
    { speed: 5, size: 0.42, life: 0.35, gravity: 6 });

  if (this.hp <= 0) this.kill();
};

Enemy.prototype.kill = function () {
  if (this.dead) return;
  this.dead = true;
  scene.remove(this.mesh.group);

  var color = this.type === 'boss' ? 0xff4a7a : (this.type === 'charger' ? 0xffa347 : (this.type === 'spitter' ? 0xd06bff : 0xff6a4a));
  FX.burst(new THREE.Vector3(this.pos.x, this.hover, this.pos.z), color, this.type === 'boss' ? 160 : 26,
    { speed: this.type === 'boss' ? 12 : 7, size: this.type === 'boss' ? 1.0 : 0.55, life: this.type === 'boss' ? 1.3 : 0.6, gravity: 7 });

  addComboKill(this);
  game.score += Math.round(this.score * game.comboMult);
  sfxKill();
  game.shake = Math.min(1.4, game.shake + (this.type === 'boss' ? 1.2 : 0.18));
  game.hitStop = Math.max(game.hitStop, this.type === 'boss' ? 0.22 : 0.07);

  if (this.type === 'boss') {
    game.boss = null;
    setBossBar(null);
    showMessage('WARDEN DESTROYED', '#ffd166', 2.6);
    arenaPulse(0xff6a8a);
    onWaveCleared();
  }

  // small chance to drop health
  if (Math.random() < 0.16 && player.stats.health < player.stats.maxHealth) {
    player.stats.health = Math.min(player.stats.maxHealth, player.stats.health + 8);
    FX.burst(new THREE.Vector3(player.pos.x, player.pos.y + 1, player.pos.z), 0x4dffa6, 12, { speed: 2, size: 0.4, life: 0.6, gravity: -2 });
  }
};

Enemy.prototype.update = function (dt) {
  if (this.dead) return;

  this.t += dt;
  this.hitFlash = Math.max(0, this.hitFlash - dt * 4);

  var dx = player.pos.x - this.pos.x;
  var dz = player.pos.z - this.pos.z;
  var dist = Math.hypot(dx, dz) || 0.0001;
  var nx = dx / dist;
  var nz = dz / dist;

  var desiredX = 0;
  var desiredZ = 0;

  if (this.type === 'hunter') {
    desiredX = nx * this.speed;
    desiredZ = nz * this.speed;
  } else if (this.type === 'charger') {
    this.stateTimer -= dt;

    if (this.state === 'idle') {
      desiredX = nx * this.speed;
      desiredZ = nz * this.speed;
      if (dist < 9 && this.stateTimer <= 0) {
        this.state = 'wind';
        this.stateTimer = 0.75;
        this.targetX = player.pos.x;
        this.targetZ = player.pos.z;
      }
    } else if (this.state === 'wind') {
      desiredX = 0;
      desiredZ = 0;
      if (this.stateTimer <= 0) {
        this.state = 'dash';
        this.stateTimer = 0.45;
        var ax = this.targetX - this.pos.x;
        var az = this.targetZ - this.pos.z;
        var al = Math.hypot(ax, az) || 1;
        this.dirX = ax / al;
        this.dirZ = az / al;
        sfxSwing();
      }
    } else if (this.state === 'dash') {
      desiredX = this.dirX * CFG.chargerDash;
      desiredZ = this.dirZ * CFG.chargerDash;
      if (Math.random() < dt * 40) {
        FX.stream(new THREE.Vector3(this.pos.x, 0.4, this.pos.z), 0xffa347, dt, { rate: 40, size: 0.4, life: 0.28, gravity: 0 });
      }
      if (this.stateTimer <= 0) {
        this.state = 'recover';
        this.stateTimer = 0.9;
      }
    } else {
      desiredX = -nx * this.speed * 0.4;
      desiredZ = -nz * this.speed * 0.4;
      if (this.stateTimer <= 0) {
        this.state = 'idle';
        this.stateTimer = 0.2;
      }
    }
  } else if (this.type === 'spitter') {
    var want = 10.5;
    if (dist > want + 1.5) {
      desiredX = nx * this.speed;
      desiredZ = nz * this.speed;
    } else if (dist < want - 1.5) {
      desiredX = -nx * this.speed;
      desiredZ = -nz * this.speed;
    }
    // strafe
    desiredX += -nz * this.speed * 0.45;
    desiredZ += nx * this.speed * 0.45;

    this.attackTimer -= dt;
    if (this.attackTimer <= 0 && dist < 22) {
      this.attackTimer = Math.max(1.1, 2.5 - game.wave * 0.06);
      fireProjectile(this.pos.x, this.hover, this.pos.z, nx, nz, this.damage);
    }
  } else if (this.type === 'boss') {
    desiredX = nx * this.speed;
    desiredZ = nz * this.speed;

    this.shockTimer -= dt;
    this.summonTimer -= dt;

    if (this.shockTimer <= 0) {
      this.shockTimer = Math.max(2.6, 4.6 - game.wave * 0.05);
      spawnShockwave(this.pos.x, this.pos.z, this.damage * 0.8);
      fxRing(this.pos.x, this.pos.z, 0xff4a6a, 0.09);
      sfxBoss();
      game.shake = Math.min(1.5, game.shake + 0.5);
    }

    if (this.summonTimer <= 0) {
      this.summonTimer = Math.max(6, 9 - game.wave * 0.1);
      for (var s = 0; s < 3; s++) {
        var a = rand(0, TAU);
        var sx = this.pos.x + Math.cos(a) * 3.2;
        var sz = this.pos.z + Math.sin(a) * 3.2;
        var lim = CFG.arenaRadius - 1.5;
        var fl = Math.hypot(sx, sz);
        if (fl > lim) { sx *= lim / fl; sz *= lim / fl; }
        enemies.push(new Enemy('hunter', sx, sz));
        FX.burst(new THREE.Vector3(sx, 1, sz), 0xff4a3a, 14, { speed: 4, size: 0.5, life: 0.5 });
      }
      showMessage('WARDEN SUMMONS', '#ff8fa6', 1.4);
    }
  }

  // steering + separation
  this.vel.x = damp(this.vel.x, desiredX, 6, dt);
  this.vel.z = damp(this.vel.z, desiredZ, 6, dt);

  for (var i = 0; i < enemies.length; i++) {
    var o = enemies[i];
    if (o === this || o.dead) continue;
    var ox = this.pos.x - o.pos.x;
    var oz = this.pos.z - o.pos.z;
    var od = Math.hypot(ox, oz);
    var minD = this.radius + o.radius;
    if (od > 0.0001 && od < minD) {
      var push = (minD - od) * 3.0;
      this.vel.x += (ox / od) * push;
      this.vel.z += (oz / od) * push;
    }
  }

  this.pos.x += this.vel.x * dt;
  this.pos.z += this.vel.z * dt;

  var lim = CFG.arenaRadius - this.radius - 0.3;
  var flat = Math.hypot(this.pos.x, this.pos.z);
  if (flat > lim) {
    this.pos.x *= lim / flat;
    this.pos.z *= lim / flat;
  }

  // pillars are solid
  for (var p = 0; p < arena.pillars.length; p++) {
    var pil = arena.pillars[p];
    var px = this.pos.x - pil.x;
    var pz = this.pos.z - pil.z;
    var pd = Math.hypot(px, pz);
    var minP = pil.r + this.radius;
    if (pd < minP && pd > 0.0001) {
      this.pos.x = pil.x + (px / pd) * minP;
      this.pos.z = pil.z + (pz / pd) * minP;
    }
  }

  // visuals
  var hover = this.hover + Math.sin(this.t * 2.4) * (this.type === 'boss' ? 0.22 : 0.09);
  this.mesh.group.position.set(this.pos.x, hover, this.pos.z);

  if (this.mesh.ring) this.mesh.ring.rotation.z += dt * (this.type === 'boss' ? 1.4 : 3.0);
  if (this.mesh.orbits) {
    for (var k = 0; k < this.mesh.orbits.length; k++) {
      var oa = this.t * 2.2 + (TAU * k) / 3;
      this.mesh.orbits[k].position.set(Math.cos(oa) * 0.85, Math.sin(oa * 1.3) * 0.3, Math.sin(oa) * 0.85);
    }
  }
  if (this.mesh.ringA) {
    this.mesh.ringA.rotation.z += dt * 0.9;
    this.mesh.ringB.rotation.z -= dt * 1.4;
    this.mesh.crown.rotation.y += dt * 0.6;
  }

  // hit flash / telegraph glow
  var mat = this.mesh.material;
  if (mat) {
    var base = this.type === 'hunter' ? 1.5 : (this.type === 'charger' ? 1.2 : (this.type === 'spitter' ? 1.35 : 1.25));
    var extra = this.hitFlash * 3.2;
    if (this.type === 'charger' && this.state === 'wind') {
      var pulse = 0.5 + 0.5 * Math.sin(this.t * 26);
      extra += pulse * 2.4;
      this.mesh.group.scale.setScalar(1 + pulse * 0.12);
    } else if (this.mesh.group.scale.x !== 1) {
      this.mesh.group.scale.setScalar(damp(this.mesh.group.scale.x, 1, 12, dt));
    }
    mat.emissiveIntensity = base + extra;
  }

  // contact damage
  if (this.type !== 'spitter') {
    var touch = this.radius + CFG.playerRadius + 0.15;
    if (dist < touch) {
      player.hurt(this.damage, this.pos.x, this.pos.z);
    }
  }
};

// ---- projectiles -----------------------------------------------------------
var orbGeo = new THREE.SphereGeometry(0.22, 12, 10);
var orbMat = new THREE.MeshBasicMaterial({ color: 0xe58cff });

function fireProjectile(x, y, z, nx, nz, damage) {
  var mesh = new THREE.Mesh(orbGeo, orbMat);
  mesh.position.set(x, y, z);
  var spr = new THREE.Sprite(new THREE.SpriteMaterial({
    map: glowTex, color: 0xd06bff, transparent: true, opacity: 0.9,
    blending: THREE.AdditiveBlending, depthWrite: false
  }));
  spr.scale.set(1.4, 1.4, 1);
  mesh.add(spr);
  scene.add(mesh);

  projectiles.push({
    mesh: mesh, pos: new THREE.Vector3(x, y, z),
    vel: new THREE.Vector3(nx * 9.5, 0, nz * 9.5),
    damage: damage, life: 4.5
  });
  tone(300, 0.12, 'sine', 0.03, 520);
}

function updateProjectiles(dt) {
  for (var i = projectiles.length - 1; i >= 0; i--) {
    var p = projectiles[i];
    p.life -= dt;
    p.pos.addScaledVector(p.vel, dt);
    p.mesh.position.copy(p.pos);

    FX.stream(p.pos, 0xc06bff, dt, { rate: 30, size: 0.28, life: 0.25, gravity: 0 });

    var hitPlayer = Math.hypot(p.pos.x - player.pos.x, p.pos.z - player.pos.z) < 0.72 &&
      Math.abs(p.pos.y - (player.pos.y + 1.0)) < 1.3;

    var outOfArena = Math.hypot(p.pos.x, p.pos.z) > CFG.arenaRadius - 0.4;

    if (hitPlayer) {
      player.hurt(p.damage, p.pos.x, p.pos.z);
      FX.burst(p.pos, 0xc06bff, 18, { speed: 5, size: 0.45, life: 0.4 });
    }

    if (hitPlayer || outOfArena || p.life <= 0) {
      scene.remove(p.mesh);
      projectiles.splice(i, 1);
    }
  }
}

// ---- boss shockwave --------------------------------------------------------
var shockwaves = [];

function spawnShockwave(x, z, damage) {
  var ring = new THREE.Mesh(
    new THREE.RingGeometry(0.9, 1.15, 72),
    new THREE.MeshBasicMaterial({ color: 0xff3f6a, transparent: true, opacity: 0.9, side: THREE.DoubleSide, blending: THREE.AdditiveBlending })
  );
  ring.rotation.x = -Math.PI / 2;
  ring.position.set(x, 0.08, z);
  scene.add(ring);
  shockwaves.push({ mesh: ring, x: x, z: z, r: 1.0, speed: 11, damage: damage, hit: false, life: 1.8 });
}

function updateShockwaves(dt) {
  for (var i = shockwaves.length - 1; i >= 0; i--) {
    var s = shockwaves[i];
    s.r += s.speed * dt;
    s.life -= dt;
    s.mesh.scale.setScalar(s.r);
    s.mesh.material.opacity = clamp(s.life / 1.8, 0, 1) * 0.9;

    var d = Math.hypot(player.pos.x - s.x, player.pos.z - s.z);
    if (!s.hit && Math.abs(d - s.r * 0.95) < 1.0 && player.pos.y < 1.2) {
      s.hit = true;
      player.hurt(s.damage, s.x, s.z);
      FX.burst(new THREE.Vector3(player.pos.x, 0.6, player.pos.z), 0xff4a6a, 20, { speed: 6, size: 0.55, life: 0.5 });
    }

    if (s.life <= 0) {
      scene.remove(s.mesh);
      shockwaves.splice(i, 1);
    }
  }
}

// =============================================================================
// 11. Cores
// =============================================================================
var coreGeo = new THREE.OctahedronGeometry(0.42, 0);
var haloGeo = new THREE.TorusGeometry(0.72, 0.03, 8, 48);

function spawnCore(x, z) {
  var g = new THREE.Group();
  var mat = new THREE.MeshStandardMaterial({
    color: 0x0d8f88, emissive: 0x2afff0, emissiveIntensity: 1.6, roughness: 0.2, metalness: 0.5
  });
  var gem = new THREE.Mesh(coreGeo, mat);
  gem.castShadow = true;
  g.add(gem);

  var halo = new THREE.Mesh(haloGeo, new THREE.MeshBasicMaterial({ color: 0x9bfcff, transparent: true, opacity: 0.85 }));
  halo.rotation.x = Math.PI / 2;
  g.add(halo);

  var spr = new THREE.Sprite(new THREE.SpriteMaterial({
    map: glowTex, color: 0x35f5e8, transparent: true, opacity: 0.8,
    blending: THREE.AdditiveBlending, depthWrite: false
  }));
  spr.scale.set(2.6, 2.6, 1);
  g.add(spr);

  g.position.set(x, 1.25, z);
  scene.add(g);

  cores.push({ group: g, gem: gem, halo: halo, baseY: 1.25, phase: rand(0, TAU), x: x, z: z });
}

function updateCores(dt) {
  for (var i = cores.length - 1; i >= 0; i--) {
    var c = cores[i];
    c.phase += dt;
    c.group.position.y = c.baseY + Math.sin(c.phase * 2.2) * 0.16;
    c.gem.rotation.y += dt * 2.6;
    c.gem.rotation.x += dt * 1.1;
    c.halo.rotation.z += dt * 1.8;

    if (player.dead) continue;

    var d = Math.hypot(player.pos.x - c.x, player.pos.z - c.z);
    if (d < 1.15 && Math.abs((player.pos.y + 0.9) - c.group.position.y) < 1.7) {
      scene.remove(c.group);
      cores.splice(i, 1);
      game.cores++;
      game.score += CFG.scorePerCore;
      arenaPulse(0x54e8ff);
      sfxPickup();
      FX.burst(c.group.position.clone(), 0x5ff0e6, 22, { speed: 5.5, size: 0.45, life: 0.5, gravity: 3 });
      showMessage('CORE ' + game.cores + ' / ' + game.coresTotal, '#6fe9ff', 0.9);

      if (cores.length === 0) onWaveCleared();
    }
  }
}

// =============================================================================
// 12. Combo
// =============================================================================
function addComboKill(enemy) {
  game.combo++;
  game.comboTimer = player.stats.comboWindow;
  game.comboMult = Math.min(CFG.comboMax, 1 + game.combo * CFG.comboStep);
  if (game.combo >= 3) {
    showMessage('x' + game.comboMult.toFixed(1) + '  ' + game.combo + ' CHAIN', '#ff7ac4', 0.9);
  }
}

function breakCombo() {
  if (game.combo >= 3) showMessage('COMBO LOST', '#8fa6bd', 0.8);
  game.combo = 0;
  game.comboMult = 1;
  game.comboTimer = 0;
}

function updateCombo(dt) {
  if (game.comboTimer > 0) {
    game.comboTimer -= dt;
    if (game.comboTimer <= 0) breakCombo();
  }
}

// =============================================================================
// 13. Waves / upgrades
// =============================================================================
var UPGRADES = [
  { id: 'edge', icon: '⚔', name: 'Edge', max: 5, desc: '+25% melee damage', apply: function () { player.stats.damage *= 1.25; } },
  { id: 'rhythm', icon: '⏱', name: 'Rhythm', max: 5, desc: '+18% attack speed', apply: function () { player.stats.attackCooldown *= 0.82; } },
  { id: 'stride', icon: '🏃', name: 'Stride', max: 4, desc: '+10% movement speed', apply: function () { player.stats.moveSpeed *= 1.1; player.stats.sprintSpeed *= 1.1; } },
  { id: 'core', icon: '❤', name: 'Core', max: 4, desc: '+25 max HP and heal 25', apply: function () { player.stats.maxHealth += 25; player.stats.health = Math.min(player.stats.maxHealth, player.stats.health + 25); } },
  { id: 'phase', icon: '⚡', name: 'Phase', max: 3, desc: '-22% dash cooldown', apply: function () { player.stats.dashCooldown *= 0.78; } },
  { id: 'leech', icon: '🩸', name: 'Leech', max: 3, desc: '+3 HP per hit landed', apply: function () { player.stats.lifesteal += 3; } },
  { id: 'reach', icon: '↗', name: 'Reach', max: 3, desc: '+0.45m range, wider arc', apply: function () { player.stats.range += 0.45; player.stats.arc += 12; } },
  { id: 'momentum', icon: '🔥', name: 'Momentum', max: 3, desc: '+0.8s combo window', apply: function () { player.stats.comboWindow += 0.8; } }
];

function upgradeLevel(id) { return game.upgrades[id] || 0; }

function rollUpgrades() {
  var pool = UPGRADES.filter(function (u) { return upgradeLevel(u.id) < u.max; });
  var out = [];
  while (out.length < 3 && pool.length) {
    var idx = randInt(0, pool.length - 1);
    out.push(pool[idx]);
    pool.splice(idx, 1);
  }
  return out;
}

function showUpgrades() {
  var cards = document.getElementById('cards');
  cards.innerHTML = '';
  var options = rollUpgrades();

  options.forEach(function (u) {
    var btn = document.createElement('button');
    btn.className = 'ucard';
    var lvl = upgradeLevel(u.id);
    btn.innerHTML = '<div class="lvl">LV ' + (lvl + 1) + '/' + u.max + '</div>' +
      '<div class="ico">' + u.icon + '</div>' +
      '<h4>' + u.name + '</h4><p>' + u.desc + '</p>';
    btn.addEventListener('click', function (ev) {
      ev.preventDefault();
      ev.stopPropagation();
      applyUpgrade(u);
    });
    cards.appendChild(btn);
  });

  if (!options.length) {
    // everything maxed: just continue
    setTimeout(function () { applyUpgrade(null); }, 400);
  }

  if (document.exitPointerLock) { try { document.exitPointerLock(); } catch (e) { /* ignore */ } }
  document.getElementById('upgrade').classList.add('on');
  game.state = 'upgrade';
}

function applyUpgrade(u) {
  if (u) {
    u.apply();
    game.upgrades[u.id] = upgradeLevel(u.id) + 1;
    sfxUpgrade();
  }
  document.getElementById('upgrade').classList.remove('on');
  game.wave++;
  startWave();

  if (!IS_TOUCH && canvas.requestPointerLock) {
    try { canvas.requestPointerLock(); } catch (e) { /* ignore */ }
  }
}

function onWaveCleared() {
  if (game.state !== 'playing') return;
  game.state = 'upgrade';
  game.score += CFG.waveBonus + game.wave * 40;
  sfxWave();
  arenaPulse(0x66ffc2);
  showMessage('WAVE ' + game.wave + ' CLEAR', '#3fffb0', 2.0);
  setBossBar(null);
  setTimeout(showUpgrades, 850);
}

function startWave() {
  game.state = 'playing';
  game.cores = 0;
  game.coresTotal = 0;
  game.spawnTimer = 0.8;

  var isBossWave = (game.wave % CFG.bossEvery) === 0;

  // clear leftover projectiles / shockwaves
  for (var i = projectiles.length - 1; i >= 0; i--) { scene.remove(projectiles[i].mesh); }
  projectiles.length = 0;
  for (var s = shockwaves.length - 1; s >= 0; s--) { scene.remove(shockwaves[s].mesh); }
  shockwaves.length = 0;

  if (isBossWave) {
    game.coresTotal = 0;
    var boss = new Enemy('boss', 0, -CFG.arenaRadius * 0.68);
    enemies.push(boss);
    game.boss = boss;
    setBossBar(boss);
    showMessage('WARDEN AWAKENS', '#ff5c7a', 2.4);
    sfxBoss();
    game.shake = 1.2;
    arenaPulse(0xff4a6a);
  } else {
    var count = Math.min(CFG.maxCores, Math.round(CFG.coreCount0 + CFG.corePerWave * (game.wave - 1)));
    game.coresTotal = count;
    var placed = [];
    for (var c = 0; c < count; c++) {
      var spot = placeInArena(6, 3.2, placed);
      placed.push(spot);
      spawnCore(spot.x, spot.z);
    }
    showMessage('WAVE ' + game.wave, '#7fe3ff', 1.4);
    arenaPulse(0x54e8ff);
  }

  updateHud(true);
}

function placeInArena(minFromPlayer, minFromOthers, others) {
  for (var attempt = 0; attempt < 40; attempt++) {
    var a = Math.random() * TAU;
    var r = 4.5 + Math.random() * (CFG.arenaRadius - 4.5 - 3.2);
    var x = Math.cos(a) * r;
    var z = Math.sin(a) * r;

    if (Math.hypot(x - player.pos.x, z - player.pos.z) < minFromPlayer) continue;

    var tooClose = false;
    for (var i = 0; i < others.length; i++) {
      if (Math.hypot(x - others[i].x, z - others[i].z) < minFromOthers) { tooClose = true; break; }
    }
    if (tooClose) continue;

    // keep off the pillars
    var blocked = false;
    for (var p = 0; p < arena.pillars.length; p++) {
      if (Math.hypot(x - arena.pillars[p].x, z - arena.pillars[p].z) < 2) { blocked = true; break; }
    }
    if (blocked) continue;

    return { x: x, z: z };
  }
  var fa = Math.random() * TAU;
  return { x: Math.cos(fa) * (CFG.arenaRadius * 0.6), z: Math.sin(fa) * (CFG.arenaRadius * 0.6) };
}

function aliveEnemies() {
  var n = 0;
  for (var i = 0; i < enemies.length; i++) if (!enemies[i].dead) n++;
  return n;
}

function enemyTypeForWave(wave) {
  if (wave < 2) return 'hunter';
  if (wave < 4) return Math.random() < 0.7 ? 'hunter' : 'charger';
  if (wave < 7) return Math.random() < 0.5 ? 'hunter' : (Math.random() < 0.55 ? 'charger' : 'spitter');
  var r = Math.random();
  if (r < 0.35) return 'hunter';
  if (r < 0.68) return 'charger';
  return 'spitter';
}

function updateSpawns(dt) {
  game.spawnTimer -= dt;
  if (game.spawnTimer > 0) return;

  var interval = Math.max(CFG.spawnIntervalMin, CFG.spawnInterval0 - game.wave * 0.12);
  game.spawnTimer = interval;

  var cap = Math.min(CFG.maxAliveCap, CFG.maxAliveBase + Math.floor(game.wave * 0.8));
  if (aliveEnemies() >= cap) return;

  var spot = placeInArena(9, 2.0, enemies.filter(function (e) { return !e.dead; }).map(function (e) {
    return { x: e.pos.x, z: e.pos.z };
  }));

  var type = enemyTypeForWave(game.wave);
  enemies.push(new Enemy(type, spot.x, spot.z));
  FX.burst(new THREE.Vector3(spot.x, 1, spot.z), 0xff6a4a, 12, { speed: 4, size: 0.45, life: 0.45 });
}

// =============================================================================
// 14. Run lifecycle
// =============================================================================
function resetRun() {
  // clear the field
  for (var i = enemies.length - 1; i >= 0; i--) scene.remove(enemies[i].mesh.group);
  enemies.length = 0;
  for (var c = cores.length - 1; c >= 0; c--) scene.remove(cores[c].group);
  cores.length = 0;
  for (var p = projectiles.length - 1; p >= 0; p--) scene.remove(projectiles[p].mesh);
  projectiles.length = 0;
  for (var s = shockwaves.length - 1; s >= 0; s--) scene.remove(shockwaves[s].mesh);
  shockwaves.length = 0;

  // reset player
  player.dead = false;
  player.root.visible = true;
  player.pos.set(0, 0, 0);
  player.vel.set(0, 0, 0);
  player.knock.set(0, 0, 0);
  player.yaw = Math.PI;
  player.lastDamage = -999;
  player.attackTimer = 0;
  player.dashCd = 0;
  player.dashTimer = 0;
  player.invuln = 0;
  player.stats = {
    maxHealth: CFG.maxHealth, health: CFG.maxHealth,
    damage: CFG.attackDamage, attackCooldown: CFG.attackCooldown,
    moveSpeed: CFG.walkSpeed, sprintSpeed: CFG.sprintSpeed,
    dashCooldown: CFG.dashCooldown, lifesteal: 0,
    range: CFG.attackRange, arc: CFG.attackArc, comboWindow: CFG.comboWindow
  };

  game.score = 0;
  game.wave = 1;
  game.combo = 0;
  game.comboMult = 1;
  game.comboTimer = 0;
  game.upgrades = {};
  game.boss = null;
  game.time = 0;
  game.shake = 0;
  game.hitStop = 0;
  game.fovKick = 0;
  setBossBar(null);

  camYaw = Math.PI;
  camPitch = 0.26;
  camPos.set(0, 3.0, 6.6);
  camLook.set(0, 1.4, 0);

  startWave();
}

function onPlayerDied() {
  game.state = 'dead';
  game.slowmo = 1;
  if (game.score > game.best) {
    game.best = game.score;
    try { localStorage.setItem('arenaRunnerBestV2', String(game.best)); } catch (e) { /* ignore */ }
  }
  setTimeout(showRunOver, 1500);
}

function showRunOver() {
  var overlay = document.getElementById('start');
  var h1 = overlay.querySelector('h1');
  var tag = overlay.querySelector('.tagline');
  var btn = document.getElementById('startBtn');
  h1.textContent = 'RUN OVER';
  tag.textContent = 'SCORE ' + game.score + '  ·  WAVE ' + game.wave + '  ·  BEST ' + game.best;
  btn.textContent = 'Run again';
  document.getElementById('bestHint').textContent = String(game.best);
  if (document.exitPointerLock) { try { document.exitPointerLock(); } catch (e) { /* ignore */ } }
  overlay.classList.remove('hidden');
  game.state = 'menu';
}

function startGame() {
  initAudio();
  document.getElementById('start').classList.add('hidden');
  document.getElementById('upgrade').classList.remove('on');
  resetRun();
  if (!IS_TOUCH && canvas.requestPointerLock) {
    try { canvas.requestPointerLock(); } catch (e) { /* ignore */ }
  }
}

function togglePause() {
  if (game.state === 'playing') {
    game.state = 'paused';
    document.getElementById('pauseBadge').classList.add('on');
    if (document.exitPointerLock) document.exitPointerLock();
  } else if (game.state === 'paused') {
    game.state = 'playing';
    document.getElementById('pauseBadge').classList.remove('on');
  }
}

// =============================================================================
// 15. HUD
// =============================================================================
var el = {
  score: document.getElementById('score'),
  wave: document.getElementById('wave'),
  cores: document.getElementById('cores'),
  best: document.getElementById('best'),
  healthFill: document.getElementById('healthFill'),
  healthText: document.getElementById('healthText'),
  sprintTag: document.getElementById('sprintTag'),
  comboWrap: document.getElementById('comboWrap'),
  comboVal: document.getElementById('comboVal'),
  comboBar: document.getElementById('comboBar'),
  messages: document.getElementById('messages'),
  danger: document.getElementById('danger'),
  hurtFlash: document.getElementById('hurtFlash'),
  minimap: document.getElementById('minimap'),
  dashFill: document.getElementById('dashFill'),
  bossWrap: document.getElementById('bossWrap'),
  bossFill: document.getElementById('bossFill'),
  bossName: document.getElementById('bossName')
};
var mapCtx = el.minimap.getContext('2d');
var hudCache = { score: -1, wave: -1, cores: '', best: -1, hp: -1, combo: -1, sprint: null };

function showMessage(text, color, duration) {
  var node = document.createElement('div');
  node.className = 'msg';
  node.textContent = text;
  node.style.color = color || '#eaf4ff';
  el.messages.appendChild(node);
  msgs.push({ node: node, until: game.time + (duration || 1.6) });
  while (msgs.length > 4) {
    var old = msgs.shift();
    if (old.node.parentNode) old.node.parentNode.removeChild(old.node);
  }
}

var msgs = [];

function updateMessages() {
  for (var i = msgs.length - 1; i >= 0; i--) {
    var m = msgs[i];
    var left = m.until - game.time;
    if (left <= 0) {
      if (m.node.parentNode) m.node.parentNode.removeChild(m.node);
      msgs.splice(i, 1);
    } else if (left < 0.4) {
      m.node.style.opacity = String(clamp(left / 0.4, 0, 1));
    }
  }
}

function flashHurt() {
  el.hurtFlash.style.opacity = '0.9';
  setTimeout(function () { el.hurtFlash.style.opacity = '0'; }, 80);
}

function setBossBar(boss) {
  if (boss) {
    el.bossWrap.classList.add('on');
    el.bossName.textContent = 'WARDEN  ·  WAVE ' + game.wave;
  } else {
    el.bossWrap.classList.remove('on');
  }
}

function updateHud(force) {
  var scoreStr = pad(Math.round(game.score), 6);
  if (force || hudCache.score !== scoreStr) { el.score.textContent = scoreStr; hudCache.score = scoreStr; }
  if (force || hudCache.wave !== game.wave) { el.wave.textContent = String(game.wave); hudCache.wave = game.wave; }

  var coresStr = game.coresTotal ? (game.cores + ' / ' + game.coresTotal) : '—';
  if (force || hudCache.cores !== coresStr) { el.cores.textContent = coresStr; hudCache.cores = coresStr; }
  if (force || hudCache.best !== game.best) { el.best.textContent = String(game.best); hudCache.best = game.best; }

  var pct = clamp(player.stats.health / player.stats.maxHealth, 0, 1);
  if (force || Math.abs(hudCache.hp - pct) > 0.002) {
    el.healthFill.style.transform = 'scaleX(' + pct + ')';
    el.healthFill.style.background = pct < 0.3
      ? 'linear-gradient(90deg,#ff3b30,#ff7a45)'
      : (pct < 0.6 ? 'linear-gradient(90deg,#ffb62b,#ffd166)' : 'linear-gradient(90deg,#12e08a,#28f5c0)');
    el.healthText.textContent = Math.ceil(player.stats.health) + ' / ' + Math.round(player.stats.maxHealth);
    hudCache.hp = pct;
  }

  var showCombo = game.combo > 1;
  if (force || hudCache.combo !== game.combo) {
    el.comboWrap.classList.toggle('on', showCombo);
    el.comboVal.textContent = 'x' + game.comboMult.toFixed(1);
    hudCache.combo = game.combo;
  }
  if (showCombo) {
    var k = clamp(game.comboTimer / Math.max(0.1, player.stats.comboWindow), 0, 1);
    el.comboBar.style.transform = 'scaleX(' + k + ')';
  }

  var sprinting = player.sprinting;
  if (force || hudCache.sprint !== sprinting) {
    el.sprintTag.classList.toggle('on', sprinting);
    hudCache.sprint = sprinting;
  }

  var dashK = clamp(1 - player.dashCd / Math.max(0.01, player.stats.dashCooldown), 0, 1);
  el.dashFill.style.transform = 'scaleY(' + dashK + ')';

  if (game.boss && !game.boss.dead) {
    el.bossFill.style.transform = 'scaleX(' + clamp(game.boss.hp / game.boss.maxHp, 0, 1) + ')';
  }
}

function drawMinimap() {
  var w = el.minimap.width, h = el.minimap.height;
  var cx = w / 2, cy = h / 2;
  var scale = (w / 2 - 8) / (CFG.arenaRadius + 1);

  mapCtx.clearRect(0, 0, w, h);
  mapCtx.fillStyle = 'rgba(6,14,22,0.92)';
  mapCtx.fillRect(0, 0, w, h);

  mapCtx.strokeStyle = 'rgba(67,230,255,0.45)';
  mapCtx.lineWidth = 3;
  mapCtx.beginPath();
  mapCtx.arc(cx, cy, CFG.arenaRadius * scale, 0, TAU);
  mapCtx.stroke();

  mapCtx.strokeStyle = 'rgba(67,230,255,0.12)';
  mapCtx.lineWidth = 1.5;
  mapCtx.beginPath();
  mapCtx.arc(cx, cy, CFG.arenaRadius * scale * 0.55, 0, TAU);
  mapCtx.stroke();

  mapCtx.fillStyle = 'rgba(255,138,61,0.55)';
  for (var p = 0; p < arena.pillars.length; p++) {
    mapCtx.beginPath();
    mapCtx.arc(cx + arena.pillars[p].x * scale, cy + arena.pillars[p].z * scale, 2.4, 0, TAU);
    mapCtx.fill();
  }

  for (var i = 0; i < cores.length; i++) {
    mapCtx.fillStyle = '#63f7ea';
    mapCtx.beginPath();
    mapCtx.arc(cx + cores[i].x * scale, cy + cores[i].z * scale, 3.2, 0, TAU);
    mapCtx.fill();
  }

  for (var e = 0; e < enemies.length; e++) {
    var en = enemies[e];
    if (en.dead) continue;
    mapCtx.fillStyle = en.type === 'boss' ? '#ff2f6d' : (en.type === 'charger' ? '#ff9a3c' : (en.type === 'spitter' ? '#c76bff' : '#ff4b2b'));
    mapCtx.beginPath();
    mapCtx.arc(cx + en.pos.x * scale, cy + en.pos.z * scale, en.type === 'boss' ? 6 : 3.6, 0, TAU);
    mapCtx.fill();
  }

  if (!player.dead) {
    var px = cx + player.pos.x * scale;
    var py = cy + player.pos.z * scale;
    mapCtx.fillStyle = '#ffffff';
    mapCtx.beginPath();
    mapCtx.arc(px, py, 4.2, 0, TAU);
    mapCtx.fill();

    mapCtx.strokeStyle = '#3fd8ff';
    mapCtx.lineWidth = 2.5;
    mapCtx.beginPath();
    mapCtx.moveTo(px, py);
    mapCtx.lineTo(px + Math.sin(player.yaw) * 13, py + Math.cos(player.yaw) * 13);
    mapCtx.stroke();
  }
}

function updateDanger() {
  if (game.state !== 'playing' || player.dead) { el.danger.style.opacity = '0'; return; }
  var nearest = Infinity;
  for (var i = 0; i < enemies.length; i++) {
    if (enemies[i].dead) continue;
    var d = Math.hypot(enemies[i].pos.x - player.pos.x, enemies[i].pos.z - player.pos.z) - enemies[i].radius;
    nearest = Math.min(nearest, d);
  }
  var danger = nearest < 4 ? clamp(1 - nearest / 4, 0, 1) : 0;
  el.danger.style.opacity = String(danger * 0.55);
}

// =============================================================================
// 16. Camera
// =============================================================================
function updateCamera(dt) {
  var target = new THREE.Vector3(player.pos.x, player.pos.y + CFG.cameraHeight, player.pos.z);

  var horiz = Math.cos(camPitch);
  var offset = new THREE.Vector3(Math.sin(camYaw) * horiz, Math.sin(camPitch), Math.cos(camYaw) * horiz)
    .multiplyScalar(CFG.cameraDist);

  var desired = target.clone().add(offset);
  desired.y = Math.max(desired.y, 0.75);

  var flat = Math.hypot(desired.x, desired.z);
  var maxFlat = CFG.arenaRadius - 0.6;
  if (flat > maxFlat) {
    desired.x *= maxFlat / flat;
    desired.z *= maxFlat / flat;
  }

  camPos.lerp(desired, 1 - Math.exp(-10 * dt));
  camLook.lerp(target, 1 - Math.exp(-16 * dt));

  var sprintK = player.sprinting ? 1 : 0;
  var targetFov = 72 + sprintK * 5 + game.fovKick;
  camera.fov = damp(camera.fov, targetFov, 8, dt);
  camera.updateProjectionMatrix();

  game.fovKick = damp(game.fovKick, 0, 7, dt);

  var shake = game.shake;
  if (shake > 0.001) {
    var s = shake * 0.22;
    camera.position.set(
      camPos.x + rand(-s, s),
      camPos.y + rand(-s, s),
      camPos.z + rand(-s, s)
    );
    game.shake = damp(game.shake, 0, 6, dt);
  } else {
    camera.position.copy(camPos);
  }

  camera.lookAt(camLook);
  camera.rotation.z += clamp(-(player.vel.x * Math.cos(camYaw) - player.vel.z * Math.sin(camYaw)) * 0.004, -0.03, 0.03);
}

// =============================================================================
// 17. Input
// =============================================================================
var keys = Object.create(null);
var stick = { active: false, id: null, ox: 0, oy: 0, dx: 0, dy: 0, radius: 92 };
var lookFinger = { active: false, id: null, x: 0, y: 0 };
var runToggle = false;
var attackHeld = false;

var stickBase = document.getElementById('stickBase');
var stickKnob = document.getElementById('stickKnob');

function setStickVisual(x, y, on) {
  stickBase.style.left = x + 'px';
  stickBase.style.top = y + 'px';
  stickBase.style.transform = 'translate(-50%,-50%)';
  stickKnob.style.left = x + 'px';
  stickKnob.style.top = y + 'px';
  stickKnob.style.transform = 'translate(-50%,-50%)';
  stickBase.classList.toggle('on', !!on);
}

function hideStickVisual() {
  stickBase.style.left = '-999px';
  stickKnob.style.left = '-999px';
  stickBase.classList.remove('on');
}

function onPointerDown(e) {
  initAudio();
  if (game.state !== 'playing') {
    if (e.target && e.target.closest && e.target.closest('.ucard, #startBtn, .tbtn, .overlay')) return;
  }

  if (e.target && e.target.closest && e.target.closest('.tbtn, .ucard, #startBtn')) return;

  if (!IS_TOUCH) {
    if (document.pointerLockElement !== canvas && canvas.requestPointerLock) {
      try { canvas.requestPointerLock(); } catch (err) { /* ignore */ }
    }
    if (game.state === 'playing') {
      if (e.button === 0) tryPlayerAttack();
      else if (e.button === 2) player.tryDash();
    }
    return;
  }

  if (game.state !== 'playing') return;

  var x = e.clientX, y = e.clientY;
  if (x < window.innerWidth * 0.5) {
    if (stick.active) return;
    stick.active = true;
    stick.id = e.pointerId;
    stick.ox = x;
    stick.oy = y;
    stick.dx = 0;
    stick.dy = 0;
    setStickVisual(x, y, true);
  } else if (!lookFinger.active) {
    lookFinger.active = true;
    lookFinger.id = e.pointerId;
    lookFinger.x = x;
    lookFinger.y = y;
  }
}

function onPointerMove(e) {
  if (!IS_TOUCH) {
    if (document.pointerLockElement === canvas) {
      camYaw -= (e.movementX || 0) * 0.0024;
      camPitch += (e.movementY || 0) * 0.0020;
      camPitch = clamp(camPitch, -0.45, 0.95);
    }
    return;
  }

  if (stick.active && e.pointerId === stick.id) {
    var dx = e.clientX - stick.ox;
    var dy = e.clientY - stick.oy;
    var len = Math.hypot(dx, dy);
    if (len > stick.radius) {
      dx = (dx / len) * stick.radius;
      dy = (dy / len) * stick.radius;
    }
    stick.dx = dx / stick.radius;
    stick.dy = dy / stick.radius;
    setStickVisual(stick.ox + dx, stick.oy + dy, true);
  } else if (lookFinger.active && e.pointerId === lookFinger.id) {
    camYaw -= (e.clientX - lookFinger.x) * 0.0044;
    camPitch += (e.clientY - lookFinger.y) * 0.0034;
    camPitch = clamp(camPitch, -0.45, 0.95);
    lookFinger.x = e.clientX;
    lookFinger.y = e.clientY;
  }
}

function onPointerUp(e) {
  if (stick.active && e.pointerId === stick.id) {
    stick.active = false;
    stick.id = null;
    stick.dx = 0;
    stick.dy = 0;
    hideStickVisual();
  }
  if (lookFinger.active && e.pointerId === lookFinger.id) {
    lookFinger.active = false;
    lookFinger.id = null;
  }
}

function tryPlayerAttack() {
  if (game.state !== 'playing' || player.dead) return;
  player.tryAttack();
}

window.addEventListener('pointerdown', onPointerDown, { passive: true });
window.addEventListener('pointermove', onPointerMove, { passive: true });
window.addEventListener('pointerup', onPointerUp, { passive: true });
window.addEventListener('pointercancel', onPointerUp, { passive: true });
window.addEventListener('contextmenu', function (e) { e.preventDefault(); });

window.addEventListener('keydown', function (e) {
  var k = e.key.toLowerCase();
  keys[k] = true;
  if (k === 'p' || k === 'escape') togglePause();
  if (k === ' ') {
    e.preventDefault();
    if (game.state === 'playing') player.jump();
  }
  if (k === 'q') player.tryDash();
  if (k === 'j') tryPlayerAttack();
});
window.addEventListener('keyup', function (e) { keys[e.key.toLowerCase()] = false; });

function bindHold(button, onDown, onUp) {
  button.addEventListener('pointerdown', function (e) {
    e.preventDefault();
    e.stopPropagation();
    initAudio();
    button.classList.add('hot');
    if (onDown) onDown();
  });
  ['pointerup', 'pointercancel', 'pointerleave'].forEach(function (evt) {
    button.addEventListener(evt, function () {
      button.classList.remove('hot');
      if (onUp) onUp();
    });
  });
}

var btnAttack = document.getElementById('btnAttack');
var btnRun = document.getElementById('btnRun');

bindHold(btnAttack, function () { attackHeld = true; tryPlayerAttack(); }, function () { attackHeld = false; });
bindHold(document.getElementById('btnJump'), function () { if (game.state === 'playing') player.jump(); });
bindHold(document.getElementById('btnDash'), function () { if (game.state === 'playing') player.tryDash(); });
bindHold(btnRun, function () {
  runToggle = !runToggle;
  btnRun.classList.toggle('on', runToggle);
});

document.getElementById('startBtn').addEventListener('click', function (e) {
  e.preventDefault();
  e.stopPropagation();
  startGame();
});

document.addEventListener('visibilitychange', function () {
  if (document.hidden && game.state === 'playing') togglePause();
});

// touch UI visibility
if (IS_TOUCH) {
  document.getElementById('touch').classList.add('on');
  document.getElementById('touchHelp').style.display = '';
  document.getElementById('startBtn').textContent = 'Tap to enter';
  hideStickVisual();
}

// =============================================================================
// 18. Main update + loop
// =============================================================================
function update(dt) {
  game.time += dt;

  // ---- movement input ----
  var mx = 0, mz = 0;
  if (keys['w'] || keys['arrowup']) mz += 1;
  if (keys['s'] || keys['arrowdown']) mz -= 1;
  if (keys['d'] || keys['arrowright']) mx += 1;
  if (keys['a'] || keys['arrowleft']) mx -= 1;
  if (stick.active) { mz += -stick.dy; mx += stick.dx; }

  var mag = Math.hypot(mx, mz);
  if (mag > 1) { mx /= mag; mz /= mag; }

  var sprinting = !!keys['shift'] || runToggle;
  player.update(dt, mx, mz, sprinting);

  // auto-attack while the button is held
  if (attackHeld) tryPlayerAttack();

  updateCombo(dt);

  // ---- enemies ----
  for (var i = enemies.length - 1; i >= 0; i--) {
    var e = enemies[i];
    e.update(dt);
    if (e.dead) enemies.splice(i, 1);
  }

  updateSpawns(dt);
  updateCores(dt);
  updateProjectiles(dt);
  updateShockwaves(dt);
  FX.update(dt);

  // ---- transient vfx ----
  for (var v = vfx.length - 1; v >= 0; v--) {
    var item = vfx[v];
    item.life -= dt;
    var t = 1 - item.life / item.max;
    if (item.kind === 'arc') {
      item.mesh.material.opacity = 0.85 * (1 - t);
      item.mesh.scale.setScalar(1 + t * 0.12);
    }
    if (item.life <= 0) {
      scene.remove(item.mesh);
      item.mesh.geometry.dispose();
      item.mesh.material.dispose();
      vfx.splice(v, 1);
    }
  }

  // arena pulse
  if (arena.pulse > 0) {
    arena.pulse = Math.max(0, arena.pulse - dt * 1.6);
    var pr = (1 - arena.pulse) * CFG.arenaRadius;
    arena.pulseMesh.scale.setScalar(Math.max(0.1, pr));
    arena.pulseMat.opacity = arena.pulse * 0.55;
  }

  // ambient dust drift
  if (arena.dust) {
    arena.dust.rotation.y += dt * 0.02;
  }

  updateDanger();
  updateHud(false);
  updateMessages();
  drawMinimap();
}

// ---- adaptive quality: keep the frame rate playable on weak phones ----------
var perf = { frames: 0, acc: 0, level: 0, bloomOn: QUALITY.bloom };

function adaptQuality(realDt) {
  perf.frames++;
  perf.acc += realDt;
  if (perf.frames < 45) return;

  var avg = perf.acc / perf.frames;
  perf.frames = 0;
  perf.acc = 0;

  if (avg > 0.030 && perf.level < 3) {
    perf.level++;
    if (perf.level === 1) {
      renderer.setPixelRatio(Math.max(0.8, QUALITY.pixelRatio * 0.8));
    } else if (perf.level === 2) {
      renderer.setPixelRatio(Math.max(0.65, QUALITY.pixelRatio * 0.65));
    } else {
      QUALITY.bloom = false;
      renderer.shadowMap.enabled = false;
      renderer.shadowMap.needsUpdate = true;
    }
    resize();
  }
}

var lastTime = performance.now();

function frame(now) {
  requestAnimationFrame(frame);

  var realDt = Math.min(0.1, (now - lastTime) / 1000);
  lastTime = now;

  var dt = realDt;

  if (game.hitStop > 0) {
    game.hitStop -= realDt;
    dt *= 0.08;
  }

  if (game.state === 'playing') {
    update(dt);
  } else if (game.state === 'dead') {
    // slow-mo death camera
    game.time += dt * 0.35;
    if (arena.dust) arena.dust.rotation.y += dt * 0.01;
    FX.update(realDt * 0.4);
  }

  updateCamera(realDt);
  updateHud(false);
  adaptQuality(realDt);
  PostFX.render(realDt);
}

// =============================================================================
// 19. Boot
// =============================================================================
function resize() {
  var w = window.innerWidth;
  var h = window.innerHeight;
  renderer.setPixelRatio(QUALITY.pixelRatio);
  renderer.setSize(w, h, false);
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
  PostFX.setSize(Math.floor(w * QUALITY.pixelRatio), Math.floor(h * QUALITY.pixelRatio));

  stick.radius = clamp(Math.min(w, h) * 0.16, 58, 108);
  var size = stick.radius * 1.7;
  stickBase.style.width = size + 'px';
  stickBase.style.height = size + 'px';
  stickKnob.style.width = (size * 0.42) + 'px';
  stickKnob.style.height = (size * 0.42) + 'px';
}

window.addEventListener('resize', resize);
window.addEventListener('orientationchange', function () { setTimeout(resize, 120); });

resize();
hideStickVisual();

document.getElementById('bestHint').textContent = String(game.best);
updateHud(true);
drawMinimap();
camera.lookAt(0, 1.4, 0);
PostFX.render(0.016);
requestAnimationFrame(frame);

// expose a tiny debug hook for automated smoke tests
window.__arena = {
  state: game,
  player: player,
  enemies: enemies,
  cores: cores,
  start: startGame,
  attack: tryPlayerAttack,
  dash: function () { player.tryDash(); },
  jump: function () { player.jump(); },
  spawn: function (type, x, z) { var e = new Enemy(type || 'hunter', x == null ? 3 : x, z == null ? 3 : z); enemies.push(e); return e; },
  killAll: function () { for (var i = enemies.length - 1; i >= 0; i--) enemies[i].kill(); },
  winWave: function () { for (var i = cores.length - 1; i >= 0; i--) scene.remove(cores[i].group); cores.length = 0; onWaveCleared(); },
  startWave: function () { startWave(); },
  hurt: function (n) { player.hurt(n || 10, player.pos.x + 1, player.pos.z); },
  upgradeOptions: function () { return rollUpgrades(); },
  applyUpgrade: function (id) {
    var u = null;
    for (var i = 0; i < UPGRADES.length; i++) if (UPGRADES[i].id === id) u = UPGRADES[i];
    applyUpgrade(u);
  }
};

})();
