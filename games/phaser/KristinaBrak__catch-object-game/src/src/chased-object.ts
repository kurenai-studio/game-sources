import { Physics } from "phaser";
import Player from "./player";


export default class ChasedObject {

    sprite: Physics.Arcade.Sprite;
    scene: Phaser.Scene;
    player: Player;
    exist = 0;


    constructor(scene: Phaser.Scene, player: Player, key: string) {
        this.scene = scene;
        this.player = player;
        const x = Math.random() * this.scene.cameras.main.centerX * 2;
        const y = Math.random() * this.scene.cameras.main.centerY * 2;
        this.exist += 1;
        this.sprite = scene.physics.add.sprite(x, y, 'heart');

    }

    move() {
        while (Phaser.Math.Distance.Between(this.sprite.x, this.sprite.y, this.player.sprite.x, this.player.sprite.y) < 100) {
            const x = Math.random() * this.scene.cameras.main.centerX * 2;
            const y = Math.random() * this.scene.cameras.main.centerY * 2;
            this.sprite.x = x;
            this.sprite.y = y;
        }
    }
}