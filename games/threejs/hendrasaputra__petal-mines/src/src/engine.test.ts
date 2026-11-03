import { describe, expect, it } from 'vitest';
import { chord, clueNeighbors, createGame, neighbors, restoreGame, reveal, retryGame, startGame, toggleFlag, type Config, type Game } from './engine';

const config: Config = { width: 6, height: 6, mines: 6, floors: 1, seed: 'pink-islands' };
const copy = <T>(value: T): T => JSON.parse(JSON.stringify(value));

function numbered(game: Game): number {
  return game.cells[0].findIndex((cell, index) => cell.revealed && cell.adjacent > 0
    && neighbors(game.config, index).some(i => !game.cells[0][i].revealed && !game.cells[0][i].mine));
}

describe('deterministic independent puzzle floors', () => {
  it('defers mines and guarantees a zero first reveal when there is room', () => {
    const game = createGame(config);
    expect(game.cells[0].some(cell => cell.mine)).toBe(false);
    expect(reveal(game, 0, 14)).toBe(true);
    expect(game.cells[0][14]).toMatchObject({ revealed: true, mine: false, adjacent: 0 });
    expect(game.cells[0].filter(cell => cell.mine)).toHaveLength(config.mines);
    expect(game.cells[0].filter(cell => cell.revealed).length).toBeGreaterThan(1);
    expect(game.status).toBe('playing');
  });

  it('reproduces identical boards for seed, floor, and first tile', () => {
    const a = createGame({ ...config, floors: 3 });
    const b = createGame({ ...config, floors: 3 });
    for (const floor of [2, 0, 1]) reveal(a, floor, 14);
    for (const floor of [0, 1, 2]) reveal(b, floor, 14);
    expect(a).toEqual(b);
    expect(a.cells[0].map(c => c.mine)).not.toEqual(a.cells[1].map(c => c.mine));
  });

  it('keeps floors independent and requires every floor for victory', () => {
    const game = createGame({ ...config, mines: 0, floors: 3 });
    reveal(game, 0, 0);
    expect(game.cells[0].every(cell => cell.revealed)).toBe(true);
    expect(game.cells[1].some(cell => cell.revealed)).toBe(false);
    expect(game.status).toBe('playing');
    reveal(game, 1, 0);
    reveal(game, 2, 0);
    expect(game.status).toBe('won');
  });

  it('still protects the first tile on dense boards', () => {
    const game = createGame({ ...config, width: 2, height: 2, mines: 3 });
    reveal(game, 0, 0);
    expect(game.cells[0][0]).toMatchObject({ mine: false, revealed: true, adjacent: 3 });
    expect(game.status).toBe('won');
  });

  it('does not wrap adjacency across row edges', () => {
    expect(neighbors(config, 0)).toEqual([1, 6, 7]);
    expect(neighbors(config, 5)).toEqual([4, 10, 11]);
    expect(neighbors(config, 14)).toHaveLength(8);
  });
});

