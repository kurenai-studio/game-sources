import { type LevelConfig, type TowerDefinition } from './types.js';

/**
 * Deep clones a value, passing through functions and class constructors
 * as-is since they are not structurally cloneable.
 */
function deepClone<T>(value: T): T {
  if (value === null || typeof value !== 'object') {
    return value;
  }

  if (Object.getPrototypeOf(value) !== Object.prototype) {
    return value;
  }

  if (Array.isArray(value)) {
    return value.map((item) => deepClone(item)) as T;
  }

  const result: Record<string, unknown> = {};
  for (const [key, val] of Object.entries(value)) {
    result[key] = typeof val === 'function' ? val : deepClone(val);
  }
  return result as T;
}

/**
 * Returns the config for the level with the given number.
 *
 * @param tower The tower.
 * @param levelNumber The number of the level.
 * @param warriorName The name of the warrior.
 * @param epic Whether the level is to be used in epic mode or not.
 *
 * @returns The level config.
 */
function getLevelConfig(
  tower: TowerDefinition,
  levelNumber: number,
  warriorName: string,
  epic: boolean,
): LevelConfig | null {
  const level = tower.levels[levelNumber - 1];
  if (!level) {
    return null;
  }

  const levels = epic ? tower.levels : tower.levels.slice(0, levelNumber);
  const warriorAbilities = Object.assign(
    {},
    ...levels.map(
      ({
        floor: {
          warrior: { abilities },
        },
      }) => abilities || {},
    ),
  );

  return {
    number: levelNumber,
    description: level.description,
    tip: level.tip,
    clue: level.clue ?? '',
    timeBonus: level.timeBonus,
    aceScore: level.aceScore,
    floor: {
      size: deepClone(level.floor.size),
      stairs: deepClone(level.floor.stairs),
      warrior: {
        ...deepClone(tower.warrior),
        ...deepClone(level.floor.warrior),
        name: warriorName,
        abilities: warriorAbilities,
      },
      units: level.floor.units ? deepClone(level.floor.units) : undefined,
    },
  };
}

export default getLevelConfig;
