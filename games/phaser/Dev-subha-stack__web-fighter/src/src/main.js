// src/main.js
// Simple 2D fighting prototype using Phaser 3

class GameScene extends Phaser.Scene {
  constructor() {
    super('GameScene');
  }

  preload() {}

  create() {
    // create simple textures (player, enemy, hitbox)
    const g = this.add.graphics();
    g.fillStyle(0x4caf50, 1); g.fillRect(0,0,48,64); g.generateTexture('player',48,64); g.clear();
    g.fillStyle(0xf44336, 1); g.fillRect(0,0,48,64); g.generateTexture('enemy',48,64); g.clear();
    g.fillStyle(0xffeb3b, 1); g.fillRect(0,0,28,16); g.generateTexture('hitbox',28,16); g.destroy();

    // world
    this.physics.world.setBounds(0,0,800,450);
    this.add.rectangle(400,225,800,450,0x222);
    const ground = this.add.rectangle(400,420,800,60,0x333);
    this.physics.add.existing(ground, true);

    // players
    this.player = this.physics.add.sprite(200,360,'player').setCollideWorldBounds(true);
    this.enemy  = this.physics.add.sprite(600,360,'enemy').setCollideWorldBounds(true);
    this.player.setSize(32,56).setOffset(8,4);
    this.enemy.setSize(32,56).setOffset(8,4);

    this.player.health = 100;
    this.enemy.health = 100;

    this.physics.add.collider(this.player, ground);
    this.physics.add.collider(this.enemy, ground);

    // groups for hitboxes
    this.hitboxes = this.physics.add.group({allowGravity:false});

    // overlap checks
    this.physics.add.overlap(this.hitboxes, this.enemy, this.onHitEnemy, null, this);
    this.physics.add.overlap(this.hitboxes, this.player, this.onHitPlayer, null, this);

    // input
    this.cursors = this.input.keyboard.createCursorKeys();
    this.keys = this.input.keyboard.addKeys({z:Phaser.Input.Keyboard.KeyCodes.Z, x:Phaser.Input.Keyboard.KeyCodes.X, c:Phaser.Input.Keyboard.KeyCodes.C});

    // simple states
    this.player.canAttack = true;
    this.enemy.canAttack = true;

    // UI
    this.healthBarPlayer = this.add.graphics();
    this.healthBarEnemy = this.add.graphics();
    this.roundText = this.add.text(400,20,'', {font:'18px monospace', color:'#fff'}).setOrigin(0.5);

    // camera
    this.cameras.main.setBounds(0,0,800,450);

    // enemy AI timer
    this.time.addEvent({delay:800, loop:true, callback:this.enemyThink, callbackScope:this});

    this.roundOver = false;
    this.updateUI();
  }

  onHitEnemy(hitbox, enemy) {
    if (!hitbox.active) return;
    if (hitbox.owner === 'player') {
      hitbox.setActive(false).setVisible(false);
      enemy.health = Math.max(0, enemy.health - hitbox.damage);
      enemy.setTint(0xffaaaa);
      this.time.delayedCall(100, ()=>enemy.clearTint());
      this.updateUI();
      if (enemy.health <= 0) this.endRound('Player');
    }
  }

  onHitPlayer(hitbox, player) {
    if (!hitbox.active) return;
    if (hitbox.owner === 'enemy') {
      hitbox.setActive(false).setVisible(false);
      player.health = Math.max(0, player.health - hitbox.damage);
      player.setTint(0xffaaaa);
      this.time.delayedCall(100, ()=>player.clearTint());
      this.updateUI();
      if (player.health <= 0) this.endRound('CPU');
    }
  }

  spawnHitbox(x,y,w,h,owner,damage,duration=120) {
    const hb = this.add.rectangle(x,y,w,h,0xffff00,0.01);
    this.physics.add.existing(hb);
    hb.body.allowGravity = false;
    hb.owner = owner;
    hb.damage = damage;
    this.hitboxes.add(hb);
    hb.setActive(true).setVisible(false);
    this.time.delayedCall(duration, ()=>{ hb.destroy(); });
    return hb;
  }

