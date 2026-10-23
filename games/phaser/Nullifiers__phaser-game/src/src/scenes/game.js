import config from '../config';
import addFullScreenButton from '../helpers/add_fullscreen_button';

class Game extends Phaser.Scene {
    constructor() {
        super('game');

        this.portals = {};
        this.overlappingPortal = null;
    }

    preload() {
    }

    createBoundaries() {
        const bound1 = this.add.rectangle(0, -config.height * 10, 1, config.height * 11, 0x000000);
        bound1.setOrigin(0, 0);
        this.physics.add.existing(bound1);
        bound1.body.setImmovable(true);
        bound1.body.allowGravity = false;
        this.physics.add.collider(this.player, bound1);

        const bound2 = this.add.rectangle(config.width - 1, -config.height * 10, 1, config.height * 11, 0x000000);
        bound2.setOrigin(0, 0);
        this.physics.add.existing(bound2);
        bound2.body.setImmovable(true);
        bound2.body.allowGravity = false;
        this.physics.add.collider(this.player, bound2);
    }

    createPlayer() {
        this.player = this.add.rectangle(100, -100, config.playerWidth, config.playerHeight, 0xffffff);
        this.player.setOrigin(0, 0);
        this.physics.add.existing(this.player);
        // this.player.body.setCollideWorldBounds(true);
    }

    createPlatform(x, y, width, height = config.platformHeight) {
        const platform = this.add.rectangle(x, y, width, height, 0x333333);
        platform.setOrigin(0, 0);
        this.physics.add.existing(platform);
        platform.body.setImmovable(true);
        platform.body.allowGravity = false;
        this.physics.add.collider(this.player, platform);
    }

    createPlatforms() {
        const platforms = [
            [0, config.height - config.platformHeight, config.width - 16],
            [config.width - 16, config.height - 0.1, 16],
            [0, config.height - 100, config.width],
            [0, config.height - 100 - 32, config.width],
            [500, config.height - 190, 100],
            [600, config.height - 230, 100],
            [700, config.height - 280, config.width - 700],
            [100, config.height - 330, config.width - 200],
            [0, config.height - 600, 200]
        ];

        platforms.forEach((platform) => {
            this.createPlatform(...platform);
        });
    }

    createPortal(name, x, y, width = 16, height = 16) {
        const portal = this.add.rectangle(x, y, width, height, 0x0000ff);
        // portal.setAlpha(0);
        portal.setOrigin(0, 0);
        this.physics.add.existing(portal);
        portal.body.setImmovable(true);
        portal.body.allowGravity = false;
        portal.name = name;
        this.portals[name] = portal;
    }

    createPortals() {
        const portals = [
            ['zero', 10, config.height - 40],
            ['one', config.width - 16, config.height - 16],
            ['two', 10, config.height - 100 - 16],
            ['three', 150, config.height - 100 - 16],
            ['four', 500, config.height - 100 - 16],
            ['five', 300, config.height - 100 - 16],
            ['six', 10, config.height - 200],
            ['seven', 0, config.height - 330, 100],
            ['eight', 10, config.height - 680]
        ];

        portals.forEach((portal) => {
            this.createPortal(...portal);
        });
    }

    addPortalMapping(portal1, portal2) {
        this.physics.add.overlap(this.player, portal1, () => {
            if (this.overlappingPortal === portal1.name) return;

            this.player.body.x = portal2.body.x;
            this.player.body.y = portal2.body.y;
            this.overlappingPortal = portal2.name;

            this.time.addEvent({
                delay: 1000,
                callback: () => {
                    this.portalsEnabled = true;
                },
                callbackScope: this
            });
        });
    }

    addPortalOverlaps() {
        const mapping = {
            one: 'two',
            two: 'zero',
            three: 'four',
            four: 'three',
            five: 'six',
            six: 'zero',
            seven: 'eight'
        };
        Object.keys(mapping).forEach((key) => {
            this.addPortalMapping(this.portals[key], this.portals[mapping[key]]);
        });
    }

    setupCamera() {
        this.cameras.main.setBounds(0, -config.height * 10, config.width, config.height * 11);
        this.cameras.main.startFollow(this.player);
    }

    create() {
        addFullScreenButton(this);
        this.createPlayer();
        this.createBoundaries();
        this.cursors = this.input.keyboard.createCursorKeys();
        this.createPlatforms();
        this.createPortals();
        this.addPortalOverlaps();
        this.setupCamera();
    }

    update() {
        const { body: player } = this.player;
        player.setVelocityX(player.velocity.x / 1.05);
        if (this.cursors.left.isDown) {
            player.setVelocityX(-config.playerSpeed);
        } else if (this.cursors.right.isDown) {
            player.setVelocityX(config.playerSpeed);
        }

        if (this.cursors.up.isDown && player.touching.down) {
            player.setVelocityY(-config.playerJumpSpeed);
        }

        if (this.overlappingPortal && !this.physics.overlap(this.player, this.portals[this.overlappingPortal])) {
            this.overlappingPortal = null;
        }
    }
};

export default Game;
