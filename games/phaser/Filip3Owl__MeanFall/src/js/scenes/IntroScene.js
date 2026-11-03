import { STORY } from '../data/lore.js';
import { layoutRichText } from '../utils/RichText.js';
import { Music } from '../utils/MusicSystem.js';
import { Sound } from '../utils/SoundSystem.js';

/**
 * IntroScene — cinematic paginated prologue.
 * Title card → 7 prologue slides (one line each, SPACE advances) → CharacterCreation.
 * ESC skips straight to CharacterCreation at any point.
 */

const W = 544, H = 480;
const LINES = STORY.prologueLines;

// Element icon shown per slide — maps the narrative arc of the prologue:
// world in order (normal) → distortion arrives (shadow) → hero rises (fire) → journey (earth) → destiny (water)
const SLIDE_ELEMENTS = [
    'icon_element_normal',  // 0 — "Há eras, o mundo seguia a Curva..."
    'icon_element_normal',  // 1 — "A Sociedade dos Estatísticos..."
    'icon_element_shadow',  // 2 — "Então veio a Distorção..."
    'icon_element_shadow',  // 3 — "Os monstros, antes raros..."
    'icon_element_fire',    // 4 — "Você é o último aprendiz..."
    'icon_element_earth',   // 5 — "Cada criatura derrotada é uma equação resolvida..."
    'icon_element_water',   // 6 — "O destino do mundo está na sua amostra..."
];

export class IntroScene extends Phaser.Scene {
    constructor() { super('Intro'); }

    create() {
        this._page        = -1;    // -1 = title card, 0‥N-1 = prologue slides
        this._busy        = false;
        this._done        = false;
        this._content     = [];    // game objects belonging to the current page
        this._autoTimer   = null;
        this._isTyping    = false;
        this._typingTimer = null;
        this._typingText  = null;
        this._richObjects = null;  // rich text objects waiting to be revealed

        this._buildAtmosphere();
        this._buildPermanentUI();
        this._showTitle();

        this.input.keyboard.on('keydown-SPACE',     () => this._advance());
        this.input.keyboard.on('keydown-ENTER',     () => this._advance());
        this.input.keyboard.on('keydown-ESC',       () => this._finish());
        this.input.keyboard.on('keydown-LEFT',      () => this._goBack());
        this.input.keyboard.on('keydown-BACKSPACE', () => this._goBack());
        this.input.on('pointerdown',                () => this._advance());

        // P1 — música ambiente
        Music.play('menu');

        // P4 — cleanup ao fechar a cena
        this.events.once('shutdown', () => {
            this.tweens.killAll();
            this.input.keyboard.removeAllListeners();
        });
    }

    // ── Atmosphere (permanent — survives page changes) ─────────────────────

