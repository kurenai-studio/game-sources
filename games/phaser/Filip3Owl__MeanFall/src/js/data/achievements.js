// MeanFall — Achievement definitions
// Each achievement has a `check(player, ctx)` function that returns true when earned.
// `ctx` is an optional combat context: { maxStreak, allCorrect, feverReached, isElite, outcome }
// AchievementSystem.check() runs all of these and emits 'achievement-unlocked' for new ones.

// ── Helpers ───────────────────────────────────────────────────────────────────

const totalKills   = p => p.stats?.totalKills || 0;
const totalCorrect = p => Object.values(p.mastery            || {}).reduce((a, m) => a + (m.correct  || 0), 0);
const booksRead    = p => Object.values(p.bookLibrary        || {}).filter(e => e.read).length;
const questsClaimed= p => Object.values(p.questLog          || {}).filter(s => s === 'claimed').length;
const areaVisited  = (p, area) => !!(p.mastery || {})[area];
const masteryPct   = (p, area) => {
    const m = (p.mastery || {})[area];
    return m && m.attempted > 0 ? Math.round((m.correct / m.attempted) * 100) : 0;
};

// ── Achievement Definitions ───────────────────────────────────────────────────

export const ACHIEVEMENTS = {

    // ── PRIMEIROS PASSOS ──────────────────────────────────────────────────────
    first_blood: {
        id: 'first_blood',
        name: 'Primeiro Sangue',
        description: 'Derrote seu primeiro monstro.',
        icon: '⚔',
        category: 'combat',
        check: p => totalKills(p) >= 1,
    },
    first_correct: {
        id: 'first_correct',
        name: 'Eureka!',
        description: 'Acerte sua primeira questão de estatística.',
        icon: '✓',
        category: 'knowledge',
        check: p => totalCorrect(p) >= 1,
    },

    // ── ABATES ───────────────────────────────────────────────────────────────
    kills_10: {
        id: 'kills_10',
        name: 'Caçador Iniciante',
        description: 'Derrote 10 monstros.',
        icon: '☠',
        category: 'combat',
        check: p => totalKills(p) >= 10,
    },
    kills_50: {
        id: 'kills_50',
        name: 'Exterminador',
        description: 'Derrote 50 monstros.',
        icon: '☠',
        category: 'combat',
        xpReward: 100,
        check: p => totalKills(p) >= 50,
    },
    kills_100: {
        id: 'kills_100',
        name: 'Lenda das Batalhas',
        description: 'Derrote 100 monstros.',
        icon: '★',
        category: 'combat',
        xpReward: 200,
        check: p => totalKills(p) >= 100,
    },

    // ── ELITES ────────────────────────────────────────────────────────────────
    elite_first: {
        id: 'elite_first',
        name: 'Caçador de Élites',
        description: 'Derrote um monstro Elite pela primeira vez.',
        icon: '★',
        category: 'combat',
        check: p => (p.stats?.eliteKills || 0) >= 1,
    },
    elite_hunter: {
        id: 'elite_hunter',
        name: 'Élites Temem Você',
        description: 'Derrote 10 monstros Elite.',
        icon: '★',
        category: 'combat',
        xpReward: 150,
        check: p => (p.stats?.eliteKills || 0) >= 10,
    },

    // ── MÍMICOS ───────────────────────────────────────────────────────────────
    mimic_first: {
        id: 'mimic_first',
        name: 'Paranoia Justificada',
        description: 'Derrote seu primeiro Mímico.',
        icon: '⊙',
        category: 'combat',
        secret: true,
        rarity: 'rare',
        check: p => (p.stats?.mimicKills || 0) >= 1,
    },
    mimic_slayer: {
        id: 'mimic_slayer',
        name: 'Caçador de Mímicos',
        description: 'Derrote 5 Mímicos.',
        icon: '⊙',
        category: 'combat',
        xpReward: 150,
        goldReward: 75,
        secret: true,
        rarity: 'rare',
        check: p => (p.stats?.mimicKills || 0) >= 5,
    },

    // ── COMBATE PERFEITO ──────────────────────────────────────────────────────
    perfect_combat: {
        id: 'perfect_combat',
        name: 'Combate Perfeito',
        description: 'Vença um combate sem errar nenhuma questão.',
        icon: '♦',
        category: 'combat',
        check: (p, ctx) => ctx?.allCorrect && ctx?.outcome === 'win',
    },
    perfect_10: {
        id: 'perfect_10',
        name: 'Precisão Cirúrgica',
        description: 'Obtenha 10 combates perfeitos.',
        icon: '♦',
        category: 'combat',
        xpReward: 150,
        goldReward: 75,
        secret: true,
        rarity: 'rare',
        check: p => (p.stats?.perfectCombats || 0) >= 10,
    },

    // ── STREAK E FEVER ────────────────────────────────────────────────────────
    streak_5: {
        id: 'streak_5',
        name: 'Em Chamas',
        description: 'Alcance um streak de 5 acertos consecutivos em um combate.',
        icon: '⚡',
        category: 'combat',
        check: p => (p.stats?.longestStreak || 0) >= 5,
    },
    streak_10: {
        id: 'streak_10',
        name: 'Imparável',
        description: 'Alcance um streak de 10 acertos consecutivos em um combate.',
        icon: '⚡',
        category: 'combat',
        check: p => (p.stats?.longestStreak || 0) >= 10,
    },
    streak_15: {
        id: 'streak_15',
        name: 'Transcendente',
        description: 'Alcance um streak de 15 acertos consecutivos em um combate.',
        icon: '⚡',
        category: 'combat',
        xpReward: 200,
        goldReward: 150,
        secret: true,
        rarity: 'legendary',
        check: p => (p.stats?.longestStreak || 0) >= 15,
    },

    // ── CONHECIMENTO ──────────────────────────────────────────────────────────
    correct_50: {
        id: 'correct_50',
        name: 'Estudante Dedicado',
        description: 'Acerte 50 questões de estatística.',
        icon: '♦',
        category: 'knowledge',
        check: p => totalCorrect(p) >= 50,
    },
    correct_200: {
        id: 'correct_200',
        name: 'Veterano das Questões',
        description: 'Acerte 200 questões de estatística.',
        icon: '♦',
        category: 'knowledge',
        check: p => totalCorrect(p) >= 200,
    },
    correct_500: {
        id: 'correct_500',
        name: 'Estatístico Mestre',
        description: 'Acerte 500 questões de estatística.',
        icon: '★',
        category: 'knowledge',
        xpReward: 300,
        check: p => totalCorrect(p) >= 500,
    },

    // ── MAESTRIA POR ÁREA ─────────────────────────────────────────────────────
    mastery_village: {
        id: 'mastery_village',
        name: 'Mestre dos Dados',
        description: 'Atinja 80% de maestria em Tipos de Dados.',
        icon: 'μ',
        category: 'mastery',
        check: p => masteryPct(p, 'village') >= 80,
    },
    mastery_meadows: {
        id: 'mastery_meadows',
        name: 'Mestre das Medidas Centrais',
        description: 'Atinja 80% de maestria em Média, Mediana e Moda.',
        icon: 'μ',
        category: 'mastery',
        check: p => masteryPct(p, 'meadows') >= 80,
    },
    mastery_forest: {
        id: 'mastery_forest',
        name: 'Mestre da Dispersão',
        description: 'Atinja 80% de maestria em Variância e Desvio Padrão.',
        icon: 'σ',
        category: 'mastery',
        check: p => masteryPct(p, 'forest') >= 80,
    },
    mastery_plains: {
        id: 'mastery_plains',
        name: 'Mestre da Probabilidade',
        description: 'Atinja 80% de maestria em Probabilidade.',
        icon: 'π',
        category: 'mastery',
        check: p => masteryPct(p, 'plains') >= 80,
    },
    mastery_mountains: {
        id: 'mastery_mountains',
        name: 'Mestre das Distribuições',
        description: 'Atinja 80% de maestria em Distribuições.',
        icon: 'Δ',
        category: 'mastery',
        check: p => masteryPct(p, 'mountains') >= 80,
    },
    mastery_dungeon: {
        id: 'mastery_dungeon',
        name: 'Mestre da Inferência',
        description: 'Atinja 80% de maestria em Testes de Hipótese.',
        icon: 'H',
        category: 'mastery',
        check: p => masteryPct(p, 'dungeon') >= 80,
    },
    omniscient: {
        id: 'omniscient',
        name: 'Onisciente',
        description: 'Atinja 80% de maestria em todas as 6 áreas.',
        icon: '★',
        category: 'mastery',
        xpReward: 500,
        check: p => ['village', 'meadows', 'forest', 'plains', 'mountains', 'dungeon']
            .every(a => masteryPct(p, a) >= 80),
    },

    // ── NÍVEL ─────────────────────────────────────────────────────────────────
    level_5: {
        id: 'level_5',
        name: 'Aventureiro',
        description: 'Alcance o nível 5.',
        icon: '⬆',
        category: 'progression',
        check: p => p.level >= 5,
    },
    level_10: {
        id: 'level_10',
        name: 'Veterano',
        description: 'Alcance o nível 10.',
        icon: '⬆',
        category: 'progression',
        check: p => p.level >= 10,
    },
    level_15: {
        id: 'level_15',
        name: 'Herói Lendário',
        description: 'Alcance o nível 15.',
        icon: '★',
        category: 'progression',
        check: p => p.level >= 15,
    },

    // ── ECONOMIA ──────────────────────────────────────────────────────────────
    gold_500: {
        id: 'gold_500',
        name: 'Mercador Ambicioso',
        description: 'Acumule 500 de ouro em caixa.',
        icon: '♦',
        category: 'progression',
        check: p => (p.gold || 0) >= 500,
    },
    gold_2000: {
        id: 'gold_2000',
        name: 'Tesoureiro Supremo',
        description: 'Acumule 2000 de ouro em caixa.',
        icon: '♦',
        category: 'progression',
        check: p => (p.gold || 0) >= 2000,
    },

    // ── EXPLORAÇÃO ────────────────────────────────────────────────────────────
    area_meadows: {
        id: 'area_meadows',
        name: 'Além da Vila',
        description: 'Chegue aos Prados das Medidas.',
        icon: '⊕',
        category: 'exploration',
        check: p => areaVisited(p, 'meadows'),
    },
    area_forest: {
        id: 'area_forest',
        name: 'Na Sombra das Árvores',
        description: 'Entre na Floresta da Dispersão.',
        icon: '⊕',
        category: 'exploration',
        check: p => areaVisited(p, 'forest'),
    },
    area_codex: {
        id: 'area_codex',
        name: 'Hello, World',
        description: 'Resolva seu primeiro desafio de código na Cripta do Interpretador.',
        icon: '⌨',
        category: 'exploration',
        check: p => ((p.mastery || {}).codex?.attempted || 0) > 0,
    },
    codex_clean_run: {
        id: 'codex_clean_run',
        name: 'Merge Sem Conflito',
        description: 'Chegue a 20 desafios de código resolvidos.',
        icon: '⎇',
        category: 'combat',
        check: p => ((p.mastery || {}).codex?.correct || 0) >= 20,
    },
    codex_interpreter: {
        id: 'codex_interpreter',
        name: 'Exit Code 0',
        description: 'Derrote O Intérprete Primordial.',
        icon: '⏻',
        category: 'combat',
        check: p => ((p.questStats?.kills || {}).boss_codex || 0) >= 1,
    },
    area_dungeon: {
        id: 'area_dungeon',
        name: 'Descida ao Abismo',
        description: 'Entre na Masmorra da Inferência.',
        icon: '⊕',
        category: 'exploration',
        check: p => areaVisited(p, 'dungeon'),
    },

    // ── MISSÕES ───────────────────────────────────────────────────────────────
    quest_first: {
        id: 'quest_first',
        name: 'Herói de Aluguel',
        description: 'Complete sua primeira missão.',
        icon: '♖',
        category: 'quests',
        check: p => questsClaimed(p) >= 1,
    },
    quest_all: {
        id: 'quest_all',
        name: 'Herói das Lendas',
        description: 'Complete todas as 7 missões principais.',
        icon: '★',
        category: 'quests',
        xpReward: 250,
        check: p => questsClaimed(p) >= 7,
    },

    // ── BIBLIOTECA ────────────────────────────────────────────────────────────
    book_first: {
        id: 'book_first',
        name: 'Leitor Curioso',
        description: 'Leia seu primeiro tomo da biblioteca.',
        icon: '♜',
        category: 'collection',
        check: p => booksRead(p) >= 1,
    },
    book_half: {
        id: 'book_half',
        name: 'Erudito',
        description: 'Leia 9 tomos da biblioteca.',
        icon: '♜',
        xpReward: 100,
        category: 'collection',
        check: p => booksRead(p) >= 9,
    },
    book_all: {
        id: 'book_all',
        name: 'Bibliófilo',
        description: 'Leia todos os 18 tomos da biblioteca.',
        icon: '★',
        category: 'collection',
        xpReward: 200,
        check: p => booksRead(p) >= 18,
    },

    // ── BOUNTIES ──────────────────────────────────────────────────────────────
    bounty_5: {
        id: 'bounty_5',
        name: 'Mercenário',
        description: 'Complete 5 bounties diárias.',
        icon: '⊙',
        category: 'quests',
        check: p => (p.stats?.bountiesCompleted || 0) >= 5,
    },
    bounty_20: {
        id: 'bounty_20',
        name: 'Caçador de Recompensas',
        description: 'Complete 20 bounties diárias.',
        icon: '⊙',
        category: 'quests',
        check: p => (p.stats?.bountiesCompleted || 0) >= 20,
    },

    // ── A CÂMARA DA HIPÓTESE NULA ─────────────────────────────────────────────
    sanctum_judgement: {
        id: 'sanctum_judgement',
        name: 'Além do Alfa',
        description: 'Vença o Julgamento da Câmara da Hipótese Nula.',
        icon: '⚖',
        category: 'combat',
        xpReward: 500,
        check: p => !!p.sanctumCleared,
    },
};

export const ACHIEVEMENT_CATEGORIES = {
    combat:      { label: 'Combate',      color: '#ff6655' },
    knowledge:   { label: 'Conhecimento', color: '#55aaff' },
    mastery:     { label: 'Maestria',     color: '#ffaa22' },
    progression: { label: 'Progressão',   color: '#88ff88' },
    exploration: { label: 'Exploração',   color: '#aaffaa' },
    quests:      { label: 'Missões',      color: '#ffdd55' },
    collection:  { label: 'Coleção',      color: '#cc88ff' },
};
