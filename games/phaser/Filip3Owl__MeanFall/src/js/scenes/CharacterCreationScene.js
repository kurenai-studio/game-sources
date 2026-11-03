import { GENDERS, HAIR_COLORS, ROBE_COLORS, SKIN_TONES, APPEARANCE_DEFAULTS } from '../data/appearance.js';
import { buildPlayerSprite } from '../utils/Draw.js';
import { PLAYER_DEFAULTS, DIFFICULTIES } from '../constants.js';

const W = 544, H = 480;
const PANEL_W = 158;
const R_X     = PANEL_W + 10;
const R_W     = W - R_X - 8;
const R_CX    = R_X + R_W / 2;
const PREV_CX = PANEL_W / 2;
const NAV_Y   = H - 44;

const CLASSES = [
    { id: 'mage',     name: 'Mago',       icon: '✦', color: 0x6644ff, dark: 0x100a28, stats: 'INT +3 · Foco +15', lore: 'Domina teoria e fórmulas',    apply: d => { d.intelligence += 3; d.maxFocus += 15; d.focus = d.maxFocus; } },
    { id: 'warrior',  name: 'Guerreiro',  icon: '⚔', color: 0xff5533, dark: 0x28100a, stats: 'FOR +3 · HP +20',   lore: 'Resiste em combates longos',  apply: d => { d.strength += 3; d.maxHp += 20; d.hp = d.maxHp; } },
    { id: 'explorer', name: 'Explorador', icon: '◈', color: 0x33cc66, dark: 0x0a2814, stats: 'AGI +3 · Bônus Fuga', lore: 'Aprende rápido no campo',  apply: d => { d.agility += 3; } },
];

export class CharacterCreationScene extends Phaser.Scene {
    constructor() { super('CharacterCreation'); }

    create() {
        this._appearance = { ...APPEARANCE_DEFAULTS };
        this._difficulty = 'medium';
        this._class      = 'mage';
        this._name       = '';
        this._nameCursor = true;
        this._step       = 0;

        this._buildBackground();
        this._buildLeftPanel();
        this._buildStepUI();
        this._buildNavBar();

        this._refreshSprite();
        this._renderNameInput();
        this._refreshSwatches();
        this._refreshClassCards();
        this._refreshDiffPills();
        this._refreshStatBars();
        if (this._genderTx) this._genderTx.setText(GENDERS.find(g => g.id === this._appearance.gender)?.name || '?');

        this._showStep(0);

        this.time.addEvent({ delay: 530, loop: true, callback: () => {
            this._nameCursor = !this._nameCursor;
            if (this._step === 0) this._renderNameInput();
        }});
        this.input.keyboard.on('keydown', this._onKey.bind(this));
        this.cameras.main.fadeIn(400, 0, 0, 0);
    }

    // ── Background ─────────────────────────────────────────────────────────────

    _buildBackground() {
        this.add.rectangle(0, 0, W, H, 0x020108).setOrigin(0);
        [[W*.15,H*.35,140,0x2200aa,.06,3800],[W*.82,H*.65,120,0x002288,.05,4200],[W*.50,H*.85,170,0x220055,.04,3500]]
            .forEach(([nx,ny,nr,nc,na,dur]) => {
                const g = this.add.graphics(); g.fillStyle(nc, na); g.fillCircle(nx, ny, nr);
                this.tweens.add({ targets: g, alpha: { from: .5, to: 1.3 }, duration: dur, yoyo: true, repeat: -1, delay: Math.random() * 1800 });
            });
        for (let i = 0; i < 80; i++) {
            const s = this.add.rectangle(Math.random() * W, Math.random() * H, 1, 1, 0xffffff, Math.random() * .4 + .08);
            this.tweens.add({ targets: s, alpha: .04, duration: 1400 + Math.random() * 2200, yoyo: true, repeat: -1, delay: Math.random() * 2000 });
        }
        const dg = this.add.graphics().setDepth(2);
        dg.lineStyle(1, 0xd4af37, 0.2);
        dg.lineBetween(PANEL_W, 0, PANEL_W, H);
    }

    // ── Left panel (always visible) ────────────────────────────────────────────

