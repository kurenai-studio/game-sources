/**
 * Whale Coin Collector
 * A Phaser 3 mini-game.
 */

class MainScene extends Phaser.Scene {
    constructor() {
        super('MainScene');
        this.score = 0;
    }

    preload() {
        // Load Whale Animation Frames
        this.load.image('whale1', 'assets/whale1.png');
        this.load.image('whale2', 'assets/whale2.png');
        this.load.image('whale3', 'assets/whale3.png');
        this.load.image('whale4', 'assets/whale4.png');

        // Load Coin Spritesheet
        // Assuming 16x16 frames in a grid
        this.load.spritesheet('coin', 'assets/coin.png', { 
            frameWidth: 16, 
            frameHeight: 16 
        });
    }

    create() {
        // 1. Create Animations
        this.anims.create({
            key: 'whale-swim',
            frames: [
                { key: 'whale1' },
                { key: 'whale2' },
                { key: 'whale3' },
                { key: 'whale4' }
            ],
            frameRate: 8,
            repeat: -1
        });

        this.anims.create({
            key: 'coin-spin',
            frames: this.anims.generateFrameNumbers('coin', { start: 0, end: 5 }),
            frameRate: 10,
            repeat: -1
        });

        // 2. Setup Player
        this.player = this.physics.add.sprite(100, 100, 'whale1');
        this.player.play('whale-swim');
        this.player.setCollideWorldBounds(true);

        // 3. Setup Coins
        this.coins = this.physics.add.sprite(300, 300, 'coin');
        this.coins.play('coin-spin');
        this.coins.setScale(2);

        // 4. UI: Score Text
        const style = { font: '24px Arial', fill: '#fff', stroke: '#000', strokeThickness: 4 };
        this.scoreText = this.add.text(20, 20, 'Score: 0', style);
        this.scoreText.setDepth(100);

        // 5. Input: Keyboard Cursor Keys
        this.cursors = this.input.keyboard.createCursorKeys();
    }

    update() {
        // Collision detection
        if (this.physics.overlap(this.player, this.coins)) {
            this.handleCoinCollection();
        }

        // Movement logic
        const speed = 4;
        if (this.cursors.right.isDown) {
            this.player.x += speed;
            this.player.setFlipX(false);
        } else if (this.cursors.left.isDown) {
            this.player.x -= speed;
            this.player.setFlipX(true);
        }

        if (this.cursors.down.isDown) {
            this.player.y += speed;
        } else if (this.cursors.up.isDown) {
            this.player.y -= speed;
        }
    }

    handleCoinCollection() {
        // Relocate coin
        this.coins.x = Phaser.Math.Between(50, 650);
        this.coins.y = Phaser.Math.Between(50, 350);

        // Update score
        this.score += 10;
        this.scoreText.setText('Score: ' + this.score);

        // Simple scale-up tween for feedback
        this.tweens.add({
            targets: this.player,
            duration: 100,
            scaleX: 1.1,
            scaleY: 1.1,
            yoyo: true
        });
    }
}

// Game Configuration
const config = {
    type: Phaser.AUTO,
    width: 700,
    height: 400,
    backgroundColor: '#87CEEB',
    parent: 'game',
    physics: {
        default: 'arcade',
        arcade: {
            debug: false
        }
    },
    scene: MainScene
};

// Initialize the game
const game = new Phaser.Game(config);