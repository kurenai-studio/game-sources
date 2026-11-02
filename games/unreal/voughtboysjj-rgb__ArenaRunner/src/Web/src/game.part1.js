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
