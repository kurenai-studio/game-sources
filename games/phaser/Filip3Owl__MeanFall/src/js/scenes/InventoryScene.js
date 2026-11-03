import { CombatSystem }            from '../systems/CombatSystem.js';
import { ITEMS, RARITY_COLORS }    from '../data/items.js';
import { SaveSystem }              from '../systems/SaveSystem.js';
import EventBus                    from '../utils/EventBus.js';
import { Sound }                   from '../utils/SoundSystem.js';
import { attachRarityGlow }        from '../utils/Draw.js';

const W = 544, H = 480;
const LIST_X = 14,  LIST_W = 282;
const DET_X  = 304, DET_W  = 226;
const TABS_Y = 44,  BODY_Y = 68;
const ROW_H  = 26,  MAX_ROWS = 14;

export class InventoryScene extends Phaser.Scene {
    constructor() { super('Inventory'); }

    create() {
        this._player      = JSON.parse(JSON.stringify(this.registry.get('player')));
        this._selectedIdx = -1;
        this._filter      = 'all';
        this._scroll      = 0;
        this._rows        = [];
        this._listBg      = null;
        this._scrollUp    = null;
        this._scrollDn    = null;
        this._footerTx    = null;
        this._tabObjs     = {};   // { key: { bg, tx } }

        this._buildFrame();
        this._buildFilterTabs();
        this._buildDetailPanel();
        this._buildEquippedPanel();
        this._renderList();
        this._bindKeys();
    }

    // ── Frame ─────────────────────────────────────────────────────────────────

    _buildFrame() {
        this.add.rectangle(0, 0, W, H, 0x000000, 0.92).setOrigin(0, 0);
        this.add.rectangle(10, 10, W - 20, H - 20, 0x0d0a03, 1).setOrigin(0, 0);
        this.add.rectangle(10, 10, W - 20, H - 20, 0xd4af37, 0).setOrigin(0, 0).setStrokeStyle(1, 0xd4af37);

        this.add.text(W / 2, 22, 'I N V E N T Á R I O', {
            fontSize: '17px', color: '#ffd700', fontFamily: 'Courier New',
        }).setOrigin(0.5, 0);

        const closeBg = this.add.rectangle(504, 14, 22, 22, 0x330000, 1).setOrigin(0, 0)
            .setInteractive()
            .on('pointerover', () => closeBg.setFillStyle(0x660000))
            .on('pointerout',  () => closeBg.setFillStyle(0x330000))
            .on('pointerdown', () => this._close());
        this.add.text(515, 25, 'X', { fontSize: '15px', color: '#ff4444', fontFamily: 'Courier New' }).setOrigin(0.5, 0.5);

        // Divider between left/right panels
        this.add.rectangle(LIST_X + LIST_W + 4, BODY_Y, 2, H - BODY_Y - 28, 0xd4af37, 0.15).setOrigin(0, 0);
    }

    // ── Filter tabs ───────────────────────────────────────────────────────────

    _buildFilterTabs() {
        const tabs = [
            { label: 'Todos',   key: 'all'        },
            { label: 'Consum.', key: 'consumable' },
            { label: 'Equip.',  key: 'equipment'  },
            { label: 'Mater.',  key: 'material'   },
        ];
        const tabW = Math.floor(LIST_W / tabs.length);

        tabs.forEach(({ label, key }, i) => {
            const tx = LIST_X + i * tabW;
            const active = this._filter === key;

            const bg = this.add.rectangle(tx, TABS_Y, tabW - 2, 22, active ? 0x2a1a00 : 0x111111, 1)
                .setOrigin(0, 0)
                .setStrokeStyle(1, active ? 0xd4af37 : 0x333333)
                .setInteractive()
                .on('pointerover', () => { if (this._filter !== key) bg.setFillStyle(0x1a1100); })
                .on('pointerout',  () => { if (this._filter !== key) bg.setFillStyle(0x111111); })
                .on('pointerdown', () => this._setFilter(key));

            const txt = this.add.text(tx + tabW / 2 - 1, TABS_Y + 11, label, {
                fontSize: '12px', color: active ? '#ffd700' : '#777777', fontFamily: 'Courier New',
            }).setOrigin(0.5, 0.5);

            this._tabObjs[key] = { bg, txt };
        });
    }