    _buildAtmosphere() {
        // Deep void background
        this.add.rectangle(0, 0, W, H, 0x020108).setOrigin(0);

        // Nebula glow blobs (large, very transparent, pulsing)
        for (const [nx, ny, nr, nc, na] of [
            [W * 0.22, H * 0.30, 155, 0x3a0088, 0.055],
            [W * 0.78, H * 0.68, 125, 0x002266, 0.045],
            [W * 0.50, H * 0.52, 195, 0x440022, 0.035],
        ]) {
            const g = this.add.graphics();
            g.fillStyle(nc, na);
            g.fillCircle(nx, ny, nr);
            this.tweens.add({
                targets: g, alpha: { from: 0.55, to: 1.25 },
                duration: 3500 + Math.random() * 3000, yoyo: true, repeat: -1,
                delay: Math.random() * 2000,
            });
        }

        // Stars — three layers for parallax
        this._parallaxLayers = [];
        const starConfigs = [
            [105, 0.4, 1.0, 0.10, 0.45,  700, 1800], // Back (slowest)
            [ 44, 1.0, 1.5, 0.35, 0.80, 1200, 3200], // Mid
            [ 14, 1.5, 2.5, 0.55, 1.00, 2000, 5500], // Front (fastest)
        ];

        starConfigs.forEach((config, layerIdx) => {
            const [count, sMin, sMax, aMin, aMax, dMin, dMax] = config;
            const container = this.add.container(0, 0);
            this._parallaxLayers.push({
                container,
                factor: (layerIdx + 1) * 0.35,
                baseX: 0,
                baseY: 0
            });

            for (let i = 0; i < count; i++) {
                const x   = Math.random() * W;
                const y   = Math.random() * H;
                const s   = sMin + Math.random() * (sMax - sMin);
                const a   = aMin + Math.random() * (aMax - aMin);
                const dur = dMin + Math.random() * (dMax - dMin);
                const star = this.add.rectangle(x, y, s, s, 0xffffff, a);
                container.add(star);
                this.tweens.add({
                    targets: star, alpha: aMin * 0.15,
                    duration: dur, yoyo: true, repeat: -1, delay: Math.random() * dur,
                });
            }
        });

        // Vignette — dark circles at each corner to frame the scene
        const vg = this.add.graphics().setDepth(1);
        vg.fillStyle(0x000000, 0.75);
        for (const [cx, cy] of [[0,0],[W,0],[0,H],[W,H]]) vg.fillCircle(cx, cy, 230);

        // Slow-drifting micro-particles (colored dust)
        const PCOLS = [0xd4af37, 0x7755ff, 0x4488ff, 0xff6644, 0x44ffbb];
        for (let i = 0; i < 14; i++) {
            const px  = 50 + Math.random() * (W - 100);
            const py  = 80 + Math.random() * (H - 160);
            const ps  = 0.7 + Math.random() * 1.4;
            const pc  = PCOLS[i % PCOLS.length];
            const dur = 5000 + Math.random() * 6000;
            const p   = this.add.rectangle(px, py, ps, ps, pc, 0).setDepth(2);
            this.tweens.add({
                targets: p, y: py - 90 - Math.random() * 80,
                alpha: { from: 0, to: 0.55 },
                duration: dur, delay: Math.random() * 4000,
                yoyo: true, repeat: -1,
            });
        }
    }

    update(time) {
        if (this._done) return;

        // Pointer-based parallax
        const pointer = this.input.activePointer;
        // Normalize pointer position from -1 to 1
        const nx = (pointer.x - W / 2) / (W / 2);
        const ny = (pointer.y - H / 2) / (H / 2);

        // Autonomous drift (subtle sine movement)
        const driftX = Math.sin(time * 0.0005) * 2;
        const driftY = Math.cos(time * 0.0007) * 2;

        this._parallaxLayers.forEach(layer => {
            const targetX = -nx * 10 * layer.factor + driftX * layer.factor;
            const targetY = -ny * 10 * layer.factor + driftY * layer.factor;

            // Smooth interpolation
            layer.container.x += (targetX - layer.container.x) * 0.05;
            layer.container.y += (targetY - layer.container.y) * 0.05;
        });
    }

    // ── Permanent UI (always visible) ──────────────────────────────────────

    _buildPermanentUI() {
        // ESC-to-skip label — fades in after the first second
        const skipLbl = this.add.text(W - 14, 14, 'ESC — PULAR', {
            fontSize: '10px', color: '#ff4444', fontFamily: 'Courier New', letterSpacing: 1, fontStyle: 'bold'
        }).setOrigin(1, 0).setDepth(20).setAlpha(0);
        this.tweens.add({ targets: skipLbl, alpha: 1, duration: 600, delay: 2000 });

        // Progress dots — one per prologue line
        this._dots = [];
        const dotSpacing = 14;
        const dotX0 = (W - LINES.length * dotSpacing + dotSpacing) / 2;
        for (let i = 0; i < LINES.length; i++) {
            const d = this.add.circle(dotX0 + i * dotSpacing, H - 16, 3, 0x141228, 1).setDepth(20);
            this._dots.push(d);
        }

        // "SPACE to continue" hint, shown during prologue slides
        this._spaceHint = this.add.text(W / 2, H - 30, 'ESPAÇO  para continuar', {
            fontSize: '10px', color: '#ffd700', fontFamily: 'Courier New', fontStyle: 'bold'
        }).setOrigin(0.5, 1).setDepth(20).setAlpha(0);

        // "← BACK" hint, shown on prologue slides after text finishes
        this._backHint = this.add.text(14, H - 30, '←  VOLTAR', {
            fontSize: '10px', color: '#a090d0', fontFamily: 'Courier New', fontStyle: 'bold'
        }).setOrigin(0, 1).setDepth(20).setAlpha(0);
    }