    _buildLeftPanel() {
        const FW = 100, FH = 128, FY = 108;
        const bot = FY + FH / 2;

        this.add.rectangle(PREV_CX, FY, FW, FH, 0x060412).setDepth(2).setStrokeStyle(1, 0xd4af37, 0.4);
        this._previewAura = this.add.circle(PREV_CX, FY, 32, 0x6644ff, 0.12).setDepth(2);
        this.tweens.add({ targets: this._previewAura, alpha: { from: .08, to: .28 }, scale: { from: 1, to: 1.14 }, duration: 1300, yoyo: true, repeat: -1 });
        this._previewSprite = this.add.image(PREV_CX, FY, 'sprite_player').setScale(3.5).setDepth(3);

        this._namePreview  = this.add.text(PREV_CX, bot + 8,  'Aventureiro',  { fontSize: '13px', color: '#f0e8d0', fontFamily: 'Courier New', fontStyle: 'bold', align: 'center' }).setOrigin(0.5, 0).setDepth(3);
        this._classBadge   = this.add.text(PREV_CX, bot + 26, 'MAGO',         { fontSize: '12px', color: '#8877ff', fontFamily: 'Courier New', fontStyle: 'bold' }).setOrigin(0.5, 0).setDepth(3);
        this._classBonusTx = this.add.text(PREV_CX, bot + 40, 'INT+3·FOCO+15',{ fontSize: '10px', color: '#9999bb', fontFamily: 'Courier New' }).setOrigin(0.5, 0).setDepth(3);

        const sg = this.add.graphics().setDepth(2);
        sg.lineStyle(1, 0xd4af37, 0.12);
        sg.lineBetween(10, bot + 55, PANEL_W - 8, bot + 55);

        const STATS = [{ key:'str', label:'FOR', color:0xff5533 }, { key:'int', label:'INT', color:0x6644ff }, { key:'agi', label:'AGI', color:0x33cc66 }, { key:'vit', label:'VIT', color:0xffbb33 }];
        const sbX = 10, barW = 88, sbY0 = bot + 64;
        this._statBars = {};
        STATS.forEach(({ key, label, color }, i) => {
            const sy = sbY0 + i * 22;
            this.add.text(sbX, sy, label, { fontSize: '11px', color: '#aaaacc', fontFamily: 'Courier New' }).setOrigin(0, 0.5).setDepth(3);
            this.add.rectangle(sbX + 28, sy, barW, 6, 0x08061a).setOrigin(0, 0.5).setDepth(2).setStrokeStyle(1, 0x181630);
            const fill = this.add.rectangle(sbX + 28, sy, 1, 6, color, 0.8).setOrigin(0, 0.5).setDepth(3);
            this._statBars[key] = { fill, barW };
        });

        this._diffBadge = this.add.text(PREV_CX, H - 18, 'MÉDIO', { fontSize: '11px', color: '#ffcc44', fontFamily: 'Courier New', fontStyle: 'bold' }).setOrigin(0.5).setDepth(3);

        this.add.text(12, 16, '← MENU', { fontSize: '12px', color: '#888877', fontFamily: 'Courier New' })
            .setOrigin(0, 0.5).setDepth(6).setInteractive({ useHandCursor: true })
            .on('pointerover', function() { this.setColor('#d4af37'); })
            .on('pointerout',  function() { this.setColor('#888877'); })
            .on('pointerdown', () => this._backToMenu());
    }

    // ── Step containers ────────────────────────────────────────────────────────

    _buildStepUI() {
        this._stepContainers = [
            this._buildStep0(),
            this._buildStep1(),
            this._buildStep2(),
            this._buildStep3(),
        ];

        const dotGap = 18, dotsX = R_CX - dotGap * 1.5;
        this._dots = Array.from({ length: 4 }, (_, i) =>
            this.add.circle(dotsX + i * dotGap, 18, 4, 0x333355).setDepth(6)
        );

        this._stepTitle = this.add.text(R_CX, 36, '', {
            fontSize: '15px', color: '#d4af37', fontFamily: 'Courier New', fontStyle: 'bold', letterSpacing: 3,
        }).setOrigin(0.5).setDepth(6);

        const hg = this.add.graphics().setDepth(5);
        hg.lineStyle(1, 0xd4af37, 0.15);
        hg.lineBetween(R_X, 50, W - 4, 50);
    }

