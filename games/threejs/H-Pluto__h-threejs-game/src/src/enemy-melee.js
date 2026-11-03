/**
 * enemy-melee.js — 近战敌人
 * 行为：巡逻 → 发现玩家 → 追击 → 近身攻击
 */
import * as THREE from 'three';
import { Enemy, EnemyState } from './enemy.js';
import { createMeleeEnemyTexture } from './textures.js';
import {
    MELEE_PATROL_SPEED, MELEE_CHASE_SPEED,
    MELEE_ATTACK_COOLDOWN, MELEE_ATTACK_DAMAGE,
    ENEMY_SIGHT_RANGE, MELEE_HP,
} from './config.js';

/** 近战攻击距离 */
const MELEE_ATTACK_RANGE = 40;

export class MeleeEnemy extends Enemy {
    constructor(x, y, patrolMinX, patrolMaxX) {
        super(x, y, MELEE_HP, patrolMinX, patrolMaxX);

        // ===== 精灵 =====
        const texture = createMeleeEnemyTexture(0, false);
        const material = new THREE.SpriteMaterial({
            map: texture,
            transparent: true,
            depthWrite: false,
            depthTest: true,
        });
        this.sprite = new THREE.Sprite(material);
        this.sprite.scale.set(48, 48, 1);
        this.sprite.position.set(x, y, 4);

        // ===== 巡逻 =====
        this.patrolDir = -1;
        this.facingRight = false;
    }

    /**
     * 更新近战敌人AI
     * @param {number} dt
     * @param {Object} player - 玩家对象
     * @param {Array} platforms - 平台数组（用于边缘检测）
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
                this.updateChase(dt, player, platforms);
                break;

            case EnemyState.ATTACK:
                this.updateAttack(dt);
                break;

            case EnemyState.HURT:
                this.updateHurt(dt);
                break;
        }

        // 发现玩家 → 切换追击
        if ((this.state === EnemyState.PATROL || this.state === EnemyState.IDLE) &&
            dist < ENEMY_SIGHT_RANGE) {
            this.state = EnemyState.CHASE;
            this.stateTime = 0;
        }

        this.applyGravity(dt);
        this.updateSprite();

        // 仅在状态或朝向改变时更新纹理
        const targetFrame = this.state === EnemyState.ATTACK ? 2 : 0;
        if (this._lastFrame !== targetFrame || this._lastFacing !== this.facingRight) {
            this._lastFrame = targetFrame;
            this._lastFacing = this.facingRight;
            const newTex = createMeleeEnemyTexture(targetFrame, this.facingRight);
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
     * 巡逻行为：在边界间来回移动，检测边缘
     */
    updatePatrol(dt, player, platforms) {
        this.vx = this.patrolDir * MELEE_PATROL_SPEED;

        // 到达巡逻边界 → 转向
        if (this.x <= this.patrolMinX) {
            this.patrolDir = 1;
        } else if (this.x >= this.patrolMaxX) {
            this.patrolDir = -1;
        }

        // 检测前方是否是悬崖（平台边缘）
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
            if (!hasFloor) {
                this.patrolDir *= -1;
            }
        }
    }

    /**
     * 追击行为：朝玩家移动，足够近时攻击
     */
    updateChase(dt, player, platforms) {
        const { dist, dirX } = this.getPlayerInfo(player);

        if (dist < MELEE_ATTACK_RANGE && this.attackCooldown <= 0) {
            // 进入攻击范围 → 攻击
            this.state = EnemyState.ATTACK;
            this.stateTime = 0;
            this.attackCooldown = MELEE_ATTACK_COOLDOWN;
            this.vx = 0;
        } else if (dist > ENEMY_SIGHT_RANGE * 1.2) {
            // 超出视野 → 回到巡逻
            this.state = EnemyState.PATROL;
            this.stateTime = 0;
        } else {
            // 追击
            this.vx = dirX * MELEE_CHASE_SPEED;
        }
    }

    /**
     * 攻击状态
     */
    updateAttack(dt) {
        // 攻击动画持续0.3秒
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
     * 获取攻击伤害（在攻击判定帧调用）
     */
    getAttackDamage() {
        // 攻击帧在前0.15-0.2秒之间
        if (this.state === EnemyState.ATTACK &&
            this.stateTime > 0.1 && this.stateTime < 0.2) {
            return MELEE_ATTACK_DAMAGE;
        }
        return 0;
    }

    /**
     * 检查是否在攻击判定窗口内
     */
    isInAttackWindow() {
        return this.state === EnemyState.ATTACK &&
            this.stateTime > 0.1 && this.stateTime < 0.22;
    }

    /**
     * 获取攻击判定框
     */
    getAttackBox() {
        const range = 35;
        const offsetX = this.facingRight ? this.width / 2 : -(this.width / 2 + range);
        return {
            left: this.x + offsetX,
            right: this.x + offsetX + range,
            top: this.y - 25,
            bottom: this.y + 25,
        };
    }
}
