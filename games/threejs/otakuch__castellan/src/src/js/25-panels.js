/* ══════════════ 18 · movable panels ══════════════
   Every panel is lifted out of the flex layout at boot, at exactly the place
   the layout put it, and from then on it can be dragged, folded or put away.  */
const Panels=(function(){
  const LIST=[
    {id:'p-name',    label:'Name'},
    {id:'census',    label:'Census'},
    {id:'workbench', label:'Tools'},
    {id:'band',      label:'Time'},
    {id:'p-ctrl',    label:'Controls'},
    {id:'run',       label:'Seal', bare:true},
    {id:'bare',      label:'Hide', bare:true, noChip:true}
  ];
  let ready=false;
  const el=p=>document.getElementById(p.id);

  function header(p){
    const h=document.createElement('div');
    h.className='phead';
    h.innerHTML='<span class="grip"></span><span class="ptitle">'+p.label+'</span>';
    const fold=document.createElement('button');
    fold.type='button'; fold.textContent='–'; fold.title='Fold this panel';
    fold.addEventListener('click',e=>{ e.stopPropagation(); collapse(p); });
    const shut=document.createElement('button');
    shut.type='button'; shut.textContent='×'; shut.title='Put this panel away';
    shut.addEventListener('click',e=>{ e.stopPropagation(); show(p,false); });
    h.appendChild(fold); h.appendChild(shut);
    p.node.insertBefore(h,p.node.firstChild);
    p.head=h;
    return h;
  }
  function anchorOf(p){
    const n=p.node, r=n.getBoundingClientRect();
    p.ax=(r.left+r.width/2)<innerWidth/2?'l':'r';
    p.ay=(r.top+r.height/2)<innerHeight/2?'t':'b';
    p.ox=p.ax==='l'?r.left:innerWidth-r.right;
    p.oy=p.ay==='t'?r.top:innerHeight-r.bottom;
  }
  function reanchor(p){
    const n=p.node, r=n.getBoundingClientRect();
    n.style.left=(p.ax==='l'?p.ox:innerWidth-p.ox-r.width)+'px';
    n.style.top =(p.ay==='t'?p.oy:innerHeight-p.oy-r.height)+'px';
    clampInto(p);
  }
  /* keep a panel whole on screen where it fits, and at least reachable where it does not */
  function clampInto(p){
    const n=p.node, r=n.getBoundingClientRect();
    const x=r.width<=innerWidth?clamp(r.left,0,innerWidth-r.width)
                               :clamp(r.left,innerWidth-r.width,0);
    const y=r.height<=innerHeight?clamp(r.top,0,innerHeight-r.height)
                                 :clamp(r.top,innerHeight-r.height,0);
    n.style.left=x+'px'; n.style.top=y+'px';
  }
  function drag(p,handle){
    let sx=0,sy=0,ox=0,oy=0,moved=0,on=false;
    handle.addEventListener('pointerdown',e=>{
      if(e.button!==0||e.target.closest('.phead button')) return;
      on=true; moved=0;
      const r=p.node.getBoundingClientRect();
      sx=e.clientX; sy=e.clientY; ox=r.left; oy=r.top;
      try{handle.setPointerCapture(e.pointerId);}catch(x){}
      e.preventDefault(); e.stopPropagation();
    });
    handle.addEventListener('pointermove',e=>{
      if(!on) return;
      const dx=e.clientX-sx, dy=e.clientY-sy;
      moved+=Math.abs(dx)+Math.abs(dy);
      p.node.style.left=(ox+dx)+'px';
      p.node.style.top=(oy+dy)+'px';
      p.moved=moved;
      e.stopPropagation();
    });
    const up=e=>{
      if(!on) return;
      on=false; clampInto(p); anchorOf(p);
      if(moved>6) e.stopPropagation();
    };
    handle.addEventListener('pointerup',up);
    handle.addEventListener('pointercancel',up);
  }
  function collapse(p,force){
    const on=force===undefined?!p.node.classList.contains('collapsed'):force;
    p.node.classList.toggle('collapsed',on);
    if(p.head) p.head.querySelector('button').textContent=on?'+':'–';
    clampInto(p);
  }
  function show(p,on){
    p.node.classList.toggle('gone',!on);
    const chip=document.querySelector('#dock button[data-p="'+p.id+'"]');
    if(chip) chip.setAttribute('aria-pressed',String(on));
    if(on) clampInto(p);
  }
  function buildDock(){
    const d=document.getElementById('dock');
    d.innerHTML='';
    LIST.forEach(p=>{
      if(!p.node||p.noChip) return;
      const b=document.createElement('button');
      b.type='button'; b.dataset.p=p.id; b.textContent=p.label;
      b.setAttribute('aria-pressed','true');
      b.title='Show or hide the '+p.label.toLowerCase()+' panel';
      d.appendChild(b);
    });
    const q=document.createElement('button');
    q.type='button'; q.textContent='Keys'; q.title='The full list of controls (?)';
    q.addEventListener('click',ev=>{ ev.stopPropagation(); toggleKeys(true); });
    d.appendChild(q);
    const r=document.createElement('button');
    r.type='button'; r.className='reset'; r.textContent='Reset';
    r.title='Put every panel back where it started';
    d.appendChild(r);
    d.addEventListener('click',e=>{
      const b=e.target.closest('button'); if(!b) return;
      if(b.className==='reset'){ reset(); return; }
      const p=LIST.find(x=>x.id===b.dataset.p);
      if(p) show(p,b.getAttribute('aria-pressed')!=='true');
    });
    d.hidden=false;
  }
  function reset(){
    LIST.forEach(p=>{
      if(!p.node) return;
      p.node.style.left=p.home.left+'px';
      p.node.style.top=p.home.top+'px';
      if(p.home.width) p.node.style.width=p.home.width+'px';
      collapse(p,false); show(p,true); anchorOf(p);
    });
    say('Panels put back.');
  }
  function init(){
    if(ready) return;
    /* measure everything before anything leaves the flow */
    LIST.forEach(p=>{
      const n=el(p); if(!n) return;
      p.node=n;
      const r=n.getBoundingClientRect();
      p.home={left:r.left,top:r.top,width:p.id==='band'?r.width:0};
    });
    LIST.forEach(p=>{
      if(!p.node) return;
      if(p.home.width) p.node.style.width=p.home.width+'px';
      p.node.style.left=p.home.left+'px';
      p.node.style.top=p.home.top+'px';
      p.node.classList.add('floating');
      drag(p, p.bare?p.node:header(p));
    });
    LIST.forEach(p=>{ if(p.node){ clampInto(p); const r=p.node.getBoundingClientRect();
      p.home.left=r.left; p.home.top=r.top; anchorOf(p); } });
    buildDock();
    /* a phone has no room for all of it at once — start tidy, the dock brings it back */
    if(innerWidth<640){
      ['p-name','census'].forEach(id=>{
        const p=LIST.find(x=>x.id===id); if(p&&p.node) show(p,false);
      });
      const c=LIST.find(x=>x.id==='p-ctrl'); if(c&&c.node) collapse(c,true);
    }
    ready=true;
  }
  addEventListener('resize',()=>{ if(ready) LIST.forEach(p=>{ if(p.node) reanchor(p); }); });
  return {init:init, reset:reset, ready:()=>ready,
          dragged:id=>{const p=LIST.find(x=>x.id===(id||'run')); return !!(p&&p.moved>6);},
          clearDrag:id=>{const p=LIST.find(x=>x.id===(id||'run')); if(p) p.moved=0;}};
})();


