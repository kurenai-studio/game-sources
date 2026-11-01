import type { MineKind } from './Mines';
import { LayoutKind, LAYOUT_ORDER } from './Layouts';

export interface LevelConfig {
    mine?: MineKind;
    layout: LayoutKind;
    target: number;
    rocks: number;
    largeRocks: number;
    heavyRocks: number;
    minimumDepth: number;
    diamonds: number;
    moneyBags: number;
    rats: number;
    diamondRats: number;
    tnt: number;
    timeVials?: number;
    strengthVials?: number;
    goldRushVials?: number;
    ratSpeed: number;
    ratLaneMargin?: number;
}

const BASE_LEVELS: readonly Omit<LevelConfig, 'layout' | 'heavyRocks'>[] = [
    { target: 650, rocks: 3, largeRocks: 1, minimumDepth: 320, diamonds: 1, moneyBags: 0, rats: 0, diamondRats: 0, tnt: 0, ratSpeed: 1 },
    { target: 850, rocks: 4, largeRocks: 1, minimumDepth: 335, diamonds: 1, moneyBags: 1, rats: 0, diamondRats: 0, tnt: 1, ratSpeed: 1 },
    { target: 1050, rocks: 4, largeRocks: 2, minimumDepth: 350, diamonds: 1, moneyBags: 1, rats: 2, diamondRats: 0, tnt: 2, ratSpeed: 1 },
    { target: 1250, rocks: 5, largeRocks: 2, minimumDepth: 365, diamonds: 1, moneyBags: 2, rats: 3, diamondRats: 1, tnt: 3, ratSpeed: 1 },
    { target: 1450, rocks: 5, largeRocks: 3, minimumDepth: 380, diamonds: 2, moneyBags: 2, rats: 4, diamondRats: 2, tnt: 4, ratSpeed: 1 },
    // Extend the introduction into a 30-level run. Cap crowding rather than
    // adding objects forever; higher targets and faster rats keep the pressure on.
    ...Array.from({ length: 25 }, (_, index): Omit<LevelConfig, 'layout' | 'heavyRocks'> => {
        const step = index + 1;
        // Preserve levels 1–20; late difficulty grows without unbounded crowding.
        const populationStep = Math.min(step, 15);
        const lateStep = Math.max(0, step - 15);
        const largeRocks = 3 + Math.floor(populationStep / 6);
        return {
            target: 1450 + step * 150,
            rocks: 8 - largeRocks,
            largeRocks,
            minimumDepth: Math.min(400, 380 + step * 2) + lateStep * 2,
            diamonds: 2 + Math.floor(populationStep / 4),
            moneyBags: 2 + Math.floor(populationStep / 6),
            rats: 4 + Math.floor(populationStep / 6) - Math.floor(lateStep / 5),
            diamondRats: 2 + Math.floor(populationStep / 8) + Math.floor(lateStep / 5),
            tnt: 4 + Math.floor(populationStep / 6),
            ratSpeed: 1 + step * 0.04
        };
    })
];

/** Raise the previous rounded targets to match the denser mine. */
function densityAdjustedTarget(baseTarget: number, index: number): number {
    const previousTarget = Math.round(baseTarget * 0.9 * 1.1 / 50) * 50;
    const multiplier = index < 3 ? 1.25 : index < 10 ? 1.35 : 1.4;
    return Math.round(previousTarget * multiplier / 50) * 50;
}

export const LEVELS: readonly LevelConfig[] = BASE_LEVELS.map((level, index) => ({
    ...level,
    target: densityAdjustedTarget(level.target, index),
    // More hazards should tighten shots, never turn the mine into a solid wall.
    largeRocks: Math.min(3, level.largeRocks),
    rocks: Math.min(level.rocks, 6 - Math.min(3, level.largeRocks))
        - (index >= 10 && LAYOUT_ORDER[index % LAYOUT_ORDER.length] === 'ratTunnels' ? 1 : 0),
    heavyRocks: index >= 2 ? 1 : 0,
    // Endgame rat lanes already remove placement space; avoid packing them with barrels.
    tnt: index >= 20 && LAYOUT_ORDER[index % LAYOUT_ORDER.length] === 'ratTunnels'
        ? Math.min(5, level.tnt) : level.tnt,
    layout: LAYOUT_ORDER[index % LAYOUT_ORDER.length],
    ...(index >= 20 && LAYOUT_ORDER[index % LAYOUT_ORDER.length] === 'ratTunnels'
        ? { ratLaneMargin: 28 } : {})
}));