    _setDots(activeIdx) {
        this._dots.forEach((d, i) => {
            if (i === activeIdx) { d.setFillStyle(0xd4af37); d.setRadius(4.5); }
            else if (i < activeIdx) { d.setFillStyle(0x4a4070); d.setRadius(3); }
            else { d.setFillStyle(0x141228); d.setRadius(3); }
        });
    }

    // ── Title card ─────────────────────────────────────────────────────────

    _showTitle() {
        this._page = -1;
        this._clearContent();

        // Radial glow behind the main title
        const glow = this.add.circle(W / 2, H * 0.31, 100, 0xd4af37, 0).setDepth(3);
        this.tweens.add({ targets: glow, alpha: 0.09, duration: 2400, delay: 400, ease: 'Quad.In' });

        // "MeanFall" — rises up with a fade
        const gameTitle = this.add.text(W / 2, H * 0.20, 'MeanFall', {
            fontSize: '38px', color: '#f5c842', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5).setAlpha(0).setDepth(4);
        this.tweens.add({ targets: gameTitle, alpha: 1, y: H * 0.25, duration: 1500, ease: 'Quad.Out', delay: 300 });

        // Story name
        const storyTitle = this.add.text(W / 2, H * 0.39, STORY.title.toUpperCase(), {
            fontSize: '13px', color: '#c9a832', fontFamily: 'Courier New', fontStyle: 'bold', letterSpacing: 4,
        }).setOrigin(0.5).setAlpha(0).setDepth(4);
        this.tweens.add({ targets: storyTitle, alpha: 1, duration: 900, delay: 1100 });

        // Horizontal rule sweeps outward from center
        const ruleY = Math.floor(H * 0.465);
        const rL = this.add.rectangle(W / 2, ruleY, 0, 1, 0xd4af37, 0.55).setOrigin(1, 0.5).setDepth(4);
        const rR = this.add.rectangle(W / 2, ruleY, 0, 1, 0xd4af37, 0.55).setOrigin(0, 0.5).setDepth(4);
        this.tweens.add({ targets: rL, width: 192, duration: 700, delay: 1800, ease: 'Quad.Out' });
        this.tweens.add({ targets: rR, width: 192, duration: 700, delay: 1800, ease: 'Quad.Out' });

        // Subtitle
        const subtitle = this.add.text(W / 2, H * 0.51, STORY.subtitle, {
            fontSize: '12px', color: '#7060a0', fontFamily: 'Courier New', fontStyle: 'italic',
        }).setOrigin(0.5).setAlpha(0).setDepth(4);
        this.tweens.add({ targets: subtitle, alpha: 0.9, duration: 800, delay: 2200 });

        // Beta / version tag
        const verTx = this.add.text(W / 2, H * 0.595, 'B E T A  ·  v 0 . 9 . 0', {
            fontSize: '8px', color: '#2a2748', fontFamily: 'Courier New', letterSpacing: 2,
        }).setOrigin(0.5).setAlpha(0).setDepth(4);
        this.tweens.add({ targets: verTx, alpha: 1, duration: 600, delay: 2800 });

        // "SPACE to begin" hint (title-specific, not _spaceHint)
        const beginHint = this.add.text(W / 2, H - 32, 'ESPAÇO  para começar', {
            fontSize: '11px', color: '#ffd700', fontFamily: 'Courier New', fontStyle: 'bold'
        }).setOrigin(0.5, 1).setAlpha(0).setDepth(20);
        this.tweens.add({ targets: beginHint, alpha: 1, duration: 500, delay: 3000 });

        this._content = [glow, gameTitle, storyTitle, rL, rR, subtitle, verTx, beginHint];

        // Auto-advance after 4.6 s if the player hasn't pressed anything
        this._autoTimer = this.time.delayedCall(4600, () => {
            if (!this._done && !this._busy && this._page === -1) this._advance();
        });
    }

    // ── Prologue slides ────────────────────────────────────────────────────

    _showLine(idx) {
        this._page = idx;
        this._clearContent();
        this._setDots(idx);

        // Header label (left)
        const hdr = this.add.text(22, 22, '— PRÓLOGO —', {
            fontSize: '9px', color: '#26234a', fontFamily: 'Courier New', letterSpacing: 3,
        }).setOrigin(0, 0.5).setAlpha(0).setDepth(4);
        this.tweens.add({ targets: hdr, alpha: 1, duration: 500 });

        // Line counter (right)
        const ctr = this.add.text(W - 22, 22, `${idx + 1} / ${LINES.length}`, {
            fontSize: '9px', color: '#26234a', fontFamily: 'Courier New',
        }).setOrigin(1, 0.5).setAlpha(0).setDepth(4);
        this.tweens.add({ targets: ctr, alpha: 1, duration: 500 });

        // Element icon — top-right corner, fades in with the header
        const elemIcon = this.add.image(W - 14, 6, SLIDE_ELEMENTS[idx])
            .setOrigin(1, 0).setScale(0.58).setAlpha(0).setDepth(5);
        this.tweens.add({ targets: elemIcon, alpha: 0.72, duration: 700, delay: 200 });

        // Top rule
        const tRule = this.add.graphics().setDepth(4).setAlpha(0);
        tRule.lineStyle(1, 0x1c1a36, 1);
        tRule.lineBetween(22, 32, W - 22, 32);
        this.tweens.add({ targets: tRule, alpha: 1, duration: 500 });

        // Bottom rule
        const bRule = this.add.graphics().setDepth(4).setAlpha(0);
        bRule.lineStyle(1, 0x1c1a36, 1);
        bRule.lineBetween(22, H - 42, W - 22, H - 42);
        this.tweens.add({ targets: bRule, alpha: 1, duration: 500 });

        // Rich prologue text — lay out at y=0 to measure height, then center
        const MARGIN = 52;
        const rich = layoutRichText(this, MARGIN, 0, LINES[idx], {
            fontSize: '12px', wrapWidth: W - MARGIN * 2, lineHeight: 18, baseColor: '#d0c4a8',
        });

        // Vertically center the text block between the two rules
        const availTop = 40, availBot = 50;
        const textTopY = Math.floor((H - availTop - availBot - rich.height) / 2) + availTop;
        rich.objects.forEach(obj => { obj.y += textTopY; obj.setAlpha(0).setDepth(4); });

        // Accent decoration: small vertical bar on the left of the text
        const accent = this.add.rectangle(MARGIN - 14, textTopY + rich.height / 2, 2, rich.height + 6, 0xd4af37, 0).setOrigin(0.5).setDepth(4);
        this.tweens.add({ targets: accent, alpha: 0.45, duration: 600, delay: 300 });

        this._content = [hdr, ctr, elemIcon, tRule, bRule, accent, ...rich.objects];

        // Start typewriter — rich objects revealed only after typing finishes
        this._startTyping(LINES[idx], textTopY, rich.objects);
    }

    // ── Typewriter ─────────────────────────────────────────────────────────

    _plainText(line) {
        return line.replace(/\{\{(\w+):([^}]+)\}\}/g, '$2');
    }