    _buildStep0() {
        const c = this.add.container(0, 0).setDepth(4).setVisible(false);
        const midY = 58 + (NAV_Y - 58) / 2;

        c.add(this.add.text(R_CX, midY - 92, 'SEU NOME', { fontSize: '13px', color: '#9999bb', fontFamily: 'Courier New', letterSpacing: 2 }).setOrigin(0.5));

        const inW = R_W - 16, inH = 42;
        const inBg = this.add.rectangle(R_CX, midY - 58, inW, inH, 0x07041a).setStrokeStyle(1, 0xd4af37, 0.7).setInteractive({ useHandCursor: true });
        this._nameText = this.add.text(R_CX - inW / 2 + 12, midY - 58, '', { fontSize: '17px', color: '#f0e8d0', fontFamily: 'Courier New' }).setOrigin(0, 0.5);
        c.add([inBg, this._nameText]);

        c.add(this.add.text(R_CX, midY + 12, 'GÊNERO', { fontSize: '13px', color: '#9999bb', fontFamily: 'Courier New', letterSpacing: 2 }).setOrigin(0.5));

        this._genderTx = this.add.text(R_CX, midY + 46, '', { fontSize: '16px', color: '#f0e8d0', fontFamily: 'Courier New', fontStyle: 'bold' }).setOrigin(0.5);
        c.add(this._genderTx);

        const aStyle = { fontSize: '22px', color: '#8877cc', fontFamily: 'Courier New', fontStyle: 'bold' };
        const mkArrow = (ax, ch, cb) => {
            const btn = this.add.rectangle(ax, midY + 46, 32, 32, 0x0d0a1e).setStrokeStyle(1, 0x4433aa, 0.5).setInteractive({ useHandCursor: true })
                .on('pointerover', () => btn.setFillStyle(0x1a1630))
                .on('pointerout',  () => btn.setFillStyle(0x0d0a1e))
                .on('pointerdown', cb);
            c.add([btn, this.add.text(ax, midY + 46, ch, aStyle).setOrigin(0.5)]);
        };
        mkArrow(R_CX - 80, '‹', () => this._cycleGender(-1));
        mkArrow(R_CX + 80, '›', () => this._cycleGender(+1));
        return c;
    }

    _buildStep1() {
        const c = this.add.container(0, 0).setDepth(4).setVisible(false);
        const rows = [
            { label: 'PELE',   list: SKIN_TONES,  field: 'skin' },
            { label: 'CABELO', list: HAIR_COLORS, field: 'hair' },
            { label: 'TÚNICA', list: ROBE_COLORS, field: 'robe' },
        ];
        this._allSwatches = [];
        const startY = 58 + Math.floor((NAV_Y - 58 - 3 * 68) / 2) + 18;

        rows.forEach(({ label, list, field }, rowIdx) => {
            const y = startY + rowIdx * 68;
            c.add(this.add.text(R_X + 4, y, label, { fontSize: '13px', color: '#9999bb', fontFamily: 'Courier New', letterSpacing: 2 }).setOrigin(0, 0.5));
            const SW = 22, GAP = 6, sx = R_X + 76;
            list.forEach((item, i) => {
                const cx = sx + i * (SW + GAP) + SW / 2;
                const sq = this.add.rectangle(cx, y, SW, SW, item.hex).setInteractive({ useHandCursor: true })
                    .on('pointerdown', () => { this._appearance[field] = item.id; this._refreshSprite(); this._refreshSwatches(); });
                const ring = this.add.rectangle(cx, y, SW + 6, SW + 6, 0, 0).setStrokeStyle(1, 0x556677, 0.5);
                c.add([ring, sq]);
                this._allSwatches.push({ item, sq, ring, field });
            });
        });
        return c;
    }

