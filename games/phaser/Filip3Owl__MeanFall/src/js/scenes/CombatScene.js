import { CombatSystem }                from '../systems/CombatSystem.js';
import { QuestionEngine }                from '../systems/QuestionEngine.js';
import { CodeChallengeEngine }           from '../systems/CodeChallengeEngine.js';
import { PythonRuntime }                 from '../systems/PythonRuntime.js';
import { CodeEditor }                    from '../utils/CodeEditor.js';
import { awardXP, awardElementalXP }           from '../systems/XPSystem.js';
import { BookSystem }                    from '../systems/BookSystem.js';
import { ITEMS, RARITY_COLORS } from '../data/items.js';
import { BOOKS, BOOK_IMPORTANCE }        from '../data/books.js';
import { ELEMENTS, FLEE_XP_PENALTY, TOPIC_TO_ELEMENT, CODE_TOPIC_TO_ELEMENT, parentArea } from '../constants.js';
import { StatusEffectSystem, STATUS_DEFS }                  from '../systems/StatusEffectSystem.js';
import { CompanionSystem }               from '../systems/CompanionSystem.js';
import EventBus                          from '../utils/EventBus.js';
import { Sound }                         from '../utils/SoundSystem.js';
import { Music }                         from '../utils/MusicSystem.js';
import { attachRarityGlow }              from '../utils/Draw.js';

export class CombatScene extends Phaser.Scene {
    constructor() { super('Combat'); }

    init(data) {
        this._monsterDef   = data.monster;
        this._instanceId   = data.instanceId;
        this._monsterHp    = data.monster.maxHp;
        this._streak       = 0;
        this._maxStreak    = 0;
        this._wrongCount   = 0;
        this._recentIds    = [];
        this._currentQ     = null;
        this._answerLock   = false;
        this._numericValue = '';
        this._relicEffect  = null;
        this._rules        = data.rules || {};      // ex.: { noItems: true } no Julgamento
        this._gauntletInfo = data.gauntlet || null; // { index, total } quando em gauntlet
        this._alphaUsed    = false;                 // Anel da Significância: 1 perdão/combate
        this._codeReport   = null;                  // último envio de código do turno
    }

    create() {
        this._player = JSON.parse(JSON.stringify(this.registry.get('player')));
        const relicId = this._player.equipment?.relic;
        this._relicEffect = (relicId && ITEMS[relicId]?.passiveEffect) ? ITEMS[relicId].passiveEffect : null;
        this._buildUI();
        this._nextQuestion();
        Sound.combatStart();

        // ── Entrance Animation ──────────────────────────────────────────────
        this.cameras.main.fadeIn(300, 0, 0, 0);

        if (this._monsterSprite) {
            const finalScale = this._monsterDef.isBoss ? 2.6 : 2.5;
            this._monsterSprite.setScale(0).setAlpha(0);
            this.tweens.add({
                targets: this._monsterSprite,
                scale: finalScale,
                alpha: 1,
                duration: 600,
                delay: 100,
                ease: 'Back.easeOut'
            });
        }
    }

    // ─── UI CONSTRUCTION ──────────────────────────────────────────────────────

    _buildUI() {
        const W = 544, H = 480;
        const isBoss  = !!this._monsterDef.isBoss;
        const isShiny = !!this._monsterDef.isShiny;
        const isElite = isBoss || isShiny || !!this._monsterDef.isElite || this._monsterDef.name.startsWith('Elite');
        const elem     = ELEMENTS[this._monsterDef.element] || ELEMENTS.normal;
        const eColor   = isBoss ? 0xff4400 : isShiny ? 0xfff2aa : isElite ? 0xffd700 : elem.color;
        const eDark    = isBoss ? 0x1a0800 : isShiny ? 0x2a2410 : isElite ? 0x2a1a00 : elem.dark;
        const eHex     = '#' + eColor.toString(16).padStart(6, '0');
        const eAccent  = isBoss ? 0xff8844 : isShiny ? 0xfff2aa : isElite ? 0xffd700 : elem.accent;
        const eTextHex = '#' + eAccent.toString(16).padStart(6, '0');

        // ── Deep void background ─────────────────────────────────────────
        this.add.rectangle(0, 0, W, H, 0x020106, 0.97).setOrigin(0, 0);

        // Subtle ambient elemental glow at corners
        const gfx = this.add.graphics();
        gfx.fillStyle(eColor, 0.06);
        gfx.fillRect(0, 0, W / 2, H / 2);
        gfx.fillStyle(0x000000, 0.0);

        // ── Ornamental top header ────────────────────────────────────────
        this.add.rectangle(0, 0, W, 32, eDark, 1).setOrigin(0, 0);
        this.add.rectangle(0, 31, W, 1, eColor, 0.9).setOrigin(0, 0);
        this.add.rectangle(0, 32, W, 1, 0x000000, 0.6).setOrigin(0, 0);

        // Corner runes
        this.add.text(8, 6, '⟨ ⟩', { fontSize: '12px', color: eTextHex, fontFamily: 'Courier New' }).setOrigin(0, 0).setAlpha(0.7);
        this.add.text(W - 8, 6, '⟨ ⟩', { fontSize: '12px', color: eTextHex, fontFamily: 'Courier New' }).setOrigin(1, 0).setAlpha(0.7);

        const titleStr = this._gauntletInfo
            ? `⚖  JULGAMENTO ${this._gauntletInfo.index + 1}/${this._gauntletInfo.total}  ·  ${elem.topicLabel.toUpperCase()}  ⚖`
            : isBoss
            ? `☠  CHEFE DE ÁREA  ·  ${elem.topicLabel.toUpperCase()}  ☠`
            : isShiny
                ? `✦  CRIATURA CINTILANTE  ·  ${elem.topicLabel.toUpperCase()}  ✦`
                : isElite
                    ? `✦  ENCONTRO ELITE  ·  ${elem.topicLabel.toUpperCase()}  ✦`
                    : `[ ${elem.symbol} ]  COMBATE  ·  ${elem.topicLabel.toUpperCase()}`;
        this.add.text(W / 2, 16, titleStr, {
            fontSize: '13px', color: eTextHex, fontFamily: 'Courier New', fontStyle: 'bold', letterSpacing: 1,
            stroke: '#000000', strokeThickness: 2,
        }).setOrigin(0.5, 0.5);

        // ── Build panels ─────────────────────────────────────────────────
        this._buildMonsterPanel(elem, eColor, eDark, eHex, eTextHex, isElite);
        this._buildPlayerPanel(eColor, eHex, eTextHex, isElite);
        this._buildInfoOverlay(elem, eColor, eTextHex);

        // ── VS divider ───────────────────────────────────────────────────
        const vsColor = isElite ? '#ffe55a' : '#f5c842';
        this.add.text(W / 2, 92, 'VS', {
            fontSize: '18px', color: vsColor, fontFamily: 'Courier New', fontStyle: 'bold',
            stroke: '#000000', strokeThickness: 4,
        }).setOrigin(0.5, 0.5);

        // ── Horizontal divider ───────────────────────────────────────────
        const divGfx = this.add.graphics();
        divGfx.lineStyle(1, eColor, 0.35);
        divGfx.lineBetween(12, 162, W - 12, 162);
        divGfx.lineStyle(1, 0xffffff, 0.04);
        divGfx.lineBetween(12, 163, W - 12, 163);

        // ── Question zone ────────────────────────────────────────────────
        this._buildQuestionBox(eColor, eHex, eTextHex, isElite);
        this._buildBottomBar(eColor, eHex, isElite);

        // ── Juice Overlays ───────────────────────────────────────────────
        this._juiceCorrect = this.add.rectangle(0, 0, W, H, 0xffd700, 0).setOrigin(0, 0).setDepth(200);
        this._juiceWrong = this.add.rectangle(0, 0, W, H, 0x445588, 0).setOrigin(0, 0).setDepth(200);

        // ── Fever Mode Visuals ───────────────────────────────────────────
        this._feverFrame = this.add.graphics().setDepth(150);
        this._feverActive = false;

        this.input.keyboard.on('keydown', this._onKeyDown.bind(this));
    }

