/**
 * game.js — 游戏状态管理器
 * 协调所有子系统：玩家、敌人、平台、碰撞、特效、摄像机、HUD
 */
import * as THREE from 'three';
import { Player, PlayerState } from './player.js';
import { MeleeEnemy } from './enemy-melee.js';
import { RangedEnemy } from './enemy-ranged.js';
import { createPlatform } from './platform.js';
import { GameItem } from './items.js';
import { EffectsManager } from './effects.js';
import { GameCamera } from './camera.js';
import { HUD } from './hud.js';
import {
    checkAABB, resolvePlayerPlatform,
    checkAttackHitEnemies, checkProjectileHitPlayer,
    checkPlayerItemCollision, checkEndZone,
} from './collision.js';
import { getLevelData } from './level.js';
import {
    getMoveDirection, justJumpPressed, justAttackPressed,
    updatePrevState,
} from './input.js';
import {
    ATTACK1_DAMAGE, ATTACK2_DAMAGE,
    PROJECTILE_DAMAGE,
} from './config.js';
import { createBackgroundTexture } from './textures.js';

export class Game {
    constructor(container) {
        // ==================== Three.js初始化 ====================
        this.scene = new THREE.Scene();

        // 正交相机（由GameCamera管理）
        this.gameCamera = new GameCamera(3500, 600);

        // 渲染器
        this.renderer = new THREE.WebGLRenderer({ antialias: false, alpha: true });
        this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
        this.renderer.setSize(window.innerWidth, window.innerHeight);
        this.renderer.setClearColor(0x1a1a3e); // 深蓝紫色背景（稍亮）
        container.appendChild(this.renderer.domElement);

        // 渲染器设置
        this.renderer.domElement.style.imageRendering = 'auto';

        // ==================== 背景 ====================
        this.createBackground();

        // ==================== 特效管理器 ====================
        this.effects = new EffectsManager(this.scene);

        // ==================== HUD ====================
        this.hud = new HUD();

        // ==================== 游戏状态 ====================
        this.isRunning = false;
        this.isPaused = false;
        this.gameOver = false;
        this.victory = false;

        // ==================== 关卡数据 ====================
        this.platforms = [];
        this.enemies = [];
        this.items = [];
        this.startPos = { x: 0, y: 0 };
        this.endZone = { x: 0, y: 0, w: 0, h: 0 };

        // ==================== 弹幕列表（统一管理） ====================
        this.projectiles = [];

        // ==================== 窗口响应 ====================
        window.addEventListener('resize', () => this.onResize());

        // ==================== 时钟 ====================
        this.clock = new THREE.Clock();
        this.lastTime = 0;
    }

    /**
     * 创建背景
     */
    createBackground() {
        // 大背景精灵
        const bgTexture = createBackgroundTexture();
        bgTexture.wrapS = THREE.RepeatWrapping;
        bgTexture.wrapT = THREE.RepeatWrapping;
        bgTexture.repeat.set(60, 1);

        const bgMat = new THREE.SpriteMaterial({
            map: bgTexture,
            depthWrite: false,
            depthTest: false,
        });
        this.bgSprite = new THREE.Sprite(bgMat);
        this.bgSprite.scale.set(4000, 800, 1);
        this.bgSprite.position.set(1750, 300, -10);
        this.scene.add(this.bgSprite);

        // 远处山脉/建筑剪影（简单渐变块）
        const farMat = new THREE.SpriteMaterial({
            map: this.createFarBgTexture(),
            depthWrite: false,
            depthTest: false,
        });
        this.farSprite = new THREE.Sprite(farMat);
        this.farSprite.scale.set(4000, 300, 1);
        this.farSprite.position.set(1750, 450, -5);
        this.scene.add(this.farSprite);
    }

    createFarBgTexture() {
        const canvas = document.createElement('canvas');
        canvas.width = 512;
        canvas.height = 64;
        const ctx = canvas.getContext('2d');

        // 建筑剪影
        ctx.fillStyle = '#0a0a15';
        ctx.fillRect(0, 0, 512, 64);

        ctx.fillStyle = '#111128';
        for (let x = 0; x < 512; x += 40 + Math.random() * 30) {
            const h = 10 + Math.random() * 40;
            ctx.fillRect(x, 64 - h, 20 + Math.random() * 20, h);
        }

        const texture = new THREE.CanvasTexture(canvas);
        texture.minFilter = THREE.LinearFilter;
        texture.wrapS = THREE.RepeatWrapping;
        texture.repeat.set(8, 1);
        return texture;
    }