    _buildStep2() {
        const c = this.add.container(0, 0).setDepth(4).setVisible(false);
        this._classCards = [];
        const cardW = Math.floor((R_W - 14) / 3);
        const cardH = 165;
        const startY = 58 + Math.floor((NAV_Y - 58 - cardH) / 2);

        CLASSES.forEach((cls, i) => {
            const cx  = R_X + 3 + i * (cardW + 7);
            const hex = '#' + cls.color.toString(16).padStart(6, '0');
            const bg  = this.add.rectangle(cx, startY, cardW, cardH, cls.dark).setOrigin(0, 0).setStrokeStyle(1, cls.color, 0.4)
                .setInteractive({ useHandCursor: true })
                .on('pointerover', () => { if (this._class !== cls.id) bg.setFillStyle(cls.dark + 0x060206); })
                .on('pointerout',  () => { if (this._class !== cls.id) bg.setFillStyle(cls.dark); })
                .on('pointerdown', () => this._selectClass(cls.id));
            const mx = cx + cardW / 2;
            c.add([
                bg,
                this.add.text(mx, startY + 24,  cls.icon,               { fontSize: '24px', color: hex,       fontFamily: 'Courier New' }).setOrigin(0.5),
                this.add.text(mx, startY + 56,  cls.name.toUpperCase(),  { fontSize: '12px', color: '#f0e8d0', fontFamily: 'Courier New', fontStyle: 'bold', letterSpacing: 1 }).setOrigin(0.5),
                this.add.text(mx, startY + 76,  cls.stats,               { fontSize: '11px', color: hex,       fontFamily: 'Courier New', fontStyle: 'bold' }).setOrigin(0.5),
                this.add.text(mx, startY + 114, cls.lore,                { fontSize: '11px', color: '#9999bb', fontFamily: 'Courier New', align: 'center', wordWrap: { width: cardW - 10 } }).setOrigin(0.5),
            ]);
            this._classCards.push({ id: cls.id, bg, color: cls.color, dark: cls.dark });
        });
        return c;
    }

    _buildStep3() {
        const c = this.add.container(0, 0).setDepth(4).setVisible(false);
        const diffIds = Object.keys(DIFFICULTIES);
        const pillW = Math.floor((R_W - 14) / 2);
        const pillH = 42;
        const startY = 62;
        this._diffPills = {};

        diffIds.forEach((id, i) => {
            const diff = DIFFICULTIES[id];
            const col  = parseInt(diff.color.replace('#', ''), 16);
            const px   = R_X + 3 + (i % 2) * (pillW + 8);
            const py   = startY + Math.floor(i / 2) * (pillH + 8);
            const pill = this.add.rectangle(px, py, pillW, pillH, 0x08061a).setOrigin(0, 0).setStrokeStyle(1, col, 0.35)
                .setInteractive({ useHandCursor: true }).on('pointerdown', () => this._selectDiff(id));
            const tx = this.add.text(px + pillW / 2, py + pillH / 2, diff.name, { fontSize: '13px', color: diff.color, fontFamily: 'Courier New', fontStyle: 'bold' }).setOrigin(0.5);
            c.add([pill, tx]);
            this._diffPills[id] = { pill, tx, col };
        });

        const descY = startY + Math.ceil(diffIds.length / 2) * (pillH + 8) + 16;
        this._diffDesc = this.add.text(R_CX, descY, '', { fontSize: '12px', color: '#aaaacc', fontFamily: 'Courier New', align: 'center', wordWrap: { width: R_W - 16 } }).setOrigin(0.5, 0);
        c.add(this._diffDesc);
        return c;
    }

    // ── Nav bar ─────────────────────────────────────────────────────────────────

