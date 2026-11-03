// MeanFall — Skills (passive abilities the hero unlocks at certain levels)
// Each skill is unlocked at a specific level. The player must CHOOSE which
// skills to learn — there are typically more options than slots available.

export const SKILLS = {
    // ── LEVEL 2 ──────────────────────────────────────────────────────────────
    sharp_mind: {
        id: 'sharp_mind', name: 'Mente Afiada',
        unlockLevel: 2, tier: 1,
        description: '+10% XP ganho em batalhas.',
        effects: { xpMultBonus: 0.10 },
    },
    iron_will: {
        id: 'iron_will', name: 'Vontade de Ferro',
        unlockLevel: 2, tier: 1,
        description: '+15 HP máximo permanente.',
        effects: { maxHpBonus: 15 },
    },
    quick_step: {
        id: 'quick_step', name: 'Passo Rápido',
        unlockLevel: 2, tier: 1,
        description: '+2 Agilidade permanente.',
        effects: { agilityBonus: 2 },
    },

    // ── LEVEL 4 ──────────────────────────────────────────────────────────────
    focused_strike: {
        id: 'focused_strike', name: 'Golpe Focado',
        unlockLevel: 4, tier: 2,
        description: 'Streak começa contando 1 (primeiro acerto já dá +2 dano).',
        effects: { streakBaseBonus: 1 },
    },
    scholar: {
        id: 'scholar', name: 'Erudito',
        unlockLevel: 4, tier: 2,
        description: 'Livros concedem +50% XP na primeira leitura.',
        effects: { bookXpMult: 1.5 },
    },
    haggler: {
        id: 'haggler', name: 'Negociador',
        unlockLevel: 4, tier: 2,
        description: 'Vende itens a 70% (em vez de 50%).',
        effects: { sellRatio: 0.70 },
    },

    // ── LEVEL 6 ──────────────────────────────────────────────────────────────
    second_wind: {
        id: 'second_wind', name: 'Segundo Fôlego',
        unlockLevel: 6, tier: 3,
        description: 'Regenera 2 HP a cada 3s (em vez de 1).',
        effects: { hpRegenBonus: 1 },
    },
    deep_focus: {
        id: 'deep_focus', name: 'Foco Profundo',
        unlockLevel: 6, tier: 3,
        description: 'Regenera 4 Foco a cada 3s (em vez de 2).',
        effects: { focusRegenBonus: 2 },
    },
    crit_master: {
        id: 'crit_master', name: 'Mestre Crítico',
        unlockLevel: 6, tier: 3,
        description: '+10% chance de acerto crítico.',
        effects: { critBonus: 0.10 },
    },

    // ── LEVEL 8 ──────────────────────────────────────────────────────────────
    elemental_mastery: {
        id: 'elemental_mastery', name: 'Maestria Elemental',
        unlockLevel: 8, tier: 4,
        description: 'Vantagens elementais aumentam dano em 1.75× (em vez de 1.5×).',
        effects: { elementBonus: 0.25 },
    },
    treasure_hunter: {
        id: 'treasure_hunter', name: 'Caçador de Tesouros',
        unlockLevel: 8, tier: 4,
        description: '+15% chance em todos os drops.',
        effects: { lootBonus: 0.15 },
    },

    // ── LEVEL 10 ─────────────────────────────────────────────────────────────
    archmage: {
        id: 'archmage', name: 'Arquimago Estatístico',
        unlockLevel: 10, tier: 5,
        description: '+5 Inteligência permanente, +20 Foco máx.',
        effects: { intelligenceBonus: 5, maxFocusBonus: 20 },
    },
    survivor: {
        id: 'survivor', name: 'Sobrevivente',
        unlockLevel: 10, tier: 5,
        description: '+30 HP máximo, dano recebido reduzido em 10%.',
        effects: { maxHpBonus: 30, damageReduction: 0.10 },
    },
};

// How many skills the player can have at each tier (forces choices).
export const SKILL_SLOTS_PER_TIER = {
    1: 1, // pick 1 of 3
    2: 1, // pick 1 of 3
    3: 1, // pick 1 of 3
    4: 1, // pick 1 of 2
    5: 1, // pick 1 of 2
};
