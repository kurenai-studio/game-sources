
// ================= 天空、光、水 =================
const ENV = {};

function setupSky() {
  const mat = new THREE.ShaderMaterial({
    side: THREE.BackSide, depthWrite: false, fog: false,
    uniforms: {
      uTop: { value: new THREE.Color() }, uHorizon: { value: new THREE.Color() },
      uSunDir: { value: new THREE.Vector3(0, 1, 0) }, uSun: { value: new THREE.Color() }, uNight: { value: 0 },
    },
    vertexShader: `varying vec3 vDir;
      void main(){ vDir = normalize(position); gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }`,
    fragmentShader: `uniform vec3 uTop, uHorizon, uSunDir, uSun; uniform float uNight; varying vec3 vDir;
      float hash(vec3 p){ return fract(sin(dot(p, vec3(12.9898, 78.233, 45.164))) * 43758.5453); }
      void main(){
        vec3 d = normalize(vDir);
        vec3 col = mix(uHorizon, uTop, smoothstep(-.02, .55, d.y));
        float s = max(dot(d, normalize(uSunDir)), 0.0);
        col += uSun * pow(s, 18.0) * .35;
        if (uNight > 0.0) {
          float st = step(.9965, hash(floor(d * 180.0))) * smoothstep(0.0, .25, d.y);
          col += vec3(st) * uNight * .9;
        }
        gl_FragColor = vec4(col, 1.0);
        #include <tonemapping_fragment>
        #include <colorspace_fragment>
      }`,
  });
  const sky = new THREE.Mesh(new THREE.SphereGeometry(170, 32, 16), mat);
  sky.renderOrder = -10; sky.frustumCulled = false;
  S.scene.add(sky);
  ENV.sky = sky;
}

function setupLights() {
  ENV.hemi = new THREE.HemisphereLight(0xeef6fa, 0x8f8270, 1.3);
  S.scene.add(ENV.hemi);
  const sun = new THREE.DirectionalLight(0xfff1de, 2.8);
  sun.castShadow = true;
  sun.shadow.mapSize.set(2048, 2048);
  Object.assign(sun.shadow.camera, { left: -20, right: 20, top: 22, bottom: -22, near: 1, far: 90 });
  sun.shadow.bias = -0.0006; sun.shadow.normalBias = 0.045; sun.shadow.radius = 3;
  sun.target.position.copy(S.center);
  S.scene.add(sun, sun.target);
  ENV.sun = sun;
  const fill = new THREE.DirectionalLight(0xbfd6ff, .35);
  fill.position.set(S.center.x - 20, 18, S.center.z - 25);
  S.scene.add(fill);
}

// 水面與島側壁共用的 shader
function makeWaterMaterial() {
  return new THREE.ShaderMaterial({
    fog: true,
    uniforms: THREE.UniformsUtils.merge([THREE.UniformsLib.fog, {
      uShallow: { value: new THREE.Color('#a4d4da') }, uDeep: { value: new THREE.Color('#6fa9b8') },
      uTime: { value: 0 }, uCenter: { value: new THREE.Vector3() },
    }]),
    vertexShader: `varying vec3 vWorld;
      #include <fog_pars_vertex>
      void main(){
        vec4 wp = modelMatrix * vec4(position, 1.0); vWorld = wp.xyz;
        vec4 mvPosition = viewMatrix * wp; gl_Position = projectionMatrix * mvPosition;
        #include <fog_vertex>
      }`,
    fragmentShader: `uniform vec3 uShallow, uDeep, uCenter; uniform float uTime; varying vec3 vWorld;
      #include <fog_pars_fragment>
      void main(){
        vec2 p = vWorld.xz;
        float d = length(p - uCenter.xz);
        float w = sin(p.x * .35 + uTime * .4) * sin(p.y * .3 - uTime * .33) + sin((p.x + p.y) * .22 - uTime * .25) * .6;
        float deep = smoothstep(12.0, 70.0, d);
        vec3 col = mix(uShallow, uDeep, clamp(deep + w * .06, 0.0, 1.0));
        col += w * .012;
        float sp = pow(max(0.0, sin(p.x * 3.1 + uTime * 1.3 + w * 4.0) * sin(p.y * 2.7 - uTime * 1.1 - w * 3.0)), 60.0) * .1 * (1.0 - deep);
        col += sp;
        // 側壁：越往下越深
        col *= mix(.82, 1.0, smoothstep(-.6, .4, vWorld.y));
        gl_FragColor = vec4(col, 1.0);
        #include <tonemapping_fragment>
        #include <colorspace_fragment>
        #include <fog_fragment>
      }`,
  });
}