    _buildMonsterPanel(elem, eColor, eDark, eHex, eTextHex, isElite) {
        const PX = 8, PY = 32, PW = 258, PH = 128;

        // Background
        this.add.rectangle(PX, PY, PW, PH, eDark, 1).setOrigin(0, 0);
        this.add.rectangle(PX, PY, PW, PH, eColor, 0).setOrigin(0, 0).setStrokeStyle(1, eColor, 0.45);
        // Top accent line
        this.add.rectangle(PX, PY, PW, 2, eColor, 0.6).setOrigin(0, 0);

        // Flash overlay
        this._monsterFlashRect = this.add.rectangle(PX, PY, PW, PH, 0xff2222, 0).setOrigin(0, 0);

        // Sprite zone (left 100px)
        this._monsterPanelCenter = { x: PX + 50, y: PY + 64 };
        const texKey = `sprite_${this._monsterDef.id}`;
        if (this.textures.exists(texKey)) {
            const aura = this.add.circle(PX + 50, PY + 64, 36, eColor, 0.12).setDepth(0);
            this.tweens.add({ targets: aura, alpha: 0.28, scale: 1.15, duration: 1100, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });
            this._monsterSprite = this.add.image(PX + 50, PY + 64, texKey).setScale(2.4).setDepth(1);
        }

        // Info panel (right side)
        const ix = PX + 108;
        this.add.text(ix, PY + 8, this._monsterDef.name.toUpperCase(), {
            fontSize: '13px', color: '#f0e8d8', fontFamily: 'Courier New', fontStyle: 'bold',
            wordWrap: { width: 148 },
        }).setOrigin(0, 0);

        // Level + element badge
        const badgeBg = this.add.rectangle(ix, PY + 30, 72, 16, eColor, 0.2).setOrigin(0, 0).setStrokeStyle(1, eColor, 0.5);
        this.add.text(ix + 36, PY + 38, `${elem.symbol} · Nv.${this._monsterDef.level}`, {
            fontSize: '11px', color: eTextHex, fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5, 0.5);

        // HP label row
        this.add.text(ix, PY + 52, 'HP', { fontSize: '11px', color: '#aa9988', fontFamily: 'Courier New', fontStyle: 'bold' }).setOrigin(0, 0);
        this._mHpTxt = this.add.text(PX + PW - 6, PY + 52, '', { fontSize: '11px', color: '#ffbbaa', fontFamily: 'Courier New', fontStyle: 'bold' }).setOrigin(1, 0);

        // HP bar graphics
        this._mHpGfx = this.add.graphics();
        this._updateMonsterBar();

        // Boss crown badge
        if (this._monsterDef.isBoss) {
            this.add.text(ix, PY + 82, '☠  CHEFE DE ÁREA', {
                fontSize: '11px', color: '#ff8844', fontFamily: 'Courier New', fontStyle: 'bold',
            }).setOrigin(0, 0);
        }

        // Info button [i]
        const infoBtnBg = this.add.rectangle(PX + PW - 32, PY + PH - 22, 24, 16, 0x1a1020, 1)
            .setOrigin(0, 0).setStrokeStyle(1, eColor, 0.6).setInteractive()
            .on('pointerover', () => infoBtnBg.setFillStyle(0x2a1840))
            .on('pointerout',  () => infoBtnBg.setFillStyle(0x1a1020))
            .on('pointerdown', () => this._toggleInfo());
        this.add.text(PX + PW - 20, PY + PH - 14, 'i', {
            fontSize: '13px', color: eTextHex, fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5, 0.5);
    }

    _buildPlayerPanel(eColor, eHex, eTextHex, isElite) {
        const PX = 278, PY = 32, PW = 258, PH = 128;
        const p = this._player;

        // Background
        this.add.rectangle(PX, PY, PW, PH, 0x001a08, 1).setOrigin(0, 0);
        this.add.rectangle(PX, PY, PW, PH, 0x33cc66, 0).setOrigin(0, 0).setStrokeStyle(1, 0x33cc66, 0.35);
        this.add.rectangle(PX, PY, PW, 2, 0x44dd77, 0.5).setOrigin(0, 0);

        // Flash
        this._playerFlashRect   = this.add.rectangle(PX, PY, PW, PH, 0xff2222, 0).setOrigin(0, 0);
        this._playerPanelCenter = { x: PX + PW - 50, y: PY + 64 };

        // Sprite
        if (this.textures.exists('sprite_player')) {
            // Rim de prestígio pela maior raridade equipada — atrás do halo
            // verde padrão do combate, só aparece em raro+ (ver InventoryScene)
            const rarity = CombatSystem.highestEquippedRarity(this._player, ITEMS);
            attachRarityGlow(this, PX + PW - 50, PY + 64, 36, rarity);

            const aura = this.add.circle(PX + PW - 50, PY + 64, 30, 0x44ff88, 0.08);
            this.tweens.add({ targets: aura, alpha: 0.2, scale: 1.1, duration: 1300, yoyo: true, repeat: -1 });
            this.add.image(PX + PW - 50, PY + 64, 'sprite_player').setScale(1.5).setDepth(1);
        }

        // Outlier — o companheiro assiste ao combate ao lado do jogador
        const compStage = this._player.companionStage || CompanionSystem.stage(this._player);
        const compKey   = CompanionSystem.texKey(compStage);
        if (this.textures.exists(compKey)) {
            this._companionHome = { x: PX + PW - 92, y: PY + 96 };
            this._companion = this.add.image(this._companionHome.x, this._companionHome.y, compKey).setDepth(2);
            // Pulso de alpha como idle — deixa o eixo Y livre para as reações
            this.tweens.add({
                targets: this._companion, alpha: 0.65,
                duration: 900, yoyo: true, repeat: -1, ease: 'Sine.easeInOut',
            });
        }

        // Info (left side of panel)
        const ix = PX + 8;
        this.add.text(ix, PY + 8, (p.name || 'Aventureiro').toUpperCase(), {
            fontSize: '13px', color: '#88ffaa', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0, 0);

        // Level badge
        this.add.rectangle(ix, PY + 30, 64, 16, 0x44cc66, 0.18).setOrigin(0, 0).setStrokeStyle(1, 0x44cc66, 0.5);
        this.add.text(ix + 32, PY + 38, `Nv. ${p.level}`, {
            fontSize: '11px', color: '#88ffaa', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5, 0.5);

        // HP / Focus bar labels
        this.add.text(ix, PY + 50, 'HP', { fontSize: '11px', color: '#aa9988', fontFamily: 'Courier New', fontStyle: 'bold' }).setOrigin(0, 0);
        this._pHpTxt = this.add.text(ix + 134, PY + 50, '', { fontSize: '11px', color: '#aaffbb', fontFamily: 'Courier New', fontStyle: 'bold' }).setOrigin(1, 0);
        this.add.text(ix, PY + 78, 'FOC', { fontSize: '11px', color: '#7788aa', fontFamily: 'Courier New', fontStyle: 'bold' }).setOrigin(0, 0);
        this._pFocTxt = this.add.text(ix + 134, PY + 78, '', { fontSize: '11px', color: '#aabbff', fontFamily: 'Courier New', fontStyle: 'bold' }).setOrigin(1, 0);

        // Streak text (top-right of whole panel row)
        this._streakTxt = this.add.text(PX + PW - 6, PY + 8, '', {
            fontSize: '11px', color: '#ffd700', fontFamily: 'Courier New', fontStyle: 'bold',
            stroke: '#000000', strokeThickness: 2,
        }).setOrigin(1, 0);

        this._pVitalsGfx = this.add.graphics();
        this._updatePlayerBars();

        // Status effect badge (bottom of player panel)
        this._statusBadgeBg = this.add.rectangle(PX + 8, PY + 108, PW - 16, 16, 0x0a0010, 1)
            .setOrigin(0, 0).setStrokeStyle(1, 0x440066, 0.6).setVisible(false);
        this._statusBadgeTx = this.add.text(PX + PW / 2, PY + 116, '', {
            fontSize: '11px', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5, 0.5).setVisible(false);
        this._updateStatusDisplay();
    }

    _buildInfoOverlay(elem, eColor, eTextHex) {
        const W = 544, H = 480;
        const OX = 16, OY = 28, OW = W - 32, OH = H - 56;
        const m = this._monsterDef;

        this._infoOverlay = this.add.container(0, 0).setDepth(90).setVisible(false);

        // Dim backdrop
        const dim = this.add.rectangle(0, 0, W, H, 0x000000, 0.75).setOrigin(0, 0)
            .setInteractive().on('pointerdown', () => this._toggleInfo());
        this._infoOverlay.add(dim);

        // Card background
        const card = this.add.rectangle(OX, OY, OW, OH, 0x060210, 1).setOrigin(0, 0)
            .setStrokeStyle(2, eColor, 0.8);
        const topBar = this.add.rectangle(OX, OY, OW, 3, eColor, 0.9).setOrigin(0, 0);
        this._infoOverlay.add([card, topBar]);

        // Close button
        const closeBg = this.add.rectangle(OX + OW - 28, OY + 6, 22, 18, 0x330000, 1)
            .setOrigin(0, 0).setStrokeStyle(1, 0xff4444, 0.6).setInteractive()
            .on('pointerdown', () => this._toggleInfo());
        const closeTx = this.add.text(OX + OW - 17, OY + 15, 'X', {
            fontSize: '13px', color: '#ff5555', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5, 0.5);
        this._infoOverlay.add([closeBg, closeTx]);

        // Monster name
        const namePrefix = m.isBoss ? '☠  ' : '';
        const nameTx = this.add.text(OX + 12, OY + 10, namePrefix + m.name.toUpperCase(), {
            fontSize: '17px', color: eTextHex, fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0, 0);
        this._infoOverlay.add(nameTx);

        // Element + level badge
        const badgeBg = this.add.rectangle(OX + 12, OY + 34, 110, 16, eColor, 0.2)
            .setOrigin(0, 0).setStrokeStyle(1, eColor, 0.5);
        const badgeTx = this.add.text(OX + 67, OY + 42, `${elem.symbol} ${elem.name.toUpperCase()}  ·  NÍVEL ${m.level}`, {
            fontSize: '11px', color: eTextHex, fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5, 0.5);
        this._infoOverlay.add([badgeBg, badgeTx]);

        // Stats row
        const statY = OY + 58;
        const stats = [
            { label: 'HP',    value: m.maxHp },
            { label: 'ATQ',   value: m.attackDamage },
            { label: 'DEF',   value: m.defense || 0 },
            { label: 'XP',    value: m.xpReward },
            { label: 'OURO',  value: m.goldReward },
        ];
        stats.forEach((s, i) => {
            const sx = OX + 12 + i * 96;
            const statBox = this.add.rectangle(sx, statY, 88, 32, 0x0d0820, 1)
                .setOrigin(0, 0).setStrokeStyle(1, eColor, 0.25);
            const statLbl = this.add.text(sx + 44, statY + 8, s.label, {
                fontSize: '10px', color: '#6655aa', fontFamily: 'Courier New', fontStyle: 'bold',
            }).setOrigin(0.5, 0);
            const statVal = this.add.text(sx + 44, statY + 18, String(s.value), {
                fontSize: '13px', color: eTextHex, fontFamily: 'Courier New', fontStyle: 'bold',
            }).setOrigin(0.5, 0);
            this._infoOverlay.add([statBox, statLbl, statVal]);
        });

        // Divider
        const div = this.add.graphics();
        div.lineStyle(1, eColor, 0.2);
        div.lineBetween(OX + 12, statY + 40, OX + OW - 12, statY + 40);
        this._infoOverlay.add(div);

        // Full flavor text
        if (m.flavor) {
            const flavorTx = this.add.text(OX + 12, statY + 48, `"${m.flavor}"`, {
                fontSize: '13px', color: '#bb9966', fontFamily: 'Courier New', fontStyle: 'italic',
                wordWrap: { width: OW - 24 }, lineSpacing: 4,
            }).setOrigin(0, 0);
            this._infoOverlay.add(flavorTx);
        }

        // Topic label
        const topicTx = this.add.text(OX + 12, OY + OH - 22, `Tópico: ${elem.topicLabel}`, {
            fontSize: '12px', color: '#554466', fontFamily: 'Courier New',
        }).setOrigin(0, 0);
        const closeLbl = this.add.text(OX + OW - 12, OY + OH - 22, 'Clique fora para fechar', {
            fontSize: '11px', color: '#443355', fontFamily: 'Courier New',
        }).setOrigin(1, 0);
        this._infoOverlay.add([topicTx, closeLbl]);
    }

    _toggleInfo() {
        if (!this._infoOverlay) return;
        const next = !this._infoOverlay.visible;
        this._infoOverlay.setVisible(next);
        // While info is open, block answer interaction
        this._answerLock = next;
    }

    _buildQuestionBox(eColor, eHex, eTextHex, isElite) {
        const W = 544;
        const QY = 166, QH = 270;

        // Background
        this.add.rectangle(8, QY, W - 16, QH, 0x060409, 1).setOrigin(0, 0);

        // Ornamental frame
        const fg = this.add.graphics();
        fg.lineStyle(1, eColor, 0.3);
        fg.strokeRect(8, QY, W - 16, QH);
        fg.lineStyle(1, eColor, 0.12);
        fg.strokeRect(11, QY + 3, W - 22, QH - 6);

        // Corner ornaments
        const cornerSz = 8;
        fg.lineStyle(2, eColor, 0.55);
        [[8, QY], [W - 8, QY], [8, QY + QH], [W - 8, QY + QH]].forEach(([cx, cy]) => {
            const sx = cx === 8 ? 1 : -1, sy = cy === QY ? 1 : -1;
            fg.lineBetween(cx, cy, cx + sx * cornerSz, cy);
            fg.lineBetween(cx, cy, cx, cy + sy * cornerSz);
        });

        // Section title
        this.add.text(W / 2, QY + 8, '◆  P E R G U N T A  ◆', {
            fontSize: '12px', color: eTextHex, fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5, 0).setAlpha(0.8);

        // Thin title separator
        fg.lineStyle(1, eColor, 0.15);
        fg.lineBetween(30, QY + 20, W - 30, QY + 20);

        // Context text
        this._ctxTxt = this.add.text(16, QY + 24, '', {
            fontSize: '12px', color: '#aabbcc', fontFamily: 'Courier New', fontStyle: 'italic',
            wordWrap: { width: W - 32 },
        }).setOrigin(0, 0).setVisible(false);

        // Question text
        this._qTxt = this.add.text(16, QY + 24, '', {
            fontSize: '15px', color: '#ede8de', fontFamily: 'Courier New',
            wordWrap: { width: W - 32 }, lineSpacing: 5,
        }).setOrigin(0, 0);

        // Choice buttons (built dynamically in _showChoiceBtns)
        this._aBtns = [];
        for (let i = 0; i < 4; i++) {
            const col = i % 2, row = Math.floor(i / 2);
            const bx = 10 + col * 262;
            const by = 306 + row * 36;
            const bg = this.add.rectangle(bx, by, 256, 30, 0x0d0b18, 1)
                .setOrigin(0, 0).setStrokeStyle(1, 0x2a2440, 1).setInteractive()
                .on('pointerover', () => { if (!this._answerLock) { bg.setFillStyle(0x16122a); bg.setStrokeStyle(1, eColor, 0.6); } })
                .on('pointerout',  () => { if (!this._answerLock) { bg.setFillStyle(0x0d0b18); bg.setStrokeStyle(1, 0x2a2440, 1); } });

            // Label badge (A/B/C/D)
            const LABELS = ['A','B','C','D'];
            const badge = this.add.rectangle(bx + 3, by + 3, 24, 24, eColor, 0.25).setOrigin(0, 0).setStrokeStyle(1, eColor, 0.6);
            const badgeTx = this.add.text(bx + 15, by + 15, LABELS[i], {
                fontSize: '13px', color: eTextHex, fontFamily: 'Courier New', fontStyle: 'bold',
                stroke: '#000000', strokeThickness: 2,
            }).setOrigin(0.5, 0.5);

            const tx = this.add.text(bx + 34, by + 15, '', {
                fontSize: '12px', color: '#ddd8cc', fontFamily: 'Courier New', wordWrap: { width: 214 },
            }).setOrigin(0, 0.5);

            this._aBtns.push({ bg, badge, badgeTx, tx });
        }

        // Numeric input
        this._numPrt = this.add.text(14, 306, '▶  DIGITE A RESPOSTA  ·  ENTER para confirmar', {
            fontSize: '12px', color: eTextHex, fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0, 0).setVisible(false);

        // Input box background
        this._numBoxBg = this.add.rectangle(14, 322, W - 28, 28, 0x0a0814, 1).setOrigin(0, 0)
            .setStrokeStyle(1, eColor, 0.4).setVisible(false);
        this._numDisp = this.add.text(22, 336, '', {
            fontSize: '16px', color: '#ffffff', fontFamily: 'Courier New',
        }).setOrigin(0, 0.5).setVisible(false);
        this._numCursor = this.add.text(22, 336, '|', {
            fontSize: '16px', color: eTextHex, fontFamily: 'Courier New',
        }).setOrigin(0, 0.5).setVisible(false);
        this._numOkBg = this.add.rectangle(14, 356, 140, 26, 0x0a2010, 1).setOrigin(0, 0)
            .setStrokeStyle(1, 0x33cc66, 0.6).setInteractive()
            .on('pointerover', () => this._numOkBg.setFillStyle(0x153020))
            .on('pointerout',  () => this._numOkBg.setFillStyle(0x0a2010))
            .on('pointerdown', () => this._submitNumeric())
            .setVisible(false);
        this._numOkTx = this.add.text(84, 369, '✓  CONFIRMAR', {
            fontSize: '11px', color: '#55ee88', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5, 0.5).setVisible(false);

        // Feedback (correct/wrong)
        this._feedbackTxt = this.add.text(W / 2, 376, '', {
            fontSize: '12px', fontFamily: 'Courier New', fontStyle: 'bold',
            stroke: '#000000', strokeThickness: 3,
            wordWrap: { width: W - 32 },
        }).setOrigin(0.5, 0).setVisible(false);

        // Explanation text
        this._explTxt = this.add.text(16, 396, '', {
            fontSize: '11px', color: '#99bbdd', fontFamily: 'Courier New',
            wordWrap: { width: W - 32 }, fontStyle: 'italic',
        }).setOrigin(0, 0);

        // Continue prompt — shown after an answer so the player can read
        // the explanation calmly before the next question. Sits over the DICA
        // slot (useless during the pause) — never over FUGIR, which must stay
        // clickable right after the player takes damage.
        this._awaitContinue = false;
        this._continueBg = this.add.rectangle(83, 458, 146, 30, 0x1a1400, 1)
            .setStrokeStyle(1, 0xd4af37, 0.8).setDepth(60).setVisible(false)
            .setInteractive({ useHandCursor: true })
            .on('pointerover', () => this._continueBg.setFillStyle(0x2a2000))
            .on('pointerout',  () => this._continueBg.setFillStyle(0x1a1400))
            .on('pointerdown', () => this._continueAfterAnswer());
        this._continueTx = this.add.text(83, 458, '▶ CONTINUAR [ESPAÇO]', {
            fontSize: '10px', color: '#ffd700', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5, 0.5).setDepth(61).setVisible(false);
        this._continueTween = null;
    }

    _showContinuePrompt() {
        // Com o editor aberto, quem oferece o "Continuar" é ele — o prompt do
        // canvas está escondido atrás do overlay.
        if (this._currentQ?.type === 'code' && CodeEditor.isOpen()) {
            this._concludeCodeTurn(null);
            return;
        }
        this._awaitContinue = true;
        this._continueBg.setVisible(true);
        this._continueTx.setVisible(true).setAlpha(1);
        this._continueTween = this.tweens.add({
            targets: this._continueTx, alpha: 0.45,
            duration: 550, yoyo: true, repeat: -1, ease: 'Sine.easeInOut',
        });
    }

    _continueAfterAnswer() {
        if (!this._awaitContinue) return;
        this._awaitContinue = false;
        this._continueTween?.stop();
        this._continueTween = null;
        this._continueBg.setVisible(false);
        this._continueTx.setVisible(false);
        Sound.click();
        this._nextQuestion();
    }

    _buildBottomBar(eColor, eHex, isElite) {
        const W = 544;
        const BY = 438;

        // Bar background
        this.add.rectangle(0, BY - 1, W, 1, eColor, 0.2).setOrigin(0, 0);
        this.add.rectangle(0, BY, W, 42, 0x040206, 1).setOrigin(0, 0);

        const btnStyle = (fillColor, borderColor, label, textColor, x, w) => {
            const bg = this.add.rectangle(x, BY + 6, w, 28, fillColor, 1).setOrigin(0, 0)
                .setStrokeStyle(1, borderColor, 0.5).setInteractive()
                .on('pointerover', () => bg.setFillStyle(fillColor + 0x0a0a0a))
                .on('pointerout',  () => bg.setFillStyle(fillColor));
            this.add.text(x + w / 2, BY + 20, label, {
                fontSize: '12px', color: textColor, fontFamily: 'Courier New', fontStyle: 'bold',
            }).setOrigin(0.5, 0.5);
            return bg;
        };

        // DICA
        const hintBg = btnStyle(0x080818, 0x5555bb, '◈ DICA (−10 FOCO)', '#aaaaff', 8, 150);
        hintBg.on('pointerdown', () => this._useHint());

        // ITEM (consumíveis) — selado durante o Julgamento
        const itemBg = this._rules.noItems
            ? btnStyle(0x141414, 0x444444, '✚ ITEM ⊘', '#666666', 166, 110)
            : btnStyle(0x0e1408, 0x55aa33, '✚ ITEM [E]', '#88dd66', 166, 110);
        itemBg.on('pointerdown', () => this._toggleItemPanel());

        // NOTAS/CALC
        const calcBg = btnStyle(0x060e06, 0x338833, '✦ NOTAS/CALC [N]', '#55cc66', 284, 150);
        calcBg.on('pointerdown', () => this._openScratchpad());

        // FUGIR
        const fleeBg = btnStyle(0x180808, 0xaa3322, '⊗ FUGIR', '#ee6644', 442, 94);
        fleeBg.on('pointerdown', () => this._flee());

        // Extra separator before Fugir
        const sepGfx = this.add.graphics();
        sepGfx.lineStyle(1, 0x331100, 0.8);
        sepGfx.lineBetween(436, BY + 6, 436, BY + 34);

        this.input.keyboard.on('keydown-N', () => this._openScratchpad());
    }

    _openScratchpad() {
        if (this.scene.isActive('Scratchpad')) return;
        this.scene.launch('Scratchpad', { parent: this });
    }

    // ─── ITENS EM COMBATE ─────────────────────────────────────────────────────
    // Consumíveis podem ser usados fora do turno de resposta ou durante a
    // pausa da correção (o momento natural de curar). Custo: zera o streak.

    _toggleItemPanel() {
        if (this._rules.noItems) {
            Sound.denied();
            EventBus.emit('chat', { msg: 'Sua mochila foi selada — o Julgamento não permite itens.', type: 'system' });
            return;
        }
        if (this._itemPanel) { this._closeItemPanel(); return; }
        if (this._fleeConfirmOpen) return;
        if (this._answerLock && !this._awaitContinue) return;

        const consumables = (this._player.inventory || [])
            .filter(s => ITEMS[s.itemId]?.type === 'consumable');
        if (!consumables.length) {
            Sound.denied();
            EventBus.emit('chat', { msg: 'Você não tem consumíveis na mochila.', type: 'system' });
            return;
        }

        Sound.menuOpen();
        const W = 544;
        const rows = Math.min(consumables.length, 6);
        const pw = 330, ph = 66 + rows * 26;
        const px = (W - pw) / 2;
        const py = 430 - ph;

        const c = this.add.container(0, 0).setDepth(190);
        this._itemPanel = c;
        // Dim interativo: clicar fora fecha o painel
        c.add(this.add.rectangle(0, 0, 544, 480, 0x000000, 0.5).setOrigin(0, 0)
            .setInteractive().on('pointerdown', () => this._closeItemPanel()));

        c.add(this.add.rectangle(px, py, pw, ph, 0x0a1206, 1).setOrigin(0, 0)
            .setStrokeStyle(2, 0x55aa33, 0.8));
        c.add(this.add.text(W / 2, py + 10, '✚  USAR ITEM', {
            fontSize: '14px', color: '#88dd66', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5, 0));
        c.add(this.add.text(W / 2, py + 28, 'Usar um item zera sua sequência de acertos', {
            fontSize: '10px', color: '#997', fontFamily: 'Courier New', fontStyle: 'italic',
        }).setOrigin(0.5, 0));

        consumables.slice(0, 6).forEach((slot, i) => {
            const item = ITEMS[slot.itemId];
            const y = py + 46 + i * 26;
            const bg = this.add.rectangle(px + 12, y, pw - 24, 22, 0x101a0a, 1).setOrigin(0, 0)
                .setStrokeStyle(1, 0x22401a, 1)
                .setInteractive({ useHandCursor: true })
                .on('pointerover', () => bg.setFillStyle(0x1c3012))
                .on('pointerout',  () => bg.setFillStyle(0x101a0a))
                .on('pointerdown', () => this._useCombatItem(slot.itemId));
            const e = item.effect || {};
            const effTxt = e.hp ? `+${e.hp} HP` : e.focus ? `+${e.focus} FOCO`
                : e.incense ? `${e.incense}× ELITE` : '';
            c.add(bg);
            c.add(this.add.text(px + 20, y + 11, `${item.name}  ×${slot.qty}`, {
                fontSize: '11px', color: '#e8e0d0', fontFamily: 'Courier New',
            }).setOrigin(0, 0.5));
            c.add(this.add.text(px + pw - 20, y + 11, effTxt, {
                fontSize: '11px', color: '#88dd66', fontFamily: 'Courier New', fontStyle: 'bold',
            }).setOrigin(1, 0.5));
        });
    }

    _closeItemPanel() {
        if (!this._itemPanel) return;
        this._itemPanel.destroy();
        this._itemPanel = null;
    }

    _useCombatItem(itemId) {
        const item = ITEMS[itemId];
        const ok = CombatSystem.useItem(this._player, itemId, ITEMS);
        this._closeItemPanel();
        if (!ok || !item) { Sound.denied(); return; }

        Sound.useItem();
        if (this._streak > 0) {
            this._streak = 0;
            this._streakTxt.setText('');
            this._updateFeverMode(false);
            EventBus.emit('chat', { msg: 'A pausa para usar o item quebrou sua sequência.', type: 'system' });
        }
        this._updatePlayerBars();
        this.registry.set('player', this._player);
        EventBus.emit('player-hp-change', { player: this._player });

        const e = item.effect || {};
        const gains = [];
        if (e.hp)    gains.push(`{{heal:+${e.hp} HP}}`);
        if (e.focus) gains.push(`{{hint:+${e.focus} Foco}}`);
        EventBus.emit('chat', {
            msg: `Você usou {{accent:${item.name}}}${gains.length ? ' — ' + gains.join(', ') : ''}.`,
            type: 'heal',
        });
        if (e.incense) {
            EventBus.emit('chat', {
                msg: `{{accent:Incenso do Caos}} aceso — os próximos ${this._player.incenseCharges} monstros serão {{level:Elite}}!`,
                type: 'system',
            });
        }
        this._spawnDamageNumber(this._playerPanelCenter, e.hp ? `+${e.hp}` : '✚', '#55ff88', false);
    }

    // Combat in the depths counts toward the parent surface area's mastery
    _masteryRef() {
        const area = parentArea(this._player.currentArea);
        if (!this._player.mastery[area]) {
            this._player.mastery[area] = { attempted: 0, correct: 0, wrongIds: [] };
        }
        return this._player.mastery[area];
    }

    // ─── QUESTION FLOW ────────────────────────────────────────────────────────

    _nextQuestion() {
        StatusEffectSystem.tick(this._player);
        this._updateStatusDisplay();

        const mastery = this._masteryRef();
        const q = this._isCodeMonster()
            ? this._pickCodeChallenge(mastery)
            : QuestionEngine.getQuestion(
                this._monsterDef.questionTopic,
                this._monsterDef.questionDifficulty,
                mastery,
                this._recentIds
            );

        if (!q) { this._endCombat('flee'); return; }

        this._codeReport = null;
        this._currentQ = q.type === 'code' ? q : QuestionEngine.shuffleOptions(q);
        this._recentIds.push(q.id);
        if (this._recentIds.length > 6) this._recentIds.shift();

        this._answerLock   = false;
        this._numericValue = '';
        this._feedbackTxt.setVisible(false);
        this._explTxt.setFontSize(11).setText('');

        this._renderQuestion();
    }

    _renderQuestion() {
        const q = this._currentQ;
        let y = 186;

        if (q.type === 'code') {
            this._renderCodeChallenge(q);
            return;
        }

        if (q.context) {
            this._ctxTxt.setY(y).setText(`Contexto: ${q.context}`).setVisible(true);
            y += this._ctxTxt.height + 4;
        } else {
            this._ctxTxt.setVisible(false);
        }

        this._qTxt.setY(y).setText(q.questionText);
        // Clamp options start between 284-296 so they don't drift too far
        const optY = Math.min(Math.max(y + this._qTxt.height + 8, 284), 296);

        if (q.type === 'fill_numeric') {
            this._hideChoiceBtns();
            this._showNumericInput(optY);
        } else {
            this._hideNumericInput();
            this._showChoiceBtns(q.options || [], optY);
        }
    }

    _showChoiceBtns(options, startY) {
        for (let i = 0; i < this._aBtns.length; i++) {
            const { bg, badge, badgeTx, tx } = this._aBtns[i];
            if (i < options.length) {
                const col = i % 2, row = Math.floor(i / 2);
                const by  = startY + row * 36;
                bg.setY(by).setFillStyle(0x0d0b18).setVisible(true);
                badge.setY(by + 3).setVisible(true);
                badgeTx.setY(by + 15).setVisible(true);
                tx.setY(by + 15).setText(options[i]).setVisible(true);
                bg.removeAllListeners('pointerdown');
                const answer = options[i];
                this._aBtns[i]._answer = answer;
                bg.on('pointerdown', () => { if (!this._answerLock) this._onAnswer(answer, bg); });
            } else {
                bg.setVisible(false);
                badge.setVisible(false);
                badgeTx.setVisible(false);
                tx.setVisible(false);
                this._aBtns[i]._answer = null;
            }
        }
    }

    _hideChoiceBtns() {
        for (const { bg, badge, badgeTx, tx } of this._aBtns) {
            bg.setVisible(false).removeAllListeners('pointerdown');
            badge.setVisible(false);
            badgeTx.setVisible(false);
            tx.setVisible(false);
        }
    }

    _showNumericInput(startY) {
        this._numPrt.setY(startY).setVisible(true);
        this._numBoxBg.setY(startY + 16).setVisible(true);
        this._numDisp.setY(startY + 30).setText('').setVisible(true);
        this._numCursor.setY(startY + 30).setX(22).setVisible(true).setAlpha(1);
        if (!this._cursorTween) {
            this._cursorTween = this.tweens.add({
                targets: this._numCursor, alpha: 0.1, duration: 500, yoyo: true, repeat: -1,
            });
        }
        this._numOkBg.setY(startY + 50).setVisible(true);
        this._numOkTx.setY(startY + 63).setVisible(true);
    }

    _hideNumericInput() {
        this._numPrt.setVisible(false);
        this._numBoxBg?.setVisible(false);
        this._numDisp.setVisible(false);
        this._numCursor.setVisible(false);
        this._numOkBg.setVisible(false);
        this._numOkTx.setVisible(false);
    }

    _onKeyDown(event) {
        if (this.scene.isActive('Scratchpad')) return;
        if (CodeEditor.isOpen()) return;
        if (this._currentQ?.type === 'code' && !this._answerLock
            && (event.key === ' ' || event.key === 'Enter')) {
            this._openCodeEditor();
            return;
        }
        if (this._fleeConfirmOpen) return; // diálogo de fuga tem os próprios controles
        if (this._itemPanel) {
            if (event.key === 'Escape' || event.key === 'e' || event.key === 'E') this._closeItemPanel();
            return;
        }
        if (event.key === 'e' || event.key === 'E') { this._toggleItemPanel(); return; }
        if (this._awaitContinue && (event.key === ' ' || event.key === 'Enter')) {
            this._continueAfterAnswer();
            return;
        }
        if (!this._currentQ || this._answerLock) return;

        if (this._currentQ.type !== 'fill_numeric' && /^[1234]$/.test(event.key)) {
            const idx = parseInt(event.key) - 1;
            const btn = this._aBtns[idx];
            if (btn?.bg.visible && btn._answer != null) this._onAnswer(btn._answer, btn.bg);
            return;
        }

        if (this._currentQ.type !== 'fill_numeric') return;
        if (event.key === 'Enter')     { this._submitNumeric(); return; }
        if (event.key === 'Backspace') { this._numericValue = this._numericValue.slice(0, -1); }
        else if (/^[-0-9.,]$/.test(event.key)) {
            const ch = (event.key === ',') ? '.' : event.key;
            if ((ch === '.') && this._numericValue.includes('.')) return;
            this._numericValue += ch;
        }
        this._numDisp.setText(this._numericValue);
        this._numCursor.setX(22 + this._numDisp.width + 2);
    }

    _submitNumeric() {
        if (!this._answerLock && this._numericValue) this._onAnswer(this._numericValue, null);
    }

    // ─── DESAFIOS DE CÓDIGO ───────────────────────────────────────────────────
    // A criatura pede uma função Python em vez de uma alternativa. O editor é
    // DOM (o canvas de 544×480 não comporta digitação), então o turno acontece
    // fora da tela do Phaser e volta pelo mesmo _onAnswer das demais questões.

    _isCodeMonster() {
        return this._monsterDef?.questionKind === 'code';
    }

    _pickCodeChallenge(mastery) {
        // Sem interpretador (offline, navegador antigo, CDN fora do ar) a
        // criatura recorre à teoria do próprio elemento em vez de travar.
        if (PythonRuntime.status === 'failed') {
            const elem  = CODE_TOPIC_TO_ELEMENT[this._monsterDef.questionTopic] || this._monsterDef.element;
            const topic = ELEMENTS[elem]?.topic || 'data_types';
            EventBus.emit('chat', {
                msg: 'O interpretador não respondeu — a criatura recorre à teoria.',
                type: 'system',
            });
            return QuestionEngine.getQuestion(topic, this._monsterDef.questionDifficulty, mastery, this._recentIds);
        }
        return CodeChallengeEngine.getChallenge(
            this._monsterDef.questionTopic,
            this._monsterDef.questionDifficulty,
            mastery,
            this._recentIds,
        );
    }

    _renderCodeChallenge(q) {
        this._hideChoiceBtns();
        this._hideNumericInput();
        this._ctxTxt.setVisible(false);
        this._qTxt.setY(200).setText(
            `⌨  DESAFIO DE CÓDIGO\n\n${q.title}\n\nO editor abre por cima da tela.\nSe ele fechar, pressione ESPAÇO para reabrir.`
        );
        this._openCodeEditor();
    }

    _codeCombatState() {
        return {
            monsterName:  this._monsterDef.name,
            monsterHp:    this._monsterHp,
            monsterMaxHp: this._monsterDef.maxHp,
            playerHp:     this._player.hp,
            playerMaxHp:  this._player.maxHp,
            focus:        this._player.focus,
            maxFocus:     this._player.maxFocus,
            streak:       this._streak,
        };
    }

    _openCodeEditor() {
        if (CodeEditor.isOpen() || this._answerLock) return;
        // O Phaser escuta o teclado na window: sem desligar, cada letra
        // digitada viraria atalho de combate.
        if (this.input?.keyboard) this.input.keyboard.enabled = false;
        const world = this.scene.get('World');
        if (world?.input?.keyboard) world.input.keyboard.enabled = false;

        CodeEditor.open({
            challenge: this._currentQ,
            combat:    this._codeCombatState(),
            onSubmit:  (report) => this._onCodeSubmit(report),
            onGiveUp:  () => this._onCodeSubmit({
                allPassed: false, passed: 0, gaveUp: true,
                total: (this._currentQ.cases || []).length, results: [],
            }),
            onHint:    () => this._codeHint(),
        });
    }

    _restoreKeyboard() {
        if (this.input?.keyboard) this.input.keyboard.enabled = true;
        const world = this.scene.get('World');
        if (world?.input?.keyboard) world.input.keyboard.enabled = true;
    }

    /** Mesma economia de Foco da dica normal, devolvendo o texto ao editor. */
    _codeHint() {
        if (StatusEffectSystem.isHintBlocked(this._player)) {
            EventBus.emit('chat', { msg: '❄ Congelado! A dica está bloqueada neste turno.', type: 'system' });
            return null;
        }
        if (!this._currentQ?.hint) return null;
        const custo = this._relicEffect?.type === 'free_hints' ? 0 : 10;
        if (this._player.focus < custo) {
            EventBus.emit('chat', { msg: 'Foco insuficiente para a dica (custa 10).', type: 'system' });
            return null;
        }
        this._player.focus -= custo;
        this._updatePlayerBars();
        EventBus.emit('player-hp-change', { player: this._player });
        Sound.hint();
        CodeEditor.updateVitals(this._codeCombatState());
        return `${this._currentQ.hint}${custo === 0 ? ' [Prisma da Clareza]' : ''}`;
    }

    _onCodeSubmit(report) {
        this._codeReport = report;
        this._onAnswer(report, null);
        CodeEditor.updateVitals(this._codeCombatState());
    }

    /** Fecha o turno dentro do editor: veredito, explicação e gabarito. */
    _concludeCodeTurn(outcome) {
        const q   = this._currentQ;
        const rep = this._codeReport || {};
        const passou = !!rep.allPassed;
        const headline = passou
            ? '✓ Código aceito — o golpe acerta em cheio!'
            : rep.gaveUp
                ? '✗ Você desistiu deste desafio'
                : `✗ ${rep.passed || 0} de ${rep.total || 0} testes passaram`;

        CodeEditor.conclude({
            passed:   passou,
            headline,
            detail:   q?.explanation,
            solution: passou ? null : q?.solution,
            onContinue: () => {
                this._restoreKeyboard();
                if (outcome) this._endCombat(outcome);
                else         this._nextQuestion();
            },
        });
        CodeEditor.updateVitals(this._codeCombatState());
    }

    // ─── ANSWER HANDLING ──────────────────────────────────────────────────────

    _onAnswer(userAnswer, btnBg) {
        if (this._answerLock || this._awaitContinue) return;
        this._answerLock = true;

        const q = this._currentQ;
        const qForCheck = StatusEffectSystem.isToleranceZero(this._player) && q.type === 'fill_numeric'
            ? { ...q, tolerance: 0 }
            : q;
        // No desafio de código quem decide são os testes, não a comparação
        // de texto: só passa quem passa em todos, inclusive nos ocultos.
        const correct = q.type === 'code'
            ? CodeChallengeEngine.checkAnswer(q, userAnswer)
            : QuestionEngine.checkAnswer(qForCheck, userAnswer);
        const mastery = this._masteryRef();
        mastery.attempted++;

        if (correct) {
            this._streak++;
            if (this._streak > this._maxStreak) this._maxStreak = this._streak;
            this._companionReact(true);
            mastery.correct++;
            mastery.wrongIds = mastery.wrongIds.filter(id => id !== q.id);

            // JUICE: Correct flash
            this._juiceCorrect.setAlpha(0.2);
            this.tweens.add({ targets: this._juiceCorrect, alpha: 0, duration: 400 });

            // Award Elemental XP based on topic
            const elementId = TOPIC_TO_ELEMENT[q.topic] || CODE_TOPIC_TO_ELEMENT[q.topic] || 'normal';
            awardElementalXP(this._player, elementId, 15);

            // Resolve weapon element from equipped item (live lookup)
            const weaponId = this._player.equipment?.rightHand || this._player.equipment?.leftHand;
            const weaponInfo = ITEMS[weaponId] || null;
            this._player._weaponElement = weaponInfo?.element || 'normal';

            const result = CombatSystem.calcPlayerDamage(this._player, this._monsterDef, this._streak, weaponInfo);

            // Relic: damage boost on correct answer
            let finalDmgToMonster = result.damage;
            if (this._relicEffect?.type === 'damage_boost_correct') {
                finalDmgToMonster = Math.floor(finalDmgToMonster * (1 + this._relicEffect.value));
            }

            this._monsterHp = Math.max(0, this._monsterHp - finalDmgToMonster);
            this._updateMonsterBar();
            this._spawnDamageNumber(this._monsterPanelCenter, finalDmgToMonster, result.isCrit ? '#ff88cc' : '#ff5555', result.isCrit);
            this._flashTarget('monster', result.advantage === 'super' ? 0xffaa00 : 0xff3333);

            if (result.isCrit) Sound.critical(); else Sound.hit();

            if (result.advantage !== 'neutral') {
                this._spawnElementalBanner(result.advantage, result.multiplier);
            }

            let msg = `Correto! Dano: ${finalDmgToMonster}`;
            if (result.isCrit)  msg += ' [CRÍTICO!]';
            if (result.isFever) msg += ' [🔥FERVURA]';
            if (this._relicEffect?.type === 'damage_boost_correct') msg += ' [RELÍQUIA]';
            if (result.distribution === 'uniform') msg += ' (Instável!)';
            else if (weaponInfo) msg += ' (Consistente)';

            this._showFeedback(msg, result.isCrit ? '#ff88cc' : '#55ff88');
            if (btnBg) btnBg.setFillStyle(0x003300);
            if (this._streak > 1) {
                this._streakTxt.setText(`${this._streak}× STREAK!`);
                Sound.streak(this._streak);
                
                // Fever Mode Activation (5+ streak)
                if (this._streak >= 5) {
                    this._updateFeverMode(true);
                    this._spawnFeverText();
                }
            }

            // Relic: focus regen on correct answer
            if (this._relicEffect?.type === 'focus_regen_on_correct') {
                const regen = this._relicEffect.value;
                this._player.focus = Math.min(this._player.maxFocus, this._player.focus + regen);
                this._updatePlayerBars();
                this._spawnDamageNumber(this._playerPanelCenter, `+${regen}F`, '#88aaff', false);
            }

            if (q.explanation) this._explTxt.setText(`Explicação: ${q.explanation}`);

            if (this._monsterHp <= 0) {
                this.time.delayedCall(1500, () => this._endCombat('win'));
                return;
            }

            // Acertos também pausam: o jogador confirma quando terminar de ler a explicação
            this._showContinuePrompt();
            return;
        } else {
            // Anel da Significância: o primeiro erro do combate fica dentro de
            // α — sem dano, sem status, e a sequência de acertos sobrevive.
            if (this._relicEffect?.type === 'first_error_forgiven' && !this._alphaUsed) {
                this._alphaUsed = true;
                this._wrongCount++;
                if (!mastery.wrongIds.includes(q.id)) mastery.wrongIds.push(q.id);
                Sound.dodge();
                this._juiceWrong.setAlpha(0.15);
                this.tweens.add({ targets: this._juiceWrong, alpha: 0, duration: 400 });
                this._showFeedback('Errado — mas dentro da margem! O Anel da Significância perdoa seu primeiro deslize.', '#aaddff');
                this._spawnDamageNumber(this._playerPanelCenter, 'α', '#aaddff', false);

                const ansA = typeof q.correctAnswer === 'number'
                    ? String(q.correctAnswer).replace('.', ',')
                    : q.correctAnswer;
                let corrA = `Resposta correta: ${ansA}.`;
                if (q.explanation) corrA += ` ${q.explanation}`;
                this._explTxt.setFontSize(11).setText(corrA);
                if (this._explTxt.y + this._explTxt.height > 436) this._explTxt.setFontSize(10);

                this._showContinuePrompt();
                return;
            }

            this._streak = 0;
            this._wrongCount++;
            this._companionReact(false);
            this._streakTxt.setText('');
            this._updateFeverMode(false); // DEACTIVATE FEVER ON WRONG
            if (!mastery.wrongIds.includes(q.id)) mastery.wrongIds.push(q.id);

            // JUICE: Wrong flash (cold/danger)
            this._juiceWrong.setAlpha(0.35);
            this.tweens.add({ targets: this._juiceWrong, alpha: 0, duration: 600 });
            this.cameras.main.shake(300, 0.015); // Extra heavy shake for wrong answer

            const result = CombatSystem.calcMonsterDamage(this._monsterDef, this._player);

            let finalDamage = result.damage;

            // Desafio de código resolvido pela metade ainda vale alguma coisa:
            // os testes que passaram arranham o monstro e amortecem o troco.
            const codeRatio = (q.type === 'code' && userAnswer?.total)
                ? (userAnswer.passed || 0) / userAnswer.total
                : 0;
            if (codeRatio > 0) {
                finalDamage = Math.max(1, Math.round(finalDamage * (1 - codeRatio * 0.5)));

                const weaponId   = this._player.equipment?.rightHand || this._player.equipment?.leftHand;
                const weaponInfo = ITEMS[weaponId] || null;
                this._player._weaponElement = weaponInfo?.element || 'normal';
                const base    = CombatSystem.calcPlayerDamage(this._player, this._monsterDef, 0, weaponInfo).damage;
                const parcial = Math.max(1, Math.floor(base * codeRatio * 0.4));
                this._monsterHp = Math.max(0, this._monsterHp - parcial);
                this._updateMonsterBar();
                this._spawnDamageNumber(this._monsterPanelCenter, parcial, '#ffaa66', false);
                EventBus.emit('chat', {
                    msg: `${userAnswer.passed}/${userAnswer.total} testes passaram — golpe de raspão: {{damage:${parcial}}}.`,
                    type: 'combat-hit',
                });
            }
            let statusLabel = null;
            let relicBlocked = false;
            if (!result.dodged) {
                // Relic: chance to block all damage on wrong answer
                if (this._relicEffect?.type === 'damage_block_chance' && Math.random() < this._relicEffect.value) {
                    relicBlocked = true;
                    finalDamage  = 0;
                } else {
                    const mod = StatusEffectSystem.modifyDamage(this._player, result.damage);
                    finalDamage = mod.damage;
                    statusLabel = mod.label;
                }
            }

            this._player.hp = Math.max(0, this._player.hp - finalDamage);
            this._updatePlayerBars();
            EventBus.emit('player-hp-change', { player: this._player });

            // Apply new status effect from monster element
            const newEffect = StatusEffectSystem.apply(this._player, this._monsterDef.element);
            this._updateStatusDisplay();

            if (result.dodged) {
                Sound.dodge();
                this._showFeedback('Errado! Mas você ESQUIVOU o ataque!', '#88ccff');
                this._spawnDamageNumber(this._playerPanelCenter, 'ESQUIVA', '#88ccff', false);
            } else if (relicBlocked) {
                Sound.dodge();
                this._showFeedback('Errado! A Relíquia ABSORVEU o dano!', '#aaddff');
                this._spawnDamageNumber(this._playerPanelCenter, 'BLOQUEIO', '#aaddff', false);
            } else {
                Sound.wrong();
                this.time.delayedCall(120, () => Sound.damage());
                let msg = `Errado! Dano recebido: ${finalDamage}`;
                if (statusLabel) msg += `  ${statusLabel}`;
                this._showFeedback(msg, '#ff5555');
                this._spawnDamageNumber(this._playerPanelCenter, finalDamage, '#ff5555', false);
                this._flashTarget('player', 0xff3333);
                if (newEffect) {
                    const def = STATUS_DEFS[newEffect];
                    if (def) {
                        const effectTxt = this.add.text(278 + 129, 148, `⚠ ${def.name.toUpperCase()} APLICADO!`, {
                            fontSize: '11px', color: def.color, fontFamily: 'Courier New', fontStyle: 'bold',
                            stroke: '#000000', strokeThickness: 3,
                        }).setOrigin(0.5, 0).setAlpha(0).setDepth(60);
                        this.tweens.add({
                            targets: effectTxt, alpha: 1, duration: 200,
                            onComplete: () => this.tweens.add({
                                targets: effectTxt, alpha: 0, y: effectTxt.y - 20,
                                delay: 700, duration: 400,
                                onComplete: () => effectTxt.destroy(),
                            }),
                        });
                    }
                }
            }
            if (btnBg) btnBg.setFillStyle(0x330000);

            const ans = typeof q.correctAnswer === 'number'
                ? String(q.correctAnswer).replace('.', ',')
                : q.correctAnswer;
            // Em código a "resposta certa" é a solução inteira — ela vai para o
            // editor em _concludeCodeTurn, não cabe nesta caixa.
            let correction = q.type === 'code' ? '' : `Resposta correta: ${ans}.`;
            if (q.explanation) correction += `${correction ? ' ' : ''}${q.explanation}`;
            this._explTxt.setFontSize(11).setText(correction);
            // Explanation area ends where the bottom bar begins (y=438)
            if (this._explTxt.y + this._explTxt.height > 436) this._explTxt.setFontSize(10);

            if (this._player.hp <= 0) {
                this.time.delayedCall(1500, () => this._endCombat('loss'));
                return;
            }

            // O dano de raspão pode ter derrubado o monstro mesmo com a
            // resposta errada — a vitória vale igual.
            if (this._monsterHp <= 0) {
                this.time.delayedCall(1200, () => this._endCombat('win'));
                return;
            }

            // Erros pausam: o jogador confirma quando terminar de ler a explicação
            this._showContinuePrompt();
        }
    }

    // Outlier comemora acertos e murcha nos erros
    _companionReact(correct) {
        if (!this._companion) return;
        this._compTween?.stop();
        this._companion.setPosition(this._companionHome.x, this._companionHome.y).setAngle(0);
        if (correct) {
            this._companion.setTintFill(0xffffff);
            this.time.delayedCall(120, () => this._companion?.clearTint());
            this._compTween = this.tweens.add({
                targets: this._companion, y: this._companionHome.y - 12,
                duration: 150, yoyo: true, ease: 'Quad.easeOut',
            });
        } else {
            this._companion.setTint(0x667788);
            this._compTween = this.tweens.add({
                targets: this._companion, y: this._companionHome.y + 5, angle: -14,
                duration: 260, ease: 'Quad.easeIn',
            });
            this.time.delayedCall(1200, () => {
                if (!this._companion) return;
                this._companion.clearTint();
                this._compTween?.stop();
                this._compTween = this.tweens.add({
                    targets: this._companion, y: this._companionHome.y, angle: 0, duration: 300,
                });
            });
        }
    }

    _spawnDamageNumber(center, value, color, big) {
        if (!center) return;
        
        // Screen shake on hit
        this.cameras.main.shake(big ? 250 : 150, big ? 0.012 : 0.006);

        // Sprite jump/shake
        const targetSprite = center === this._monsterPanelCenter ? this._monsterSprite : null;
        if (targetSprite) {
            this.tweens.add({
                targets: targetSprite,
                x: center.x + (big ? 10 : 5),
                yoyo: true, duration: 50, repeat: 2,
                onComplete: () => targetSprite.setX(center.x)
            });
        }

        const txt = this.add.text(center.x, center.y - 10, String(value), {
            fontSize: big ? '24px' : '16px', color, fontFamily: 'Courier New', fontStyle: 'bold',
            stroke: '#000000', strokeThickness: 4,
        }).setOrigin(0.5, 0.5).setDepth(50);
        this.tweens.add({
            targets: txt, y: center.y - 60, alpha: 0,
            duration: 1100, ease: 'Cubic.Out',
            onComplete: () => txt.destroy(),
        });
    }

    _flashTarget(who, color) {
        const target = who === 'monster' ? this._monsterFlashRect : this._playerFlashRect;
        if (!target) return;
        target.setFillStyle(color, 0.5);
        this.tweens.add({
            targets: target, alpha: 0,
            duration: 280, ease: 'Quad.Out',
            onComplete: () => target.setAlpha(1).setFillStyle(color, 0),
        });
    }

    _showFeedback(msg, color) {
        this._feedbackTxt.setText(msg).setColor(color).setVisible(true);
    }

    _updateStatusDisplay() {
        const effect = StatusEffectSystem.getActive(this._player);
        if (!effect) {
            this._statusBadgeBg?.setVisible(false);
            this._statusBadgeTx?.setVisible(false);
            return;
        }
        this._statusBadgeBg?.setFillStyle(effect.bg).setStrokeStyle(1, parseInt(effect.color.replace('#',''), 16), 0.8).setVisible(true);
        this._statusBadgeTx?.setText(`⚠ ${effect.name.toUpperCase()} · ${effect.desc}`).setColor(effect.color).setVisible(true);
    }

    _spawnElementalBanner(advantage, multiplier) {
        const W = 544;
        const isSuper = advantage === 'super';
        const label = isSuper
            ? `⚡ SUPER EFICAZ!  ×${multiplier.toFixed(1)} ⚡`
            : `🛡 POUCO EFICAZ  ×${multiplier.toFixed(1)}`;
        const color = isSuper ? '#ffcc00' : '#6699cc';
        const size  = isSuper ? '20px' : '15px';

        const txt = this.add.text(W / 2, 92, label, {
            fontSize: size, color, fontFamily: 'Courier New', fontStyle: 'bold',
            stroke: '#000000', strokeThickness: 4,
        }).setOrigin(0.5, 0.5).setAlpha(0).setDepth(60);

        this.tweens.add({
            targets: txt, alpha: 1, y: isSuper ? 82 : 86,
            duration: 180, ease: 'Back.Out',
            onComplete: () => {
                this.tweens.add({
                    targets: txt, alpha: 0, y: isSuper ? 62 : 70,
                    delay: 500, duration: 400, ease: 'Quad.In',
                    onComplete: () => txt.destroy(),
                });
            },
        });
    }

    // ─── FEVER MODE ───────────────────────────────────────────────────────────

    _updateFeverMode(active) {
        if (this._feverActive === active) return;
        this._feverActive = active;
        this._feverFrame.clear();

        if (active) {
            Sound.fever();
            Music.setFever(true);
            this.cameras.main.flash(400, 255, 215, 0, 0.2);
            this._renderFeverFrame();
            this._feverTimer = this.time.addEvent({
                delay: 100,
                loop: true,
                callback: () => this._renderFeverFrame()
            });
        } else {
            Music.setFever(false);
            if (this._feverTimer) this._feverTimer.remove();
        }
    }

    _renderFeverFrame() {
        const W = 544, H = 480;
        const g = this._feverFrame;
        g.clear();
        
        const colors = [0xffd700, 0xff8800, 0xff3300];
        const thickness = 3 + Math.random() * 2;
        
        colors.forEach((col, i) => {
            const offset = i * 2;
            g.lineStyle(thickness, col, 0.4 - i * 0.1);
            g.strokeRect(offset, offset, W - offset * 2, H - offset * 2);
        });
    }

    _spawnFeverText() {
        const W = 544;
        const txt = this.add.text(W / 2, 140, '🔥 MODO FERVURA ATIVO 🔥', {
            fontSize: '22px', color: '#ffcc00', fontFamily: 'Courier New', fontStyle: 'bold',
            stroke: '#ff3300', strokeThickness: 6
        }).setOrigin(0.5).setDepth(160).setScale(0);

        this.tweens.add({
            targets: txt,
            scale: 1.2,
            duration: 300,
            ease: 'Back.easeOut',
            onComplete: () => {
                this.tweens.add({
                    targets: txt,
                    y: 110,
                    alpha: 0,
                    delay: 800,
                    duration: 500,
                    onComplete: () => txt.destroy()
                });
            }
        });

        this.addMsg('COMBO! Modo Fervura ativado: Bônus de XP e Ouro!', 'levelup');
    }

    addMsg(msg, type) { EventBus.emit('chat', { msg, type }); }

    // ─── BAR RENDERING ────────────────────────────────────────────────────────

    _drawBar(g, x, y, w, h, pct, baseColor, dangerColor) {
        const color  = pct < 0.3 ? dangerColor : baseColor;
        const filled = Math.max(0, Math.floor(w * pct));
        g.fillStyle(0x0a0008);       g.fillRect(x, y, w, h);
        if (filled > 0) {
            g.fillStyle(color, 0.85); g.fillRect(x, y, filled, h);
            g.fillStyle(0xffffff, 0.18); g.fillRect(x, y, filled, Math.ceil(h * 0.4));
        }
        // Tick marks at 25%, 50%, 75%
        g.fillStyle(0x000000, 0.4);
        [0.25, 0.5, 0.75].forEach(t => { const tx = x + Math.floor(w * t); g.fillRect(tx, y, 1, h); });
        // Border
        g.lineStyle(1, color, 0.35); g.strokeRect(x, y, w, h);
    }

    _updateMonsterBar() {
        const pct = Math.max(0, this._monsterHp / this._monsterDef.maxHp);
        const g   = this._mHpGfx;
        g.clear();
        this._drawBar(g, 116, 98, 144, 11, pct, 0xee3333, 0xff0000);
        this._mHpTxt.setText(`${this._monsterHp} / ${this._monsterDef.maxHp}`);
        // Pulse danger when low
        if (pct < 0.3 && this._monsterSprite && !this._dangerPulse) {
            this._dangerPulse = this.tweens.add({ targets: this._monsterSprite, alpha: 0.6, duration: 300, yoyo: true, repeat: -1 });
        } else if (pct >= 0.3 && this._dangerPulse) {
            this._dangerPulse.stop(); this._dangerPulse = null;
            if (this._monsterSprite) this._monsterSprite.setAlpha(1);
        }
    }

    _updatePlayerBars() {
        const p = this._player;
        const g = this._pVitalsGfx;
        g.clear();
        const hpPct  = Math.max(0, p.hp / p.maxHp);
        const focPct = Math.max(0, p.focus / p.maxFocus);
        this._drawBar(g, 286, 95,  134, 11, hpPct,  0x22cc55, 0xff3333);
        this._drawBar(g, 286, 123, 134, 11, focPct, 0x4488ff, 0x2244aa);
        this._pHpTxt?.setText(`${p.hp}/${p.maxHp}`);
        this._pFocTxt?.setText(`${p.focus}/${p.maxFocus}`);
    }

    // ─── ACTIONS ──────────────────────────────────────────────────────────────

    _useHint() {
        if (StatusEffectSystem.isHintBlocked(this._player)) {
            this._explTxt.setText('❄ CONGELADO! Dica bloqueada neste turno.');
            return;
        }
        if (!this._currentQ?.hint) {
            this._explTxt.setText('Nenhuma dica disponível para esta questão.');
            return;
        }
        const hintCost = this._relicEffect?.type === 'free_hints' ? 0 : 10;
        if (this._player.focus < hintCost) {
            this._explTxt.setText('Foco insuficiente para dica! (Necessário: 10)');
            return;
        }
        this._player.focus -= hintCost;
        this._updatePlayerBars();
        EventBus.emit('player-hp-change', { player: this._player });
        Sound.hint();
        const suffix = hintCost === 0 ? ' [Prisma da Clareza]' : '';
        this._explTxt.setText(`Dica: ${this._currentQ.hint}${suffix}`);
    }

    _flee() {
        const lost = Math.floor((this._player.xp || 0) * FLEE_XP_PENALTY);
        this._showFleeConfirm(lost, () => {
            this._player.xp = Math.max(0, (this._player.xp || 0) - lost);
            EventBus.emit('player-xp-change', { player: this._player });
            EventBus.emit('chat', { msg: `Você fugiu e perdeu ${lost} XP.`, type: 'error' });
            this._endCombat('flee');
        });
    }

    _showFleeConfirm(lost, onConfirm) {
        const W = 544, H = 480;
        this._answerLock = true;
        this._fleeConfirmOpen = true;
        // Ao cancelar, restaura o estado anterior: se a fuga foi aberta durante
        // a pausa da correção, o lock continua até o jogador confirmar a leitura
        const closeCancel = () => {
            this._fleeConfirmOpen = false;
            this._answerLock = this._awaitContinue;
            this.input.keyboard.off('keydown', escKey);
        };
        const c = this.add.container(0, 0).setDepth(200);
        // Interativo para engolir cliques nos botões que ficam embaixo
        c.add(this.add.rectangle(0, 0, W, H, 0x000000, 0.7).setOrigin(0, 0).setInteractive());
        const pw = 320, ph = 148;
        const px = (W - pw) / 2, py = (H - ph) / 2;
        c.add(this.add.rectangle(px, py, pw, ph, 0x180808, 1).setOrigin(0, 0).setStrokeStyle(2, 0xaa3322, 0.8));
        c.add(this.add.rectangle(px, py, pw, 3, 0xaa3322, 0.9).setOrigin(0, 0));
        c.add(this.add.text(W / 2, py + 14, '⊗  CONFIRMAR FUGA', {
            fontSize: '15px', color: '#ee6644', fontFamily: 'Courier New', fontStyle: 'bold',
            stroke: '#000000', strokeThickness: 3,
        }).setOrigin(0.5, 0));
        const fleeWarn = this._gauntletInfo
            ? `Fugir custa ${Math.round(FLEE_XP_PENALTY * 100)}% do XP atual (−${lost} XP)\ne ENCERRA O JULGAMENTO`
            : `Fugir custa ${Math.round(FLEE_XP_PENALTY * 100)}% do XP atual\n−${lost} XP serão perdidos`;
        c.add(this.add.text(W / 2, py + 44, fleeWarn, {
            fontSize: '12px', color: '#ccaa99', fontFamily: 'Courier New', align: 'center',
        }).setOrigin(0.5, 0));
        const yesBg = this.add.rectangle(px + 20, py + 100, 128, 30, 0x2a0808, 1)
            .setOrigin(0, 0).setStrokeStyle(1, 0xcc4433, 0.7).setInteractive()
            .on('pointerover', () => yesBg.setFillStyle(0x3a1010))
            .on('pointerout',  () => yesBg.setFillStyle(0x2a0808))
            .on('pointerdown', () => {
                this._fleeConfirmOpen = false;
                this.input.keyboard.off('keydown', escKey);
                c.destroy();
                onConfirm();
            });
        c.add([yesBg, this.add.text(px + 84, py + 115, '⊗  FUGIR', {
            fontSize: '13px', color: '#ee5533', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5, 0.5)]);
        const noBg = this.add.rectangle(px + pw - 148, py + 100, 128, 30, 0x081808, 1)
            .setOrigin(0, 0).setStrokeStyle(1, 0x33aa55, 0.7).setInteractive()
            .on('pointerover', () => noBg.setFillStyle(0x102818))
            .on('pointerout',  () => noBg.setFillStyle(0x081808))
            .on('pointerdown', () => { c.destroy(); closeCancel(); });
        c.add([noBg, this.add.text(px + pw - 84, py + 115, '✗  FICAR E LUTAR', {
            fontSize: '12px', color: '#55cc77', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5, 0.5)]);
        const escKey = (e) => {
            if (e.key === 'Escape') { c.destroy(); closeCancel(); }
        };
        this.input.keyboard.on('keydown', escKey);
    }

    // ─── COMBAT END ───────────────────────────────────────────────────────────

    _endCombat(outcome) {
        // Vitória ou derrota no meio de um desafio: o jogador ainda precisa ver
        // o veredito e o gabarito antes de o combate encerrar.
        if (CodeEditor.isOpen()) {
            this._concludeCodeTurn(outcome);
            return;
        }
        Music.setFever(false);
        StatusEffectSystem.clear(this._player);
        let xpGained = 0;
        let goldGained = 0;
        const lootNames = [];
        let lootIds = [];
        let bookIds = [];

        if (outcome === 'win') {
            const isElite = !!this._monsterDef.isElite || this._monsterDef.name.startsWith('Elite');
            const isShiny = !!this._monsterDef.isShiny;
            const feverReached = this._maxStreak >= 5;
            let baseXpReward = this._relicEffect?.type === 'xp_multiplier'
                ? Math.floor(this._monsterDef.xpReward * this._relicEffect.value)
                : this._monsterDef.xpReward;
            
            // FEVER BONUS: +50% XP if fever was active at least once or based on max streak
            if (this._maxStreak >= 5) {
                baseXpReward = Math.floor(baseXpReward * 1.5);
            }

            // Bônus passivo do Outlier evoluído
            const compBonus = CompanionSystem.xpBonus(
                this._player.companionStage || CompanionSystem.stage(this._player));
            if (compBonus > 0) baseXpReward = Math.floor(baseXpReward * (1 + compBonus));

            xpGained = awardXP(this._player, baseXpReward);

            // Relic: streak_xp_double — if best streak hit threshold, double the XP
            if (this._relicEffect?.type === 'streak_xp_double' && this._maxStreak >= this._relicEffect.value) {
                const bonusXp = xpGained;
                xpGained += bonusXp;
                awardXP(this._player, bonusXp);
                EventBus.emit('chat', { msg: `{{level:COROA DAS TREVAS!}} Streak de ${this._maxStreak}+ acertos — XP dobrado!`, type: 'levelup' });
            }
            
            // Base gold
            goldGained = this._monsterDef.goldReward || 0;

            // FEVER BONUS: +50% Gold
            if (this._maxStreak >= 5) {
                goldGained = Math.floor(goldGained * 1.5);
            }
            
            // STREAK BONUS: 20% extra gold per streak point above 2
            if (this._streak >= 3) {
                const multiplier = 1 + (this._streak - 2) * 0.2;
                const bonus = Math.floor(goldGained * (multiplier - 1));
                goldGained += bonus;
                EventBus.emit('chat', { msg: `{{gold:STREAK BONUS!}} +${bonus} moedas extras!`, type: 'loot' });
            }

            this._player.gold = (this._player.gold || 0) + goldGained;

            // Loot rolls: Elites/Cintilantes roll twice; Fever Mode grants +1 roll
            const rolls = (isElite || isShiny ? 2 : 1) + (feverReached ? 1 : 0);
            for (let i = 0; i < rolls; i++) {
                const batch = CombatSystem.rollDrops(this._monsterDef);
                lootIds.push(...batch);
            }

            // Forge material drop, tied to the monster's element.
            // Base 25%, +1%/nível de maestria do elemento (cap +15%), dobrado em Fervura.
            // Elite garante 1; Cintilante garante 2.
            const elemId = ELEMENTS[this._monsterDef.element] ? this._monsterDef.element : 'normal';
            const masteryLvl = this._player.elementalMastery?.[elemId]?.level || 1;
            let matChance = 0.25 + Math.min(0.15, 0.01 * (masteryLvl - 1));
            if (feverReached) matChance *= 2;
            let matQty = 0;
            if (isShiny)      matQty = 2;
            else if (isElite) matQty = 1 + (Math.random() < matChance ? 1 : 0);
            else if (Math.random() < matChance) matQty = 1;
            for (let i = 0; i < matQty; i++) lootIds.push(`essence_${elemId}`);

            const RARITY_TAG = { legendary: 'legend', epic: 'epic', rare: 'rare', uncommon: 'loot', common: 'mute' };
            for (const itemId of lootIds) {
                CombatSystem.addToInventory(this._player, itemId);
                const itemDef = ITEMS[itemId];
                if (itemDef) {
                    const tag = RARITY_TAG[itemDef.rarity] || 'loot';
                    lootNames.push(`{{${tag}:${itemDef.name}}}`);
                }
            }

            bookIds = BookSystem.rollBookDrops(this._monsterDef.id.replace('Elite ', ''));
            for (const bookId of bookIds) {
                BookSystem.addBook(this._player, bookId);
                const b = BOOKS[bookId];
                if (b) lootNames.push(`{{hint:Livro: ${b.title}}}`);
            }

            EventBus.emit('player-stats-changed', { player: this._player });
        }

        this.registry.set('player', this._player);

        if (outcome === 'win' && (lootIds.length > 0 || bookIds.length > 0)) {
            this._showVictoryPopup(xpGained, goldGained, lootIds, bookIds, () => {
                this._finishCombat(outcome, xpGained, lootNames);
            });
        } else {
            this._finishCombat(outcome, xpGained, lootNames);
        }
    }

    _finishCombat(outcome, xpGained, lootNames) {
        this.scene.stop('Combat');
        EventBus.emit('combat-end', {
            outcome,
            instanceId: this._instanceId,
            xpGained,
            loot: lootNames,
            playerData: this._player,
            maxStreak:    this._maxStreak,
            allCorrect:   this._wrongCount === 0,
            feverReached: this._maxStreak >= 5,
            isElite:      !!this._monsterDef.isElite || this._monsterDef.name.startsWith('Elite'),
            isMimic:      this._monsterDef.id === 'mimic',
        });
    }

    _showVictoryPopup(xp, gold, lootIds, bookIds, onContinue) {
        const W = 544, H = 480;
        const totalRows = Math.min(lootIds.length + bookIds.length, 7);
        this.add.rectangle(0, 0, W, H, 0x000000, 0.85).setOrigin(0, 0).setDepth(100);

        const panelW = 380, panelH = 80 + totalRows * 22 + 60;
        const px2 = (W - panelW) / 2;
        const py2 = (H - panelH) / 2;

        const panel = this.add.rectangle(px2, py2, panelW, panelH, 0x0d0a03, 1).setOrigin(0, 0).setDepth(101);
        panel.setStrokeStyle(2, 0xffd700);

        const title = this.add.text(W / 2, py2 + 12, 'VITÓRIA!', {
            fontSize: '22px', color: '#ffd700', fontFamily: 'Courier New', fontStyle: 'bold',
            stroke: '#000000', strokeThickness: 4
        }).setOrigin(0.5, 0).setDepth(102).setScale(0);
        this.tweens.add({ targets: title, scale: 1, duration: 400, ease: 'Back.easeOut' });

        const stats = this.add.text(W / 2, py2 + 38, `+${xp} XP    +${gold} Ouro`, {
            fontSize: '14px', color: '#ffaa44', fontFamily: 'Courier New',
        }).setOrigin(0.5, 0).setDepth(102).setAlpha(0);
        this.tweens.add({ targets: stats, alpha: 1, y: py2 + 42, duration: 300, delay: 300 });

        const itemHeader = this.add.text(W / 2, py2 + 62, 'ITENS OBTIDOS:', {
            fontSize: '11px', color: '#888888', fontFamily: 'Courier New',
        }).setOrigin(0.5, 0).setDepth(102).setAlpha(0);
        this.tweens.add({ targets: itemHeader, alpha: 1, duration: 300, delay: 500 });

        let rowIdx = 0;
        const itemsToProcess = [
            ...lootIds.slice(0, 7 - bookIds.length).map(id => ({ type: 'item', id })),
            ...bookIds.slice(0, 7).map(id => ({ type: 'book', id }))
        ].slice(0, 7);

        itemsToProcess.forEach((entry, i) => {
            const yLine = py2 + 82 + rowIdx * 22;
            const container = this.add.container(px2 + 20, yLine).setDepth(102).setAlpha(0);
            
            if (entry.type === 'item') {
                const item = ITEMS[entry.id];
                if (!item) return;
                const colorHex = RARITY_COLORS[item.rarity] || '#cccccc';
                const isRare = item.rarity === 'legendary' || item.rarity === 'epic';

                const bg = this.add.rectangle(0, 0, panelW - 40, 18, 0x111111, 1).setOrigin(0, 0);
                if (isRare) bg.setStrokeStyle(1, parseInt(colorHex.replace('#',''), 16), 0.5);

                const glow = attachRarityGlow(this, 12, 9, 9, item.rarity);
                const icon = this.add.image(12, 9, item.icon || 'item_potion_red').setScale(0.6);
                const name = this.add.text(26, 9, item.name, {
                    fontSize: '12px', color: colorHex, fontFamily: 'Courier New', fontStyle: isRare ? 'bold' : 'normal'
                }).setOrigin(0, 0.5);
                const rarityTxt = this.add.text(panelW - 48, 9, (item.rarity || 'common').toUpperCase(), {
                    fontSize: '10px', color: '#666666', fontFamily: 'Courier New'
                }).setOrigin(1, 0.5);

                container.add([bg, ...(glow ? [glow] : []), icon, name, rarityTxt]);

                // JACKPOT EFFECT for Rare Items
                if (isRare) {
                    this.time.delayedCall(700 + i * 150, () => {
                        Sound.critical();
                        const flash = this.add.rectangle(px2 + 20, yLine, panelW - 40, 18, 0xffffff, 0.4)
                            .setOrigin(0, 0).setDepth(103);
                        this.tweens.add({ targets: flash, alpha: 0, duration: 400, onComplete: () => flash.destroy() });
                        this.tweens.add({ targets: container, scale: 1.05, duration: 100, yoyo: true });
                    });
                }
            } else {
                const book = BOOKS[entry.id];
                if (!book) return;
                const imp = BOOK_IMPORTANCE[book.importance] || BOOK_IMPORTANCE.normal;
                const bg = this.add.rectangle(0, 0, panelW - 40, 18, 0x1a1108, 1).setOrigin(0, 0);
                const name = this.add.text(8, 9, `[Livro] ${book.title}`, {
                    fontSize: '11px', color: imp.hex, fontFamily: 'Courier New', fontStyle: 'bold'
                }).setOrigin(0, 0.5);
                const impTxt = this.add.text(panelW - 48, 9, imp.name.toUpperCase(), {
                    fontSize: '10px', color: imp.hex, fontFamily: 'Courier New'
                }).setOrigin(1, 0.5);
                container.add([bg, name, impTxt]);
            }

            this.tweens.add({
                targets: container,
                alpha: 1,
                x: px2 + 20,
                duration: 300,
                delay: 600 + i * 150,
                ease: 'Cubic.Out'
            });

            rowIdx++;
        });

        let continued = false;
        const safeContinue = () => { if (!continued) { continued = true; onContinue(); } };

        // Largura acomoda o texto (18 chars × ~7,8px a 13px Courier ≈ 140px)
        const btnY = py2 + panelH - 36;
        const btnBg = this.add.rectangle(W / 2 - 88, btnY, 176, 28, 0x1a3a1a, 1).setOrigin(0, 0).setDepth(102)
            .setAlpha(0).setInteractive()
            .on('pointerover', () => btnBg.setFillStyle(0x2a5a2a))
            .on('pointerout',  () => btnBg.setFillStyle(0x1a3a1a))
            .on('pointerdown', () => safeContinue());
        const btnTx = this.add.text(W / 2, btnY + 14, 'CONTINUAR  [ENTER]', {
            fontSize: '13px', color: '#88ff88', fontFamily: 'Courier New',
        }).setOrigin(0.5, 0.5).setDepth(102).setAlpha(0);

        this.tweens.add({ targets: [btnBg, btnTx], alpha: 1, duration: 500, delay: 1500 });

        this.time.delayedCall(1600, () => {
            const handler = (e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                    this.input.keyboard.off('keydown', handler);
                    safeContinue();
                }
            };
            this.input.keyboard.on('keydown', handler);
        });

        // Auto-continue after 8s as fallback
        this.time.delayedCall(8000, () => safeContinue());
    }

    shutdown() {
        if (CodeEditor.isOpen()) CodeEditor.close();
        this._restoreKeyboard();
        this.input.keyboard.removeAllListeners();
    }
}
