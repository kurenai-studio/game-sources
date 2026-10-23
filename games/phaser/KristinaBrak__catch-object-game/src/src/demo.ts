export default class Demo extends Phaser.Scene {

    logo: Phaser.Physics.Arcade.Sprite;

    constructor() {
        super('demo');
    }



    preload() {
        this.load.image('logo', 'assets/logo.png');
    }

    create() {
        // logo = this.add.image(400, 70, 'logo');
        this.logo = this.physics.add.sprite(0, 0, 'logo');
        // logo = game.add.sprite(0, 0, 'logo');
        this.logo.setCollideWorldBounds(true);
        this.logo.body.bounce.set(1);
        this.logo.body.velocity.set(100, 100);
        this.logo.setScale(0.5, 0.5);
        this.logo.setAngularVelocity(-50);
    }
}