describe('player actions', () => {
  it('preserves flags through generation and flood, and prevents revealing flagged tiles', () => {
    const game = createGame({ ...config, mines: 0 });
    toggleFlag(game, 0, 1);
    expect(reveal(game, 0, 1)).toBe(false);
    expect(game.started[0]).toBe(false);
    reveal(game, 0, 0);
    expect(game.cells[0][1]).toMatchObject({ flagged: true, revealed: false });
    expect(game.status).toBe('playing');
    toggleFlag(game, 0, 1);
    reveal(game, 0, 1);
    expect(game.status).toBe('won');
    expect(toggleFlag(game, 0, 2)).toBe(false);
  });

  it('reveals neighboring tiles on a correctly flagged chord', () => {
    const game = createGame(config);
    reveal(game, 0, 14);
    const index = numbered(game);
    expect(index).toBeGreaterThanOrEqual(0);
    const around = neighbors(config, index);
    expect(chord(game, 0, index)).toBe(false);
    around.filter(i => game.cells[0][i].mine).forEach(i => toggleFlag(game, 0, i));
    expect(chord(game, 0, index)).toBe(true);
    expect(around.every(i => game.cells[0][i].flagged || game.cells[0][i].revealed)).toBe(true);
    expect(game.status).not.toBe('lost');
  });

  it('loses when a chord has the right flag count but wrong flags', () => {
    const game = createGame(config);
    reveal(game, 0, 14);
    const index = numbered(game);
    const around = neighbors(config, index);
    const mine = around.find(i => game.cells[0][i].mine)!;
    around.filter(i => game.cells[0][i].mine && i !== mine).forEach(i => toggleFlag(game, 0, i));
    toggleFlag(game, 0, around.find(i => !game.cells[0][i].mine && !game.cells[0][i].revealed)!);
    expect(chord(game, 0, index)).toBe(true);
    expect(game.status).toBe('lost');
    expect(game.exploded).toEqual({ floor: 0, index: mine });
  });

  it('records the detonated tile and blocks actions after loss', () => {
    const game = createGame(config);
    reveal(game, 0, 14);
    const mine = game.cells[0].findIndex(c => c.mine);
    reveal(game, 0, mine);
    expect(game.status).toBe('lost');
    expect(game.exploded).toEqual({ floor: 0, index: mine });
    const snapshot = copy(game);
    expect(reveal(game, 0, 0)).toBe(false);
    expect(toggleFlag(game, 0, 1)).toBe(false);
    expect(chord(game, 0, 14)).toBe(false);
    expect(game).toEqual(snapshot);
  });

  it('wins by revealing all safe cells without needing flags', () => {
    const game = createGame(config);
    reveal(game, 0, 14);
    game.cells[0].forEach((cell, i) => { if (!cell.mine) reveal(game, 0, i); });
    expect(game.status).toBe('won');
  });

  it('rejects invalid actions and configurations', () => {
    const game = createGame(config);
    for (const [floor, index] of [[-1, 0], [1, 0], [0, 36], [0, NaN], [0, 0.5]]) {
      expect(reveal(game, floor, index)).toBe(false);
      expect(toggleFlag(game, floor, index)).toBe(false);
      expect(chord(game, floor, index)).toBe(false);
    }
    expect(() => createGame({ ...config, mines: 36 })).toThrow(RangeError);
    expect(() => createGame({ ...config, floors: 4 })).toThrow(RangeError);
    expect(() => createGame({ ...config, seed: '' })).toThrow(RangeError);
  });
});

describe('save validation', () => {
  it('round-trips ready, playing, won, and lost states without retaining references', () => {
    const ready = createGame(config);
    toggleFlag(ready, 0, 0);
    const playing = createGame({ ...config, floors: 2 });
    reveal(playing, 1, 14);
    const lost = createGame(config);
    reveal(lost, 0, 14);
    reveal(lost, 0, lost.cells[0].findIndex(c => c.mine));
    const won = createGame({ ...config, mines: 0 });
    reveal(won, 0, 0);
    for (const game of [ready, playing, lost, won]) {
      const restored = restoreGame(copy(game));
      expect(restored).toEqual(game);
      expect(restored?.cells).not.toBe(game.cells);
    }
  });

  it('rejects malformed, inconsistent, and corrupted saves', () => {
    const game = createGame(config);
    reveal(game, 0, 14);
    const mutations: ((save: Game) => void)[] = [
      save => { save.cells.pop(); },
      save => { save.started = [false]; },
      save => { save.cells[0][14].adjacent = 8; },
      save => { save.cells[0][14].flagged = true; },
      save => { save.cells[0].find(c => c.mine)!.mine = false; },
      save => { save.status = 'won'; },
      save => { save.exploded = { floor: 0, index: 14 }; },
      save => { save.config.width = Infinity; },
    ];
    for (const mutate of mutations) {
      const saved = copy(game);
      mutate(saved);
      expect(restoreGame(saved)).toBeNull();
    }
    for (const value of [null, {}, 'invalid', [], { config: null }]) expect(restoreGame(value)).toBeNull();
    const lost = copy(game);
    reveal(lost, 0, lost.cells[0].findIndex(c => c.mine));
    delete lost.exploded;
    expect(restoreGame(lost)).toBeNull();
  });
});


const connected: Config = { width: 6, height: 6, mines: 5, floors: 3, seed: 'connections', mode: 'connected', firstReveal: [14, 14, 14], generatorVersion: 1 };
function verticalFixture(mineIndex = 0): Game {
  const game = createGame({ width: 3, height: 3, mines: 1, floors: 2, seed: 'fixture' });
  game.started = [true, true];
  game.status = 'playing';
  game.cells.forEach(floor => floor.forEach(cell => { cell.clueType = 'local'; }));
  game.cells[0][8].mine = true;
  game.cells[1][mineIndex].mine = true;
  game.cells[0][4].clueType = 'above';
  game.cells.forEach((floor, f) => floor.forEach((cell, i) => {
    const targetFloor = cell.clueType === 'above' ? f + 1 : f;
    const indices = cell.clueType === 'above' ? [i, ...neighbors(game.config, i)] : neighbors(game.config, i);
    cell.adjacent = indices.filter(j => game.cells[targetFloor][j].mine).length;
  }));
  return game;
}

