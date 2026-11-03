import { BOOKS, BOOK_IMPORTANCE } from '../data/books.js';
import { ELEMENTS } from '../constants.js';

const W = 544, H = 480;
const SIDEBAR_W  = 168;
const CONTENT_X  = SIDEBAR_W + 14;
const CONTENT_W  = W - CONTENT_X - 8;

const TOPICS = [
    { id: 'data_types',       name: 'Tipos de Dados',    elem: 'normal' },
    { id: 'mean_median_mode', name: 'Tendência Central', elem: 'earth'  },
    { id: 'spread',           name: 'Dispersão',         elem: 'ice'    },
    { id: 'probability',      name: 'Probabilidade',     elem: 'fire'   },
    { id: 'distributions',    name: 'Distribuições',     elem: 'water'  },
    { id: 'inference',        name: 'Inferência',        elem: 'shadow' },
];

export class CompendiumScene extends Phaser.Scene {
    constructor() { super('Compendium'); }

    init() {
        this._selectedTopic  = null;
        this._sidebarBtns    = [];
        this._contentObjs    = [];
        this._detailObjs     = [];
        this._scrollPx      = 0;   // scroll offset in pixels for book list
    }

    create() {
        this._player = this.registry.get('player');

        // Background
        this.add.rectangle(0, 0, W, H, 0x050201, 0.97).setOrigin(0);

        // Header bar
        this.add.rectangle(0, 0, W, 34, 0x111111, 1).setOrigin(0);
        this.add.rectangle(0, 33, W, 1, 0xd4af37, 0.4).setOrigin(0);
        this.add.text(W / 2, 17, 'COMPÊNDIO DE ESTATÍSTICA', {
            fontSize: '16px', color: '#ffd700', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0.5);
        this.add.text(W - 10, 17, '[ESC]', {
            fontSize: '14px', color: '#666', fontFamily: 'Courier New',
        }).setOrigin(1, 0.5).setInteractive({ useHandCursor: true })
            .on('pointerdown', () => this._close());

        // Sidebar divider
        this.add.rectangle(SIDEBAR_W + 6, 34, 1, H - 34, 0xd4af37, 0.2).setOrigin(0);

        this._buildSidebar();
        this._renderEmptyState();

        this.input.keyboard.on('keydown-ESC', () => this._close());
        this.input.keyboard.on('keydown-L',   () => this._close());
    }

    // ── Sidebar ───────────────────────────────────────────────────────────────

    _buildSidebar() {
        const x = 8, yStart = 48;
        this.add.text(x, yStart - 12, 'TÓPICOS', {
            fontSize: '12px', color: '#443322', fontFamily: 'Courier New',
        });

        TOPICS.forEach((topic, i) => {
            const ty      = yStart + i * 30;
            const elem    = ELEMENTS[topic.elem] || {};
            const readCnt = this._readCountForTopic(topic.id);
            const total   = this._totalBooksForTopic(topic.id);

            const bg = this.add.rectangle(x, ty, SIDEBAR_W - 4, 26, 0x111111, 1)
                .setOrigin(0).setInteractive({ useHandCursor: true });

            const dot = this.add.circle(x + 8, ty + 13, 4, elem.color ?? 0x888888, readCnt > 0 ? 1 : 0.25);

            const txt = this.add.text(x + 18, ty + 13, topic.name, {
                fontSize: '13px', color: readCnt > 0 ? '#aaaaaa' : '#444444', fontFamily: 'Courier New',
            }).setOrigin(0, 0.5);

            const complete = total > 0 && readCnt === total;
            const cntTx = this.add.text(x + SIDEBAR_W - 10, ty + 13,
                complete ? '✓' : `${readCnt}/${total}`, {
                fontSize: complete ? '14px' : '11px',
                color: complete ? '#ffd700' : (readCnt > 0 ? '#666633' : '#333333'),
                fontFamily: 'Courier New', fontStyle: complete ? 'bold' : 'normal',
            }).setOrigin(1, 0.5);

            bg.on('pointerover', () => {
                if (this._selectedTopic !== topic.id) bg.setFillStyle(0x1e1a10);
            });
            bg.on('pointerout', () => {
                if (this._selectedTopic !== topic.id) bg.setFillStyle(0x111111);
            });
            bg.on('pointerdown', () => this._selectTopic(topic));

            this._sidebarBtns.push({ topic, bg, txt, dot, cntTx });
        });

        // Total progress bar at sidebar bottom
        const readAll  = Object.values(this._player.bookLibrary || {}).filter(e => e.read).length;
        const totalAll = Object.keys(BOOKS).length;
        const pct = totalAll > 0 ? readAll / totalAll : 0;

        this.add.text(x, H - 46, 'PROGRESSO TOTAL:', {
            fontSize: '11px', color: '#443322', fontFamily: 'Courier New',
        });
        this.add.rectangle(x, H - 34, SIDEBAR_W - 4, 10, 0x1a1a1a, 1).setOrigin(0);
        this.add.rectangle(x, H - 34, Math.max(2, (SIDEBAR_W - 4) * pct), 10, 0xd4af37, 0.6).setOrigin(0);
        this.add.text(x + SIDEBAR_W / 2 - 2, H - 22, `${readAll} / ${totalAll} livros`, {
            fontSize: '11px', color: '#666633', fontFamily: 'Courier New',
        }).setOrigin(0.5, 0);
    }

    _readCountForTopic(topicId) {
        const lib = this._player.bookLibrary || {};
        return Object.values(BOOKS).filter(b => b.topic === topicId && lib[b.id]?.read).length;
    }

    _totalBooksForTopic(topicId) {
        return Object.values(BOOKS).filter(b => b.topic === topicId).length;
    }

    // ── Topic selection ───────────────────────────────────────────────────────

    _selectTopic(topic) {
        this._selectedTopic = topic.id;
        this._scrollPx = 0; // reset scroll on topic change

        // Reset all sidebar buttons — iterate our small stored array, NOT children.list
        this._sidebarBtns.forEach(({ topic: t, bg, txt }) => {
            const isActive = t.id === topic.id;
            bg.setFillStyle(isActive ? 0x2a1e08 : 0x111111);
            bg.setStrokeStyle(isActive ? 1 : 0, 0xd4af37);
            txt.setColor(isActive ? '#ffd700' : (this._readCountForTopic(t.id) > 0 ? '#aaaaaa' : '#444444'));
        });

        this._renderTopicContent(topic);
    }

    // ── Content area ──────────────────────────────────────────────────────────

    _clearContent() {
        this._contentObjs.forEach(o => o?.destroy());
        this._contentObjs = [];
    }

    _addContent(obj) {
        this._contentObjs.push(obj);
        return obj;
    }

    _renderEmptyState() {
        this._clearContent();
        this._addContent(this.add.text(CONTENT_X + CONTENT_W / 2, 260,
            'Selecione um tópico para revisar\no conhecimento adquirido\nem sua jornada.', {
                fontSize: '14px', color: '#333', fontFamily: 'Courier New', align: 'center',
            }).setOrigin(0.5));
    }

    _renderTopicContent(topic) {
        this._clearContent();

        const x = CONTENT_X, y = 44;

        // Topic header (always visible, not scrolled)
        const elem = ELEMENTS[topic.elem] || {};
        this._addContent(this.add.rectangle(x, y, CONTENT_W, 28, 0x111111, 1).setOrigin(0));
        this._addContent(this.add.circle(x + 10, y + 14, 5, elem.color ?? 0x888888, 0.9));
        this._addContent(this.add.text(x + 22, y + 14, topic.name.toUpperCase(), {
            fontSize: '14px', color: '#ffd700', fontFamily: 'Courier New', fontStyle: 'bold',
        }).setOrigin(0, 0.5));

        const areaMap = {
            data_types: 'village', mean_median_mode: 'meadows',
            spread: 'forest', probability: 'plains',
            distributions: 'mountains', inference: 'dungeon',
        };
        const areaKey = areaMap[topic.id];
        const mastery = this._player.mastery?.[areaKey] || { attempted: 0, correct: 0 };
        const pct = mastery.attempted > 0 ? Math.floor((mastery.correct / mastery.attempted) * 100) : 0;
        const masteryColor = pct >= 70 ? '#44cc44' : pct >= 40 ? '#ddaa22' : '#888888';
        this._addContent(this.add.text(x + CONTENT_W, y + 14, `Precisão: ${pct}%`, {
            fontSize: '12px', color: masteryColor, fontFamily: 'Courier New',
        }).setOrigin(1, 0.5));

        // Build the full scrollable row list
        const lib        = this._player.bookLibrary || {};
        const topicBooks = Object.values(BOOKS).filter(b => b.topic === topic.id);
        const unlocked   = topicBooks.filter(b => lib[b.id]?.read);
        const locked     = topicBooks.filter(b => !lib[b.id]?.read);

        // Virtual rows: { type: 'label'|'book'|'locked', data? }
        const rows = [];
        if (unlocked.length === 0) {
            rows.push({ type: 'empty' });
        } else {
            rows.push({ type: 'label', text: `${unlocked.length} entrada(s) desbloqueada(s):`, color: '#665533' });
            unlocked.forEach(book => rows.push({ type: 'book', book }));
        }
        if (locked.length > 0) {
            rows.push({ type: 'label', text: `${locked.length} entrada(s) ainda bloqueada(s):`, color: '#333' });
            locked.forEach(book => rows.push({ type: 'locked', book }));
        }

        // Row heights
        const ROW_H = { label: 18, book: 30, locked: 18, empty: 0 };
        const BODY_Y   = y + 38;
        const BODY_MAX = H - BODY_Y - 10; // usable vertical space for rows

        // Compute total height and max scroll
        let totalH = 0;
        rows.forEach(r => { totalH += ROW_H[r.type] || 0; });
        const maxScroll = Math.max(0, totalH - BODY_MAX);

        // Clamp scroll offset (pixels, not rows) to valid range
        this._scrollPx = Math.min(this._scrollPx, maxScroll);

        // Render rows shifted by scroll offset
        let curY = BODY_Y - this._scrollPx;
        rows.forEach(r => {
            const rh = ROW_H[r.type] || 0;
            const visible = curY + rh > BODY_Y && curY < H - 10;

            if (r.type === 'empty') {
                if (visible) {
                    this._addContent(this.add.text(x + CONTENT_W / 2, BODY_Y + BODY_MAX / 2,
                        'Nenhum livro encontrado ainda.\n\nDerrote criaturas deste elemento\npara desbloquear entradas.', {
                            fontSize: '13px', color: '#444', fontFamily: 'Courier New',
                            align: 'center', fontStyle: 'italic',
                        }).setOrigin(0.5));
                }
            } else if (r.type === 'label') {
                if (visible) {
                    this._addContent(this.add.text(x + 4, curY, r.text, {
                        fontSize: '11px', color: r.color, fontFamily: 'Courier New',
                    }));
                }
                curY += rh;
            } else if (r.type === 'book') {
                if (visible) {
                    const imp     = BOOK_IMPORTANCE[r.book.importance] || BOOK_IMPORTANCE.normal;
                    const rowBg   = this._addContent(
                        this.add.rectangle(x, curY, CONTENT_W, 28, 0x111111, 1).setOrigin(0)
                            .setInteractive({ useHandCursor: true }));
                    this._addContent(this.add.rectangle(x, curY, 4, 28, imp.color, 1).setOrigin(0));
                    const titleTx = this._addContent(
                        this.add.text(x + 10, curY + 14, r.book.title, {
                            fontSize: '13px', color: imp.hex, fontFamily: 'Courier New',
                        }).setOrigin(0, 0.5));
                    this._addContent(
                        this.add.text(x + CONTENT_W - 2, curY + 14, r.book.author || '', {
                            fontSize: '11px', color: '#444', fontFamily: 'Courier New', fontStyle: 'italic',
                        }).setOrigin(1, 0.5));
                    rowBg.on('pointerover',  () => { rowBg.setFillStyle(0x1e1a10); titleTx.setColor('#ffffff'); });
                    rowBg.on('pointerout',   () => { rowBg.setFillStyle(0x111111); titleTx.setColor(imp.hex); });
                    rowBg.on('pointerdown',  () => this._showBookDetail(r.book));
                }
                curY += rh;
            } else if (r.type === 'locked') {
                if (visible) {
                    this._addContent(this.add.text(x + 10, curY, `• ${r.book.title}`, {
                        fontSize: '12px', color: '#2a2a2a', fontFamily: 'Courier New',
                    }));
                }
                curY += rh;
            }
        });

        // Scroll arrows when content overflows
        if (maxScroll > 0) {
            if (this._scrollPx > 0) {
                this._addContent(
                    this.add.text(x + CONTENT_W - 4, BODY_Y + 2, '▲', {
                        fontSize: '14px', color: '#d4af37', fontFamily: 'Courier New',
                    }).setOrigin(1, 0).setInteractive({ useHandCursor: true })
                        .on('pointerdown', () => {
                            this._scrollPx = Math.max(0, this._scrollPx - 60);
                            this._renderTopicContent(topic);
                        }));
            }
            if (this._scrollPx < maxScroll) {
                this._addContent(
                    this.add.text(x + CONTENT_W - 4, H - 16, '▼', {
                        fontSize: '14px', color: '#d4af37', fontFamily: 'Courier New',
                    }).setOrigin(1, 0).setInteractive({ useHandCursor: true })
                        .on('pointerdown', () => {
                            this._scrollPx = Math.min(maxScroll, this._scrollPx + 60);
                            this._renderTopicContent(topic);
                        }));
            }
        }

        // Mouse wheel scroll
        this.input.off('wheel'); // remove previous listener
        this.input.on('wheel', (_ptr, _objs, _dx, dy) => {
            this._scrollPx = Math.max(0, Math.min(maxScroll, (this._scrollPx || 0) + dy * 1.0));
            this._renderTopicContent(topic);
        });
    }

    // ── Book detail overlay ───────────────────────────────────────────────────

    _showBookDetail(book, pageIdx = 0) {
        this._clearDetail();

        const imp      = BOOK_IMPORTANCE[book.importance] || BOOK_IMPORTANCE.normal;
        const pages    = book.pages || [];
        const total    = pages.length;
        const idx      = Math.max(0, Math.min(pageIdx, total - 1));

        const add = obj => { this._detailObjs.push(obj); return obj; };

        const PANEL_W = 420, PANEL_H = 320;
        const panelX  = W / 2;
        const panelY  = H / 2 - PANEL_H / 2;

        // Backdrop — click closes
        add(this.add.rectangle(0, 0, W, H, 0x000000, 0.82)
            .setOrigin(0).setDepth(50).setInteractive()
            .on('pointerdown', () => this._clearDetail()));

        // Panel background
        add(this.add.rectangle(panelX, panelY, PANEL_W, PANEL_H, 0x0e0c06, 1)
            .setStrokeStyle(2, imp.color).setDepth(51));

        // Importance color bar at top
        add(this.add.rectangle(panelX - PANEL_W / 2, panelY, PANEL_W, 4, imp.color, 0.7)
            .setOrigin(0, 0).setDepth(52));

        // Title
        add(this.add.text(panelX, panelY + 18, book.title, {
            fontSize: '14px', color: imp.hex, fontFamily: 'Courier New', fontStyle: 'bold',
            wordWrap: { width: 390 }, align: 'center',
        }).setOrigin(0.5, 0).setDepth(52));

        // Author
        add(this.add.text(panelX, panelY + 36, `— ${book.author || 'Autor desconhecido'}`, {
            fontSize: '11px', color: '#555', fontFamily: 'Courier New', fontStyle: 'italic',
        }).setOrigin(0.5, 0).setDepth(52));

        // Divider
        add(this.add.rectangle(panelX, panelY + 52, 380, 1, 0xd4af37, 0.2).setDepth(52));

        // Page content
        add(this.add.text(panelX - 190, panelY + 60, pages[idx] || '', {
            fontSize: '12px', color: '#d4c8b0', fontFamily: 'Courier New',
            wordWrap: { width: 388 }, lineSpacing: 4,
        }).setOrigin(0, 0).setDepth(52));

        // Page indicator
        if (total > 1) {
            add(this.add.text(panelX, panelY + PANEL_H - 44, `Página ${idx + 1} de ${total}`, {
                fontSize: '11px', color: '#555', fontFamily: 'Courier New',
            }).setOrigin(0.5, 0).setDepth(52));
        }

        // Prev / Next buttons
        if (idx > 0) {
            const prev = add(this.add.text(panelX - 100, panelY + PANEL_H - 28, '◄ ANTERIOR', {
                fontSize: '12px', color: '#aaaaff', fontFamily: 'Courier New',
            }).setOrigin(0.5, 0).setDepth(52).setInteractive({ useHandCursor: true }));
            prev.on('pointerover', () => prev.setColor('#ffffff'));
            prev.on('pointerout',  () => prev.setColor('#aaaaff'));
            prev.on('pointerdown', () => this._showBookDetail(book, idx - 1));
        }

        if (idx < total - 1) {
            const next = add(this.add.text(panelX + 100, panelY + PANEL_H - 28, 'PRÓXIMO ►', {
                fontSize: '12px', color: '#aaaaff', fontFamily: 'Courier New',
            }).setOrigin(0.5, 0).setDepth(52).setInteractive({ useHandCursor: true }));
            next.on('pointerover', () => next.setColor('#ffffff'));
            next.on('pointerout',  () => next.setColor('#aaaaff'));
            next.on('pointerdown', () => this._showBookDetail(book, idx + 1));
        }

        // "Open in Library" button — only if player owns the book
        const lib = this._player.bookLibrary || {};
        if (lib[book.id]) {
            const libraryBtn = add(this.add.text(panelX, panelY + PANEL_H - 28, '[ Abrir na Biblioteca ]', {
                fontSize: '12px', color: '#88ccff', fontFamily: 'Courier New',
            }).setOrigin(0.5, 0).setDepth(52).setInteractive({ useHandCursor: true }));
            libraryBtn.on('pointerover', () => libraryBtn.setColor('#ffffff'));
            libraryBtn.on('pointerout',  () => libraryBtn.setColor('#88ccff'));
            libraryBtn.on('pointerdown', () => this._openInLibrary(book.id));
        }

        // Close hint
        add(this.add.text(panelX, panelY + PANEL_H - 10, '[ Clique fora para fechar ]', {
            fontSize: '10px', color: '#333', fontFamily: 'Courier New',
        }).setOrigin(0.5, 1).setDepth(52));
    }

    _clearDetail() {
        this._detailObjs.forEach(o => o?.destroy());
        this._detailObjs = [];
    }

    _openInLibrary(bookId) {
        this.registry.set('pendingBookId', bookId);
        this.input.off('wheel');
        this._clearContent();
        this._clearDetail();
        // Stop Compendium without resuming World — Book will resume it on close
        this.scene.stop('Compendium');
        this.scene.launch('Book');
    }

    // ── Close ─────────────────────────────────────────────────────────────────

    _close() {
        this.input.off('wheel');
        this._clearContent();
        this._clearDetail();
        this.scene.stop();
        const world = this.scene.get('World');
        if (world?.resumeFromOverlay) world.resumeFromOverlay();
    }
}