    // ── Detail panel ──────────────────────────────────────────────────────────

    _buildDetailPanel() {
        this.add.rectangle(DET_X, BODY_Y, DET_W, 190, 0x080604, 1).setOrigin(0, 0);
        this.add.text(DET_X + DET_W / 2, BODY_Y + 6, 'Detalhes', {
            fontSize: '14px', color: '#d4af37', fontFamily: 'Courier New',
        }).setOrigin(0.5, 0);

        const dy = BODY_Y + 24;
        this._detName    = this.add.text(DET_X + 6, dy,       '', { fontSize: '15px', color: '#ffd700', fontFamily: 'Courier New', wordWrap: { width: DET_W - 40 } }).setOrigin(0, 0);
        this._detRarity  = this.add.text(DET_X + 6, dy + 18,  '', { fontSize: '11px', color: '#aaaaaa', fontFamily: 'Courier New' }).setOrigin(0, 0);
        this._detType    = this.add.text(DET_X + 90, dy + 18, '', { fontSize: '11px', color: '#666666', fontFamily: 'Courier New' }).setOrigin(0, 0);
        this._detDesc    = this.add.text(DET_X + 6, dy + 33,  '', { fontSize: '13px', color: '#cccccc', fontFamily: 'Courier New', wordWrap: { width: DET_W - 12 }, lineSpacing: 2 }).setOrigin(0, 0);
        this._detBonuses = this.add.text(DET_X + 6, dy + 72,  '', { fontSize: '13px', color: '#88ff88', fontFamily: 'Courier New', wordWrap: { width: DET_W - 12 }, lineSpacing: 2 }).setOrigin(0, 0);
        this._detCompare = this.add.text(DET_X + 6, dy + 112, '', { fontSize: '12px', color: '#88aaff', fontFamily: 'Courier New', wordWrap: { width: DET_W - 12 }, lineSpacing: 2 }).setOrigin(0, 0);
        this._detIcon    = this.add.image(DET_X + DET_W - 18, BODY_Y + 30, '').setScale(2.2).setVisible(false).setAlpha(0.65).setDepth(1);
        this._detGlow    = null; // recriado por raridade em _showDetail

        // Action buttons
        const btnY = BODY_Y + 196;
        this._useBg = this.add.rectangle(DET_X, btnY, 108, 26, 0x1a3a1a, 1).setOrigin(0, 0).setInteractive()
            .on('pointerover', () => this._useBg.setFillStyle(0x2a5a2a))
            .on('pointerout',  () => this._useBg.setFillStyle(0x1a3a1a))
            .on('pointerdown', () => this._useSelected())
            .setVisible(false);
        this._useTx = this.add.text(DET_X + 54, btnY + 13, '[ USAR ]', {
            fontSize: '14px', color: '#88ff88', fontFamily: 'Courier New',
        }).setOrigin(0.5, 0.5).setVisible(false);

        this._eqBg = this.add.rectangle(DET_X + 114, btnY, 112, 26, 0x1a1a3a, 1).setOrigin(0, 0).setInteractive()
            .on('pointerover', () => this._eqBg.setFillStyle(0x2a2a5a))
            .on('pointerout',  () => this._eqBg.setFillStyle(0x1a1a3a))
            .on('pointerdown', () => this._equipSelected())
            .setVisible(false);
        this._eqTx = this.add.text(DET_X + 170, btnY + 13, '[ EQUIPAR ]', {
            fontSize: '14px', color: '#8888ff', fontFamily: 'Courier New',
        }).setOrigin(0.5, 0.5).setVisible(false);

        this._actionMsg = this.add.text(DET_X + DET_W / 2, btnY + 34, '', {
            fontSize: '13px', fontFamily: 'Courier New', align: 'center', wordWrap: { width: DET_W - 10 },
        }).setOrigin(0.5, 0);
    }

