import { GameManager, createMemoryStorage } from '/tmp/t/public/game/gameManager.js';
import { PlayerAction, GameState } from '/tmp/t/public/game/gameState.js';
import { createFakeScheduler } from '/tmp/t/test/helpers.js';
const storage=createMemoryStorage(); const real=createFakeScheduler(); let boom=false;
const sch={ setTimeout:(cb,ms)=>{ if(boom) throw new Error('scheduler fault'); return real.setTimeout(cb,ms)}, clearTimeout:h=>real.clearTimeout(h), advance:ms=>real.advance(ms), get pending(){return real.pending} };
const game=new GameManager({scheduler:sch,storage}); game.handleAction(PlayerAction.newGame); game.handleAction(PlayerAction.pause);
console.log('before: state',game.state,'saved flag',game.isSessionSaved,'stored text',(storage.getItem('tetris.savedGameSession')||'').length,'chars');
boom=true; game.handleAction(PlayerAction.newGame); game.handleAction(PlayerAction.newGame);
console.log('after fault after withdrawal: state',game.state,'faults',game.faults.length,'saved flag',game.isSessionSaved,'stored flag',storage.getItem('tetris.isSessionSaved'),'stored text kept',(storage.getItem('tetris.savedGameSession')||'').length,'chars');
