import { QuestSystem } from '../systems/QuestSystem.js';
import { BountySystem } from '../systems/BountySystem.js';
import { QUESTS, questProgress, questTarget } from '../data/quests.js';
import { ITEMS, RARITY_COLORS } from '../data/items.js';
import EventBus from '../utils/EventBus.js';

const W = 544, H = 480;
const PX = 12, PY = 10;
const PW = W - PX * 2;          // 520
const PH = H - PY * 2;          // 460
const HEADER_H = 46;
const TAB_H    = 30;
const FOOTER_H = 26;
const SCROLL_Y = PY + HEADER_H + TAB_H;        // 86
const SCROLL_H = PH - HEADER_H - TAB_H - FOOTER_H; // 358

const CX = PX + 10;             // card left x  (22)
const CW = PW - 22;             // card width   (498)

const SC = {
    complete: { hex: '#44ff88', int: 0x44ff88, bg: 0x051410 },
    active:   { hex: '#ffaa44', int: 0xffaa44, bg: 0x140e04 },
    claimed:  { hex: '#363646', int: 0x363646, bg: 0x080810 },
    default:  { hex: '#8899cc', int: 0x8899cc, bg: 0x080a16 },
};

const AREA_LABELS = {
    village: 'Aldeia', meadows: 'Prados', forest: 'Floresta',
    plains: 'Planícies', mountains: 'Montanhas', dungeon: 'Masmorra',
};

export class QuestScene extends Phaser.Scene {
    constructor() { super('Quest'); }

    create() {
        this._player   = this.registry.get('player');
        this._tab      = 'bounties';
        this._scrollY  = 0;
        this._totalH   = 0;
        this._closing  = false;

        QuestSystem.init(this._player);
        QuestSystem.refresh(this._player);
        BountySystem.init(this._player);

        this._drawBackground();
        this._drawChrome();
        this._buildScrollArea();
        this._buildTabs();
        this._render();
        this._setupInput();

        this.cameras.main.fadeIn(200, 0, 0, 0);
    }

    // ── Background ────────────────────────────────────────────────────────────

    _drawBackground() {
        this.add.rectangle(0, 0, W, H, 0x000000, 0.9).setOrigin(0);

        const g = this.add.graphics();

        // Panel gradient fill
        g.fillGradientStyle(0x0e0c1e, 0x0e0c1e, 0x07050f, 0x07050f, 1);
        g.fillRect(PX, PY, PW, PH);

        // Gold outer border
        g.lineStyle(1, 0xd4af37, 0.8);
        g.strokeRect(PX, PY, PW, PH);

        // Inner accent border
        g.lineStyle(1, 0x2a2644, 0.6);
        g.strokeRect(PX + 2, PY + 2, PW - 4, PH - 4);

        // Corner ornaments (L-shaped gold lines)
        g.lineStyle(2, 0xd4af37, 1);
        for (const [cx, cy] of [[PX, PY], [PX + PW, PY], [PX, PY + PH], [PX + PW, PY + PH]]) {
            const sx = cx === PX ? 1 : -1;
            const sy = cy === PY ? 1 : -1;
            g.beginPath();
            g.moveTo(cx + sx * 16, cy);
            g.lineTo(cx, cy);
            g.lineTo(cx, cy + sy * 16);
            g.strokePath();
        }

        // Divider below header
        g.lineStyle(1, 0x2a2644, 0.9);
        g.lineBetween(PX + 16, PY + HEADER_H, PX + PW - 16, PY + HEADER_H);

        // Divider above footer
        g.lineStyle(1, 0x1e1c30, 0.7);
        g.lineBetween(PX + 16, PY + PH - FOOTER_H, PX + PW - 16, PY + PH - FOOTER_H);
    }

    // ── Static chrome ─────────────────────────────────────────────────────────