    // ── Equipped panel ────────────────────────────────────────────────────────

    _buildEquippedPanel() {
        const py = BODY_Y + 260;
        this.add.rectangle(DET_X, py, DET_W, 210, 0x080604, 1).setOrigin(0, 0);
        this.add.text(DET_X + DET_W / 2, py + 6, 'Equipado', {
            fontSize: '14px', color: '#d4af37', fontFamily: 'Courier New',
        }).setOrigin(0.5, 0);
        this._slotRows = {};
        this._renderEquipped();
    }

    // ── List rendering ────────────────────────────────────────────────────────

    _filteredInventory() {
        const inv = this._player.inventory || [];
        if (this._filter === 'all') return inv;
        return inv.filter(({ itemId }) => (ITEMS[itemId]?.type || '') === this._filter);
    }

    _renderList() {
        this._rows.forEach(r => {
            r.glow?.destroyGlow();
            [r.bg, r.tx, r.qty, r.icon].forEach(o => o?.destroy());
        });
        this._rows = [];
        this._listBg?.destroy();
        this._scrollUp?.destroy(); this._scrollUp = null;
        this._scrollDn?.destroy(); this._scrollDn = null;
        this._footerTx?.destroy(); this._footerTx = null;

        this._listBg = this.add.rectangle(LIST_X, BODY_Y, LIST_W, H - BODY_Y - 28, 0x080604, 1).setOrigin(0, 0);

        const filtered = this._filteredInventory();
        const maxScroll = Math.max(0, filtered.length - MAX_ROWS);
        this._scroll = Math.max(0, Math.min(this._scroll, maxScroll));

        if (filtered.length === 0) {
            const msg = this._filter === 'all' ? 'Inventário vazio' : 'Sem itens nesta categoria';
            this.add.text(LIST_X + LIST_W / 2, BODY_Y + (H - BODY_Y) / 2 - 20, msg, {
                fontSize: '14px', color: '#444444', fontFamily: 'Courier New',
            }).setOrigin(0.5, 0.5);
        } else {
            // Scroll arrows
            if (this._scroll > 0) {
                this._scrollUp = this.add.text(LIST_X + LIST_W - 12, BODY_Y + 4, '▲', {
                    fontSize: '12px', color: '#888888', fontFamily: 'Courier New',
                }).setOrigin(0.5, 0).setInteractive()
                    .on('pointerdown', () => { this._scroll--; this._renderList(); this._restoreDetail(); });
            }
            if (this._scroll < maxScroll) {
                this._scrollDn = this.add.text(LIST_X + LIST_W - 12, BODY_Y + MAX_ROWS * ROW_H - 4, '▼', {
                    fontSize: '12px', color: '#888888', fontFamily: 'Courier New',
                }).setOrigin(0.5, 1).setInteractive()
                    .on('pointerdown', () => { this._scroll++; this._renderList(); this._restoreDetail(); });
            }

            const visible = filtered.slice(this._scroll, this._scroll + MAX_ROWS);
            visible.forEach((invItem, visIdx) => {
                const filtIdx = this._scroll + visIdx;
                const { itemId, qty } = invItem;
                const item = ITEMS[itemId];
                if (!item) return;

                const isEq   = Object.values(this._player.equipment || {}).includes(itemId);
                const isSel  = this._selectedIdx === filtIdx;
                const color  = RARITY_COLORS[item.rarity] || '#cccccc';
                const y      = BODY_Y + visIdx * ROW_H;
                const fillBg = isSel ? 0x1a1a33 : 0x111111;

                const bg = this.add.rectangle(LIST_X, y, LIST_W, ROW_H, fillBg, 1)
                    .setOrigin(0, 0).setInteractive()
                    .on('pointerover', () => {
                        if (!isSel) bg.setFillStyle(0x1a1100);
                        Sound.hover();
                        this._showDetail(filtIdx, false);
                    })
                    .on('pointerout', () => {
                        if (this._selectedIdx !== filtIdx) bg.setFillStyle(0x111111);
                        this._restoreDetail();
                    })
                    .on('pointerdown', () => { Sound.select(); this._selectItem(filtIdx); });

                const glow = attachRarityGlow(this, LIST_X + 14, y + ROW_H / 2, 10, item.rarity);
                const icon = this.add.image(LIST_X + 14, y + ROW_H / 2, item.icon || 'item_potion_red')
                    .setScale(0.65).setOrigin(0.5, 0.5).setDepth(1);

                const upLvl = this._player.upgrades?.[itemId] || 0;
                const tx = this.add.text(LIST_X + 27, y + ROW_H / 2, item.name + (upLvl ? ` +${upLvl}` : ''), {
                    fontSize: '14px', color, fontFamily: 'Courier New',
                }).setOrigin(0, 0.5);

                const qtyLabel = isEq ? '[E]' : (qty > 1 ? `×${qty}` : '');
                const qty2 = this.add.text(LIST_X + LIST_W - 5, y + ROW_H / 2, qtyLabel, {
                    fontSize: '13px', color: isEq ? '#8888ff' : '#666666', fontFamily: 'Courier New',
                }).setOrigin(1, 0.5);

                this._rows.push({ bg, tx, qty: qty2, icon, glow, filtIdx });
            });
        }

        // Footer hint — centered on left panel to avoid overlap with relic slot
        this._footerTx = this.add.text(LIST_X + LIST_W / 2, H - 10, '↑↓  Enter: ação  ·  I/ESC: fechar', {
            fontSize: '12px', color: '#444444', fontFamily: 'Courier New',
        }).setOrigin(0.5, 1);
    }

