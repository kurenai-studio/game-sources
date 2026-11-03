/* ══════════════ 9 · bodies ══════════════ */
const blobTex=(function(){
  const c=document.createElement('canvas'); c.width=c.height=64;
  const x=c.getContext('2d');
  const g=x.createRadialGradient(32,32,2,32,32,31);
  g.addColorStop(0,'rgba(0,0,0,.42)'); g.addColorStop(1,'rgba(0,0,0,0)');
  x.fillStyle=g; x.fillRect(0,0,64,64);
  const t=new T.CanvasTexture(c); if(MODERN) t.colorSpace=T.SRGBColorSpace; return t;
})();
const blobMat=new T.MeshBasicMaterial({map:blobTex,transparent:true,depthWrite:false});
const blobGeo=new T.PlaneGeometry(1,1); blobGeo.rotateX(-PI/2); blobGeo.userData.cached=true;
const folk=new T.Group(); scene.add(folk);
const SKIN=[0xd8ab86,0xc79370,0xb07d5c,0xe0bb99];
const TUNIC=[0x7a5c3a,0x5d6b45,0x8a4b3a,0x4a5a6b,0x8c7340,0x6b4a5c,0x93783f];

function humanBody(cfg){
  const g=new T.Group();
  const tun=mat('t'+cfg.tunic,cfg.tunic),skin=mat('s'+cfg.skin,cfg.skin),hose=mat('h'+cfg.hose,cfg.hose);
  const s=cfg.scale||1;
  const legL=new T.Group(),legR=new T.Group(),armL=new T.Group(),armR=new T.Group();
  legL.add(box(0.16,0.78,0.17,hose,0,-0.39,0)); legL.scale.setScalar(s);
  legR.add(box(0.16,0.78,0.17,hose,0,-0.39,0)); legR.scale.setScalar(s);
  armL.add(box(0.13,0.62,0.14,tun,0,-0.31,0)); armL.scale.setScalar(s);
  armR.add(box(0.13,0.62,0.14,tun,0,-0.31,0)); armR.scale.setScalar(s);
  legL.position.set(-0.11*s,0.78*s,0); legR.position.set(0.11*s,0.78*s,0);
  armL.position.set(-0.26*s,1.28*s,0); armR.position.set(0.26*s,1.28*s,0);
  const body=box(0.44*s,0.66*s,0.26*s,tun,0,1.08*s,0);
  const head=box(0.26*s,0.28*s,0.25*s,skin,0,1.55*s,0);
  body.castShadow=head.castShadow=true;
  g.add(legL,legR,armL,armR,body,head,box(0.30*s,0.12*s,0.29*s,mat('hat'+cfg.hat,cfg.hat),0,1.73*s,0));
  if(cfg.cloak) g.add(box(0.50*s,0.72*s,0.10*s,mat('ck'+cfg.cloak,cfg.cloak),0,1.06*s,-0.19*s));
  const b=new T.Mesh(blobGeo,blobMat); b.scale.setScalar(0.9*s); b.position.y=0.03; g.add(b);
  folk.add(g);
  return {mesh:g,gait:{phase:rnd(0,6),rate:3.4,moving:false,legL:legL,legR:legR,armL:armL,armR:armR}};
}
function quadBody(cfg){
  const g=new T.Group();
  const bm=mat('q'+cfg.body,cfg.body),hm=mat('q'+cfg.head,cfg.head);
  const s=cfg.scale||1,legs=[];
  const bl=cfg.len,bw=cfg.wid,bh=cfg.hgt,lh=cfg.legh;
  const body=box(bw*s,bh*s,bl*s,bm,0,(lh+bh/2)*s,0); body.castShadow=true; g.add(body);
  const neck=new T.Group(); neck.position.set(0,(lh+bh*0.6)*s,bl*0.48*s); g.add(neck);
  const head=box(bw*0.62*s,bh*0.6*s,bh*0.7*s,hm,0,(cfg.headUp?0.3:0.05)*s,0.2*s);
  head.castShadow=true; neck.add(head);
  if(cfg.ears)[-1,1].forEach(d=>neck.add(box(0.07*s,0.16*s,0.05*s,hm,d*0.11*s,(cfg.headUp?0.44:0.2)*s,0.16*s)));
  if(cfg.horns)[-1,1].forEach(d=>neck.add(box(0.06*s,0.05*s,0.26*s,mat('horn',0xd8cdb0),d*0.14*s,(cfg.headUp?0.42:0.18)*s,0.1*s)));
  g.add(box(0.07*s,0.07*s,0.34*s,hm,0,(lh+bh*0.7)*s,-bl*0.55*s));
  [[-1,1],[1,1],[-1,-1],[1,-1]].forEach(p=>{
    const lg=new T.Group();
    lg.position.set(p[0]*bw*0.34*s,lh*s,p[1]*bl*0.34*s);
    lg.add(box(0.11*s,lh*s,0.11*s,hm,0,-lh*0.5*s,0));
    g.add(lg); legs.push(lg);
  });
  const b=new T.Mesh(blobGeo,blobMat); b.scale.setScalar(bl*1.15*s); b.position.y=0.03; g.add(b);
  folk.add(g);
  return {mesh:g,neck:neck,gait:{phase:rnd(0,6),rate:cfg.gaitRate||4.5,moving:false,legs:legs}};
}
function crowBody(){
  const g=new T.Group(),bm=mat('crow',0x2b2b30);
  g.add(box(0.16,0.14,0.42,bm,0,0,0));
  const wl=new T.Group(),wr=new T.Group();
  wl.position.set(-0.07,0.03,0); wr.position.set(0.07,0.03,0);
  wl.add(box(0.42,0.04,0.28,bm,-0.21,0,0)); wr.add(box(0.42,0.04,0.28,bm,0.21,0,0));
  g.add(wl,wr); folk.add(g);
  return {mesh:g,wl:wl,wr:wr};
}

