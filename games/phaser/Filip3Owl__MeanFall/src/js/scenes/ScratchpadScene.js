import EventBus from '../utils/EventBus.js';

export class ScratchpadScene extends Phaser.Scene {
    constructor() { super('Scratchpad'); }

    init(data) {
        this._parentScene  = data.parent;
        this._history      = [];
        this._currentInput = '';
        this._activeTab    = 'calc';
        this._notesText    = localStorage.getItem('meanfall_notes') || '';
        this._notesFocused = false;
        this._notesCursor  = true;
        this._notesScroll  = 0;
        this._cursorPos    = (localStorage.getItem('meanfall_notes') || '').length;
        this._calcGroup    = [];
        this._notesGroup   = [];

        const saved = JSON.parse(localStorage.getItem('meanfall_scratchpad_pos') || 'null');
        this._initX = saved ? Math.min(saved.x, 544 - 240) : 290;
        this._initY = saved ? Math.min(saved.y, 480 - 320) : 38;
    }

    create() {
        this._W = 240;
        this._H = 320;

        this._container = this.add.container(this._initX, this._initY);

        this._buildChrome();
        this._buildCalcContent();
        this._buildNotesContent();
        this._switchTab('calc');

        // Blinking cursor for notes
        this.time.addEvent({ delay: 500, loop: true, callback: () => {
            this._notesCursor = !this._notesCursor;
            if (this._activeTab === 'notes') this._renderNotes();
        }});

        this.input.keyboard.on('keydown', this._onKeyDown.bind(this));
    }

    // ─── CHROME (header, tabs, drag) ──────────────────────────────────────────

