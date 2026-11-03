// MeanFall — Item Catalog
// Each item is either a 'consumable' (used from inventory) or 'equipment'
// (worn in a slot, applies passive bonuses while equipped).

export const ITEMS = {

    // ─── CONSUMÍVEIS ──────────────────────────────────────────────────────────
    health_potion: {
        id: 'health_potion', name: 'Poção de Vida', type: 'consumable', rarity: 'common',
        description: 'Restaura 30 HP.', effect: { hp: 30 }, value: 20, icon: 'item_potion_red',
    },
    greater_health_potion: {
        id: 'greater_health_potion', name: 'Poção de Vida Maior', type: 'consumable', rarity: 'uncommon',
        description: 'Restaura 70 HP.', effect: { hp: 70 }, value: 50, icon: 'item_potion_red',
    },
    focus_potion: {
        id: 'focus_potion', name: 'Poção de Foco', type: 'consumable', rarity: 'common',
        description: 'Restaura 20 de Foco.', effect: { focus: 20 }, value: 15, icon: 'item_potion_blue',
    },
    data_scroll: {
        id: 'data_scroll', name: 'Pergaminho de Dados', type: 'consumable', rarity: 'common',
        description: 'Restaura 10 HP e 10 Foco.', effect: { hp: 10, focus: 10 }, value: 25, icon: 'item_scroll',
    },

    // ─── CONSUMÍVEIS AVANÇADOS ────────────────────────────────────────────────
    supreme_health_potion: {
        id: 'supreme_health_potion', name: 'Elixir da Vida', type: 'consumable', rarity: 'rare',
        description: 'Restaura todo o HP.', effect: { hp: 9999 }, value: 220, icon: 'item_potion_red',
    },
    full_focus_elixir: {
        id: 'full_focus_elixir', name: 'Elixir de Foco Total', type: 'consumable', rarity: 'uncommon',
        description: 'Restaura todo o Foco.', effect: { focus: 9999 }, value: 160, icon: 'item_potion_blue',
    },

    // ─── CABEÇA ───────────────────────────────────────────────────────────────
    leather_cap: {
        id: 'leather_cap', name: 'Capuz de Couro', type: 'equipment', slot: 'head', rarity: 'common',
        description: '+5 HP máximo.', bonuses: { maxHp: 5 }, value: 30, icon: 'item_helm',
    },
    mage_hat: {
        id: 'mage_hat', name: 'Chapéu do Mago', type: 'equipment', slot: 'head', rarity: 'uncommon',
        description: '+3 INT, +10 Foco máx.', bonuses: { intelligence: 3, maxFocus: 10 }, value: 80, icon: 'item_helm',
    },
    crown_of_insight: {
        id: 'crown_of_insight', name: 'Coroa do Conhecimento', type: 'equipment', slot: 'head', rarity: 'rare',
        element: 'normal',
        description: '+5 INT, +15 Foco máx, +1 todos atributos.',
        bonuses: { intelligence: 5, maxFocus: 15, strength: 1, agility: 1, vitality: 1 }, value: 200, icon: 'item_helm',
    },
    crown_of_archmage: {
        id: 'crown_of_archmage', name: 'Coroa do Arquimago', type: 'equipment', slot: 'head', rarity: 'legendary',
        element: 'shadow',
        description: '+10 INT, +30 Foco máx, +3 em todos, +20 HP máx.',
        bonuses: { intelligence: 10, maxFocus: 30, strength: 3, agility: 3, vitality: 3, maxHp: 20 },
        value: 800, icon: 'item_helm',
    },

    // ─── PEITO ────────────────────────────────────────────────────────────────
    leather_armor: {
        id: 'leather_armor', name: 'Armadura de Couro', type: 'equipment', slot: 'chest', rarity: 'common',
        description: '+10 HP máx, +1 VIT.', bonuses: { maxHp: 10, vitality: 1 }, value: 50, icon: 'item_armor',
    },
    chain_mail: {
        id: 'chain_mail', name: 'Cota de Malha', type: 'equipment', slot: 'chest', rarity: 'uncommon',
        description: '+25 HP máx, +2 VIT.', bonuses: { maxHp: 25, vitality: 2 }, value: 120, icon: 'item_armor',
    },
    plate_armor: {
        id: 'plate_armor', name: 'Armadura de Placas', type: 'equipment', slot: 'chest', rarity: 'rare',
        element: 'earth',
        description: '+50 HP máx, +4 VIT, +2 FOR.',
        bonuses: { maxHp: 50, vitality: 4, strength: 2 }, value: 250, icon: 'item_armor',
    },
    dragonscale_mail: {
        id: 'dragonscale_mail', name: 'Cota de Escamas', type: 'equipment', slot: 'chest', rarity: 'epic',
        element: 'fire',
        description: '+80 HP máx, +6 VIT, +3 FOR. Resistência a Fogo.',
        bonuses: { maxHp: 80, vitality: 6, strength: 3 }, value: 500, icon: 'item_armor',
    },

    // ─── CABEÇA (continuação) ─────────────────────────────────────────────────
    crown_of_statistics: {
        id: 'crown_of_statistics', name: 'Coroa do Estatístico', type: 'equipment', slot: 'head', rarity: 'epic',
        element: 'normal',
        description: '+8 INT, +8 VIT, +40 HP máx, +20 Foco máx.',
        bonuses: { intelligence: 8, vitality: 8, maxHp: 40, maxFocus: 20 }, value: 2200, icon: 'item_helm',
    },

    // ─── PEITO (continuação) ──────────────────────────────────────────────────
    specialist_armor: {
        id: 'specialist_armor', name: 'Armadura do Especialista', type: 'equipment', slot: 'chest', rarity: 'epic',
        element: 'earth',
        description: '+100 HP máx, +8 VIT, +3 FOR.',
        bonuses: { maxHp: 100, vitality: 8, strength: 3 }, value: 1500, icon: 'item_armor',
    },
    legendary_robe: {
        id: 'legendary_robe', name: 'Veste Lendária', type: 'equipment', slot: 'chest', rarity: 'legendary',
        element: 'water',
        description: '+150 HP máx, +10 VIT, +5 FOR, +5 INT.',
        bonuses: { maxHp: 150, vitality: 10, strength: 5, intelligence: 5 }, value: 4500, icon: 'item_armor',
    },

    // ─── PERNAS ───────────────────────────────────────────────────────────────
    cloth_pants: {
        id: 'cloth_pants', name: 'Calças de Pano', type: 'equipment', slot: 'legs', rarity: 'common',
        description: '+1 AGI.', bonuses: { agility: 1 }, value: 25, icon: 'item_legs',
    },
    leather_greaves: {
        id: 'leather_greaves', name: 'Grevas de Couro', type: 'equipment', slot: 'legs', rarity: 'uncommon',
        description: '+10 HP máx, +2 AGI.', bonuses: { maxHp: 10, agility: 2 }, value: 70, icon: 'item_legs',
    },

    greaves_of_wind: {
        id: 'greaves_of_wind', name: 'Grevas do Vento', type: 'equipment', slot: 'legs', rarity: 'rare',
        description: '+5 AGI, +15 HP máx.', bonuses: { agility: 5, maxHp: 15 }, value: 420, icon: 'item_legs',
    },

    // ─── PÉS ──────────────────────────────────────────────────────────────────
    worn_boots: {
        id: 'worn_boots', name: 'Botas Gastas', type: 'equipment', slot: 'feet', rarity: 'common',
        description: '+1 AGI.', bonuses: { agility: 1 }, value: 20, icon: 'item_boots',
    },
    boots_agility: {
        id: 'boots_agility', name: 'Botas da Agilidade', type: 'equipment', slot: 'feet', rarity: 'uncommon',
        description: '+3 AGI.', bonuses: { agility: 3 }, value: 80, icon: 'item_boots',
    },

    boots_of_swiftness: {
        id: 'boots_of_swiftness', name: 'Botas da Velocidade', type: 'equipment', slot: 'feet', rarity: 'rare',
        description: '+6 AGI, +5 VIT.', bonuses: { agility: 6, vitality: 5 }, value: 480, icon: 'item_boots',
    },

    // ─── MÃOS ─────────────────────────────────────────────────────────────────
    wooden_sword: {
        id: 'wooden_sword', name: 'Espada de Madeira', type: 'equipment', slot: 'rightHand', rarity: 'common',
        description: '+2 FOR. Dano instável (Uniforme).', 
        bonuses: { strength: 2 }, 
        damageDistribution: 'uniform', damageRange: [0.7, 1.3],
        value: 40, icon: 'item_sword',
    },
    iron_blade: {
        id: 'iron_blade', name: 'Lâmina de Ferro', type: 'equipment', slot: 'rightHand', rarity: 'uncommon',
        description: '+5 FOR. Dano consistente (Normal).', 
        bonuses: { strength: 5 },
        damageDistribution: 'normal', damageRange: [0.8, 1.2],
        value: 110, icon: 'item_sword',
    },
    elemental_staff: {
        id: 'elemental_staff', name: 'Cajado Elemental', type: 'equipment', slot: 'rightHand', rarity: 'rare',
        element: 'shadow',
        description: '+4 INT, +3 FOR, +10 Foco máx. Dano instável (Uniforme).',
        bonuses: { intelligence: 4, strength: 3, maxFocus: 10 },
        damageDistribution: 'uniform', damageRange: [0.5, 1.5],
        value: 220, icon: 'item_staff',
    },
    blade_of_inference: {
        id: 'blade_of_inference', name: 'Lâmina da Inferência', type: 'equipment', slot: 'rightHand', rarity: 'legendary',
        element: 'shadow',
        description: '+12 FOR, +6 INT, +20 Foco máx. Dano muito preciso (Normal).',
        bonuses: { strength: 12, intelligence: 6, maxFocus: 20 },
        damageDistribution: 'normal', damageRange: [0.9, 1.1],
        value: 1200, icon: 'item_sword',
    },
    sword_of_probability: {
        id: 'sword_of_probability', name: 'Espada da Probabilidade', type: 'equipment', slot: 'rightHand', rarity: 'epic',
        element: 'fire',
        description: '+12 FOR, +4 INT. Dano consistente (Normal).',
        bonuses: { strength: 12, intelligence: 4 },
        damageDistribution: 'normal', damageRange: [0.85, 1.15],
        value: 950, icon: 'item_sword',
    },
    staff_of_distributions: {
        id: 'staff_of_distributions', name: 'Cajado das Distribuições', type: 'equipment', slot: 'rightHand', rarity: 'epic',
        element: 'water',
        description: '+10 INT, +5 AGI, +25 Foco máx. Dano variável (Uniforme).',
        bonuses: { intelligence: 10, agility: 5, maxFocus: 25 },
        damageDistribution: 'uniform', damageRange: [0.6, 1.4],
        value: 1100, icon: 'item_staff',
    },
    blade_of_sigma: {
        id: 'blade_of_sigma', name: 'Lâmina de Sigma', type: 'equipment', slot: 'rightHand', rarity: 'legendary',
        element: 'ice',
        description: '+20 FOR, +8 AGI. Dano ultra-preciso (±5%).',
        bonuses: { strength: 20, agility: 8 },
        damageDistribution: 'normal', damageRange: [0.95, 1.05],
        value: 3500, icon: 'item_sword',
    },
    staff_of_the_oracle: {
        id: 'staff_of_the_oracle', name: 'Cajado do Oráculo', type: 'equipment', slot: 'rightHand', rarity: 'legendary',
        element: 'shadow',
        description: '+14 INT, +8 AGI, +40 Foco máx. Dano caótico mas devastador.',
        bonuses: { intelligence: 14, agility: 8, maxFocus: 40 },
        damageDistribution: 'uniform', damageRange: [0.5, 1.5],
        value: 4000, icon: 'item_staff',
    },
    wooden_shield: {
        id: 'wooden_shield', name: 'Escudo de Madeira', type: 'equipment', slot: 'leftHand', rarity: 'common',
        description: '+8 HP máx, +1 VIT.', bonuses: { maxHp: 8, vitality: 1 }, value: 35, icon: 'item_shield',
    },
    iron_shield: {
        id: 'iron_shield', name: 'Escudo de Ferro', type: 'equipment', slot: 'leftHand', rarity: 'uncommon',
        description: '+20 HP máx, +3 VIT.', bonuses: { maxHp: 20, vitality: 3 }, value: 120, icon: 'item_shield',
    },

    shield_of_inference: {
        id: 'shield_of_inference', name: 'Escudo da Inferência', type: 'equipment', slot: 'leftHand', rarity: 'rare',
        element: 'shadow',
        description: '+35 HP máx, +5 VIT.', bonuses: { maxHp: 35, vitality: 5 }, value: 800, icon: 'item_shield',
    },
    bulwark_of_distribution: {
        id: 'bulwark_of_distribution', name: 'Baluarte das Distribuições', type: 'equipment', slot: 'leftHand', rarity: 'epic',
        element: 'water',
        description: '+60 HP máx, +8 VIT, +3 FOR.',
        bonuses: { maxHp: 60, vitality: 8, strength: 3 }, value: 1800, icon: 'item_shield',
    },

    // ─── ACESSÓRIOS ───────────────────────────────────────────────────────────
    copper_ring: {
        id: 'copper_ring', name: 'Anel de Cobre', type: 'equipment', slot: 'ring', rarity: 'common',
        description: '+1 INT.', bonuses: { intelligence: 1 }, value: 30, icon: 'item_ring',
    },
    ring_of_focus: {
        id: 'ring_of_focus', name: 'Anel do Foco', type: 'equipment', slot: 'ring', rarity: 'rare',
        description: '+3 INT, +20 Foco máx.', bonuses: { intelligence: 3, maxFocus: 20 }, value: 180, icon: 'item_ring',
    },
    stats_amulet: {
        id: 'stats_amulet', name: 'Amuleto Estatístico', type: 'equipment', slot: 'amulet', rarity: 'rare',
        element: 'normal',
        description: '+2 em todos atributos.',
        bonuses: { strength: 2, intelligence: 2, agility: 2, vitality: 2 }, value: 250, icon: 'item_amulet',
    },
    talisman_of_legends: {
        id: 'talisman_of_legends', name: 'Talismã das Lendas', type: 'equipment', slot: 'amulet', rarity: 'legendary',
        element: 'water',
        description: '+5 todos atributos, +30 HP máx, +20 Foco máx.',
        bonuses: { strength: 5, intelligence: 5, agility: 5, vitality: 5, maxHp: 30, maxFocus: 20 },
        value: 1000, icon: 'item_amulet',
    },
    amulet_of_clarity: {
        id: 'amulet_of_clarity', name: 'Amuleto da Clareza', type: 'equipment', slot: 'amulet', rarity: 'uncommon',
        description: '+2 INT, +15 Foco máx.', bonuses: { intelligence: 2, maxFocus: 15 }, value: 100, icon: 'item_amulet',
    },
    ring_of_mastery: {
        id: 'ring_of_mastery', name: 'Anel da Maestria', type: 'equipment', slot: 'ring', rarity: 'epic',
        element: 'normal',
        description: '+5 INT, +5 AGI, +20 Foco máx.',
        bonuses: { intelligence: 5, agility: 5, maxFocus: 20 }, value: 1200, icon: 'item_ring',
    },
    arcane_talisman: {
        id: 'arcane_talisman', name: 'Talismã Arcano', type: 'equipment', slot: 'amulet', rarity: 'legendary',
        element: 'normal',
        description: '+8 em todos atributos, +50 HP máx, +30 Foco máx.',
        bonuses: { strength: 8, intelligence: 8, agility: 8, vitality: 8, maxHp: 50, maxFocus: 30 },
        value: 6000, icon: 'item_amulet',
    },

    // ─── RELÍQUIAS DOS CHEFES ─────────────────────────────────────────────────
    // Itens únicos dropados apenas por chefes. Não podem ser vendidos.
    // Cada um muda fundamentalmente a mecânica de combate.
    relic_wind: {
        id: 'relic_wind', name: 'Essência do Vento', type: 'equipment', slot: 'relic',
        rarity: 'legendary', value: 0, sellable: false,
        passiveEffect: { type: 'focus_regen_on_correct', value: 3 },
        description: 'Cada resposta correta recupera 3 Foco.',
        flavor: 'O último sopro do Arauto Eterno, cristalizado pela estatística.',
        icon: 'item_ring',
    },
    relic_earth: {
        id: 'relic_earth', name: 'Cristal da Mediana', type: 'equipment', slot: 'relic',
        rarity: 'legendary', value: 0, sellable: false,
        passiveEffect: { type: 'xp_multiplier', value: 1.5 },
        description: '+50% de XP em todos os combates.',
        flavor: 'A pedra-coração do Colossus, que nunca mente sobre a maioria.',
        icon: 'item_ring',
    },
    relic_light: {
        id: 'relic_light', name: 'Prisma da Clareza', type: 'equipment', slot: 'relic',
        rarity: 'legendary', value: 0, sellable: false,
        passiveEffect: { type: 'free_hints', value: true },
        description: 'Dicas custam 0 Foco.',
        flavor: 'O cristal do Prism Celestial refrata toda dúvida em clareza.',
        icon: 'item_ring',
    },
    relic_fire: {
        id: 'relic_fire', name: 'Chama Perpétua', type: 'equipment', slot: 'relic',
        rarity: 'legendary', value: 0, sellable: false,
        passiveEffect: { type: 'damage_boost_correct', value: 0.8 },
        description: 'Respostas corretas causam +80% dano ao monstro.',
        flavor: 'O coração da Grande Fênix, que nunca deixa de queimar.',
        icon: 'item_ring',
    },
    relic_water: {
        id: 'relic_water', name: 'Orbe das Marés', type: 'equipment', slot: 'relic',
        rarity: 'legendary', value: 0, sellable: false,
        passiveEffect: { type: 'damage_block_chance', value: 0.30 },
        description: '30% de chance de anular completamente o dano de um erro.',
        flavor: 'A escama do Leviatã Profundo, mais dura que qualquer aço.',
        icon: 'item_ring',
    },
    relic_shadow: {
        id: 'relic_shadow', name: 'Coroa das Trevas', type: 'equipment', slot: 'relic',
        rarity: 'legendary', value: 0, sellable: false,
        passiveEffect: { type: 'streak_xp_double', value: 4 },
        description: 'Acertar 4 seguidas em um combate dobra o XP final.',
        flavor: 'A coroa do Rei das Sombras, forjada com XP de almas consumidas.',
        icon: 'item_ring',
    },

    // ─── MATERIAIS DE FORJA ───────────────────────────────────────────────────
    // Dropados por monstros do elemento correspondente. Usados pelo Ferreiro
    // Brom (Prados) para aprimorar equipamentos (+1 / +2 / +3).
    essence_fire: {
        id: 'essence_fire', name: 'Essência de Fogo', type: 'material', rarity: 'uncommon',
        element: 'fire', value: 30, icon: 'item_essence_fire',
        description: 'Fragmento incandescente deixado por criaturas de Fogo. Usado na forja.',
    },
    essence_earth: {
        id: 'essence_earth', name: 'Fragmento de Terra', type: 'material', rarity: 'uncommon',
        element: 'earth', value: 30, icon: 'item_essence_earth',
        description: 'Pedra densa e estável deixada por criaturas de Terra. Usada na forja.',
    },
    essence_water: {
        id: 'essence_water', name: 'Gota Abissal', type: 'material', rarity: 'uncommon',
        element: 'water', value: 30, icon: 'item_essence_water',
        description: 'Gota que nunca evapora, deixada por criaturas de Água. Usada na forja.',
    },
    essence_ice: {
        id: 'essence_ice', name: 'Cristal de Gelo', type: 'material', rarity: 'uncommon',
        element: 'ice', value: 30, icon: 'item_essence_ice',
        description: 'Cristal que nunca derrete, deixado por criaturas de Gelo. Usado na forja.',
    },
    essence_shadow: {
        id: 'essence_shadow', name: 'Névoa das Trevas', type: 'material', rarity: 'uncommon',
        element: 'shadow', value: 30, icon: 'item_essence_shadow',
        description: 'Névoa engarrafada de criaturas das Trevas. Usada na forja.',
    },
    essence_normal: {
        id: 'essence_normal', name: 'Poeira de Dados', type: 'material', rarity: 'uncommon',
        element: 'normal', value: 30, icon: 'item_essence_normal',
        description: 'Resíduo cintilante de criaturas Normais. Usado na forja.',
    },

    // ─── FERRAMENTAS DE EXPLORAÇÃO ────────────────────────────────────────────
    // Compradas nas lojas; nunca se gastam. Abrem pontos do mapa marcados com
    // montes de terra (pá) e rochas rachadas (picareta).
    shovel: {
        id: 'shovel', name: 'Pá do Escavador', type: 'tool', rarity: 'uncommon',
        value: 150, icon: 'item_shovel', sellable: false,
        description: 'Escava montes de terra revirada. A Sociedade enterrou mais do que registros.',
    },
    pickaxe: {
        id: 'pickaxe', name: 'Picareta de Ferro', type: 'tool', rarity: 'uncommon',
        value: 250, icon: 'item_pickaxe', sellable: false,
        description: 'Quebra rochas rachadas que bloqueiam passagens. Todo veio selado esconde algo.',
    },

    // ─── RECOMPENSA DO JULGAMENTO ─────────────────────────────────────────────
    // Concedido uma única vez ao vencer os 4 guardiões da Câmara da Hipótese Nula.
    ring_of_significance: {
        id: 'ring_of_significance', name: 'Anel da Significância', type: 'equipment', slot: 'relic',
        rarity: 'legendary', value: 0, sellable: false,
        passiveEffect: { type: 'first_error_forgiven', value: 0.05 },
        description: 'O primeiro erro de cada combate fica dentro da margem: sem dano e sua sequência continua.',
        flavor: 'Forjado com α = 0,05. Todo julgamento honesto tolera um erro — o seu.',
        icon: 'item_ring',
    },

    // ─── CAÇA ─────────────────────────────────────────────────────────────────
    chaos_incense: {
        id: 'chaos_incense', name: 'Incenso do Caos', type: 'consumable', rarity: 'rare',
        effect: { incense: 3 }, value: 150, icon: 'item_scroll',
        description: 'Os próximos 3 monstros que surgirem serão Elite (2× HP, 3× ouro, loot extra).',
    },
};

export const RARITY_COLORS = {
    common:    '#aaaaaa',
    uncommon:  '#44cc44',
    rare:      '#4488ff',
    epic:      '#bb44ff',
    legendary: '#ffaa22',
};
