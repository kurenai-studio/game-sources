/* ══════════════ 21 · the welcome ══════════════ */
const NAMES=['Aubemont','Carrowgate','Hartlow','Duncaster','Roseneath','Fenmarch','Blackmere',
             'Thornbury','Cairnwell','Oakmoor','Sablecliff','Greywater','Highford','Lorrance',
             'Merrowdean','Stonewick','Ashbourne','Vellamar'];
const gate=$('gate'), nameIn=$('name');
nameIn.value=pick(NAMES);
$('roll').addEventListener('click',()=>{
  let n=pick(NAMES); if(n===nameIn.value) n=pick(NAMES);
  nameIn.value=n; nameIn.focus();
});
function begin(withPlan){
  setName(nameIn.value);
  const on=$('wantmusic').getAttribute('aria-pressed')==='true';
  if(on) Music.start(0.55);
  [...$('music').children].forEach(x=>
    x.setAttribute('aria-pressed',String(on?x.dataset.v==='0.55':x.dataset.v==='0')));
  if(withPlan){
    preset();
    placed.forEach(r=>{ FIRST[r.key]=true; });
    chron('The holding stands as the last castellan left it: walls, a keep, and a mill '+
          'that someone else paid for.',true);
  } else { clearBuild(); indexBuild(); }
  $('hud').hidden=false;
  requestAnimationFrame(()=>Panels.init());
  updateMarkers();
  refreshCensus();
  setTab(withPlan?'build':'terrain');
  say(withPlan?'The standard plan, already standing. Change it, clear it, or run the day as it is.'
              :'An empty valley. Shape the ground on this tab, then move to Build.');
  gate.classList.add('gone');
  setTimeout(()=>gate.remove(),700);
}
$('wantmusic').addEventListener('click',e=>{
  const on=e.currentTarget.getAttribute('aria-pressed')!=='true';
  e.currentTarget.setAttribute('aria-pressed',String(on));
  e.currentTarget.textContent=on?'Music on':'Music off';
});
$('startPlan').addEventListener('click',()=>begin(true));
$('startEmpty').addEventListener('click',()=>begin(false));
nameIn.addEventListener('keydown',e=>{ if(e.key==='Enter') begin(true); });

