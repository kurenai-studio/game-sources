/**
 * effects.js — 视觉特效系统
 * 管理打击火花、伤害飘字、屏幕震动、攻击拖尾、敌人消散等特效
 */
import * as THREE from 'three';
import { createParticleTexture, createDamageNumberCanvas, createSlashTexture } from './textures.js';
import {
    DAMAGE_NUMBER_DURATION, PARTICLE_LIFETIME,
    SCREEN_SHAKE_DURATION, SCREEN_SHAKE_INTENSITY,
    COLORS,
} from './config.js';

// ==================== 粒子特效 ====================

/**
 * 单个粒子
 */
class Particle {
    constructor(x, y, vx, vy, color, lifetime, size) {
        this.x = x;
        this.y = y;
        this.vx = vx;
        this.vy = vy;
        this.lifetime = lifetime;
        this.maxLifetime = lifetime;
        this.size = size || 6;

        const texture = createParticleTexture(color);
        const material = new THREE.SpriteMaterial({
            map: texture,
            transparent: true,
            depthWrite: false,
            blending: THREE.AdditiveBlending,
        });
        this.sprite = new THREE.Sprite(material);
        this.sprite.scale.set(this.size, this.size, 1);
        this.sprite.position.set(x, y, 8);
    }

    update(dt) {
        this.lifetime -= dt;
        this.x += this.vx * dt;
        this.y += this.vy * dt;
        this.vy += 300 * dt; // 粒子微重力

        const progress = 1 - this.lifetime / this.maxLifetime;
        this.sprite.position.set(this.x, this.y, 8);
        this.sprite.scale.set(
            this.size * (1 - progress * 0.5),
            this.size * (1 - progress * 0.5),
            1
        );
        this.sprite.material.opacity = 1 - progress;
    }

    get dead() {
        return this.lifetime <= 0;
    }

    remove(scene) {
        scene.remove(this.sprite);
        this.sprite.material.map.dispose();
        this.sprite.material.dispose();
    }
}

// ==================== 伤害飘字 ====================

/**
 * 伤害/治疗数字
 */
class DamageNumber {
    constructor(x, y, text, color) {
        this.x = x;
        this.y = y;
        this.lifetime = DAMAGE_NUMBER_DURATION;
        this.maxLifetime = DAMAGE_NUMBER_DURATION;

        const canvas = createDamageNumberCanvas(text, color);
        const texture = new THREE.CanvasTexture(canvas);
        texture.minFilter = THREE.NearestFilter;
        texture.magFilter = THREE.NearestFilter;

        const material = new THREE.SpriteMaterial({
            map: texture,
            transparent: true,
            depthWrite: false,
        });
        this.sprite = new THREE.Sprite(material);
        this.sprite.scale.set(48, 24, 1);
        this.sprite.position.set(x, y - 20, 9);
    }

    update(dt) {
        this.lifetime -= dt;
        this.y -= 60 * dt; // 向上飘

        const progress = 1 - this.lifetime / this.maxLifetime;
        this.sprite.position.set(this.x, this.y, 9);
        this.sprite.material.opacity = 1 - progress;
    }

    get dead() {
        return this.lifetime <= 0;
    }

    remove(scene) {
        scene.remove(this.sprite);
        this.sprite.material.map.dispose();
        this.sprite.material.dispose();
    }
}

// ==================== 斩击特效 ====================

/**
 * 攻击斩击弧光
 */
class SlashEffect {
    constructor(x, y, facingRight) {
        this.lifetime = 0.15;
        this.maxLifetime = 0.15;

        const texture = createSlashTexture();
        const material = new THREE.SpriteMaterial({
            map: texture,
            transparent: true,
            depthWrite: false,
            blending: THREE.AdditiveBlending,
        });
        this.sprite = new THREE.Sprite(material);
        this.sprite.scale.set(facingRight ? 50 : -50, 18, 1);
        this.sprite.position.set(
            x + (facingRight ? 25 : -25),
            y,
            7
        );
    }

    update(dt) {
        this.lifetime -= dt;
        const progress = 1 - this.lifetime / this.maxLifetime;
        this.sprite.material.opacity = 1 - progress;
        this.sprite.scale.x *= 0.95;
    }

    get dead() {
        return this.lifetime <= 0;
    }

