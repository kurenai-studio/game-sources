// MeanFall — Shop catalog
// Each merchant lives in a specific area and offers a curated stock of items.
// Players can buy from the merchant; sell value = item.value * 0.5.

export const SHOPS = {
    village_merchant: {
        id: 'village_merchant',
        npcId: 'merchant',
        area: 'village',
        name: 'Mercador da Vila',
        greeting: 'Bem-vindo, aventureiro! Tenho o básico para sua jornada.',
        stock: [
            'health_potion',
            'focus_potion',
            'data_scroll',
            'leather_cap',
            'cloth_pants',
            'worn_boots',
            'wooden_sword',
            'wooden_shield',
            'copper_ring',
            'supreme_health_potion',
            'full_focus_elixir',
            'chaos_incense',
            'shovel',
        ],
    },

    meadows_smith: {
        id: 'meadows_smith',
        npcId: 'smith',
        area: 'meadows',
        name: 'Ferreiro dos Prados',
        greeting: 'Boa armadura faz a diferença. Vê algo que te interesse?',
        stock: [
            'health_potion',
            'greater_health_potion',
            'leather_armor',
            'chain_mail',
            'leather_greaves',
            'iron_shield',
            'iron_blade',
            'amulet_of_clarity',
            'shield_of_inference',
            'greaves_of_wind',
            'boots_of_swiftness',
            'chaos_incense',
            'shovel',
            'pickaxe',
        ],
    },

    plains_trader: {
        id: 'plains_trader',
        npcId: 'trader',
        area: 'plains',
        name: 'Comerciante Errante',
        greeting: 'Itens raros, preços justos. Decida-se rápido!',
        stock: [
            'greater_health_potion',
            'focus_potion',
            'mage_hat',
            'boots_agility',
            'iron_blade',
            'iron_shield',
            'ring_of_focus',
            'amulet_of_clarity',
            'stats_amulet',
            'sword_of_probability',
            'staff_of_distributions',
            'specialist_armor',
            'ring_of_mastery',
            'blade_of_sigma',
            'staff_of_the_oracle',
            'legendary_robe',
            'arcane_talisman',
            'chaos_incense',
        ],
    },
};

export const SELL_RATIO = 0.5;
