/* ══════════════ 14 · interface ══════════════ */
const $=id=>document.getElementById(id);
const elRun=$('run'),elClock=$('clock'),elOffice=$('office'),elDoing=$('doing'),
      elSun=$('sun'),elLit=$('lit'),elDial=$('dial'),
      elN=[$('n1'),$('n2'),$('n3')],elK=[$('k1'),$('k2'),$('k3')],
      elWork=$('workbench'),elTools=$('tools'),elGroundTools=$('groundtools'),
      elSite=$('sitename'),elHint=$('hint'),elTitle=$('title'),elPerf=$('perf');
let sayHold=0, shownOffice=null, bare=false;
function setBare(v){
  bare=v;
  $('hud').classList.toggle('bare',v);
  const btn=$('bare');
  btn.textContent=v?'Show':'Hide';
  btn.title=v?'Bring the panels back (H)':'Hide the panels (H)';
  btn.setAttribute('aria-pressed',String(v));
  updateMarkers();
  if(v){
    if(ghost) ghost.visible=false;
    lineGhost.visible=false; ghostArrow.visible=false; brushRing.visible=false;
  }
}
function say(t){ if(t){ elDoing.textContent=t; sayHold=6; } }
function setName(n){
  const first=!LORE.name;
  holdName=(n||'').trim()||holdName;
  if(first||LORE.name!==holdName){ makeLore(holdName); if(tab==='chronicle') drawChronicle(); }
  elTitle.firstChild.nodeValue=holdName;
  document.title='CASTELLAN — '+holdName;
}

(function marks(){
  [[2,'Matins'],[5,'Lauds'],[6,'Prime'],[9,'Terce'],[12,'Sext'],[15,'None'],[18,'Vespers'],[21,'Compline']]
  .forEach(m=>{
    const d=document.createElement('div'); d.className='mark';
    d.style.left=(m[0]/24*100)+'%'; d.innerHTML='<b>'+m[1]+'</b>';
    elDial.appendChild(d);
  });
})();
(function buildPalette(){
  const groups={};
  Object.keys(PIECES).forEach(k=>{(groups[PIECES[k].group]=groups[PIECES[k].group]||[]).push(k);});
  Object.keys(groups).forEach(gname=>{
    const toGround=(gname==='Ground');
    const row=document.createElement('div'); row.className='group';
    const lab=document.createElement('span'); lab.className='glab';
    lab.textContent=toGround?'Brushes':gname;
    row.appendChild(lab);
    groups[gname].forEach(k=>{
      const btn=document.createElement('button');
      btn.className='tool'+(PIECES[k].warn?' warn':'')+(PIECES[k].dig?' dig':'');
      btn.type='button'; btn.dataset.k=k; btn.textContent=PIECES[k].label;
      btn.setAttribute('aria-pressed',String(k===tool));
      row.appendChild(btn);
    });
    (toGround?elGroundTools:elTools).appendChild(row);
  });
  const allTools=()=>[...document.querySelectorAll('.tool')];
  function choose(k){
    tool=k; anchor=null; ghostRot=0; ghostFlip=false;
    allTools().forEach(x=>x.setAttribute('aria-pressed',String(x.dataset.k===k)));
    brushRing.visible=false;
    makeGhost(); updateMarkers();
    say(PIECES[k].tip||('Click the ground to place a '+PIECES[k].label.toLowerCase()+'.'));
  }
  const onClick=e=>{ const btn=e.target.closest('.tool'); if(btn) choose(btn.dataset.k); };
  elTools.addEventListener('click',onClick);
  elGroundTools.addEventListener('click',onClick);
  window.__choose=choose;
})();

/* ── the two tabs ── */
let tab='build', lastPiece='cottage';
/* the arrows are a placing aid, so they show only while a piece is in hand */
function updateMarkers(){
  markers.visible=(mode==='build'&&!bare&&tab==='build'&&!isSculpt()&&tool!=='remove');
}
function setTab(t){
  tab=t;
  $('tabTerrain').hidden=(t!=='terrain');
  $('tabBuild').hidden=(t!=='build');
  $('tabHolding').hidden=(t!=='holding');
  $('tabChronicle').hidden=(t!=='chronicle');
  [...$('tabs').children].forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.t===t)));
  if(t==='terrain'){
    if(!isSculpt()) lastPiece=tool;
    window.__choose(isSculpt()?tool:'raise');
  }else if(t==='build'){
    window.__choose(isSculpt()?lastPiece:tool);
  }else if(t==='holding'){
    drawReport();
    say('What the holding has and what it is short of. It updates as you build.');
  }else{
    drawChronicle();
    say('The chronicle of '+holdName+'. It writes itself as you build.');
  }
  updateMarkers();
}
$('tabs').addEventListener('click',e=>{
  const b=e.target.closest('button'); if(b) setTab(b.dataset.t);
});

