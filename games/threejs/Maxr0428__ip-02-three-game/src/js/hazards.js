/* ============================================================
   巡逻者：会撞人的红色障碍
   4 个红色球体沿不同半径的圆形轨道巡逻，方向与速度各不相同
   ============================================================ */

window.CORE = window.CORE || {};

CORE.createHazards = function (THREE, scene) {
  const group = new THREE.Group();
  scene.add(group);

  // 巡逻轨道配置：半径 / 角速度（正负表示方向）/ 初始相位
  const CONFIG = [
    { radius: 6.5,  speed: 0.85,  phase: 0.0 },
    { radius: 11,   speed: -0.62, phase: 1.6 },
    { radius: 15.5, speed: 0.5,   phase: 3.1 },
    { radius: 19,   speed: -0.42, phase: 4.4 }
  ];

  const items = CONFIG.map(function (config) {
    const mesh = new THREE.Mesh(
      new THREE.SphereGeometry(1.05, 32, 24),
      new THREE.MeshStandardMaterial({
        color: 0xE8554A,
        emissive: 0xB0271F,
        emissiveIntensity: 1.1,
        roughness: 0.35,
        metalness: 0.2
      })
    );
    mesh.castShadow = true;

    // 拖在后面的红色小尾巴，让「危险」更容易被看见
    const tail = new THREE.Mesh(
      new THREE.SphereGeometry(0.4, 16, 12),
      new THREE.MeshStandardMaterial({
        color: 0xE8554A,
        emissive: 0xB0271F,
        emissiveIntensity: 0.8,
        transparent: true,
        opacity: 0.4
      })
    );
    group.add(mesh);
    group.add(tail);

    return Object.assign({ mesh: mesh, tail: tail, angle: config.phase }, config);
  });

  const api = {
    items: items,

    update: function (dt, elapsed) {
      for (const item of items) {
        item.angle += item.speed * dt;
        item.mesh.position.set(
          Math.cos(item.angle) * item.radius,
          1.05 + Math.sin(elapsed * 4 + item.phase) * 0.25,
          Math.sin(item.angle) * item.radius
        );
        // 尾巴拖在运动方向的后方
        const trailAngle = item.angle - Math.sign(item.speed) * 0.22;
        item.tail.position.set(
          Math.cos(trailAngle) * item.radius,
          1.05,
          Math.sin(trailAngle) * item.radius
        );
      }
    },

    /* 碰撞检测：命中返回命中的巡逻者，否则 null */
    hitPlayer: function (player) {
      for (const item of items) {
        const dx = item.mesh.position.x - player.group.position.x;
        const dz = item.mesh.position.z - player.group.position.z;
        const distance = Math.hypot(dx, dz);
        if (distance < player.radius + 1.0) {
          return item;
        }
      }
      return null;
    },

    /* 把玩家从巡逻者身上弹开，避免连续判定 */
    knockBack: function (player, hazard) {
      const dx = player.group.position.x - hazard.mesh.position.x;
      const dz = player.group.position.z - hazard.mesh.position.z;
      const distance = Math.hypot(dx, dz) || 1;
      player.group.position.x += (dx / distance) * 2.4;
      player.group.position.z += (dz / distance) * 2.4;
      player.velocity.set(-dx / distance, 0, -dz / distance);
    },

    reset: function () {
      for (const item of items) {
        item.angle = item.phase;
      }
    }
  };

  return api;
};
