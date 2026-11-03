import { XP_TABLE, DIFFICULTIES } from '../constants.js';
import EventBus from '../utils/EventBus.js';

export function awardXP(player, baseXP) {
    const diffDef = DIFFICULTIES[player.difficulty] || DIFFICULTIES.medium;
    const diffMult = diffDef.rewardMult;
    const statMult = 1 + (player.intelligence * 0.02);
    
    const earned = Math.floor(baseXP * statMult * diffMult);
    player.xp += earned;

    let leveled = false;
    while (player.xp >= xpToNext(player.level)) {
        player.xp -= xpToNext(player.level);
        levelUp(player);
        leveled = true;
    }

    EventBus.emit('player-xp-change', { player, earned });
    if (leveled) {
        EventBus.emit('player-level-up', { player });
        EventBus.emit('player-stats-changed', { player });
        EventBus.emit('player-hp-change', { player });
    }
    return earned;
}

export function xpToNext(level) {
    return XP_TABLE[Math.min(level - 1, 49)] ?? 999999;
}

function levelUp(player) {
    player.level++;
    player.maxHp += 10 + Math.floor(player.vitality * 0.5);
    player.maxFocus += 5 + Math.floor(player.intelligence * 0.3);
    player.hp = player.maxHp;
    player.focus = player.maxFocus;

    if (player.level % 3 === 0) {
        player.availableStatPoints = (player.availableStatPoints || 0) + 1;
    }
}

export function spendStatPoint(player, stat) {
    if (player.availableStatPoints <= 0) return false;
    if (!['strength', 'intelligence', 'agility', 'vitality'].includes(stat)) return false;
    player[stat]++;
    player.availableStatPoints--;
    if (stat === 'vitality') player.maxHp += 5;
    if (stat === 'intelligence') player.maxFocus += 3;
    EventBus.emit('player-stats-changed', { player });
    return true;
}

export function awardElementalXP(player, elementId, baseXP) {
    if (!player.elementalMastery[elementId]) return 0;
    
    const mastery = player.elementalMastery[elementId];
    mastery.xp += baseXP;
    mastery.totalCorrect++;

    let leveled = false;
    while (mastery.xp >= xpToNextElement(mastery.level)) {
        mastery.xp -= xpToNextElement(mastery.level);
        mastery.level++;
        leveled = true;
        
        // Apply passive attribute bonuses every 2 levels
        if (mastery.level % 2 === 0) {
            applyElementalBonus(player, elementId);
        }
    }

    EventBus.emit('element-xp-change', { player, elementId, earned: baseXP, leveled });
    return baseXP;
}

function applyElementalBonus(player, elementId) {
    let stat = '';
    let amount = 1;

    switch(elementId) {
        case 'fire':   stat = 'strength';     break;
        case 'earth':  stat = 'vitality';     break;
        case 'water':  stat = 'intelligence'; break;
        case 'ice':    stat = 'agility';      break;
        case 'shadow': 
            // Shadow is harder, gives random primary stat
            const stats = ['strength', 'intelligence', 'agility', 'vitality'];
            stat = stats[Math.floor(Math.random() * stats.length)];
            break;
        case 'normal':
            // Normal gives +HP/Focus directly
            player.maxHp += 5;
            player.maxFocus += 2;
            EventBus.emit('chat', { msg: `Maestria Normal: +5 HP e +2 Foco permanentes!`, type: 'system' });
            return;
    }

    if (stat) {
        player[stat] += amount;
        if (stat === 'vitality') player.maxHp += 5;
        if (stat === 'intelligence') player.maxFocus += 3;
        
        const statNames = { strength: 'Força', intelligence: 'Inteligência', agility: 'Agilidade', vitality: 'Vitalidade' };
        EventBus.emit('chat', { 
            msg: `Maestria em ${elementId.toUpperCase()}: +1 em ${statNames[stat]} permanente!`, 
            type: 'system' 
        });
        EventBus.emit('player-stats-changed', { player });
    }
}

export function xpToNextElement(level) {
    // Slower curve for elements: 50, 125, 230, 360...
    return Math.floor(50 * Math.pow(level, 1.4));
}

export function masteryPercent(mastery) {
    if (!mastery || mastery.attempted === 0) return 0;
    return Math.round((mastery.correct / mastery.attempted) * 100);
}
