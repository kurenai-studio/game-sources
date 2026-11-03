import { TILE_SIZE } from '../constants.js';
import { Sound } from '../utils/SoundSystem.js';

// tileId → footstep timbre (see Sound.step)
const STEP_TERRAIN = { 1: 'stone', 8: 'sand', 11: 'snow', 12: 'cave' };

export class Player {
    constructor(scene, data) {
        this.scene = scene;
        Object.assign(this, data);

        const px = this.position.x * TILE_SIZE + TILE_SIZE / 2;
        const py = this.position.y * TILE_SIZE + TILE_SIZE / 2;

        // Shadow
        this.shadow = scene.add.image(px, py + 10, 'entity_shadow').setScale(0.85).setDepth(2).setAlpha(0.6);

        this.sprite = scene.add.image(px, py, 'sprite_player').setDepth(5);

        this._moveCooldown = 0;
        this._moveDelay    = 180;
        this._bumpCooldown = 0;
        this._facing = 'down';
    }

    update(delta, cursors, wasd, mapManager) {
        this._moveCooldown -= delta;
        this._bumpCooldown -= delta;
        if (this._moveCooldown > 0) return null;

        let dx = 0, dy = 0;
        if (cursors.left.isDown  || wasd.left.isDown)  dx = -1;
        if (cursors.right.isDown || wasd.right.isDown) dx =  1;
        if (cursors.up.isDown    || wasd.up.isDown)    dy = -1;
        if (cursors.down.isDown  || wasd.down.isDown)  dy =  1;

        if (dx !== 0 && dy !== 0) dy = 0;
        if (dx === 0 && dy === 0) return null;

        const nx = this.position.x + dx;
        const ny = this.position.y + dy;

        if (!mapManager.isWalkable(nx, ny)) {
            // Dull knock when walking into an obstacle (throttled while key held)
            if (this._bumpCooldown <= 0) {
                Sound.bump();
                this._bumpCooldown = 400;
            }
            return null;
        }

        this.position.x = nx;
        this.position.y = ny;
        const npx = nx * TILE_SIZE + TILE_SIZE / 2;
        const npy = ny * TILE_SIZE + TILE_SIZE / 2;
        this.sprite.setPosition(npx, npy);
        this.shadow.setPosition(npx, npy + 10);
        this._moveCooldown = this._moveDelay;

        Sound.step(STEP_TERRAIN[mapManager.getTileId(nx, ny)] || 'grass');

        return { x: nx, y: ny };
    }

    syncSprite() {
        const px = this.position.x * TILE_SIZE + TILE_SIZE / 2;
        const py = this.position.y * TILE_SIZE + TILE_SIZE / 2;
        this.sprite.setPosition(px, py);
        this.shadow.setPosition(px, py + 10);
    }

    refreshTexture() {
        if (this.sprite) this.sprite.setTexture('sprite_player');
    }

    takeDamage(amount) { this.hp = Math.max(0, this.hp - amount); }
    heal(amount)       { this.hp = Math.min(this.maxHp, this.hp + amount); }

    toData() {
        const { scene, sprite, shadow, _moveCooldown, _moveDelay, _bumpCooldown, _facing, ...data } = this;
        return data;
    }

    destroy() { 
        this.sprite.destroy(); 
        this.shadow.destroy();
    }
}