    _startTyping(line, textTopY, richObjects) {
        this._isTyping    = true;
        this._richObjects = richObjects;
        const MARGIN = 52;
        const plain  = this._plainText(line);
        let revealed = 0;

        // Plain-text proxy rendered char by char at the same position as the rich layout
        this._typingText = this.add.text(MARGIN, textTopY, '', {
            fontSize: '12px', color: '#d0c4a8', fontFamily: 'Courier New',
            wordWrap: { width: W - MARGIN * 2 }, lineSpacing: 6,
        }).setOrigin(0, 0).setDepth(5);

        this._typingTimer = this.time.addEvent({
            delay: 28,
            callback: () => {
                revealed = Math.min(revealed + 1, plain.length);
                this._typingText.setText(plain.substring(0, revealed));
                if (plain[revealed - 1] !== ' ') Sound.dialogTick();
                if (revealed >= plain.length) {
                    this._typingTimer.remove();
                    this._typingTimer = null;
                    this._finishTyping();
                }
            },
            loop: true,
        });
    }

    _finishTyping() {
        this._isTyping = false;
        if (this._typingText) { this._typingText.destroy(); this._typingText = null; }
        // Swap plain proxy for the colored rich text
        if (this._richObjects) {
            this.tweens.add({ targets: this._richObjects, alpha: 1, duration: 120 });
        }
        // Show space hint now that text is fully revealed
        this.tweens.add({ targets: this._spaceHint, alpha: 1, duration: 400 });
        // Show back hint on prologue slides (page ≥ 0)
        if (this._page >= 0) {
            this.tweens.add({ targets: this._backHint, alpha: 1, duration: 400 });
        }
    }