    // ==================== 关卡加载 ====================

    /**
     * 加载/重置关卡
     */
    loadLevel() {
        // 清理旧对象
        this.clearLevel();

        const levelData = getLevelData();

        // 创建平台
        for (const pd of levelData.platforms) {
            const plat = createPlatform(pd.x, pd.y, pd.w, pd.h, pd.type);
            plat.addToScene(this.scene);
            this.platforms.push(plat);
        }

        // 创建敌人
        for (const ed of levelData.enemies) {
            let enemy;
            if (ed.type === 'melee') {
                enemy = new MeleeEnemy(ed.x, ed.y, ed.patrolMinX, ed.patrolMaxX);
            } else if (ed.type === 'ranged') {
                enemy = new RangedEnemy(ed.x, ed.y, ed.patrolMinX, ed.patrolMaxX);
            }
            if (enemy) {
                this.scene.add(enemy.sprite);
                this.enemies.push(enemy);
            }
        }

        // 创建物品
        for (const id of levelData.items) {
            const item = new GameItem(id.x, id.y, id.type);
            item.addToScene(this.scene);
            this.items.push(item);
        }

        // 玩家
        this.startPos = levelData.startPos;
        this.endZone = levelData.endZone;

        this.player = new Player(this.startPos.x, this.startPos.y);
        this.player.addToScene(this.scene);

        // 终点标识（发光区域）
        this.createEndZoneMarker();

        // 重置相机
        this.gameCamera.reset(this.startPos.x, this.startPos.y);

        // 重置状态
        this.gameOver = false;
        this.victory = false;
        this.isRunning = true;
        this.hud.reset();
        this.projectiles = [];
    }

    /**
     * 创建终点标识
     */
    createEndZoneMarker() {
        // 光柱效果
        const canvas = document.createElement('canvas');
        canvas.width = 64;
        canvas.height = 128;
        const ctx = canvas.getContext('2d');
        const gradient = ctx.createLinearGradient(0, 0, 0, 128);
        gradient.addColorStop(0, 'rgba(255,200,50,0.4)');
        gradient.addColorStop(0.5, 'rgba(255,200,50,0.1)');
        gradient.addColorStop(1, 'rgba(255,200,50,0)');
        ctx.fillStyle = gradient;
        ctx.fillRect(0, 0, 64, 128);

        const texture = new THREE.CanvasTexture(canvas);
        const material = new THREE.SpriteMaterial({
            map: texture,
            transparent: true,
            depthWrite: false,
            blending: THREE.AdditiveBlending,
        });
        this.endZoneMarker = new THREE.Sprite(material);
        this.endZoneMarker.scale.set(this.endZone.w + 40, this.endZone.h + 60, 1);
        this.endZoneMarker.position.set(this.endZone.x, this.endZone.y, 1);
        this.scene.add(this.endZoneMarker);
    }

    /**
     * 清理关卡
     */
    clearLevel() {
        for (const plat of this.platforms) {
            plat.removeFromScene(this.scene);
        }
        for (const enemy of this.enemies) {
            if (enemy.sprite) {
                this.scene.remove(enemy.sprite);
                enemy.sprite.material.map?.dispose();
                enemy.sprite.material.dispose();
            }
            // 清理远程敌人的弹幕
            if (enemy.clearProjectiles) {
                enemy.clearProjectiles(this.scene);
            }
        }
        for (const item of this.items) {
            item.remove(this.scene);
        }
        if (this.player) {
            this.scene.remove(this.player.sprite);
            this.scene.remove(this.player.light);
            this.player.sprite.material.map?.dispose();
            this.player.sprite.material.dispose();
        }
        if (this.endZoneMarker) {
            this.scene.remove(this.endZoneMarker);
            this.endZoneMarker.material.map?.dispose();
            this.endZoneMarker.material.dispose();
        }
        this.effects.clearAll();

        this.platforms = [];
        this.enemies = [];
        this.items = [];
        this.projectiles = [];
    }

