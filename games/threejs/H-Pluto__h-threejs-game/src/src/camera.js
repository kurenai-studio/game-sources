/**
 * camera.js — 摄像机控制器
 * 实现平滑跟随玩家 + 屏幕震动偏移
 *
 * 使用 camera.scale.y = -1 翻转Y轴（游戏使用Y-down坐标系，摄像机需要Y-up）
 */
import * as THREE from 'three';
import { GAME_WIDTH, GAME_HEIGHT } from './config.js';

export class GameCamera {
    /**
     * @param {number} worldWidth - 关卡总宽度
     * @param {number} worldHeight - 关卡总高度
     */
    constructor(worldWidth, worldHeight) {
        // 正交相机：标准Y-up设置（top > bottom）
        // 通过 camera.scale.y = -1 将世界Y-down坐标转换为摄像机Y-up
        this.camera = new THREE.OrthographicCamera(
            0, GAME_WIDTH,
            GAME_HEIGHT, 0,
            -100, 100
        );
        this.camera.position.z = 10;
        // 翻转Y轴以适配游戏的Y-down坐标系
        this.camera.scale.y = -1;

        /** 相机目标位置 */
        this.targetX = GAME_WIDTH / 2;
        this.targetY = GAME_HEIGHT / 2;

        /** 当前实际位置 */
        this.currentX = this.targetX;
        this.currentY = this.targetY;

        /** 关卡边界 */
        this.worldWidth = worldWidth;
        this.worldHeight = worldHeight;

        /** 震动偏移 */
        this.shakeX = 0;
        this.shakeY = 0;

        /** 平滑跟随速度（越接近1越快） */
        this.smoothSpeed = 0.08;
    }

    /**
     * 设置相机跟踪目标（通常是玩家位置）
     */
    setTarget(x, y) {
        this.targetX = x;
        this.targetY = y;
    }

    /**
     * 应用屏幕震动
     */
    applyShake(offsetX, offsetY) {
        this.shakeX = offsetX;
        this.shakeY = offsetY;
    }

    /**
     * 每帧更新：平滑插值 + 震动偏移 + 边界钳制
     *
     * 使用 camera.scale.y = -1 翻转Y轴后，摄像机内部使用标准Y-up坐标系。
     * 世界Y坐标通过 scale 自动转换为摄像机Y-up坐标（cam_y = -world_y）。
     * 摄像机投影参数（top/bottom）需要在摄像机坐标系中定义。
     *
     * 要显示世界Y范围 [currentY-halfH, currentY+halfH]：
     *   摄像机坐标系范围：[-(currentY+halfH), -(currentY-halfH)]
     *   即：top = -(currentY-halfH) = halfH - currentY
     *      bottom = -(currentY+halfH) = -halfH - currentY
     */
    update() {
        // 平滑插值
        this.currentX += (this.targetX - this.currentX) * this.smoothSpeed;
        this.currentY += (this.targetY - this.currentY) * this.smoothSpeed;

        // 限制摄像机在关卡边界内
        const halfW = GAME_WIDTH / 2;
        const halfH = GAME_HEIGHT / 2;
        this.currentX = Math.max(halfW, Math.min(this.worldWidth - halfW, this.currentX));
        this.currentY = Math.max(halfH, Math.min(this.worldHeight - halfH, this.currentY));

        // 通过投影矩阵平移实现摄像机跟随 + 震动
        const viewLeft = this.currentX - halfW + this.shakeX;
        const viewRight = this.currentX + halfW + this.shakeX;
        // 摄像机Y-up坐标：top > bottom，震动偏移在摄像机空间需要取反
        const viewTop = halfH - this.currentY - this.shakeY;
        const viewBottom = -halfH - this.currentY - this.shakeY;

        this.camera.left = viewLeft;
        this.camera.right = viewRight;
        this.camera.top = viewTop;
        this.camera.bottom = viewBottom;
        this.camera.updateProjectionMatrix();
    }

    /**
     * 窗口大小变化时更新
     */
    onResize(width, height) {
        // 保持设计分辨率，通过CSS缩放适配
        // 此处不需要修改相机参数
    }

    /**
     * 重置相机（关卡加载时）
     */
    reset(x, y) {
        this.targetX = x;
        this.targetY = y;
        this.currentX = x;
        this.currentY = y;
        this.shakeX = 0;
        this.shakeY = 0;
        this.update();
    }
}