/* is this door inside the walls? cast a ray out and count crossings */
function barriers(){
  const segs=idx.walls.map(r=>({a:r.meta.a,b:r.meta.b}));
  idx.gates.forEach(r=>{                       // a gatehouse closes the gap it sits in
    const m=r.meta.mid, f=r.meta.front;
    const dx=f.x-m.x, dz=f.z-m.z, L=Math.hypot(dx,dz)||1;
    const px=-dz/L*4.4, pz=dx/L*4.4;
    segs.push({a:{x:m.x+px,z:m.z+pz},b:{x:m.x-px,z:m.z-pz}});
  });
  return segs;
}
function enclosed(p,segs){
  segs=segs||barriers();
  if(!segs.length) return false;
  let inside=0;
  [[0.317,900],[900,0.211],[-0.443,-900]].forEach(d=>{   // three rays, majority wins
    let n=0;
    const far={x:p.x+d[0],z:p.z+d[1]};
    for(let i=0;i<segs.length;i++) if(segCross(p,far,segs[i].a,segs[i].b)) n++;
    if(n%2===1) inside++;
  });
  return inside>=2;
}
function report(){
  const rows=[];
  const dwell=idx.cottages.length+idx.halls.length+idx.taverns.length+idx.keeps.length;
  const souls=dwell*2;
  const plots=allPlots().length;
  const doors=[].concat(
    idx.cottages.map(r=>r.meta.door),idx.halls.map(r=>r.meta.door),
    idx.taverns.map(r=>r.meta.door),idx.keeps.map(r=>r.meta.door));
  const push=(lab,state,txt)=>rows.push({lab:lab,state:state,txt:txt});

  if(!dwell) push('Roof','bad','Nobody lives here yet. <b>A cottage houses two.</b>');
  else push('Roof',souls>=8?'ok':'thin',
    'Room for <b>'+souls+'</b> under '+dwell+' roof'+(dwell>1?'s':'')+'.');

  if(!plots) push('Bread','bad','No ground under crop. <b>A field feeds about six.</b>');
  else{
    const fed=Math.round(plots*1.6);
    push('Bread',fed>=souls?'ok':'thin',
      'Field and orchard for about <b>'+fed+'</b> of '+souls+'.'+
      (fed<souls?' Another field would close the gap.':''));
  }
  push('Oven',idx.bakehouses.length?'ok':'thin',
    idx.bakehouses.length?'A bakehouse, so they eat at midday rather than walk home.'
      :'No bakehouse. They break at the well instead.');
  push('Store',idx.granaries.length?'ok':(plots?'thin':'ok'),
    idx.granaries.length?'A granary takes the harvest in.'
      :(plots?'Nothing to put the harvest in. <b>A granary is worth its posts.</b>':'Nothing to store yet.'));

  if(!idx.wells.length) push('Water','bad','No well. <b>Everything stops at the well at midday.</b>');
  else{
    const near=doors.filter(d=>idx.wells.some(w=>Math.hypot(w.x-d.x,w.z-d.z)<34)).length;
    push('Water',near===doors.length?'ok':'thin',
      near===doors.length?'Every door is within a fair walk of a well.'
        :'<b>'+(doors.length-near)+'</b> of '+doors.length+' doors are a long way from water.');
  }
  const segs=barriers();
  const inside=doors.filter(d=>enclosed(d,segs)).length;
  push('Walls',!idx.walls.length?'bad':(inside>=Math.ceil(doors.length*0.6)?'ok':'thin'),
    !idx.walls.length?'Open ground. <b>Nothing is enclosed.</b>'
      :(inside===doors.length?'Every dwelling stands inside the circuit.'
        :'<b>'+inside+'</b> of '+doors.length+' dwellings are inside the circuit; '+
          (doors.length-inside)+' stand out in the open.'));
  push('Watch',idx.towers.length?'ok':'thin',
    idx.towers.length?idx.towers.length+' tower'+(idx.towers.length>1?'s':'')+
      ', so '+idx.towers.length+' on the wall walk.'
      :'No towers, so no watch at all.');
  push('Gate',!idx.walls.length?'ok':(idx.gates.length?'ok':'bad'),
    !idx.walls.length?'Nothing to pass through.'
      :(idx.gates.length?'A gatehouse, and everyone routes through it.'
        :'<b>Walls with no gatehouse.</b> They will walk straight through the stone.'));
  push('Beasts',idx.pens.length?'ok':'thin',
    idx.pens.length?idx.pens.length+' pen'+(idx.pens.length>1?'s':'')+' out to the common by day.'
      :'No pens, so no flock.');
  push('Trade',idx.stalls.length?'ok':'thin',
    idx.stalls.length?idx.stalls.length+' stall'+(idx.stalls.length>1?'s':'')+' up through the day.'
      :'No stalls in the ward.');
  push('Souls',idx.chapels.length||idx.taverns.length?'ok':'thin',
    (idx.chapels.length?'A chapel, and monks to keep the hours. ':'No chapel. ')+
    (idx.taverns.length?'A tavern for the evening.':'Nowhere to go after Vespers.'));

  const score=Math.round(100*rows.reduce((s,r)=>s+(r.state==='ok'?1:(r.state==='thin'?0.45:0)),0)/rows.length);
  return {rows:rows,score:score};
}
function drawReport(){
  const r=report();
  const el=$('report');
  el.innerHTML=r.rows.map(x=>
    '<div class="rrow '+x.state+'"><span class="dot"></span>'+
    '<span class="lab">'+x.lab+'</span><span class="txt">'+x.txt+'</span></div>').join('');
  $('standing').textContent=r.score+' / 100';
}
function refreshCensus(){
  if(mode==='build'){
    elK[0].textContent='Homes'; elK[1].textContent='Works'; elK[2].textContent='Defence';
    elN[0].textContent=idx.cottages.length+idx.halls.length+idx.taverns.length+idx.keeps.length;
    elN[1].textContent=idx.fields.length+idx.orchards.length+idx.stalls.length+idx.wells.length+
                       idx.smithies.length+idx.mills.length+idx.chapels.length+idx.pens.length+
                       idx.granaries.length+idx.bakehouses.length+idx.gardens.length+
                       idx.beehives.length+idx.jetties.length+idx.dovecotes.length;
    elN[2].textContent=idx.walls.length+idx.towers.length+idx.gates.length+
                       idx.butts.length+idx.beacons.length;
  }else{
    elK[0].textContent='Souls'; elK[1].textContent='Beasts'; elK[2].textContent='Abroad';
    let souls=0,abroad=0;
    world.query([C.HUMAN,C.RENDER,C.TRANSFORM]).forEach(e=>{
      if(!world.get(e,C.RENDER).visible) return;
      souls++;
      const tr=world.get(e,C.TRANSFORM);
      if(Math.hypot(tr.x-idx.centre.x,tr.z-idx.centre.z)>30) abroad++;
    });
    souls+=world.count(C.WATCH);
    elN[0].textContent=souls;
    elN[1].textContent=world.count(C.BEAST)+world.count(C.BIRD)+world.count(C.CART);
    elN[2].textContent=abroad;
  }
}
function setSeal(){
  if(mode==='build'){
    elRun.classList.remove('running');
    elRun.innerHTML='Run<br>the day<span class="sub">Building</span>';
    elRun.setAttribute('aria-pressed','false');
  }else{
    elRun.classList.toggle('running',running);
    elRun.innerHTML=(running?'Hold<br>the day':'Run<br>the day')+
      '<span class="sub">'+(running?'Running':'Held')+'</span>';
    elRun.setAttribute('aria-pressed',String(running));
  }
}
function setMode(m){
  if(m===mode) return;
  mode=m; anchor=null; sculpting=null;
  const build=(m==='build');
  elWork.hidden=!build;
  updateMarkers();
  elSite.textContent=build?'Building':'The day of it';
  elHint.textContent=build?'Click ground to place · , . to turn or flip · Z to undo'
                          :'Drag to orbit · wheel to zoom · space to hold';
  [...$('modes').children].forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.m===m)));
  if(build){
    clearPop(); running=false; makeGhost();
    say(tab==='terrain'?'Drag with a brush to cut the ground.'
                       :'Pick something from the palette, then click the ground to place it.');
  }else{
    if(ghost)ghost.visible=false;
    lineGhost.visible=false; ghostArrow.visible=false; brushRing.visible=false;
    indexBuild(); buildPop(); world.singletons.clock.bucket=-1; retask(); running=true;
    say(world.count(C.HUMAN)?officeFor(hour)[2]
      :'Nothing here to run yet. Go back and place a cottage or two.');
  }
  setSeal(); refreshCensus();
}
$('bare').addEventListener('click',()=>{
  if(Panels.dragged('bare')){ Panels.clearDrag('bare'); return; }
  setBare(!bare);
});
$('modes').addEventListener('click',e=>{const b=e.target.closest('button'); if(b) setMode(b.dataset.m);});
elRun.addEventListener('click',()=>{
  if(Panels.dragged()){ Panels.clearDrag(); return; }   // that was a move, not a press
  if(mode==='build') setMode('run'); else { running=!running; setSeal(); }
});
$('detail').addEventListener('click',e=>{
  const b=e.target.closest('button'); if(!b) return;
  if(b.dataset.q==='auto'){ QUALITY.auto=true; applyQuality(QUALITY.detected); }
  else { QUALITY.auto=false; applyQuality(b.dataset.q); }
  [...e.currentTarget.children].forEach(x=>x.setAttribute('aria-pressed',String(x===b)));
});
$('music').addEventListener('click',e=>{
  const b=e.target.closest('button'); if(!b) return;
  const v=parseFloat(b.dataset.v);
  [...e.currentTarget.children].forEach(x=>x.setAttribute('aria-pressed',String(x===b)));
  if(v<=0){ Music.stop(); say('Music off.'); }
  else if(!Music.start(v)) say('This browser will not give me any sound.');
  else say(v<0.5?'Music, softly.':'Music on. It follows the hour and the season.');
});
$('season').addEventListener('click',e=>{
  const b=e.target.closest('button'); if(!b) return;
  season=parseInt(b.dataset.s,10);
  [...e.currentTarget.children].forEach(x=>x.setAttribute('aria-pressed',String(x===b)));
  applySeason(); Music.season(season); noteSeason();
  if(mode==='run') retask();
  say(SN().name+'. '+SN().note);
});
$('pace').addEventListener('click',e=>{
  const b=e.target.closest('button'); if(!b) return;
  pace=parseFloat(b.dataset.p);
  [...e.currentTarget.children].forEach(c=>c.setAttribute('aria-pressed',String(c===b)));
});
function regenerate(msg,keepEdits){
  if(!keepEdits) EDIT.fill(0);
  clearBuild(); shapeTerrain(); scatter(); indexBuild();
  if(mode==='run') setMode('build');
  say(msg);
}
$('newland').addEventListener('click',()=>{
  land.seed=Math.floor(Math.random()*1e9); seedNoise(land.seed);
  regenerate('New ground, and nothing on it. Everything you had built is gone.');
});
$('preset').addEventListener('click',()=>{
  if(mode==='run') setMode('build');
  preset(); say('The standard plan, laid out. Change anything you like, then run the day.');
});
$('clear').addEventListener('click',()=>{
  clearBuild(); indexBuild();
  if(mode==='run') setMode('build');
  say('Cleared. The valley is yours again.');
});
$('mount').addEventListener('click',e=>{
  land.mount=!land.mount;
  e.currentTarget.setAttribute('aria-pressed',String(land.mount));
  regenerate(land.mount?'A mount with a wet ditch round it. Bridge it to get in.'
                       :'Flat ground, no ditch. You make your own defences now.',true);
});
$('relief').addEventListener('input',e=>{
  land.relief=parseFloat(e.target.value);
  if(!placed.length){ shapeTerrain(); reseatScenery(); }
});
$('relief').addEventListener('change',()=>{
  const had=placed.length;
  regenerate(had?'The land re-cut, so what stood on it had to come down.':'The land re-cut.',true);
});
$('brush').addEventListener('input',e=>{ brush=parseFloat(e.target.value); });
$('waterlvl').addEventListener('input',e=>{
  WATER=parseFloat(e.target.value); water.position.y=WATER; shapeTerrain();
});
$('waterlvl').addEventListener('change',()=>{
  rebuildAll(); reseatScenery(); indexBuild();
  say(WATER>-1.2?'The water is high. Much of the low ground is gone.'
                :'Water level set. Anything below it is under.');
});
$('resetcuts').addEventListener('click',()=>{
  EDIT.fill(0); shapeTerrain(); rebuildAll(); reseatScenery(); indexBuild();
  say('Your cuts are undone. The ground is as it was generated.');
});
$('rename').addEventListener('click',()=>{
  if(elTitle.querySelector('#retitle')) return;
  const inp=document.createElement('input');
  inp.id='retitle'; inp.value=holdName; inp.maxLength=26;
  elTitle.firstChild.nodeValue='';
  elTitle.insertBefore(inp,elTitle.firstChild);
  inp.focus(); inp.select();
  let closed=false;
  const done=commit=>{
    if(closed) return; closed=true;
    const v=inp.value; inp.remove();
    setName(commit?v:holdName);
  };
  inp.addEventListener('keydown',e=>{
    e.stopPropagation();
    if(e.key==='Enter'){e.preventDefault(); done(true);}
    if(e.key==='Escape'){e.preventDefault(); done(false);}
  });
  inp.addEventListener('blur',()=>done(true));
});

