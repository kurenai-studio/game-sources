/* ============================================================
   玩家：一颗会发光的小球
   键盘控制移动，移动方向跟随当前相机朝向，拖拽视角后依旧顺手
   ============================================================ */

window.CORE = window.CORE || {};

CORE.createPlayer = function (THREE, scene) {
  const RADIUS = 0.9;

  const body = new THREE.Mesh(
    new THREE.SphereGeometry(RADIUS, 40, 32),
    new THREE.MeshStandardMaterial({
      color: 0xFFB74A,
      emissive: 0xFF9A2A,
      emissiveIntensity: 1.5,
      roughness: 0.3,
      metalness: 0.1
    })
  );
  body.castShadow = true;

  // 玩家自带一盏暖色点光，走到哪里照亮哪里
  const glow = new THREE.PointLight(0xFFB74A, 1.5, 16, 2);
  glow.position.y = 0.4;

  const player = new THREE.Group();
  player.add(body);
  player.add(glow);
  player.position.set(0, RADIUS, 0);
  scene.add(player);

  const state = {
    group: player,
    body: body,
    radius: RADIUS,
    speed: 13,                     // 移动速度（单位 / 秒）
    velocity: new THREE.Vector3(),
    keys: { forward: false, back: false, left: false, right: false },
    invulnerableUntil: 0           // 受击后的短暂无敌时间（秒）
  };

  /* 键盘按下 / 松开 */
  function setKey(code, pressed) {
    switch (code) {
      case 'KeyW': case 'ArrowUp':    state.keys.forward = pressed; break;
      case 'KeyS': case 'ArrowDown':  state.keys.back = pressed; break;
      case 'KeyA': case 'ArrowLeft':  state.keys.left = pressed; break;
      case 'KeyD': case 'ArrowRight': state.keys.right = pressed; break;
    }
  }

  document.addEventListener('keydown', function (event) {
    setKey(event.code, true);
    if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Space'].indexOf(event.code) >= 0) {
      event.preventDefault();      // 防止方向键滚动页面
    }
  });
  document.addEventListener('keyup', function (event) {
    setKey(event.code, false);
  });

  /* 每帧更新：把键盘输入换算成世界坐标的移动 */
  state.update = function (dt, cameraYaw, elapsed, isRunning) {
    const input = { x: 0, z: 0 };
    if (isRunning) {
      if (state.keys.forward) input.z -= 1;
      if (state.keys.back) input.z += 1;
      if (state.keys.left) input.x -= 1;
      if (state.keys.right) input.x += 1;
    }

    const moving = input.x !== 0 || input.z !== 0;
    if (moving) {
      // 把输入向量旋转到相机朝向：拖拽视角后「前」永远是屏幕里的前方
      const sin = Math.sin(cameraYaw);
      const cos = Math.cos(cameraYaw);
      const worldX = input.x * cos - input.z * sin;
      const worldZ = input.x * sin + input.z * cos;
      const length = Math.hypot(worldX, worldZ) || 1;
      state.velocity.set(worldX / length, 0, worldZ / length);
    } else {
      state.velocity.multiplyScalar(0.82);   // 松键后带一点惯性滑行
    }

    player.position.x += state.velocity.x * state.speed * dt;
    player.position.z += state.velocity.z * state.speed * dt;

    // 限制在平台上（半径 22，留 1.2 出容错）
    const distance = Math.hypot(player.position.x, player.position.z);
    const limit = 20.8;
    if (distance > limit) {
      player.position.x *= limit / distance;
      player.position.z *= limit / distance;
    }

    // 待机时轻轻呼吸；受击无敌期闪烁
    const breathe = 1 + Math.sin(elapsed * 3.2) * 0.04;
    body.scale.setScalar(breathe);
    const blinking = elapsed < state.invulnerableUntil;
    body.material.emissiveIntensity = blinking
      ? (Math.sin(elapsed * 28) > 0 ? 2.2 : 0.35)
      : 1.5;
  };

  return state;
};
