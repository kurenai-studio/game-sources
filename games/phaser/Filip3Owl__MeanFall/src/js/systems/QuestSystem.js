import { QUESTS, questIsComplete, questProgress, questTarget } from '../data/quests.js';
import { CombatSystem } from './CombatSystem.js';
import { ITEMS }        from '../data/items.js';
import { awardXP }      from './XPSystem.js';
import EventBus         from '../utils/EventBus.js';

export const QuestSystem = {

    init(player) {
        if (!player.questLog)   player.questLog   = {}; // questId → status
        if (!player.questStats) player.questStats = { kills: {}, killsByArea: {}, killsByElement: {} };
    },

    /** Returns quests offered by an NPC that aren't yet active/claimed. */
    questsForNPC(player, npcId) {
        this.init(player);
        const out = [];
        for (const q of Object.values(QUESTS)) {
            if (q.giver !== npcId) continue;
            const status = player.questLog[q.id];
            if (status === 'claimed') continue;
            if (q.prerequisite && player.questLog[q.prerequisite] !== 'claimed') continue;
            out.push({ quest: q, status: status || 'available' });
        }
        return out;
    },

    accept(player, questId) {
        this.init(player);
        if (player.questLog[questId]) return false;
        player.questLog[questId] = 'active';
        EventBus.emit('quest-accepted', { questId, player });
        return true;
    },

    /** Called whenever a relevant gameplay event occurs. */
    recordKill(player, monsterDef) {
        this.init(player);
        const stats = player.questStats;
        stats.kills[monsterDef.id] = (stats.kills[monsterDef.id] || 0) + 1;
        if (monsterDef.area)    stats.killsByArea[monsterDef.area]       = (stats.killsByArea[monsterDef.area] || 0) + 1;
        if (monsterDef.element) stats.killsByElement[monsterDef.element] = (stats.killsByElement[monsterDef.element] || 0) + 1;
        this._checkActiveQuests(player);
    },

    _checkActiveQuests(player) {
        for (const [id, status] of Object.entries(player.questLog)) {
            if (status !== 'active') continue;
            const quest = QUESTS[id];
            if (!quest) continue;
            if (questIsComplete(player, quest)) {
                player.questLog[id] = 'complete';
                EventBus.emit('quest-complete', { questId: id, player });
            }
        }
    },

    refresh(player) {
        this.init(player);
        this._checkActiveQuests(player);
    },

    claim(player, questId) {
        this.init(player);
        const quest = QUESTS[questId];
        if (!quest) return false;
        if (player.questLog[questId] !== 'complete') return false;

        const r = quest.reward || {};
        if (r.xp)   awardXP(player, r.xp);
        if (r.gold) player.gold = (player.gold || 0) + r.gold;
        if (r.items) for (const { itemId, qty } of r.items) {
            for (let i = 0; i < (qty || 1); i++) CombatSystem.addToInventory(player, itemId);
        }
        player.questLog[questId] = 'claimed';
        EventBus.emit('quest-claimed', { questId, player, reward: r });
        return true;
    },

    progressInfo(player, questId) {
        const quest = QUESTS[questId];
        if (!quest) return null;
        return { current: questProgress(player, quest), target: questTarget(quest) };
    },
};
