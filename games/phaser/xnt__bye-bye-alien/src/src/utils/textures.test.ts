import { vi, describe, it, expect, beforeEach } from 'vitest';

vi.mock('phaser', () => ({ default: {} }));

import { generateTextures } from './textures';

/* ---------- Helpers ---------- */

function createMockGraphics() {
  const g: Record<string, any> = {
    setVisible: vi.fn().mockReturnThis(),
    fillStyle: vi.fn(),
    fillRect: vi.fn(),
    lineStyle: vi.fn(),
    strokeRect: vi.fn(),
    generateTexture: vi.fn(),
    destroy: vi.fn(),
  };
  return g;
}

function createMockScene() {
  const graphicsInstances: any[] = [];
  return {
    scene: {
      add: {
        graphics: vi.fn(() => {
          const g = createMockGraphics();
          graphicsInstances.push(g);
          return g;
        }),
      },
    },
    graphicsInstances,
  };
}

/* ---------- Tests ---------- */

describe('generateTextures', () => {
  let helpers: ReturnType<typeof createMockScene>;

  beforeEach(() => {
    helpers = createMockScene();
    generateTextures(helpers.scene as any);
  });

  it('should create 18 graphics contexts (one per texture)', () => {
    // 4 ships + 4 ship bullets + 3 power-up + alien + alien_bullet + boss + boss_bullet + obstacle + star + explosion
    expect(helpers.scene.add.graphics).toHaveBeenCalledTimes(18);
  });

  it('should hide every graphics context', () => {
    for (const g of helpers.graphicsInstances) {
      expect(g.setVisible).toHaveBeenCalledWith(false);
    }
  });

  it('should destroy every graphics context after use', () => {
    for (const g of helpers.graphicsInstances) {
      expect(g.destroy).toHaveBeenCalled();
    }
  });

  it('should generate all expected texture keys', () => {
    const expectedKeys = [
      'f35',
      'valkyrie',
      'titan',
      'spectre',
      'bullet_f35',
      'bullet_valkyrie',
      'bullet_titan',
      'bullet_spectre',
      'powerup_pickup',
      'powerup_disguise',
      'bullet_powerup',
      'alien',
      'bullet_alien',
      'boss',
      'bullet_boss',
      'obstacle',
      'star',
      'explosion',
    ];

    const generated = helpers.graphicsInstances.map(
      (g) => g.generateTexture.mock.calls[0][0] as string,
    );

    for (const key of expectedKeys) {
      expect(generated).toContain(key);
    }
  });

  it('should call generateTexture exactly once per graphics context', () => {
    for (const g of helpers.graphicsInstances) {
      expect(g.generateTexture).toHaveBeenCalledTimes(1);
    }
  });

  it('should generate f35 at 64×64 (32 * scale 2)', () => {
    const f35 = helpers.graphicsInstances.find(
      (g) => g.generateTexture.mock.calls[0][0] === 'f35',
    );
    expect(f35.generateTexture).toHaveBeenCalledWith('f35', 64, 64);
  });

  it('should generate bullet_f35 at 10×4', () => {
    const bp = helpers.graphicsInstances.find(
      (g) => g.generateTexture.mock.calls[0][0] === 'bullet_f35',
    );
    expect(bp.generateTexture).toHaveBeenCalledWith('bullet_f35', 10, 4);
  });

  it('should generate all ship textures at 64×64', () => {
    for (const key of ['f35', 'valkyrie', 'titan', 'spectre']) {
      const ship = helpers.graphicsInstances.find(
        (g) => g.generateTexture.mock.calls[0][0] === key,
      );
      expect(ship).toBeDefined();
      expect(ship.generateTexture).toHaveBeenCalledWith(key, 64, 64);
    }
  });

  it('should generate alien at 56×36 (28*2 × 18*2)', () => {
    const a = helpers.graphicsInstances.find(
      (g) => g.generateTexture.mock.calls[0][0] === 'alien',
    );
    expect(a.generateTexture).toHaveBeenCalledWith('alien', 56, 36);
  });

  it('should generate boss at 120×80', () => {
    const b = helpers.graphicsInstances.find(
      (g) => g.generateTexture.mock.calls[0][0] === 'boss',
    );
    expect(b.generateTexture).toHaveBeenCalledWith('boss', 120, 80);
  });

  it('should generate explosion at 32×32', () => {
    const e = helpers.graphicsInstances.find(
      (g) => g.generateTexture.mock.calls[0][0] === 'explosion',
    );
    expect(e.generateTexture).toHaveBeenCalledWith('explosion', 32, 32);
  });

  it('should draw pixels via fillStyle and fillRect', () => {
    for (const g of helpers.graphicsInstances) {
      expect(g.fillStyle.mock.calls.length).toBeGreaterThan(0);
      expect(g.fillRect.mock.calls.length).toBeGreaterThan(0);
    }
  });
});