    _renderEquipped() {
        Object.values(this._slotRows).forEach(r => r.forEach(o => o?.destroy()));
        this._slotRows = {};

        const SLOTS = [
            ['head',      'Cabeça'], ['chest',     'Peito'],
            ['legs',      'Pernas'], ['feet',      'Pés'],
            ['leftHand',  'M.Esq'],  ['rightHand', 'M.Dir'],
            ['ring',      'Anel'],   ['amulet',    'Amul'],
        ];
        const py = BODY_Y + 280;
        const SH = 24; // slot height
        const SP = 24; // slot spacing

        SLOTS.forEach(([slot, label], i) => {
            const col = i % 2, row = Math.floor(i / 2);
            const x   = DET_X + col * 113;
            const y   = py + row * SP;

            const itemId    = this._player.equipment?.[slot];
            const item      = itemId ? ITEMS[itemId] : null;
            const shortName = item ? (item.name.length > 9 ? item.name.slice(0, 9) + '…' : item.name) : '—';
            const color     = item ? (RARITY_COLORS[item.rarity] || '#aaaaff') : '#2a2a2a';
            const fillBg    = itemId ? 0x1a1a2a : 0x0a0a0a;

            const bg = this.add.rectangle(x, y, 111, SH, fillBg, 1).setOrigin(0, 0)
                .setStrokeStyle(1, itemId ? 0x334466 : 0x181818);
            if (itemId) {
                bg.setInteractive()
                    .on('pointerover', () => bg.setFillStyle(0x331111))
                    .on('pointerout',  () => bg.setFillStyle(fillBg))
                    .on('pointerdown', () => this._unequip(slot));
            }
            const lblTxt  = this.add.text(x + 4, y + 2,  label,     { fontSize: '10px', color: '#555555', fontFamily: 'Courier New' }).setOrigin(0, 0);
            const itemTxt = this.add.text(x + 4, y + 12, shortName, { fontSize: '11px', color,             fontFamily: 'Courier New' }).setOrigin(0, 0);
            this._slotRows[slot] = [bg, lblTxt, itemTxt];
        });

        // ── Relic slot (full width, gold-bordered) ────────────────────────────
        const relicY   = py + 4 * SP + 4;
        const relicId  = this._player.equipment?.relic;
        const relicItem = relicId ? ITEMS[relicId] : null;
        // Curto o bastante para uma linha (largura útil ≈ 148px a 11px)
        const relicName = relicItem ? relicItem.name : '—  Nenhuma';
        const relicColor = relicItem ? (RARITY_COLORS[relicItem.rarity] || '#ffaa22') : '#333333';
        const relicFill  = relicId ? 0x1a1200 : 0x0a0a0a;
        const relicStroke = relicId ? 0xaa8800 : 0x222222;

        const relicBg = this.add.rectangle(DET_X, relicY, DET_W - 2, SH + 4, relicFill, 1).setOrigin(0, 0)
            .setStrokeStyle(1, relicStroke);
        if (relicId) {
            relicBg.setInteractive()
                .on('pointerover', () => relicBg.setFillStyle(0x332200))
                .on('pointerout',  () => relicBg.setFillStyle(relicFill))
                .on('pointerdown', () => this._unequip('relic'));
        }
        const relicLbl  = this.add.text(DET_X + 4,  relicY + 2,  'Relíquia',  { fontSize: '10px', color: relicId ? '#cc9900' : '#444444', fontFamily: 'Courier New' }).setOrigin(0, 0);
        const relicTxt  = this.add.text(DET_X + 70, relicY + 2,  relicName,   { fontSize: '11px', color: relicColor, fontFamily: 'Courier New', wordWrap: { width: DET_W - 78 } }).setOrigin(0, 0);
        this._slotRows['relic'] = [relicBg, relicLbl, relicTxt];
    }

