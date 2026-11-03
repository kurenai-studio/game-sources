/* ══════════════ 7 · reading the build ══════════════ */
const idx={cottages:[],halls:[],taverns:[],keeps:[],chapels:[],smithies:[],mills:[],stalls:[],
           wells:[],fields:[],orchards:[],pens:[],towers:[],gates:[],walls:[],bridges:[],
           granaries:[],bakehouses:[],dovecotes:[],beehives:[],jetties:[],butts:[],gardens:[],beacons:[],
           smoke:[],torch:[],banners:[],sails:[],forge:null,centre:{x:0,z:0}};
const fires=new T.Group(); scene.add(fires);
const mkTorch=()=>new T.PointLight(0xffa64d,0,20,MODERN?1.5:1);   // decay defaults to 2 in r155+
const torchLights=[mkTorch(),mkTorch(),mkTorch()];
torchLights.forEach(l=>scene.add(l));
const forgeLight=new T.PointLight(0xff7a2a,0,16,MODERN?1.5:1); scene.add(forgeLight);

function indexBuild(){
  for(const k in idx) if(Array.isArray(idx[k])) idx[k].length=0;
  idx.forge=null;
  while(markers.children.length) markers.remove(markers.children[0]);
  placed.forEach(r=>{
    const m=r.meta;
    switch(r.key){
      case 'cottage':idx.cottages.push(r); idx.smoke.push(m.smoke); break;
      case 'hall':   idx.halls.push(r);    idx.smoke.push(m.smoke); break;
      case 'tavern': idx.taverns.push(r);  idx.smoke.push(m.smoke); break;
      case 'keep':   idx.keeps.push(r);    idx.smoke.push(m.smoke); idx.torch.push(m.torch);
                     idx.banners.push(m.banner); break;
      case 'chapel': idx.chapels.push(r); break;
      case 'smithy': idx.smithies.push(r); idx.smoke.push(m.smoke);
                     if(!idx.forge) idx.forge=m.forge; break;
      case 'mill':   idx.mills.push(r); idx.sails.push(m.sails); break;
      case 'stall':  idx.stalls.push(r); break;
      case 'well':   idx.wells.push(r); break;
      case 'field':  idx.fields.push(r); break;
      case 'orchard':idx.orchards.push(r); break;
      case 'pen':    idx.pens.push(r); break;
      case 'tower':  idx.towers.push(r); idx.torch.push(m.torch); break;
      case 'gate':   idx.gates.push(r); idx.torch.push(m.torch); break;
      case 'wall':   idx.walls.push(r); break;
      case 'bridge': idx.bridges.push(r); break;
      case 'granary':  idx.granaries.push(r); break;
      case 'bakehouse':idx.bakehouses.push(r); idx.smoke.push(m.smoke); idx.torch.push(m.forge); break;
      case 'dovecote': idx.dovecotes.push(r); break;
      case 'beehive':  idx.beehives.push(r); break;
      case 'jetty':    idx.jetties.push(r); break;
      case 'butts':    idx.butts.push(r); break;
      case 'garden':   idx.gardens.push(r); break;
      case 'beacon':   idx.beacons.push(r); idx.torch.unshift(m.torch); break;
    }
    if(m&&m.face) markers.add(arrow(m.face.x,m.face.z,m.face.a,
                                    r.key==='wall'?1.25:1.6, r.key==='wall'));
  });
  let cx=0,cz=0,n=0;
  placed.forEach(r=>{ if(r.key!=='tree'&&r.key!=='hay'&&r.key!=='bush'){cx+=r.x; cz+=r.z; n++;} });
  idx.centre={x:n?cx/n:0,z:n?cz/n:0};

  while(fires.children.length) fires.remove(fires.children[0]);
  idx.torch.forEach(p=>{
    const f=new T.Mesh(new T.SphereGeometry(0.26,7,6),flameM);
    f.position.copy(p); fires.add(f);
  });
  torchLights.forEach((l,i)=>{
    if(idx.torch[i]) l.position.copy(idx.torch[i]);
    l.userData.on=!!idx.torch[i];
  });
  if(idx.forge) forgeLight.position.copy(idx.forge);
  buildPatrol();
  updateMarkers();
  refreshCensus();
  if(tab==='holding') drawReport();
}