describe('Connected topology and actions', () => {
  it('uses exactly the clipped adjacent-floor footprint including aligned coordinates', () => {
    const game = createGame(connected);
    game.cells[1][14].clueType = 'above';
    expect(clueNeighbors(game, 1, 14)).toHaveLength(9);
    expect(clueNeighbors(game, 1, 14)).toContainEqual({ floor: 2, index: 14 });
    expect(clueNeighbors(game, 1, 14).every(p => p.floor === 2)).toBe(true);
    game.cells[1][0].clueType = 'below';
    expect(clueNeighbors(game, 1, 0).map(p => p.index).sort((a,b) => a-b)).toEqual([0,1,6,7]);
    expect(clueNeighbors(game, 1, 0).every(p => p.floor === 0)).toBe(true);
    game.cells[1][2].clueType = 'above';
    expect(clueNeighbors(game, 1, 2)).toHaveLength(6);
  });

  it('generates all floors before any clue is read and respects boundary/direction lessons', () => {
    for (const vertical of ['above', 'below', 'both'] as const) {
      const game = createGame({ ...connected, vertical });
      expect(game.status).toBe('ready');
      expect(game.started).toEqual([false,false,false]);
      game.cells.forEach((floor, f) => {
        expect(floor.filter(c => c.mine)).toHaveLength(connected.mines);
        floor.forEach((cell, i) => {
          if (f === 0) expect(cell.clueType).not.toBe('below');
          if (f === 2) expect(cell.clueType).not.toBe('above');
          if (vertical === 'above') expect(cell.clueType).not.toBe('below');
          if (vertical === 'below') expect(cell.clueType).not.toBe('above');
          const type = cell.clueType;
          const targetFloor = type === 'above' ? f+1 : type === 'below' ? f-1 : f;
          const x = i % connected.width, y = Math.floor(i / connected.width);
          let count = 0;
          for(let dy=-1;dy<=1;dy++) for(let dx=-1;dx<=1;dx++) {
            if(type === 'local' && dx === 0 && dy === 0) continue;
            if(x+dx<0 || x+dx>=connected.width || y+dy<0 || y+dy>=connected.height) continue;
            if(game.cells[targetFloor][(y+dy)*connected.width+x+dx].mine) count++;
          }
          expect(cell.adjacent).toBe(count);
        });
      });
    }
  });

  it('chords onto the indicated floor, and incorrect vertical flags can lose', () => {
    const correct = verticalFixture();
    correct.cells[0][4].revealed = true;
    toggleFlag(correct,1,0);
    expect(chord(correct,0,4)).toBe(true);
    expect(correct.status).not.toBe('lost');
    expect(correct.cells[1].every(c => c.flagged || c.revealed)).toBe(true);
    const wrong = verticalFixture();
    wrong.cells[0][4].revealed = true;
    toggleFlag(wrong,1,1);
    expect(chord(wrong,0,4)).toBe(true);
    expect(wrong.status).toBe('lost');
    expect(wrong.exploded).toEqual({floor:1,index:0});
  });

  it('vertical zero floods its target footprint without revealing mines or own-floor neighbors', () => {
    const game = verticalFixture(8);
    game.cells[0][4].clueType = 'local';
    game.cells[0][0].clueType = 'above';
    game.cells[0][0].adjacent = 0;
    reveal(game,0,0);
    expect([0,1,3,4].every(i => game.cells[1][i].revealed)).toBe(true);
    expect(game.cells[0].filter(c => c.revealed)).toHaveLength(1);
    expect(game.cells.flat().some(c => c.mine && c.revealed)).toBe(false);
    expect(game.cells[1][8].revealed).toBe(false);
  });

  it('replays fixed starts exactly and rejects a different initial campaign opening', () => {
    const ready = createGame(connected);
    expect(reveal(ready,0,0)).toBe(false);
    expect(ready.status).toBe('ready');
    const a = startGame(connected), b = startGame(connected);
    expect(a).toEqual(b);
    expect(a.started.every(Boolean)).toBe(true);
    for(let f=0;f<3;f++) expect(a.cells[f][14]).toMatchObject({mine:false,revealed:true});
    const mine = a.cells[0].findIndex(c => c.mine);
    reveal(a,0,mine);
    expect(a.status).toBe('lost');
    expect(startGame(a.config)).toEqual(b);
    expect(restoreGame(copy(a))).toEqual(a);
    expect(restoreGame(copy(b))).toEqual(b);
    expect(restoreGame(copy(ready))).toEqual(ready);
  });

  it('keeps fixed Classic/Layered layout independent of reveal order and config references', () => {
    const cfg: Config = {...config, floors:2, firstReveal:[14,14], generatorVersion:1};
    const a=createGame(cfg), b=createGame(cfg);
    reveal(a,1,14);reveal(a,0,14);
    reveal(b,0,14);reveal(b,1,14);
    expect(a).toEqual(b);
    cfg.firstReveal![0]=1;
    expect(a.config.firstReveal).toEqual([14,14]);
    expect(restoreGame(copy(a))).toEqual(a);
  });

  it('rejects corrupt Connected types/layouts/version and invalid fixed configs', () => {
    const game=startGame(connected);
    const wrongType=copy(game);wrongType.cells[0][0].clueType='below';
    const wrongClue=copy(game);wrongClue.cells[0][0].adjacent++;
    const wrongMine=copy(game);wrongMine.cells[1][0].mine=!wrongMine.cells[1][0].mine;
    for(const save of [wrongType,wrongClue,wrongMine]) expect(restoreGame(save)).toBeNull();
    for(const patch of [{firstReveal:[14]}, {firstReveal:[14,14,99]}, {generatorVersion:2}, {mode:'connected',floors:1}, {vertical:'sideways'}]) {
      expect(()=>createGame({...connected,...patch} as Config)).toThrow(RangeError);
    }
  });
});


