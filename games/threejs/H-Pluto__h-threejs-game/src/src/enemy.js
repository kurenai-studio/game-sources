/**
 * enemy.js — 敌人基类
 * 提供敌人共用的位置、生命、状态机、渲染等基础功能
 */

/** 敌人状态枚举 */
export const EnemyState = {
    IDLE: 'idle',
    PATROL: 'patrol',
    CHASE: 'chase',
    ATTACK: 'attack',
    HURT: 'hurt',
    DYING: 'dying',
};

export class Enemy {
    /**
     * @param {number} x - 初始X
     * @param {number} y - 初始Y
     * @param {number} hp - 生命值
     * @param {number} patrolMinX - 巡逻左边界
     * @param {number} patrolMaxX - 巡逻右边界
     */
    constructor(x, y, hp, patrolMinX, patrolMaxX) {
        // ===== 位置与运动 =====
        this.x = x;
        this.y = y;
        this.vx = 0;
        this.vy = 0;
        this.width = 28;
        this.height = 38;
        this.facingRight = false;

        // ===== 巡逻边界 =====
        this.patrolMinX = patrolMinX;
        this.patrolMaxX = patrolMaxX;
        this.patrolDir = -1;

        // ===== 状态 =====
        this.state = EnemyState.IDLE;
        this.stateTime = 0;
        this.hp = hp;
        this.maxHp = hp;
        this.isGrounded = false;
        this.isDead = false;
        this.isDying = false;
        this.flashTimer = 0;

        // ===== 攻击冷却 =====
        this.attackCooldown = 0;

        // ===== 跌落计时（平台外悬空多久后转向） =====
        this.edgeTimer = 0;
    }

    /**
     * 获取AABB碰撞盒
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
     * 受到伤害
     * @param {number} damage
     * @param {number} knockbackDir
     */
    takeDamage(damage, knockbackDir) {
        if (this.isDead || this.isDying) return false;

        this.hp -= damage;
        this.flashTimer = 0.08;
        this.vx = knockbackDir * 200;
        this.vy = -150;

        if (this.hp <= 0) {
            this.hp = 0;
            this.isDying = true;
            this.state = EnemyState.DYING;
            this.stateTime = 0;
            this.vx = knockbackDir * 80;
            return true; // 已击杀
        } else {
            this.state = EnemyState.HURT;
            this.stateTime = 0;
            return false;
        }
    }

    /**
     * 获取到玩家的距离和方向
     * @param {Object} player
     * @returns {{ dist: number, dirX: number, dirY: number }}
     */
    getPlayerInfo(player) {
        const dx = player.x - this.x;
        const dy = player.y - this.y;
        return {
            dist: Math.sqrt(dx * dx + dy * dy),
            dirX: dx > 0 ? 1 : -1,
            dirY: dy,
        };
    }

    /**
     * 基础更新（子类应调用 super.update(dt, player)）
     */
    update(dt, player) {
        if (this.isDead) return;
        this.stateTime += dt;
        this.attackCooldown = Math.max(0, this.attackCooldown - dt);

        // 闪白计时
        if (this.flashTimer > 0) {
            this.flashTimer -= dt;
            if (this.sprite) {
                const flashOn = Math.floor(this.flashTimer * 30) % 2 === 0;
                this.sprite.material.color.set(flashOn ? 0xffffff : 0xffffff);
            }
            if (this.flashTimer <= 0 && this.sprite) {
                this.sprite.material.color.set(0xffffff);
            }
        }

        // 死亡处理
        if (this.isDying) {
            if (this.stateTime > 0.6) {
                this.isDead = true;
            }
        }
    }

    /**
     * 应用重力（子类在update中调用）
     */
    applyGravity(dt) {
        if (this.isDying) {
            this.vy += 1200 * dt;
        } else {
            this.vy += 1800 * dt;
            if (this.vy > 900) this.vy = 900;
        }
        this.x += this.vx * dt;
        this.y += this.vy * dt;
    }

    /**
     * 更新精灵位置（子类在update后调用）
     */
    updateSprite() {
        if (this.sprite) {
            this.sprite.position.set(this.x, this.y, 4);
        }
    }
}
