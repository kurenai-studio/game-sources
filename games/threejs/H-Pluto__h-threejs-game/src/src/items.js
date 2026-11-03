/**
 * items.js — 可收集物品（血瓶、金币）
 */
import * as THREE from 'three';
import { createHealthPotionTexture, createCoinTexture } from './textures.js';
import { HEALTH_POTION_HEAL, COIN_SCORE } from './config.js';

export class GameItem {
    /**
     * @param {number} x - 世界X坐标
     * @param {number} y - 世界Y坐标
     * @param {string} type - 'health' | 'coin'
     */
    constructor(x, y, type) {
        this.x = x;
        this.y = y;
        this.type = type;
        this.width = 16;
        this.height = 16;
        this.collected = false;

        // 浮动动画参数
        this.floatOffset = Math.random() * Math.PI * 2;
        this.floatSpeed = 2 + Math.random() * 2;
        this.floatAmount = 4;

        // 创建精灵
        const texture = type === 'health'
            ? createHealthPotionTexture()
            : createCoinTexture();

        const material = new THREE.SpriteMaterial({
            map: texture,
            transparent: true,
            depthWrite: false,
            depthTest: true,
        });
        this.sprite = new THREE.Sprite(material);
        this.sprite.scale.set(20, 20, 1);
        this.sprite.position.set(x, y, 3);
    }

    /**
     * 添加到场景
     */
    addToScene(scene) {
        scene.add(this.sprite);
    }

    /**
     * 更新浮动动画
     */
    update(dt) {
        if (this.collected) return;
        this.floatOffset += this.floatSpeed * dt;
        const floatY = Math.sin(this.floatOffset) * this.floatAmount;
        this.sprite.position.set(this.x, this.y + floatY, 3);

        // 金币旋转效果（通过缩放模拟）
        if (this.type === 'coin') {
            const scaleX = 20 * Math.abs(Math.cos(this.floatOffset * 1.5));
            this.sprite.scale.set(Math.max(8, scaleX), 20, 1);
        }
    }

    /**
     * 收集物品
     * @returns {{ type: string, healAmount?: number, score?: number }}
     */
    collect() {
        this.collected = true;
        this.sprite.visible = false;

        return {
            type: this.type,
            healAmount: this.type === 'health' ? HEALTH_POTION_HEAL : 0,
            score: this.type === 'coin' ? COIN_SCORE : 0,
        };
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
