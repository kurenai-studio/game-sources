import { RICH_COLORS } from '../utils/RichText.js';
import { Sound } from '../utils/SoundSystem.js';

// Highlight key terms in dialog text using Phaser BBCode-like tagging.
// We can't use real BBCode without an extra plugin, so we render line in
// segments: any token wrapped in {{tag:value}} is shown in its own colored
// Text object positioned next to the previous one.

const DIALOG_KEYWORDS = {
    Estatística: '#ffd700', estatística: '#ffd700',
    Distorção:   '#ff5566',
    HIPÓTESE:    '#bb88ff', Hipótese: '#bb88ff',
    Curva:       '#88ccff',  curva: '#88ccff',
    Média:       '#aaee66',  média: '#aaee66',
    Mediana:     '#88dd88',  mediana: '#88dd88',
    Moda:        '#ddaa88',  moda: '#ddaa88',
    Variância:   '#88ddff',  variância: '#88ddff',
    Probabilidade: '#ff9966',
    Inferência:  '#bb88ff',  inferência: '#bb88ff',
    XP:          '#ffaa22',
    nível:       '#ffaa44',  Nível: '#ffaa44',
    missão:      '#88ccff',  Missão: '#88ccff', missões: '#88ccff',
    LOOT:        '#ffd700',
    Lendário:    '#ffaa22',
    Importante:  '#44cc88',
    Essencial:   '#bb44ff',
    Foco:        '#88aaff',
    'α':          '#ff88cc',
    'p-valor':    '#ff88cc',
    'H₀':         '#bb88ff',
};

/**
 * DialogScene — bottom dialog box like classic JRPGs.
 * Receives { speaker, lines, onClose, role }.
 * Press SPACE / ENTER / click box to advance. Closes when out of lines.
 */
export class DialogScene extends Phaser.Scene {
    constructor() { super('Dialog'); }

    init(data) {
        this._speaker     = data.speaker || 'NPC';
        this._npcId       = data.npcId   || null;
        this._lines       = this._paginateLines(data.lines || []);
        this._onClose     = data.onClose || (() => {});
        this._action      = data.action  || null;     // { label, kind } or null
        this._onAction    = data.onAction || null;
        this._choices     = data.choices  || null;    // [{ label, onSelect }] or null
        this._role        = data.role     || 'quest';
        this._idx            = 0;
        this._typingTimer    = null;
        this._typingText     = null;
        this._isTyping       = false;
        this._fullText       = '';
        this._actionTaken    = false;  // MUST reset: scene object is reused across launches
        this._ready          = false;
        this._choicesShowing = false;
        this._choiceIdx      = 0;
        this._choiceItems    = [];
    }

