import * as THREE from 'three';

export class ThirdPersonCamera {
  constructor(camera, domElement) {
    this.camera = camera;
    this.domElement = domElement;

    // Base FOV
    this.baseFov = 60;
    this.targetFov = 60;

    // Spherical coordinates
    this.distance = 9.5;
    this.targetDistance = 9.5;
    this.minDistance = 4.0;
    this.maxDistance = 18.0;

    this.yaw = Math.PI;          // Face forward towards +Z adventure progression
    this.pitch = 0.38;          // Elevated angle looking down nicely at player
    this.targetYaw = Math.PI;
    this.targetPitch = 0.38;

    this.lookOffset = new THREE.Vector3(0, 1.4, 0);
    this.currentPosition = new THREE.Vector3(0, 5, -9.5);
    this.currentLookAt = new THREE.Vector3(0, 1.5, 0);
    this.initialized = false;

    // Screen Shake system
    this.trauma = 0;
    this.maxShakeOffset = 0.45;

    // Mouse drag state
    this.isDragging = false;
    this.previousMousePosition = { x: 0, y: 0 };
    this.sensitivity = 0.004;

    this.setupListeners();
  }

  setupListeners() {
    this.domElement.addEventListener('mousedown', (e) => {
      this.isDragging = true;
      this.previousMousePosition = { x: e.clientX, y: e.clientY };
    });

    window.addEventListener('mouseup', () => {
      this.isDragging = false;
    });

    window.addEventListener('mousemove', (e) => {
      if (!this.isDragging) return;

      const deltaX = e.clientX - this.previousMousePosition.x;
      const deltaY = e.clientY - this.previousMousePosition.y;

      this.targetYaw -= deltaX * this.sensitivity;
      this.targetPitch += deltaY * this.sensitivity;

      // Clamp vertical pitch to avoid flipping or digging below ground
      this.targetPitch = Math.max(0.08, Math.min(Math.PI / 2.3, this.targetPitch));

      this.previousMousePosition = { x: e.clientX, y: e.clientY };
    });

    // Mouse wheel zoom
    this.domElement.addEventListener('wheel', (e) => {
      e.preventDefault();
      this.targetDistance += e.deltaY * 0.008;
      this.targetDistance = Math.max(this.minDistance, Math.min(this.maxDistance, this.targetDistance));
    }, { passive: false });

    // Touch controls for mobile camera orbiting
    let touchStartX = 0;
    let touchStartY = 0;
    this.domElement.addEventListener('touchstart', (e) => {
      if (e.touches.length === 1 && !e.target.closest('.touch-btn')) {
        touchStartX = e.touches[0].clientX;
        touchStartY = e.touches[0].clientY;
      }
    }, { passive: true });

    this.domElement.addEventListener('touchmove', (e) => {
      if (e.touches.length === 1 && !e.target.closest('.touch-btn')) {
        const deltaX = e.touches[0].clientX - touchStartX;
        const deltaY = e.touches[0].clientY - touchStartY;

        this.targetYaw -= deltaX * this.sensitivity * 1.5;
        this.targetPitch += deltaY * this.sensitivity * 1.5;
        this.targetPitch = Math.max(0.08, Math.min(Math.PI / 2.3, this.targetPitch));

        touchStartX = e.touches[0].clientX;
        touchStartY = e.touches[0].clientY;
      }
    }, { passive: true });

    // Screen Shake listener
    window.addEventListener('screenShake', (e) => {
      const intensity = (e.detail && e.detail.intensity) ? e.detail.intensity : 10;
      this.addTrauma(intensity / 15);
    });
  }

  addTrauma(amount) {
    this.trauma = Math.min(1.0, this.trauma + amount);
  }

  rotateBy(yawDelta) {
    this.targetYaw += yawDelta;
  }

  update(delta, player, colliders = []) {
    // 1. Dynamic Speed FOV Expansion
    const speedH = Math.hypot(player.velocity.x, player.velocity.z);
    if (player.isDiving || speedH > 18) {
      this.targetFov = 71; // High sensation of speed
    } else {
      this.targetFov = this.baseFov;
    }

    if (Math.abs(this.camera.fov - this.targetFov) > 0.1) {
      this.camera.fov = THREE.MathUtils.lerp(this.camera.fov, this.targetFov, Math.min(8 * delta, 1));
      this.camera.updateProjectionMatrix();
    }

    // 2. Smooth angle & distance interpolation
    this.yaw = THREE.MathUtils.lerp(this.yaw, this.targetYaw, Math.min(14 * delta, 1));
    this.pitch = THREE.MathUtils.lerp(this.pitch, this.targetPitch, Math.min(14 * delta, 1));
    this.distance = THREE.MathUtils.lerp(this.distance, this.targetDistance, Math.min(10 * delta, 1));

    // Player target focus point
    const targetLook = player.mesh.position.clone().add(this.lookOffset);

    // Calculate desired camera position on spherical orbit
    const cx = targetLook.x + this.distance * Math.sin(this.yaw) * Math.cos(this.pitch);
    const cy = targetLook.y + this.distance * Math.sin(this.pitch);
    const cz = targetLook.z + this.distance * Math.cos(this.yaw) * Math.cos(this.pitch);
    const desiredPos = new THREE.Vector3(cx, cy, cz);

    // Platform collision clamping
    for (const c of colliders) {
      if (!c.box) continue;
      if (
        desiredPos.x >= c.box.min.x - 0.5 && desiredPos.x <= c.box.max.x + 0.5 &&
        desiredPos.z >= c.box.min.z - 0.5 && desiredPos.z <= c.box.max.z + 0.5
      ) {
        if (desiredPos.y >= c.box.min.y - 1.0 && desiredPos.y < c.box.max.y + 0.8 && c.box.max.y <= targetLook.y + 1.0) {
          desiredPos.y = c.box.max.y + 0.8;
        }
      }
    }

    // Smooth camera motion
    if (!this.initialized) {
      this.currentPosition.copy(desiredPos);
      this.currentLookAt.copy(targetLook);
      this.initialized = true;
    } else {
      this.currentPosition.lerp(desiredPos, Math.min(12 * delta, 1));
      this.currentLookAt.lerp(targetLook, Math.min(15 * delta, 1));
    }

    // 3. Screen Shake calculation (trauma^2 non-linear falloff)
    const finalPos = this.currentPosition.clone();
    const finalLook = this.currentLookAt.clone();

    if (this.trauma > 0) {
      const shakePower = this.trauma * this.trauma * this.maxShakeOffset;
      const shakeOffset = new THREE.Vector3(
        (Math.random() - 0.5) * shakePower,
        (Math.random() - 0.5) * shakePower,
        (Math.random() - 0.5) * shakePower
      );
      finalPos.add(shakeOffset);
      finalLook.add(shakeOffset);

      this.trauma = Math.max(0, this.trauma - delta * 2.5);
    }

    this.camera.position.copy(finalPos);
    this.camera.lookAt(finalLook);
  }
}