    // ── Detail display ────────────────────────────────────────────────────────

    _showDetail(filtIdx, isSelected) {
        const filtered = this._filteredInventory();
        const invItem  = filtered[filtIdx];
        if (!invItem) { this._clearDetail(); return; }

        const { itemId } = invItem;
        const item = ITEMS[itemId];
        if (!item) return;

        const rarityColor = RARITY_COLORS[item.rarity] || '#aaaaaa';
        const upgradeLvl  = this._player.upgrades?.[itemId] || 0;
        this._detName.setText(item.name + (upgradeLvl ? ` +${upgradeLvl}` : '')).setColor(rarityColor);
        this._detRarity.setText((item.rarity || 'common').toUpperCase()).setColor(rarityColor);
        this._detType.setText(
            item.type === 'consumable' ? 'Consumível'
            : item.type === 'material' ? 'Material de forja'
            : item.type === 'tool' ? 'Ferramenta de exploração'
            : `Equip · ${item.slot || ''}`
        ).setColor('#666666');
        this._detDesc.setText(item.description || '');
        this._detIcon.setTexture(item.icon || 'item_potion_red').setVisible(true);
        this._detGlow?.destroyGlow();
        this._detGlow = attachRarityGlow(this, this._detIcon.x, this._detIcon.y, 30, item.rarity);

        // Bonuses
        if (item.bonuses && Object.keys(item.bonuses).length > 0) {
            const labels = { strength: 'FOR', intelligence: 'INT', agility: 'AGI', vitality: 'VIT', maxHp: 'HP máx', maxFocus: 'Foco máx' };
            const lines = Object.entries(item.bonuses).map(([k, v]) => `+${v} ${labels[k] || k}`);
            this._detBonuses.setText(lines.join('   '));
        } else {
            this._detBonuses.setText('');
        }

        // Stat comparison
        if (item.type === 'equipment' && item.slot) {
            const currentId = this._player.equipment?.[item.slot];
            if (!currentId) {
                this._detCompare.setText('Slot livre').setColor('#88ff88');
            } else if (currentId === itemId) {
                this._detCompare.setText('Já equipado').setColor('#888888');
            } else {
                const cur    = ITEMS[currentId];
                const labels = { strength: 'FOR', intelligence: 'INT', agility: 'AGI', vitality: 'VIT', maxHp: 'HP', maxFocus: 'Foco' };
                const newB   = item.bonuses || {}, curB = cur?.bonuses || {};
                const allKeys = new Set([...Object.keys(newB), ...Object.keys(curB)]);
                const diffs = [];
                allKeys.forEach(k => {
                    const d = (newB[k] || 0) - (curB[k] || 0);
                    if (d !== 0) diffs.push((d > 0 ? '+' : '') + d + ' ' + (labels[k] || k));
                });
                const hasGain = diffs.some(d => d.startsWith('+'));
                if (diffs.length) {
                    this._detCompare.setText(`vs ${cur.name.slice(0, 11)}:\n${diffs.join('   ')}`).setColor(hasGain ? '#88ccff' : '#ff8866');
                } else {
                    this._detCompare.setText(`Similar a ${cur.name.slice(0, 11)}`).setColor('#888888');
                }
            }
        } else {
            this._detCompare.setText('');
        }

        // Action buttons — only when truly selected (clicked)
        const sel = isSelected !== false && this._selectedIdx === filtIdx;
        const isConsumable = item.type === 'consumable';
        const isEquippable = item.type === 'equipment' && this._player.equipment?.[item.slot] !== itemId;
        this._useBg.setVisible(sel && isConsumable); this._useTx.setVisible(sel && isConsumable);
        this._eqBg.setVisible(sel && isEquippable);  this._eqTx.setVisible(sel && isEquippable);
    }

