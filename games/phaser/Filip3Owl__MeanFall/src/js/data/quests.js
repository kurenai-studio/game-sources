// MeanFall — Quest definitions
// Quests are statistics-themed objectives that reward XP and items.
// Each quest has objectives that track player progress (kills, items, mastery).

export const QUESTS = {
    // ── TUTORIAL / VILLAGE ────────────────────────────────────────────────────
    q_intro: {
        id: 'q_intro',
        name: 'A Primeira Lição',
        giver: 'elder',
        area: 'village',
        description: 'O ancião quer que você derrote 3 Wisps Tipológicos e aprenda sobre tipos de dados.',
        objective: { type: 'kill', monsterId: 'air_wisp', count: 3 },
        reward: { xp: 60, gold: 30, items: [{ itemId: 'health_potion', qty: 2 }] },
        prerequisite: null,
    },

    q_classify: {
        id: 'q_classify',
        name: 'Classificador',
        giver: 'scholar',
        area: 'village',
        description: 'Atinja 50% de maestria em Tipos de Dados respondendo perguntas corretamente.',
        objective: { type: 'mastery', area: 'village', percent: 50 },
        reward: { xp: 80, gold: 40, items: [{ itemId: 'leather_cap', qty: 1 }] },
        prerequisite: 'q_intro',
    },

    // ── MEADOWS ───────────────────────────────────────────────────────────────
    q_central: {
        id: 'q_central',
        name: 'O Centro de Tudo',
        giver: 'sage',
        area: 'meadows',
        description: 'Derrote 4 criaturas dos Prados para dominar média, mediana e moda.',
        objective: { type: 'kill_area', area: 'meadows', count: 4 },
        reward: { xp: 150, gold: 80, items: [{ itemId: 'wooden_sword', qty: 1 }] },
        prerequisite: 'q_intro',
    },

    // ── FOREST ────────────────────────────────────────────────────────────────
    q_disperse: {
        id: 'q_disperse',
        name: 'A Verdade Dispersa',
        giver: 'hermit',
        area: 'forest',
        description: 'Colete 1 Lâmina de Ferro derrotando criaturas elementais de Luz/Gelo.',
        objective: { type: 'collect', itemId: 'iron_blade', count: 1 },
        reward: { xp: 220, gold: 120, items: [{ itemId: 'leather_greaves', qty: 1 }] },
        prerequisite: 'q_central',
    },

    // ── PLAINS ────────────────────────────────────────────────────────────────
    q_chance: {
        id: 'q_chance',
        name: 'Os Caminhos do Acaso',
        giver: 'gambler',
        area: 'plains',
        description: 'Derrote 3 criaturas de Fogo para dominar a probabilidade.',
        objective: { type: 'kill_element', element: 'fire', count: 3 },
        reward: { xp: 320, gold: 200, items: [{ itemId: 'ring_of_focus', qty: 1 }] },
        prerequisite: 'q_disperse',
    },

    // ── MOUNTAINS ─────────────────────────────────────────────────────────────
    q_normal: {
        id: 'q_normal',
        name: 'A Curva Perfeita',
        giver: 'astronomer',
        area: 'mountains',
        description: 'Atinja nível 10 e derrote 2 criaturas de Água.',
        objective: { type: 'kill_element', element: 'water', count: 2 },
        reward: { xp: 500, gold: 300, items: [{ itemId: 'plate_armor', qty: 1 }] },
        prerequisite: 'q_chance',
    },

    // ── DUNGEON ───────────────────────────────────────────────────────────────
    q_inference: {
        id: 'q_inference',
        name: 'Senhor dos P-Valores',
        giver: 'oracle',
        area: 'dungeon',
        description: 'Derrote o Lich do P-valor — o mestre final da inferência.',
        objective: { type: 'kill', monsterId: 'shadow_lich', count: 1 },
        reward: { xp: 1500, gold: 1000, items: [{ itemId: 'crown_of_insight', qty: 1 }, { itemId: 'stats_amulet', qty: 1 }] },
        prerequisite: 'q_normal',
    },

    // ── CRIPTA DO INTERPRETADOR ───────────────────────────────────────────────
    q_codex_first: {
        id: 'q_codex_first',
        name: 'Compile ou Pereça',
        giver: 'archivist',
        area: 'codex',
        description: 'Derrote 4 criaturas da Cripta resolvendo os desafios de código que elas exigem.',
        objective: { type: 'kill_area', area: 'codex', count: 4 },
        reward: { xp: 2000, gold: 800, items: [{ itemId: 'supreme_health_potion', qty: 3 }] },
        prerequisite: 'q_inference',
    },

    q_codex_mastery: {
        id: 'q_codex_mastery',
        name: 'Revisão de Código',
        giver: 'archivist',
        area: 'codex',
        description: 'Alcance 60% de acerto nos desafios de código da Cripta.',
        objective: { type: 'mastery', area: 'codex', percent: 60 },
        reward: { xp: 2500, gold: 1000, items: [{ itemId: 'amulet_of_clarity', qty: 1 }] },
        prerequisite: 'q_codex_first',
    },

    q_codex_boss: {
        id: 'q_codex_boss',
        name: 'O Intérprete Primordial',
        giver: 'archivist',
        area: 'codex',
        description: 'Derrote O Intérprete Primordial — ele roda o que você escreveu, não o que você quis escrever.',
        objective: { type: 'kill', monsterId: 'boss_codex', count: 1 },
        reward: { xp: 5000, gold: 2500, items: [{ itemId: 'crown_of_archmage', qty: 1 }, { itemId: 'talisman_of_legends', qty: 1 }] },
        prerequisite: 'q_codex_first',
    },
};

// Quest log status per quest:
// undefined = not yet offered, 'available' = can be accepted,
// 'active' = in progress, 'complete' = ready to claim, 'claimed' = done.

export function questProgress(player, quest) {
    const obj = quest.objective;
    const stats = player.questStats || {};

    switch (obj.type) {
        case 'kill': {
            const k = (stats.kills || {})[obj.monsterId] || 0;
            return Math.min(k, obj.count);
        }
        case 'kill_area': {
            const k = (stats.killsByArea || {})[obj.area] || 0;
            return Math.min(k, obj.count);
        }
        case 'kill_element': {
            const k = (stats.killsByElement || {})[obj.element] || 0;
            return Math.min(k, obj.count);
        }
        case 'collect': {
            const inv = player.inventory || [];
            const slot = inv.find(s => s.itemId === obj.itemId);
            return Math.min(slot ? slot.qty : 0, obj.count);
        }
        case 'mastery': {
            const m = (player.mastery || {})[obj.area];
            const pct = m && m.attempted > 0 ? Math.round((m.correct / m.attempted) * 100) : 0;
            return Math.min(pct, obj.percent);
        }
    }
    return 0;
}

export function questTarget(quest) {
    const obj = quest.objective;
    return obj.count ?? obj.percent ?? 1;
}

export function questIsComplete(player, quest) {
    return questProgress(player, quest) >= questTarget(quest);
}
