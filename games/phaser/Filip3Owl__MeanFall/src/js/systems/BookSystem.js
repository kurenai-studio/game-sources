import { BOOKS, BOOK_DROPS, BOOK_IMPORTANCE } from '../data/books.js';
import { awardXP } from './XPSystem.js';
import EventBus from '../utils/EventBus.js';

export const BookSystem = {

    init(player) {
        if (!player.bookLibrary) player.bookLibrary = {}; // bookId -> { owned, read }
    },

    rollBookDrops(monsterId) {
        const table = BOOK_DROPS[monsterId] || [];
        return table.filter(e => Math.random() < (e.chance ?? 0)).map(e => e.bookId);
    },

    addBook(player, bookId) {
        this.init(player);
        if (!BOOKS[bookId]) return false;
        const entry = player.bookLibrary[bookId] || { owned: 0, read: false };
        entry.owned += 1;
        player.bookLibrary[bookId] = entry;
        return true;
    },

    /** Mark book as read; grants XP and one-time stat bonus. */
    readBook(player, bookId) {
        this.init(player);
        const book = BOOKS[bookId];
        if (!book) return { ok: false, reason: 'Livro inexistente' };
        const entry = player.bookLibrary[bookId];
        if (!entry || entry.owned <= 0) return { ok: false, reason: 'Você não possui este livro' };

        const importance = BOOK_IMPORTANCE[book.importance] || BOOK_IMPORTANCE.normal;
        let firstRead = false;
        if (!entry.read) {
            firstRead = true;
            entry.read = true;
            // One-time rewards: XP + stat bonus
            if (importance.xp) awardXP(player, importance.xp);
            if (importance.bonus) {
                for (const [k, v] of Object.entries(importance.bonus)) {
                    player[k] = (player[k] || 0) + v;
                }
                EventBus.emit('player-stats-changed', { player });
                EventBus.emit('player-hp-change',     { player });
            }
        }
        return { ok: true, firstRead, book, importance };
    },

    ownedBooks(player) {
        this.init(player);
        return Object.entries(player.bookLibrary)
            .filter(([, e]) => e.owned > 0)
            .map(([id, e]) => ({ id, ...e, book: BOOKS[id] }))
            .filter(x => x.book);
    },
};
