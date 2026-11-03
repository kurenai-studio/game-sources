/**
 * textures.js — Canvas纹理生成器
 * 所有游戏纹理均通过Canvas动态绘制（像素风格），无需外部资源
 * 使用32x32像素画布，通过 nearest-neighbor 缩放保持像素锐度
 */
import * as THREE from 'three';
import { COLORS, PIXEL_SCALE } from './config.js';

/** 纹理画布基础尺寸 */
const TEX_SIZE = 32;

/**
 * 创建像素风格纹理的辅助函数
 * @param {number} width - 纹理宽度(像素)
 * @param {number} height - 纹理高度(像素)
 * @param {Function} drawFn - 绘制回调(ctx, canvas)
 * @returns {THREE.Texture}
 */
function makeTexture(width, height, drawFn) {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');
    // 关闭抗锯齿以保持像素风格
    ctx.imageSmoothingEnabled = false;
    drawFn(ctx, canvas);

    const texture = new THREE.CanvasTexture(canvas);
    texture.minFilter = THREE.NearestFilter;
    texture.magFilter = THREE.NearestFilter;
    texture.needsUpdate = true;
    return texture;
}

/**
 * 绘制像素化矩形
 */
function pixelRect(ctx, x, y, w, h, color) {
    ctx.fillStyle = color;
    ctx.fillRect(x, y, w, h);
}

/**
 * 绘制像素化边框
 */
function pixelBorder(ctx, x, y, w, h, color, thickness = 1) {
    ctx.fillStyle = color;
    ctx.fillRect(x, y, w, thickness);           // top
    ctx.fillRect(x, y + h - thickness, w, thickness); // bottom
    ctx.fillRect(x, y, thickness, h);           // left
    ctx.fillRect(x + w - thickness, y, thickness, h); // right
}

// ==================== 平台纹理 ====================

/**
 * 创建平台/地面纹理
 * @param {number} w - 宽度(像素)
 * @param {number} h - 高度(像素)
 * @param {string} type - 类型: 'ground' | 'platform' | 'wall'
 */
export function createPlatformTexture(w, h, type = 'ground') {
    const cw = w * PIXEL_SCALE;
    const ch = h * PIXEL_SCALE;

    return makeTexture(cw, ch, (ctx) => {
        const baseColor = type === 'ground' ? COLORS.stone :
                          type === 'wall' ? COLORS.stoneDark : COLORS.stoneLight;
        const lightColor = type === 'ground' ? COLORS.stoneLight :
                          type === 'wall' ? COLORS.stone : '#5a5a6a';

        // 基础填充
        ctx.fillStyle = baseColor;
        ctx.fillRect(0, 0, cw, ch);

        // 像素化砖块纹理
        const brickW = 8 * PIXEL_SCALE;
        const brickH = 8 * PIXEL_SCALE;
        for (let by = 0; by < ch; by += brickH) {
            const offset = (Math.floor(by / brickH) % 2) * (brickW / 2);
            for (let bx = -brickW; bx < cw + brickW; bx += brickW) {
                const bx2 = bx + offset;
                ctx.fillStyle = lightColor;
                ctx.fillRect(bx2 + 1, by + 1, brickW - 2, brickH - 2);
                ctx.fillStyle = baseColor;
                ctx.fillRect(bx2 + 2, by + 2, brickW - 4, brickH - 4);

                // 随机裂痕/苔藓点缀
                if (Math.random() < 0.3) {
                    ctx.fillStyle = COLORS.moss;
                    ctx.fillRect(bx2 + 3, by + brickH - 3, 3, 2);
                }
            }
        }

        // 顶部边缘高亮
        ctx.fillStyle = 'rgba(255,255,255,0.15)';
        ctx.fillRect(0, 0, cw, 2 * PIXEL_SCALE);

        // 底部边缘阴影
        ctx.fillStyle = 'rgba(0,0,0,0.3)';
        ctx.fillRect(0, ch - 2 * PIXEL_SCALE, cw, 2 * PIXEL_SCALE);
    });
}

