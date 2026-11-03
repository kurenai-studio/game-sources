import type { LevelDef } from '../types';

/**
 * The Range: the police academy training ground. A sequence of stations that teaches every
 * mechanic without walls of text, ending in a dark kill house.
 * Legend: see src/core/grid.ts. 60 x 40 tiles of 32 px.
 */
export const RANGE_MAP: readonly string[] = [
  '############################################################',
  '#..........................................................#',
  '#..........................................................#',
  '#..........................................................#',
  '#######################################################....#',
  '#............................#....................b........#',
  '#............................#....S...............b........#',
  '#............................#............S.......b........#',
  '#...wwwwwwwwwwwwwwwwDwwwww...#....................b........#',
  '#...w,,,,,,,,,w,,,,,,,,,,w...#........S...........b........#',
  '#...w,TT,,,,?,w,,,,,,,TT,w...#....................b........#',
  '#...w,TT,,,,,,w,,?,,,,,,,w...#...............S....b........#',
  '#...w,,,,,,,,,w,,,,,,,,?,w...#...S................b........#',
  '#...w,,,?,,,,,D,,,,,,,,,,w...#..........S.........b........#',
  '#...w,,,,,,,,,w,,,,,,,,,,w...#....................b........#',
  '#...w,,,,,,TT,w,M,,,,,,,,w...###########################D###',
  '#...w,,,,,,,,,w,,,,,,,,,,w...############w..........w......#',
  '#...w,,,,,,,,,w,,,,,,,,,,w...############w....S.....D......#',
  '#...wwwwwDwwwwwwwwwwwDwwww...############w.......S..w......#',
  '#...w,,,,,,,,,,,,w,,,,,,,w...############w..........w......#',
  '#...w,,,,,,,,,,,,w,,,,,,,w...############wwwwwwwwwwww......#',
  '#...w,,,,,,,,?,,,w,,,,?,,w...############w..........w......#',
  '#...w,,?,,,,,,,,,w,,,,,,,w...############w........S.D......#',
  '#...w,,,,,,,,,,,,D,,,,,,,w...############w..S.......w......#',
  '#...w,,,,,,,,,,,,w,,,,,,,w...############w..........w......#',
  '#...w,TTT,,,,,,,,w,T,,,,,w...############wwwwwwwwwwww......#',
  '#...w,,,,,,,,,,,,w,T,,,?,w...############w.S........w......#',
  '#...w,,,,,,,,,,,,w,,,,,,,w...############w..........D......#',
  '#...wwwwwwDwwwwwwwwwwwwwww...############w......C...w......#',
  '#............................############w..........w......#',
  '#............................############wwwwwwwwwwww......#',
  '#............................########################......#',
  '#####################...#############################......#',
  '####################............w...............w..........#',
  '####################...S.....S..w...C.......S...w..........#',
  '####################............w...............w..........#',
  '####################......w.............w..................#',
  '####################..C...w.C........S..w....C.............#',
  '####################......w.............w..................#',
  '############################################################',
];

export type StationId = 'movement' | 'targets' | 'doors' | 'shoot' | 'killhouse';

export interface StationDef {
  id: StationId;
  name: string;
  /** Shown in the HUD while the operator is inside the station. */
  brief: string[];
  /** Tile rectangle, inclusive. The first station whose zone contains a tile owns it. */
  zone: { x0: number; y0: number; x1: number; y1: number };
}

export const RANGE_STATIONS: readonly StationDef[] = [
  {
    id: 'movement',
    name: 'Movement lane',
    brief: ['WASD to walk. Walking is quiet.', 'Hold Shift to sprint: faster, but the ring shows how far you are heard.', 'Sprint to the end of the lane.'],
    zone: { x0: 1, y0: 1, x1: 58, y1: 4 },
  },
  {
    id: 'targets',
    name: 'Target lane',
    brief: ['Aim with the mouse. The laser shows exactly where a shot lands.', 'Moving makes it wobble; stand still to steady it.', 'Left click to fire, R to reload. Hit 5 targets.'],
    zone: { x0: 30, y0: 5, x1: 58, y1: 14 },
  },
  {
    id: 'doors',
    name: 'Door station',
    brief: ['E or right click opens or closes a door.', 'Stop before a door: the room opens up as it swings.', 'Clear all three booths.'],
    zone: { x0: 41, y0: 15, x1: 58, y1: 32 },
  },
  {
    id: 'shoot',
    name: "Shoot or don't",
    brief: ['Red with a gun: suspect. Yellow: civilian.', 'Hitting a civilian costs you a star. Check before you fire.', 'Clear every suspect in the lane.'],
    zone: { x0: 20, y0: 32, x1: 58, y1: 38 },
  },
  {
    id: 'killhouse',
    name: 'Kill house',
    brief: ['The lights are off: you only see as far as your weapon light reaches.', 'Ripples show sounds through walls. One target is on the move.', 'Clear every room. The layout is fixed, the targets are not.'],
    zone: { x0: 1, y0: 5, x1: 28, y1: 31 },
  },
];

/** The station whose zone contains a tile; the first match wins where zones touch. */
export function stationAt(tx: number, ty: number): StationDef | undefined {
  return RANGE_STATIONS.find((s) => tx >= s.zone.x0 && tx <= s.zone.x1 && ty >= s.zone.y0 && ty <= s.zone.y1);
}

export interface FloorLabel {
  text: string;
  tx: number;
  ty: number;
  size?: number;
  angle?: number;
}

export const RANGE_LABELS: readonly FloorLabel[] = [
  { text: 'PORT ARDLEY POLICE ACADEMY', tx: 4, ty: 1.15, size: 18 },
  { text: 'MOVEMENT LANE  >>>', tx: 22, ty: 2.1, size: 22 },
  { text: 'TARGET LANE', tx: 52.2, ty: 6, size: 16 },
  { text: 'FIRING LINE', tx: 51.2, ty: 13.6, size: 11 },
  { text: "<<<  SHOOT OR DON'T", tx: 49.5, ty: 37.2, size: 18 },
  { text: 'KILL HOUSE', tx: 10.5, ty: 29.4, size: 22 },
];

/** How many of the kill house's random slots become suspects and civilians on each run. */
export const KILLHOUSE_ROLL = { minSuspects: 3, maxSuspects: 5, minCivilians: 1, maxCivilians: 2 };

export const RANGE: LevelDef = {
  id: 'range',
  name: 'The Range',
  map: RANGE_MAP,
  labels: RANGE_LABELS,
  entries: [{ id: 'gate', name: 'the Range', approach: [{ tx: 1.5, ty: 2.5 }, { tx: 5.5, ty: 2.5 }] }],
  intro: [
    'Range control: Recruit, welcome to the Range.',
    'Range control: Range is hot. Work the stations in order.',
  ],
  stations: RANGE_STATIONS,
};