  playerAttack(type) {
    if (!this.player.canAttack || this.roundOver) return;
    this.player.canAttack = false;
    const dir = this.player.flipX ? -1 : 1;
    let dmg = 8; let w=28,h=16,ox=36;
    if (type==='heavy'){ dmg=18; w=36; ox=42; }
    if (type==='special'){ dmg=28; w=44; ox=48; }
    const x = this.player.x + ox*dir;
    const y = this.player.y - 10;
    this.spawnHitbox(x,y,w,h,'player',dmg);
    this.player.setTint(0x88ff88);
    this.time.delayedCall(150, ()=>this.player.clearTint());
    this.time.delayedCall(300, ()=>{ this.player.canAttack = true; });
  }

  enemyAttack() {
    if (!this.enemy.canAttack || this.roundOver) return;
    this.enemy.canAttack = false;
    const dir = this.enemy.x < this.player.x ? 1 : -1;
    const x = this.enemy.x + 36*dir;
    const y = this.enemy.y - 10;
    const dmg = Phaser.Math.RND.pick([6,12,20]);
    this.spawnHitbox(x,y,28,16,'enemy',dmg);
    this.enemy.setTint(0xffdd88);
    this.time.delayedCall(120, ()=>this.enemy.clearTint());
    this.time.delayedCall(500, ()=>{ this.enemy.canAttack = true; });
  }

  enemyThink() {
    if (this.roundOver) return;
    // simple AI: move toward player, sometimes attack
    const dist = this.player.x - this.enemy.x;
    if (Math.abs(dist) > 80) {
      const speed = dist>0?50:-50;
      this.enemy.setVelocityX(speed);
      this.enemy.flipX = dist>0?false:true;
    } else {
      this.enemy.setVelocityX(0);
      if (Phaser.Math.Between(0,100) > 70) this.enemyAttack();
    }
  }

  endRound(winner) {
    this.roundOver = true;
    this.roundText.setText(winner + ' wins! Press R to restart');
    this.player.setVelocity(0,0);
    this.enemy.setVelocity(0,0);
  }

  updateUI() {
    // player
    this.healthBarPlayer.clear();
    this.healthBarPlayer.fillStyle(0x000000); this.healthBarPlayer.fillRect(20,20,300,16);
    this.healthBarPlayer.fillStyle(0x76ff03); this.healthBarPlayer.fillRect(22,22, (this.player.health/100)*296,12);
    // enemy
    this.healthBarEnemy.clear();
    this.healthBarEnemy.fillStyle(0x000000); this.healthBarEnemy.fillRect(480,20,300,16);
    this.healthBarEnemy.fillStyle(0xff5252); this.healthBarEnemy.fillRect(482,22, (this.enemy.health/100)*296,12);
  }

  resetRound() {
    this.player.health = 100; this.enemy.health = 100;
    this.player.x = 200; this.player.y = 360; this.player.setVelocity(0,0);
    this.enemy.x = 600; this.enemy.y = 360; this.enemy.setVelocity(0,0);
    this.roundOver = false; this.roundText.setText('');
    this.updateUI();
  }

  update(time, delta) {
    // restart
    if (this.input.keyboard.checkDown(this.input.keyboard.addKey('R'), 250) && this.roundOver) {
      this.resetRound();
    }

    // player controls
    if (!this.roundOver) {
      const speed = 160;
      if (this.cursors.left.isDown) { this.player.setVelocityX(-speed); this.player.flipX = true; }
      else if (this.cursors.right.isDown) { this.player.setVelocityX(speed); this.player.flipX = false; }
      else { this.player.setVelocityX(0); }

      if (Phaser.Input.Keyboard.JustDown(this.cursors.up) && this.player.body.blocked.down) {
        this.player.setVelocityY(-320);
      }

      if (Phaser.Input.Keyboard.JustDown(this.keys.z)) this.playerAttack('light');
      if (Phaser.Input.Keyboard.JustDown(this.keys.x)) this.playerAttack('heavy');
      if (Phaser.Input.Keyboard.JustDown(this.keys.c)) this.playerAttack('special');
    }

    // keep UI updated (could be optimized)
    this.updateUI();
  }
}

const config = {
  type: Phaser.AUTO,
  width: 800,
  height: 450,
  backgroundColor: '#111',
  parent: 'game-container',
  physics: { default: 'arcade', arcade: { gravity: { y: 800 }, debug: false } },
  scene: [ GameScene ]
};

window.game = new Phaser.Game(config);