(function dial(){
  let on=false;
  const set=e=>{
    const r=elDial.getBoundingClientRect();
    hour=clamp((e.clientX-r.left)/r.width,0,0.9999)*24;
    if(mode==='run') retask();
  };
  elDial.addEventListener('pointerdown',e=>{on=true; try{elDial.setPointerCapture(e.pointerId);}catch(x){} set(e);});
  elDial.addEventListener('pointermove',e=>{if(on)set(e);});
  elDial.addEventListener('pointerup',()=>on=false);
  elDial.addEventListener('keydown',e=>{
    if(e.key==='ArrowRight'){hour=(hour+0.5)%24; if(mode==='run')retask(); e.preventDefault();}
    if(e.key==='ArrowLeft'){hour=(hour+23.5)%24; if(mode==='run')retask(); e.preventDefault();}
  });
})();

(function bind(){
  const el=renderer.domElement;
  let drag=null; const pts=new Map(); let pinch=0;
  el.addEventListener('pointerdown',e=>{
    try{el.setPointerCapture(e.pointerId);}catch(x){}
    pts.set(e.pointerId,{x:e.clientX,y:e.clientY});
    if(mode==='build'&&!bare&&isSculpt()&&e.button===0&&!e.shiftKey&&pts.size===1){
      const hit=pickGround(e.clientX,e.clientY);
      if(hit){ sculpting={x:hit.x,z:hit.z,level:ground(hit.x,hit.z)}; drag=null; return; }
    }
    drag={x:e.clientX,y:e.clientY,pan:(e.button===1||e.button===2||e.shiftKey),moved:0,btn:e.button};
  });
  el.addEventListener('pointermove',e=>{
    if(sculpting){
      const hit=pickGround(e.clientX,e.clientY);
      if(hit){ sculpting.x=hit.x; sculpting.z=hit.z; }
      updateGhost(e.clientX,e.clientY);
      return;
    }
    if(!pts.has(e.pointerId)){ if(mode==='build') updateGhost(e.clientX,e.clientY); return; }
    pts.set(e.pointerId,{x:e.clientX,y:e.clientY});
    if(pts.size===2){
      const v=[...pts.values()],d=Math.hypot(v[0].x-v[1].x,v[0].y-v[1].y);
      if(pinch) cam.dist*=pinch/d;
      pinch=d; applyCam(); return;
    }
    if(!drag) return;
    const dx=e.clientX-drag.x,dy=e.clientY-drag.y;
    drag.x=e.clientX; drag.y=e.clientY; drag.moved+=Math.abs(dx)+Math.abs(dy);
    if(drag.pan){
      const s=cam.dist*0.0016;
      cam.tx-=(Math.cos(cam.yaw)*dx-Math.sin(cam.yaw)*dy)*s;
      cam.tz+=(Math.sin(cam.yaw)*dx+Math.cos(cam.yaw)*dy)*s;
      cam.tx=clamp(cam.tx,-HALF,HALF); cam.tz=clamp(cam.tz,-HALF,HALF);
    }else{ cam.yaw-=dx*0.005; cam.pitch+=dy*0.004; }
    applyCam();
    if(mode==='build') updateGhost(e.clientX,e.clientY);
  });
  const up=e=>{
    if(sculpting){ sculpting=null; pts.delete(e.pointerId); afterSculpt(); return; }
    const wasDrag=drag;
    pts.delete(e.pointerId); if(pts.size<2)pinch=0; if(!pts.size)drag=null;
    if(wasDrag&&wasDrag.moved<6&&wasDrag.btn===0&&mode==='build'&&!bare&&pts.size===0){
      doPlace(e.clientX,e.clientY);
      updateGhost(e.clientX,e.clientY);
    }
  };
  el.addEventListener('pointerup',up);
  el.addEventListener('pointercancel',e=>{
    if(sculpting){sculpting=null; afterSculpt();}
    pts.delete(e.pointerId); if(!pts.size)drag=null;
  });
  el.addEventListener('contextmenu',e=>e.preventDefault());
  el.addEventListener('wheel',e=>{e.preventDefault(); cam.dist*=Math.exp(e.deltaY*0.0011); applyCam();},{passive:false});
})();

