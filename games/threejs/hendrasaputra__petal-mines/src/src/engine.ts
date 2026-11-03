/** Puzzle rules only: no DOM, rendering, clocks, or storage. */
export type ClueType = 'local' | 'above' | 'below';
export interface Config {
  width: number;
  height: number;
  mines: number;
  floors: number;
  seed: string;
  mode?: 'classic' | 'layered' | 'connected';
  firstReveal?: number[];
  generatorVersion?: 1;
  vertical?: 'above' | 'below' | 'both';
}
export interface Cell {
  mine: boolean;
  revealed: boolean;
  flagged: boolean;
  adjacent: number;
  clueType?: ClueType;
}
export interface Position { floor: number; index: number }
export interface Game {
  config: Config;
  cells: Cell[][];
  started: boolean[];
  status: 'ready' | 'playing' | 'won' | 'lost';
  exploded?: Position;
}

function validConfig(config: Config): boolean {
  return !!config && Number.isInteger(config.width) && config.width >= 2 && config.width <= 24
    && Number.isInteger(config.height) && config.height >= 2 && config.height <= 24
    && Number.isInteger(config.floors) && config.floors >= 1 && config.floors <= 3
    && Number.isInteger(config.mines) && config.mines >= 0 && config.mines < config.width * config.height
    && typeof config.seed === 'string' && config.seed.length > 0 && config.seed.length <= 128
    && (config.mode === undefined || ['classic', 'layered', 'connected'].includes(config.mode))
    && (config.mode !== 'classic' || config.floors === 1)
    && (config.mode !== 'connected' || config.floors >= 2)
    && (config.generatorVersion === undefined || config.generatorVersion === 1)
    && (config.vertical === undefined || ['above', 'below', 'both'].includes(config.vertical))
    && (config.firstReveal === undefined || Array.isArray(config.firstReveal)
      && config.firstReveal.length === config.floors
      && config.firstReveal.every(i => Number.isInteger(i) && i >= 0 && i < config.width * config.height));
}

function fixed(game: Game): boolean { return !!game.config.firstReveal || game.config.mode === 'connected'; }
function opening(config: Config, floor: number): number {
  return config.firstReveal?.[floor] ?? Math.floor(config.height / 2) * config.width + Math.floor(config.width / 2);
}

export function createGame(config: Config): Game {
  if (!validConfig(config)) throw new RangeError('Invalid puzzle configuration');
  const game: Game = {
    config: { ...config, ...(config.firstReveal ? { firstReveal: [...config.firstReveal] } : {}) },
    cells: Array.from({ length: config.floors }, () => Array.from(
      { length: config.width * config.height }, () => ({ mine: false, revealed: false, flagged: false, adjacent: 0 }),
    )),
    started: Array(config.floors).fill(false),
    status: 'ready',
  };
  if (fixed(game)) {
    for (let f = 0; f < config.floors; f++) plant(game, f, opening(config, f));
    updateClues(game);
  }
  return game;
}

/** Campaign/retry entry point: fixed, safe openings become visible before player input. */
export function startGame(config: Config): Game {
  if (!validConfig(config)) throw new RangeError('Invalid puzzle configuration');
  const game = createGame({ ...config, firstReveal: Array.from({ length: config.floors }, (_, f) => opening(config, f)), generatorVersion: 1 });
  for (let f = 0; f < config.floors; f++) reveal(game, f, opening(game.config, f));
  return game;
}

/** Recover old freeplay openings once; subsequent retries use the recorded fixed starts. */
export function retryGame(game: Game): Game {
  if (fixed(game)) return startGame(game.config);
  const firstReveal = game.cells.map((floor, f) => {
    if (!game.started[f]) return opening(game.config, f);
    for (let i = 0; i < floor.length; i++) {
      if (!floor[i].revealed || floor[i].mine) continue;
      const candidate = createGame(game.config);
      plant(candidate, f, i);
      if (floor.every((cell, j) => cell.mine === candidate.cells[f][j].mine)) return i;
    }
    throw new RangeError('Saved puzzle does not match its seed; cannot reproduce retry');
  });
  return startGame({ ...game.config, firstReveal, generatorVersion: 1 });
}

