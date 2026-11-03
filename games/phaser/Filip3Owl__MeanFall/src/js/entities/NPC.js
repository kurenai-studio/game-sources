import { TILE_SIZE, NPC_NAMES } from '../constants.js';

export class NPC {
    constructor(scene, data) {
        this.scene   = scene;
        this.npcId   = data.npcId;
        this.role    = data.role || 'quest'; // 'quest' | 'shop' | 'lore'
        this.tileX   = data.x;
        this.tileY   = data.y;
        this.dialog  = data.dialog || [];
        this._dlgIdx = 0;

        const px = data.x * TILE_SIZE + TILE_SIZE / 2;
        const py = data.y * TILE_SIZE + TILE_SIZE / 2;

        const perNpc = `sprite_npc_${this.npcId}`;
        const texKey = scene.textures.exists(perNpc) ? perNpc
            : (this.role === 'shop' ? 'sprite_npc_shop' : 'sprite_npc');
        
        // Shadow
        this.shadow = scene.add.image(px, py + 8, 'entity_shadow').setScale(0.8).setDepth(2).setAlpha(0.6);
        
        this.sprite  = scene.add.image(px, py, texKey).setDepth(4);

        // Role badge above name — shops only; quest NPCs get the dynamic
        // '!' / '?' indicator from WorldScene instead (avoids double icons)
        if (this.role === 'shop') {
            this._badge = scene.add.text(px, py - 28, '$', {
                fontSize: '10px', color: '#ffcc44', fontFamily: 'Courier New', fontStyle: 'bold',
                stroke: '#000000', strokeThickness: 2,
            }).setOrigin(0.5).setDepth(7);
        }

        this._label = scene.add.text(px, py - 18, NPC_NAMES[data.npcId] || data.npcId, {
            fontSize: '8px', color: '#ffd700', backgroundColor: '#00000088',
        }).setOrigin(0.5).setDepth(6);

        // Subtle floating animation
        if (this._badge) {
            scene.tweens.add({
                targets: [this._badge], y: py - 32, duration: 700, yoyo: true, repeat: -1, ease: 'Sine.easeInOut',
            });
        }
    }

    isAdjacentTo(col, row) {
        return Math.abs(this.tileX - col) + Math.abs(this.tileY - row) === 1;
    }

    nextLine() {
        const line = this.dialog[this._dlgIdx % this.dialog.length];
        this._dlgIdx++;
        return line;
    }

    destroy() {
        this.sprite.destroy();
        this.shadow.destroy();
        this._label.destroy();
        this._badge?.destroy();
    }
}
