import Phaser from 'phaser';
import { generateTextures } from '../utils/textures';
import { SHIPS, SHIP_KEYS, ShipKey } from '../config/ships';
import { GAME_WIDTH, GAME_HEIGHT } from '../config/game';

export class StartScene extends Phaser.Scene {
  private selectedIndex = 0;
  private shipCards: Phaser.GameObjects.Container[] = [];
  private stars: Phaser.GameObjects.Image[] = [];
  private selectIndicator!: Phaser.GameObjects.Graphics;

  constructor() {
    super({ key: 'StartScene' });
  }

  create(): void {
    // Generate all textures (idempotent — only first time)
    if (!this.textures.exists('f35')) {
      generateTextures(this);
    }

    // Scrolling star background
    this.createStarfield();

    // Title
    this.add
      .text(GAME_WIDTH / 2, 40, 'BYE BYE ALIEN', {
        fontSize: '36px',
        color: '#44eeff',
        fontFamily: 'monospace',
        fontStyle: 'bold',
      })
      .setOrigin(0.5)
      .setDepth(10);

    this.add
      .text(GAME_WIDTH / 2, 75, 'CHOOSE YOUR SHIP', {
        fontSize: '18px',
        color: '#aaaaaa',
        fontFamily: 'monospace',
      })
      .setOrigin(0.5)
      .setDepth(10);

    // Selection indicator (drawn behind the active card)
    this.selectIndicator = this.add.graphics().setDepth(4);

    // Create ship cards
    this.createShipCards();

    // Highlight the default selection
    this.updateSelection();

    // Keyboard input
    if (this.input.keyboard) {
      this.input.keyboard.on('keydown-LEFT', () => this.changeSelection(-1));
      this.input.keyboard.on('keydown-RIGHT', () => this.changeSelection(1));
      this.input.keyboard.on('keydown-A', () => this.changeSelection(-1));
      this.input.keyboard.on('keydown-D', () => this.changeSelection(1));
      this.input.keyboard.on('keydown-ENTER', () => this.launchGame());
      this.input.keyboard.on('keydown-SPACE', () => this.launchGame());
    }

    // Controls hint
    this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT - 30, '← → to select  •  ENTER / SPACE to launch', {
        fontSize: '14px',
        color: '#666666',
        fontFamily: 'monospace',
      })
      .setOrigin(0.5)
      .setDepth(10);
  }

  update(_time: number, _delta: number): void {
    this.updateStarfield();
  }

  /* ---------------------------------------------------------------- */
  /*  Ship cards                                                       */
  /* ---------------------------------------------------------------- */

  private createShipCards(): void {
    const cardW = 170;
    const cardH = 310;
    const gap = 16;
    const totalW = SHIP_KEYS.length * cardW + (SHIP_KEYS.length - 1) * gap;
    const startX = (GAME_WIDTH - totalW) / 2 + cardW / 2;
    const cardY = 100 + cardH / 2;

    for (let i = 0; i < SHIP_KEYS.length; i++) {
      const key = SHIP_KEYS[i];
      const stats = SHIPS[key];
      const cx = startX + i * (cardW + gap);

      const container = this.add.container(cx, cardY).setDepth(5);

      // Card background
      const bg = this.add.graphics();
      bg.fillStyle(0x111122, 0.85);
      bg.fillRoundedRect(-cardW / 2, -cardH / 2, cardW, cardH, 8);
      bg.lineStyle(1, 0x334466);
      bg.strokeRoundedRect(-cardW / 2, -cardH / 2, cardW, cardH, 8);
      container.add(bg);

      // Ship preview sprite (rotated 90° to face right, like in-game)
      const preview = this.add.image(0, -cardH / 2 + 70, stats.textureKey);
      preview.setScale(1.2);
      preview.setAngle(90);
      container.add(preview);

      // Ship name
      const nameText = this.add
        .text(0, -cardH / 2 + 120, stats.name, {
          fontSize: '16px',
          color: '#ffffff',
          fontFamily: 'monospace',
          fontStyle: 'bold',
          align: 'center',
        })
        .setOrigin(0.5);
      container.add(nameText);

      // Description
      const descText = this.add
        .text(0, -cardH / 2 + 145, stats.description, {
          fontSize: '10px',
          color: '#888888',
          fontFamily: 'monospace',
          align: 'center',
          wordWrap: { width: cardW - 20 },
        })
        .setOrigin(0.5, 0);
      container.add(descText);

      // Stats bars
      const statsY = -cardH / 2 + 190;
      const barConfigs = [
        { label: 'SPD', value: stats.speed, max: 500, color: 0x44eeff },
        { label: 'HP',  value: stats.hp,    max: 250, color: 0x44ff44 },
        { label: 'DMG', value: stats.damage, max: 30, color: 0xff6644 },
        { label: 'ROF', value: stats.fireRate, max: 12, color: 0xffaa44 },
      ];

      for (let j = 0; j < barConfigs.length; j++) {
        const cfg = barConfigs[j];
        const sy = statsY + j * 24;

        const label = this.add
          .text(-cardW / 2 + 10, sy, cfg.label, {
            fontSize: '11px',
            color: '#aaaaaa',
            fontFamily: 'monospace',
          })
          .setOrigin(0, 0.5);
        container.add(label);

        const barX = -cardW / 2 + 45;
        const barW = cardW - 60;
        const barH = 8;

        const barBg = this.add.graphics();
        barBg.fillStyle(0x222233);
        barBg.fillRect(barX, sy - barH / 2, barW, barH);
        container.add(barBg);

        const barFg = this.add.graphics();
        const ratio = Math.min(1, cfg.value / cfg.max);
        barFg.fillStyle(cfg.color);
        barFg.fillRect(barX, sy - barH / 2, barW * ratio, barH);
        container.add(barFg);
      }

      // Bullet preview
      const bulletPreview = this.add.image(0, statsY + 4 * 24 + 10, stats.bulletTextureKey);
      bulletPreview.setScale(2);
      container.add(bulletPreview);

      // Make clickable
      const hitZone = this.add
        .zone(0, 0, cardW, cardH)
        .setInteractive({ useHandCursor: true });
      hitZone.on('pointerdown', () => {
        this.selectedIndex = i;
        this.updateSelection();
        this.launchGame();
      });
      hitZone.on('pointerover', () => {
        if (this.selectedIndex !== i) {
          this.selectedIndex = i;
          this.updateSelection();
        }
      });
      container.add(hitZone);

      this.shipCards.push(container);
    }
  }

  /* ---------------------------------------------------------------- */
  /*  Selection                                                        */
  /* ---------------------------------------------------------------- */

  private changeSelection(dir: number): void {
    this.selectedIndex = (this.selectedIndex + dir + SHIP_KEYS.length) % SHIP_KEYS.length;
    this.updateSelection();
  }

  private updateSelection(): void {
    const cardW = 170;
    const cardH = 310;

    this.selectIndicator.clear();

    const container = this.shipCards[this.selectedIndex];
    if (!container) return;

    // Glow border around the selected card
    this.selectIndicator.lineStyle(2, 0x44eeff, 1);
    this.selectIndicator.strokeRoundedRect(
      container.x - cardW / 2 - 2,
      container.y - cardH / 2 - 2,
      cardW + 4,
      cardH + 4,
      10,
    );

    // Subtle glow fill
    this.selectIndicator.fillStyle(0x44eeff, 0.06);
    this.selectIndicator.fillRoundedRect(
      container.x - cardW / 2,
      container.y - cardH / 2,
      cardW,
      cardH,
      8,
    );
  }

  /* ---------------------------------------------------------------- */
  /*  Launch                                                           */
  /* ---------------------------------------------------------------- */

  private launchGame(): void {
    const shipKey = SHIP_KEYS[this.selectedIndex];
    this.scene.start('GameScene', { ship: shipKey });
  }

  /* ---------------------------------------------------------------- */
  /*  Starfield (same as GameScene)                                    */
  /* ---------------------------------------------------------------- */

  private createStarfield(): void {
    this.stars = [];
    for (let i = 0; i < 80; i++) {
      const star = this.add.image(
        Phaser.Math.Between(0, GAME_WIDTH),
        Phaser.Math.Between(0, GAME_HEIGHT),
        'star',
      );
      star.setAlpha(0.3 + Math.random() * 0.7);
      star.setDepth(0);
      (star as any)._speed = 0.3 + Math.random() * 1.0;
      this.stars.push(star);
    }
  }

  private updateStarfield(): void {
    for (const star of this.stars) {
      star.x -= (star as any)._speed;
      if (star.x < 0) {
        star.x = GAME_WIDTH;
        star.y = Phaser.Math.Between(0, GAME_HEIGHT);
      }
    }
  }
}