    create() {
        const W = 544, H = 480;

        // Translucent shade over world — fades in with box
        this._shade = this.add.rectangle(0, 0, W, H, 0x000000, 0).setOrigin(0, 0).setInteractive()
            .on('pointerdown', () => this._advance());
        this.tweens.add({ targets: this._shade, alpha: 0.45, duration: 140 });

        // Dialog box
        const boxY = H - 130;
        const boxH = 120;
        this._box = this.add.rectangle(8, boxY, W - 16, boxH, 0x0a0814, 1).setOrigin(0, 0);
        this.add.rectangle(8, boxY, W - 16, boxH, 0xd4af37, 0).setOrigin(0, 0).setStrokeStyle(2, 0xd4af37);
        this.add.rectangle(10, boxY + 2, W - 20, 2, 0xd4af37, 0.4).setOrigin(0, 0);
        this.add.rectangle(10, boxY + boxH - 4, W - 20, 2, 0xd4af37, 0.4).setOrigin(0, 0);

        // Speaker tag
        const tagColor = this._role === 'shop' ? 0x33aa55 : 0xaa6633;
        this._tagBg = this.add.rectangle(20, boxY - 14, 130, 22, tagColor, 1).setOrigin(0, 0).setStrokeStyle(1, 0xd4af37);
        this._tagTx = this.add.text(85, boxY - 3, this._speaker.toUpperCase(), {
            fontSize: '17px', color: '#ffffff', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5, 0.5);

        // NPC portrait (left side of box)
        this._createPortrait(boxY);
        this._textStartX = 64;

        // Body text container (tokens drawn dynamically by _renderTokens)
        this._lineTokens = [];

        // Continue prompt — ▼ bouncing triangle (starts hidden; shown by _finishTyping)
        const promptY = boxY + boxH - 16;
        this._promptTx = this.add.text(W - 18, promptY, '▼', {
            fontSize: '14px', color: '#d4af37', fontFamily: 'Courier New',
        }).setOrigin(0.5, 0.5).setVisible(false);
        this.tweens.add({
            targets: this._promptTx, alpha: 0.15, y: promptY + 4,
            duration: 480, yoyo: true, repeat: -1, ease: 'Sine.easeInOut',
        });

        // Page indicator
        this._pageTx = this.add.text(20, boxY + boxH - 18, '', {
            fontSize: '15px', color: '#aaaaaa', fontFamily: 'Courier New',
        }).setOrigin(0, 0.5);

        // Slide-up entrance: offset all box elements down, tween back to final position
        const SLIDE = 64;
        const boxEls = this.children.list.filter(c => c !== this._shade && c !== this._promptTx);
        boxEls.forEach(el => { el.y += SLIDE; });
        this.tweens.add({ targets: boxEls, y: `-=${SLIDE}`, duration: 140, ease: 'Cubic.easeOut',
            onComplete: () => { this._ready = true; this._renderLine(); },
        });

        this.input.keyboard.on('keydown-SPACE', () => this._advance());
        this.input.keyboard.on('keydown-ENTER', () => this._advance());
        this.input.keyboard.on('keydown-ESC',   () => {
            if (this._choicesShowing) this._selectChoice(this._choices.length - 1);
            else this._close();
        });
        this.input.keyboard.on('keydown-UP',   () => { if (this._choicesShowing) this._choiceNav(-1); });
        this.input.keyboard.on('keydown-DOWN', () => { if (this._choicesShowing) this._choiceNav(+1); });
    }

    _portraitKey() {
        if (this._npcId && this.textures.exists(`sprite_npc_${this._npcId}`))
            return `sprite_npc_${this._npcId}`;
        if (this._role === 'shop')   return 'sprite_npc_shop';
        if (this._role === 'lore')   return 'sprite_npc_scholar';
        return 'sprite_npc';
    }

    _createPortrait(boxY) {
        const px = 14, py = boxY + 10, pw = 40, ph = 48;
        this.add.rectangle(px, py, pw, ph, 0x0a0814, 1).setOrigin(0, 0);
        this.add.rectangle(px, py, pw, ph, 0xd4af37, 0).setOrigin(0, 0).setStrokeStyle(2, 0xd4af37);
        const key = this._portraitKey();
        this.add.image(px + pw / 2, py + ph / 2, key)
            .setOrigin(0.5, 0.5).setScale(1.5).setDepth(10);
    }

    _paginateLines(lines) {
        const CHARS_PER_LINE = 50; // Courier New 15px ~9px/char, wrap width 494px
        const MAX_LINES      = 4;  // boxH 120 - padding 18 - footer 16 = 86px / 20px lineHeight
        const result = [];

        for (const raw of lines) {
            for (const seg of raw.split('\n')) {
                const plain    = seg.replace(/\{\{(\w+):([^}]+)\}\}/g, '$2');
                const srcWords = seg.split(' ');
                const pltWords = plain.split(' ');

                let pageWords = [], lineChars = 0, lineCount = 1;

                for (let i = 0; i < srcWords.length; i++) {
                    const wLen = (pltWords[i] || '').length;
                    const needed = lineChars > 0 ? 1 + wLen : wLen;

                    if (lineChars > 0 && lineChars + needed > CHARS_PER_LINE) {
                        lineCount++;
                        lineChars = wLen;
                        if (lineCount > MAX_LINES) {
                            result.push(pageWords.join(' '));
                            pageWords = [srcWords[i]];
                            lineCount = 1;
                            lineChars = wLen;
                            continue;
                        }
                    } else {
                        lineChars += needed;
                    }
                    pageWords.push(srcWords[i]);
                }

                if (pageWords.length > 0) result.push(pageWords.join(' '));
            }
        }

        return result;
    }

    _renderLine() {
        const line = this._lines[this._idx];
        if (!line) { this._close(); return; }
        this._fullText = line;
        this._pageTx.setText(`(${this._idx + 1} / ${this._lines.length})`);

        if (this._lineTokens) this._lineTokens.forEach(t => t.destroy());
        this._lineTokens = [];

        const isLast = this._idx === this._lines.length - 1;
        this._setActionButtonVisible(isLast && !!this._action);
        this._promptTx.setVisible(false);

        this._startTyping(line, isLast);
    }

