import { ELEMENT_MATRIX, RARITIES, DIFFICULTIES, rarityRank } from '../constants.js';

export const CombatSystem = {

    // ── Damage calculation ────────────────────────────────────────────────────

    /**
     * Player damage with elemental matchup, weapon element, and rarity scaling.
     * Incorporates statistical distributions (Uniform vs Normal) from weapons.
     */
    calcPlayerDamage(player, monster, streak = 0, weaponInfo = null) {
        const base       = 10 + (player.level * 1.5);
        const intBonus   = player.intelligence * 0.5;
        const strBonus   = player.strength * 0.3;
        const streakBonus = Math.min(streak * 2, 20);
        let raw          = base + intBonus + strBonus + streakBonus;

        // Apply statistical distribution multiplier
        let distMult = 1.0;
        const dist = weaponInfo?.damageDistribution || 'normal';
        const range = weaponInfo?.damageRange || [0.8, 1.2]; // min/max multiplier

        if (dist === 'uniform') {
            distMult = range[0] + Math.random() * (range[1] - range[0]);
        } else {
            // Normal (Gauss) distribution using Box-Muller transform
            // Mean at center of range, stdDev such that 95% is within range
            const mean = (range[0] + range[1]) / 2;
            const stdDev = (range[1] - range[0]) / 4;
            distMult = this._boxMuller(mean, stdDev);
            // Clamp to absolute range
            distMult = Math.max(range[0], Math.min(range[1], distMult));
        }

        raw = Math.floor(raw * distMult);

        // Fever bonus: streak 5+ grants +40% damage
        const isFever = streak >= 5;
        if (isFever) raw = Math.floor(raw * 1.4);

        // Weapon element vs monster element
        const weaponElem = this._weaponElement(player);
        const matchup    = (ELEMENT_MATRIX[weaponElem] || {})[monster.element] ?? 1;
        raw = Math.floor(raw * matchup);

        // Elemental mastery: +2% damage per level of the weapon's element (cap +30%)
        const masteryLvl  = player.elementalMastery?.[weaponElem]?.level || 1;
        const masteryMult = 1 + Math.min(0.30, 0.02 * (masteryLvl - 1));
        raw = Math.floor(raw * masteryMult);

        // Crit (5% + 1% per agility, capped 30%)
        const critChance = Math.min(0.05 + player.agility * 0.01, 0.3);
        const isCrit = Math.random() < critChance;
        if (isCrit) raw = Math.floor(raw * 1.6);

        const damage = Math.max(1, raw - (monster.defense || 0));
        const advantage = matchup > 1.1 ? 'super' : matchup < 0.9 ? 'weak' : 'neutral';
        return {
            damage,
            multiplier: matchup,
            isCrit,
            isFever,
            advantage,
            weaponElement: weaponElem,
            distribution: dist
        };
    },

    // Standard Box-Muller for Normal Distribution
    _boxMuller(mean, stdDev) {
        let u = 0, v = 0;
        while(u === 0) u = Math.random();
        while(v === 0) v = Math.random();
        const z = Math.sqrt(-2.0 * Math.log(u)) * Math.cos(2.0 * Math.PI * v);
        return z * stdDev + mean;
    },

    calcMonsterDamage(monster, player) {
        const diffDef = DIFFICULTIES[player.difficulty] || DIFFICULTIES.medium;
        const diffMult = diffDef.monsterDamage;

        const agiRed = Math.floor(player.agility * 0.3);
        if (Math.random() < player.agility * 0.01) return { damage: 0, dodged: true };
        
        const baseDmg = monster.attackDamage || 10;
        const dmg = Math.max(1, Math.floor(baseDmg * diffMult) - agiRed);
        return { damage: dmg, dodged: false };
    },

    _weaponElement(player) {
        const eq = player.equipment || {};
        for (const slot of ['rightHand', 'leftHand', 'amulet', 'ring', 'head', 'chest']) {
            const id = eq[slot];
            if (!id) continue;
            // late-import safety: items table referenced at call site, fallback to 'normal'
        }
        // weapon element resolution happens at call sites where ITEMS is imported.
        // For static system here, just return 'normal' baseline.
        return player._weaponElement || 'normal';
    },

    // ── Loot ──────────────────────────────────────────────────────────────────

    rollDrops(monster) {
        const table = monster?.lootTable || [];
        return table
            .filter(entry => entry.guaranteed || Math.random() < (entry.chance ?? 0))
            .map(entry => entry.itemId);
    },

    // ── Inventory ─────────────────────────────────────────────────────────────

    addToInventory(player, itemId) {
        if (!player.inventory) player.inventory = [];
        if (player.inventory.length >= 32) return false;
        const existing = player.inventory.find(i => i.itemId === itemId);
        if (existing) {
            existing.qty = (existing.qty || 1) + 1;
        } else {
            player.inventory.push({ itemId, qty: 1 });
        }
        return true;
    },

    useItem(player, itemId, ITEMS) {
        const slot = player.inventory.find(i => i.itemId === itemId);
        if (!slot) return false;
        const item = ITEMS[itemId];
        if (!item || item.type !== 'consumable') return false;

        const e = item.effect || {};
        if (e.hp)    player.hp    = Math.min(player.maxHp,    player.hp    + e.hp);
        if (e.focus) player.focus = Math.min(player.maxFocus, player.focus + e.focus);
        if (e.incense) player.incenseCharges = (player.incenseCharges || 0) + e.incense;

        slot.qty--;
        if (slot.qty <= 0) player.inventory = player.inventory.filter(i => i.itemId !== itemId);
        return true;
    },

    countItem(player, itemId) {
        const slot = (player.inventory || []).find(i => i.itemId === itemId);
        return slot ? (slot.qty || 0) : 0;
    },

    removeItem(player, itemId, qty) {
        const slot = (player.inventory || []).find(i => i.itemId === itemId);
        if (!slot || slot.qty < qty) return false;
        slot.qty -= qty;
        if (slot.qty <= 0) player.inventory = player.inventory.filter(i => i.itemId !== itemId);
        return true;
    },

    // ── Forge (equipment upgrades) ────────────────────────────────────────────
    // Upgrades are per item type: player.upgrades[itemId] = 0..3.
    // Each level scales the item's passive bonuses by +25%.

    upgradeLevel(player, itemId) {
        return player.upgrades?.[itemId] || 0;
    },

    scaledBonuses(item, level) {
        if (!item?.bonuses || !level) return item?.bonuses || null;
        const out = {};
        for (const [key, val] of Object.entries(item.bonuses)) {
            out[key] = Math.round(val * (1 + 0.25 * level));
        }
        return out;
    },

    // Which elemental material this item's upgrades consume. Uses the item's
    // own element when present; otherwise a stable hash spreads demand evenly.
    forgeElement(item) {
        if (item.element) return item.element;
        const order = ['normal', 'earth', 'ice', 'fire', 'water', 'shadow'];
        let h = 0;
        for (const ch of item.id || '') h = (h + ch.charCodeAt(0)) % 997;
        return order[h % order.length];
    },

    upgradeCost(item, currentLevel) {
        const base = item.value || 400; // relics have value 0 — treat as endgame gear
        return {
            gold: Math.max(40, Math.floor(base * 0.4 * (currentLevel + 1))),
            qty:  [3, 5, 8][currentLevel] ?? 8,
            element: this.forgeElement(item),
        };
    },

    upgradeItem(player, itemId, ITEMS) {
        const item = ITEMS[itemId];
        if (!item || item.type !== 'equipment') return { ok: false, reason: 'Item inválido' };
        if (!player.upgrades) player.upgrades = {};

        const lvl = player.upgrades[itemId] || 0;
        if (lvl >= 3) return { ok: false, reason: 'Nível máximo (+3)' };

        const owned = this.countItem(player, itemId) > 0
            || Object.values(player.equipment || {}).includes(itemId);
        if (!owned) return { ok: false, reason: 'Você não possui este item' };

        const cost = this.upgradeCost(item, lvl);
        const materialId = `essence_${cost.element}`;
        if ((player.gold || 0) < cost.gold) return { ok: false, reason: 'Ouro insuficiente' };
        if (this.countItem(player, materialId) < cost.qty) {
            return { ok: false, reason: `Faltam materiais (${cost.qty}× necessários)` };
        }

        // If the item is equipped, swap its applied bonuses to the new level
        const equipped = Object.values(player.equipment || {}).includes(itemId);
        if (equipped && item.bonuses) applyBonuses(player, this.scaledBonuses(item, lvl), -1);

        player.gold -= cost.gold;
        this.removeItem(player, materialId, cost.qty);
        player.upgrades[itemId] = lvl + 1;

        if (equipped && item.bonuses) applyBonuses(player, this.scaledBonuses(item, lvl + 1), 1);
        player.hp    = Math.min(player.hp,    player.maxHp);
        player.focus = Math.min(player.focus, player.maxFocus);

        return { ok: true, level: lvl + 1, cost };
    },

    // ── Equipment ─────────────────────────────────────────────────────────────

    equipItem(player, itemId, ITEMS) {
        const item = ITEMS[itemId];
        if (!item || item.type !== 'equipment') return false;
        const slot = item.slot;
        if (!slot) return false;

        // Remove old bonuses (scaled by its upgrade level) + return old item
        const oldId = player.equipment[slot];
        if (oldId) {
            const oldItem = ITEMS[oldId];
            if (oldItem?.bonuses) {
                applyBonuses(player, this.scaledBonuses(oldItem, this.upgradeLevel(player, oldId)), -1);
            }
            this.addToInventory(player, oldId);
        }

        // Take from inventory
        const invSlot = (player.inventory || []).find(s => s.itemId === itemId);
        if (invSlot) {
            invSlot.qty--;
            if (invSlot.qty <= 0) player.inventory = player.inventory.filter(s => s.itemId !== itemId);
        }

        player.equipment[slot] = itemId;
        if (item.bonuses) applyBonuses(player, this.scaledBonuses(item, this.upgradeLevel(player, itemId)), 1);

        // Cache weapon element for quick combat lookup
        if (slot === 'rightHand' || slot === 'leftHand') {
            player._weaponElement = item.element || 'normal';
        }
        // Cap vitals
        player.hp    = Math.min(player.hp,    player.maxHp);
        player.focus = Math.min(player.focus, player.maxFocus);
        return true;
    },

    unequipItem(player, slot, ITEMS) {
        const itemId = player.equipment[slot];
        if (!itemId) return false;
        const item = ITEMS[itemId];
        if (item?.bonuses) applyBonuses(player, this.scaledBonuses(item, this.upgradeLevel(player, itemId)), -1);
        player.equipment[slot] = null;
        if (slot === 'rightHand' || slot === 'leftHand') player._weaponElement = 'normal';
        player.hp    = Math.min(player.hp,    player.maxHp);
        player.focus = Math.min(player.focus, player.maxFocus);
        this.addToInventory(player, itemId);
        return true;
    },

    refreshWeaponElement(player, ITEMS) {
        const id = player.equipment?.rightHand || player.equipment?.leftHand;
        player._weaponElement = (id && ITEMS[id]?.element) || 'normal';
    },

    // Maior raridade entre os itens equipados — usada para a aura de brilho
    // do personagem no mundo/combate. Retorna null se nada estiver equipado.
    highestEquippedRarity(player, ITEMS) {
        let best = null;
        for (const itemId of Object.values(player.equipment || {})) {
            if (!itemId) continue;
            const r = ITEMS[itemId]?.rarity;
            if (r && (!best || rarityRank(r) > rarityRank(best))) best = r;
        }
        return best;
    },
};

function applyBonuses(player, bonuses, sign) {
    for (const [key, val] of Object.entries(bonuses)) {
        player[key] = (player[key] || 0) + sign * val;
    }
}
