import * as THREE from 'three';

export class Effects {
  constructor(scene) { this.scene = scene; this.active = []; }

  burst(position, color = 0x111514, count = 36) {
    const positions = new Float32Array(count * 3);
    const velocities = [];
    for (let i = 0; i < count; i++) {
      const v = new THREE.Vector3().randomDirection().multiplyScalar(1.3 + Math.random() * 2.6);
      v.y = Math.abs(v.y) + 0.4;
      velocities.push(v);
    }
    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    const material = new THREE.PointsMaterial({ color, size: 0.18, transparent: true, opacity: 0.92, depthWrite: false });
    const points = new THREE.Points(geometry, material);
    points.position.copy(position);
    this.scene.add(points);
    this.active.push({ points, velocities, age: 0, life: 0.65 });
  }

  tracer(start, end) {
    const geometry = new THREE.BufferGeometry().setFromPoints([start, end]);
    const material = new THREE.LineBasicMaterial({ color: 0xdce9e4, transparent: true, opacity: 0.8 });
    const line = new THREE.Line(geometry, material);
    this.scene.add(line);
    this.active.push({ points: line, velocities: null, age: 0, life: 0.16 });
  }

  update(dt) {
    for (let i = this.active.length - 1; i >= 0; i--) {
      const effect = this.active[i];
      effect.age += dt;
      effect.points.material.opacity = Math.max(0, 1 - effect.age / effect.life);
      if (effect.velocities) {
        const positions = effect.points.geometry.attributes.position;
        for (let j = 0; j < effect.velocities.length; j++) {
          const v = effect.velocities[j];
          positions.array[j * 3] += v.x * dt;
          positions.array[j * 3 + 1] += v.y * dt;
          positions.array[j * 3 + 2] += v.z * dt;
          v.y -= 4.5 * dt;
        }
        positions.needsUpdate = true;
      }
      if (effect.age >= effect.life) {
        this.scene.remove(effect.points);
        effect.points.geometry.dispose();
        effect.points.material.dispose();
        this.active.splice(i, 1);
      }
    }
  }
}
