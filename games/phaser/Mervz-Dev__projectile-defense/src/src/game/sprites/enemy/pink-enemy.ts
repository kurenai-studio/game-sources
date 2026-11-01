import { Enemy } from "./enemy";

export class PinkEnemy extends Enemy {
    constructor(scene: Phaser.Scene, x: number, y: number) {
        super(scene, x, y, "pink_enemy", {
            name: "PinkEnemy",
            speed: -200,
            health: 2,
            damage: 2,
            scoreValue: 10,
        });
    }
}

