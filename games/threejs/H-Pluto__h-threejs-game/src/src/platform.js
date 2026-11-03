/**
 * platform.js — 平台类
 * 表示关卡中的地面、平台和墙壁
 */
import * as THREE from 'three';
import { createPlatformTexture } from './textures.js';
import { GAME_WIDTH, GAME_HEIGHT, PIXEL_SCALE } from './config.js';

/**
 * 平台类 - 用于碰撞检测和渲染的静态方块
 */
export class Platform {
    /**
     * @param {number} x - 中心X世界坐标
     * @param {number} y - 中心Y世界坐标
     * @param {number} width - 宽度
     * @param {number} height - 高度
     * @param {string} type - 类型: 'ground' | 'platform' | 'wall'
     */
    constructor(x, y, width, height, type = 'ground') {
        /** 世界坐标位置 */
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.type = type;

        /** AABB碰撞盒 */
        this.left = x - width / 2;
        this.right = x + width / 2;
        this.top = y - height / 2;
        this.bottom = y + height / 2;

        // 创建Three.js精灵
        const texture = createPlatformTexture(
            Math.ceil(width / PIXEL_SCALE) + 1,
            Math.ceil(height / PIXEL_SCALE) + 1,
            type
        );
        const material = new THREE.SpriteMaterial({
            map: texture,
            transparent: true,
            depthWrite: false,
            depthTest: true,
        });
        this.sprite = new THREE.Sprite(material);
        this.sprite.scale.set(width, height, 1);
        this.sprite.position.set(x, y, 0);
    }

    /**
     * 添加到场景
     * @param {THREE.Scene} scene
     */
    addToScene(scene) {
        scene.add(this.sprite);
    }

    /**
     * 从场景移除
     * @param {THREE.Scene} scene
     */
    removeFromScene(scene) {
        scene.remove(this.sprite);
        this.sprite.material.map.dispose();
        this.sprite.material.dispose();
    }
}

/**
 * 创建平台的辅助函数
 * @param {number} x - 中心X
 * @param {number} y - 中心Y
 * @param {number} w - 宽度
 * @param {number} h - 高度
 * @param {string} type - 类型
 * @returns {Platform}
 */
export function createPlatform(x, y, w, h, type = 'ground') {
    return new Platform(x, y, w, h, type);
}
