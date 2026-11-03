/**
 * player.js — 玩家类
 * 管理玩家状态机、移动、跳跃、攻击、受伤逻辑
 * 状态: idle → run → jump → fall → attack1 → attack2 → hurt → death
 */
import * as THREE from 'three';
import { createPlayerTexture } from './textures.js';
import {
    PLAYER_SPEED, PLAYER_JUMP_FORCE, PLAYER_FRICTION,
    PLAYER_AIR_CONTROL, GRAVITY, MAX_FALL_SPEED,
    PLAYER_MAX_HP, ATTACK1_DAMAGE, ATTACK2_DAMAGE,
    ATTACK_RANGE_X, ATTACK_RANGE_Y, COMBO_WINDOW,
    ATTACK1_DURATION, ATTACK2_DURATION,
    INVINCIBILITY_TIME, KNOCKBACK_FORCE,
    PIXEL_SCALE
} from './config.js';
import { isJumpPressed } from './input.js';

/** 玩家状态枚举 */
export const PlayerState = {
    IDLE: 'idle',
    RUN: 'run',
    JUMP: 'jump',
    FALL: 'fall',
    ATTACK1: 'attack1',
    ATTACK2: 'attack2',
    HURT: 'hurt',
    DEATH: 'death',
};

export class Player {
    constructor(x, y) {
        // ===== 位置与运动 =====
        this.x = x;
        this.y = y;
        this.vx = 0;        // 水平速度
        this.vy = 0;        // 垂直速度
        this.width = 28;    // 碰撞宽度
        this.height = 38;   // 碰撞高度
        this.facingRight = true;

        // ===== 状态 =====
        this.state = PlayerState.IDLE;
        this.stateTime = 0;         // 当前状态持续时间
        this.isGrounded = false;
        this.jumpHeld = false;      // 是否持续按住跳跃
        this.jumpBufferTime = 0;    // 跳跃缓冲（落地前按跳）
        this.canAttack = true;

        // ===== 战斗 =====
        this.hp = PLAYER_MAX_HP;
        this.maxHp = PLAYER_MAX_HP;
        this.invincible = false;    // 无敌状态
        this.invincibleTimer = 0;
        this.comboCount = 0;        // 当前连击数
        this.comboTimer = 0;        // 连击窗口计时器
        this.knockbackVx = 0;       // 击退速度
        this.flashTimer = 0;        // 受伤闪白计时

        // ===== 动画帧 =====
        this.animFrame = 0;         // 0=idle, 1=run1, 2=run2
        this.animTimer = 0;
        this.animInterval = 0.12;   // 跑步动画帧间隔（秒）

        // ===== 攻击状态 =====
        this.attackHit = false;     // 当前攻击是否已造成伤害（防止重复判定）
        this.attackBox = null;      // 当前攻击的AABB { left, right, top, bottom }

        // ===== Three.js精灵 =====
        this.texture = createPlayerTexture(0, true);
        const material = new THREE.SpriteMaterial({
            map: this.texture,
            transparent: true,
            depthWrite: false,
            depthTest: true,
        });
        this.sprite = new THREE.Sprite(material);
        this.sprite.scale.set(48, 48, 1);
        this.sprite.position.set(x, y, 5); // z=5 在平台前面

        // ===== 光晕光源（点光源跟随玩家） =====
        this.light = new THREE.PointLight(0xffaa66, 2.5, 300);
        this.light.position.set(x, y, 30);

        // ===== 跑步拖尾精灵列表 =====
        this.trailSprites = [];
    }

    /**
     * 添加玩家到场景
     */
    addToScene(scene) {
        scene.add(this.sprite);
        scene.add(this.light);
    }

    /**
     * 更新玩家纹理
     */
    updateTexture() {
        const frame = this.getTextureFrame();
        const newTex = createPlayerTexture(frame, this.facingRight);
        this.sprite.material.map.dispose();
        this.sprite.material.map = newTex;
        this.sprite.material.needsUpdate = true;
    }

    /**
     * 根据状态获取对应的动画帧索引
     */
    getTextureFrame() {
        switch (this.state) {
            case PlayerState.RUN:
                return this.animFrame === 0 ? 1 : 2;
            case PlayerState.JUMP:
            case PlayerState.FALL:
                return 3;
            case PlayerState.ATTACK1:
                return 4;
            case PlayerState.ATTACK2:
                return 5;
            case PlayerState.HURT:
                return 3; // 受伤用跳帧代替
            default:
                return 0; // idle
        }
    }

    /**
     * 获取碰撞AABB
     */
    getAABB() {
        return {
            left: this.x - this.width / 2,
            right: this.x + this.width / 2,
            top: this.y - this.height / 2,
            bottom: this.y + this.height / 2,
        };
    }

    /**
     * 获取攻击判定框（在玩家前方）
     */
    getAttackBox() {
        const boxW = ATTACK_RANGE_X;
        const boxH = ATTACK_RANGE_Y;
        const offsetX = this.facingRight ? this.width / 2 : -(this.width / 2 + boxW);
        return {
            left: this.x + offsetX,
            right: this.x + offsetX + boxW,
            top: this.y - boxH / 2,
            bottom: this.y + boxH / 2,
        };
    }

