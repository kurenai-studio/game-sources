/**
 * enemy-ranged.js — 远程敌人
 * 行为：巡逻 → 发现玩家 → 保持距离 → 发射弹幕
 */
import * as THREE from 'three';
import { Enemy, EnemyState } from './enemy.js';
import { createRangedEnemyTexture, createProjectileTexture } from './textures.js';
import {
    RANGED_PATROL_SPEED, RANGED_CHASE_SPEED,
    RANGED_ATTACK_COOLDOWN, PROJECTILE_SPEED,
    PROJECTILE_DAMAGE, ENEMY_SIGHT_RANGE, RANGED_HP,
} from './config.js';

/** 远程攻击理想距离（保持在此距离射击） */
const IDEAL_RANGE = 200;
const MIN_RANGE = 100;

/**
 * 弹幕类 - 远程敌人发射的投射物
 */
export class Projectile {
    constructor(x, y, dirX) {
        this.x = x;
        this.y = y;
        this.vx = dirX * PROJECTILE_SPEED;
        this.vy = 0;
        this.radius = 7;
        this.dead = false;
        this.lifetime = 0;
        this.maxLifetime = 3.0;

        // 创建精灵
        const texture = createProjectileTexture();
        const material = new THREE.SpriteMaterial({
            map: texture,
            transparent: true,
            depthWrite: false,
            depthTest: true,
        });
        this.sprite = new THREE.Sprite(material);
        this.sprite.scale.set(16, 16, 1);
        this.sprite.position.set(x, y, 6);
    }

    /**
     * 更新弹幕
     */
    update(dt) {
        this.x += this.vx * dt;
        this.y += this.vy * dt;
        this.lifetime += dt;

        if (this.lifetime > this.maxLifetime) {
            this.dead = true;
        }

        this.sprite.position.set(this.x, this.y, 6);

        // 脉冲效果
        const pulse = 1 + Math.sin(this.lifetime * 10) * 0.2;
        this.sprite.scale.set(16 * pulse, 16 * pulse, 1);
    }

    /**
     * 从场景移除
     */
    remove(scene) {
        scene.remove(this.sprite);
        this.sprite.material.map.dispose();
        this.sprite.material.dispose();
    }
}

export class RangedEnemy extends Enemy {
    constructor(x, y, patrolMinX, patrolMaxX) {
        super(x, y, RANGED_HP, patrolMinX, patrolMaxX);

        // ===== 精灵 =====
        const texture = createRangedEnemyTexture(0, false);
        const material = new THREE.SpriteMaterial({
            map: texture,
            transparent: true,
            depthWrite: false,
            depthTest: true,
        });
        this.sprite = new THREE.Sprite(material);
        this.sprite.scale.set(48, 48, 1);
        this.sprite.position.set(x, y, 4);

        // ===== 弹幕列表 =====
        this.projectiles = [];
    }

    /**
     * 更新远程敌人AI
     */
    update(dt, player, platforms) {
        super.update(dt, player);
        if (this.isDead) return;

        const { dist, dirX } = this.getPlayerInfo(player);
        this.facingRight = dirX > 0;

        switch (this.state) {
            case EnemyState.IDLE:
                this.state = EnemyState.PATROL;
                break;

            case EnemyState.PATROL:
                this.updatePatrol(dt, player, platforms);
                break;

            case EnemyState.CHASE:
                this.updateChase(dt, player);
                break;

            case EnemyState.ATTACK:
                this.updateAttack(dt);
                break;

            case EnemyState.HURT:
                this.updateHurt(dt);
                break;
        }

        // 发现玩家
        if ((this.state === EnemyState.PATROL || this.state === EnemyState.IDLE) &&
            dist < ENEMY_SIGHT_RANGE) {
            this.state = EnemyState.CHASE;
            this.stateTime = 0;
        }

        this.applyGravity(dt);
        this.updateSprite();

        // 更新弹幕
        for (const proj of this.projectiles) {
            proj.update(dt);
        }
        // 清理死亡弹幕
        this.projectiles = this.projectiles.filter(p => !p.dead);

        // 仅在状态或朝向改变时更新纹理
        const targetFrame = this.state === EnemyState.ATTACK ? 2 : 0;
        if (this._lastFrame !== targetFrame || this._lastFacing !== this.facingRight) {
            this._lastFrame = targetFrame;
            this._lastFacing = this.facingRight;
            const newTex = createRangedEnemyTexture(targetFrame, this.facingRight);
            this.sprite.material.map.dispose();
            this.sprite.material.map = newTex;
            this.sprite.material.needsUpdate = true;
        }

        // 死亡消散
        if (this.isDying) {
            const progress = this.stateTime / 0.6;
            this.sprite.scale.set(
                48 * (1 - progress * 0.5),
                48 * (1 - progress * 0.5),
                1
            );
            this.sprite.material.opacity = 1 - progress;
        }
    }

