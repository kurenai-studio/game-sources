import * as Phaser from "phaser";

const width = 800
const height = 600

var config = {
    type: Phaser.AUTO,
    width: width,
    height: height,
    parent: "game-container",
    physics: {
        default: "arcade",
        arcade: {
            gravity: { y: 300 },
            debug: true
        }
    },
    scene: {
        preload: preload,
        create: create,
        update: update
    }
};

let player
let stars
let bombs
let platforms
let cursors
let keys
let score = 0
let gameOver = false
let scoreText

let game = new Phaser.Game(config)

function preload()
{
    this.load.image("sky", "assets/sky.png")
    this.load.image("star", "assets/star.png")
    this.load.image("bomb", "assets/bomb.png")
    this.load.image("platform", 'assets/platform.png')
    this.load.spritesheet("dude",
        "assets/dude.png",
        { frameWidth: 32, frameHeight: 48 }
    )
}

function create()
{
    // background
    const { centerX, centerY } = this.cameras.main;
    this.add.image(centerX, centerY, "sky")

    // platforms
    platforms = this.physics.add.staticGroup()
    platforms.create(400, 568, "platform").setScale(2).refreshBody()

    platforms.create(600, 400, "platform")
    platforms.create(50, 250, "platform")
    platforms.create(750, 220, "platform")

    // player
    player = this.physics.add.sprite(100, 450, "dude")

    player.setBounce(0.22)
    player.setCollideWorldBounds(true)

    // player animation (old school way)
    this.anims.create({
        key: "left",
        frames: this.anims.generateFrameNumbers("dude", { start: 0, end: 3 }),
        frameRate: 10,
        repeat: -1
    })

    this.anims.create({
        key: "turn",
        frames: [ { key: "dude", frame: 4 }],
        frameRate: 20
    })

    this.anims.create({
        key: "right",
        frames: this.anims.generateFrameNumbers("dude", { start: 5, end: 8 }),
        frameRate: 10,
        repeat: -1
    })


    // player movement
    // arrow keys
    cursors = this.input.keyboard.createCursorKeys();
    // wsad + space
    keys = this.input.keyboard.addKeys({
        up: Phaser.Input.Keyboard.KeyCodes.W,
        left: Phaser.Input.Keyboard.KeyCodes.A,
        Down: Phaser.Input.Keyboard.KeyCodes.S,
        right: Phaser.Input.Keyboard.KeyCodes.D,
        space: Phaser.Input.Keyboard.KeyCodes.SPACE,
    })

    // stars
    stars = this.physics.add.group({
        key: "star",
        repeat: 11, // 12 stars in total
        setXY: { x: 12, y: 0, stepX: 70 }
    })

    stars.getChildren().forEach(child => {
        child.setBounceY(Phaser.Math.FloatBetween(0.35, 0.6))
    })
    
    // bombs
    bombs = this.physics.add.group()

    // score
    scoreText = this.add.text(16, 16, "Score: 0", { fontSize: "32px", fill: "#000" })

    // make platforms collidable
    this.physics.add.collider(player, platforms)
    this.physics.add.collider(stars,  platforms)
    this.physics.add.collider(bombs,  platforms)
    // overlaps
    this.physics.add.overlap(player, stars, collectStar, null, this);
    this.physics.add.collider(player, bombs, hitBomb, null, this)
}

function update()
{
    if(gameOver){
        return
    }

    if (cursors.left.isDown || keys.left.isDown){
        player.setVelocityX(-160)
        player.anims.play("left", true)
    }
    else if (cursors.right.isDown || keys.right.isDown){
        player.setVelocityX(160)
        player.anims.play("right", true)
    }
    else {
        player.setVelocityX(0)
        player.anims.play("turn")
    }

    const isUpPressed = cursors.up.isDown || keys.up.isDown || keys.space.isDown
    if (isUpPressed && player.body.touching.down){
        player.setVelocityY(-330)
    }
}

function collectStar(player, star){
    // disable star
    star.disableBody(true, true)

    // increase scores
    score += 10
    scoreText.setText("Score: " + score)
    
    // check if all the stars are collected
    if (stars.countActive(true) === 0){
        stars.getChildren().forEach(child => {
            child.enableBody(true, child.x, 0, true, true)
        })

        let x = (player.x < 400) ? Phaser.Math.Between(400, 800) : Phaser.Math.Between(0, 400);

        let bomb = bombs.create(x, 16, "bomb")
        bomb.setBounce(1)
        bomb.setCollideWorldBounds(true)
        bomb.setVelocity(Phaser.Math.Between(-200, 200), 20)
    }
}

function hitBomb(player, bomb) {
    this.physics.pause()
    player.setTint(0xff0000)
    player.anims.play("turn")
    gameOver = true
}