const KEY      = 'statquest_save_v1';
const AUTO_KEY = 'statquest_autosave_v1';

export const SaveSystem = {

    save(slotIndex, playerData) {
        const slots = this.loadAll();
        slots[slotIndex] = {
            ...this._serialize(playerData),
            saveTimestamp: new Date().toISOString(),
            version: '1.0.0',
        };
        try {
            localStorage.setItem(KEY, JSON.stringify(slots));
            return true;
        } catch {
            return false;
        }
    },

    load(slotIndex) {
        const slots = this.loadAll();
        return slots[slotIndex] ?? null;
    },

    loadAll() {
        try {
            const raw = localStorage.getItem(KEY);
            const data = raw ? JSON.parse(raw) : {};
            return [data[0] ?? null, data[1] ?? null, data[2] ?? null];
        } catch {
            return [null, null, null];
        }
    },

    delete(slotIndex) {
        const slots = this.loadAll();
        slots[slotIndex] = null;
        localStorage.setItem(KEY, JSON.stringify(slots));
    },

    // Writes to a dedicated auto-slot, never touches manual save slots.
    autoSave(playerData) {
        try {
            const data = {
                ...this._serialize(playerData),
                saveTimestamp: new Date().toISOString(),
                version: '1.0.0',
                isAuto: true,
            };
            localStorage.setItem(AUTO_KEY, JSON.stringify(data));
            return true;
        } catch {
            return false;
        }
    },

    loadAuto() {
        try {
            const raw = localStorage.getItem(AUTO_KEY);
            return raw ? JSON.parse(raw) : null;
        } catch {
            return null;
        }
    },

    // Returns all saves (manual + auto) as a flat array for menu use.
    loadAllIncludingAuto() {
        return [...this.loadAll(), this.loadAuto()].filter(Boolean);
    },

    hasAnySave() {
        return this.loadAll().some(s => s !== null) || this.loadAuto() !== null;
    },

    _serialize(player) {
        if (player.toData) return player.toData();
        const { scene, sprite, shadow, ...rest } = player;
        return rest;
    },
};