export function neighbors(config: Config, index: number): number[] {
  const result: number[] = [];
  const x = index % config.width;
  const y = Math.floor(index / config.width);
  for (let dy = -1; dy <= 1; dy++) {
    for (let dx = -1; dx <= 1; dx++) {
      if ((dx || dy) && x + dx >= 0 && x + dx < config.width && y + dy >= 0 && y + dy < config.height) {
        result.push((y + dy) * config.width + x + dx);
      }
    }
  }
  return result;
}

/** Up/down clues include the aligned tile and clipped 3×3 footprint, never the source floor. */
export function clueNeighbors(game: Game, floor: number, index: number): Position[] {
  const type = game.cells[floor]?.[index]?.clueType ?? 'local';
  if (type === 'local') return neighbors(game.config, index).map(index => ({ floor, index }));
  const target = floor + (type === 'above' ? 1 : -1);
  if (target < 0 || target >= game.config.floors) return [];
  return [index, ...neighbors(game.config, index)].map(index => ({ floor: target, index }));
}

function random(seed: string): () => number {
  let state = 2166136261;
  for (let i = 0; i < seed.length; i++) state = Math.imul(state ^ seed.charCodeAt(i), 16777619);
  return () => {
    state += 0x6d2b79f5;
    let value = Math.imul(state ^ (state >>> 15), state | 1);
    value ^= value + Math.imul(value ^ (value >>> 7), value | 61);
    return ((value ^ (value >>> 14)) >>> 0) / 4294967296;
  };
}

function plant(game: Game, floor: number, index: number): void {
  const cells = game.cells[floor];
  let safe = new Set([index, ...neighbors(game.config, index)]);
  // Dense boards still guarantee a safe first tile when a full opening cannot fit.
  if (cells.length - safe.size < game.config.mines) safe = new Set([index]);
  const candidates = cells.map((_, i) => i).filter(i => !safe.has(i));
  const next = random(`${game.config.seed}:${floor}:${index}`);
  for (let i = candidates.length - 1; i > 0; i--) {
    const j = Math.floor(next() * (i + 1));
    [candidates[i], candidates[j]] = [candidates[j], candidates[i]];
  }
  for (const i of candidates.slice(0, game.config.mines)) cells[i].mine = true;
  if (game.config.mode === 'connected') cells.forEach((cell, i) => {
    let type: ClueType = 'local';
    if (!cell.mine && i % 4 === 0 && game.config.vertical !== 'below' && floor < game.config.floors - 1) type = 'above';
    if (!cell.mine && i % 4 === 2 && game.config.vertical !== 'above' && floor > 0) type = 'below';
    cell.clueType = type;
  });
}

function updateClues(game: Game): void {
  game.cells.forEach((floor, f) => floor.forEach((cell, i) => {
    cell.adjacent = clueNeighbors(game, f, i).filter(p => game.cells[p.floor][p.index].mine).length;
  }));
}

function playable(game: Game, floor: number, index: number): boolean {
  return game.status !== 'lost' && game.status !== 'won' && Number.isInteger(floor) && Number.isInteger(index)
    && floor >= 0 && floor < game.config.floors && index >= 0 && index < game.config.width * game.config.height;
}

function open(game: Game, floor: number, index: number): void {
  const pending: Position[] = [{ floor, index }];
  while (pending.length) {
    const p = pending.pop()!;
    const cell = game.cells[p.floor][p.index];
    if (cell.revealed || cell.flagged) continue;
    cell.revealed = true;
    game.started[p.floor] = true;
    if (cell.mine) {
      game.status = 'lost';
      game.exploded = p;
      return;
    }
    if (cell.adjacent === 0) pending.push(...clueNeighbors(game, p.floor, p.index));
  }
}

function checkWin(game: Game): void {
  if (game.status !== 'lost' && game.started.every(Boolean)
    && game.cells.every(floor => floor.every(cell => cell.mine || cell.revealed))) game.status = 'won';
}

export function reveal(game: Game, floor: number, index: number): boolean {
  if (!playable(game, floor, index)) return false;
  const cell = game.cells[floor][index];
  if (cell.revealed || cell.flagged) return false;
  if (!game.started[floor]) {
    if (fixed(game)) {
      if (index !== opening(game.config, floor)) return false;
    } else {
      plant(game, floor, index);
      updateClues(game);
    }
  }
  game.status = 'playing';
  open(game, floor, index);
  checkWin(game);
  return true;
}

