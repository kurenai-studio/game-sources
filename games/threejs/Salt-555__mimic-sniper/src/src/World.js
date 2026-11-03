import * as THREE from 'three';

const mats = {
  concrete: new THREE.MeshStandardMaterial({ color: 0x66706b, roughness: 0.96, flatShading: true }),
  dark: new THREE.MeshStandardMaterial({ color: 0x202725, roughness: 0.92, flatShading: true }),
  metal: new THREE.MeshStandardMaterial({ color: 0x34433f, roughness: 0.62, metalness: 0.35, flatShading: true }),
  rust: new THREE.MeshStandardMaterial({ color: 0x74564a, roughness: 0.92, flatShading: true }),
  seafoam: new THREE.MeshStandardMaterial({ color: 0x7fb3a8, roughness: 0.76, flatShading: true }),
};

export class World {
  constructor(scene) {
    this.scene = scene;
    this.obstacles = [];
    this.props = [];
    this.shootables = [];
    this.build();
  }

  box(size, position, material = mats.concrete, { propType = null, shootable = true } = {}) {
    const mesh = new THREE.Mesh(new THREE.BoxGeometry(size.x, size.y, size.z), material);
    mesh.position.copy(position);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    this.scene.add(mesh);
    if (shootable) this.shootables.push(mesh);
    if (propType) {
      mesh.userData.propType = propType;
      mesh.userData.baseEmissive = material.emissive?.getHex?.() ?? 0;
      this.props.push(mesh);
    }
    const box = new THREE.Box3().setFromObject(mesh);
    this.obstacles.push(box);
    return mesh;
  }

  build() {
    this.scene.background = new THREE.Color(0x85958f);
    this.scene.fog = new THREE.FogExp2(0x82918b, 0.014);

    const hemi = new THREE.HemisphereLight(0xbfd2cb, 0x19211f, 1.5);
    this.scene.add(hemi);
    const sun = new THREE.DirectionalLight(0xdde8df, 2.2);
    sun.position.set(-24, 40, -18);
    sun.castShadow = true;
    sun.shadow.mapSize.set(2048, 2048);
    sun.shadow.camera.left = -40; sun.shadow.camera.right = 40;
    sun.shadow.camera.top = 40; sun.shadow.camera.bottom = -40;
    this.scene.add(sun);

    const ground = new THREE.Mesh(new THREE.PlaneGeometry(100, 100), new THREE.MeshStandardMaterial({ color: 0x4c5853, roughness: 1 }));
    ground.rotation.x = -Math.PI / 2;
    ground.receiveShadow = true;
    ground.userData.ground = true;
    this.scene.add(ground);
    this.shootables.push(ground);

    this.box(new THREE.Vector3(72, 3, 1), new THREE.Vector3(0, 1.5, 29), mats.dark);
    this.box(new THREE.Vector3(72, 3, 1), new THREE.Vector3(0, 1.5, -29), mats.dark);
    this.box(new THREE.Vector3(1, 3, 58), new THREE.Vector3(-36, 1.5, 0), mats.dark);
    this.box(new THREE.Vector3(1, 3, 58), new THREE.Vector3(36, 1.5, 0), mats.dark);

    this.box(new THREE.Vector3(12, 9, 10), new THREE.Vector3(-20, 4.5, 3), mats.concrete);
    this.box(new THREE.Vector3(9, 6, 13), new THREE.Vector3(18, 3, -8), mats.dark);
    this.box(new THREE.Vector3(14, 4, 7), new THREE.Vector3(6, 2, 16), mats.concrete);
    this.box(new THREE.Vector3(7, 3, 7), new THREE.Vector3(-7, 1.5, -14), mats.rust);

    const propData = [
      ['crate', [-10, 1, 9], [2, 2, 2], mats.rust],
      ['crate', [-6, 1, 11], [2, 2, 2], mats.rust],
      ['generator', [12, 1.2, 7], [3, 2.4, 1.8], mats.metal],
      ['cabinet', [25, 1.8, 10], [1.7, 3.6, 1.5], mats.seafoam],
      ['crate', [5, 1, -4], [2, 2, 2], mats.rust],
      ['barrel', [-25, 1.4, -10], [1.5, 2.8, 1.5], mats.metal],
    ];
    for (const [type, p, s, mat] of propData) {
      const mesh = this.box(new THREE.Vector3(...s), new THREE.Vector3(...p), mat.clone(), { propType: type });
      mesh.userData.disguiseScale = new THREE.Vector3(...s);
    }

    for (let i = 0; i < 9; i++) {
      const pole = new THREE.Mesh(new THREE.CylinderGeometry(0.12, 0.16, 6, 6), mats.metal);
      pole.position.set(-31 + i * 8, 3, -23 + (i % 2) * 4);
      pole.castShadow = true;
      this.scene.add(pole);
    }

    const platform = this.box(new THREE.Vector3(10, 1, 8), new THREE.Vector3(0, 12, 36), mats.dark);
    platform.userData.sniperPlatform = true;
  }
}
