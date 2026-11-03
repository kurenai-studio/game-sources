import './style.css';
import { startGame, retryGame, reveal, toggleFlag, chord, clueNeighbors, type Game } from './engine';
import { BoardScene } from './scene';
import { DoubleTap } from './gestures';
import { campaign } from './campaign';
import { nextDeduction } from './solver';
import { readSession, writeSession, type Session } from './storage';

const KEY = 'petal-save-v2';
const chapters = ['classic', 'layered', 'connected'] as const;
type Chapter = typeof chapters[number];
const titles = {classic:'The simple things',layered:'A little more depth',connected:'Hidden connections'};
const ids = campaign.map(level => level.id);
let game = startGame(campaign[0].config);
let active = 0, exploded = false, elapsed = 0;
let action: Session['action'] = 'reveal';
let levelId: string | null = campaign[0].id;
let completed: string[] = [];
const accessibleDoubleTap = new DoubleTap();
let inspected: {floor:number;index:number} | undefined;
let notice = '', storageAvailable = true;
let lastTick = performance.now(), elapsedRemainder = 0;
function newSeed() { return Array.from(crypto.getRandomValues(new Uint32Array(4)), n => n.toString(16).padStart(8,'0')).join(''); }
try {
  const raw = localStorage.getItem(KEY) ?? localStorage.getItem('petal-save-v1');
  const session = readSession(raw, ids);
  if (session) {
    ({game,active,elapsed,exploded,action,levelId,completed} = session);
    // A campaign save must still describe the shipped level, including its fixed opening.
    const level = campaign.find(l => l.id === levelId);
    if (level && JSON.stringify(game.config) !== JSON.stringify(startGame(level.config).config)) {
      game = startGame(level.config); elapsed = 0; active = 0;
      notice = 'This level was updated. Your attempt has restarted; chapter progress is kept.';
    }
  } else if (raw) notice = 'The previous save could not be restored. A fresh puzzle is ready.';
} catch { storageAvailable = false; }