    _plainText(line) {
        return line.replace(/\{\{(\w+):([^}]+)\}\}/g, '$2');
    }

    _startTyping(line, isLast) {
        if (this._typingTimer) { this._typingTimer.remove(); this._typingTimer = null; }
        if (this._typingText)  { this._typingText.destroy(); this._typingText = null; }

        this._isTyping = true;
        const plain = this._plainText(line);
        let revealed = 0;

        const startX = this._textStartX;
        const startY = this.scale.height - 130 + 18;

        this._typingText = this.add.text(startX, startY, '', {
            fontSize: '15px', color: '#eeeedd', fontFamily: 'Courier New',
            wordWrap: { width: this.scale.width - startX - 26 },
        }).setOrigin(0, 0).setDepth(11);

        this._typingTimer = this.time.addEvent({
            delay: 30,
            callback: () => {
                revealed = Math.min(revealed + 2, plain.length);
                this._typingText.setText(plain.substring(0, revealed));
                if (plain[revealed - 1] !== ' ') Sound.dialogTick();
                if (revealed >= plain.length) {
                    this._typingTimer.remove();
                    this._typingTimer = null;
                    this._finishTyping(line, isLast);
                }
            },
            loop: true,
        });
    }

    _skipTyping() {
        if (this._typingTimer) { this._typingTimer.remove(); this._typingTimer = null; }
        const isLast = this._idx === this._lines.length - 1;
        this._finishTyping(this._fullText, isLast);
    }

    _finishTyping(line, isLast) {
        this._isTyping = false;
        if (this._typingText) { this._typingText.destroy(); this._typingText = null; }

        const tokens = this._tokenize(line);
        this._renderTokens(tokens);
        for (const t of this._lineTokens) t.setAlpha(0);
        this.tweens.add({ targets: this._lineTokens, alpha: 1, duration: 120 });

        if (isLast && this._choices) {
            this._promptTx.setVisible(false);
            this.time.delayedCall(180, () => this._showChoices());
        } else {
            this._promptTx.setVisible(true).setAlpha(1);
        }
    }

    _setActionButtonVisible(visible) {
        if (!this._action) return;
        if (visible && !this._actionBtn) {
            const W = this.scale.width;
            const boxY = W ? this.scale.height - 130 : 350;
            const btnY = boxY + 80;
            const color = this._action.kind === 'shop' ? 0x33aa55 : 0x4488ff;
            this._actionBtn = this.add.rectangle(W - 130, btnY, 110, 24, color, 1)
                .setStrokeStyle(2, 0xffffff, 0.4)
                .setOrigin(0, 0).setInteractive()
                .on('pointerover', () => this._actionBtn.setFillStyle(color + 0x222222))
                .on('pointerout',  () => this._actionBtn.setFillStyle(color))
                .on('pointerdown', (p, lx, ly, ev) => { ev.stopPropagation(); this._triggerAction(); });
            this._actionTx = this.add.text(W - 75, btnY + 12, this._action.label, {
                fontSize: '16px', color: '#ffffff', fontFamily: 'Courier New', fontStyle: 'bold',
            }).setOrigin(0.5, 0.5);
        } else if (!visible && this._actionBtn) {
            this._actionBtn.destroy(); this._actionBtn = null;
            this._actionTx?.destroy(); this._actionTx = null;
        }
    }

    _triggerAction() {
        const fn = this._onAction;
        this._onAction = null;
        this._actionTaken = true;
        this._destroyAll();
        this.scene.stop('Dialog');
        try { fn && fn(); } catch (e) {}
    }

    _destroyAll() {
        if (this._typingTimer) { this._typingTimer.remove(); this._typingTimer = null; }
        if (this._typingText)  { this._typingText.destroy(); this._typingText = null; }
        this._isTyping = false;
        this._choicesShowing = false;
        this._choiceItems = [];
        this.children.getAll().forEach(c => c.destroy());
        this._lineTokens = [];
        this._shade = this._box = this._tagBg = this._tagTx = null;
        this._promptTx = this._pageTx = this._actionBtn = this._actionTx = null;
    }

    _showChoices() {
        if (!this._choices || this._actionTaken) return;
        this._choicesShowing = true;

        const W    = this.scale.width;
        const boxY = this.scale.height - 130;
        const itemH = 26, padV = 6, boxW = 260;
        const choiceBoxH = this._choices.length * itemH + padV * 2;
        const cbX = W - 8 - boxW;
        const cbY = boxY - choiceBoxH - 8;

        const bg = this.add.rectangle(cbX, cbY, boxW, choiceBoxH, 0x0a0814, 1).setOrigin(0, 0).setAlpha(0)
            .setDepth(20);
        const frame = this.add.rectangle(cbX, cbY, boxW, choiceBoxH, 0xd4af37, 0)
            .setOrigin(0, 0).setStrokeStyle(2, 0xd4af37).setAlpha(0).setDepth(20);
        this.tweens.add({ targets: [bg, frame], alpha: 1, duration: 160 });

        this._choiceItems = this._choices.map((c, i) => {
            const iy = cbY + padV + i * itemH;
            const bg = this.add.rectangle(cbX + 2, iy, boxW - 4, itemH, 0xd4af37, 0)
                .setOrigin(0, 0).setDepth(21).setInteractive()
                .on('pointerover', () => { this._choiceIdx = i; this._updateChoiceHighlight(); })
                .on('pointerdown', (p, lx, ly, ev) => { ev.stopPropagation(); this._selectChoice(i); });
            const tx = this.add.text(cbX + 14, iy + itemH / 2, '', {
                fontSize: '14px', color: '#aaaaaa', fontFamily: 'Courier New',
            }).setOrigin(0, 0.5).setDepth(22).setAlpha(0);
            this.tweens.add({ targets: tx, alpha: 1, duration: 160, delay: 60 + i * 40 });
            return { bg, tx, label: c.label };
        });

        this._choiceIdx = 0;
        this._updateChoiceHighlight();
    }

    _choiceNav(dir) {
        this._choiceIdx = (this._choiceIdx + dir + this._choices.length) % this._choices.length;
        this._updateChoiceHighlight();
        Sound.click();
    }

    _updateChoiceHighlight() {
        this._choiceItems.forEach(({ bg, tx, label }, i) => {
            const sel = i === this._choiceIdx;
            bg.setFillStyle(0xd4af37, sel ? 0.18 : 0);
            tx.setColor(sel ? '#ffd700' : '#888888');
            tx.setText((sel ? '▶ ' : '  ') + label);
        });
    }

    _selectChoice(idx) {
        if (!this._choicesShowing || this._actionTaken) return;
        const fn = this._choices[idx]?.onSelect;
        this._actionTaken = true;
        this._destroyAll();
        this.scene.stop('Dialog');
        try { fn && fn(); } catch (e) {}
    }

    _tokenize(line) {
        // Handles both {{tag:value}} rich tokens and plain words with keyword highlighting.
        const tokens = [];
        const re = /\{\{(\w+):([^}]+)\}\}|([^\s{]+|\s+)/g;
        let m;
        while ((m = re.exec(line)) !== null) {
            if (m[1] && m[2]) {
                // {{tag:body}} — color from RICH_COLORS, split for wrapping
                const color = RICH_COLORS[m[1]] || '#ffd700';
                for (const part of m[2].split(/(\s+)/)) {
                    if (part) tokens.push({ text: part, color, bold: true });
                }
            } else {
                const word = m[3] || '';
                const cleaned = word.replace(/[.,!?;:()…]/g, '');
                const kw = DIALOG_KEYWORDS[cleaned];
                tokens.push({ text: word, color: kw || null, bold: !!kw });
            }
        }
        return tokens;
    }

    _renderTokens(tokens) {
        const startX = this._textStartX;
        const startY = this.scale.height - 130 + 18;
        const wrapWidth = this.scale.width - startX - 26;
        let cx = 0, cy = 0;
        const lineHeight = 20;

        for (const { text, color, bold } of tokens) {
            if (!text) continue;
            const txt = this.add.text(0, 0, text, {
                fontSize: '15px', color: color || '#eeeedd', fontFamily: 'Courier New',
                fontStyle: bold ? 'bold' : 'normal',
            }).setOrigin(0, 0).setDepth(11);

            const w = txt.width;
            if (cx + w > wrapWidth && text.trim() !== '') {
                cx = 0; cy += lineHeight;
            }
            txt.setPosition(startX + cx, startY + cy);
            cx += w;
            this._lineTokens.push(txt);
        }
    }

    _advance() {
        if (!this._ready || this._actionTaken) return;
        if (this._choicesShowing) { this._selectChoice(this._choiceIdx); return; }
        if (this._isTyping) { this._skipTyping(); return; }
        this._idx++;
        if (this._idx >= this._lines.length) this._close();
        else this._renderLine();
    }

    _close() {
        if (this._actionTaken) return;
        this._actionTaken = true;
        this._destroyAll();
        this.scene.stop('Dialog');
        try { this._onClose(); } catch (e) { /* swallow */ }
    }
}
