/**
 * input.js — 输入管理系统
 * 跟踪键盘按键状态和鼠标点击，提供 pressed/justPressed 查询接口
 */

/** 当前帧按键状态映射 键名 → true/false */
const keys = {};

/** 上一帧按键状态，用于检测"刚按下" */
const prevKeys = {};

/** 鼠标左键是否按下 */
let mousePressed = false;
let prevMousePressed = false;

// ==================== 键盘事件 ====================

window.addEventListener('keydown', (e) => {
    keys[e.code] = true;
    // 防止方向键滚动页面 / 空格滚动
    if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Space'].includes(e.code)) {
        e.preventDefault();
    }
});

window.addEventListener('keyup', (e) => {
    keys[e.code] = false;
});

// ==================== 鼠标事件 ====================

window.addEventListener('mousedown', (e) => {
    if (e.button === 0) { // 左键
        mousePressed = true;
    }
});

window.addEventListener('mouseup', (e) => {
    if (e.button === 0) {
        mousePressed = false;
    }
});

// ==================== 失焦处理 ====================

/** 窗口失去焦点时清除所有输入，防止按键卡住 */
window.addEventListener('blur', () => {
    for (const key in keys) {
        keys[key] = false;
    }
    mousePressed = false;
});

// ==================== 外部接口 ====================

/**
 * 检查按键当前是否被按下
 * @param {...string} codes - 按键代码（如 'KeyA', 'ArrowLeft'）
 * @returns {boolean}
 */
export function isPressed(...codes) {
    return codes.some(code => keys[code] === true);
}

/**
 * 检查按键是否在当前帧刚被按下（从松开变为按下）
 * 用于触发型操作（跳跃、攻击）
 * @param {...string} codes - 按键代码
 * @returns {boolean}
 */
export function justPressed(...codes) {
    return codes.some(code => keys[code] === true && prevKeys[code] !== true);
}

/**
 * 检查鼠标左键是否刚按下
 */
export function mouseJustPressed() {
    return mousePressed && !prevMousePressed;
}

/**
 * 每帧结束时调用，保存当前帧状态供下一帧比较
 */
export function updatePrevState() {
    for (const key in keys) {
        prevKeys[key] = keys[key];
    }
    prevMousePressed = mousePressed;
}

/**
 * 获取移动输入方向 (-1左, 0无, 1右)
 */
export function getMoveDirection() {
    let dir = 0;
    if (isPressed('KeyA', 'ArrowLeft')) dir -= 1;
    if (isPressed('KeyD', 'ArrowRight')) dir += 1;
    return dir;
}

/**
 * 是否按下跳跃
 */
export function isJumpPressed() {
    return isPressed('KeyW', 'ArrowUp', 'Space');
}

/**
 * 是否刚按下跳跃
 */
export function justJumpPressed() {
    return justPressed('KeyW', 'ArrowUp', 'Space');
}

/**
 * 是否刚按下攻击
 */
export function justAttackPressed() {
    return justPressed('KeyJ') || mouseJustPressed();
}