const $ = <T extends HTMLElement = HTMLElement>(id:string) => document.getElementById(id) as T;
document.querySelector<HTMLDivElement>('#app')!.innerHTML = `
<header class="topbar"><a class="brand" href="./" aria-label="Petal home"><span class="brand-cube" aria-hidden="true"></span>petal<span class="brand-sub">MINESWEEPER, IN A NEW DIMENSION</span></a><button id="help" class="text-button">How to play ↗</button></header>
<main>
<nav class="journey" aria-label="Hybrid progression">${chapters.map((c,i)=>`<button id="${c}" class="phase"><span>0${i+1}</span> ${c[0].toUpperCase()+c.slice(1)}</button><span class="connector"></span>`).join('')}<button class="phase future" disabled title="Future chapter: full 3D adjacency"><span>04</span> Volume <small>SOON</small></button></nav>
<section class="intro"><div><p class="eyebrow" id="chapter"></p><h1>A little world of logic<span>.</span></h1><p class="subtitle" id="subtitle"></p></div><div class="puzzle-actions"><button id="retry" class="text-button">↻ Retry</button><button id="new" class="new-button">New puzzle</button></div></section>
<section class="level-controls" aria-label="Puzzle selection"><label>Play <select id="play-type"><option value="campaign">Campaign · no guessing</option><option value="free">Free play · may need guesses</option></select></label><label id="level-label">Level <select id="level-select"></select></label><label id="count-label" hidden>Floors <select id="floor-count"><option value="1">1 floor</option><option value="2">2 floors</option><option value="3">3 floors</option></select></label><span id="campaign-progress"></span></section>
<p id="lesson" class="lesson"></p>
<section class="play-area" aria-label="Minesweeper game">
<div class="stats"><div><span class="stat-icon" aria-hidden="true">⚑</span><strong id="mines"></strong><small>MINES LEFT</small></div><span class="stat-divider"></span><div><strong id="timer">00:00</strong><small>ACTIVE PLAY</small></div><span class="stat-divider"></span><div><strong id="progress"></strong><small>TILES CLEARED</small></div></div>
<div class="scene" id="scene" aria-label="3D puzzle board. Tap to reveal, hold to flag. The HTML board below supports keyboard play."></div>
<div class="scene-caption"><span class="tiny-cube" aria-hidden="true"></span><span id="floor-caption"></span></div>
<aside class="floors"><span class="eyebrow">YOUR FLOORS</span><div id="floor-buttons"></div></aside>
<div class="view-controls"><button id="focus" aria-pressed="true">▣ <span>Focus</span></button><button id="explode" aria-pressed="false">▤ <span>Exploded</span></button><button id="reset-view" aria-label="Reset camera">⟲</button></div>
<div id="result" class="result" role="status" hidden></div>
</section>
<section class="bottom-bar"><div class="mode-switch" aria-label="Tap action"><button id="reveal-mode">◇ Reveal</button><button id="flag-mode">⚑ Flag</button><button id="inspect-mode">⌕ Inspect</button></div><button id="hint" class="text-button" title="Uses visible clues and assumes your flags are correct">One logical hint ↗</button><span class="save-state" id="save-state"></span><p class="gesture-hint">Tap to reveal <span>·</span> Hold to flag <span>·</span> Drag to rotate</p></section>
<p id="notice" class="notice" role="status" aria-live="polite"></p>
<section id="inspector" class="inspector" aria-label="Clue neighborhood" hidden><div><p class="eyebrow">FOLLOW THE CLUE</p><p id="clue-description"></p><p id="clue-targets"></p></div><div class="inspector-actions"><button id="target-floor" class="new-button">View target floor</button><button id="chord" class="new-button">Open unflagged neighbors</button><button id="clear-inspect" class="text-button">Close inspection ×</button></div></section>
<details class="accessible"><summary>Keyboard & accessible board</summary><p>Arrow keys move. Enter/Space uses the selected action; F toggles a flag; I inspects a clue; C chords the focused clue. E changes view; 1–3 selects floors. Highlighted cells belong to the inspected clue.</p><div id="accessible-board" role="grid" aria-label="Current floor"></div></details>
<footer><span>Small steps. Clear thinking.</span><span id="seed"></span></footer>
</main>
<dialog id="rules"><button id="close-help" class="close" aria-label="Close instructions">×</button><p class="eyebrow">A MOMENT TO GET YOUR BEARINGS</p><h2>Make a little room<br>for clear thinking.</h2><p>Reveal every safe tile on every floor to win. A mine ends the attempt. Flags alone do not win.</p><ul><li><strong>Classic / Layered:</strong> a plain number counts the eight same-floor neighbors. Layered floors are independent.</li><li><strong>Connected:</strong> ↑ counts the 3×3 footprint on the floor immediately above; ↓ counts the floor immediately below. Both include the aligned tile, clip at edges, and exclude the clue’s own floor. Plain numbers remain local.</li><li><strong>Inspect:</strong> tap a revealed clue or select Inspect, then tap it. The highlighted cells are its exact neighborhood; View target floor reaches vertical targets.</li><li><strong>Chord:</strong> double-click or double-tap a revealed number, or choose Open unflagged neighbors. Chording works when the target flags equal the clue. Wrong flags can expose a mine. Hints also assume your flags are correct. Zeros and chords use the same neighborhood as the displayed clue.</li><li><strong>Explore:</strong> drag to rotate, pinch or scroll to zoom. Focus isolates the selected floor. Exploded shows the stack; only the selected floor accepts taps.</li><li><strong>Campaign:</strong> fixed safe openings and solver-validated puzzles. Retry restores the same puzzle. Clear levels to unlock the next. Free play is random and can require guesses.</li></ul><button id="start-play" class="new-button">Let’s play</button></dialog>`;
let scene: BoardScene | undefined;
try { scene = new BoardScene($('scene'), act); }
catch { $('scene').innerHTML = '<p class="webgl-error">3D graphics are unavailable.<br>Open the HTML board below to play.</p>'; document.querySelector<HTMLDetailsElement>('.accessible')!.open = true; }
function chapter(): Chapter { return game.config.mode === 'connected' ? 'connected' : game.config.floors > 1 ? 'layered' : 'classic'; }
function unlocked(index:number) { return index === 0 || completed.includes(campaign[index-1].id); }
function chapterUnlocked(c:Chapter) { return unlocked(campaign.findIndex(l=>l.chapter===c)); }
function save() {
  try { localStorage.setItem(KEY,writeSession({game,active,elapsed,exploded,action,levelId,completed})); }
  catch { storageAvailable = false; }
  $('save-state').textContent = storageAvailable ? 'Saved on this device' : 'Saving unavailable · keep this tab open';
}
function inspect(floor:number,index:number) {
  if (!game.cells[floor][index].revealed || game.cells[floor][index].mine) { notice = 'Reveal a safe clue before inspecting its neighborhood.'; return; }
  inspected = {floor,index}; notice = '';
}
function markCompletion() {
  if (game.status === 'won' && levelId && !completed.includes(levelId)) completed.push(levelId);
}
function act(floor:number,index:number,flag:boolean,doubleTap=false) {
  if (floor !== active) return;
  const cell = game.cells[floor][index]; notice = '';
  if (doubleTap && cell.revealed && !cell.mine) {performChord(floor,index);return;}
  if (flag || action === 'flag') toggleFlag(game,floor,index);
  else if (action === 'inspect' || cell.revealed) inspect(floor,index);
  else reveal(game,floor,index);
  markCompletion(); draw(); save();
}
function performChord(floor:number,index:number) {
  if (!chord(game,floor,index)) notice = 'Chord needs a revealed clue with the same number of flags in its highlighted neighborhood.';
  else notice = '';
  markCompletion(); draw(); save();
}
function draw() {
  scene?.update(game,active,exploded,inspected);
  const cells = game.cells.flat(), cleared = cells.filter(c=>c.revealed&&!c.mine).length;
  const c = chapter(), level = campaign.find(l=>l.id===levelId);
  $('mines').textContent = String(game.config.mines*game.config.floors-cells.filter(c=>c.flagged).length).padStart(2,'0');
  $('progress').textContent = `${cleared} / ${cells.length-game.config.mines*game.config.floors}`;
  $('chapter').textContent = `CHAPTER 0${chapters.indexOf(c)+1} · ${titles[c].toUpperCase()}`;
  $('subtitle').textContent = level ? level.title : `${c[0].toUpperCase()+c.slice(1)} free play · random puzzles may require guesses`;
  $('lesson').textContent = level ? level.lesson : c==='connected' ? 'Plain numbers count locally. ↑ and ↓ count the adjacent floor’s 3×3 footprint. Fixed safe openings are already revealed.' : game.config.firstReveal?'Safe openings on each floor are already revealed. Reveal every safe tile to finish.':'Your first reveal on each unopened floor is safe. Reveal every safe tile to finish.';
  for (const ch of chapters) { $(ch).classList.toggle('current',ch===c); $(ch).setAttribute('aria-current',ch===c?'step':'false'); $<HTMLButtonElement>(ch).disabled=!chapterUnlocked(ch); $(ch).title=chapterUnlocked(ch)?`Play ${ch}`:'Complete the preceding campaign levels to unlock'; }
  $<HTMLSelectElement>('play-type').value=levelId?'campaign':'free';
  $('level-label').hidden=!levelId; $('count-label').hidden=!!levelId;
  $<HTMLSelectElement>('floor-count').value=String(game.config.floors);
  $<HTMLSelectElement>('floor-count').disabled=c==='connected';
  $('level-select').innerHTML=campaign.map((l,i)=>`<option value="${l.id}" ${l.id===levelId?'selected':''} ${unlocked(i)?'':'disabled'}>${completed.includes(l.id)?'✓ ':''}${i+1}. ${l.title}${unlocked(i)?'':' · locked'}</option>`).join('');
  $('campaign-progress').textContent=`${completed.length} / ${campaign.length} levels cleared · ${game.config.mines} mines per floor`;
  const next = level ? campaign.findIndex(l=>l.id===levelId)+1 : -1;
  $('new').textContent=level ? next<campaign.length?'Next level →':'Back to free play →':'New puzzle';
  $<HTMLButtonElement>('new').disabled=!!level&&game.status!=='won';
  $('floor-caption').textContent=`FLOOR ${String(active+1).padStart(2,'0')} / ${exploded?'A different perspective':'One floor at a time'}`;
  $('floor-buttons').innerHTML=game.cells.map((floor,f)=>{const n=floor.filter(c=>c.revealed&&!c.mine).length;return `<button class="floor-button ${f===active?'active':''}" data-floor="${f}" aria-pressed="${f===active}"><span class="floor-symbol" aria-hidden="true">▱</span><span>Floor ${String(f+1).padStart(2,'0')}<small>${n} / ${floor.length-game.config.mines} cleared</small></span><span>${n===floor.length-game.config.mines?'✓':'↗'}</span></button>`;}).reverse().join('');
  $('floor-buttons').querySelectorAll<HTMLButtonElement>('button').forEach(b=>b.onclick=()=>setFloor(Number(b.dataset.floor)));
  $('result').hidden=!['won','lost'].includes(game.status); $('result').textContent=game.status==='won'?'Beautifully done. Every floor is clear.':'A little misstep. Retry this exact puzzle or choose another.'; $('result').classList.toggle('loss',game.status==='lost');
  $('seed').textContent=`${levelId ? `LEVEL ${levelId.toUpperCase()}` : `PUZZLE ${game.config.seed.slice(0,12).toUpperCase()}`} · G1`;
  $('notice').textContent=notice;
  for (const [id,on] of [['focus',!exploded],['explode',exploded],['reveal-mode',action==='reveal'],['flag-mode',action==='flag'],['inspect-mode',action==='inspect']] as const) { $(id).classList.toggle('selected',on); $(id).setAttribute('aria-pressed',String(on)); }
  drawInspector(); drawAccessible(); tick();
}
function drawInspector() {
  $('inspector').hidden=!inspected;
  if(!inspected)return;
  const {floor,index}=inspected, cell=game.cells[floor][index], targets=clueNeighbors(game,floor,index), type=cell.clueType??'local';
  const flags=targets.filter(p=>game.cells[p.floor][p.index].flagged).length;
  $('clue-description').textContent=`Floor ${floor+1}, row ${Math.floor(index/game.config.width)+1}, column ${index%game.config.width+1}: ${type==='above'?'↑ Above':type==='below'?'↓ Below':'Local'} ${cell.adjacent}. Counts ${targets.length} cells ${type==='local'?'on this floor':`on floor ${targets[0]?.floor+1}`}.`;
  $('clue-targets').textContent=`${flags} flags in this neighborhood. ${targets.filter(p=>!game.cells[p.floor][p.index].revealed&&!game.cells[p.floor][p.index].flagged).length} unflagged hidden tiles. ${type==='local'?'The clue cell itself is excluded.':'The directly aligned tile is included; this floor is excluded.'}`;
  $<HTMLButtonElement>('target-floor').disabled=type==='local';
  $<HTMLButtonElement>('chord').disabled=flags!==cell.adjacent||!targets.some(p=>!game.cells[p.floor][p.index].revealed&&!game.cells[p.floor][p.index].flagged)||game.status==='lost'||game.status==='won';
}
function drawAccessible() {
  const board=$('accessible-board'), w=game.config.width;
  const focused=(document.activeElement as HTMLElement)?.dataset.cell;
  const targets=inspected?clueNeighbors(game,inspected.floor,inspected.index):[];
  board.style.gridTemplateColumns=`repeat(${w}, 1fr)`;
  board.setAttribute('aria-label',`Floor ${active+1}`);
  board.innerHTML=Array.from({length:game.config.height},(_,row)=>`<div role="row" class="board-row">${game.cells[active].slice(row*w,(row+1)*w).map((cell,col)=>{
    const i=row*w+col, mine=cell.mine&&(cell.revealed||game.status==='lost'), type=cell.clueType??'local';
    const target=targets.some(p=>p.floor===active&&p.index===i), source=inspected?.floor===active&&inspected.index===i;
    const arrow=type==='above'?'↑':type==='below'?'↓':'';
    const state=mine?'Mine':cell.flagged?'Flagged':cell.revealed?`${type} clue ${cell.adjacent}`:'Hidden';
    return `<button role="gridcell" data-cell="${i}" tabindex="${i===Number(focused??0)?0:-1}" aria-label="Row ${row+1}, column ${col+1}: ${state}${target?', clue target':''}${source?', inspected clue':''}" class="${cell.revealed?'open':''} ${target?'target':''} ${source?'source':''}">${mine?'✹':cell.flagged?'⚑':cell.revealed?`${arrow}${type!=='local'?cell.adjacent:cell.adjacent||'·'}`:'◇'}</button>`;
  }).join('')}</div>`).join('');
  board.querySelectorAll<HTMLButtonElement>('button').forEach(b=>{
    const i=Number(b.dataset.cell);
    b.onclick=e=>{
      const cell=game.cells[active][i], eligible=e.detail>0&&cell.revealed&&!cell.mine;
      const top=b.getBoundingClientRect().top;
      const doubleTap=accessibleDoubleTap.tap({floor:active,index:i},performance.now(),eligible);
      act(active,i,false,doubleTap);
      // Keep the number under the pointer when inspection inserts content above the grid.
      if(eligible) window.scrollBy(0,board.querySelector<HTMLElement>(`[data-cell="${i}"]`)!.getBoundingClientRect().top-top);
    };
    b.onkeydown=e=>{
      accessibleDoubleTap.reset();
      if(['f','i','c'].includes(e.key.toLowerCase())){e.preventDefault();if(e.key.toLowerCase()==='f')act(active,i,true);else if(e.key.toLowerCase()==='i'){inspect(active,i);draw();}else performChord(active,i);return;}
      let next=i;
      if(e.key==='ArrowRight')next=Math.min(i+1,w*game.config.height-1);else if(e.key==='ArrowLeft')next=Math.max(i-1,0);else if(e.key==='ArrowDown')next=Math.min(i+w,w*game.config.height-1);else if(e.key==='ArrowUp')next=Math.max(i-w,0);else return;
      e.preventDefault();b.tabIndex=-1;const target=board.querySelector<HTMLButtonElement>(`[data-cell="${next}"]`)!;target.tabIndex=0;target.focus();
    };
  });
  if(focused!==undefined)board.querySelector<HTMLButtonElement>(`[data-cell="${focused}"]`)?.focus();
}
function resetUI() { accessibleDoubleTap.reset();active=0;elapsed=0;elapsedRemainder=0;lastTick=performance.now();inspected=undefined;notice='';scene?.reset();markCompletion();draw();save(); }
function loadLevel(id:string) {const index=campaign.findIndex(l=>l.id===id);if(index<0||!unlocked(index))return;levelId=id;game=startGame(campaign[index].config);resetUI();}
function freePlay(c:Chapter,floors=c==='classic'?1:c==='connected'?3:2) {
  levelId=null;game=startGame({width:6,height:6,mines:c==='connected'?5:6,floors:c==='connected'?3:floors,mode:c==='connected'?'connected':floors===1?'classic':'layered',...(c==='connected'?{vertical:'both' as const}:{}),seed:newSeed(),generatorVersion:1});resetUI();
}
function setFloor(floor:number) {if(floor<game.config.floors){accessibleDoubleTap.reset();active=floor;draw();save();}}
$('retry').onclick=()=>{try {game=retryGame(game);resetUI();}catch{notice='This legacy puzzle cannot be reproduced from its seed. Choose New puzzle to continue.';draw();}};
$('new').onclick=()=>{if(levelId){const next=campaign.findIndex(l=>l.id===levelId)+1;if(next<campaign.length)loadLevel(campaign[next].id);else freePlay('connected');}else freePlay(chapter(),game.config.floors);};
for(const c of chapters)$(c).onclick=()=>loadLevel(campaign.find(l=>l.chapter===c)!.id);
$<HTMLSelectElement>('level-select').onchange=e=>loadLevel((e.target as HTMLSelectElement).value);
$<HTMLSelectElement>('play-type').onchange=e=>{if((e.target as HTMLSelectElement).value==='free')freePlay(chapter());else loadLevel(campaign.find(l=>l.chapter===chapter())!.id);};
$<HTMLSelectElement>('floor-count').onchange=e=>{const n=Number((e.target as HTMLSelectElement).value);if(n>1&&!chapterUnlocked('layered')){notice='Clear the Classic campaign to unlock multiple floors.';draw();return;}freePlay(n===1?'classic':'layered',n);};
$('focus').onclick=()=>{exploded=false;draw();save();};$('explode').onclick=()=>{exploded=true;draw();save();};$('reset-view').onclick=()=>scene?.reset();
for(const a of ['reveal','flag','inspect'] as const)$(`${a}-mode`).onclick=()=>{action=a;draw();save();};
$('target-floor').onclick=()=>{if(inspected){const targets=clueNeighbors(game,inspected.floor,inspected.index);if(targets.length)setFloor(targets[0].floor);}};
$('chord').onclick=()=>{if(inspected)performChord(inspected.floor,inspected.index);};
$('clear-inspect').onclick=()=>{inspected=undefined;draw();};
$('hint').onclick=()=>{
  if(game.status==='won'||game.status==='lost'){notice='Retry or start the next puzzle to continue.';draw();return;}
  const step=nextDeduction(game);
  if(step==='contradiction'){notice='These flags contradict the available clues. Check or remove your flags before requesting a hint.';draw();return;}
  if(!step){notice='No deduction is available with these flags. Check your flags; random free play may require a guess.';draw();return;}
  active=step.floor;
  if(step.action==='flag')toggleFlag(game,step.floor,step.index);else reveal(game,step.floor,step.index);
  inspected=step.sources[0];notice=`Logical hint: ${step.action==='flag'?'flagged':'revealed'} floor ${step.floor+1}, row ${Math.floor(step.index/game.config.width)+1}, column ${step.index%game.config.width+1}, using ${step.sources.length===0?'the published floor mine total':step.rule==='subset'?'overlapping clues':'a clue constraint'}. Hints assume your flags are correct.`;
  markCompletion();draw();save();
};
const rules=$<HTMLDialogElement>('rules');$('help').onclick=()=>rules.showModal();$('close-help').onclick=$('start-play').onclick=()=>{rules.close();lastTick=performance.now();};
window.addEventListener('keydown',e=>{if(rules.open||e.target instanceof HTMLSelectElement||e.altKey||e.ctrlKey||e.metaKey)return;if(e.key.toLowerCase()==='e'){exploded=!exploded;draw();save();}else if(/^[1-3]$/.test(e.key))setFloor(Number(e.key)-1);});
$('accessible-board').addEventListener('pointercancel',()=>accessibleDoubleTap.reset());
window.addEventListener('blur',()=>accessibleDoubleTap.reset());
function tick(){$('timer').textContent=`${String(Math.floor(elapsed/60)).padStart(2,'0')}:${String(elapsed%60).padStart(2,'0')}`;}
setInterval(()=>{const now=performance.now();if(game.status==='playing'&&!document.hidden&&!rules.open){elapsedRemainder+=Math.min(2000,now-lastTick);elapsed+=Math.floor(elapsedRemainder/1000);elapsedRemainder%=1000;tick();save();}lastTick=now;},1000);
document.addEventListener('visibilitychange',()=>{lastTick=performance.now();save();});window.addEventListener('pagehide',save);
markCompletion();draw();save();