    remove(scene) {
        scene.remove(this.sprite);
        this.sprite.material.map.dispose();
        this.sprite.material.dispose();
    }
}

// ==================== 特效管理器 ====================

export class EffectsManager {
    constructor(scene) {
        /** @type {THREE.Scene} */
        this.scene = scene;

        /** @type {Particle[]} */
        this.particles = [];

        /** @type {DamageNumber[]} */
        this.damageNumbers = [];

        /** @type {SlashEffect[]} */
        this.slashEffects = [];

        /** 屏幕震动状态 */
        this.shakeIntensity = 0;
        this.shakeTimer = 0;

        /** 攻击拖尾精灵 */
        this.trailSprites = [];
    }

    /**
     * 生成打击火花粒子
     * @param {number} x - 世界X
     * @param {number} y - 世界Y
     * @param {number} count - 粒子数量
     */
    spawnHitSparks(x, y, count = 8) {
        for (let i = 0; i < count; i++) {
            const angle = Math.random() * Math.PI * 2;
            const speed = 100 + Math.random() * 200;
            const vx = Math.cos(angle) * speed;
            const vy = Math.sin(angle) * speed - 100;
            const color = i % 2 === 0 ? COLORS.hitSpark : '#ffffff';
            const p = new Particle(x, y, vx, vy, color, PARTICLE_LIFETIME, 4 + Math.random() * 4);
            this.particles.push(p);
            this.scene.add(p.sprite);
        }
    }

    /**
     * 生成伤害飘字
     * @param {number} x
     * @param {number} y
     * @param {number} damage
     * @param {boolean} isHeal - 是否是治疗
     */
    spawnDamageNumber(x, y, damage, isHeal = false) {
        const text = isHeal ? `+${damage}` : `-${damage}`;
        const color = isHeal ? COLORS.healNumber : COLORS.damageNumber;
        const dn = new DamageNumber(x, y, text, color);
        this.damageNumbers.push(dn);
        this.scene.add(dn.sprite);
    }

    /**
     * 生成斩击特效
     */
    spawnSlash(x, y, facingRight) {
        const slash = new SlashEffect(x, y, facingRight);
        this.slashEffects.push(slash);
        this.scene.add(slash.sprite);
    }

    /**
     * 触发屏幕震动
     * @param {number} intensity - 震动强度（覆盖默认值）
     */
    triggerScreenShake(intensity = SCREEN_SHAKE_INTENSITY) {
        this.shakeIntensity = intensity;
        this.shakeTimer = SCREEN_SHAKE_DURATION;
    }

    /**
     * 获取屏幕震动偏移
     * @returns {{ x: number, y: number }}
     */
    getShakeOffset() {
        if (this.shakeTimer <= 0) return { x: 0, y: 0 };
        const progress = this.shakeTimer / SCREEN_SHAKE_DURATION;
        const intensity = this.shakeIntensity * progress;
        return {
            x: (Math.random() - 0.5) * intensity * 2,
            y: (Math.random() - 0.5) * intensity * 2,
        };
    }

    /**
     * 每帧更新所有特效
     * @param {number} dt
     */
    update(dt) {
        // 粒子
        for (const p of this.particles) p.update(dt);
        this.particles = this.particles.filter(p => {
            if (p.dead) { p.remove(this.scene); return false; }
            return true;
        });

        // 飘字
        for (const dn of this.damageNumbers) dn.update(dt);
        this.damageNumbers = this.damageNumbers.filter(dn => {
            if (dn.dead) { dn.remove(this.scene); return false; }
            return true;
        });

        // 斩击
        for (const s of this.slashEffects) s.update(dt);
        this.slashEffects = this.slashEffects.filter(s => {
            if (s.dead) { s.remove(this.scene); return false; }
            return true;
        });

        // 震动
        if (this.shakeTimer > 0) {
            this.shakeTimer -= dt;
        }
    }

    /**
     * 清理所有特效
     */
    clearAll() {
        for (const p of this.particles) p.remove(this.scene);
        for (const dn of this.damageNumbers) dn.remove(this.scene);
        for (const s of this.slashEffects) s.remove(this.scene);
        this.particles = [];
        this.damageNumbers = [];
        this.slashEffects = [];
        this.shakeTimer = 0;
        this.shakeIntensity = 0;
    }
}
