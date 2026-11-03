import * as THREE from 'three';

/** Original whitebox geometry: no models, textures or art resources. */
export class World {
  constructor() {
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x172025);
    this.scene.fog = new THREE.FogExp2(0x172025, 0.057);
    this.scene.add(new THREE.HemisphereLight(0xcad5d9, 0x313333, 2));
    const light = new THREE.DirectionalLight(0xf1efdf, 2.1);
    light.position.set(-4, 8, 4); this.scene.add(light);
    this.materials = {
      road: new THREE.MeshStandardMaterial({ color: 0x626a6c, roughness: 1 }),
      wall: new THREE.MeshStandardMaterial({ color: 0xa5adae, roughness: 1 }),
      body: new THREE.MeshStandardMaterial({ color: 0xc8cecc, roughness: 1 }),
      hand: new THREE.MeshStandardMaterial({ color: 0xb0b9b6, roughness: 1 }),
      dark: new THREE.MeshStandardMaterial({ color: 0x5b6466, roughness: 1 }),
      marker: new THREE.MeshStandardMaterial({ color: 0xcbd0c9, roughness: 1 }),
      monster: new THREE.MeshStandardMaterial({ color: 0x8b9191, roughness: 1, emissive: 0x000000 }),
      glow: new THREE.MeshBasicMaterial({ color: 0xe3e7de })
    };
    this.boxGeometry = new THREE.BoxGeometry(1, 1, 1);
    this.road = [];
    for (let i = 0; i < 35; i++) {
      const section = new THREE.Group();
      section.add(this.box(5, 0.18, 4, 0, -0.1, 0, 'road'));
      section.add(this.box(0.1, 0.01, 1.1, 0, 0.002, 0, 'marker'));
      for (const side of [-1, 1]) {
        section.add(this.box(0.35, 0.6, 3.96, side * 2.65, 0.26, 0, 'wall'));
        section.add(this.box(0.45, 0.86, 0.45, side * 2.65, 0.43, 1.7, 'wall'));
        const height = 5 + ((i * 7 + (side + 1)) % 6);
        section.add(this.box(0.7, height, 0.7, side * (4.4 + i % 3), height/2, 0, 'dark'));
        if (i % 3 === 0) {
          section.add(this.box(0.12, 3.5, 0.12, side * 2.95, 1.75, 0, 'dark'));
          section.add(this.box(0.65, 0.08, 0.16, side * 2.7, 3.48, 0, 'glow'));
        }
      }
      this.road.push(section); this.scene.add(section);
    }
    this.avatar = this.person(1, 'body'); this.scene.add(this.avatar);
    this.follower = this.person(3, 'dark'); this.scene.add(this.follower);
    this.cameraA = new THREE.PerspectiveCamera(68, 1, 0.05, 100);
    this.cameraA.rotation.order = 'YXZ'; this.cameraA.layers.enable(3);
    this.cameraB = new THREE.PerspectiveCamera(70, 1, 0.05, 100);
    this.cameraB.layers.enable(1); this.cameraB.layers.enable(2);
    this.scene.add(this.cameraA, this.cameraB);
    this.hands = [];
    for (const side of [-1, 1]) {
      const arm = new THREE.Group();
      arm.add(this.box(0.14, 0.14, 0.45, 0, 0, 0, 'hand', 2));
      arm.add(this.box(0.19, 0.1, 0.2, 0, 0, -0.28, 'hand', 2));
      // Four rectangular fingers communicate the hand without art assets.
      for (let finger = 0; finger < 4; finger++) arm.add(this.box(0.035, 0.065, 0.15, -0.068 + finger * 0.045, 0, -0.435, 'hand', 2));
      arm.position.set(side * 0.34, -0.37, -0.55);
      arm.rotation.set(-0.22, side * -0.24, side * -0.15);
      this.cameraB.add(arm); this.hands.push(arm);
    }
    this.monsterMeshes = new Map();
  }
  box(w,h,d,x,y,z,material,layer=0) {
    const mesh = new THREE.Mesh(this.boxGeometry, this.materials[material]);
    mesh.scale.set(w,h,d); mesh.position.set(x,y,z); mesh.layers.set(layer); return mesh;
  }
  person(layer, material) {
    const group = new THREE.Group();
    group.add(this.box(0.48,0.62,0.26,0,1.11,0,material,layer));
    group.add(this.box(0.28,0.31,0.27,0,1.59,0,material,layer));
    for (const side of [-1, 1]) {
      const arm = this.box(0.14,0.6,0.17,side*0.32,1.02,0,material,layer); group.add(arm);
      const leg = this.box(0.17,0.75,0.2,side*0.14,0.39,0,material,layer); group.add(leg);
      group.add(this.box(0.19,0.12,0.32,side*0.14,0.06,-0.05,material,layer));
    }
    return group;
  }
  update(model, motion) {
    const z = -model.distance;
    const base = -Math.floor(model.distance / 4) * 4;
    this.road.forEach((section, i) => section.position.z = base + 12 - i * 4);
    const walking = model.status === 'playing';
    const bob = motion ? Math.sin(model.time * 8) * 0.018 : 0;
    this.cameraA.position.set(0, 1.65 + bob, z);
    this.cameraA.rotation.set(model.pitch, model.yaw, 0, 'YXZ');
    this.cameraB.position.set(0, 1.59 + bob * .7, z + model.config.followDistance);
    this.cameraB.rotation.set(-0.08, 0, 0);
    this.avatar.position.set(0,0,z); this.avatar.rotation.y = model.yaw * 0.22;
    this.follower.position.set(0,0,z + model.config.followDistance);
    // Limb swinging only reflects game time and freezes while paused.
    for (const [index, limb] of this.avatar.children.entries()) {
      if (index === 2 || index === 3 || index === 5 || index === 6) limb.rotation.x = Math.sin(model.time*8 + index*Math.PI) * 0.12;
    }
    const tapAge = model.time - model.lastTap;
    const tapPose = model.taps > 0 && tapAge < 0.65 ? Math.sin(Math.PI * tapAge / 0.65) : 0;
    this.hands[0].position.set(-0.34, -0.37 + (walking ? bob : 0), -0.55);
    this.hands[1].position.set(0.34 - tapPose * 0.03, -0.37 + tapPose * 0.43 + bob, -0.55 - tapPose * 0.28);
    this.hands[1].rotation.x = -0.22 + tapPose * 0.18;
    const ids = new Set(model.monsters.map(m=>m.id));
    for (const [id, mesh] of this.monsterMeshes) if (!ids.has(id)) { this.scene.remove(mesh); this.monsterMeshes.delete(id); }
    for (const monster of model.monsters) {
      let mesh = this.monsterMeshes.get(monster.id);
      if (!mesh) {
        mesh = this.person(3, 'monster'); mesh.scale.set(1.3, 1.3, 1.3);
        mesh.add(this.box(.035,.035,.04,-.07,1.64,.145,'glow',3));
        mesh.add(this.box(.035,.035,.04,.07,1.64,.145,'glow',3));
        this.scene.add(mesh); this.monsterMeshes.set(monster.id, mesh);
      }
      const approach = Math.min(1, monster.age / model.config.monsterAttackTime);
      mesh.position.set(monster.lane, monster.attacked ? -(monster.age - model.config.monsterAttackTime) * 4 : 0, z - (18 - approach*17.1));
      mesh.rotation.z = Math.sin(monster.age * 13) * .035;
      mesh.children[2].rotation.x = -approach * 1.2;
      mesh.children[5].rotation.x = -approach * 1.2;
    }
  }
}