    // ==================== 主循环 ====================

    /**
     * 启动游戏
     */
    start() {
        this.loadLevel();
        this.lastTime = performance.now();
        this.loop(this.lastTime);
    }

    /**
     * 游戏主循环
     */
    loop(timestamp) {
        if (!this.isRunning) return;

        requestAnimationFrame((t) => this.loop(t));

        // 计算帧间隔（限制最大dt防止跳帧，设置最小dt避免首帧dt=0）
        let dt = (timestamp - this.lastTime) / 1000;
        if (dt <= 0) dt = 0.016; // 首帧使用假设的16ms步长
        if (dt > 0.1) dt = 0.1; // 最多100ms步长
        this.lastTime = timestamp;

        this.update(dt);
        this.render();
    }

    /**
     * 主更新
     */
    update(dt) {
        // 始终更新特效（即使游戏结束）
        this.effects.update(dt);

        if (this.gameOver) return;

        // 1. 读取输入
        const inputActions = {
            moveDir: getMoveDirection(),
            jumpPressed: justJumpPressed(),
            attackPressed: justAttackPressed(),
        };

        // 2. 更新玩家
        this.player.update(dt, inputActions);

        // 3. 玩家与平台碰撞
        resolvePlayerPlatform(this.player, this.platforms);

        // 4. 检查玩家掉出世界
        if (this.player.y > 700) {
            this.handlePlayerDeath();
            return;
        }

        // 5. 更新敌人
        for (const enemy of this.enemies) {
            if (enemy.isDead) continue;
            enemy.update(dt, this.player, this.platforms);

            // 敌人与平台碰撞
            resolvePlayerPlatform(enemy, this.platforms);
        }

        // 6. 收集远程敌人弹幕
        this.projectiles = [];
        for (const enemy of this.enemies) {
            if (enemy.isDead) continue;
            if (enemy.getActiveProjectiles) {
                for (const proj of enemy.getActiveProjectiles()) {
                    if (!proj.dead && !this.scene.children.includes(proj.sprite)) {
                        this.scene.add(proj.sprite);
                    }
                    this.projectiles.push(proj);
                }
            }
        }

        // 7. 玩家攻击判定
        this.checkPlayerAttack();

        // 8. 敌人对玩家的攻击
        this.checkEnemyAttacks();

        // 9. 弹幕对玩家的碰撞
        const hitProjectiles = checkProjectileHitPlayer(this.projectiles, this.player);
        for (const proj of hitProjectiles) {
            const knockbackDir = proj.vx > 0 ? 1 : -1;
            const result = this.player.takeDamage(PROJECTILE_DAMAGE, knockbackDir);
            proj.dead = true;
            if (result) {
                this.effects.spawnHitSparks(this.player.x, this.player.y - 10, 6);
                this.effects.spawnDamageNumber(this.player.x, this.player.y - 20, result.damage);
                this.effects.triggerScreenShake();
                this.hud.updateHealth(this.player.hp, this.player.maxHp);
                if (result.wasKilled) {
                    this.handlePlayerDeath();
                    return;
                }
            }
        }

        // 10. 物品收集
        this.checkItemCollection();

        // 11. 终点检测
        if (checkEndZone(this.player, this.endZone)) {
            this.handleVictory();
            return;
        }

        // 12. 更新物品动画
        for (const item of this.items) {
            item.update(dt);
        }

        // 13. 更新摄像机
        this.gameCamera.setTarget(this.player.x, this.player.y + 20);
        const shake = this.effects.getShakeOffset();
        this.gameCamera.applyShake(shake.x, shake.y);
        this.gameCamera.update();

        // 15. 更新HUD
        this.hud.updateHealth(this.player.hp, this.player.maxHp);
        this.hud.updateCombo(this.player.comboCount);

        // 16. 保存输入状态
        updatePrevState();

        // 17. 背景视差
        this.bgSprite.position.x = this.gameCamera.currentX;
        this.farSprite.position.x = this.gameCamera.currentX;
    }

