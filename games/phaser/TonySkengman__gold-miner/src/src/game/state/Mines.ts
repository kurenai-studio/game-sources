import { LEVELS, type LevelConfig } from './Levels';

export type MineKind = 'quarry' | 'goldBasin' | 'gemHollow';
export const MINES = {
    quarry: { baseSeconds: 60, name: 'Treasure Hollow', fee: 0, targetMultiplier: 1, playstyle: 'VARIETY & STREAKS', description: 'A varied mix of gold, gems, chests and bags. Quick catches and steady streaks reward adaptable play.', subtext: 'More chests and bags offer varied rewards, with a lower earnings target.', color: 0xcca676 },
    goldBasin: { baseSeconds: 90, name: 'Gold Basin', fee: 0, targetMultiplier: 1.15, playstyle: 'HEAVY HAULS & TIMING', description: 'Giant gold and few loose gems. Use plentiful Strength, Gold Rush and time vials to plan heavy hauls around TNT.', subtext: 'Slow hauls and higher targets. Catch vials to keep going; blasts can destroy your gold.', color: 0xffd45d },
    gemHollow: { baseSeconds: 60, name: 'Gem Hollow', fee: 0, targetMultiplier: 1.2, playstyle: 'PRECISION & PERFECT CATCHES', description: 'Scattered diamonds and rubies, no gold. Aim through rock gaps for perfect catches; Gem Polish rewards precision.', subtext: 'Small targets and higher stakes. Misses cost time; careful aim avoids heavy rock hauls.', color: 0x78dfeb }
} as const;

export const roundDuration = (mine: MineKind = 'quarry', extraTime = 0): number =>
    MINES[mine].baseSeconds + (extraTime > 0 ? 15 : 0);

export function mineConfig(level: number, mine: MineKind = 'quarry'): LevelConfig {
    const base = LEVELS[level - 1];
    const rocks = mine === 'goldBasin' ? {
        rocks: 1,
        largeRocks: 0,
        heavyRocks: 0,
        tnt: Math.min(5, 3 + Math.floor((level - 1) / 6)),
        timeVials: Math.min(4, 2 + Math.floor((level - 1) / 6)),
        strengthVials: Math.min(4, 2 + Math.floor((level - 1) / 6)),
        goldRushVials: Math.min(4, 2 + Math.floor((level - 1) / 6))
    } : mine === 'gemHollow' ? { tnt: Math.min(3, base.tnt) } : {};
    const previousTarget = Math.round(base.target * MINES[mine].targetMultiplier / 50) * 50;
    const routeTarget = mine === 'quarry' ? previousTarget : Math.round(previousTarget * 1.35 / 50) * 50;
    const target = mine === 'goldBasin' ? Math.round(routeTarget * 0.9 / 50) * 50 : routeTarget;
    return { ...base, ...rocks, layout: mine === 'goldBasin' ? 'goldPocket' : base.layout, mine, target };
}