    _restoreDetail() {
        if (this._selectedIdx >= 0) this._showDetail(this._selectedIdx, true);
        else this._clearDetail();
    }

    _clearDetail() {
        this._detName.setText('');
        this._detRarity.setText('');
        this._detType.setText('');
        this._detDesc.setText('');
        this._detBonuses.setText('');
        this._detCompare.setText('');
        this._detIcon.setVisible(false);
        this._detGlow?.destroyGlow();
        this._detGlow = null;
        this._useBg.setVisible(false); this._useTx.setVisible(false);
        this._eqBg.setVisible(false);  this._eqTx.setVisible(false);
        this._actionMsg.setText('');
    }

    // ── Selection & navigation ────────────────────────────────────────────────

    _selectItem(filtIdx) {
        const prev = this._selectedIdx;
        if (prev >= 0) {
            const prevRow = this._rows.find(r => r.filtIdx === prev);
            if (prevRow?.bg?.setFillStyle) prevRow.bg.setFillStyle(0x111111);
        }

        if (prev === filtIdx) {
            // Toggle off
            this._selectedIdx = -1;
            this._clearDetail();
            return;
        }

        this._selectedIdx = filtIdx;
        const row = this._rows.find(r => r.filtIdx === filtIdx);
        if (row?.bg?.setFillStyle) row.bg.setFillStyle(0x1a1a33);
        this._showDetail(filtIdx, true);
    }

    _moveSelection(delta) {
        const filtered = this._filteredInventory();
        if (!filtered.length) return;
        const cur  = this._selectedIdx < 0 ? (delta > 0 ? -1 : filtered.length) : this._selectedIdx;
        const next = Math.max(0, Math.min(filtered.length - 1, cur + delta));
        if (next === this._selectedIdx) return;

        if (next < this._scroll) this._scroll = next;
        else if (next >= this._scroll + MAX_ROWS) this._scroll = next - MAX_ROWS + 1;

        this._selectedIdx = next;
        this._renderList();
        this._showDetail(next, true);
    }

    _actionSelected() {
        if (this._selectedIdx < 0) return;
        const filtered = this._filteredInventory();
        const invItem  = filtered[this._selectedIdx];
        if (!invItem) return;
        const item = ITEMS[invItem.itemId];
        if (!item) return;
        if (item.type === 'consumable') this._useSelected();
        else if (item.type === 'equipment') this._equipSelected();
    }

    _setFilter(key) {
        this._filter      = key;
        this._selectedIdx = -1;
        this._scroll      = 0;
        this._clearDetail();

        Object.entries(this._tabObjs).forEach(([k, { bg, txt }]) => {
            const active = k === key;
            bg.setFillStyle(active ? 0x2a1a00 : 0x111111);
            bg.setStrokeStyle(1, active ? 0xd4af37 : 0x333333);
            txt.setColor(active ? '#ffd700' : '#777777');
        });
        this._renderList();
    }