    /**
     * 检测玩家攻击命中
     */
    checkPlayerAttack() {
        if (!this.player.attackBox) return;

        const hitEnemies = checkAttackHitEnemies(this.player.attackBox, this.enemies);
        if (hitEnemies.length > 0 && !this.player.attackHit) {
            this.player.markAttackHit();

            for (const enemy of hitEnemies) {
                const isAttack2 = this.player.state === PlayerState.ATTACK2;
                const damage = isAttack2 ? ATTACK2_DAMAGE : ATTACK1_DAMAGE;
                const knockbackDir = this.player.facingRight ? 1 : -1;

                const killed = enemy.takeDamage(damage, knockbackDir);

                // 特效
                this.effects.spawnHitSparks(
                    (this.player.x + enemy.x) / 2,
                    enemy.y - 10,
                    10
                );
                this.effects.spawnDamageNumber(enemy.x, enemy.y - 20, damage);
                this.effects.spawnSlash(this.player.x, this.player.y, this.player.facingRight);
                this.effects.triggerScreenShake(isAttack2 ? 8 : 4);

                // 连击与得分
                this.player.addCombo();
                const comboMultiplier = 1 + this.player.comboCount * 0.15;
                const score = Math.floor(damage * 10 * comboMultiplier);
                this.hud.addScore(score);
            }
        }
    }

    /**
     * 检测敌人攻击玩家
     */
    checkEnemyAttacks() {
        for (const enemy of this.enemies) {
            if (enemy.isDead || enemy.isDying) continue;

            // 近战敌人攻击判定
            if (enemy.isInAttackWindow && enemy.isInAttackWindow()) {
                const attackBox = enemy.getAttackBox();
                const playerBox = this.player.getAABB();
                if (checkAABB(attackBox, playerBox)) {
                    const damage = enemy.getAttackDamage();
                    if (damage > 0) {
                        const knockbackDir = enemy.facingRight ? 1 : -1;
                        const result = this.player.takeDamage(damage, knockbackDir);
                        if (result) {
                            this.effects.spawnHitSparks(this.player.x, this.player.y - 10, 6);
                            this.effects.spawnDamageNumber(this.player.x, this.player.y - 20, result.damage);
                            this.effects.triggerScreenShake();
                            this.hud.updateHealth(this.player.hp, this.player.maxHp);
                            if (result.wasKilled) {
                                this.handlePlayerDeath();
                                return;
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     * 检测物品收集
     */
    checkItemCollection() {
        const collected = checkPlayerItemCollision(this.player, this.items);
        for (const item of collected) {
            const result = item.collect();
            if (result.type === 'health') {
                this.player.heal(result.healAmount);
                this.effects.spawnDamageNumber(item.x, item.y, result.healAmount, true);
                this.hud.updateHealth(this.player.hp, this.player.maxHp);
            } else if (result.type === 'coin') {
                this.hud.addScore(result.score);
                this.effects.spawnHitSparks(item.x, item.y, 4);
            }
        }
    }

    /**
     * 处理玩家死亡
     */
    handlePlayerDeath() {
        this.gameOver = true;
        this.hud.showMessage('你失败了...\n按 R 键重新开始', 4);
        // 添加重新开始监听
        this._restartHandler = (e) => {
            if (e.code === 'KeyR') {
                window.removeEventListener('keydown', this._restartHandler);
                this.restart();
            }
        };
        window.addEventListener('keydown', this._restartHandler);
    }

    /**
     * 处理胜利
     */
    handleVictory() {
        this.gameOver = true;
        this.victory = true;
        this.hud.showMessage('✨ 胜利！ ✨\n按 R 键重新开始', 5);

        // 胜利粒子特效
        this.effects.spawnHitSparks(this.player.x, this.player.y, 30);

        this._restartHandler = (e) => {
            if (e.code === 'KeyR') {
                window.removeEventListener('keydown', this._restartHandler);
                this.restart();
            }
        };
        window.addEventListener('keydown', this._restartHandler);
    }

    /**
     * 重新开始
     */
    restart() {
        this.gameOver = false;
        this.victory = false;
        this.clearLevel();
        this.loadLevel();
    }

    // ==================== 渲染 ====================

    render() {
        this.renderer.render(this.scene, this.gameCamera.camera);
    }

    // ==================== 窗口响应 ====================

    onResize() {
        const w = window.innerWidth;
        const h = window.innerHeight;
        this.renderer.setSize(w, h);
    }
}

