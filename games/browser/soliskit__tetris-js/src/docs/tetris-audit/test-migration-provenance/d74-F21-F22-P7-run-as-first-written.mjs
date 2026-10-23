import { GameManager, createMemoryStorage } from '/tmp/t/public/game/gameManager.js';
import { PlayerAction, GameState } from '/tmp/t/public/game/gameState.js';
import { createFakeScheduler, newGame, sequenceFactory } from '/tmp/t/test/helpers.js';
import { TetrominoFactory } from '/tmp/t/public/game/tetrominoFactory.js';
// F22
console.log('== F22 requested gravity delay vs formula, levels 1 to 2000');
{ let bad=0,minDiff=0,maxDiff=0,below=0; const { game, scheduler } = newGame();
  for (let lv=1; lv<=2000; lv++) { game.level=lv; const got=game.standardDropInterval*1000; const want=Math.max(250,700-20*(lv-1)); const d=got-want; if(d<0) below++; if(Math.abs(d)>1e-9) bad++; minDiff=Math.min(minDiff,d); maxDiff=Math.max(maxDiff,d); }
  console.log(' levels outside 1e-9 ms tolerance:',bad,'| levels slightly below nominal:',below,'| smallest diff',minDiff,'| largest diff',maxDiff);
  const caps=[]; const sch=createFakeScheduler(); const orig=sch.setTimeout; sch.setTimeout=(cb,ms)=>{caps.push(ms);return orig(cb,ms)};
  const g=newGame({scheduler:sch}).game; console.log(' level 1 requested delays seen:',[...new Set(caps)].join(', ')); }
// F21
console.log('== F21 sparse boards at the invariant check (injected)');
for (const [label,mut] of [['delete a whole row (board[5] hole)',g=>{delete g.gameBoard[5]}],['row replaced by sparse 10-slot array',g=>{g.gameBoard[3]=new Array(10)}],['one cell hole in a row',g=>{delete g.gameBoard[7][3]}],['20-slot sparse board',g=>{g.gameBoard=new Array(20)}],['control: row of 9',g=>{g.gameBoard[2]=g.gameBoard[2].slice(0,9)}]]) {
  const { game } = newGame(); mut(game); let v; try { v=game.findInvariantViolation(); } catch(e){ v='threw '+e.message; }
  console.log(' ',label,'-> check says:',v);
}
{ const { game, scheduler } = newGame(); delete game.gameBoard[5]; game.handleAction(PlayerAction.moveLeft); console.log('  after a move with the hole: state',game.state,'faults',game.faults.length);
  let t; try { game.saveGameSession(); t='save ok'; } catch(e){ t='save threw '+e.message } console.log('  save:',t); }
console.log('  reachability: JSON.parse of a board with null cells never makes holes; sparse needs a direct write.');
{ const s=JSON.parse('[1,null,3]'); console.log('  JSON.parse array holes?', 1 in s, Object.keys(s).length===s.length); }
// N1
console.log('== N1 New Game when the piece factory throws on the second call');
{ const storage=createMemoryStorage(); const sch=createFakeScheduler(); let n=0; let mode=false; const f=new TetrominoFactory();
  const factory={ generate:()=>{ if(mode) throw new Error('factory fault'); return f.generate(); }, resetBag:()=>f.resetBag?.() };
  const game=new GameManager({scheduler:sch,storage,factory}); game.handleAction(PlayerAction.newGame); game.handleAction(PlayerAction.moveLeft); game.handleAction(PlayerAction.pause ?? 'pause'); 
  console.log('  before: state',game.state,'saved flag',game.isSessionSaved,'stored text length',(storage.getItem('tetris.savedGameSession')||'').length);
  mode=true; game.handleAction(PlayerAction.newGame); if(game.state===GameState.paused) game.handleAction(PlayerAction.newGame);
  console.log('  after confirm with fault: state',game.state,'faults',game.faults.length,'saved flag',game.isSessionSaved,'stored text length',(storage.getItem('tetris.savedGameSession')||'').length,'stored flag',storage.getItem('tetris.isSessionSaved')); }
// P7
console.log('== P7 hand-edited canHoldTetromino');
{ const storage=createMemoryStorage(); const sch=createFakeScheduler(); const {game}=newGame({scheduler:sch,storage}); game.handleAction(PlayerAction.hold); console.log('  after one hold: canHold',game.canHoldTetromino); game.handleAction(PlayerAction.pause ?? 'pause'); game.saveGameSession();
  const key='tetris.savedGameSession'; const d=JSON.parse(storage.getItem(key)); console.log('  stored canHold:',d.canHoldTetromino); d.canHoldTetromino=true; storage.setItem(key,JSON.stringify(d));
  const g2=new GameManager({scheduler:createFakeScheduler(),storage}); g2.loadGameSession(); console.log('  loaded: state',g2.state,'canHold',g2.canHoldTetromino,'held?',!!g2.heldTetromino);
  if(g2.state===GameState.paused) g2.handleAction(PlayerAction.pause ?? 'pause'); const before=g2.currentTetromino?.color; g2.handleAction(PlayerAction.hold); console.log('  second hold accepted:', g2.canHoldTetromino===false, 'state',g2.state); }
