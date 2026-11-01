import { vi, describe, it, expect, beforeEach } from 'vitest';
import { OBSTACLE_COUNT } from '../config/game';

/* ---------- Phaser mock ---------- */

vi.mock('phaser', () => ({
  default: {
    Math: {
      Between: (a: number, b: number) => (a + b) / 2,
    },
    Physics: {
      Arcade: {
        StaticGroup: class {
          create = vi.fn().mockReturnThis();
        },
      },
    },
  },
}));

import { EnvironmentController } from './EnvironmentController';

function mockScene() {
  const stars: any[] = [];
  const obstacles: any[] = [];
  return {
    add: {
      image: vi.fn().mockImplementation((_x, _y, _key) => {
        const star = { x: 0, y: 0, setAlpha: vi.fn().mockReturnThis(), setDepth: vi.fn().mockReturnThis() };
        (star as any)._speed = 1;
        stars.push(star);
        return star;
      }),
    },
    physics: {
      add: {
        staticGroup: vi.fn().mockImplementation(() => ({
          create: vi.fn().mockImplementation(() => {
            const obs = { setScale: vi.fn().mockReturnThis(), setDepth: vi.fn().mockReturnThis(), setAlpha: vi.fn().mockReturnThis(), refreshBody: vi.fn() };
            obstacles.push(obs);
            return obs;
          }),
        })),
      },
    },
    _stars: stars,
    _obstacles: obstacles,
  };
}

describe('EnvironmentController', () => {
  let scene: ReturnType<typeof mockScene>;
  let env: EnvironmentController;

  beforeEach(() => {
    scene = mockScene();
    env = new EnvironmentController(scene as any);
  });

  describe('create', () => {
    it('should create 80 stars', () => {
      env.create();
      // The mock adds to _stars array; we verify via add.image calls
      expect(scene.add.image).toHaveBeenCalledTimes(80);
    });

    it('should create OBSTACLE_COUNT obstacles', () => {
      env.create();
      // Static group create called OBSTACLE_COUNT times
      const staticGroup = (scene.physics.add.staticGroup as any).mock.results[0].value;
      expect(staticGroup.create).toHaveBeenCalledTimes(OBSTACLE_COUNT);
    });

    it('should expose obstacles group', () => {
      env.create();
      expect(env.obstacles).toBeDefined();
    });
  });

  describe('update', () => {
    it('should call update without crashing', () => {
      env.create();
      // Just ensure update runs without error (starfield logic is simple)
      expect(() => env.update()).not.toThrow();
    });
  });
});
