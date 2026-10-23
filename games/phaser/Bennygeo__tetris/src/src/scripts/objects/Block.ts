import { TETRIS } from "./TETRIS";

export class Block extends TETRIS {

    color: any = null;
    x: any = null;
    y: any = null;

    sprite: any = null;
    tween: any = null;

    scene: Phaser.Scene;

    constructor() {
        // super({ key: 'PreloadScene' });
        super();
    }

    makeBlock(scope: Phaser.Scene, newX, newY, newColor) {

        this.scene = scope;
        // debugger;
        this.x = newX;
        this.y = newY;
        this.color = newColor;

        var spriteLocation = this.getSpriteLocation();

        this.sprite = scope.add.sprite(spriteLocation.x, spriteLocation.y, 'block', this.color).setOrigin(0, .6);
    }

    clean() {
        this.x = null;
        this.y = null;
        this.color = null;
        this.sprite.destroy();
        this.sprite = null;
    }

    getSpriteLocation(newX?: number, newY?: number) {
        var spriteX, spriteY;
        spriteX = this.LINING_WIDTH + (this.x * this.BLOCK_WIDTH);
        spriteY = this.BANNER_HEIGHT + (this.y * this.BLOCK_WIDTH);

        return { "x": spriteX, "y": spriteY };
    }

    moveBlock(newX, newY) {

        this.x = newX;
        this.y = newY;

        var spriteLocation = this.getSpriteLocation(newX, newY);
        var duration = 55;
        var repeat = 0;
        var ease = 'Power2';
        var autoStart = false;
        var delay = 0;
        var yoyo = false;

        // this.tween = this.scene.add.tween(this.sprite).to(spriteLocation, duration, ease, autoStart, delay, repeat, yoyo);

        this.tween = this.scene.tweens.add({
            targets: this.sprite,
            x: spriteLocation.x,
            y: spriteLocation.y,
            duration: duration,
            yoyo: false,
            onComplete: () => {
                // bob.destroy();
            }
        })
    }

}