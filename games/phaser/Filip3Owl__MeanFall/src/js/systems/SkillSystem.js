import { SKILLS, SKILL_SLOTS_PER_TIER } from '../data/skills.js';
import EventBus from '../utils/EventBus.js';

export const SkillSystem = {

    init(player) {
        if (!player.skills) player.skills = [];
    },

    /** Returns array of skills the player can pick now (unlocked but not chosen). */
    availableSkills(player) {
        this.init(player);
        return Object.values(SKILLS).filter(s =>
            player.level >= s.unlockLevel && !player.skills.includes(s.id)
        );
    },

    /** Returns tiers where the player has remaining slots and can pick from. */
    pendingChoices(player) {
        this.init(player);
        const tiersAvailable = {};
        for (const s of Object.values(SKILLS)) {
            if (player.level < s.unlockLevel) continue;
            if (!tiersAvailable[s.tier]) tiersAvailable[s.tier] = { tier: s.tier, options: [], picked: 0 };
            if (player.skills.includes(s.id)) tiersAvailable[s.tier].picked++;
            else tiersAvailable[s.tier].options.push(s);
        }
        return Object.values(tiersAvailable).filter(t =>
            (t.picked < (SKILL_SLOTS_PER_TIER[t.tier] || 1)) && t.options.length > 0
        );
    },

    chooseSkill(player, skillId) {
        this.init(player);
        const skill = SKILLS[skillId];
        if (!skill) return false;
        if (player.level < skill.unlockLevel) return false;
        if (player.skills.includes(skillId))  return false;

        // Check tier slots
        const taken = player.skills.filter(id => SKILLS[id]?.tier === skill.tier).length;
        const max   = SKILL_SLOTS_PER_TIER[skill.tier] || 1;
        if (taken >= max) return false;

        player.skills.push(skillId);
        // Apply persistent effects (stat bonuses)
        const e = skill.effects || {};
        if (e.maxHpBonus)        { player.maxHp = (player.maxHp || 0) + e.maxHpBonus; player.hp = Math.min(player.maxHp, player.hp + e.maxHpBonus); }
        if (e.maxFocusBonus)     { player.maxFocus = (player.maxFocus || 0) + e.maxFocusBonus; player.focus = Math.min(player.maxFocus, player.focus + e.maxFocusBonus); }
        if (e.agilityBonus)       player.agility = (player.agility || 0) + e.agilityBonus;
        if (e.intelligenceBonus)  player.intelligence = (player.intelligence || 0) + e.intelligenceBonus;
        if (e.strengthBonus)      player.strength = (player.strength || 0) + e.strengthBonus;
        if (e.vitalityBonus)      player.vitality = (player.vitality || 0) + e.vitalityBonus;

        EventBus.emit('player-stats-changed', { player });
        EventBus.emit('player-hp-change',     { player });
        EventBus.emit('chat', { msg: `Habilidade aprendida: ${skill.name}!`, type: 'levelup' });
        return true;
    },

    /** Aggregated effect modifier for combat / loot lookups. */
    effectsOf(player, key) {
        this.init(player);
        let total = 0;
        for (const id of player.skills) {
            const s = SKILLS[id];
            if (s?.effects?.[key]) total += s.effects[key];
        }
        return total;
    },

    has(player, skillId) {
        return (player.skills || []).includes(skillId);
    },
};
