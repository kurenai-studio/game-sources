import Phaser from 'phaser';
import { COLORS } from '../config';
import { sfx } from '../game/audio';
import { WEAPONS } from '../game/weapons';
import { BREACH_RANK, CAMPAIGNS, RANKS, SUPPRESSOR_RANK } from '../levels/campaigns';
import { attractBackdrop } from './backdrop';
import { insignia } from './TitleScene';
import { ACCENT, Button, DIM, display, fadeIn, FAINT, GOLD, goTo, KeyNav, panel, setupScreenCamera, stagger, style, TEXT, UI } from './ui';

/**
 * Closes a campaign as a small ceremony: the insignia stamped in, the new rank, a note from
 * whoever signs it, and any gun or kit issued with it.
 */
export class PromotionScene extends Phaser.Scene {
  private campaignId = '';

  constructor() {
    super('promotion');
  }

  init(data: { campaignId: string }): void {
    this.campaignId = data.campaignId;
  }

  create(): void {
    setupScreenCamera(this);
    this.cameras.main.setBackgroundColor(COLORS.void);
    attractBackdrop(this, 0.86);
    fadeIn(this, 600);
    sfx.menuAmbience(true);
    const c = CAMPAIGNS.find((x) => x.id === this.campaignId)!;
    const rank = c.rank + 1;
    const cx = 640;

    // The stamp: insignia, flash, rank.
    const kicker = this.add.text(cx, 96, 'PROMOTED', display(16, ACCENT)).setOrigin(0.5).setAlpha(0);
    const badge = insignia(this, cx, 150, rank, UI.gold).setScale(0).setAlpha(0);
    const flash = this.add.circle(cx, 150, 60, 0xffe9a8, 0.5).setScale(0).setBlendMode(Phaser.BlendModes.ADD);
    const title = this.add.text(cx, 240, RANKS[rank].toUpperCase(), display(64, '#f8fafc', { letterSpacing: 14 })).setOrigin(0.5).setAlpha(0).setScale(1.2);
    const rule = this.add.rectangle(cx, 284, 320, 2, UI.gold, 0.9).setScale(0, 1);

    this.tweens.add({ targets: kicker, alpha: 1, duration: 400, delay: 300 });
    this.tweens.add({
      // The higher ranks' chevrons stack taller: they're scaled to fit between kicker and title.
      targets: badge, scale: Math.min(1.8, 70 / (rank * 9)), alpha: 1, duration: 420, delay: 600, ease: 'Back.Out',
      onStart: () => sfx.secured(),
    });
    this.tweens.add({ targets: flash, scale: 3, alpha: 0, duration: 600, delay: 640, ease: 'Quad.Out' });
    this.tweens.add({ targets: title, alpha: 1, scale: 1, duration: 500, delay: 900, ease: 'Cubic.Out' });
    this.tweens.add({ targets: rule, scaleX: 1, duration: 600, delay: 1150, ease: 'Cubic.Out' });

    // The note, then who signed it.
    const lines = c.promotion.note.map((l, i) => this.add.text(cx, 312 + i * 30, l, style(15, TEXT, { align: 'center', wordWrap: { width: 760 } })).setOrigin(0.5, 0));
    const sigY = 312 + lines.length * 30 + 10;
    const signature = this.add.text(cx, sigY, `— ${c.promotion.from ?? 'Captain Hale'}`, style(13, DIM, { fontStyle: 'italic' })).setOrigin(0.5, 0);
    stagger(this, [...lines, signature], 1400, 260, 6);

    // What comes with it.
    const suppressors = rank === SUPPRESSOR_RANK, charge = rank === BREACH_RANK;
    const gun = c.promotion.unlocks ? WEAPONS[c.promotion.unlocks] : null;
    const issued: Phaser.GameObjects.GameObject[] = [];
    if (gun || suppressors || charge) {
      const y = sigY + 48;
      const box = this.add.container(0, 0);
      box.add(panel(this, cx - 260, y, 520, 84, UI.gold));
      box.add(this.add.text(cx - 232, y + 16, 'ISSUED', display(12, GOLD)));
      const name = gun ? gun.name : suppressors ? 'Suppressors' : 'Breach charge';
      const blurb = gun ? gun.blurb : suppressors ? 'Fit them from the loadout on any briefing.' : 'One per mission. G on a wall, then stand back. Loud.';
      box.add(this.add.text(cx - 232, y + 34, name.toUpperCase(), display(24, TEXT)));
      box.add(this.add.text(cx + 232, y + 42, blurb, style(11, FAINT, { wordWrap: { width: 250 }, align: 'right' })).setOrigin(1, 0.5));
      issued.push(box);
      stagger(this, issued, 1400 + (lines.length + 1) * 260 + 200, 0, 14);
    }

    const go = () => goTo(this, 'menu');
    const cont = new Button(this, cx, 650, 240, 46, 'CONTINUE', go, { primary: true, size: 17 });
    const nav = new KeyNav(this, [cont]);
    cont.nav = nav;
    stagger(this, [cont.container], 1400 + (lines.length + 1) * 260 + 500, 0, 10);
  }
}
