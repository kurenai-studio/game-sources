import Phaser from 'phaser';
import { resetTouchInput, touchInput } from '@/game/systems/touch';
import type { Direction, Vector2Like } from '@/game/types';

export class GameInput {
  private readonly up: Phaser.Input.Keyboard.Key;
  private readonly down: Phaser.Input.Keyboard.Key;
  private readonly left: Phaser.Input.Keyboard.Key;
  private readonly right: Phaser.Input.Keyboard.Key;
  private readonly shootUp: Phaser.Input.Keyboard.Key;
  private readonly shootDown: Phaser.Input.Keyboard.Key;
  private readonly shootLeft: Phaser.Input.Keyboard.Key;
  private readonly shootRight: Phaser.Input.Keyboard.Key;
  private readonly toll: Phaser.Input.Keyboard.Key;
  private tollQueued = false;
  private readonly shootOrder: Direction[] = [];
  private readonly removers: Array<() => void> = [];

  constructor(scene: Phaser.Scene) {
    const keyboard = scene.input.keyboard;
    if (!keyboard) throw new Error('Keyboard input is unavailable');
    this.up = keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.W);
    this.down = keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.S);
    this.left = keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.A);
    this.right = keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.D);
    this.shootUp = keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.UP);
    this.shootDown = keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.DOWN);
    this.shootLeft = keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.LEFT);
    this.shootRight = keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.RIGHT);
    // no key capture, so Space still works on focused menu buttons
    this.toll = keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE, false);
    // queue on the key event: a tap shorter than one frame would slip past JustDown
    const onToll = (): void => {
      this.tollQueued = true;
    };
    this.toll.on('down', onToll);
    this.removers.push(() => this.toll.off('down', onToll));

    const directionKeys: Array<[Direction, Phaser.Input.Keyboard.Key]> = [
      ['north', this.shootUp],
      ['south', this.shootDown],
      ['west', this.shootLeft],
      ['east', this.shootRight],
    ];
    for (const [direction, key] of directionKeys) {
      const onDown = (): void => {
        const index = this.shootOrder.indexOf(direction);
        if (index >= 0) this.shootOrder.splice(index, 1);
        this.shootOrder.push(direction);
      };
      const onUp = (): void => {
        const index = this.shootOrder.indexOf(direction);
        if (index >= 0) this.shootOrder.splice(index, 1);
      };
      key.on('down', onDown);
      key.on('up', onUp);
      this.removers.push(() => {
        key.off('down', onDown);
        key.off('up', onUp);
      });
    }
  }

  movement(): Vector2Like {
    let x = Number(this.right.isDown) - Number(this.left.isDown) + touchInput.move.x;
    let y = Number(this.down.isDown) - Number(this.up.isDown) + touchInput.move.y;
    const length = Math.hypot(x, y);
    if (length > 1) {
      x /= length;
      y /= length;
    }
    return { x, y };
  }

  shooting(): Direction | null {
    const touchLength = Math.hypot(touchInput.shoot.x, touchInput.shoot.y);
    if (touchLength > 0.18) {
      if (Math.abs(touchInput.shoot.x) > Math.abs(touchInput.shoot.y)) {
        return touchInput.shoot.x > 0 ? 'east' : 'west';
      }
      return touchInput.shoot.y > 0 ? 'south' : 'north';
    }
    for (let index = this.shootOrder.length - 1; index >= 0; index -= 1) {
      const direction = this.shootOrder[index];
      if (direction && this.isDirectionDown(direction)) return direction;
    }
    if (this.shootUp.isDown) return 'north';
    if (this.shootDown.isDown) return 'south';
    if (this.shootLeft.isDown) return 'west';
    if (this.shootRight.isDown) return 'east';
    return null;
  }

  /** True once per Space press. */
  tollPressed(): boolean {
    const queued = this.tollQueued;
    this.tollQueued = false;
    return queued;
  }

  reset(): void {
    this.tollQueued = false;
    this.shootOrder.splice(0, this.shootOrder.length);
    resetTouchInput();
  }

  destroy(): void {
    this.removers.forEach((remove) => remove());
    this.reset();
  }

  private isDirectionDown(direction: Direction): boolean {
    return (
      (direction === 'north' && this.shootUp.isDown) ||
      (direction === 'south' && this.shootDown.isDown) ||
      (direction === 'west' && this.shootLeft.isDown) ||
      (direction === 'east' && this.shootRight.isDown)
    );
  }
}