let patrolNodes=[],patrolWalls=[];
function buildPatrol(){
  patrolNodes=[]; patrolWalls=[];
  const nodeAt=p=>{
    for(let i=0;i<patrolNodes.length;i++)
      if(Math.hypot(patrolNodes[i].x-p.x,patrolNodes[i].z-p.z)<4) return i;
    patrolNodes.push({x:p.x,z:p.z,links:[]}); return patrolNodes.length-1;
  };
  idx.walls.forEach(r=>{
    const i=nodeAt(r.meta.a),j=nodeAt(r.meta.b);
    if(i===j) return;
    patrolWalls.push({a:r.meta.a,b:r.meta.b,y:r.meta.topY,n1:i,n2:j,
      len:Math.hypot(r.meta.b.x-r.meta.a.x,r.meta.b.z-r.meta.a.z)});
    patrolNodes[i].links.push(patrolWalls.length-1);
    patrolNodes[j].links.push(patrolWalls.length-1);
  });
}
function segCross(p1,p2,p3,p4){
  const d=(p2.x-p1.x)*(p4.z-p3.z)-(p2.z-p1.z)*(p4.x-p3.x);
  if(Math.abs(d)<1e-9) return false;
  const t=((p3.x-p1.x)*(p4.z-p3.z)-(p3.z-p1.z)*(p4.x-p3.x))/d;
  const u=((p3.x-p1.x)*(p2.z-p1.z)-(p3.z-p1.z)*(p2.x-p1.x))/d;
  return t>0.02&&t<0.98&&u>0&&u<1;
}
function walledOff(ax,az,bx,bz){
  const p1={x:ax,z:az},p2={x:bx,z:bz};
  for(let i=0;i<idx.walls.length;i++){
    const w=idx.walls[i].meta;
    if(segCross(p1,p2,w.a,w.b)) return true;
  }
  return false;
}
function onBridge(x,z){
  for(let i=0;i<idx.bridges.length;i++){
    const b=idx.bridges[i].meta;
    if(distToSeg(x,z,b.a,b.b)<2.4) return true;
  }
  return false;
}


let hour=9.0, running=false, pace=1, mode='build', perf=0, nightF=0, holdName='Aubemont';
const HOURS_PER_SEC=0.1;
let season=1;
const SEASONS=[
 {name:'Spring', dawn:5.6,dusk:19.2,grass:0x6f9048,dry:0x8fa055,leafA:0x4b7a38,leafB:0x5f8f3c,
  orchard:0x93b06a,soil:0x6d5a37,crop:0x7fa04a,snow:0,
  note:'Ground broken and sown. The bees are out and the days are lengthening.'},
 {name:'Summer', dawn:4.6,dusk:20.4,grass:0x6d8a45,dry:0x96984f,leafA:0x3d6a33,leafB:0x517a35,
  orchard:0x5f8a3c,soil:0x6d5a37,crop:0x8b9448,snow:0,
  note:'Long light. Everything that can be out of doors is out of doors.'},
 {name:'Harvest',dawn:6.2,dusk:18.4,grass:0x87904a,dry:0xa89a52,leafA:0x5a6b30,leafB:0x7a7434,
  orchard:0xb0862f,soil:0x6a5734,crop:0xc0a049,snow:0,
  note:'No midday break until it is in. The field hands run the granary all afternoon.'},
 {name:'Winter', dawn:7.8,dusk:16.4,grass:0x7d8474,dry:0x8d9184,leafA:0x3a5236,leafB:0x44603a,
  orchard:0x6b5f4a,soil:0x6f6a5e,crop:0x8a8676,snow:0.78,
  note:'Short light, stock kept in, and nobody outside who does not have to be.'}
];
const SN=()=>SEASONS[season];
/* the routines keep their shape; the working day is stretched or squeezed to fit the light */
function workHour(h){
  const s=SN();
  return 6+(h-s.dawn)*(13.6/(s.dusk-s.dawn));
}
function applySeason(){
  const s=SN();
  cGrass.setHex(s.grass); cDry.setHex(s.dry);
  SNOW=s.snow;
  leafA.color.setHex(s.leafA); leafB.color.setHex(s.leafB); leafC.color.setHex(s.orchard);
  soilM.color.setHex(s.soil); cropM.color.setHex(s.crop);
  shapeTerrain();
}