    _buildNavBar() {
        const ng = this.add.graphics().setDepth(5);
        ng.lineStyle(1, 0xd4af37, 0.18);
        ng.lineBetween(R_X, NAV_Y - 10, W - 4, NAV_Y - 10);

        this._prevBtn = this.add.text(R_X + 6, NAV_Y + 10, '← ANTERIOR', { fontSize: '13px', color: '#9999bb', fontFamily: 'Courier New', fontStyle: 'bold' })
            .setOrigin(0, 0.5).setDepth(6).setInteractive({ useHandCursor: true })
            .on('pointerover', function() { this.setColor('#d4af37'); })
            .on('pointerout',  function() { this.setColor('#9999bb'); })
            .on('pointerdown', () => this._goStep(this._step - 1));

        this._nextBtn = this.add.text(W - 8, NAV_Y + 10, 'PRÓXIMO →', { fontSize: '13px', color: '#55ee77', fontFamily: 'Courier New', fontStyle: 'bold' })
            .setOrigin(1, 0.5).setDepth(6).setInteractive({ useHandCursor: true })
            .on('pointerover', function() { this.setColor('#88ffaa'); })
            .on('pointerout',  function() { this.setColor('#55ee77'); })
            .on('pointerdown', () => this._step < 3 ? this._goStep(this._step + 1) : this._confirm());

        this._nameWarning = this.add.text(R_CX, NAV_Y - 18, 'Digite um nome para continuar', { fontSize: '11px', color: '#ff5555', fontFamily: 'Courier New' })
            .setOrigin(0.5).setDepth(6).setVisible(false);
    }

    // ── Step logic ─────────────────────────────────────────────────────────────

    _showStep(n) {
        const LABELS = ['IDENTIDADE', 'APARÊNCIA', 'CLASSE', 'DIFICULDADE'];
        this._stepContainers.forEach((c, i) => { c.setVisible(i === n); if (i !== n) c.setAlpha(1); });
        this._stepContainers[n].setAlpha(0);
        this.tweens.add({ targets: this._stepContainers[n], alpha: 1, duration: 200, ease: 'Quad.Out' });
        this._dots.forEach((d, i) => d.setFillStyle(i <= n ? 0xd4af37 : 0x333355).setAlpha(i === n ? 1 : 0.7));
        this._stepTitle.setText(LABELS[n]);
        this._prevBtn.setVisible(n > 0);
        const last = n === 3;
        this._nextBtn.setText(last ? '⚔  INICIAR  ⚔' : 'PRÓXIMO →').setColor(last ? '#d4af37' : '#55ee77');
        this._nameWarning.setVisible(false);
    }

    _goStep(n) {
        if (n < 0 || n > 3) return;
        if (n > this._step && this._step === 0 && !this._name.trim()) {
            this._nameWarning.setVisible(true);
            return;
        }
        this._step = n;
        this._showStep(n);
    }

    // ── Refresh ────────────────────────────────────────────────────────────────

    _refreshSprite() {
        buildPlayerSprite(this, this._appearance);
        this._previewSprite?.setTexture('sprite_player');
        const cls = CLASSES.find(c => c.id === this._class);
        if (!cls) return;
        const hex = '#' + cls.color.toString(16).padStart(6, '0');
        this._classBadge?.setText(cls.name.toUpperCase()).setColor(hex);
        this._classBonusTx?.setText(cls.stats);
        this._tweenAuraColor(cls.color);
    }

    _tweenAuraColor(toColor) {
        if (this._auraColorTween) this._auraColorTween.stop();
        const from = Phaser.Display.Color.IntegerToColor(this._auraColor ?? toColor);
        const to   = Phaser.Display.Color.IntegerToColor(toColor);
        this._auraColor = toColor;
        this._auraColorTween = this.tweens.addCounter({
            from: 0, to: 100, duration: 350,
            onUpdate: tw => {
                const col = Phaser.Display.Color.Interpolate.ColorWithColor(from, to, 100, tw.getValue());
                this._previewAura?.setFillStyle(Phaser.Display.Color.GetColor(col.r, col.g, col.b), 0.13);
            },
            onComplete: () => { this._auraColorTween = null; },
        });
    }

    _renderNameInput() {
        this._nameText?.setText(this._name + (this._nameCursor ? '|' : ''));
        this._namePreview?.setText(this._name.trim() || 'Aventureiro');
    }

    _refreshSwatches() {
        for (const { item, sq, ring, field } of (this._allSwatches || [])) {
            const active = this._appearance[field] === item.id;
            ring.setStrokeStyle(active ? 2 : 1, active ? 0xd4af37 : 0x556677, active ? 1 : 0.5);
            sq.setAlpha(active ? 1 : 0.7);
        }
    }

