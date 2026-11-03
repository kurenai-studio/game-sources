/* ============================================================
   能量核心：要收集的目标
   12 枚八面体，交错两种色温，上下浮动 + 自转
   ============================================================ */

window.CORE = window.CORE || {};

CORE.createCores = function (THREE, scene) {
  const TOTAL = 12;
  const group = new THREE.Group();
  scene.add(group);

  const COLORS = [0xFFB74A, 0x4AD8E8];   // 暖橙 / 冷青交替

  const items = [];
  for (let i = 0; i < TOTAL; i += 1) {
    const angle = (i / TOTAL) * Math.PI * 2 + (i % 3) * 0.35;
    // 螺旋布点：从内圈到外圈均匀铺开，避免堆在中心
    const radius = 4.5 + (i / (TOTAL - 1)) * 14.5;

    const mesh = new THREE.Mesh(
      new THREE.OctahedronGeometry(0.62),
      new THREE.MeshStandardMaterial({
        color: COLORS[i % 2],
        emissive: COLORS[i % 2],
        emissiveIntensity: 1.35,
        roughness: 0.25,
        metalness: 0.35
      })
    );
    mesh.position.set(Math.cos(angle) * radius, 1.35, Math.sin(angle) * radius);
    mesh.castShadow = true;
    group.add(mesh);

    // 底下一圈淡淡的「标记环」，让玩家远远就能看到目标
    const marker = new THREE.Mesh(
      new THREE.TorusGeometry(0.85, 0.035, 8, 48),
      new THREE.MeshStandardMaterial({
        color: 0x0B0E14,
        emissive: COLORS[i % 2],
        emissiveIntensity: 0.8,
        roughness: 0.5
      })
    );
    marker.rotation.x = Math.PI / 2;
    marker.position.set(mesh.position.x, 0.06, mesh.position.z);
    group.add(marker);

    items.push({
      mesh: mesh,
      marker: marker,
      baseY: 1.35,
      phase: i * 0.9,
      collected: false,
      collectTimer: 0
    });
  }

  const api = {
    items: items,
    remaining: TOTAL,

    /* 浮动与自转 */
    update: function (dt, elapsed) {
      for (const item of items) {
        if (item.collected) {
          // 收集动画：缩小 + 上浮，0.35 秒后隐藏
          item.collectTimer += dt;
          const progress = Math.min(item.collectTimer / 0.35, 1);
          item.mesh.scale.setScalar(1 - progress);
          item.mesh.position.y = item.baseY + progress * 2.2;
          if (progress >= 1) {
            item.mesh.visible = false;
            item.marker.visible = false;
          }
          continue;
        }
        item.mesh.position.y = item.baseY + Math.sin(elapsed * 2 + item.phase) * 0.35;
        item.mesh.rotation.y += dt * 1.4;
        item.mesh.rotation.x += dt * 0.5;
      }
    },

    /* 与玩家的碰撞检测：命中返回被收集的核心，否则返回 null */
    tryCollect: function (player) {
      for (const item of items) {
        if (item.collected) continue;
        const dx = item.mesh.position.x - player.group.position.x;
        const dz = item.mesh.position.z - player.group.position.z;
        const distance = Math.hypot(dx, dz);
        if (distance < player.radius + 1.0) {
          item.collected = true;
          item.collectTimer = 0;
          api.remaining -= 1;
          return item;
        }
      }
      return null;
    },

    /* 重开一局 */
    reset: function () {
      api.remaining = TOTAL;
      for (const item of items) {
        item.collected = false;
        item.collectTimer = 0;
        item.mesh.visible = true;
        item.marker.visible = true;
        item.mesh.scale.setScalar(1);
        item.mesh.position.y = item.baseY;
      }
    }
  };

  return api;
};