    _drawChrome() {
        const midX = W / 2;

        // Decorative lines flanking title
        const g = this.add.graphics();
        g.lineStyle(1, 0xd4af37, 0.3);
        g.lineBetween(PX + 18, PY + 13, midX - 108, PY + 13);
        g.lineBetween(midX + 108, PY + 13, PX + PW - 18, PY + 13);

        // Title
        this.add.text(midX, PY + 7, 'DIÁRIO DE MISSÕES', {
            fontSize: '14px', color: '#f5c842', fontFamily: 'Courier New',
            fontStyle: 'bold', letterSpacing: 3,
        }).setOrigin(0.5, 0);

        // Subtitle
        this.add.text(midX, PY + 24, 'OBJETIVOS  ·  BÔNUS  ·  RECOMPENSAS', {
            fontSize: '8px', color: '#584e2e', fontFamily: 'Courier New', letterSpacing: 2,
        }).setOrigin(0.5, 0);

        // Close button
        const closeBg = this.add.rectangle(PX + PW - 15, PY + 16, 24, 24, 0x150808, 1)
            .setOrigin(0.5).setInteractive().setStrokeStyle(1, 0x502020, 0.9);
        const closeTx = this.add.text(PX + PW - 15, PY + 16, 'X', {
            fontSize: '12px', color: '#774444', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5);
        closeBg
            .on('pointerover', () => { closeBg.setFillStyle(0x380808); closeTx.setColor('#ff5555'); })
            .on('pointerout',  () => { closeBg.setFillStyle(0x150808); closeTx.setColor('#774444'); })
            .on('pointerdown', () => this._close());

        // Footer hint
        this.add.text(midX, PY + PH - FOOTER_H + 8, 'Q  ESC  fechar        RODA / SETAS  rolar', {
            fontSize: '9px', color: '#2a2848', fontFamily: 'Courier New', letterSpacing: 1,
        }).setOrigin(0.5, 0);
    }

    // ── Scroll area ───────────────────────────────────────────────────────────

    _buildScrollArea() {
        this._scrollCt = this.add.container(0, SCROLL_Y);

        const maskGfx = this.make.graphics({ add: false });
        maskGfx.fillStyle(0xffffff);
        maskGfx.fillRect(PX + 1, SCROLL_Y, PW - 2, SCROLL_H);
        this._scrollCt.setMask(maskGfx.createGeometryMask());

        // Scrollbar track
        this._sbTrack = this.add.rectangle(PX + PW - 8, SCROLL_Y + 2, 4, SCROLL_H - 4, 0x16142a, 1).setOrigin(0).setAlpha(0);
        // Scrollbar thumb
        this._sbThumb = this.add.rectangle(PX + PW - 8, SCROLL_Y + 2, 4, 40, 0x4a4370, 1).setOrigin(0).setAlpha(0);
    }

    _updateScrollbar() {
        const vis = SCROLL_H;
        const tot = this._totalH;
        if (tot <= vis) { this._sbTrack.setAlpha(0); this._sbThumb.setAlpha(0); return; }
        this._sbTrack.setAlpha(0.7);
        this._sbThumb.setAlpha(0.9);
        const ratio  = vis / tot;
        const trackH = SCROLL_H - 4;
        const thumbH = Math.max(20, Math.floor(trackH * ratio));
        const maxOff = trackH - thumbH;
        const thumbY = SCROLL_Y + 2 + Math.floor((Math.abs(this._scrollY) / (tot - vis)) * maxOff);
        this._sbThumb.setPosition(this._sbThumb.x, thumbY);
        this._sbThumb.setSize(4, thumbH);
    }

    // ── Tabs ──────────────────────────────────────────────────────────────────

    _buildTabs() {
        const ty  = PY + HEADER_H + 1;
        const th  = TAB_H - 1;
        const tw1 = Math.floor(PW / 2) - 1;
        const tw2 = PW - tw1 - 2;

        // Tab 1 — Bounties
        this._t1Bg = this.add.rectangle(PX + 1, ty, tw1, th, 0x0e0b1c, 1)
            .setOrigin(0).setInteractive()
            .on('pointerover', () => { if (this._tab !== 'bounties') this._t1Bg.setFillStyle(0x141028); })
            .on('pointerout',  () => { if (this._tab !== 'bounties') this._t1Bg.setFillStyle(0x08060f); })
            .on('pointerdown', () => this._switchTab('bounties'));
        this._t1Tx = this.add.text(PX + 1 + tw1 * 0.42, ty + th / 2, 'BONUS DIARIOS', {
            fontSize: '11px', color: '#f5c842', fontFamily: 'Courier New',
            fontStyle: 'bold', letterSpacing: 1,
        }).setOrigin(0.5);
        this._t1Badge = this.add.text(PX + 1 + tw1 - 12, ty + th / 2, '', {
            fontSize: '10px', color: '#44ff88', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5);

        // Divider between tabs
        this.add.rectangle(PX + tw1 + 1, ty, 2, th, 0x14122a, 1).setOrigin(0);

        // Tab 2 — Quests
        this._t2Bg = this.add.rectangle(PX + tw1 + 3, ty, tw2, th, 0x08060f, 1)
            .setOrigin(0).setInteractive()
            .on('pointerover', () => { if (this._tab !== 'quests') this._t2Bg.setFillStyle(0x141028); })
            .on('pointerout',  () => { if (this._tab !== 'quests') this._t2Bg.setFillStyle(0x08060f); })
            .on('pointerdown', () => this._switchTab('quests'));
        this._t2Tx = this.add.text(PX + tw1 + 3 + tw2 * 0.42, ty + th / 2, 'MISSOES', {
            fontSize: '11px', color: '#404055', fontFamily: 'Courier New',
            fontStyle: 'bold', letterSpacing: 1,
        }).setOrigin(0.5);
        this._t2Badge = this.add.text(PX + tw1 + 3 + tw2 - 12, ty + th / 2, '', {
            fontSize: '10px', color: '#44ff88', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5);

        // Active underline indicator
        this._tabLine = this.add.rectangle(PX + 1, ty + th - 2, tw1, 2, 0xd4af37, 1).setOrigin(0);

        this._tw1 = tw1; this._tw2 = tw2;
        this._tx1 = PX + 1; this._tx2 = PX + tw1 + 3;

        this._refreshTabs();
    }

    _refreshTabs() {
        const isB = this._tab === 'bounties';
        this._t1Bg.setFillStyle(isB ? 0x0e0b1c : 0x08060f);
        this._t2Bg.setFillStyle(!isB ? 0x0e0b1c : 0x08060f);
        this._t1Tx.setColor(isB ? '#f5c842' : '#3a3850');
        this._t2Tx.setColor(!isB ? '#f5c842' : '#3a3850');
        this._tabLine.setPosition(isB ? this._tx1 : this._tx2, this._tabLine.y);
        this._tabLine.setSize(isB ? this._tw1 : this._tw2, 2);

        // Count badges (show # of COMPLETE items waiting to be collected)
        const slots  = BountySystem.getSlots(this._player);
        const readyB = slots.filter(s => s.status === 'complete').length;
        this._t1Badge.setText(readyB > 0 ? `${readyB}` : '');

        const log    = this._player.questLog || {};
        const readyQ = Object.values(log).filter(s => s === 'complete').length;
        this._t2Badge.setText(readyQ > 0 ? `${readyQ}` : '');
    }

    // ── Tab switching ─────────────────────────────────────────────────────────

    _switchTab(tab) {
        this._tab = tab;
        this._render();
    }

    // ── Render dispatcher ─────────────────────────────────────────────────────

    _render() {
        this._scrollCt.removeAll(true);
        this._scrollY = 0;
        this._scrollCt.y = SCROLL_Y;
        if (this._tab === 'bounties') this._renderBounties();
        else                          this._renderQuests();
        this._updateScrollbar();
        this._refreshTabs();
    }

    // ── Bounties ──────────────────────────────────────────────────────────────

    _renderBounties() {
        const slots = BountySystem.getSlots(this._player);
        const reset = BountySystem.timeUntilReset();
        let y = 4;

        // Renewal timer
        const timerTx = this.add.text(W / 2, y, `Renova em  ${reset}`, {
            fontSize: '11px', color: '#3a3824', fontFamily: 'Courier New', letterSpacing: 1,
        }).setOrigin(0.5, 0);
        this._scrollCt.add(timerTx);
        y += 20;

        if (!slots.length) {
            this._scrollCt.add(
                this.add.text(W / 2, 150, 'Nenhum bonus disponivel hoje.', {
                    fontSize: '14px', color: '#2e2e40', fontFamily: 'Courier New',
                }).setOrigin(0.5)
            );
            this._totalH = 300;
            return;
        }

        for (let i = 0; i < slots.length; i++) {
            y = this._bountyCard(slots[i], i, y);
        }
        this._totalH = y + 6;
    }

    _bountyCard(slot, idx, y) {
        const sc    = SC[slot.status] ?? SC.default;
        const dim   = slot.status === 'claimed';
        const hasBtn = slot.status === 'complete';
        const CARD_H = 84;

        // Background
        const bg = this.add.rectangle(CX, y, CW, CARD_H, sc.bg, 1).setOrigin(0);

        // Subtle inner gradient overlay
        const gloss = this.add.graphics();
        gloss.fillGradientStyle(0xffffff, 0xffffff, 0x000000, 0x000000, dim ? 0.01 : 0.03);
        gloss.fillRect(CX, y, CW, CARD_H / 2);

        // Border
        const border = this.add.rectangle(CX, y, CW, CARD_H, 0, 0).setOrigin(0)
            .setStrokeStyle(1, sc.int, dim ? 0.12 : 0.45);

        // Left accent strip
        const strip = this.add.rectangle(CX, y, 3, CARD_H, sc.int, dim ? 0.2 : 1).setOrigin(0);

        // Status badge pill
        const bw = 58, bh = 14;
        const badgeBg = this.add.rectangle(CX + 9, y + 10, bw, bh, sc.int, dim ? 0.07 : 0.2).setOrigin(0);
        const badgeTx = this.add.text(CX + 9 + bw / 2, y + 17, this._statusLabel(slot.status), {
            fontSize: '9px', color: sc.hex, fontFamily: 'Courier New', fontStyle: 'bold', letterSpacing: 0.5,
        }).setOrigin(0.5);

        // Title
        const titleTx = this.add.text(CX + 74, y + 17, slot.label, {
            fontSize: '13px', color: dim ? '#303040' : '#f5c842',
            fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0, 0.5);

        // Area tag (top-right)
        const areaTx = this.add.text(CX + CW - 9, y + 10, AREA_LABELS[slot.area] ?? slot.area, {
            fontSize: '10px', color: dim ? '#282838' : '#3c3860', fontFamily: 'Courier New',
        }).setOrigin(1, 0);

        // Description
        const descTx = this.add.text(CX + 9, y + 29, slot.desc, {
            fontSize: '11px', color: dim ? '#242432' : '#7a7060',
            fontFamily: 'Courier New', wordWrap: { width: CW - 20 }, maxLines: 2,
        }).setOrigin(0);

        // Progress bar
        const barW = hasBtn ? CW - 110 : CW - 18;
        const barY = y + 56;
        const pct  = slot.count > 0 ? Math.min(1, slot.progress / slot.count) : 0;
        const fillW = Math.floor(barW * pct);
        const barBg = this.add.rectangle(CX + 9, barY, barW, 5, 0x08060e, 1).setOrigin(0);
        const barFg = this.add.rectangle(CX + 9, barY, Math.max(pct > 0 ? 2 : 0, fillW), 5, sc.int, dim ? 0.2 : 0.8).setOrigin(0);
        const cntTx = this.add.text(CX + 9 + barW + 7, barY + 2, `${slot.progress}/${slot.count}`, {
            fontSize: '10px', color: dim ? '#242432' : '#555566', fontFamily: 'Courier New',
        }).setOrigin(0, 0.5);

        // Reward row
        let rewStr = `+${slot.reward.xp} XP   +${slot.reward.gold} ouro`;
        if (slot.reward.materials) rewStr += `   +${slot.reward.materials.qty}× material`;
        const rewTx = this.add.text(CX + 9, y + 70, rewStr, {
            fontSize: '11px', color: dim ? '#242432' : '#485578', fontFamily: 'Courier New',
        }).setOrigin(0);

        this._scrollCt.add([bg, gloss, border, strip, badgeBg, badgeTx, titleTx, areaTx, descTx, barBg, barFg, cntTx, rewTx]);

        if (hasBtn) this._claimBtn(CX + CW - 100, y + 50, 90, 26, () => this._doBounty(idx));

        return y + CARD_H + 8;
    }

    // ── Quests ────────────────────────────────────────────────────────────────

    _renderQuests() {
        const log   = this._player.questLog || {};
        const known = Object.entries(log)
            .map(([id, status]) => ({ id, status, quest: QUESTS[id] }))
            .filter(x => x.quest);

        if (!known.length) {
            this._scrollCt.add(
                this.add.text(W / 2, 140, 'Nenhuma missao ativa.\nConverse com NPCs para receber objetivos.', {
                    fontSize: '13px', color: '#2e2e42', fontFamily: 'Courier New', align: 'center',
                }).setOrigin(0.5)
            );
            this._totalH = 300;
            return;
        }

        const ORDER = { complete: 0, active: 1, claimed: 2 };
        known.sort((a, b) => (ORDER[a.status] ?? 3) - (ORDER[b.status] ?? 3));

        let y = 4;
        for (const entry of known) {
            y = this._questCard(entry, y);
        }
        this._totalH = y + 6;
    }

    _questCard(entry, y) {
        const sc    = SC[entry.status] ?? SC.default;
        const dim   = entry.status === 'claimed';
        const hasBtn = entry.status === 'complete';
        const q     = entry.quest;
        const cur   = questProgress(this._player, q);
        const tgt   = questTarget(q);
        const pct   = Math.min(1, cur / tgt);
        const CARD_H = 94;

        // Background + gloss
        const bg = this.add.rectangle(CX, y, CW, CARD_H, sc.bg, 1).setOrigin(0);
        const gloss = this.add.graphics();
        gloss.fillGradientStyle(0xffffff, 0xffffff, 0x000000, 0x000000, dim ? 0.01 : 0.03);
        gloss.fillRect(CX, y, CW, CARD_H / 2);

        // Border + strip
        const border = this.add.rectangle(CX, y, CW, CARD_H, 0, 0).setOrigin(0)
            .setStrokeStyle(1, sc.int, dim ? 0.1 : 0.45);
        const strip = this.add.rectangle(CX, y, 3, CARD_H, sc.int, dim ? 0.18 : 1).setOrigin(0);

        // Status badge
        const bw = 58, bh = 14;
        const badgeBg = this.add.rectangle(CX + 9, y + 10, bw, bh, sc.int, dim ? 0.06 : 0.2).setOrigin(0);
        const badgeTx = this.add.text(CX + 9 + bw / 2, y + 17, this._statusLabel(entry.status), {
            fontSize: '9px', color: sc.hex, fontFamily: 'Courier New', fontStyle: 'bold', letterSpacing: 0.5,
        }).setOrigin(0.5);

        // Quest name
        const nameTx = this.add.text(CX + 74, y + 17, q.name, {
            fontSize: '13px', color: dim ? '#303040' : '#f5c842',
            fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0, 0.5);

        // Area tag
        const areaTx = this.add.text(CX + CW - 9, y + 10, AREA_LABELS[q.area] ?? q.area, {
            fontSize: '10px', color: dim ? '#282838' : '#3c3860', fontFamily: 'Courier New',
        }).setOrigin(1, 0);

        // Description (max 2 lines)
        const descTx = this.add.text(CX + 9, y + 29, q.description, {
            fontSize: '11px', color: dim ? '#242432' : '#7a7060',
            fontFamily: 'Courier New', wordWrap: { width: CW - 20 }, maxLines: 2,
        }).setOrigin(0);

        // Progress bar
        const barW = hasBtn ? CW - 110 : CW - 18;
        const barY = y + 62;
        const fillW = Math.floor(barW * pct);
        const barBg = this.add.rectangle(CX + 9, barY, barW, 5, 0x08060e, 1).setOrigin(0);
        const barFg = this.add.rectangle(CX + 9, barY, Math.max(pct > 0 ? 2 : 0, fillW), 5, sc.int, dim ? 0.18 : 0.8).setOrigin(0);
        const cntTx = this.add.text(CX + 9 + barW + 7, barY + 2, `${cur}/${tgt}`, {
            fontSize: '10px', color: dim ? '#242432' : '#555566', fontFamily: 'Courier New',
        }).setOrigin(0, 0.5);

        // Reward row
        const r     = q.reward || {};
        const basic = [r.xp ? `+${r.xp} XP` : '', r.gold ? `+${r.gold} ouro` : ''].filter(Boolean).join('   ');
        const rewTx = this.add.text(CX + 9, y + 78, basic, {
            fontSize: '11px', color: dim ? '#242432' : '#485578', fontFamily: 'Courier New',
        }).setOrigin(0);

        this._scrollCt.add([bg, gloss, border, strip, badgeBg, badgeTx, nameTx, areaTx, descTx, barBg, barFg, cntTx, rewTx]);

        // Item rewards inline
        if (r.items?.length) {
            let ix = rewTx.x + rewTx.width + 8;
            for (const it of r.items) {
                const item = ITEMS[it.itemId];
                if (!item) continue;
                const itTx = this.add.text(ix, y + 78, (it.qty > 1 ? `x${it.qty} ` : '') + item.name, {
                    fontSize: '11px',
                    color: dim ? '#242432' : (RARITY_COLORS[item.rarity] ?? '#88aacc'),
                    fontFamily: 'Courier New',
                }).setOrigin(0);
                this._scrollCt.add(itTx);
                ix = itTx.x + itTx.width + 8;
            }
        }

        if (hasBtn) this._claimBtn(CX + CW - 100, y + 58, 90, 26, () => this._doQuest(entry.id));

        return y + CARD_H + 8;
    }

    // ── Claim button ──────────────────────────────────────────────────────────

    _claimBtn(x, y, w, h, callback) {
        const bg = this.add.rectangle(x, y, w, h, 0x041410, 1)
            .setOrigin(0).setInteractive().setStrokeStyle(1, 0x44ff88, 0.5);
        const tx = this.add.text(x + w / 2, y + h / 2, 'COLETAR', {
            fontSize: '11px', color: '#44ff88', fontFamily: 'Courier New', fontStyle: 'bold', letterSpacing: 1,
        }).setOrigin(0.5);
        bg.on('pointerover', () => { bg.setFillStyle(0x103828); tx.setColor('#88ffbb'); })
          .on('pointerout',  () => { bg.setFillStyle(0x041410); tx.setColor('#44ff88'); })
          .on('pointerdown', () => { bg.setFillStyle(0x206040); this.time.delayedCall(100, callback); });
        this._scrollCt.add([bg, tx]);
    }

    // ── Actions ───────────────────────────────────────────────────────────────

    _doBounty(idx) {
        BountySystem.claim(this._player, idx);
        this.registry.set('player', this._player);
        EventBus.emit('player-stats-changed', { player: this._player });
        EventBus.emit('player-hp-change',     { player: this._player });
        this._render();
    }

    _doQuest(questId) {
        QuestSystem.claim(this._player, questId);
        this.registry.set('player', this._player);
        EventBus.emit('player-stats-changed', { player: this._player });
        EventBus.emit('player-hp-change',     { player: this._player });
        this._render();
    }

    // ── Input / scroll ────────────────────────────────────────────────────────

    _setupInput() {
        this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ESC).on('down', () => this._close());
        this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.Q).on('down', () => this._close());
        this._upKey   = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.UP);
        this._downKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.DOWN);
        this.input.on('wheel', (_p, _o, _dx, dy) => this._doScroll(dy * 0.75));
        EventBus.on('bounty-claimed', () => {
            this._player = this.registry.get('player') || this._player;
            this._render();
        });
    }

    update() {
        if (this._upKey?.isDown)   this._doScroll(-3);
        if (this._downKey?.isDown) this._doScroll(3);
    }

    _doScroll(delta) {
        const maxScroll = Math.min(0, -(this._totalH - SCROLL_H));
        this._scrollY   = Phaser.Math.Clamp(this._scrollY - delta, maxScroll, 0);
        this._scrollCt.y = SCROLL_Y + this._scrollY;
        this._updateScrollbar();
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    _statusLabel(s) {
        return { complete: 'PRONTO', active: 'ATIVA', claimed: 'FEITA' }[s] ?? 'NOVA';
    }

    // ── Close ─────────────────────────────────────────────────────────────────

    _close() {
        if (this._closing) return;
        this._closing = true;
        EventBus.off('bounty-claimed');
        this.cameras.main.fadeOut(150, 0, 0, 0);
        this.cameras.main.once('camerafadeoutcomplete', () => {
            this.scene.stop('Quest');
            const world = this.scene.get('World');
            if (world?.resumeFromOverlay) world.resumeFromOverlay();
        });
    }
}
