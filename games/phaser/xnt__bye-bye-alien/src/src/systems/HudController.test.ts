import { vi, describe, it, expect, beforeEach } from 'vitest';

/* ---------- Phaser mock ---------- */

vi.mock('phaser', () => ({
  default: {
    Math: { Between: (a: number, b: number) => (a + b) / 2 },
  },
}));

import { HudController } from './HudController';

function makeTextMock() {
  return {
    setDepth: vi.fn().mockReturnThis(),
    setOrigin: vi.fn().mockReturnThis(),
    setText: vi.fn().mockReturnThis(),
  };
}

function mockScene() {
  return {
    add: {
      text: vi.fn().mockImplementation(() => makeTextMock()),
    },
  };
}

describe('HudController', () => {
  let scene: ReturnType<typeof mockScene>;
  let hud: HudController;

  beforeEach(() => {
    scene = mockScene();
    hud = new HudController(scene as any);
  });

  describe('create', () => {
    it('should create hpText, scoreText, and timerText', () => {
      hud.create(100);
      expect(scene.add.text).toHaveBeenCalledTimes(3);
      const calls = (scene.add.text as any).mock.calls;
      expect(calls[0][2]).toMatch(/^HP:/);
      expect(calls[1][2]).toMatch(/^SCORE:/);
      expect(calls[2][2]).toMatch(/^TIME:/);
    });

    it('should display initial HP value', () => {
      hud.create(88);
      const hpCall = (scene.add.text as any).mock.calls[0];
      expect(hpCall[2]).toBe('HP: 88');
    });
  });

  describe('update', () => {
    it('should update hpText, scoreText, timerText', () => {
      hud.create(100);
      const hpText = (scene.add.text as any).mock.results[0].value;
      const scoreText = (scene.add.text as any).mock.results[1].value;
      const timerText = (scene.add.text as any).mock.results[2].value;

      hud.update(75, 500, 45_000);

      expect(hpText.setText).toHaveBeenCalledWith('HP: 75');
      expect(scoreText.setText).toHaveBeenCalledWith('SCORE: 500');
      expect(timerText.setText).toHaveBeenCalledWith('TIME: 45s');
    });

    it('should clamp HP to 0 minimum', () => {
      hud.create(100);
      const hpText = (scene.add.text as any).mock.results[0].value;
      hud.update(-10, 0, 0);
      expect(hpText.setText).toHaveBeenCalledWith('HP: 0');
    });
  });
});