it('preserves safe openings, mine totals, flood safety and saves across seeded Connected boards', () => {
  for(let seed=0;seed<40;seed++) {
    const cfg={...connected,seed:`invariant-${seed}`,firstReveal:[7,14,28]};
    const game=startGame(cfg);
    expect(game.status).not.toBe('lost');
    expect(game.cells.flat().some(c=>c.mine&&c.revealed)).toBe(false);
    expect(restoreGame(copy(game))).toEqual(game);
    game.cells.forEach((floor,f)=>{
      expect(floor.filter(c=>c.mine)).toHaveLength(cfg.mines);
      expect(floor[cfg.firstReveal[f]].revealed).toBe(true);
      floor.forEach((cell,i)=>{if(!cell.mine)reveal(game,f,i);});
    });
    expect(game.status).toBe('won');
    expect(restoreGame(copy(game))).toEqual(game);
  }
});


it('retries legacy freeplay losses with the exact layout and cleared flags', () => {
  const original=createGame({...config,floors:3});
  reveal(original,0,7);
  reveal(original,1,22);
  const flag=original.cells[0].findIndex(c=>!c.revealed);
  toggleFlag(original,0,flag);
  const mine=original.cells[1].findIndex(c=>c.mine);
  reveal(original,1,mine);
  expect(original.status).toBe('lost');
  const migrated=restoreGame(copy(original))!;
  const retry=retryGame(migrated);
  for(const f of [0,1]) expect(retry.cells[f].map(c=>c.mine)).toEqual(original.cells[f].map(c=>c.mine));
  expect(retry.cells.flat().some(c=>c.flagged)).toBe(false);
  expect(retry.status).not.toBe('lost');
  expect(retry.config.firstReveal).toHaveLength(3);
  expect(retryGame(retry)).toEqual(retry);
  expect(restoreGame(copy(retry))).toEqual(retry);
  expect(original.status).toBe('lost');
});

it('retries won legacy and fixed puzzles without changing their layouts', () => {
  const legacy=createGame(config);
  reveal(legacy,0,22);
  legacy.cells[0].forEach((c,i)=>{if(!c.mine)reveal(legacy,0,i);});
  expect(legacy.status).toBe('won');
  const retry=retryGame(legacy);
  expect(retry.cells[0].map(c=>c.mine)).toEqual(legacy.cells[0].map(c=>c.mine));
  expect(retryGame(retry)).toEqual(retry);
  const fixed=startGame(connected);
  expect(retryGame(fixed)).toEqual(fixed);
});
