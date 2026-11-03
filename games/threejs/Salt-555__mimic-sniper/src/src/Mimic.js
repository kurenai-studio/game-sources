import * as THREE from 'three';

const BLACK = new THREE.MeshStandardMaterial({ color: 0x050606, roughness: 0.72, metalness: 0.12, flatShading: true });

export class Mimic {
  constructor(scene) {
    this.scene = scene;
    this.group = new THREE.Group();
    this.group.position.set(0, 1.35, 8);
    scene.add(this.group);

    this.body = new THREE.Mesh(new THREE.IcosahedronGeometry(0.78, 1), BLACK);
    this.body.castShadow = true;
    this.body.userData.isMimic = true;
    this.group.add(this.body);

    this.legs = [];
    for (let i = 0; i < 6; i++) this.createLeg(i);

    this.disguise = null;
    this.speed = 4.5;
    this.bounds = 32;
    this.phase = 0;
  }

  createLeg(index) {
    const angle = (index / 6) * Math.PI * 2;
    const root = new THREE.Group();
    root.position.set(Math.cos(angle) * 0.52, -0.3, Math.sin(angle) * 0.52);
    root.rotation.y = -angle;
    const upper = new THREE.Mesh(new THREE.CylinderGeometry(0.075, 0.11, 0.9, 5), BLACK);
    upper.position.y = -0.42; upper.rotation.z = -0.75;
    const lower = new THREE.Mesh(new THREE.CylinderGeometry(0.025, 0.075, 1.15, 5), BLACK);
    lower.position.set(0.68, -0.84, 0); lower.rotation.z = 0.95;
    upper.castShadow = lower.castShadow = true;
    root.add(upper, lower);
    this.group.add(root);
    this.legs.push({ root, upper, lower, offset: index * 1.7 });
  }

  update(dt, input, active) {
    if (!active) return;
    const x = input.axis('KeyD', 'KeyA');
    const z = input.axis('KeyS', 'KeyW');
    const length = Math.hypot(x, z);
    const moving = length > 0;
    if (moving) {
      this.group.position.x += (x / length) * this.speed * dt;
      this.group.position.z += (z / length) * this.speed * dt;
      this.group.position.x = THREE.MathUtils.clamp(this.group.position.x, -this.bounds, this.bounds);
      this.group.position.z = THREE.MathUtils.clamp(this.group.position.z, -26, 26);
      this.group.rotation.y = THREE.MathUtils.lerp(this.group.rotation.y, Math.atan2(x, z), Math.min(1, dt * 8));
    }

    this.phase += dt * (moving ? 9 : 2.2);
    this.group.position.y = 1.25 + Math.sin(this.phase * 0.5) * 0.08;
    for (const leg of this.legs) {
      const step = Math.sin(this.phase + leg.offset) * (moving ? 0.5 : 0.12);
      leg.root.rotation.x = step;
      leg.upper.rotation.z = -0.72 + Math.max(0, step) * 0.45;
      leg.lower.rotation.z = 0.98 - Math.min(0, step) * 0.55;
    }

    if (this.disguise) {
      this.disguise.position.copy(this.group.position);
      this.disguise.rotation.y = this.group.rotation.y;
    }
  }

  transformInto(prop, poof) {
    if (!prop) return false;
    if (this.disguise) this.reveal(poof);
    this.disguise = prop.clone();
    this.disguise.material = prop.material.clone();
    this.disguise.userData.isMimic = true;
    this.disguise.userData.isDisguise = true;
    this.scene.add(this.disguise);
    this.group.visible = false;
    poof(this.group.position);
    return true;
  }

  reveal(poof) {
    if (!this.disguise) return;
    this.group.position.copy(this.disguise.position);
    poof(this.disguise.position);
    this.scene.remove(this.disguise);
    this.disguise.geometry.dispose();
    this.disguise.material.dispose();
    this.disguise = null;
    this.group.visible = true;
  }

  shootable() { return this.disguise ?? this.body; }
  reset() {
    if (this.disguise) {
      this.scene.remove(this.disguise);
      this.disguise = null;
    }
    this.group.visible = true;
    this.group.position.set(0, 1.35, 8);
  }
}