    _skipTyping() {
        if (this._typingTimer) { this._typingTimer.remove(); this._typingTimer = null; }
        if (this._typingText)  { this._typingText.destroy(); this._typingText = null; }
        this._finishTyping();
    }

    // ── Content lifecycle ──────────────────────────────────────────────────

    _clearContent() {
        this._autoTimer?.remove();
        this._autoTimer = null;
        // Clean up any in-progress typewriter
        if (this._typingTimer) { this._typingTimer.remove(); this._typingTimer = null; }
        if (this._typingText)  { this._typingText.destroy(); this._typingText = null; }
        this._isTyping    = false;
        this._richObjects = null;
        this._spaceHint?.setAlpha(0);
        this._backHint?.setAlpha(0);
        for (const obj of this._content) {
            try { this.tweens.killTweensOf(obj); obj.destroy(); } catch (_) {}
        }
        this._content = [];
    }

    // ── Navigation ─────────────────────────────────────────────────────────

    _goBack() {
        if (this._done || this._busy || this._isTyping) return;
        if (this._page < 0) return; // nada antes do title card

        this._busy = true;
        Sound.click();
        this._content.forEach(obj => this.tweens.killTweensOf(obj));
        this._spaceHint?.setAlpha(0);
        this._backHint?.setAlpha(0);

        const prev = this._page - 1;
        this.tweens.add({
            targets: this._content,
            alpha: 0,
            duration: 280,
            ease: 'Quad.In',
            onComplete: () => {
                this._busy = false;
                if (prev < 0) {
                    this._showTitle();   // slide 0 → volta ao title card
                } else {
                    this._showLine(prev);
                }
            },
        });
    }

    _advance() {
        if (this._done) return;

        // If typewriter is running, skip to full text instead of advancing page
        if (this._isTyping) {
            Sound.click();
            this._skipTyping();
            return;
        }

        if (this._busy) return;
        this._busy = true;
        this._autoTimer?.remove();
        this._autoTimer = null;
        Sound.click();

        // Freeze any in-progress fade-in tweens before fading out
        this._content.forEach(obj => this.tweens.killTweensOf(obj));
        this._spaceHint?.setAlpha(0);

        const next = this._page + 1;
        this.tweens.add({
            targets: this._content,
            alpha: 0,
            duration: 280,
            ease: 'Quad.In',
            onComplete: () => {
                this._busy = false;
                if (next < LINES.length) {
                    this._showLine(next);
                } else {
                    this._finish();
                }
            },
        });
    }

    _finish() {
        if (this._done) return;
        this._done = true;
        this._autoTimer?.remove();
        Music.stop();
        this.cameras.main.fadeOut(500, 0, 0, 0);
        this.cameras.main.once('camerafadeoutcomplete', () => {
            this.scene.start('CharacterCreation');
        });
    }
}