    // ==================== 受伤处理 ====================

    /**
     * 受到伤害
     * @param {number} damage - 伤害值
     * @param {number} knockbackDir - 击退方向 (-1左, 1右)
     */
    takeDamage(damage, knockbackDir) {
        if (this.invincible || this.state === PlayerState.DEATH) return;

        this.hp -= damage;
        this.invincible = true;
        this.invincibleTimer = INVINCIBILITY_TIME;
        this.flashTimer = 0.12;
        this.knockbackVx = knockbackDir * KNOCKBACK_FORCE;
        this.vy = -200; // 小幅度上弹

        if (this.hp <= 0) {
            this.hp = 0;
            this.state = PlayerState.DEATH;
            this.stateTime = 0;
        } else {
            this.state = PlayerState.HURT;
            this.stateTime = 0;
            this.canAttack = true; // 受伤可打断攻击
        }

        return { damage, wasKilled: this.hp <= 0 };
    }

    /**
     * 恢复生命
     */
    heal(amount) {
        this.hp = Math.min(this.maxHp, this.hp + amount);
    }

    // ==================== 主更新逻辑 ====================

    /**
     * 每帧更新
     * @param {number} dt - 帧间隔（秒）
     * @param {Object} inputActions - 输入动作 { moveDir, jumpPressed, attackPressed }
     */
    update(dt, inputActions) {
        if (this.state === PlayerState.DEATH) {
            this.updateDeath(dt);
            return;
        }

        this.stateTime += dt;
        this.updateTimers(dt);

        // 处理状态
        switch (this.state) {
            case PlayerState.IDLE:
            case PlayerState.RUN:
            case PlayerState.JUMP:
            case PlayerState.FALL:
                this.updateMovement(dt, inputActions);
                break;
            case PlayerState.ATTACK1:
            case PlayerState.ATTACK2:
                this.updateAttack(dt, inputActions);
                break;
            case PlayerState.HURT:
                this.updateHurt(dt);
                break;
        }

        // 应用物理
        this.applyPhysics(dt);

        // 更新精灵纹理（仅在视觉变化时）
        const currentFrame = this.getTextureFrame();
        if (currentFrame !== this._lastVisualFrame || this.facingRight !== this._lastVisualFacing) {
            this._lastVisualFrame = currentFrame;
            this._lastVisualFacing = this.facingRight;
            this.updateTexture();
        }
    }

    /**
     * 更新各类计时器
     */
    updateTimers(dt) {
        // 无敌计时
        if (this.invincible) {
            this.invincibleTimer -= dt;
            if (this.invincibleTimer <= 0) {
                this.invincible = false;
                this.invincibleTimer = 0;
            }
        }

        // 闪白计时
        if (this.flashTimer > 0) {
            this.flashTimer -= dt;
            // 闪烁效果：交替设置白色叠加
            const flashOn = Math.floor(this.flashTimer * 30) % 2 === 0;
            this.sprite.material.color.set(flashOn ? 0xffffff : 0xffffff);
            if (this.flashTimer <= 0) {
                this.sprite.material.color.set(0xffffff);
            }
        }

        // 连击计时
        if (this.comboCount > 0) {
            this.comboTimer -= dt;
            if (this.comboTimer <= 0) {
                this.comboCount = 0;
            }
        }
    }

    /**
     * 更新移动/跳跃状态
     */
    updateMovement(dt, inputActions) {
        const { moveDir, jumpPressed, attackPressed } = inputActions;

        // --- 攻击转换 ---
        if (attackPressed && this.canAttack) {
            this.startAttack1();
            return;
        }

        // --- 水平移动 ---
        if (moveDir !== 0) {
            this.facingRight = moveDir > 0;
            const control = this.isGrounded ? 1.0 : PLAYER_AIR_CONTROL;
            this.vx = moveDir * PLAYER_SPEED * control;
        } else {
            // 摩擦力减速
            if (this.isGrounded) {
                this.vx *= PLAYER_FRICTION;
                if (Math.abs(this.vx) < 5) this.vx = 0;
            } else {
                // 空中微弱减速
                this.vx *= 0.98;
            }
        }

        // --- 跳跃 ---
        if (jumpPressed && this.isGrounded && this.state !== PlayerState.JUMP) {
            this.vy = PLAYER_JUMP_FORCE;
            this.isGrounded = false;
            this.state = PlayerState.JUMP;
            this.stateTime = 0;
            this.jumpHeld = true;
        }

        // 可变跳跃高度：松开跳跃键提前减速
        if (!isJumpPressed() && this.jumpHeld && this.vy < -100) {
            this.vy *= 0.5;
            this.jumpHeld = false;
        }

        // --- 状态更新 ---
        if (!this.isGrounded) {
            this.state = this.vy < 0 ? PlayerState.JUMP : PlayerState.FALL;
        } else {
            this.state = Math.abs(this.vx) > 10 ? PlayerState.RUN : PlayerState.IDLE;
        }

        // --- 跑步动画 ---
        if (this.state === PlayerState.RUN) {
            this.animTimer += dt;
            if (this.animTimer >= this.animInterval) {
                this.animTimer = 0;
                this.animFrame = 1 - this.animFrame; // 0↔1切换
            }
        } else {
            this.animFrame = 0;
            this.animTimer = 0;
        }
    }

