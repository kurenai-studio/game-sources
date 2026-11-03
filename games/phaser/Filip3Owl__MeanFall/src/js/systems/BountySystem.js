import { BOUNTY_POOLS, DAILY_BOUNTY_COUNT } from '../data/bounties.js';
import { AREA_UNLOCK, ELEMENTS } from '../constants.js';
import { awardXP } from './XPSystem.js';
import { CombatSystem } from './CombatSystem.js';
import EventBus from '../utils/EventBus.js';

function todayStr() {
    return new Date().toISOString().slice(0, 10); // YYYY-MM-DD
}

// Monday of the current week — identifies the weekly contract cycle
function weekStr() {
    const d = new Date();
    d.setDate(d.getDate() - ((d.getDay() + 6) % 7));
    return d.toISOString().slice(0, 10);
}

// Element farmed in each area (matches monster population)
const AREA_ELEMENT = {
    village: 'normal', meadows: 'earth', forest: 'ice',
    plains: 'fire', mountains: 'water', dungeon: 'shadow',
    codex: 'shadow',
};

const AREA_ORDER = ['village', 'meadows', 'forest', 'plains', 'mountains', 'dungeon', 'codex'];

function masteryPct(player, areaKey) {
    const m = player.mastery?.[areaKey];
    return m && m.attempted > 0 ? Math.round((m.correct / m.attempted) * 100) : 0;
}

function isAreaUnlocked(player, area) {
    if (area === 'village') return true;
    const req = AREA_UNLOCK[area];
    if (!req) return false;
    const levelOk = !req.minLevel || player.level >= req.minLevel;
    const mastOk  = masteryPct(player, req.masteryArea) >= req.masteryPct;
    return levelOk && mastOk;
}

function pick(arr) {
    return arr[Math.floor(Math.random() * arr.length)];
}

export const BountySystem = {

    init(player) {
        if (!player.bountyLog) player.bountyLog = { date: '', slots: [] };
        this.refreshIfNewDay(player);
    },

    refreshIfNewDay(player) {
        const week = weekStr();
        if (player.bountyLog.date !== todayStr()) {
            // New day: regenerate dailies, keep the weekly contract if same week
            const weekly = player.bountyLog.week === week
                ? (player.bountyLog.slots || []).find(s => s.weekly)
                : null;
            player.bountyLog.date  = todayStr();
            player.bountyLog.slots = this._generate(player);
            player.bountyLog.slots.push(weekly || this._makeWeekly(player));
            player.bountyLog.week  = week;
        } else if (player.bountyLog.week !== week || !(player.bountyLog.slots || []).some(s => s.weekly)) {
            // Same day but week rolled over (or old save without weekly)
            player.bountyLog.slots = (player.bountyLog.slots || []).filter(s => !s.weekly);
            player.bountyLog.slots.push(this._makeWeekly(player));
            player.bountyLog.week  = week;
        }
    },

    // Big weekly contract: kill monsters of the highest unlocked area's element.
    // Reward scales with progression and includes forge materials.
    _makeWeekly(player) {
        const unlocked  = AREA_ORDER.filter(a => isAreaUnlocked(player, a));
        const area      = unlocked[unlocked.length - 1] || 'village';
        const tier      = AREA_ORDER.indexOf(area) + 1; // 1..6
        const element   = AREA_ELEMENT[area];
        const elemName  = ELEMENTS[element]?.name || element;
        return {
            templateId: `weekly_${element}`,
            weekly:     true,
            area,
            type:       'kill_element',
            label:      '⭐ CONTRATO DA SEMANA',
            desc:       `Derrote 25 criaturas de ${elemName} até domingo.`,
            element,
            monsterId:  null,
            objectiveArea: null,
            count:      25,
            progress:   0,
            status:     'active',
            reward: {
                xp:   150 * tier,
                gold: 120 * tier,
                materials: { element, qty: 5 },
            },
        };
    },

    _generate(player) {
        const unlocked = AREA_ORDER.filter(a => isAreaUnlocked(player, a));
        // Prioritize areas the player is most active in (reverse = highest first)
        const priority = [...unlocked].reverse();

        const slots   = [];
        const usedIds = new Set();

        for (const area of priority) {
            if (slots.length >= DAILY_BOUNTY_COUNT) break;
            const pool      = BOUNTY_POOLS[area] || [];
            const available = pool.filter(t => !usedIds.has(t.id));
            if (!available.length) continue;
            const tpl = pick(available);
            usedIds.add(tpl.id);
            slots.push(this._makeSlot(tpl, area));
        }

        // Fill remaining slots from village if player hasn't unlocked enough areas
        while (slots.length < DAILY_BOUNTY_COUNT) {
            const pool = BOUNTY_POOLS['village'];
            const available = pool.filter(t => !usedIds.has(t.id));
            if (!available.length) break;
            const tpl = pick(available);
            usedIds.add(tpl.id);
            slots.push(this._makeSlot(tpl, 'village'));
        }

        return slots;
    },

    _makeSlot(tpl, area) {
        return {
            templateId:    tpl.id,
            area,
            type:          tpl.type,
            label:         tpl.label,
            desc:          tpl.desc,
            monsterId:     tpl.monsterId    || null,
            element:       tpl.element      || null,
            objectiveArea: tpl.objectiveArea || null,
            count:         tpl.count,
            progress:      0,
            status:        'active',   // active | complete | claimed
            reward:        { ...tpl.reward },
        };
    },

    recordKill(player, monsterDef) {
        if (!player.bountyLog?.slots) return;

        for (const slot of player.bountyLog.slots) {
            if (slot.status !== 'active') continue;

            let match = false;
            if      (slot.type === 'kill')         match = monsterDef.id      === slot.monsterId;
            else if (slot.type === 'kill_area')    match = monsterDef.area    === slot.objectiveArea;
            else if (slot.type === 'kill_element') match = monsterDef.element === slot.element;

            if (match) {
                slot.progress = Math.min(slot.count, slot.progress + 1);
                if (slot.progress >= slot.count) {
                    slot.status = 'complete';
                    EventBus.emit('bounty-complete', { slot, player });
                }
            }
        }
    },

    claim(player, idx) {
        const slot = player.bountyLog?.slots?.[idx];
        if (!slot || slot.status !== 'complete') return false;

        if (slot.reward.xp)   awardXP(player, slot.reward.xp);
        if (slot.reward.gold) player.gold = (player.gold || 0) + slot.reward.gold;
        if (slot.reward.materials) {
            const { element, qty } = slot.reward.materials;
            for (let i = 0; i < qty; i++) {
                CombatSystem.addToInventory(player, `essence_${element}`);
            }
        }

        slot.status = 'claimed';
        EventBus.emit('bounty-claimed', { slot, player });
        return true;
    },

    getSlots(player) {
        return player.bountyLog?.slots || [];
    },

    timeUntilReset() {
        const now      = new Date();
        const tomorrow = new Date(now);
        tomorrow.setDate(tomorrow.getDate() + 1);
        tomorrow.setHours(0, 0, 0, 0);
        const ms = tomorrow - now;
        const h  = Math.floor(ms / 3600000);
        const m  = Math.floor((ms % 3600000) / 60000);
        return `${h}h ${m}m`;
    },
};
