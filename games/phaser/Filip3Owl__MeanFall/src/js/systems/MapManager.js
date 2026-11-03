import { TILE_SIZE, TILE_WALKABLE, AREA_INFO } from '../constants.js';
import { MAP_DATA } from '../data/maps.js';
import { TILE_TEXTURE_MAP, TILE_OVERLAYS, TILE_VARIANTS } from '../utils/Draw.js';

// Ground texture drawn beneath overlay tiles (trees, portals, chests, fences,
// furniture) so they blend with each area's terrain. Interiors use stone floor.
const AREA_GROUND = {
    village:   'tile_grass',
    meadows:   'tile_grass',
    forest:    'tile_dark_grass',
    plains:    'tile_sand',
    mountains: 'tile_snow',
    dungeon:   'tile_cave',
};

// Tiles altos que projetam sombra de contato no chão vizinho. O "sol" vem
// do alto-esquerda: sombra no tile abaixo e no tile à direita do caster.
const SHADOW_CASTERS = new Set([3, 4, 10, 13, 14, 17, 20, 26]);

export class MapManager {
    constructor(scene) {
        this.scene = scene;
        this.tiles = [];
        this.areaId = null;
        this.mapData = null;
        this._scrollSprites = [];
        this._decos = [];
    }

    load(areaId, playerData = null) {
        this.areaId  = areaId;
        this.mapData = MAP_DATA[areaId];
        // Working copy of the tile grid — secrets and runtime changes never
        // touch the shared MAP_DATA definition.
        this._grid = this.mapData.tiles.map(row => [...row]);

        // Apply already-discovered secret walls from the save
        const secrets = playerData?.secretsFound || {};
        for (const key of Object.keys(secrets)) {
            const [area, x, y] = key.split(':');
            if (area === areaId && this._grid[+y]?.[+x] === 26) {
                this._grid[+y][+x] = 12; // cave floor
            }
        }

        // Apply dug sites / broken boulders from the save
        const dug = playerData?.dugSites || {};
        for (const key of Object.keys(dug)) {
            const [area, x, y] = key.split(':');
            if (area !== areaId) continue;
            const t = this._grid[+y]?.[+x];
            if (t === 27) this._grid[+y][+x] = 24;                       // dig site → hole
            else if (t === 28) this._grid[+y][+x] = groundTileId(areaId); // boulder → floor
        }

        this._buildTiles();
        const info = AREA_INFO[areaId];
        if (info) this.scene.cameras.main.setBackgroundColor(info.bgColor);
    }

    // Opens a secret wall at (col,row): grid becomes cave floor and the tile
    // image is swapped in place. Persistence is the caller's responsibility.
    revealSecret(col, row) {
        if (this._grid?.[row]?.[col] !== 26) return false;
        this._grid[row][col] = 12;
        const img = this.tiles[row]?.[col];
        if (img) img.setTexture('tile_cave');
        return true;
    }

    // Digs a mound at (col,row): it becomes a hole (tile 24), whose exit is
    // already declared in the map data. Persistence is the caller's job.
    digSite(col, row) {
        if (this._grid?.[row]?.[col] !== 27) return false;
        this._grid[row][col] = 24;
        const img = this.tiles[row]?.[col];
        if (img) img.setTexture('tile_hole');
        return true;
    }

    // Breaks a boulder at (col,row) back into the area's walkable ground.
    breakBoulder(col, row) {
        if (this._grid?.[row]?.[col] !== 28) return false;
        const groundId = groundTileId(this.areaId);
        this._grid[row][col] = groundId;
        const img = this.tiles[row]?.[col];
        if (img) img.setTexture(TILE_TEXTURE_MAP[groundId] ?? 'tile_cave');
        return true;
    }