let keysOpen=false;
function toggleKeys(v){
  keysOpen=(v===undefined)?!keysOpen:v;
  document.getElementById('keys').hidden=!keysOpen;
}
document.getElementById('keysclose').addEventListener('click',()=>toggleKeys(false));
document.getElementById('keys').addEventListener('click',e=>{
  if(e.target.id==='keys') toggleKeys(false);
});
const keys=Object.create(null);
function toolAt(n){
  const box=document.getElementById(tab==='terrain'?'tabTerrain':'tabBuild');
  if(!box) return;
  const list=[...box.querySelectorAll('.tool')];
  if(list[n]) list[n].click();
}
function ringBell(){
  const nxt=OFFICES.find(o=>o[0]>hour+0.02);
  hour=nxt?nxt[0]:0.0;
  if(mode==='run') retask();
  say('The bell rings for '+officeFor(hour)[1]+'.');
}
function setPhoto(v){
  photo=v; setBare(v); if(!v) camAuto=0;
  say(v?'Photo mode — the camera drifts. P or Esc to come back.':'Back to work.');
}
addEventListener('keyup',e=>{ keys[e.code]=false; });
addEventListener('blur',()=>{ for(const k in keys) keys[k]=false; });
addEventListener('keydown',e=>{
  if(e.target.tagName==='INPUT'){ if(e.key==='Escape') e.target.blur(); return; }
  keys[e.code]=true;
  const k=e.key;
  if(k==='?'){ toggleKeys(); e.preventDefault(); return; }
  if(k==='p'||k==='P'){ setPhoto(!photo); return; }
  if(k==='h'||k==='H'){ setBare(!bare); return; }
  if(k==='r'||k==='R'){ ringBell(); return; }
  if(k==='Escape'){
    if(keysOpen){ toggleKeys(false); return; }
    if(photo){ setPhoto(false); return; }
    if(anchor){ anchor=null; lineGhost.visible=false; ghostArrow.visible=false; say('Cancelled.'); return; }
    if(mode==='run'){ running=!running; setSeal(); say(running?'Running.':'Held.'); }
    return;
  }
  if(e.code==='Space'&&e.target.tagName!=='BUTTON'){
    e.preventDefault();
    if(mode==='build') setMode('run'); else { running=!running; setSeal(); }
    return;
  }
  if(k==='z'||k==='Z'){ undo(); return; }
  if(k>='0'&&k<='9'&&mode==='build'){ toolAt(k==='0'?9:(+k-1)); e.preventDefault(); return; }
  if(mode!=='build') return;
  const def=PIECES[tool];
  if(k==='['){ sizeBy(-1); return; }
  if(k===']'){ sizeBy(1); return; }
  if(k===','||k==='.'){
    if(def&&def.line){ ghostFlip=!ghostFlip; say('Parapet on the other side now.'); }
    else { ghostRot+=(k===','?-1:1)*(e.shiftKey?PI/36:PI/12); makeGhost(); }
  }
});


let hudT=0;
function hud(dt){
  hudT-=dt; if(hudT>0) return; hudT=0.12;
  const hh=Math.floor(hour),mm=Math.floor((hour-hh)*60);
  elClock.textContent=String(hh).padStart(2,'0')+':'+String(mm).padStart(2,'0');
  const o=officeFor(hour);
  sayHold-=0.12;
  elOffice.textContent=o[1];
  if(mode==='run'&&sayHold<=0&&shownOffice!==o[1]){ elDoing.textContent=o[2]; shownOffice=o[1]; }
  const p=hour/24*100;
  elSun.style.left=p+'%'; elLit.style.width=p+'%';
  elSun.classList.toggle('moon',nightF>0.55);
  elDial.setAttribute('aria-valuenow',hour.toFixed(1));
  elDial.setAttribute('aria-valuetext',elClock.textContent+', '+o[1].toLowerCase());
  refreshCensus();
  const info=renderer.info.render;
  elPerf.textContent=Math.round(fps)+' fps · '+info.calls+' calls · '+QUALITY.now.label.toLowerCase();
}