// ==================== 玩家纹理 ====================

/**
 * 创建玩家精灵纹理（像素风骑士）
 * @param {number} frame - 动画帧 0=idle, 1=run1, 2=run2, 3=jump, 4=attack1, 5=attack2
 * @param {boolean} facingRight - 是否面朝右
 */
export function createPlayerTexture(frame = 0, facingRight = true) {
    const size = TEX_SIZE * PIXEL_SCALE;
    return makeTexture(size, size, (ctx) => {
        const cx = size / 2;
        const cy = size / 2;
        const s = PIXEL_SCALE; // 缩放单位

        // --- 身体（盔甲）---
        // 绘制顺序：腿 → 身体 → 手臂 → 头

        const drawPlayer = (flipX) => {
            ctx.save();
            if (flipX) {
                ctx.translate(size, 0);
                ctx.scale(-1, 1);
            }

            // === 腿部 ===
            if (frame === 0) {
                // idle: 直立
                pixelRect(ctx, cx - 4 * s, cy + 6 * s, 4 * s, 8 * s, COLORS.stoneDark);
                pixelRect(ctx, cx + 1 * s, cy + 6 * s, 4 * s, 8 * s, COLORS.stoneDark);
                // 靴子
                pixelRect(ctx, cx - 5 * s, cy + 13 * s, 5 * s, 2 * s, '#3a2a1a');
                pixelRect(ctx, cx + 1 * s, cy + 13 * s, 5 * s, 2 * s, '#3a2a1a');
            } else if (frame === 1) {
                // run1: 左腿前右腿后
                pixelRect(ctx, cx - 4 * s, cy + 6 * s, 3 * s, 10 * s, COLORS.stoneDark);
                pixelRect(ctx, cx + 2 * s, cy + 8 * s, 3 * s, 8 * s, COLORS.stoneDark);
                pixelRect(ctx, cx - 5 * s, cy + 14 * s, 4 * s, 2 * s, '#3a2a1a');
                pixelRect(ctx, cx + 1 * s, cy + 14 * s, 4 * s, 2 * s, '#3a2a1a');
            } else if (frame === 2) {
                // run2: 右腿前左腿后
                pixelRect(ctx, cx - 4 * s, cy + 8 * s, 3 * s, 8 * s, COLORS.stoneDark);
                pixelRect(ctx, cx + 2 * s, cy + 6 * s, 3 * s, 10 * s, COLORS.stoneDark);
                pixelRect(ctx, cx - 5 * s, cy + 14 * s, 4 * s, 2 * s, '#3a2a1a');
                pixelRect(ctx, cx + 1 * s, cy + 14 * s, 4 * s, 2 * s, '#3a2a1a');
            } else {
                // jump/attack: 跳跃姿势
                pixelRect(ctx, cx - 4 * s, cy + 8 * s, 3 * s, 6 * s, COLORS.stoneDark);
                pixelRect(ctx, cx + 2 * s, cy + 7 * s, 3 * s, 7 * s, COLORS.stoneDark);
                pixelRect(ctx, cx - 5 * s, cy + 12 * s, 4 * s, 2 * s, '#3a2a1a');
                pixelRect(ctx, cx + 1 * s, cy + 12 * s, 4 * s, 2 * s, '#3a2a1a');
            }

            // === 身体（盔甲胸甲） ===
            pixelRect(ctx, cx - 6 * s, cy - 2 * s, 13 * s, 10 * s, COLORS.playerArmor);
            pixelRect(ctx, cx - 4 * s, cy, 9 * s, 8 * s, COLORS.playerArmorLight);
            // 腰带
            pixelRect(ctx, cx - 5 * s, cy + 7 * s, 11 * s, 2 * s, '#8b6914');

            // === 头部 ===
            // 头盔
            pixelRect(ctx, cx - 5 * s, cy - 10 * s, 11 * s, 9 * s, COLORS.playerArmor);
            // 面罩/护目
            pixelRect(ctx, cx - 3 * s, cy - 7 * s, 7 * s, 3 * s, '#88ccff');
            pixelRect(ctx, cx - 1 * s, cy - 7 * s, 3 * s, 3 * s, '#ffffff');
            // 头盔角饰
            pixelRect(ctx, cx - 6 * s, cy - 12 * s, 3 * s, 4 * s, COLORS.playerArmor);
            pixelRect(ctx, cx + 4 * s, cy - 12 * s, 3 * s, 4 * s, COLORS.playerArmor);

            // === 手臂 ===
            if (frame === 4) {
                // attack1: 右臂横向挥砍
                pixelRect(ctx, cx + 6 * s, cy + 1 * s, 10 * s, 3 * s, COLORS.playerArmor);
                // 武器（剑）
                pixelRect(ctx, cx + 15 * s, cy - 2 * s, 3 * s, 10 * s, '#cccccc');
                pixelRect(ctx, cx + 15 * s, cy + 8 * s, 5 * s, 2 * s, '#888888'); // 剑格
                // 挥砍弧光
                ctx.fillStyle = 'rgba(255,220,80,0.4)';
                ctx.fillRect(cx + 8 * s, cy - 4 * s, 14 * s, 14 * s);
            } else if (frame === 5) {
                // attack2: 上挑动作
                pixelRect(ctx, cx + 4 * s, cy - 6 * s, 3 * s, 12 * s, COLORS.playerArmor);
                pixelRect(ctx, cx + 1 * s, cy - 14 * s, 3 * s, 10 * s, '#cccccc');
                pixelRect(ctx, cx, cy - 14 * s, 6 * s, 2 * s, '#888888');
                // 上挑弧光
                ctx.fillStyle = 'rgba(255,200,60,0.4)';
                ctx.fillRect(cx - 2 * s, cy - 16 * s, 10 * s, 18 * s);
            } else {
                // 普通手臂
                pixelRect(ctx, cx - 7 * s, cy + 1 * s, 3 * s, 7 * s, COLORS.playerArmor);
                pixelRect(ctx, cx + 5 * s, cy + 1 * s, 3 * s, 7 * s, COLORS.playerArmor);
            }

            // === 披风/围巾 ===
            ctx.fillStyle = 'rgba(180,40,40,0.7)';
            ctx.fillRect(cx - 4 * s, cy - 5 * s, 2 * s, 8 * s);
            if (frame === 1 || frame === 2) {
                ctx.fillRect(cx - 7 * s, cy - 3 * s, 3 * s, 10 * s);
            }

            ctx.restore();
        };

        drawPlayer(!facingRight);

        // === 光晕效果 ===
        const gradient = ctx.createRadialGradient(cx, cy, 6 * s, cx, cy, 18 * s);
        gradient.addColorStop(0, 'rgba(100,180,255,0.15)');
        gradient.addColorStop(0.5, 'rgba(100,150,255,0.05)');
        gradient.addColorStop(1, 'rgba(0,0,0,0)');
        ctx.fillStyle = gradient;
        ctx.fillRect(0, 0, size, size);
    });
}