    /**
     * 巡逻
     */
    updatePatrol(dt, player, platforms) {
        this.vx = this.patrolDir * RANGED_PATROL_SPEED;

        if (this.x <= this.patrolMinX) this.patrolDir = 1;
        else if (this.x >= this.patrolMaxX) this.patrolDir = -1;

        // 边缘检测
        if (this.isGrounded) {
            const checkX = this.x + this.patrolDir * 20;
            let hasFloor = false;
            for (const plat of platforms) {
                if (checkX > plat.left && checkX < plat.right &&
                    this.y + this.height / 2 >= plat.top - 5 &&
                    this.y + this.height / 2 <= plat.top + 20) {
                    hasFloor = true;
                    break;
                }
            }
            if (!hasFloor) this.patrolDir *= -1;
        }
    }

    /**
     * 追击：保持在理想射击距离
     */
    updateChase(dt, player) {
        const { dist, dirX } = this.getPlayerInfo(player);

        if (dist > ENEMY_SIGHT_RANGE * 1.3) {
            // 超出视野 → 回到巡逻
            this.state = EnemyState.PATROL;
            this.stateTime = 0;
        } else if (dist > IDEAL_RANGE) {
            // 太远 → 靠近
            this.vx = dirX * RANGED_CHASE_SPEED;
        } else if (dist < MIN_RANGE) {
            // 太近 → 后退
            this.vx = -dirX * RANGED_CHASE_SPEED * 0.7;
        } else {
            // 距离合适 → 停下来准备射击
            this.vx *= 0.9;
        }

        // 可以攻击时发射弹幕
        if (this.attackCooldown <= 0 && dist < IDEAL_RANGE + 40) {
            this.state = EnemyState.ATTACK;
            this.stateTime = 0;
            this.attackCooldown = RANGED_ATTACK_COOLDOWN;
            this.vx = 0;
            this.fireProjectile(dirX);
        }
    }

    /**
     * 发射弹幕
     */
    fireProjectile(dirX) {
        const proj = new Projectile(
            this.x + dirX * 20,
            this.y - 5,
            dirX
        );
        this.projectiles.push(proj);
    }

    /**
     * 攻击状态
     */
    updateAttack(dt) {
        if (this.stateTime > 0.3) {
            this.state = EnemyState.CHASE;
            this.stateTime = 0;
        }
    }

    /**
     * 受伤硬直
     */
    updateHurt(dt) {
        this.vx *= 0.8;
        if (this.stateTime > 0.25) {
            this.state = EnemyState.CHASE;
            this.stateTime = 0;
        }
    }

    /**
     * 获取活跃弹幕
     */
    getActiveProjectiles() {
        return this.projectiles.filter(p => !p.dead);
    }

    /**
     * 清理所有弹幕
     */
    clearProjectiles(scene) {
        for (const proj of this.projectiles) {
            proj.remove(scene);
        }
        this.projectiles = [];
    }
}
