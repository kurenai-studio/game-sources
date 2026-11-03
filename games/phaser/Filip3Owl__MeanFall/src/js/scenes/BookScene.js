import { BookSystem } from '../systems/BookSystem.js';
import { BOOKS, BOOK_IMPORTANCE } from '../data/books.js';
import EventBus from '../utils/EventBus.js';
import { AchievementSystem } from '../systems/AchievementSystem.js';

/**
 * BookScene — library/reader.
 * Left panel: list of owned books, colored by importance.
 * Right panel: pages of the selected book + "Ler" button.
 */
export class BookScene extends Phaser.Scene {
    constructor() { super('Book'); }

    create() {
        this._player    = this.registry.get('player');
        BookSystem.init(this._player);
        this._selected  = null;
        this._pageIdx   = 0;
        this._rows      = [];

        this._buildUI();
        this._renderList();

        const pendingId = this.registry.get('pendingBookId');
        if (pendingId) {
            this.registry.remove('pendingBookId');
            const owned = BookSystem.ownedBooks(this._player);
            const idx = owned.findIndex(e => e.id === pendingId);
            if (idx !== -1) this._selectIdx(idx);
        }

        const close = () => this._close();
        this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ESC).on('down', close);
        this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.B).on('down', close);
        this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.LEFT).on('down',  () => this._prevPage());
        this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.RIGHT).on('down', () => this._nextPage());
    }

    _buildUI() {
        const W = 544, H = 480;
        this.add.rectangle(0, 0, W, H, 0x000000, 0.92).setOrigin(0, 0);
        this.add.rectangle(10, 10, W - 20, H - 20, 0x0d0a03, 1).setOrigin(0, 0);
        this.add.rectangle(10, 10, W - 20, H - 20, 0xd4af37, 0).setOrigin(0, 0).setStrokeStyle(2, 0xd4af37);

        this.add.text(W / 2, 22, 'B I B L I O T E C A   D E   T O M O S', {
            fontSize: '16px', color: '#ffd700', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5, 0);

        this.add.rectangle(504, 14, 22, 22, 0x330000, 1).setOrigin(0, 0).setInteractive()
            .on('pointerdown', () => this._close());
        this.add.text(515, 25, 'X', { fontSize: '15px', color: '#ff4444', fontFamily: 'Courier New' }).setOrigin(0.5, 0.5);

        // Left list
        this.add.rectangle(14, 44, 220, 392, 0x080604, 1).setOrigin(0, 0);
        this.add.text(124, 50, 'TOMOS', { fontSize: '16px', color: '#d4af37', fontFamily: 'Courier New' }).setOrigin(0.5, 0);

        // Right reader
        this.add.rectangle(238, 44, 292, 392, 0x110d05, 1).setOrigin(0, 0);

        this._titleTx     = this.add.text(244, 50, '', { fontSize: '16px', color: '#ffd700', fontFamily: 'Courier New', fontStyle: 'bold', wordWrap: { width: 280 } }).setOrigin(0, 0);
        this._authorTx    = this.add.text(244, 70, '', { fontSize: '16px', color: '#aaaaaa', fontFamily: 'Courier New', fontStyle: 'italic' }).setOrigin(0, 0);
        this._importanceTx = this.add.text(244, 86, '', { fontSize: '16px', color: '#ffffff', fontFamily: 'Courier New', fontStyle: 'bold' }).setOrigin(0, 0);
        this._topicTx     = this.add.text(244, 102, '', { fontSize: '15px', color: '#888888', fontFamily: 'Courier New' }).setOrigin(0, 0);

        // Page text
        this._pageTx = this.add.text(244, 130, '', {
            fontSize: '17px', color: '#dddddd', fontFamily: 'Courier New', wordWrap: { width: 280 }, lineSpacing: 4,
        }).setOrigin(0, 0);

        this._pageNumTx = this.add.text(382, 380, '', { fontSize: '16px', color: '#666666', fontFamily: 'Courier New' }).setOrigin(0.5, 0);

        // Page navigation buttons
        this._prevBg = this.add.rectangle(244, 376, 60, 22, 0x1a1a3a, 1).setOrigin(0, 0).setInteractive()
            .on('pointerover', () => this._prevBg.setFillStyle(0x2a2a55))
            .on('pointerout',  () => this._prevBg.setFillStyle(0x1a1a3a))
            .on('pointerdown', () => this._prevPage())
            .setVisible(false);
        this._prevTx = this.add.text(274, 387, '< ANT', { fontSize: '16px', color: '#aaaaff', fontFamily: 'Courier New' }).setOrigin(0.5, 0.5).setVisible(false);

        this._nextBg = this.add.rectangle(466, 376, 60, 22, 0x1a1a3a, 1).setOrigin(0, 0).setInteractive()
            .on('pointerover', () => this._nextBg.setFillStyle(0x2a2a55))
            .on('pointerout',  () => this._nextBg.setFillStyle(0x1a1a3a))
            .on('pointerdown', () => this._nextPage())
            .setVisible(false);
        this._nextTx = this.add.text(496, 387, 'PROX >', { fontSize: '16px', color: '#aaaaff', fontFamily: 'Courier New' }).setOrigin(0.5, 0.5).setVisible(false);

        // Read button (claims first-read reward)
        this._readBg = this.add.rectangle(310, 408, 156, 24, 0x1a3a1a, 1).setOrigin(0, 0).setInteractive()
            .on('pointerover', () => this._readBg.setFillStyle(0x2a5a2a))
            .on('pointerout',  () => this._readBg.setFillStyle(0x1a3a1a))
            .on('pointerdown', () => this._claimRead())
            .setVisible(false);
        this._readTx = this.add.text(388, 420, 'ESTUDAR (XP+)', { fontSize: '17px', color: '#88ff88', fontFamily: 'Courier New', fontStyle: 'bold' }).setOrigin(0.5, 0.5).setVisible(false);

        this._readMsg = this.add.text(384, 440, '', { fontSize: '15px', color: '#888888', fontFamily: 'Courier New', wordWrap: { width: 280 } }).setOrigin(0.5, 0);

        this.add.text(W / 2, 462, 'B ou ESC para fechar', { fontSize: '15px', color: '#444444', fontFamily: 'Courier New' }).setOrigin(0.5, 0);
    }

    _renderList() {
        this._rows.forEach(r => { r.bg.destroy(); r.tx.destroy(); r.tag.destroy(); });
        this._rows = [];

        const owned = BookSystem.ownedBooks(this._player);
        if (owned.length === 0) {
            const empty = this.add.text(124, 240, 'Nenhum livro coletado.\n\nDerrote criaturas para encontrar tomos.', {
                fontSize: '16px', color: '#444444', fontFamily: 'Courier New', align: 'center', wordWrap: { width: 200 },
            }).setOrigin(0.5, 0.5);
            this._rows.push({ bg: empty, tx: empty, tag: empty });
            return;
        }

        for (let i = 0; i < owned.length; i++) {
            const entry = owned[i];
            const imp   = BOOK_IMPORTANCE[entry.book.importance] || BOOK_IMPORTANCE.normal;
            const y     = 62 + i * 20;

            const bg = this.add.rectangle(18, y, 212, 19, 0x111111, 1).setOrigin(0, 0).setInteractive()
                .on('pointerover', () => { if (this._selected !== i) bg.setFillStyle(0x1a1a22); })
                .on('pointerout',  () => { if (this._selected !== i) bg.setFillStyle(0x111111); })
                .on('pointerdown', () => this._selectIdx(i));

            const tx = this.add.text(24, y + 3, entry.book.title, {
                fontSize: '13px', color: imp.hex, fontFamily: 'Courier New', wordWrap: { width: 148 },
            }).setOrigin(0, 0);

            const tagText = entry.read ? '✓' : imp.name[0].toUpperCase();
            const tag = this.add.text(226, y + 10, tagText, {
                fontSize: '12px', color: entry.read ? '#555555' : imp.hex, fontFamily: 'Courier New',
            }).setOrigin(1, 0.5);

            this._rows.push({ bg, tx, tag, idx: i, bookId: entry.id });
        }
    }

    _selectIdx(i) {
        if (this._selected !== null && this._rows[this._selected]?.bg.setFillStyle) {
            this._rows[this._selected].bg.setFillStyle(0x111111);
        }
        this._selected = i;
        this._pageIdx  = 0;
        if (this._rows[i]?.bg.setFillStyle) this._rows[i].bg.setFillStyle(0x1a1a33);

        const bookId = this._rows[i].bookId;
        const book   = BOOKS[bookId];
        const imp    = BOOK_IMPORTANCE[book.importance] || BOOK_IMPORTANCE.normal;
        const entry  = this._player.bookLibrary[bookId];

        this._titleTx.setText(book.title).setColor(imp.hex);
        this._authorTx.setText(`Autor: ${book.author}`);
        this._importanceTx.setText(`Importância: ${imp.name}`).setColor(imp.hex);
        this._topicTx.setText(`Tópico: ${book.topic.replace(/_/g, ' ')}`);
        this._renderPage();

        const showRead = entry && !entry.read;
        this._readBg.setVisible(showRead);
        this._readTx.setVisible(showRead).setText(`ESTUDAR (+${imp.xp} XP)`);
        this._readMsg.setText(entry?.read
            ? 'Você já dominou este tomo. As lições permanecem.'
            : 'Estude este tomo para receber recompensa única.');
        this._readMsg.setColor(entry?.read ? '#666666' : '#888888');
    }

    _renderPage() {
        if (this._selected === null) return;
        const bookId = this._rows[this._selected].bookId;
        const book   = BOOKS[bookId];
        const total  = book.pages.length;
        this._pageTx.setText(book.pages[this._pageIdx] || '');
        this._pageNumTx.setText(`Página ${this._pageIdx + 1} de ${total}`);

        const showNav = total > 1;
        this._prevBg.setVisible(showNav).setAlpha(this._pageIdx > 0 ? 1 : 0.3);
        this._prevTx.setVisible(showNav).setAlpha(this._pageIdx > 0 ? 1 : 0.3);
        this._nextBg.setVisible(showNav).setAlpha(this._pageIdx < total - 1 ? 1 : 0.3);
        this._nextTx.setVisible(showNav).setAlpha(this._pageIdx < total - 1 ? 1 : 0.3);
    }

    _prevPage() {
        if (this._pageIdx > 0) { this._pageIdx--; this._renderPage(); }
    }
    _nextPage() {
        if (this._selected === null) return;
        const bookId = this._rows[this._selected].bookId;
        const total  = BOOKS[bookId].pages.length;
        if (this._pageIdx < total - 1) { this._pageIdx++; this._renderPage(); }
    }

    _claimRead() {
        if (this._selected === null) return;
        const bookId = this._rows[this._selected].bookId;
        const result = BookSystem.readBook(this._player, bookId);
        if (!result.ok) {
            this._readMsg.setColor('#ff5555').setText(result.reason);
            return;
        }
        if (result.firstRead) {
            const imp = result.importance;
            const BONUS_LABELS = { intelligence: 'Inteligência', maxFocus: 'Foco Máx' };
            const bonusStr = imp.bonus
                ? ' · ' + Object.entries(imp.bonus).map(([k, v]) => `+${v} ${BONUS_LABELS[k] || k}`).join(', ')
                : '';
            this._readMsg.setColor('#88ff88').setText(`Lição absorvida! +${imp.xp} XP${bonusStr}`);
            this.registry.set('player', this._player);
            EventBus.emit('chat', { msg: `Estudou "${result.book.title}" (+${imp.xp} XP${bonusStr})`, type: 'levelup' });
            AchievementSystem.check(this._player);
        }
        this._selectIdx(this._selected);
        this._renderList();
    }

    _close() {
        this.scene.stop('Book');
        const world = this.scene.get('World');
        if (world?.resumeFromOverlay) world.resumeFromOverlay();
    }
}