    _refreshClassCards() {
        for (const { id, bg, color, dark } of (this._classCards || [])) {
            const active = id === this._class;
            bg.setFillStyle(active ? dark + 0x0c080e : dark);
            bg.setStrokeStyle(1, color, active ? 1 : 0.35);
        }
    }

    _refreshDiffPills() {
        const diff = DIFFICULTIES[this._difficulty];
        for (const [id, { pill, tx, col }] of Object.entries(this._diffPills || {})) {
            const active = id === this._difficulty;
            pill.setFillStyle(active ? 0x14103a : 0x08061a);
            pill.setStrokeStyle(1, col, active ? 1 : 0.3);
            tx.setAlpha(active ? 1 : 0.5);
        }
        if (this._diffDesc) {
            const fmt = v => `×${v.toFixed(1)}`;
            this._diffDesc.setText(`${diff.desc}\n\nDano: ${fmt(diff.monsterDamage)} · HP: ${fmt(diff.monsterHp)} · Recomp: ${fmt(diff.rewardMult)}`);
        }
        this._diffBadge?.setText(diff.name.toUpperCase()).setColor(diff.color);
    }

    _refreshStatBars() {
        const sim = { strength: 5, intelligence: 5, agility: 5, vitality: 5 };
        const cls = CLASSES.find(c => c.id === this._class);
        if (cls?.id === 'mage')     sim.intelligence += 3;
        if (cls?.id === 'warrior')  sim.strength     += 3;
        if (cls?.id === 'explorer') sim.agility      += 3;
        const map = { str: sim.strength, int: sim.intelligence, agi: sim.agility, vit: sim.vitality };
        for (const [key, val] of Object.entries(map)) {
            const bar = this._statBars?.[key];
            if (bar) this.tweens.add({ targets: bar.fill, width: Math.floor(bar.barW * Math.min(val / 9, 1)), duration: 200, ease: 'Quad.Out' });
        }
    }

    // ── Handlers ───────────────────────────────────────────────────────────────

    _selectClass(id) {
        this._class = id;
        this._refreshClassCards();
        this._refreshStatBars();
        this._refreshSprite();
    }

    _selectDiff(id) {
        this._difficulty = id;
        this._refreshDiffPills();
    }

    _cycleGender(dir) {
        const ids = GENDERS.map(g => g.id);
        const cur = ids.indexOf(this._appearance.gender);
        this._appearance.gender = ids[((cur + dir) % ids.length + ids.length) % ids.length];
        this._genderTx?.setText(GENDERS.find(g => g.id === this._appearance.gender)?.name || '?');
        this._refreshSprite();
    }

    _onKey(event) {
        const k = event.key;
        if (k === 'Escape') { this._backToMenu(); return; }
        if (k === 'Enter')  { this._step < 3 ? this._goStep(this._step + 1) : this._confirm(); return; }
        if (this._step === 0) {
            if (k === 'Backspace')                              { this._name = this._name.slice(0, -1); this._renderNameInput(); }
            else if (k === 'Tab')                               { this._cycleGender(+1); }
            else if (k.length === 1 && this._name.length < 16) { this._name += k; this._renderNameInput(); }
        }
    }

    _backToMenu() {
        this.cameras.main.fadeOut(350, 0, 0, 0);
        this.cameras.main.once('camerafadeoutcomplete', () => this.scene.start('MainMenu'));
    }

    // ── Confirm ────────────────────────────────────────────────────────────────

    _confirm() {
        const name = this._name.trim() || 'Aventureiro';
        const data = JSON.parse(JSON.stringify(PLAYER_DEFAULTS));
        data.name        = name;
        data.difficulty  = this._difficulty;
        data.appearance  = { ...this._appearance };
        data.playerClass = this._class;
        const cls = CLASSES.find(c => c.id === this._class);
        if (cls) cls.apply(data);
        this.registry.set('player', data);
        this.cameras.main.fadeOut(450, 0, 0, 0);
        this.cameras.main.once('camerafadeoutcomplete', () => { this.scene.start('World'); this.scene.launch('UI'); });
    }
}
