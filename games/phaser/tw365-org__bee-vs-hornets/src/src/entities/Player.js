import { GAME_CONFIG } from '../config.js';
import { soundManager } from '../audio/SoundManager.js';

export class Player extends Phaser.Physics.Arcade.Sprite {
  constructor(scene, x, y) {
    super(scene, x, y, 'player_bee_1');
    scene.add.existing(this);
    scene.physics.add.existing(this);

    this.setCollideWorldBounds(true);
    // 物理引擎核心防空區約束：上方不超過 220px，下方不超過 585px (避免遮蓋 614px 血條 HUD)
    this.body.setBoundsRectangle(new Phaser.Geom.Rectangle(0, 220, 480, 365));
    this.setSize(24, 24);
    this.setOffset(4, 4);

    this.hp = GAME_CONFIG.PLAYER.MAX_HP;
    this.maxHp = GAME_CONFIG.PLAYER.MAX_HP;
    this.bombs = GAME_CONFIG.PLAYER.START_BOMBS;
    this.isInvulnerable = false;
    this.wingTimer = 0;
    this.wingFrame = 1;

    // 按鍵映射
    this.cursors = scene.input.keyboard.createCursorKeys();
    this.keyA = scene.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.A);
    this.keyD = scene.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.D);
    this.keyW = scene.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.W);
    this.keyS = scene.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.S);
    this.keySpace = scene.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE);
    this.keyX = scene.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.X);
    this.keyB = scene.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.B);
  }

  update(time, delta) {
    if (!this.active) return;

    // 拍翅動畫 (每 100ms 切換影格)
    this.wingTimer += delta;
    if (this.wingTimer > 90) {
      this.wingTimer = 0;
      this.wingFrame = this.wingFrame === 1 ? 2 : 1;
      this.setTexture(`player_bee_${this.wingFrame}`);
    }

    // 移動控制 (支援箭頭鍵、WASD 以及 Gamepad 搖桿與十字鍵)
    let vx = 0;
    let vy = 0;
    const speed = GAME_CONFIG.PLAYER.SPEED;

    // 鍵盤移動
    if (this.cursors.left.isDown || this.keyA.isDown) vx -= speed;
    if (this.cursors.right.isDown || this.keyD.isDown) vx += speed;
    if (this.cursors.up.isDown || this.keyW.isDown) vy -= speed;
    if (this.cursors.down.isDown || this.keyS.isDown) vy += speed;

    // Gamepad 支援 (Standard Gamepad / XInput)
    const pad = this.scene.input.gamepad?.getPad(0);
    let padFire = false;
    let padBombJustDown = false;

    if (pad && pad.connected) {
      // 1. 左類比搖桿 (Axes 0, 1) 含 ±0.2 死區濾波
      const deadzone = 0.2;
      const axisH = Math.abs(pad.axes[0]?.getValue() || 0) > deadzone ? pad.axes[0].getValue() : 0;
      const axisV = Math.abs(pad.axes[1]?.getValue() || 0) > deadzone ? pad.axes[1].getValue() : 0;

      if (axisH !== 0) vx = axisH * speed;
      if (axisV !== 0) vy = axisV * speed;

      // 2. D-Pad 十字鍵 (Buttons 14: Left, 15: Right, 12: Up, 13: Down)
      if (pad.isButtonDown(14)) vx -= speed;
      if (pad.isButtonDown(15)) vx += speed;
      if (pad.isButtonDown(12)) vy -= speed;
      if (pad.isButtonDown(13)) vy += speed;

      // 3. 按住 A 鍵 (Button 0) 連發
      padFire = pad.isButtonDown(0);

      // 4. B 鍵 (Button 1) 或 X 鍵 (Button 2) 核爆（邊緣偵測，只在按下瞬間觸發一次）
      const currentBombBtnDown = pad.isButtonDown(1) || pad.isButtonDown(2);
      if (currentBombBtnDown && !this.lastPadBombState) {
        padBombJustDown = true;
      }
      this.lastPadBombState = currentBombBtnDown;
    } else {
      this.lastPadBombState = false;
    }

    this.setVelocity(vx, vy);

    // 限制玩家活動範圍：上方不超過 220px，下方不超過 585px (保持在 614px 血條上方安全防空區)
    if (this.y < 220) this.y = 220;
    if (this.y > 585) this.y = 585;

    // 自動微傾斜感
    if (vx < 0) {
      this.setAngle(-12);
    } else if (vx > 0) {
      this.setAngle(12);
    } else {
      this.setAngle(0);
    }

    // 發射主武器 (鍵盤 Space 或 手把 A 鍵)
    if (this.keySpace.isDown || padFire) {
      this.scene.weaponSystem.fire(this.x, this.y, time);
    }

    // 發動必殺技花粉核爆 (鍵盤 X/B 或 手把 B/X 邊緣觸發)
    if (Phaser.Input.Keyboard.JustDown(this.keyX) || Phaser.Input.Keyboard.JustDown(this.keyB) || padBombJustDown) {
      this.useBomb();
    }
  }

  takeDamage(amount) {
    if (this.isInvulnerable || !this.active) return false;

    this.hp -= amount;
    soundManager.playHit();

    if (this.hp <= 0) {
      this.hp = 0;
      this.die();
      return true;
    }

    // 進入短暫無敵狀態並閃爍 (連動 GAME_CONFIG.PLAYER.INVULNERABLE_DURATION)
    this.isInvulnerable = true;
    const totalDuration = GAME_CONFIG.PLAYER.INVULNERABLE_DURATION || 1500;
    const flashCount = 6;
    const flashStep = Math.floor(totalDuration / (flashCount * 2));

    this.scene.tweens.add({
      targets: this,
      alpha: 0.2,
      duration: flashStep,
      yoyo: true,
      repeat: flashCount - 1,
      onComplete: () => {
        this.alpha = 1;
        this.isInvulnerable = false;
      }
    });

    return false;
  }

  useBomb() {
    if (this.bombs <= 0) return;
    this.bombs--;
    soundManager.playBomb();
    this.scene.triggerPollenSupernova();
  }

  die() {
    this.setActive(false);
    this.setVisible(false);
    this.body.stop();
    soundManager.playExplosion(true);
    this.scene.onPlayerDied();
  }
}
