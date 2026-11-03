
// ================= 主流程 =================
function showError(msg) {
  const box = document.getElementById('loadErr');
  box.hidden = false;
  box.textContent = tr('無法啟動 3D 城市：', 'Could not start the 3D city: ') + msg +
    tr('。請確認瀏覽器支援 WebGL，並重新整理頁面。', '. Check that your browser supports WebGL, then reload.');
  document.querySelector('#loading .dots').hidden = true;
}

const clock = { last: performance.now() };
function frame(now) {
  requestAnimationFrame(frame);
  const dt = Math.min((now - clock.last) / 1000, .08);
  clock.last = now;
  const animate = !S.reduced;
  if (animate) {
    S.time += dt; S.uTime.value = S.time;
    if (!S.clockPaused) { S.minute = (S.minute + dt * 10) % 1440; applyTime(S.minute); onMinute(); }
    S.dirty = true;
  }
  stepFly(now);
  if (S.controls.update()) S.dirty = true;
  if (animate) ticks.forEach((f) => f(dt));
  if (typeof updateFrame === 'function') updateFrame(dt, animate);
  if (!S.dirty) return;
  S.dirty = false;
  ENV.sky.position.copy(S.camera.position);
  updateLOD();
  S.renderer.render(S.scene, S.camera);
  S.labelRenderer.render(S.scene, S.camera);
  if (typeof afterRender === 'function') afterRender();
}
let onMinute = () => {};

async function boot() {
  try {
    applyStaticLang();
    const mods = await Promise.all([
      import('three'),
      import('three/addons/controls/OrbitControls.js'),
      import('three/addons/renderers/CSS2DRenderer.js'),
      import('three/addons/geometries/RoundedBoxGeometry.js'),
      import('three/addons/utils/BufferGeometryUtils.js'),
      import('three/addons/math/SimplexNoise.js'),
    ]);
    THREE = mods[0];
    ({ OrbitControls } = mods[1]); ({ CSS2DRenderer, CSS2DObject } = mods[2]);
    ({ RoundedBoxGeometry } = mods[3]); BufferGeometryUtils = mods[4]; ({ SimplexNoise } = mods[5]);

    const probe = document.createElement('canvas');
    if (!(probe.getContext('webgl2') || probe.getContext('webgl'))) throw new Error(tr('此瀏覽器不支援 WebGL', 'WebGL is not available'));

    S.center = new THREE.Vector3();
    Y_AXIS = new THREE.Vector3(0, 1, 0);
    initDayKeys();
    setupRenderer();
    setupSky();
    ENV.waterMat = makeWaterMaterial(); ENV.waterMat.uniforms.uTime = S.uTime;
    buildIslands();
    setupWater();
    ENV.waterMat.uniforms.uCenter.value.copy(S.center);
    setupLights();
    buildBridges();
    if (typeof buildWorld === 'function') buildWorld();
    buildKit();
    buildIslandLabels();
    if (typeof buildUI === 'function') buildUI();
    if (typeof buildWalkersAll === 'function') buildWalkersAll();
    applyTime(S.minute);
    goOverview(true);

    requestAnimationFrame(frame);
    setTimeout(() => document.getElementById('loading').classList.add('done'), 250);
    if (typeof afterBoot === 'function') afterBoot();
  } catch (err) {
    console.error(err);
    showError(err && err.message ? err.message : String(err));
  }
}
boot();
</script>
