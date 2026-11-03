import { masteryPercent } from './XPSystem.js';

// Outlier — o wisp companheiro. Segue o jogador no mundo, reage às respostas
// em combate e evolui conforme a maestria média nas 6 áreas de superfície.
const SURFACE_AREAS = ['village', 'meadows', 'forest', 'plains', 'mountains', 'dungeon'];

const STAGES = {
    1: { color: 0x88ddff, xpBonus: 0,    label: 'Outlier'           },
    2: { color: 0xffd166, xpBonus: 0.03, label: 'Outlier Desperto'  },
    3: { color: 0xbb88ff, xpBonus: 0.06, label: 'Outlier Iluminado' },
};

export const CompanionSystem = {
    avgMastery(playerData) {
        const total = SURFACE_AREAS.reduce(
            (sum, a) => sum + masteryPercent(playerData.mastery?.[a]), 0);
        return total / SURFACE_AREAS.length;
    },

    stage(playerData) {
        const m = this.avgMastery(playerData);
        return m >= 65 ? 3 : m >= 30 ? 2 : 1;
    },

    texKey(stage)   { return `sprite_companion_${stage}`; },
    color(stage)    { return STAGES[stage]?.color ?? STAGES[1].color; },
    xpBonus(stage)  { return STAGES[stage]?.xpBonus ?? 0; },
    label(stage)    { return STAGES[stage]?.label ?? STAGES[1].label; },
};