// ==================== 近战敌人纹理 ====================

/**
 * 创建近战敌人纹理（暗红战士）
 */
export function createMeleeEnemyTexture(frame = 0, facingRight = true) {
    const size = TEX_SIZE * PIXEL_SCALE;
    return makeTexture(size, size, (ctx) => {
        const cx = size / 2;
        const cy = size / 2;
        const s = PIXEL_SCALE;

        ctx.save();
        if (!facingRight) {
            ctx.translate(size, 0);
            ctx.scale(-1, 1);
        }

        // 腿
        if (frame === 0) {
            pixelRect(ctx, cx - 3 * s, cy + 7 * s, 3 * s, 8 * s, '#4a1a1a');
            pixelRect(ctx, cx + 1 * s, cy + 7 * s, 3 * s, 8 * s, '#4a1a1a');
        } else {
            pixelRect(ctx, cx - 4 * s, cy + 7 * s, 3 * s, 7 * s, '#4a1a1a');
            pixelRect(ctx, cx + 2 * s, cy + 8 * s, 3 * s, 6 * s, '#4a1a1a');
        }

        // 身体
        pixelRect(ctx, cx - 5 * s, cy - 2 * s, 11 * s, 10 * s, COLORS.meleeEnemy);
        pixelRect(ctx, cx - 3 * s, cy, 7 * s, 7 * s, COLORS.meleeEnemyLight);

        // 头 - 有角的头盔
        pixelRect(ctx, cx - 4 * s, cy - 10 * s, 9 * s, 9 * s, COLORS.meleeEnemy);
        // 眼睛（发光红）
        pixelRect(ctx, cx - 2 * s, cy - 7 * s, 2 * s, 2 * s, '#ff3333');
        pixelRect(ctx, cx + 1 * s, cy - 7 * s, 2 * s, 2 * s, '#ff3333');
        // 角
        pixelRect(ctx, cx - 5 * s, cy - 13 * s, 2 * s, 5 * s, '#5a2a2a');
        pixelRect(ctx, cx + 4 * s, cy - 13 * s, 2 * s, 5 * s, '#5a2a2a');

        // 手臂 + 武器（斧头）
        pixelRect(ctx, cx - 7 * s, cy + 1 * s, 3 * s, 6 * s, COLORS.meleeEnemy);
        pixelRect(ctx, cx + 5 * s, cy, 3 * s, 7 * s, COLORS.meleeEnemy);
        // 斧头
        pixelRect(ctx, cx + 7 * s, cy - 3 * s, 4 * s, 6 * s, '#888888');
        pixelRect(ctx, cx + 11 * s, cy - 6 * s, 5 * s, 8 * s, '#777777');

        ctx.restore();

        // 微弱暗红光晕
        const gradient = ctx.createRadialGradient(cx, cy, 5 * s, cx, cy, 16 * s);
        gradient.addColorStop(0, 'rgba(255,50,50,0.08)');
        gradient.addColorStop(1, 'rgba(0,0,0,0)');
        ctx.fillStyle = gradient;
        ctx.fillRect(0, 0, size, size);
    });
}