    _buildTiles() {
        // Clear old tiles and decorations
        this.tiles.forEach(row => row.forEach(img => img.destroy()));
        if (this._decos) this._decos.forEach(d => d.destroy());
        if (this._scrollSprites) this._scrollSprites.forEach(s => { s.sprite.destroy(); s.glow.destroy(); });
        
        this.tiles = [];
        this._decos = [];
        this._scrollSprites = [];

        const groundTex = AREA_GROUND[this.areaId]
            || (this.areaId?.endsWith('_depths') ? 'tile_cave' : 'tile_stone');

        const rows = this._grid;
        for (let row = 0; row < rows.length; row++) {
            this.tiles[row] = [];
            for (let col = 0; col < rows[row].length; col++) {
                const tileId  = rows[row][col];
                let texKey    = TILE_TEXTURE_MAP[tileId] ?? 'tile_grass';
                const x = col * TILE_SIZE + TILE_SIZE / 2;
                const y = row * TILE_SIZE + TILE_SIZE / 2;

                // Deterministic pseudo-random per-tile noise
                const seed = row * 13 + col * 37 + (this.areaId?.length || 0);
                const noise = Math.sin(seed);
                const chance = (noise + 1) / 2;

                // Overlay tiles (trees, portals, chests, ...) are transparent:
                // draw the area's ground underneath so they blend with terrain
                if (TILE_OVERLAYS.has(tileId)) {
                    const under = this.scene.add.image(x, y, groundTex).setDepth(0);
                    this._decos.push(under);
                } else if (TILE_VARIANTS[tileId]) {
                    // Alternate terrain variant to break visible tiling
                    const variants = TILE_VARIANTS[tileId];
                    const vNoise = (Math.sin(seed * 1.73 + 4.2) + 1) / 2;
                    texKey = variants[Math.floor(vNoise * variants.length) % variants.length];
                }

                const img = this.scene.add.image(x, y, texKey).setDepth(0);
                this.tiles[row][col] = img;

                // Sombras de contato suaves (ambient occlusion fake)
                if (!SHADOW_CASTERS.has(tileId)) {
                    if (row > 0 && SHADOW_CASTERS.has(rows[row - 1][col])) {
                        this._decos.push(this.scene.add.image(x, y - TILE_SIZE / 2, 'shadow_soft_h')
                            .setOrigin(0.5, 0).setDepth(0.5));
                    }
                    if (col > 0 && SHADOW_CASTERS.has(rows[row][col - 1])) {
                        this._decos.push(this.scene.add.image(x - TILE_SIZE / 2, y, 'shadow_soft_v')
                            .setOrigin(0, 0.5).setDepth(0.5));
                    }
                }

                const isIndoor = this.areaId?.includes('_house_') || this.areaId?.includes('_inn') || this.areaId?.includes('_shop');
                if (!isIndoor && chance > 0.75) {
                    let decoTex = null;
                    if (tileId === 0 || tileId === 9) { // Grass
                        if (chance > 0.96) decoTex = 'deco_flower_red';
                        else if (chance > 0.92) decoTex = 'deco_flower_blue';
                        else if (chance > 0.88) decoTex = 'deco_flower_white';
                        else decoTex = 'deco_grass_tuft';
                    } else if (tileId === 1) { // Stone
                        if (chance > 0.90) decoTex = 'deco_cracks';
                        else decoTex = 'deco_rock_small';
                    } else if (tileId === 8) { // Sand
                        if (chance > 0.92) decoTex = 'deco_cactus';
                        else decoTex = 'deco_rock_small';
                    } else if (tileId === 11) { // Snow
                        if (chance > 0.93) decoTex = 'deco_ice_crystal';
                        else decoTex = 'deco_snow_mound';
                    } else if (tileId === 12) { // Cave floor
                        if (chance > 0.97) decoTex = 'deco_bones';
                        else if (chance > 0.88) decoTex = 'deco_rock_small';
                    } else if (tileId === 3 && chance > 0.94) { // Wall — cracks only
                        decoTex = 'deco_cracks';
                    }

                    if (decoTex) {
                        const deco = this.scene.add.image(x, y, decoTex).setDepth(1).setAlpha(0.85);
                        if (noise > 0) deco.setFlipX(true);
                        this._decos.push(deco);
                    }
                }
            }
        }

        // Render fixed scrolls
        if (this.mapData.scrolls) {
            for (const s of this.mapData.scrolls) {
                const sx = s.x * TILE_SIZE + TILE_SIZE / 2;
                const sy = s.y * TILE_SIZE + TILE_SIZE / 2;
                const sprite = this.scene.add.image(sx, sy, 'item_scroll').setDepth(2).setScale(0.8);
                sprite.scrollId = s.scrollId;
                sprite.tileX = s.x;
                sprite.tileY = s.y;
                
                const glow = this.scene.add.circle(sx, sy, 8, 0x88ccff, 0.3).setDepth(1.5);
                this.scene.tweens.add({ targets: glow, alpha: 0.6, scale: 1.5, duration: 1200, yoyo: true, repeat: -1 });
                
                this._scrollSprites.push({ sprite, glow });
            }
        }
    }

