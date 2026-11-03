/**
 * main.js — 游戏入口
 * 初始化Three.js渲染器，创建Game实例，启动游戏循环
 *
 * 操作说明：
 *   A/D 或 ← →    — 左右移动
 *   W 或 空格      — 跳跃（按住可变跳高）
 *   J 或 鼠标左键  — 近战攻击（可二连击）
 *   R              — 死亡/胜利后重新开始
 *
 * 玩法：
 *   从左到右穿越关卡，击败敌人，收集金币和血瓶，到达终点光柱区域即可胜利。
 *   连续命中敌人可累积连击数，提高得分倍率。
 */

import { Game } from './game.js';

// ==================== 启动 ====================

document.addEventListener('DOMContentLoaded', () => {
    const container = document.getElementById('game-container');
    if (!container) {
        console.error('找不到游戏容器 #game-container');
        return;
    }

    const game = new Game(container);
    game.start();

    console.log('🎮 暗影之刃 — 准备就绪');
    console.log('   移动: A/D 或 ← →');
    console.log('   跳跃: W 或 空格');
    console.log('   攻击: J 或 鼠标左键');
    console.log('   重新开始: R');
});
