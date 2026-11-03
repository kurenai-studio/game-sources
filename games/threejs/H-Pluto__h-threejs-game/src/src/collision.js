/**
 * collision.js — AABB碰撞检测与响应系统
 * 处理玩家↔平台、玩家↔敌人、攻击框↔敌人、弹幕↔玩家的碰撞
 */

/**
 * 检测两个AABB矩形是否重叠
 * @param {Object} a - { left, right, top, bottom }
 * @param {Object} b - { left, right, top, bottom }
 * @returns {boolean}
 */
export function checkAABB(a, b) {
    return (
        a.left < b.right &&
        a.right > b.left &&
        a.top < b.bottom &&
        a.bottom > b.top
    );
}

/**
 * 计算两个AABB的重叠深度
 * @returns {{ overlapX: number, overlapY: number } | null}
 */
export function getOverlap(a, b) {
    if (!checkAABB(a, b)) return null;

    const overlapLeft = a.right - b.left;
    const overlapRight = b.right - a.left;
    const overlapTop = a.bottom - b.top;
    const overlapBottom = b.bottom - a.top;

    // 取最小重叠方向
    const overlapX = overlapLeft < overlapRight ? -overlapLeft : overlapRight;
    const overlapY = overlapTop < overlapBottom ? -overlapTop : overlapBottom;

    return {
        overlapX,
        overlapY,
        // 是否为水平方向碰撞
        isHorizontal: Math.abs(overlapX) < Math.abs(overlapY),
    };
}

/**
 * 玩家与平台碰撞响应
 * 将玩家推出平台，处理站立、顶头、侧墙
 * @param {Object} player - 玩家对象（需有x,y,vx,vy,width,height,isGrounded）
 * @param {Array} platforms - 平台数组
 */
export function resolvePlayerPlatform(player, platforms) {
    let grounded = false;

    for (const plat of platforms) {
        const pa = player.getAABB();
        const pb = { left: plat.left, right: plat.right, top: plat.top, bottom: plat.bottom };

        const overlap = getOverlap(pa, pb);
        if (!overlap) continue;

        // 根据最小重叠方向决定响应方式
        if (Math.abs(overlap.overlapY) < Math.abs(overlap.overlapX)) {
            // 垂直碰撞
            if (overlap.overlapY < 0) {
                // 玩家在平台上方 → 站在平台上
                player.y += overlap.overlapY;
                player.vy = Math.max(0, player.vy); // 清除向下速度
                grounded = true;
            } else {
                // 玩家在平台下方 → 顶头
                player.y += overlap.overlapY;
                if (player.vy < 0) player.vy = 0;
            }
        } else {
            // 水平碰撞 → 侧墙
            player.x += overlap.overlapX;
            player.vx = 0;
        }
    }

    player.isGrounded = grounded;
    if (grounded && player.jumpHeld !== undefined) {
        player.jumpHeld = false;
    }
}

/**
 * 玩家攻击框与敌人碰撞检测
 * @param {Object} attackBox - 攻击AABB
 * @param {Array} enemies - 敌人数组
 * @returns {Array} 被命中的敌人列表
 */
export function checkAttackHitEnemies(attackBox, enemies) {
    const hitList = [];
    for (const enemy of enemies) {
        if (enemy.isDead || enemy.isDying) continue;
        const eb = enemy.getAABB();
        if (checkAABB(attackBox, eb)) {
            hitList.push(enemy);
        }
    }
    return hitList;
}

/**
 * 弹幕与玩家碰撞检测
 * @param {Array} projectiles - 弹幕数组
 * @param {Object} player - 玩家对象
 * @returns {Array} 命中玩家的弹幕列表
 */
export function checkProjectileHitPlayer(projectiles, player) {
    if (player.invincible || player.state === 'death') return [];
    const pa = player.getAABB();
    const hits = [];
    for (const proj of projectiles) {
        if (proj.dead) continue;
        const pb = {
            left: proj.x - proj.radius,
            right: proj.x + proj.radius,
            top: proj.y - proj.radius,
            bottom: proj.y + proj.radius,
        };
        if (checkAABB(pa, pb)) {
            hits.push(proj);
        }
    }
    return hits;
}

/**
 * 玩家与敌人身体碰撞（接触伤害）
 * @param {Object} player
 * @param {Array} enemies
 * @returns {Array} 碰撞的敌人列表
 */
export function checkPlayerEnemyContact(player, enemies) {
    if (player.invincible) return [];
    const pa = player.getAABB();
    const contacts = [];
    for (const enemy of enemies) {
        if (enemy.isDead || enemy.isDying) continue;
        if (checkAABB(pa, enemy.getAABB())) {
            contacts.push(enemy);
        }
    }
    return contacts;
}

/**
 * 玩家与物品碰撞检测
 * @param {Object} player
 * @param {Array} items
 * @returns {Array} 被收集的物品列表
 */
export function checkPlayerItemCollision(player, items) {
    const pa = player.getAABB();
    const collected = [];
    for (const item of items) {
        if (item.collected) continue;
        const ib = {
            left: item.x - item.width / 2,
            right: item.x + item.width / 2,
            top: item.y - item.height / 2,
            bottom: item.y + item.height / 2,
        };
        if (checkAABB(pa, ib)) {
            collected.push(item);
        }
    }
    return collected;
}

/**
 * 检查玩家是否到达终点区域
 * @param {Object} player
 * @param {Object} endZone - { x, y, w, h }
 */
export function checkEndZone(player, endZone) {
    const pa = player.getAABB();
    const ez = {
        left: endZone.x - endZone.w / 2,
        right: endZone.x + endZone.w / 2,
        top: endZone.y - endZone.h / 2,
        bottom: endZone.y + endZone.h / 2,
    };
    return checkAABB(pa, ez);
}

/**
 * 检查实体是否在地图边界内
 */
export function clampToBounds(entity, worldMinX, worldMaxX, worldMinY) {
    if (entity.x < worldMinX) entity.x = worldMinX;
    if (entity.x > worldMaxX) entity.x = worldMaxX;
    // 掉出世界（掉入深渊）
    if (entity.y > worldMinY + 200) {
        return true; // 表示已掉落
    }
    return false;
}