    _buildChrome() {
        const W = this._W, H = this._H;

        // Drop shadow
        const shadow = this.add.rectangle(3, 3, W, H, 0x000000, 0.55).setOrigin(0);

        // Main window background
        const bg = this.add.rectangle(0, 0, W, H, 0x070510, 1).setOrigin(0)
            .setStrokeStyle(1, 0x3a2d60, 1);

        // Header background (visual)
        const headerBg = this.add.rectangle(0, 0, W, 26, 0x110d22, 1).setOrigin(0);
        // Header bottom accent
        const headerLine = this.add.rectangle(0, 25, W, 1, 0x4433aa, 0.35).setOrigin(0);

        // Title
        const titleTx = this.add.text(W / 2 - 10, 13, '⟨ CALC & NOTAS ⟩', {
            fontSize: '11px', color: '#9a7c30', fontFamily: 'Courier New',
            fontStyle: 'bold', letterSpacing: 0.5,
        }).setOrigin(0.5);

        // Drag icon hint
        const dragHint = this.add.text(8, 13, '⠿', {
            fontSize: '12px', color: '#3d3060', fontFamily: 'Courier New',
        }).setOrigin(0, 0.5);

        // Close button
        const closeBg = this.add.rectangle(W - 14, 13, 22, 18, 0x1c0808, 1).setOrigin(0.5)
            .setStrokeStyle(1, 0x662222, 0.9).setInteractive({ useHandCursor: true });
        const closeTx = this.add.text(W - 14, 13, '✕', {
            fontSize: '11px', color: '#bb2222', fontFamily: 'Courier New',
        }).setOrigin(0.5);
        closeBg.on('pointerover', () => closeBg.setFillStyle(0x381010));
        closeBg.on('pointerout',  () => closeBg.setFillStyle(0x1c0808));
        closeBg.on('pointerdown', () => this._close());

        // Transparent drag zone (header area minus close button; W-30 avoids overlap)
        const dragZone = this.add.rectangle(0, 0, W - 30, 26, 0x000000, 0)
            .setOrigin(0).setInteractive({ useHandCursor: true });

        let dragging = false, offX = 0, offY = 0;
        dragZone.on('pointerdown', (ptr) => {
            dragging = true;
            offX = ptr.x - this._container.x;
            offY = ptr.y - this._container.y;
        });
        this.input.on('pointermove', (ptr) => {
            if (!dragging) return;
            this._container.setPosition(
                Phaser.Math.Clamp(ptr.x - offX, 0, 544 - W),
                Phaser.Math.Clamp(ptr.y - offY, 0, 480 - H)
            );
        });
        this.input.on('pointerup', () => {
            if (!dragging) return;
            dragging = false;
            localStorage.setItem('meanfall_scratchpad_pos', JSON.stringify({
                x: this._container.x, y: this._container.y,
            }));
        });

        // Tab bar
        const tabBarBg  = this.add.rectangle(0, 26, W, 24, 0x090714, 1).setOrigin(0);
        const tabBarSep = this.add.rectangle(0, 49, W, 1, 0x2e2450, 0.5).setOrigin(0);

        const halfW = Math.floor(W / 2);
        this._calcTabBg = this.add.rectangle(2, 27, halfW - 3, 22, 0x17112e, 1).setOrigin(0)
            .setStrokeStyle(1, 0x4d3899, 1).setInteractive({ useHandCursor: true });
        this._calcTabTx = this.add.text(2 + (halfW - 3) / 2, 38, '⊞ CALC', {
            fontSize: '12px', color: '#9977ee', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5);

        this._notesTabBg = this.add.rectangle(halfW + 1, 27, W - halfW - 3, 22, 0x0b0914, 1).setOrigin(0)
            .setStrokeStyle(1, 0x2e224c, 1).setInteractive({ useHandCursor: true });
        this._notesTabTx = this.add.text(halfW + 1 + (W - halfW - 3) / 2, 38, '✎ NOTAS', {
            fontSize: '12px', color: '#5f4d99', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5);

        this._calcTabBg .on('pointerdown', () => this._switchTab('calc'));
        this._notesTabBg.on('pointerdown', () => this._switchTab('notes'));

        this._container.add([
            shadow, bg, headerBg, headerLine, titleTx, dragHint,
            closeBg, closeTx, dragZone,
            tabBarBg, tabBarSep,
            this._calcTabBg, this._calcTabTx,
            this._notesTabBg, this._notesTabTx,
        ]);
    }

    // ─── CALCULATOR TAB ───────────────────────────────────────────────────────

    _buildCalcContent() {
        const W = this._W;
        const topY = 52;

        // Display area
        const dispBg = this.add.rectangle(8, topY, W - 16, 40, 0x030109, 1).setOrigin(0)
            .setStrokeStyle(1, 0x2d2050, 1);
        this._historyTxt = this.add.text(W - 12, topY + 6, '', {
            fontSize: '10px', color: '#3d2d60', fontFamily: 'Courier New', align: 'right',
        }).setOrigin(1, 0);
        this._displayTxt = this.add.text(W - 12, topY + 32, '0', {
            fontSize: '15px', color: '#88ff99', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(1, 1);

        this._calcGroup.push(dispBg, this._historyTxt, this._displayTxt);

        // Keypad — 4 columns × 5 rows
        const kY   = topY + 46;
        const btnW = 52, btnH = 36, gap = 4;
        const rows = [
            ['7', '8', '9', '/'],
            ['4', '5', '6', '*'],
            ['1', '2', '3', '-'],
            ['0', '.', 'C', '+'],
            ['(', ')', '⌫', '='],
        ];

        rows.forEach((row, ri) => {
            row.forEach((key, ci) => {
                const bx  = 8 + ci * (btnW + gap);
                const by  = kY + ri * (btnH + gap);
                const isEq = key === '=';
                const isOp = ['+','-','*','/','(',')','⌫','C'].includes(key);
                const fill = isEq ? 0x0b2010 : isOp ? 0x100d20 : 0x070514;
                const bord = isEq ? 0x339955 : isOp ? 0x4030aa : 0x241d44;
                const tcol = isEq ? '#44dd77' : isOp ? '#9977ff' : '#c8c0e0';

                const btn = this.add.rectangle(bx, by, btnW, btnH, fill, 1).setOrigin(0)
                    .setStrokeStyle(1, bord, 0.75).setInteractive({ useHandCursor: true });
                const tx  = this.add.text(bx + btnW / 2, by + btnH / 2, key, {
                    fontSize: '12px', color: tcol, fontFamily: 'Courier New', fontStyle: 'bold',
                }).setOrigin(0.5);

                btn.on('pointerover', () => btn.setFillStyle(fill + 0x080810));
                btn.on('pointerout',  () => btn.setFillStyle(fill));
                btn.on('pointerdown', () => {
                    btn.setFillStyle(fill + 0x101020);
                    this.time.delayedCall(80, () => btn.setFillStyle(fill + 0x080810));
                    this._pressCalcKey(key);
                });

                this._calcGroup.push(btn, tx);
            });
        });

        this._calcGroup.forEach(o => this._container.add(o));
    }

    // ─── NOTES TAB ────────────────────────────────────────────────────────────

    _buildNotesContent() {
        const W = this._W, H = this._H;
        const topY  = 52;
        const areaH = H - topY - 34;

        // Notes text area background
        const notesBg = this.add.rectangle(8, topY, W - 16, areaH, 0x020108, 1).setOrigin(0)
            .setStrokeStyle(1, 0x252040, 1).setInteractive({ useHandCursor: true });
        notesBg.on('pointerdown', () => { this._notesFocused = true; });

        // Wheel scroll
        notesBg.on('wheel', (pointer, deltaX, deltaY, deltaZ) => {
            if (this._activeTab !== 'notes') return;
            const lines = this._notesText.split('\n');
            const MAX = 18;
            if (lines.length <= MAX) return;

            if (deltaY > 0) this._notesScroll++;
            else this._notesScroll--;

            this._notesScroll = Phaser.Math.Clamp(this._notesScroll, 0, lines.length - MAX);
            this._renderNotes();
        });

        // Scroll indicators
        this._scrollUp = this.add.text(W - 20, topY + 5, '▲', { fontSize: '10px', color: '#4d3899' }).setOrigin(0.5).setAlpha(0);
        this._scrollDn = this.add.text(W - 20, topY + areaH - 15, '▼', { fontSize: '10px', color: '#4d3899' }).setOrigin(0.5).setAlpha(0);

        // Watermark label
        const watermark = this.add.text(W - 14, topY + areaH - 10, 'NOTAS', {
            fontSize: '8px', color: '#1c1830', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(1, 1);

        // Text display
        this._notesTxt = this.add.text(12, topY + 6, '', {
            fontSize: '12px', color: '#c8c0e8', fontFamily: 'Courier New',
            wordWrap: { width: W - 32 }, lineSpacing: 3,
        }).setOrigin(0);

        // Bottom separator
        const sep = this.add.rectangle(0, H - 34, W, 1, 0x252040, 0.6).setOrigin(0);

        // Save button
        const btnH = 26;
        const saveW = Math.floor((W - 20) / 2);
        const saveBg = this.add.rectangle(8, H - 33, saveW, btnH, 0x07100a, 1).setOrigin(0)
            .setStrokeStyle(1, 0x1e5528, 0.9).setInteractive({ useHandCursor: true });
        const saveTx = this.add.text(8 + saveW / 2, H - 20, '✓  SALVAR', {
            fontSize: '12px', color: '#3dbb55', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5);
        saveBg.on('pointerover', () => saveBg.setFillStyle(0x0e1e10));
        saveBg.on('pointerout',  () => saveBg.setFillStyle(0x07100a));
        saveBg.on('pointerdown', () => this._saveNotes());

        // Clear button
        const clearX  = 8 + saveW + 4;
        const clearW  = W - clearX - 8;
        const clearBg = this.add.rectangle(clearX, H - 33, clearW, btnH, 0x100708, 1).setOrigin(0)
            .setStrokeStyle(1, 0x552020, 0.9).setInteractive({ useHandCursor: true });
        const clearTx = this.add.text(clearX + clearW / 2, H - 20, '⊗  LIMPAR', {
            fontSize: '12px', color: '#bb3322', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5);
        clearBg.on('pointerover', () => clearBg.setFillStyle(0x1e0e0e));
        clearBg.on('pointerout',  () => clearBg.setFillStyle(0x100708));
        clearBg.on('pointerdown', () => { 
            if (confirm('Limpar todas as notas?')) {
                this._notesText = ''; 
                this._notesScroll = 0;
                this._renderNotes(); 
            }
        });

        this._notesGroup.push(notesBg, this._scrollUp, this._scrollDn, watermark, this._notesTxt, sep, saveBg, saveTx, clearBg, clearTx);
        this._notesGroup.forEach(o => this._container.add(o));
    }

    // ─── TAB SWITCHING ────────────────────────────────────────────────────────

    _switchTab(tab) {
        this._activeTab    = tab;
        this._notesFocused = tab === 'notes';

        const calcOn = tab === 'calc';
        this._calcGroup .forEach(o => o.setVisible(calcOn));
        this._notesGroup.forEach(o => o.setVisible(!calcOn));

        this._calcTabBg .setFillStyle(calcOn  ? 0x17112e : 0x0b0914);
        this._calcTabTx .setColor(calcOn  ? '#bb99ff' : '#5f4d99');
        this._notesTabBg.setFillStyle(!calcOn ? 0x17112e : 0x0b0914);
        this._notesTabTx.setColor(!calcOn ? '#bb99ff' : '#5f4d99');

        if (tab === 'notes') {
            const lines = this._notesText.split('\n');
            const MAX = 18;
            this._notesScroll = Math.max(0, lines.length - MAX);
            this._renderNotes();
        }
    }

    // ─── NOTES RENDER ─────────────────────────────────────────────────────────

    _renderNotes() {
        const MAX   = 18;
        const text  = this._notesText;
        const pos   = this._cursorPos;
        
        // Split text into lines, but keep track of character indices
        const lines = text.split('\n');
        
        // Clamp scroll
        this._notesScroll = Phaser.Math.Clamp(this._notesScroll, 0, Math.max(0, lines.length - MAX));

        const visibleLines = lines.slice(this._notesScroll, this._notesScroll + MAX);
        
        // Insert cursor character for rendering
        if (this._notesFocused && this._notesCursor) {
            let charAccum = 0;
            for (let i = 0; i < this._notesScroll; i++) {
                charAccum += lines[i].length + 1;
            }

            for (let i = 0; i < visibleLines.length; i++) {
                const lineStart = charAccum;
                const lineEnd   = charAccum + visibleLines[i].length;
                
                if (pos >= lineStart && pos <= lineEnd) {
                    const linePos = pos - lineStart;
                    visibleLines[i] = visibleLines[i].slice(0, linePos) + '|' + visibleLines[i].slice(linePos);
                    break;
                }
                charAccum += lines[i].length + 1;
            }
        }
        
        this._notesTxt.setText(visibleLines.join('\n'));

        // Update scroll indicators
        if (this._scrollUp) {
            this._scrollUp.setAlpha(this._notesScroll > 0 ? 1 : 0);
            this._scrollDn.setAlpha(this._notesScroll < lines.length - MAX ? 1 : 0);
        }
    }

    _saveNotes() {
        localStorage.setItem('meanfall_notes', this._notesText);
        this._notesTxt.setColor('#44ee77');
        this.time.delayedCall(500, () => this._notesTxt.setColor('#c8c0e8'));
        EventBus.emit('chat', { cls: 'system', msg: '[ Notas salvas. ]' });
    }

    // ─── KEYBOARD ─────────────────────────────────────────────────────────────

    _onKeyDown(event) {
        const key = event.key;

        // If typing in notes, we MUST block the event from reaching other scenes
        // to prevent opening inventory (I), character (C), etc.
        const isTyping = this._activeTab === 'notes' && this._notesFocused;

        if (key === 'Escape') { 
            this._close(); 
            return; 
        }

        // N closes scratchpad unless actively typing notes
        if (key === 'n' || key === 'N') {
            if (isTyping) {
                this._handleNotesKey(key);
                event.stopImmediatePropagation();
            } else {
                this._close();
            }
            return;
        }

        if (this._activeTab === 'calc') {
            this._handleCalcKeyEvent(key);
        } else if (this._notesFocused) {
            this._handleNotesKey(key);
            // Block propagation for ALL keys while typing notes
            event.stopImmediatePropagation();
        }
    }

    _handleCalcKeyEvent(key) {
        if (key === 'Enter')    { this._calculate(); return; }
        if (key === 'Backspace'){ this._currentInput = this._currentInput.slice(0,-1); this._updateDisplay(); return; }
        if (/^[cC]$/.test(key)){ this._currentInput = ''; this._updateDisplay(); return; }
        if (/^[0-9.+\-*/%()]$/.test(key)){ this._currentInput += key; this._updateDisplay(); }
    }

    _pressCalcKey(key) {
        if (key === '=')  { this._calculate(); }
        else if (key === 'C')  { this._currentInput = ''; this._updateDisplay(); }
        else if (key === '⌫') { this._currentInput = this._currentInput.slice(0,-1); this._updateDisplay(); }
        else { this._currentInput += key; this._updateDisplay(); }
    }

    _handleNotesKey(key) {
        const text = this._notesText;
        const pos  = this._cursorPos;

        if (key === 'ArrowLeft') {
            this._cursorPos = Math.max(0, pos - 1);
        } else if (key === 'ArrowRight') {
            this._cursorPos = Math.min(text.length, pos + 1);
        } else if (key === 'ArrowUp') {
            this._moveCursorVertical(-1);
        } else if (key === 'ArrowDown') {
            this._moveCursorVertical(1);
        } else if (key === 'Home') {
            const lastLineBreak = text.lastIndexOf('\n', pos - 1);
            this._cursorPos = lastLineBreak === -1 ? 0 : lastLineBreak + 1;
        } else if (key === 'End') {
            const nextLineBreak = text.indexOf('\n', pos);
            this._cursorPos = nextLineBreak === -1 ? text.length : nextLineBreak;
        } else if (key === 'Backspace') {
            if (pos > 0) {
                this._notesText = text.slice(0, pos - 1) + text.slice(pos);
                this._cursorPos = pos - 1;
            }
        } else if (key === 'Delete') {
            if (pos < text.length) {
                this._notesText = text.slice(0, pos) + text.slice(pos + 1);
            }
        } else if (key === 'Enter') {
            this._notesText = text.slice(0, pos) + '\n' + text.slice(pos);
            this._cursorPos = pos + 1;
        } else if (key === 'Tab') {
            this._notesText = text.slice(0, pos) + '    ' + text.slice(pos);
            this._cursorPos = pos + 4;
        } else if (key.length === 1) {
            this._notesText = text.slice(0, pos) + key + text.slice(pos);
            this._cursorPos = pos + 1;
        }

        this._syncScrollToCursor();
        this._renderNotes();
        localStorage.setItem('meanfall_notes', this._notesText);
    }

    _moveCursorVertical(dir) {
        const lines = this._notesText.split('\n');
        let currentLine = 0, charAccum = 0;
        
        // Find current line and column
        for (let i = 0; i < lines.length; i++) {
            if (this._cursorPos <= charAccum + lines[i].length) {
                currentLine = i;
                break;
            }
            charAccum += lines[i].length + 1;
        }
        
        const col = this._cursorPos - charAccum;
        const targetLine = currentLine + dir;
        
        if (targetLine >= 0 && targetLine < lines.length) {
            let newPos = 0;
            for (let i = 0; i < targetLine; i++) {
                newPos += lines[i].length + 1;
            }
            this._cursorPos = newPos + Math.min(col, lines[targetLine].length);
        }
    }

    _syncScrollToCursor() {
        const lines = this._notesText.slice(0, this._cursorPos).split('\n');
        const currentLineIdx = lines.length - 1;
        const MAX = 18;

        if (currentLineIdx < this._notesScroll) {
            this._notesScroll = currentLineIdx;
        } else if (currentLineIdx >= this._notesScroll + MAX) {
            this._notesScroll = currentLineIdx - MAX + 1;
        }
    }

    // ─── CALCULATOR LOGIC ─────────────────────────────────────────────────────

    _updateDisplay() {
        this._displayTxt.setText(this._currentInput || '0');
    }

    _calculate() {
        if (!this._currentInput) return;
        try {
            const expr   = this._currentInput.replace(/[^0-9.+\-*/%()]/g, '');
            const result = new Function(`return ${expr}`)();
            const val    = typeof result === 'number' ? parseFloat(result.toFixed(8)) : result;
            this._history.unshift(`${expr}=${val}`);
            if (this._history.length > 3) this._history.pop();
            this._historyTxt.setText(this._history.join('\n'));
            this._currentInput = String(val);
            this._updateDisplay();
        } catch {
            this._displayTxt.setText('ERRO');
            this.time.delayedCall(1000, () => this._updateDisplay());
        }
    }

    _close() {
        this.scene.stop();
        EventBus.emit('scratchpad-closed');
    }
}