export function toggleFlag(game: Game, floor: number, index: number): boolean {
  if (!playable(game, floor, index) || game.cells[floor][index].revealed) return false;
  const cell = game.cells[floor][index];
  cell.flagged = !cell.flagged;
  return true;
}

export function chord(game: Game, floor: number, index: number): boolean {
  if (!playable(game, floor, index)) return false;
  const cell = game.cells[floor][index];
  const around = clueNeighbors(game, floor, index);
  if (!cell.revealed || around.filter(p => game.cells[p.floor][p.index].flagged).length !== cell.adjacent) return false;
  const targets = around.filter(p => !game.cells[p.floor][p.index].revealed && !game.cells[p.floor][p.index].flagged);
  for (const p of targets) {
    open(game, p.floor, p.index);
    if (game.status === 'lost') break;
  }
  checkWin(game);
  return targets.length > 0;
}

/** Treat browser persistence as untrusted; reject partial, stale, or inconsistent saves. */
export function restoreGame(value: unknown): Game | null {
  try {
    if (!value || typeof value !== 'object') return null;
    const saved = value as Game;
    if (!validConfig(saved.config) || !Array.isArray(saved.cells) || !Array.isArray(saved.started)
      || saved.cells.length !== saved.config.floors || saved.started.length !== saved.config.floors
      || saved.started.some(started => typeof started !== 'boolean')) return null;
    const game = createGame(saved.config);
    game.started = [...saved.started];
    for (let f = 0; f < game.config.floors; f++) {
      const floor = saved.cells[f];
      if (!Array.isArray(floor) || floor.length !== game.config.width * game.config.height) return null;
      for (let i = 0; i < floor.length; i++) {
        const cell = floor[i];
        if (!cell || typeof cell.mine !== 'boolean' || typeof cell.revealed !== 'boolean'
          || typeof cell.flagged !== 'boolean' || !Number.isInteger(cell.adjacent) || cell.adjacent < 0
          || cell.adjacent > 9 || (cell.revealed && cell.flagged)
          || (cell.clueType !== undefined && !['local', 'above', 'below'].includes(cell.clueType))) return null;
        if (fixed(game) && (cell.mine !== game.cells[f][i].mine || cell.clueType !== game.cells[f][i].clueType)) return null;
        if (game.config.mode !== 'connected' && cell.clueType && cell.clueType !== 'local') return null;
        game.cells[f][i] = { mine: cell.mine, revealed: cell.revealed, flagged: cell.flagged, adjacent: cell.adjacent,
          ...(cell.clueType !== undefined ? { clueType: cell.clueType } : {}) };
      }
    }
    for (let f = 0; f < game.config.floors; f++) {
      const floor = game.cells[f];
      if (game.started[f] !== floor.some(cell => cell.revealed)) return null;
      if (!game.started[f] && !fixed(game)) {
        if (floor.some(cell => cell.mine || cell.adjacent !== 0)) return null;
      } else if (floor.filter(cell => cell.mine).length !== game.config.mines
        || floor.some((cell, i) => cell.adjacent !== clueNeighbors(game, f, i).filter(p => game.cells[p.floor][p.index].mine).length)) return null;
    }
    const revealedMine = game.cells.some(floor => floor.some(cell => cell.mine && cell.revealed));
    const won = game.started.every(Boolean) && game.cells.every(floor => floor.every(cell => cell.mine || cell.revealed));
    const expected = revealedMine ? 'lost' : won ? 'won' : game.started.some(Boolean) ? 'playing' : 'ready';
    if (saved.status !== expected) return null;
    game.status = expected;
    if (expected === 'lost') {
      const hit = saved.exploded;
      if (!hit || !Number.isInteger(hit.floor) || !Number.isInteger(hit.index)) return null;
      const cell = game.cells[hit.floor]?.[hit.index];
      if (!cell?.mine || !cell.revealed) return null;
      game.exploded = { floor: hit.floor, index: hit.index };
    } else if (saved.exploded !== undefined) return null;
    return game;
  } catch {
    return null;
  }
}