    getScrollAt(x, y) {
        return this._scrollSprites?.find(s => s.sprite.tileX === x && s.sprite.tileY === y);
    }

    isWalkable(col, row) {
        const rows = this._grid;
        if (!rows || row < 0 || col < 0 || row >= rows.length || col >= rows[row].length) return false;
        return TILE_WALKABLE[rows[row][col]] ?? false;
    }

    getTileId(col, row) {
        return this._grid?.[row]?.[col] ?? -1;
    }

    getExit(col, row) {
        return (this.mapData?.exits || []).find(e => e.x === col && e.y === row) || null;
    }

    drawMinimap(canvas, playerData) {
        const ctx = canvas.getContext('2d');
        const rows = this._grid;
        if (!rows) return;
        const areaId = playerData.currentArea;
        const discovered = (playerData.discoveredTiles || {})[areaId] || {};
        
        const COLS = rows[0].length;
        const ROWS = rows.length;
        const cw = canvas.width  / COLS;
        const ch = canvas.height / ROWS;

        ctx.clearRect(0, 0, canvas.width, canvas.height);
        for (let r = 0; r < ROWS; r++) {
            for (let c = 0; c < COLS; c++) {
                if (discovered[`${c},${r}`]) {
                    ctx.fillStyle = miniColor(rows[r][c]);
                } else {
                    ctx.fillStyle = '#050308'; // Hidden
                }
                ctx.fillRect(c * cw, r * ch, cw, ch);
            }
        }
    }

    drawMinimapPlayer(canvas, col, row) {
        const rows = this._grid;
        if (!rows) return;
        const COLS = rows[0].length;
        const ROWS = rows.length;
        const cw = canvas.width  / COLS;
        const ch = canvas.height / ROWS;
        const ctx = canvas.getContext('2d');
        ctx.fillStyle = '#ffffff';
        ctx.fillRect(col * cw + cw * 0.1, row * ch + ch * 0.1, cw * 0.8, ch * 0.8);
    }
}

function miniColor(tileId) {
    const MAP = {
        0: '#3a7d44', 1: '#888888', 2: '#1a5fa8', 3: '#555555',
        4: '#2d6a2d', 5: '#4a3222', 6: '#9944ff', 7: '#8b6914',
        8: '#d4a647', 9: '#2a5d34', 10: '#666677', 11: '#ddddee', 12: '#2a2233',
        13: '#882211', 14: '#ffee88', 15: '#5c3a1e', 16: '#4a2d18',
        17: '#cc2222', 18: '#7a4c2a', 19: '#882222',
        24: '#0a0a14', 25: '#8b6914', 26: '#555555',
        27: '#5c4424', 28: '#5c5c68', 29: '#bb44ff',
    };
    return MAP[tileId] ?? '#111111';
}

// Walkable ground a broken boulder leaves behind, per area terrain.
function groundTileId(areaId) {
    if (!areaId || areaId.endsWith('_depths') || areaId.startsWith('dungeon')) return 12;
    if (areaId.startsWith('forest'))    return 9;
    if (areaId.startsWith('plains'))    return 8;
    if (areaId.startsWith('mountains')) return 11;
    return 0; // village / meadows grass
}