function clearPop(){
  while(folk.children.length) folk.remove(folk.children[0]);
  world.clear();
  world.singletons.clock.bucket=-1;
}
function openSpot(cx,cz,r,tries){
  for(let i=0;i<(tries||40);i++){
    const a=RG()*TAU,d=r*(0.4+RG()*0.6);
    const x=cx+Math.sin(a)*d,z=cz+Math.cos(a)*d;
    if(!wet(x,z)) return {x:x,z:z};
  }
  return {x:cx,z:cz};
}
function allPlots(){
  const s=[];
  idx.fields.forEach(f=>f.meta.spots.forEach(p=>s.push(p)));
  idx.orchards.forEach(f=>f.meta.spots.forEach(p=>s.push(p)));
  return s;
}

function buildPop(){
  clearPop();
  const cap=QUALITY.now.pop;
  const doors=[];
  const addDoors=r=>{doors.push(r.meta.door); doors.push(r.meta.door);};
  idx.cottages.forEach(addDoors); idx.halls.forEach(addDoors);
  idx.taverns.forEach(addDoors);  idx.keeps.forEach(addDoors);
  if(!doors.length) return;

  const plots=allPlots();
  const jobs=[];
  const add=(role,n)=>{for(let i=0;i<n;i++) jobs.push(role);};
  add('smith',Math.min(3,idx.smithies.length));
  add('baker',Math.min(2,idx.bakehouses.length));
  add('fisher',Math.min(3,idx.jetties.length));
  add('herbwife',Math.min(2,idx.gardens.length));
  add('beekeeper',Math.min(2,idx.beehives.length));
  add('miller',Math.min(3,idx.mills.length));
  add('monk',Math.min(6,idx.chapels.length*2));
  add('market',Math.min(8,idx.stalls.length));
  add('field',Math.min(18,idx.fields.length*3+idx.orchards.length*2));
  add('shepherd',Math.min(3,idx.pens.length));
  if(idx.keeps.length){ jobs.push('lord'); add('servant',2); }
  else if(idx.halls.length) add('servant',1);
  while(jobs.length<doors.length) jobs.push(jobs.length%3===0?'child':(plots.length?'field':'child'));
  jobs.length=Math.min(jobs.length,doors.length,cap);

  jobs.forEach((role,i)=>{
    const home=doors[i%doors.length];
    const cfg={tunic:pick(TUNIC),skin:pick(SKIN),hose:pick([0x4a4030,0x5b5240,0x3c3a2e]),
               hat:pick([0x6b5436,0x4a4a52,0x8a6b3a]),
               scale:role==='child'?0.88:rnd(1.22,1.36),
               cloak:role==='monk'?0x3a352c:(role==='lord'?0x6b2a3a:0)};
    if(role==='monk') cfg.tunic=0x4a4438;
    if(role==='lord') cfg.tunic=0x6b2a3a;
    if(role==='miller') cfg.tunic=0xbdb098;
    if(role==='baker') cfg.tunic=0xcdc3ae;
    if(role==='fisher') cfg.tunic=0x4a6b6b;
    if(role==='herbwife') cfg.tunic=0x6b7a4a;
    if(role==='beekeeper') cfg.tunic=0xd8d2bf;
    const body=humanBody(cfg);
    world.spawn({
      [C.HUMAN]:{},
      [C.TRANSFORM]:{x:home.x,z:home.z,y:ground(home.x,home.z),rot:rnd(0,TAU),tilt:0},
      [C.RENDER]:{obj:body.mesh,visible:true},
      [C.GAIT]:body.gait,
      [C.LOCO]:{speed:role==='child'?3.2:rnd(2.0,2.6),turn:3.0,arrive:0.7},
      [C.PATH]:{queue:[],dest:null},
      [C.ROUTINE]:{role:role,home:{x:home.x,z:home.z},wob:rnd(0,TAU),idle:rnd(0,9),seat:i,
                   plot:plots.length?plots[i%plots.length]:null,
                   stall:idx.stalls.length?idx.stalls[i%idx.stalls.length].meta.front:null}
    });
  });

  /* the watch */
  const nGuard=Math.min(12,idx.towers.length);
  for(let i=0;i<nGuard;i++){
    const cfg={tunic:0x4a5260,skin:pick(SKIN),hose:0x3c3a2e,hat:0x8f9299,scale:1.3,cloak:0x5a2a24};
    const body=humanBody(cfg);
    body.mesh.add(box(0.12,2.0,0.12,timber,0.34,1.2,0));
    body.mesh.add(box(0.2,0.22,0.2,mat('tip',0xbfc4c9),0.34,2.25,0));
    const t=idx.towers[i];
    world.spawn({
      [C.WATCH]:{},
      [C.TRANSFORM]:{x:t.x,z:t.z,y:t.meta.top,rot:rnd(0,TAU),tilt:0},
      [C.RENDER]:{obj:body.mesh,visible:true},
      [C.GAIT]:body.gait,
      [C.SENTRY]:{mode:patrolWalls.length?'wall':'post',w:patrolWalls.length?i%patrolWalls.length:-1,
                  t:RG(),dir:RG()<0.5?1:-1,pause:0,post:{x:t.x,y:t.meta.top,z:t.z}}
    });
  }
  idx.gates.slice(0,3).forEach(r=>{
    const f=r.meta.front,m=r.meta.mid;
    const dx=f.x-m.x,dz=f.z-m.z,L=Math.hypot(dx,dz)||1;
    [-1,1].forEach(s=>{
      const cfg={tunic:0x4a5260,skin:pick(SKIN),hose:0x3c3a2e,hat:0x8f9299,scale:1.32,cloak:0x5a2a24};
      const body=humanBody(cfg);
      body.mesh.add(box(0.12,2.0,0.12,timber,0.34,1.2,0));
      body.mesh.add(box(0.2,0.22,0.2,mat('tip',0xbfc4c9),0.34,2.25,0));
      const x=m.x+dx/L*3.4+(-dz/L)*s*2.4, z=m.z+dz/L*3.4+(dx/L)*s*2.4;
      world.spawn({
        [C.WATCH]:{},
        [C.TRANSFORM]:{x:x,z:z,y:ground(x,z),rot:Math.atan2(dx,dz),tilt:0},
        [C.RENDER]:{obj:body.mesh,visible:true},
        [C.GAIT]:body.gait,
        [C.SENTRY]:{mode:'gate',rot0:Math.atan2(dx,dz)}
      });
    });
  });

  /* beasts */
  let nBeast=0;
  function spawnBeast(kind,cfg,home,rad){
    if(nBeast>=QUALITY.now.beasts) return;
    nBeast++;
    const body=quadBody(cfg);
    const s=openSpot(home.x,home.z,rad);
    world.spawn({
      [C.BEAST]:{},
      [C.TRANSFORM]:{x:s.x,z:s.z,y:ground(s.x,s.z),rot:rnd(0,TAU),tilt:0},
      [C.RENDER]:{obj:body.mesh,visible:true},
      [C.GAIT]:body.gait,
      [C.LOCO]:{speed:cfg.spd,turn:2.2,arrive:0.8},
      [C.GRAZER]:{kind:kind,home:home,neck:body.neck,wait:rnd(0,6),target:null,
        common:openSpot(home.x+(home.x-idx.centre.x)*0.6,home.z+(home.z-idx.centre.z)*0.6,12)}
    });
  }
  idx.pens.forEach((p,pi)=>{
    const c=p.meta.centre;
    for(let i=0;i<6;i++) spawnBeast('sheep',
      {body:0xe4dccb,head:0x3a352f,len:0.9,wid:0.5,hgt:0.55,legh:0.36,scale:1.3,spd:1.3,ears:1},c,3);
    for(let i=0;i<2;i++) spawnBeast('cow',
      {body:0x8a6b4a,head:0x6d5238,len:1.5,wid:0.72,hgt:0.8,legh:0.7,scale:1.2,spd:1.05,horns:1,ears:1},c,3);
    for(let i=0;i<2;i++) spawnBeast('pig',
      {body:0xc99a90,head:0xb0837a,len:0.95,wid:0.52,hgt:0.5,legh:0.28,scale:1.3,spd:1.4,ears:1},c,2.6);
    if(pi<3) spawnBeast('dog',
      {body:pick([0x8a6a44,0x4a4038,0xb8a184]),head:0x6b5238,len:0.75,wid:0.32,hgt:0.36,legh:0.36,
       scale:1.35,spd:3.2,ears:1,headUp:1},c,4);
  });
  idx.halls.forEach(r=>{
    for(let i=0;i<3;i++) spawnBeast('horse',
      {body:0x6a4a34,head:0x513728,len:1.7,wid:0.66,hgt:0.86,legh:0.95,scale:1.2,spd:1.9,headUp:1,ears:1},
      {x:r.x,z:r.z},7);
  });
  idx.cottages.slice(0,6).forEach(r=>{
    for(let i=0;i<2;i++) spawnBeast('hen',
      {body:pick([0xd8cdb4,0x9a5f3a,0x2f2b28]),head:0xb03a24,len:0.3,wid:0.2,hgt:0.24,legh:0.16,
       scale:1.7,spd:1.7,gaitRate:11},r.meta.door,4);
  });

  /* off-duty archers at the marks */
  idx.butts.forEach(bt=>{
    for(let i=0;i<2;i++){
      const cfg={tunic:0x5a6b4a,skin:pick(SKIN),hose:0x3c3a2e,hat:0x6b5436,scale:1.28,cloak:0};
      const body=humanBody(cfg);
      body.mesh.add(box(0.1,1.7,0.1,timber,-0.36,1.15,0.1));
      const px=bt.meta.mark.x+(i?1.4:-1.4), pz=bt.meta.mark.z;
      world.spawn({
        [C.WATCH]:{},
        [C.TRANSFORM]:{x:px,z:pz,y:ground(px,pz),rot:bt.meta.aim,tilt:0},
        [C.RENDER]:{obj:body.mesh,visible:true},
        [C.GAIT]:body.gait,
        [C.SENTRY]:{mode:'butts',rot0:bt.meta.aim,off:i*1.7}
      });
    }
  });

  /* doves keep to their own cote */
  idx.dovecotes.forEach(d=>{
    for(let i=0;i<7;i++){
      const body=crowBody();
      body.mesh.traverse(o=>{ if(o.isMesh) o.material=mat('dove',0xe6e2da); });
      body.mesh.scale.setScalar(0.7);
      world.spawn({
        [C.BIRD]:{},
        [C.RENDER]:{obj:body.mesh,visible:true},
        [C.FLYER]:{a:rnd(0,TAU),r:rnd(4,9),h:d.meta.perch.y+rnd(0.5,4),spd:rnd(0.5,0.85),
          cx:d.x,cz:d.z,flap:rnd(0,6),wl:body.wl,wr:body.wr,
          roostY:d.meta.perch.y-0.4,roostR:1.9}
      });
    }
  });

  /* crows */
  const roost=idx.keeps[0]||idx.towers[0]||idx.mills[0]||null;
  if(roost){
    const n=Math.min(QUALITY.now.birds,idx.keeps.length?12:6);
    for(let i=0;i<n;i++){
      const body=crowBody();
      world.spawn({
        [C.BIRD]:{},
        [C.RENDER]:{obj:body.mesh,visible:true},
        [C.FLYER]:{a:rnd(0,TAU),r:rnd(11,26),h:ground(roost.x,roost.z)+rnd(21,32),
          spd:rnd(0.22,0.4),cx:roost.x,cz:roost.z,flap:rnd(0,6),wl:body.wl,wr:body.wr,
          roostY:ground(roost.x,roost.z)+(idx.keeps.length?19.4:12.2)}
      });
    }
  }

  /* the cart */
  if(idx.gates.length&&plots.length){
    const g=new T.Group(); folk.add(g);
    g.add(box(1.5,0.6,2.6,timber,0,1.0,0));
    for(let k=0;k<4;k++) g.add(box(1.4,0.5,0.16,thatch,0,1.5,-1.0+k*0.7));
    const wheels=[];
    [-0.82,0.82].forEach(x=>{
      const w=cyl(0.62,0.62,0.14,12,timber,x,0.62,-0.7); w.rotation.z=PI/2; g.add(w); wheels.push(w);
    });
    g.add(box(0.14,0.14,2.4,timber,0,1.0,2.0));
    const ox=quadBody({body:0x6b5a44,head:0x53442f,len:1.7,wid:0.8,hgt:0.9,legh:0.78,scale:1,spd:1,horns:1});
    folk.remove(ox.mesh); g.add(ox.mesh); ox.mesh.position.set(0,0,3.4);
    const gate=idx.gates[0].meta;
    const away={x:gate.front.x+(gate.front.x-gate.mid.x)*5,z:gate.front.z+(gate.front.z-gate.mid.z)*5};
    world.spawn({
      [C.TRANSFORM]:{x:gate.front.x,z:gate.front.z,y:0,rot:0,tilt:0},
      [C.RENDER]:{obj:g,visible:true},
      [C.GAIT]:ox.gait,
      [C.LOCO]:{speed:1.6,turn:1.3,arrive:1.6},
      [C.PATH]:{queue:[],dest:null},
      [C.CART]:{wheels:wheels,stops:[away,gate.back,gate.front],leg:0}
    });
  }
  refreshCensus();
}

