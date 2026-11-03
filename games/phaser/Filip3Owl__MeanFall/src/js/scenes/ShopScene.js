import { ShopSystem }              from '../systems/ShopSystem.js';
import { CombatSystem }            from '../systems/CombatSystem.js';
import { ITEMS, RARITY_COLORS }    from '../data/items.js';
import { SHOPS }                   from '../data/shops.js';
import { UI_COLORS, RARITIES }     from '../constants.js';
import EventBus                    from '../utils/EventBus.js';
import { Sound }                   from '../utils/SoundSystem.js';
import { attachRarityGlow }        from '../utils/Draw.js';

/**
 * Modal shop UI. Launched with { shopId } in scene data.
 * Tabs: Buy | Sell. Click an item to see details, then BUY or SELL.
 */
export class ShopScene extends Phaser.Scene {
    constructor() { super('Shop'); }

    init(data) {
        this._shopId    = data.shopId;
        this._tab       = 'buy';
        this._selected  = null;
    }

    create() {
        this._player = this.registry.get('player');
        this._shop   = SHOPS[this._shopId];
        if (!this._shop) { this._close(); return; }

        this._buildUI();
        this._render();

        const close = () => this._close();
        this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ESC).on('down', close);
    }

    _buildUI() {
        const W = 544, H = 480;
        this.add.rectangle(0, 0, W, H, 0x000000, 0.92).setOrigin(0, 0);
        this.add.rectangle(10, 10, W - 20, H - 20, 0x0d0a03, 1).setOrigin(0, 0);
        this.add.rectangle(10, 10, W - 20, H - 20, 0xd4af37, 0).setOrigin(0, 0).setStrokeStyle(2, 0xd4af37);

        // Title
        this.add.text(W / 2, 20, this._shop.name.toUpperCase(), {
            fontSize: '17px', color: '#ffd700', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5, 0);
        this.add.text(W / 2, 38, this._shop.greeting, {
            fontSize: '16px', color: '#aaaaaa', fontFamily: 'Courier New', fontStyle: 'italic',
            wordWrap: { width: W - 60 },
        }).setOrigin(0.5, 0);

        // Close button
        this.add.rectangle(504, 14, 22, 22, 0x330000, 1).setOrigin(0, 0).setInteractive()
            .on('pointerdown', () => this._close());
        this.add.text(515, 25, 'X', { fontSize: '15px', color: '#ff4444', fontFamily: 'Courier New' }).setOrigin(0.5, 0.5);

        // Gold display
        this._goldTxt = this.add.text(W - 30, 60, '', { fontSize: '15px', color: '#ffcc44', fontFamily: 'Courier New', fontStyle: 'bold' }).setOrigin(1, 0);

        // Tabs — a forja é exclusiva do Ferreiro Brom
        this._buyTab  = this._makeTab(20,  78, 'COMPRAR', () => this._switchTab('buy'));
        this._sellTab = this._makeTab(124, 78, 'VENDER',  () => this._switchTab('sell'));
        this._forgeTab = this._shop.npcId === 'smith'
            ? this._makeTab(228, 78, 'FORJAR', () => this._switchTab('forge'))
            : null;

        // List + detail
        this.add.rectangle(14, 110, 280, 326, 0x080604, 1).setOrigin(0, 0);
        this.add.rectangle(302, 110, 228, 326, 0x080604, 1).setOrigin(0, 0);

        this.add.text(154, 116, 'CATÁLOGO',  { fontSize: '16px', color: '#d4af37', fontFamily: 'Courier New' }).setOrigin(0.5, 0);
        this.add.text(416, 116, 'DETALHES', { fontSize: '16px', color: '#d4af37', fontFamily: 'Courier New' }).setOrigin(0.5, 0);

        // Detail texts
        this._detName  = this.add.text(308, 134, '', { fontSize: '15px', color: '#ffd700', fontFamily: 'Courier New', wordWrap: { width: 150 } }).setOrigin(0, 0);
        this._detTier  = this.add.text(308, 154, '', { fontSize: '16px', color: '#aaaaaa', fontFamily: 'Courier New' }).setOrigin(0, 0);
        this._detType  = this.add.text(308, 168, '', { fontSize: '16px', color: '#888888', fontFamily: 'Courier New' }).setOrigin(0, 0);
        this._detDesc  = this.add.text(308, 184, '', { fontSize: '17px', color: '#cccccc', fontFamily: 'Courier New', wordWrap: { width: 216 }, lineSpacing: 3 }).setOrigin(0, 0);
        this._detPrice = this.add.text(308, 280, '', { fontSize: '15px', color: '#ffcc44', fontFamily: 'Courier New', fontStyle: 'bold' }).setOrigin(0, 0);
        this._detIcon  = this.add.image(490, 150, '').setScale(2.5).setVisible(false).setDepth(1);
        this._detGlow  = null; // recriado por raridade em _selectIdx

        this._actionBg = this.add.rectangle(308, 360, 216, 32, 0x1a3a1a, 1).setOrigin(0, 0).setInteractive()
            .on('pointerover', () => this._actionBg.setFillStyle(0x2a5a2a))
            .on('pointerout',  () => this._actionBg.setFillStyle(0x1a3a1a))
            .on('pointerdown', () => this._doAction())
            .setVisible(false);
        this._actionTx = this.add.text(416, 376, '', { fontSize: '15px', color: '#88ff88', fontFamily: 'Courier New', fontStyle: 'bold' }).setOrigin(0.5, 0.5).setVisible(false);

        this._actionMsg = this.add.text(416, 405, '', { fontSize: '16px', fontFamily: 'Courier New' }).setOrigin(0.5, 0);

        this.add.text(W / 2, 458, 'ESC para fechar', { fontSize: '15px', color: '#444444', fontFamily: 'Courier New' }).setOrigin(0.5, 0);

        this._refreshGold();
    }

    _makeTab(x, y, label, onClick) {
        const bg = this.add.rectangle(x, y, 100, 24, 0x1a1a2a, 1).setOrigin(0, 0).setInteractive()
            .on('pointerdown', onClick);
        const tx = this.add.text(x + 50, y + 12, label, { fontSize: '17px', color: '#aaaaff', fontFamily: 'Courier New' }).setOrigin(0.5, 0.5);
        return { bg, tx };
    }

    _switchTab(tab) {
        if (this._tab !== tab) Sound.click();
        this._tab = tab;
        this._selected = null;
        this._render();
        this._clearDetail();
    }

    _refreshGold() {
        this._goldTxt.setText(`Ouro: ${this._player.gold || 0}`);
    }

    // Equipment the player owns (inventory + equipped) — candidates for forging
    _forgeList() {
        const ids = new Set();
        for (const s of (this._player.inventory || [])) {
            if (s.qty > 0 && ITEMS[s.itemId]?.type === 'equipment') ids.add(s.itemId);
        }
        for (const id of Object.values(this._player.equipment || {})) {
            if (id && ITEMS[id]) ids.add(id);
        }
        return [...ids].map(itemId => ({ itemId, qty: 1 }));
    }

    _render() {
        // tab visuals
        const tabs = [['buy', this._buyTab], ['sell', this._sellTab], ['forge', this._forgeTab]];
        for (const [key, tab] of tabs) {
            if (!tab) continue;
            tab.bg.setFillStyle(this._tab === key ? 0x3a3a55 : 0x1a1a2a);
            tab.tx.setColor(this._tab === key ? '#ffffff' : '#aaaaff');
        }

        // clear old rows
        if (this._rows) this._rows.forEach(r => {
            r.glow?.destroyGlow();
            r.bg.destroy(); r.tx.destroy(); r.priceTx.destroy(); if (r.icon) r.icon.destroy();
        });
        this._rows = [];

        const list = this._tab === 'buy'
            ? this._shop.stock.map(id => ({ itemId: id, qty: 1 }))
            : this._tab === 'forge'
                ? this._forgeList()
                : (this._player.inventory || []).filter(s => s.qty > 0);

        if (list.length === 0) {
            const emptyMsg = this._tab === 'buy' ? 'Nada à venda'
                : this._tab === 'forge' ? 'Nenhum equipamento para forjar'
                : 'Você não tem itens';
            const empty = this.add.text(154, 270, emptyMsg, {
                fontSize: '17px', color: '#444444', fontFamily: 'Courier New',
            }).setOrigin(0.5, 0.5);
            this._rows.push({ bg: empty, tx: empty, priceTx: empty });
            return;
        }

        for (let i = 0; i < list.length; i++) {
            const { itemId, qty } = list[i];
            const item = ITEMS[itemId];
            if (!item) continue;
            const color = RARITY_COLORS[item.rarity] || '#cccccc';
            const y     = 134 + i * 22;

            const bg = this.add.rectangle(18, y, 272, 20, 0x111111, 1).setOrigin(0, 0).setInteractive()
                .on('pointerover', () => { if (this._selected !== i) { bg.setFillStyle(0x1a1a22); Sound.hover(); } })
                .on('pointerout',  () => { if (this._selected !== i) bg.setFillStyle(0x111111); })
                .on('pointerdown', () => { Sound.select(); this._selectIdx(i); });

            const glow = attachRarityGlow(this, 30, y + 10, 10, item.rarity);
            const icon = this.add.image(30, y + 10, item.icon || 'item_potion_red').setScale(0.65).setDepth(1);

            let nameStr, rightStr;
            if (this._tab === 'forge') {
                const lvl = CombatSystem.upgradeLevel(this._player, itemId);
                nameStr  = lvl ? `${item.name} +${lvl}` : item.name;
                rightStr = lvl >= 3 ? 'MAX' : `→ +${lvl + 1}`;
            } else {
                nameStr  = qty > 1 ? `${item.name} ×${qty}` : item.name;
                const price = this._tab === 'buy' ? ShopSystem.buyPrice(itemId) : ShopSystem.sellPrice(itemId);
                rightStr = `${price}g`;
            }

            const tx = this.add.text(44, y + 10, nameStr, {
                fontSize: '16px', color, fontFamily: 'Courier New',
            }).setOrigin(0, 0.5);

            const priceTx = this.add.text(284, y + 10, rightStr, {
                fontSize: '16px', color: this._tab === 'forge' ? '#88ccff' : '#ffcc44', fontFamily: 'Courier New',
            }).setOrigin(1, 0.5);

            this._rows.push({ bg, tx, icon, glow, priceTx, idx: i, itemId });
        }
    }

    _selectIdx(i) {
        if (this._selected !== null && this._rows[this._selected]?.bg.setFillStyle) {
            this._rows[this._selected].bg.setFillStyle(0x111111);
        }
        this._selected = i;
        if (this._rows[i]?.bg.setFillStyle) this._rows[i].bg.setFillStyle(0x1a1a33);

        const itemId = this._rows[i].itemId;
        const item   = ITEMS[itemId];
        const rColor = RARITY_COLORS[item.rarity] || '#aaaaaa';
        const rName  = (RARITIES[item.rarity] || RARITIES.common).name;

        const upLvl = CombatSystem.upgradeLevel(this._player, itemId);
        this._detName.setText(item.name + (upLvl ? ` +${upLvl}` : '')).setColor(rColor);
        this._detTier.setText(rName.toUpperCase()).setColor(rColor);
        this._detType.setText(
            item.type === 'consumable' ? 'Consumível'
            : item.type === 'material' ? 'Material de forja'
            : `Equipamento — ${item.slot}`
        );
        this._detIcon.setTexture(item.icon || 'item_potion_red').setVisible(true);
        this._detGlow?.destroyGlow();
        this._detGlow = attachRarityGlow(this, this._detIcon.x, this._detIcon.y, 34, item.rarity);

        if (this._tab === 'forge') {
            if (upLvl >= 3) {
                this._detDesc.setText('Este item já está no nível máximo de aprimoramento (+3).');
                this._detPrice.setText('');
                this._actionBg.setVisible(false);
                this._actionTx.setVisible(false);
            } else {
                const cost  = CombatSystem.upgradeCost(item, upLvl);
                const matId = `essence_${cost.element}`;
                const owned = CombatSystem.countItem(this._player, matId);
                const matName = ITEMS[matId]?.name || cost.element;
                this._detDesc.setText(
                    `Aprimorar para +${upLvl + 1}: bônus do item +${(upLvl + 1) * 25}%.\n\n` +
                    `Requer:\n· ${cost.gold} ouro\n· ${cost.qty}× ${matName} (você tem ${owned})`
                );
                this._detPrice.setText(`Forja: ${cost.gold} ouro + ${cost.qty}× ${matName}`);
                this._actionBg.setVisible(true);
                this._actionTx.setVisible(true).setText(`FORJAR +${upLvl + 1}`);
            }
            this._actionMsg.setText('');
            return;
        }

        this._detDesc.setText(item.description || '');
        const price = this._tab === 'buy' ? ShopSystem.buyPrice(itemId) : ShopSystem.sellPrice(itemId);
        this._detPrice.setText(`${this._tab === 'buy' ? 'Custa' : 'Vende por'}: ${price} ouro`);

        this._actionBg.setVisible(true);
        this._actionTx.setVisible(true).setText(this._tab === 'buy' ? 'COMPRAR' : 'VENDER');
        this._actionMsg.setText('');
    }

    _doAction() {
        if (this._selected === null) return;
        const itemId = this._rows[this._selected].itemId;

        if (this._tab === 'forge') {
            const result = CombatSystem.upgradeItem(this._player, itemId, ITEMS);
            if (result.ok) {
                Sound.equip();
                this._actionMsg.setColor('#88ff88').setText(`${ITEMS[itemId].name} agora é +${result.level}!`);
                EventBus.emit('chat', {
                    msg: `O Ferreiro forjou {{loot:${ITEMS[itemId].name} +${result.level}}}!`,
                    type: 'loot',
                });
                EventBus.emit('player-stats-changed', { player: this._player });
                EventBus.emit('player-hp-change', { player: this._player });
                this.registry.set('player', this._player);
                this._refreshGold();
                this._render();
                this._clearDetail();
            } else {
                Sound.denied();
                this._actionMsg.setColor('#ff4444').setText(result.reason || 'Erro');
            }
            return;
        }

        const result = this._tab === 'buy'
            ? ShopSystem.buy(this._player, itemId)
            : ShopSystem.sell(this._player, itemId);

        if (result.ok) {
            if (this._tab === 'buy') Sound.buy(); else Sound.sell();
            this._actionMsg.setColor('#88ff88').setText(`OK — ${this._tab === 'buy' ? '−' : '+'}${result.price} ouro`);
            EventBus.emit('player-stats-changed', { player: this._player });
            this.registry.set('player', this._player);
            this._refreshGold();
            this._render();
            this._clearDetail();
        } else {
            Sound.denied();
            this._actionMsg.setColor('#ff4444').setText(result.reason || 'Erro');
        }
    }

    _clearDetail() {
        this._selected = null;
        this._detName.setText('');
        this._detTier.setText('');
        this._detType.setText('');
        this._detDesc.setText('');
        this._detPrice.setText('');
        this._detIcon.setVisible(false);
        this._detGlow?.destroyGlow();
        this._detGlow = null;
        this._actionBg.setVisible(false);
        this._actionTx.setVisible(false);
    }

    _close() {
        this.scene.stop('Shop');
        const world = this.scene.get('World');
        if (world?.resumeFromOverlay) world.resumeFromOverlay();
    }
}
