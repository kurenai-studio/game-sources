/* ============================================================
   场景搭建：灯光 / 平台 / 装饰 / 星尘
   全部代码挂在 window.CORE 命名空间下，方便分文件维护
   ============================================================ */

window.CORE = window.CORE || {};

CORE.createWorld = function (THREE) {
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x0B0E14);
  scene.fog = new THREE.Fog(0x0B0E14, 34, 95);

  /* ---------- 灯光：一个主光 + 一个冷色轮廓光 + 半球环境光 ---------- */
  const hemiLight = new THREE.HemisphereLight(0x8FB4D8, 0x141A24, 0.5);
  scene.add(hemiLight);

  const sunLight = new THREE.DirectionalLight(0xFFF4E0, 1.05);
  sunLight.position.set(18, 32, 14);
  sunLight.castShadow = true;
  sunLight.shadow.mapSize.set(2048, 2048);
  sunLight.shadow.camera.left = -30;
  sunLight.shadow.camera.right = 30;
  sunLight.shadow.camera.top = 30;
  sunLight.shadow.camera.bottom = -30;
  scene.add(sunLight);

  const rimLight = new THREE.DirectionalLight(0x4AD8E8, 0.4);
  rimLight.position.set(-22, 16, -20);
  scene.add(rimLight);

  /* ---------- 圆形平台：深色台面 + 发光边缘 ---------- */
  const platform = new THREE.Mesh(
    new THREE.CylinderGeometry(22, 22, 1.2, 64),
    new THREE.MeshStandardMaterial({ color: 0x161C28, roughness: 0.88, metalness: 0.12 })
  );
  platform.position.y = -0.6;
  platform.receiveShadow = true;
  scene.add(platform);

  const edgeRing = new THREE.Mesh(
    new THREE.TorusGeometry(22, 0.16, 12, 160),
    new THREE.MeshStandardMaterial({
      color: 0x0B0E14,
      emissive: 0x2AA7B8,
      emissiveIntensity: 1.4,
      roughness: 0.4
    })
  );
  edgeRing.rotation.x = Math.PI / 2;
  edgeRing.position.y = 0.02;
  scene.add(edgeRing);

  /* ---------- 台面上的三圈导轨细线：给画面加层次 ---------- */
  const railGroup = new THREE.Group();
  [6.5, 13, 19].forEach(function (radius) {
    const rail = new THREE.Mesh(
      new THREE.TorusGeometry(radius, 0.035, 8, 128),
      new THREE.MeshStandardMaterial({
        color: 0x0B0E14,
        emissive: 0x2E4A66,
        emissiveIntensity: 0.9,
        roughness: 0.6
      })
    );
    rail.rotation.x = Math.PI / 2;
    rail.position.y = 0.02;
    railGroup.add(rail);
  });
  scene.add(railGroup);

  /* ---------- 平台边缘的矮方碑：不是清一色方块，高度错落 ---------- */
  const pillarGroup = new THREE.Group();
  const pillarCount = 14;
  for (let i = 0; i < pillarCount; i += 1) {
    const angle = (i / pillarCount) * Math.PI * 2;
    const height = 1.4 + Math.sin(i * 2.4) * 0.9 + Math.random() * 0.5;
    const pillar = new THREE.Mesh(
      new THREE.BoxGeometry(0.7, height, 0.7),
      new THREE.MeshStandardMaterial({
        color: 0x1E2634,
        roughness: 0.7,
        metalness: 0.25,
        emissive: 0x0F2836,
        emissiveIntensity: 0.55
      })
    );
    pillar.position.set(Math.cos(angle) * 24.2, height / 2 - 0.2, Math.sin(angle) * 24.2);
    pillar.rotation.y = angle;
    pillar.castShadow = true;
    pillarGroup.add(pillar);
  }
  scene.add(pillarGroup);

  /* ---------- 星尘：远景中的一层缓慢闪烁的小点 ---------- */
  const starCount = 420;
  const starPositions = new Float32Array(starCount * 3);
  for (let i = 0; i < starCount; i += 1) {
    const radius = 55 + Math.random() * 70;
    const theta = Math.random() * Math.PI * 2;
    const phi = Math.acos(Math.random() * 0.9);        // 偏向上半球
    starPositions[i * 3] = radius * Math.sin(phi) * Math.cos(theta);
    starPositions[i * 3 + 1] = radius * Math.cos(phi) * 0.7 + 8;
    starPositions[i * 3 + 2] = radius * Math.sin(phi) * Math.sin(theta);
  }
  const starGeometry = new THREE.BufferGeometry();
  starGeometry.setAttribute('position', new THREE.BufferAttribute(starPositions, 3));
  const starMaterial = new THREE.PointsMaterial({
    color: 0x9FC4E8,
    size: 0.42,
    sizeAttenuation: true,
    transparent: true,
    opacity: 0.75
  });
  const stars = new THREE.Points(starGeometry, starMaterial);
  scene.add(stars);

  return {
    scene: scene,
    stars: stars
  };
};
