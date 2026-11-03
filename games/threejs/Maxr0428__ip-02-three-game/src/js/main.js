/* ============================================================
   入口：初始化渲染器、把所有模块接起来、启动主循环
   ============================================================ */

(function () {
  const THREE = window.THREE;

  // 检查 WebGL 是否可用，失败时给出一句人话提示
  let renderer;
  try {
    renderer = new THREE.WebGLRenderer({
      canvas: document.getElementById('stage'),
      antialias: true,
      powerPreference: 'high-performance'
    });
  } catch (error) {
    document.body.innerHTML =
      '<p style="padding:48px;text-align:center;color:#E8EEF6;">' +
      '你的浏览器不支持 WebGL，无法运行本作品。请换用最新版 Chrome / Edge。</p>';
    return;
  }

  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;

  const camera = new THREE.PerspectiveCamera(52, window.innerWidth / window.innerHeight, 0.1, 260);

  /* ---------- 搭世界 ---------- */
  const world = CORE.createWorld(THREE);
  const player = CORE.createPlayer(THREE, world.scene);
  const cores = CORE.createCores(THREE, world.scene);
  const hazards = CORE.createHazards(THREE, world.scene);
  const cameraRig = CORE.createCameraRig(THREE, camera, renderer.domElement);
  const game = CORE.createGame({
    player: player,
    cores: cores,
    hazards: hazards
  });
  CORE._game = game;    // 调试辅助：把状态机暴露出来，便于自动化测试
  CORE._player = player;
  CORE._cores = cores;
  CORE._hazards = hazards;

  /* ---------- 主循环 ---------- */
  const clock = new THREE.Clock();
  let elapsed = 0;

  function animate() {
    requestAnimationFrame(animate);
    // 限制单帧步长：切到后台再回来时不会瞬移
    const dt = Math.min(clock.getDelta(), 0.05);
    elapsed += dt;

    // 世界始终在呼吸：星尘缓转、核心浮动、巡逻者巡逻
    world.stars.rotation.y += dt * 0.01;
    cores.update(dt, elapsed);
    hazards.update(dt, elapsed);

    // 玩家与规则只在游玩中推进；结算画面里玩家静止呼吸
    player.update(dt, cameraRig.yaw, elapsed, game.isRunning());
    game.update(dt, elapsed);
    cameraRig.update(dt, player.group.position);

    renderer.render(world.scene, camera);
  }

  animate();

  /* ---------- 自适应窗口 ---------- */
  window.addEventListener('resize', function () {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
  });
})();