// ==================== 远程敌人纹理 ====================

/**
 * 创建远程敌人纹理（暗紫法师）
 */
export function createRangedEnemyTexture(frame = 0, facingRight = true) {
    const size = TEX_SIZE * PIXEL_SCALE;
    return makeTexture(size, size, (ctx) => {
        const cx = size / 2;
        const cy = size / 2;
        const s = PIXEL_SCALE;

        ctx.save();
        if (!facingRight) {
            ctx.translate(size, 0);
            ctx.scale(-1, 1);
        }

        // 长袍下部
        pixelRect(ctx, cx - 5 * s, cy + 6 * s, 11 * s, 10 * s, COLORS.rangedEnemy);
        pixelRect(ctx, cx - 3 * s, cy + 6 * s, 7 * s, 8 * s, COLORS.rangedEnemyLight);

        // 身体（法袍）
        pixelRect(ctx, cx - 5 * s, cy - 2 * s, 11 * s, 9 * s, COLORS.rangedEnemy);
        pixelRect(ctx, cx - 3 * s, cy, 7 * s, 6 * s, COLORS.rangedEnemyLight);

        // 兜帽/头部
        pixelRect(ctx, cx - 4 * s, cy - 10 * s, 9 * s, 9 * s, COLORS.rangedEnemy);
        pixelRect(ctx, cx - 2 * s, cy - 9 * s, 1 * s, 3 * s, '#ff66ff'); // 紫色发光的眼睛
        pixelRect(ctx, cx + 2 * s, cy - 9 * s, 1 * s, 3 * s, '#ff66ff');

        // 手臂 + 法杖
        pixelRect(ctx, cx - 7 * s, cy + 1 * s, 2 * s, 6 * s, COLORS.rangedEnemy);
        pixelRect(ctx, cx + 5 * s, cy - 1 * s, 2 * s, 8 * s, COLORS.rangedEnemy);
        // 法杖
        pixelRect(ctx, cx + 6 * s, cy - 12 * s, 3 * s, 15 * s, '#8b6914');
        // 法杖宝石（发光）
        pixelRect(ctx, cx + 5 * s, cy - 14 * s, 5 * s, 5 * s, '#ff44ff');
        pixelRect(ctx, cx + 6 * s, cy - 13 * s, 3 * s, 3 * s, '#ffaaff');

        // 攻击帧：宝石更亮
        if (frame === 2) {
            ctx.fillStyle = 'rgba(255,100,255,0.5)';
            ctx.fillRect(cx + 3 * s, cy - 16 * s, 9 * s, 9 * s);
        }

        ctx.restore();

        // 紫光光晕
        const gradient = ctx.createRadialGradient(cx, cy, 5 * s, cx, cy, 16 * s);
        gradient.addColorStop(0, 'rgba(180,50,255,0.08)');
        gradient.addColorStop(1, 'rgba(0,0,0,0)');
        ctx.fillStyle = gradient;
        ctx.fillRect(0, 0, size, size);
    });
}