    /**
     * 开始第一段攻击
     */
    startAttack1() {
        this.state = PlayerState.ATTACK1;
        this.stateTime = 0;
        this.attackHit = false;
        this.canAttack = false;
        this.vx *= 0.3; // 攻击时减速
    }

    /**
     * 开始第二段攻击
     */
    startAttack2() {
        this.state = PlayerState.ATTACK2;
        this.stateTime = 0;
        this.attackHit = false;
        this.canAttack = false;
        this.vx *= 0.2;
    }

    /**
     * 更新攻击状态
     */
    updateAttack(dt, inputActions) {
        const isAttack1 = this.state === PlayerState.ATTACK1;
        const duration = isAttack1 ? ATTACK1_DURATION : ATTACK2_DURATION;

        // 攻击动画持续中
        if (this.stateTime < duration) {
            // 检查连击输入（在连击窗口内）
            if (inputActions.attackPressed &&
                this.stateTime > duration * 0.3 && // 至少播放30%才能连击
                isAttack1) {
                this.pendingCombo = true;
            }
        }

        // 攻击状态结束
        if (this.stateTime >= duration) {
            if (this.pendingCombo && isAttack1) {
                // 触发第二段连击
                this.startAttack2();
                this.pendingCombo = false;
                return;
            }

            // 回到普通状态
            this.state = this.isGrounded ? PlayerState.IDLE : PlayerState.FALL;
            this.canAttack = true;
            this.pendingCombo = false;
        }

        // 生成攻击判定框（在攻击帧的特定时间点）
        const hitWindow = isAttack1 ?
            (this.stateTime > 0.08 && this.stateTime < 0.18) :
            (this.stateTime > 0.1 && this.stateTime < 0.22);

        if (hitWindow && !this.attackHit) {
            this.attackBox = this.getAttackBox();
        } else if (!hitWindow) {
            this.attackBox = null;
        }
    }

    /**
     * 更新受伤状态
     */
    updateHurt(dt) {
        // 击退减速
        this.knockbackVx *= 0.85;
        if (Math.abs(this.knockbackVx) < 10) this.knockbackVx = 0;
        this.vx = this.knockbackVx;

        // 受伤硬直时间
        if (this.stateTime > 0.3) {
            this.state = this.isGrounded ? PlayerState.IDLE : PlayerState.FALL;
            this.knockbackVx = 0;
            this.canAttack = true;
        }
    }

    /**
     * 更新死亡状态
     */
    updateDeath(dt) {
        // 死亡动画：缩小+下落
        this.sprite.scale.x = Math.max(0.1, 48 * (1 - this.stateTime));
        this.sprite.scale.y = Math.max(0.1, 48 * (1 - this.stateTime));
    }

    /**
     * 应用物理（重力、速度、位置更新）
     */
    applyPhysics(dt) {
        // 重力
        if (!this.isGrounded && this.state !== PlayerState.DEATH) {
            this.vy += GRAVITY * dt;
            if (this.vy > MAX_FALL_SPEED) this.vy = MAX_FALL_SPEED;
        }

        // 倒地后不再移动
        if (this.state === PlayerState.DEATH) {
            this.vy += GRAVITY * dt;
        }

        // 位置更新
        this.x += (this.vx + (this.knockbackVx || 0)) * dt;
        this.y += this.vy * dt;

        // 更新精灵位置
        this.sprite.position.set(this.x, this.y, 5);
        this.light.position.set(this.x, this.y, 30);
    }

    /**
     * 标记攻击已命中（防止一帧多次伤害）
     */
    markAttackHit() {
        this.attackHit = true;
    }

    /**
     * 增加连击计数
     */
    addCombo() {
        this.comboCount++;
        this.comboTimer = 2.0; // 2秒无命中则重置连击
    }

    /**
     * 重置玩家状态（死亡后重生用）
     */
    reset(x, y) {
        this.x = x;
        this.y = y;
        this.vx = 0;
        this.vy = 0;
        this.hp = this.maxHp;
        this.state = PlayerState.IDLE;
        this.stateTime = 0;
        this.isGrounded = false;
        this.invincible = false;
        this.invincibleTimer = 0;
        this.canAttack = true;
        this.attackHit = false;
        this.attackBox = null;
        this.knockbackVx = 0;
        this.comboCount = 0;
        this.comboTimer = 0;
        this.sprite.scale.set(48, 48, 1);
        this.sprite.material.color.set(0xffffff);
        this.sprite.position.set(x, y, 5);
        this.light.position.set(x, y, 30);
    }
}
