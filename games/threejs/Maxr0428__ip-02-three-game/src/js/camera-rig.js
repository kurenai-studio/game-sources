/* ============================================================
   相机轨道：拖拽旋转 + 滚轮缩放 + 平滑跟随玩家
   自己实现一个轻量轨道控制，只有 40 行，方便按需修改
   ============================================================ */

window.CORE = window.CORE || {};

CORE.createCameraRig = function (THREE, camera, domElement) {
  const rig = {
    yaw: 0.9,            // 水平角（弧度）
    pitch: 0.62,         // 俯仰角
    distance: 17,        // 与玩家的距离
    target: new THREE.Vector3(0, 1.2, 0)
  };

  let isDragging = false;
  let lastX = 0;
  let lastY = 0;

  domElement.addEventListener('mousedown', function (event) {
    isDragging = true;
    lastX = event.clientX;
    lastY = event.clientY;
  });

  window.addEventListener('mouseup', function () {
    isDragging = false;
  });

  window.addEventListener('mousemove', function (event) {
    if (!isDragging) return;
    rig.yaw -= (event.clientX - lastX) * 0.0055;
    rig.pitch += (event.clientY - lastY) * 0.0042;
    lastX = event.clientX;
    lastY = event.clientY;
    // 俯仰角限制：既不钻到平台下面，也不变成纯俯视
    rig.pitch = Math.min(Math.max(rig.pitch, 0.16), 1.25);
  });

  domElement.addEventListener('wheel', function (event) {
    rig.distance += event.deltaY * 0.012;
    rig.distance = Math.min(Math.max(rig.distance, 9), 34);
    event.preventDefault();
  }, { passive: false });

  /* 触屏支持：单指拖拽旋转 */
  domElement.addEventListener('touchstart', function (event) {
    if (event.touches.length === 1) {
      isDragging = true;
      lastX = event.touches[0].clientX;
      lastY = event.touches[0].clientY;
    }
  });
  domElement.addEventListener('touchmove', function (event) {
    if (isDragging && event.touches.length === 1) {
      rig.yaw -= (event.touches[0].clientX - lastX) * 0.007;
      rig.pitch += (event.touches[0].clientY - lastY) * 0.005;
      rig.pitch = Math.min(Math.max(rig.pitch, 0.16), 1.25);
      lastX = event.touches[0].clientX;
      lastY = event.touches[0].clientY;
    }
  }, { passive: true });
  window.addEventListener('touchend', function () {
    isDragging = false;
  });

  /* 每帧把相机平滑地摆到玩家身后的轨道位置上 */
  rig.update = function (dt, playerPosition) {
    rig.target.lerp(
      new THREE.Vector3(playerPosition.x, playerPosition.y + 1.1, playerPosition.z),
      1 - Math.exp(-9 * dt)
    );

    const sinPitch = Math.sin(rig.pitch);
    const cosPitch = Math.cos(rig.pitch);
    const desired = new THREE.Vector3(
      rig.target.x + rig.distance * sinPitch * Math.cos(rig.yaw),
      rig.target.y + rig.distance * cosPitch,
      rig.target.z + rig.distance * sinPitch * Math.sin(rig.yaw)
    );
    camera.position.lerp(desired, 1 - Math.exp(-10 * dt));
    camera.lookAt(rig.target);
  };

  return rig;
};