// ==================== 物品纹理 ====================

/**
 * 创建血瓶纹理
 */
export function createHealthPotionTexture() {
    const size = 16 * PIXEL_SCALE;
    return makeTexture(size, size, (ctx) => {
        const s = PIXEL_SCALE;
        const cx = size / 2;

        // 瓶子
        pixelRect(ctx, cx - 3 * s, 2 * s, 7 * s, 9 * s, '#cc3333');
        pixelRect(ctx, cx - 2 * s, 3 * s, 5 * s, 7 * s, '#ff5555');
        // 高光
        pixelRect(ctx, cx - 1 * s, 4 * s, 2 * s, 3 * s, '#ff8888');
        // 瓶口
        pixelRect(ctx, cx - 2 * s, 0, 5 * s, 3 * s, '#888888');
        // 发光
        ctx.fillStyle = 'rgba(255,80,80,0.3)';
        ctx.fillRect(cx - 4 * s, 0, 9 * s, 13 * s);
    });
}

/**
 * 创建金币纹理
 */
export function createCoinTexture() {
    const size = 16 * PIXEL_SCALE;
    return makeTexture(size, size, (ctx) => {
        const s = PIXEL_SCALE;
        const cx = size / 2;
        const cy = size / 2;

        // 圆形金币（像素化）
        const colors = ['#ffdd00', '#ffaa00', '#ffcc00', '#ff8800'];
        for (let y = -4; y <= 4; y++) {
            for (let x = -4; x <= 4; x++) {
                if (x * x + y * y <= 16) {
                    const colorIdx = (x + y + 8) % colors.length;
                    ctx.fillStyle = colors[colorIdx];
                    ctx.fillRect(cx + x * s, cy + y * s, s, s);
                }
            }
        }
        // 中间高光
        pixelRect(ctx, cx - 1 * s, cy - 2 * s, 3 * s, 3 * s, '#ffee88');

        // 发光
        ctx.fillStyle = 'rgba(255,200,0,0.3)';
        ctx.fillRect(cx - 6 * s, cy - 6 * s, 12 * s, 12 * s);
    });
}

// ==================== 特效纹理 ====================

/**
 * 创建斩击特效纹理
 */
export function createSlashTexture() {
    const size = 48 * PIXEL_SCALE;
    return makeTexture(size, size, (ctx) => {
        const s = PIXEL_SCALE;
        // 弧形斩击
        ctx.fillStyle = 'rgba(255,220,60,0.9)';
        ctx.fillRect(2 * s, 10 * s, 44 * s, 4 * s);
        ctx.fillStyle = 'rgba(255,255,200,0.8)';
        ctx.fillRect(4 * s, 11 * s, 40 * s, 2 * s);
        ctx.fillStyle = 'rgba(255,180,30,0.5)';
        ctx.fillRect(0, 8 * s, 48 * s, 8 * s);
    });
}

