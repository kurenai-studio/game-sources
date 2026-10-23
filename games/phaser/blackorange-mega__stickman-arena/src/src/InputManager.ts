import Phaser from "phaser";
import { GAME_HEIGHT, GAME_WIDTH } from "./config";

/**
 * Unifies keyboard (desktop/web) and on-screen touch buttons (mobile) into one
 * simple interface the FightScene reads each frame.
 *
 * Movement is reported as held booleans; actions are edge-triggered and must be
 * consumed (read-once) so a single tap performs exactly one move.
 */
export class InputManager {
  /** Held movement/guard state from on-screen touch buttons. */
  private touchLeft = false;
  private touchRight = false;
  private touchGuard = false;

  /** Movement is "held" — true while a left/right key OR touch button is down. */
  get left(): boolean {
    return this.touchLeft || this.keyDown("A", "LEFT");
  }
  get right(): boolean {
    return this.touchRight || this.keyDown("D", "RIGHT");
  }
  /** Guard is "held" — true while the guard key OR button is down. */
  get guard(): boolean {
    return this.touchGuard || this.keyDown("S", "DOWN");
  }

  private keyDown(...names: string[]): boolean {
    if (!this.keys) return false;
    return names.some((n) => this.keys![n]?.isDown);
  }

  private jumpQueued = false;
  private lightQueued = false;
  private heavyQueued = false;
  private specialQueued = false;

  private keys?: Record<string, Phaser.Input.Keyboard.Key>;

  constructor(private scene: Phaser.Scene) {
    this.setupKeyboard();
    this.setupTouchButtons();
  }

  // --- consumption API (edge-triggered actions) ---
  consumeJump(): boolean {
    const v = this.jumpQueued;
    this.jumpQueued = false;
    return v;
  }
  consumeLight(): boolean {
    const v = this.lightQueued;
    this.lightQueued = false;
    return v;
  }
  consumeHeavy(): boolean {
    const v = this.heavyQueued;
    this.heavyQueued = false;
    return v;
  }
  consumeSpecial(): boolean {
    const v = this.specialQueued;
    this.specialQueued = false;
    return v;
  }

  private setupKeyboard(): void {
    const kb = this.scene.input.keyboard;
    if (!kb) return; // touch-only device

    this.keys = kb.addKeys(
      "A,D,LEFT,RIGHT,W,UP,SPACE,J,K,L,S,DOWN"
    ) as Record<string, Phaser.Input.Keyboard.Key>;

    const k = this.keys;
    k.W.on("down", () => (this.jumpQueued = true));
    k.UP.on("down", () => (this.jumpQueued = true));
    k.SPACE.on("down", () => (this.jumpQueued = true));
    k.J.on("down", () => (this.lightQueued = true));
    k.K.on("down", () => (this.heavyQueued = true));
    k.L.on("down", () => (this.specialQueued = true));
  }

  private setupTouchButtons(): void {
    // Only worth showing on touch devices. We still create them on desktop if
    // there's no keyboard, as a fallback.
    const isTouch = this.scene.sys.game.device.input.touch;
    if (!isTouch) return;

    const r = 46;
    const pad = 24;
    const bottom = GAME_HEIGHT - pad - r;

    // Left side: movement + guard
    this.makeHoldButton(pad + r, bottom, r, "◀", (down) => (this.touchLeft = down));
    this.makeHoldButton(pad + r * 3 + 14, bottom, r, "▶", (down) => (this.touchRight = down));
    this.makeHoldButton(pad + r * 2 + 7, bottom - r * 2 - 14, r, "GRD", (down) => (this.touchGuard = down), 0x26c6da);

    // Right side: actions
    this.makeTapButton(GAME_WIDTH - pad - r, bottom, r, "JUMP", () => (this.jumpQueued = true), 0x4caf50);
    this.makeTapButton(GAME_WIDTH - pad - r * 3 - 14, bottom, r, "A", () => (this.lightQueued = true), 0x42a5f5);
    this.makeTapButton(GAME_WIDTH - pad - r * 3 - 14, bottom - r * 2 - 14, r, "B", () => (this.heavyQueued = true), 0xab47bc);
    this.makeTapButton(GAME_WIDTH - pad - r, bottom - r * 2 - 14, r, "SP", () => (this.specialQueued = true), 0xff7043);
  }

  /** A button that reports press-and-hold state (for movement/guard). */
  private makeHoldButton(
    x: number,
    y: number,
    radius: number,
    label: string,
    set: (down: boolean) => void,
    color = 0x37474f
  ): void {
    const { circle } = this.makeButtonVisual(x, y, radius, label, color);
    circle.on("pointerdown", () => {
      set(true);
      circle.setFillStyle(0x607d8b, 0.9);
    });
    const release = () => {
      set(false);
      circle.setFillStyle(color, 0.7);
    };
    circle.on("pointerup", release);
    circle.on("pointerout", release);
  }

  /** A button that fires once per tap (for actions). */
  private makeTapButton(
    x: number,
    y: number,
    radius: number,
    label: string,
    fire: () => void,
    color: number
  ): void {
    const { circle } = this.makeButtonVisual(x, y, radius, label, color);
    circle.on("pointerdown", () => {
      fire();
      circle.setFillStyle(0xffffff, 0.4);
      this.scene.time.delayedCall(90, () => circle.setFillStyle(color, 0.75));
    });
  }

  private makeButtonVisual(x: number, y: number, radius: number, label: string, color: number) {
    const circle = this.scene.add
      .circle(x, y, radius, color, 0.7)
      .setScrollFactor(0)
      .setDepth(1000)
      .setInteractive({ useHandCursor: true });
    const text = this.scene.add
      .text(x, y, label, { fontSize: "18px", color: "#ffffff", fontStyle: "bold" })
      .setOrigin(0.5)
      .setScrollFactor(0)
      .setDepth(1001);
    return { circle, text };
  }
}