    // ── Actions ───────────────────────────────────────────────────────────────

    _useSelected() {
        if (this._selectedIdx < 0) return;
        const filtered = this._filteredInventory();
        const invItem  = filtered[this._selectedIdx];
        if (!invItem) return;

        const ok = CombatSystem.useItem(this._player, invItem.itemId, ITEMS);
        if (ok) {
            Sound.useItem();
            this._flash('#88ff88', 'Item usado!');
            if (ITEMS[invItem.itemId]?.effect?.incense) {
                EventBus.emit('chat', {
                    msg: `{{accent:Incenso do Caos}} aceso — os próximos ${this._player.incenseCharges} monstros serão {{level:Elite}}!`,
                    type: 'system',
                });
            }
            EventBus.emit('player-hp-change', { player: this._player });
            this.registry.set('player', this._player);
            SaveSystem.autoSave(this._player);
            this._selectedIdx = -1;
            this._clearDetail();
            this._renderList();
        } else {
            this._flash('#ff4444', 'Não foi possível usar.');
        }
    }

    _equipSelected() {
        if (this._selectedIdx < 0) return;
        const filtered = this._filteredInventory();
        const invItem  = filtered[this._selectedIdx];
        if (!invItem) return;

        const prevIdx  = this._selectedIdx;
        const ok = CombatSystem.equipItem(this._player, invItem.itemId, ITEMS);
        if (ok) {
            Sound.equip();
            this._flash('#8888ff', 'Equipado!');
            EventBus.emit('player-stats-changed', { player: this._player });
            EventBus.emit('player-hp-change',     { player: this._player });
            this.registry.set('player', this._player);
            SaveSystem.autoSave(this._player);
            this._renderEquipped();
            this._renderList();
            // Keep selection if item is still in filtered list
            const newFiltered = this._filteredInventory();
            this._selectedIdx = Math.min(prevIdx, newFiltered.length - 1);
            if (this._selectedIdx >= 0) this._showDetail(this._selectedIdx, true);
        } else {
            this._flash('#ff4444', 'Não foi possível equipar.');
        }
    }

    _unequip(slot) {
        const ok = CombatSystem.unequipItem(this._player, slot, ITEMS);
        if (ok) {
            Sound.unequip();
            this._flash('#ffaa44', 'Item desequipado.');
            EventBus.emit('player-stats-changed', { player: this._player });
            EventBus.emit('player-hp-change',     { player: this._player });
            this.registry.set('player', this._player);
            SaveSystem.autoSave(this._player);
            this._renderEquipped();
            this._renderList();
        }
    }

    _flash(color, msg) {
        this._actionMsg.setAlpha(1).setColor(color).setText(msg);
        this.tweens.killTweensOf(this._actionMsg);
        this.tweens.add({
            targets: this._actionMsg, alpha: 0, duration: 900, delay: 900,
            onComplete: () => this._actionMsg.setAlpha(1).setText(''),
        });
    }

    // ── Keys & scroll ─────────────────────────────────────────────────────────

    _bindKeys() {
        const close = () => this._close();
        this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ESC).on('down', close);
        this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.I).on('down', close);
        this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.UP).on('down', () => this._moveSelection(-1));
        this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.DOWN).on('down', () => this._moveSelection(1));
        this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ENTER).on('down', () => this._actionSelected());

        this.input.on('wheel', (_p, _o, _dx, dy) => {
            const maxScroll = Math.max(0, this._filteredInventory().length - MAX_ROWS);
            this._scroll = Math.max(0, Math.min(this._scroll + (dy > 0 ? 1 : -1), maxScroll));
            this._renderList();
            this._restoreDetail();
        });
    }

    // ── Close ─────────────────────────────────────────────────────────────────

    _close() {
        this.registry.set('player', this._player);
        SaveSystem.autoSave(this._player);
        this.scene.stop('Inventory');
        const world = this.scene.get('World');
        if (world?.resumeFromOverlay) world.resumeFromOverlay();
    }
}
