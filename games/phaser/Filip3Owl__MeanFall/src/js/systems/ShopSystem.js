import { ITEMS } from '../data/items.js';
import { SHOPS, SELL_RATIO } from '../data/shops.js';
import { DIFFICULTIES } from '../constants.js';
import { CombatSystem } from './CombatSystem.js';
import EventBus from '../utils/EventBus.js';

export const ShopSystem = {

    shopForNPC(npcId) {
        return Object.values(SHOPS).find(s => s.npcId === npcId) || null;
    },

    buyPrice(itemId) {
        const item = ITEMS[itemId];
        return item ? Math.floor(item.value || 0) : 0;
    },

    sellPrice(itemId, player = null) {
        const item = ITEMS[itemId];
        const diffDef = player ? (DIFFICULTIES[player.difficulty] || DIFFICULTIES.medium) : DIFFICULTIES.medium;
        const diffMult = diffDef.rewardMult;
        return item ? Math.floor((item.value || 0) * SELL_RATIO * diffMult) : 0;
    },

    buy(player, itemId) {
        const price = this.buyPrice(itemId);
        if (!price) return { ok: false, reason: 'Item inválido' };
        if ((player.gold || 0) < price) return { ok: false, reason: 'Ouro insuficiente' };
        if (!CombatSystem.addToInventory(player, itemId)) return { ok: false, reason: 'Inventário cheio' };
        player.gold -= price;
        EventBus.emit('shop-buy', { player, itemId, price });
        return { ok: true, price };
    },

    sell(player, itemId) {
        const slot = (player.inventory || []).find(s => s.itemId === itemId);
        if (!slot || slot.qty <= 0) return { ok: false, reason: 'Sem estoque' };
        // can't sell equipped
        if (Object.values(player.equipment || {}).includes(itemId) && slot.qty <= 1) {
            return { ok: false, reason: 'Item equipado' };
        }
        const price = this.sellPrice(itemId, player);
        slot.qty--;
        if (slot.qty <= 0) player.inventory = player.inventory.filter(s => s.itemId !== itemId);
        player.gold = (player.gold || 0) + price;
        EventBus.emit('shop-sell', { player, itemId, price });
        return { ok: true, price };
    },
};
