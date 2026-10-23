export const DIFFICULTIES = {
  easy: {
    errorFactor: 0.25,
    cooldownMin: 4000,
    cooldownMax: 5000,
    windCompensation: 0.2,
    learns: false,
    names: ['Rookie', 'Trainee', 'Novice', 'Cadet'],
  },
  medium: {
    errorFactor: 0.15,
    cooldownMin: 3000,
    cooldownMax: 4000,
    windCompensation: 0.5,
    learns: false,
    names: ['Gunner', 'Sergeant', 'Marshal', 'Captain'],
  },
  hard: {
    errorFactor: 0.08,
    cooldownMin: 2500,
    cooldownMax: 3500,
    windCompensation: 0.8,
    learns: true,
    names: ['Commander', 'Warlord', 'General', 'Overlord'],
  },
};

export function getAIName(difficulty) {
  const config = DIFFICULTIES[difficulty] || DIFFICULTIES.medium;
  const names = config.names;
  return names[Math.floor(Math.random() * names.length)];
}

export function getDifficultyConfig(difficulty) {
  return DIFFICULTIES[difficulty] || DIFFICULTIES.medium;
}