/**
 * 创建弹幕纹理（紫色能量球）
 */
export function createProjectileTexture() {
    const size = 16 * PIXEL_SCALE;
    return makeTexture(size, size, (ctx) => {
        const s = PIXEL_SCALE;
        const cx = size / 2, cy = size / 2;

        // 能量球
        for (let y = -3; y <= 3; y++) {
            for (let x = -3; x <= 3; x++) {
                if (x * x + y * y <= 10) {
                    const alpha = 1 - (x * x + y * y) / 12;
                    ctx.fillStyle = `rgba(200,80,255,${alpha.toFixed(1)})`;
                    ctx.fillRect(cx + x * s, cy + y * s, s, s);
                }
            }
        }
        // 核心
        pixelRect(ctx, cx - 1 * s, cy - 1 * s, 3 * s, 3 * s, '#ffaaff');
    });
}

/**
 * 创建通用粒子纹理（圆形渐变）
 */
export function createParticleTexture(color = '#ffcc00') {
    const size = 8 * PIXEL_SCALE;

    // 解析颜色为 RGB
    let r, g, b;
    if (color.startsWith('#')) {
        r = parseInt(color.slice(1, 3), 16);
        g = parseInt(color.slice(3, 5), 16);
        b = parseInt(color.slice(5, 7), 16);
    } else {
        r = 255; g = 200; b = 0; // 默认金色
    }

    return makeTexture(size, size, (ctx) => {
        const s = PIXEL_SCALE;
        const cx = size / 2, cy = size / 2;

        for (let y = -3; y <= 3; y++) {
            for (let x = -3; x <= 3; x++) {
                const dist = x * x + y * y;
                if (dist <= 13) {
                    const alpha = Math.max(0, 1 - dist / 13);
                    ctx.fillStyle = `rgba(${r},${g},${b},${alpha.toFixed(2)})`;
                    ctx.fillRect(cx + x * s, cy + y * s, s, s);
                }
            }
        }
    });
}

/**
 * 创建伤害数字的Canvas（动态生成）
 * @param {string} text - 数字文本
 * @param {string} color - 颜色
 * @returns {HTMLCanvasElement}
 */
export function createDamageNumberCanvas(text, color = '#ff4444') {
    const canvas = document.createElement('canvas');
    canvas.width = 64;
    canvas.height = 32;
    const ctx = canvas.getContext('2d');
    ctx.imageSmoothingEnabled = false;
    ctx.font = 'bold 18px "Courier New", monospace';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';

    // 先填充文字
    ctx.fillStyle = color;
    ctx.fillText(text, 32, 16);

    // 再描绘边框（在文字下方）
    ctx.strokeStyle = '#000';
    ctx.lineWidth = 3;
    ctx.strokeText(text, 32, 16);

    // 再次填充确保文字在描边上方清晰
    ctx.fillStyle = color;
    ctx.fillText(text, 32, 16);

    return canvas;
}

/**
 * 创建背景纹理（渐变天空）
 */
export function createBackgroundTexture() {
    const w = 64;
    const h = 64;
    return makeTexture(w, h, (ctx) => {
        const gradient = ctx.createLinearGradient(0, 0, 0, h);
        gradient.addColorStop(0, '#1a1a3e');
        gradient.addColorStop(0.5, '#25255a');
        gradient.addColorStop(1, '#2a2a4e');
        ctx.fillStyle = gradient;
        ctx.fillRect(0, 0, w, h);

        // 星星
        for (let i = 0; i < 15; i++) {
            const sx = Math.random() * w;
            const sy = Math.random() * h * 0.6;
            const brightness = 0.3 + Math.random() * 0.7;
            ctx.fillStyle = `rgba(255,255,255,${brightness.toFixed(2)})`;
            ctx.fillRect(sx, sy, 1, 1);
        }
    });
}