function setupWater() {
  const mat = makeWaterMaterial();
  mat.uniforms.uCenter.value.copy(S.center);
  mat.uniforms.uTime = S.uTime;
  const water = new THREE.Mesh(new THREE.CircleGeometry(160, 64).rotateX(-Math.PI / 2), mat);
  water.position.set(S.center.x, WATER_Y, S.center.z);
  water.receiveShadow = false;
  S.scene.add(water);
  ENV.water = water; ENV.waterMat = mat;
}

// ================= 日夜循環 =================
// 欄位：分鐘、skyTop、horizon、sunColor、sunI、hemiSky、hemiGround、hemiI、night、water
const DAY_RAW = [
  [0, '1e2c58', '3f4f80', 'b4c2ff', 1.15, '94a2d8', '64566a', 1.85, 1, '5a88b2'],
  [300, '26365f', '4c5688', 'b8c4ff', 1.0, '96a4da', '66586c', 1.85, 1, '5c8ab4'],
  [360, '7f8fc4', 'f6c3a6', 'ffb48a', 1.3, 'f3c6b5', '6b5a5a', 1.1, .55, '8fb7c4'],
  [450, 'a9d1ea', 'fbe6d3', 'ffe2c4', 2.4, 'eaf2f6', '8a7a68', 1.25, 0, '9fcfd6'],
  [720, '9fd0ec', 'f4eee3', 'fff1de', 2.9, 'eef6fa', '8f8270', 1.35, 0, 'a9d8db'],
  [960, 'a6cfe6', 'f8e7d2', 'ffe3c0', 2.5, 'f1efe8', '8a7a66', 1.25, 0, '9fcbd2'],
  [1065, '8b8fc4', 'f7b98f', 'ff9f6a', 1.8, 'f6d2bc', '7d6660', 1.2, .3, '93a9bd'],
  [1140, '5a5e9e', 'd99aa6', 'ff9a7a', 1.3, 'c0b2e0', '655868', 1.35, .75, '6a7cab'],
  [1260, '22325f', '445488', 'c0ccff', 1.2, '98a8dc', '685a6e', 1.9, 1, '5a88b2'],
];
let DAY_KEYS;
function initDayKeys() {
  DAY_KEYS = DAY_RAW.map((k) => k.map((v) => typeof v === 'string' ? new THREE.Color('#' + v) : v));
  DAY_KEYS.push([1440, ...DAY_KEYS[0].slice(1)]);
}

const _c = [];
function lerpKey(min) {
  let i = 0;
  while (i < DAY_KEYS.length - 2 && DAY_KEYS[i + 1][0] <= min) i++;
  const a = DAY_KEYS[i], b = DAY_KEYS[i + 1], t = clamp((min - a[0]) / (b[0] - a[0]), 0, 1);
  return a.map((v, j) => {
    if (j === 0) return min;
    if (typeof v === 'number') return v + (b[j] - v) * t;
    _c[j] = _c[j] || new THREE.Color();
    return _c[j].copy(v).lerp(b[j], t);
  });
}

const deepRatio = { r: 0x6f / 0xa4, g: 0xa9 / 0xd4, b: 0xb8 / 0xda };
const nightListeners = [], timeListeners = [];
function applyTime(min) {
  const [, top, hor, sunC, sunI, hSky, hGround, hI, night, water] = lerpKey(min);
  const u = ENV.sky.material.uniforms;
  u.uTop.value.copy(top); u.uHorizon.value.copy(hor); u.uSun.value.copy(sunC); u.uNight.value = night;
  S.scene.fog.color.copy(hor);
  ENV.sun.color.copy(sunC); ENV.sun.intensity = sunI;
  ENV.hemi.color.copy(hSky); ENV.hemi.groundColor.copy(hGround); ENV.hemi.intensity = hI;
  ENV.waterMat.uniforms.uShallow.value.copy(water);
  ENV.waterMat.uniforms.uDeep.value.setRGB(water.r * deepRatio.r, water.g * deepRatio.g, water.b * deepRatio.b);

  // 太陽方位：量化到 10 分鐘，永遠在鏡頭這一側的上方
  const qm = Math.floor(min / 10) * 10;
  const t = clamp((qm - 360) / 720, 0, 1);
  const az = Math.PI * (.15 + .7 * t), el = .35 + Math.sin(t * Math.PI) * .75;
  const dir = new THREE.Vector3(Math.cos(az) * Math.cos(el), Math.sin(el), .55 * Math.cos(el) + .35).normalize();
  ENV.sun.position.copy(S.center).addScaledVector(dir, 40);
  u.uSunDir.value.copy(dir);

  if (Math.abs(night - S.night) > 1e-4) { S.night = night; nightListeners.forEach((f) => f(night)); }
  timeListeners.forEach((f) => f(hor, min));
  markDirty();
}
