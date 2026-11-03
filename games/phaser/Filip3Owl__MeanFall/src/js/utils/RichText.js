// MeanFall — Rich text helper for Phaser
// Lets us write strings with inline color markup like:
//   "Você ganhou {{xp:+50 XP}} e {{loot:Poção de Vida}}!"
// and render them as a horizontal flow of colored Text objects.

export const RICH_COLORS = {
    damage:  '#ff5566',
    heal:    '#55ff88',
    crit:    '#ff88cc',
    xp:      '#ffaa22',
    gold:    '#ffd700',
    level:   '#ffaa44',
    loot:    '#ffd700',
    rare:    '#bb88ff',
    legend:  '#ffaa22',
    epic:    '#bb44ff',
    hint:    '#88ccff',
    mute:    '#888888',
    accent:  '#d4af37',
    good:    '#88ff88',
    bad:     '#ff5555',
    fire:    '#ff6644',
    water:   '#4488ff',
    earth:   '#88aa44',
    ice:     '#88ddff',
    shadow:  '#bb88ff',
    normal:  '#cccccc',
};

const TOKEN_RE = /\{\{(\w+):([^}]+)\}\}|([^{]+)/g;

/**
 * Layout a rich-text string as multiple Text objects flowing left-to-right
 * with word-wrap. Returns an array of game objects (caller is responsible
 * for adding them to a container or storing for cleanup).
 *
 * Tokens: {{key:text}} where key is one of RICH_COLORS keys.
 */
export function layoutRichText(scene, x, y, text, opts = {}) {
    const fontSize    = opts.fontSize    || '12px';
    const fontFamily  = opts.fontFamily  || 'Courier New';
    const wrapWidth   = opts.wrapWidth   || 500;
    const lineHeight  = opts.lineHeight  || 18;
    const baseColor   = opts.baseColor   || '#ddd5c8';
    const fontStyle   = opts.fontStyle   || 'normal';

    const out = [];
    let cx = 0, cy = 0;
    const matches = [...text.matchAll(TOKEN_RE)];

    for (const m of matches) {
        const key  = m[1];
        const body = m[2] ?? m[3] ?? '';
        const color = key ? (RICH_COLORS[key] || baseColor) : baseColor;
        const isAccent = !!key;

        // Tokenize body further so we can wrap on whitespace
        const parts = body.split(/(\s+)/);
        for (const part of parts) {
            if (part === '') continue;
            const txt = scene.add.text(0, 0, part, {
                fontSize, fontFamily, color, fontStyle: isAccent ? 'bold' : fontStyle,
            }).setOrigin(0, 0);
            const w = txt.width;
            if (cx + w > wrapWidth && part.trim() !== '') {
                cx = 0; cy += lineHeight;
            }
            txt.setPosition(x + cx, y + cy);
            cx += w;
            out.push(txt);
        }
    }
    return { objects: out, height: cy + lineHeight };
}

/**
 * One-line variant: parses tokens and returns a single concatenated
 * `<span>`-style HTML string (for DOM-based UIs). Used by chat log too.
 */
export function richToHtml(text) {
    return text.replace(/\{\{(\w+):([^}]+)\}\}/g, (_, key, body) => {
        const color = RICH_COLORS[key] || '#dddddd';
        return `<span style="color:${color};font-weight:bold">${body}</span>`;
    });
}
