// Particle Manager - Optimized particle system with object pooling
import { PARTICLE_TYPES } from '../constants/gameParams.js';
import { getParticleColor } from '../utils/colorHelpers.js';

export class ParticleManager {
  constructor(scene, themeManager, gameElementsContainer, particlesGroup) {
    this.scene = scene;
    this.themeManager = themeManager;
    this.gameElementsContainer = gameElementsContainer;
    this.particles = particlesGroup || scene.add.group();
    this.particlePool = [];
    this.maxParticles = 150;
    this.activeParticles = 0;
  }

  createParticles(x, y, count, color, type = PARTICLE_TYPES.NORMAL) {
    const isExplosion = type === PARTICLE_TYPES.EXPLOSION;
    const availableSlots = this.maxParticles - this.activeParticles;
    const actualCount = Math.min(count, Math.max(0, availableSlots));
    
    if (actualCount <= 0) return;

    for (let i = 0; i < actualCount; i++) {
      let particle = this.getParticleFromPool();
      
      // If particle from pool is invalid or destroyed, create a new one
      if (!particle || !particle.scene || particle.scene.sys === undefined) {
        particle = this.createNewParticle();
      }
      
      this.initParticle(particle, x, y, isExplosion, color);
      this.particles.add(particle);
      
      // Only add to container if not already in it and particle is valid
      if (particle.scene && particle.scene.sys && (!particle.parentContainer || particle.parentContainer !== this.gameElementsContainer)) {
        this.gameElementsContainer.add(particle);
      }
      
      this.activeParticles++;
    }
  }

  getParticleFromPool() {
    if (this.particlePool.length > 0) {
      return this.particlePool.pop();
    }
    return null;
  }

  createNewParticle() {
    const particle = this.scene.add.graphics();
    particle.pooled = false;
    return particle;
  }

  initParticle(particle, x, y, isExplosion, color) {
    const angle = (Math.PI * 2 * Math.random());
    const speed = isExplosion ? Math.random() * 6 + 3 : Math.random() * 5 + 2;
    
    particle.x = x;
    particle.y = y;
    particle.vx = Math.cos(angle) * speed;
    particle.vy = Math.sin(angle) * speed;
    particle.life = isExplosion ? 50 : 40;
    particle.maxLife = particle.life;
    particle.size = Math.random() * 3 + 1;
    particle.color = color || getParticleColor(this.themeManager, PARTICLE_TYPES.DEFAULT);
    particle.dirty = true;
    particle.lastDrawnAlpha = -1;
    particle.active = true;
  }

  update() {
    const particlesToRemove = [];
    const children = this.particles.getChildren();
    const childrenLength = children.length;

    // Limit particles if too many
    if (childrenLength > this.maxParticles) {
      const toRemove = childrenLength - this.maxParticles;
      for (let i = childrenLength - 1; i >= 0 && particlesToRemove.length < toRemove; i--) {
        const particle = children[i];
        if (particle.active) {
          this.removeParticle(particle);
          particlesToRemove.push(particle);
        }
      }
    }

    // Update remaining particles
    const updatedChildren = this.particles.getChildren();
    const updatedLength = updatedChildren.length;

    for (let i = 0; i < updatedLength; i++) {
      const particle = updatedChildren[i];
      if (!particle.active) continue;

      particle.x += particle.vx;
      particle.y += particle.vy;
      particle.vx *= 0.96;
      particle.vy *= 0.96;
      particle.life--;

      if (particle.life <= 0) {
        this.removeParticle(particle);
        particlesToRemove.push(particle);
      } else {
        this.drawParticle(particle);
      }
    }

    // Clean up removed particles
    for (const particle of particlesToRemove) {
      this.activeParticles--;
      this.particles.remove(particle, true, true);
      this.gameElementsContainer.remove(particle);
      this.returnParticleToPool(particle);
    }
  }

  drawParticle(particle) {
    const alpha = particle.life / particle.maxLife;
    
    if (Math.abs(particle.lastDrawnAlpha - alpha) < 0.05 && !particle.dirty) {
      return;
    }

    particle.clear();
    particle.fillStyle(particle.color, alpha);
    const size = particle.size * alpha;
    particle.fillCircle(0, 0, size);
    
    particle.lastDrawnAlpha = alpha;
    particle.dirty = false;
  }

  removeParticle(particle) {
    particle.active = false;
    particle.clear();
  }

  returnParticleToPool(particle) {
    if (!particle || !particle.scene) {
      // Particle is already destroyed, don't add to pool
      return;
    }
    
    if (this.particlePool.length < 50) {
      particle.clear();
      particle.active = false;
      // Ensure particle is removed from container before pooling
      if (this.gameElementsContainer && particle.parentContainer === this.gameElementsContainer) {
        this.gameElementsContainer.remove(particle);
      }
      this.particlePool.push(particle);
    } else {
      particle.destroy();
    }
  }

  clear() {
    const children = this.particles.getChildren();
    for (const particle of children) {
      this.removeParticle(particle);
      this.returnParticleToPool(particle);
    }
    this.particles.clear(true, true);
    this.activeParticles = 0;
  }
}

