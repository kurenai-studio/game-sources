/* ══════════════ 12 · building and digging by hand ══════════════ */
let tool='cottage',ghost=null,ghostOff=0,ghostRot=0,ghostFlip=false,anchor=null,ghostOK=true;
let ghostFace=null,brush=10,sculpting=null,ghostScale=1,photo=false,camAuto=0;
const gMatOK=new T.MeshBasicMaterial({color:0x9fd6a8,transparent:true,opacity:0.42,depthWrite:false});
const gMatNo=new T.MeshBasicMaterial({color:0xd2542f,transparent:true,opacity:0.42,depthWrite:false});
const lineGhost=new T.Mesh(bgeo(1,1,1),gMatOK); lineGhost.visible=false; scene.add(lineGhost);
const ghostArrow=arrow(0,0,0,1.6); ghostArrow.visible=false; scene.add(ghostArrow);
const brushRing=new T.Mesh(new T.RingGeometry(0.93,1,48),
  new T.MeshBasicMaterial({color:0x5C8A72,transparent:true,opacity:0.85,side:T.DoubleSide,
    depthTest:false,depthWrite:false}));
brushRing.geometry.rotateX(-PI/2); brushRing.visible=false; brushRing.renderOrder=3; scene.add(brushRing);

const isSculpt=()=>!!(PIECES[tool]&&PIECES[tool].sculpt);

function makeGhost(){
  if(ghost){scene.remove(ghost); ghost=null;}
  lineGhost.visible=false; ghostArrow.visible=false; ghostFace=null;
  const def=PIECES[tool];
  if(!def||tool==='remove'||def.line||def.sculpt) return;
  const made=MAKERS[tool](0,0,ghostRot);
  if(!made) return;
  made.group.traverse(o=>{if(o.isMesh){o.material=gMatOK; o.castShadow=false; o.receiveShadow=false;}});
  ghostOff=made.group.position.y-ground(0,0);
  if(made.meta&&made.meta.face) ghostFace={dx:made.meta.face.x,dz:made.meta.face.z,a:made.meta.face.a};
  ghost=made.group; ghost.visible=false; scene.add(ghost);
}
function tintGhost(ok){
  const m=ok?gMatOK:gMatNo;
  if(ghost) ghost.traverse(o=>{if(o.isMesh)o.material=m;});
  lineGhost.material=m;
}
const ray=new T.Raycaster();
function pickGround(cx,cy){
  ray.setFromCamera(new T.Vector2((cx/innerWidth)*2-1,-(cy/innerHeight)*2+1),camera);
  const o=ray.ray.origin,d=ray.ray.direction;
  if(d.y>-0.02) return null;
  let lo=0;
  for(let i=1;i<=460;i++){
    const tt=i*1.6;
    const px=o.x+d.x*tt,py=o.y+d.y*tt,pz=o.z+d.z*tt;
    if(py-ground(px,pz)<=0){
      let a=lo,b=tt;
      for(let k=0;k<20;k++){
        const m=(a+b)/2;
        if(o.y+d.y*m-ground(o.x+d.x*m,o.z+d.z*m)>0) a=m; else b=m;
      }
      const ft=(a+b)/2;
      return {x:clamp(o.x+d.x*ft,-HALF,HALF),z:clamp(o.z+d.z*ft,-HALF,HALF)};
    }
    lo=tt;
  }
  return null;
}
function canPlace(x,z){
  const def=PIECES[tool];
  if(!def) return false;
  if(tool==='bridge') return true;
  if(def.water){
    const f={x:Math.sin(ghostRot),z:Math.cos(ghostRot)};
    return !wet(x,z)&&wet(x+f.x*8.4,z+f.z*8.4);   // stand on the bank, reach the deep
  }
  if(wet(x,z)) return false;
  if(def.r) for(let i=0;i<placed.length;i++){
    const p=placed[i],pd=PIECES[p.key];
    if(!pd||!pd.r) continue;
    if(Math.hypot(p.x-x,p.z-z)<(def.r+pd.r)*0.52) return false;
  }
  return true;
}
function updateGhost(px,py){
  if(bare||mode!=='build'){ if(ghost)ghost.visible=false; lineGhost.visible=false;
                      ghostArrow.visible=false; brushRing.visible=false; return; }
  const hit=pickGround(px,py);
  if(!hit){ if(ghost)ghost.visible=false; lineGhost.visible=false;
            ghostArrow.visible=false; brushRing.visible=false; return; }
  const def=PIECES[tool];
  if(def.sculpt){
    if(ghost)ghost.visible=false; lineGhost.visible=false; ghostArrow.visible=false;
    brushRing.visible=true; brushRing.scale.setScalar(brush);
    brushRing.position.set(hit.x,ground(hit.x,hit.z)+0.2,hit.z);
    return;
  }
  brushRing.visible=false;
  if(tool==='remove'){ if(ghost)ghost.visible=false; lineGhost.visible=false; ghostArrow.visible=false; return; }
  if(def.line){
    if(!anchor){ lineGhost.visible=false; ghostArrow.visible=false; return; }
    const len=Math.hypot(hit.x-anchor.x,hit.z-anchor.z);
    const y=Math.max(ground(anchor.x,anchor.z),ground(hit.x,hit.z));
    const mx=(anchor.x+hit.x)/2,mz=(anchor.z+hit.z)/2;
    const rot=Math.atan2(hit.x-anchor.x,hit.z-anchor.z)+PI/2;
    lineGhost.visible=len>0.6;
    lineGhost.position.set(mx,y+(tool==='wall'?3.0:0.9),mz);
    lineGhost.rotation.y=rot;
    lineGhost.scale.set(len,tool==='wall'?5.6:1.4,tool==='bridge'?4.6:(tool==='path'?3.0:1.0));
    ghostOK=len>2;
    tintGhost(ghostOK);
    if(tool==='wall'&&len>2){
      const outA=ghostFlip?rot+PI:rot;
      const ax=mx+Math.sin(outA)*3.4,az=mz+Math.cos(outA)*3.4;
      ghostArrow.visible=true; ghostArrow.scale.setScalar(1.4);
      ghostArrow.position.set(ax,ground(ax,az)+0.16,az);
      ghostArrow.rotation.y=outA;
    }else ghostArrow.visible=false;
    return;
  }
  if(!ghost) makeGhost();
  if(!ghost) return;
  ghost.visible=true;
  ghost.scale.setScalar(ghostScale);
  ghost.position.set(hit.x,ground(hit.x,hit.z)+ghostOff*ghostScale,hit.z);
  ghostOK=canPlace(hit.x,hit.z);
  tintGhost(ghostOK);
  if(ghostFace){
    const ax=hit.x+ghostFace.dx*ghostScale,az=hit.z+ghostFace.dz*ghostScale;
    ghostArrow.visible=true; ghostArrow.scale.setScalar(1.6);
    ghostArrow.position.set(ax,ground(ax,az)+0.16,az);
    ghostArrow.rotation.y=ghostFace.a;
  }else ghostArrow.visible=false;
}
function doPlace(px,py){
  const hit=pickGround(px,py);
  if(!hit) return;
  const def=PIECES[tool];
  if(def.sculpt) return;
  if(tool==='remove'){
    const r=nearestPlaced(hit.x,hit.z,7);
    if(r){ removeRec(r); indexBuild(); say('Taken away. '+placed.length+' pieces still standing.'); }
    else say('Nothing of yours within reach of that.');
    return;
  }
  if(def.line){
    if(!anchor){ anchor={x:hit.x,z:hit.z};
      say('Now click where the '+def.label.toLowerCase()+' should end.'+
          (tool==='wall'?' , or . flips the parapet side.':'')); return; }
    const rec=place(tool,0,0,0,anchor,hit,ghostFlip);
    if(rec){ pushHistory({t:'place',rec:rec}); notePlaced(tool); }
    anchor=null; lineGhost.visible=false; ghostArrow.visible=false;
    if(rec){ indexBuild(); say(def.tip||''); }
    else say('Too short to build. Try two points further apart.');
    return;
  }
  if(!canPlace(hit.x,hit.z)){
    say(PIECES[tool].water?'A jetty needs dry bank behind it and open water ahead. Turn it with , and .'
        :(wet(hit.x,hit.z)?'That ground is under water.':'Something is already standing there.'));
    return;
  }
  const rec=place(tool,hit.x,hit.z,ghostRot,null,null,false,ghostScale);
  if(rec){ pushHistory({t:'place',rec:rec}); notePlaced(tool); }
  indexBuild();
}
const history=[];
function pushHistory(h){
  history.push(h);
  let cuts=0;
  for(let i=history.length-1;i>=0;i--){
    if(history[i].t==='cut'&&++cuts>10) history.splice(i,1);
  }
  while(history.length>40) history.shift();
}
function undo(){
  const h=history.pop();
  if(!h){
    if(placed.length){ removeRec(placed[placed.length-1]); indexBuild();
                       say('Undone. '+placed.length+' pieces standing.'); }
    else say('Nothing to undo.');
    return;
  }
  if(h.t==='place'){
    removeRec(h.rec); indexBuild();
    say('Undone. '+placed.length+' pieces standing.');
  }else{
    EDIT.set(h.data); shapeTerrain(); rebuildAll(); reseatScenery(); indexBuild();
    say('That cut undone.');
  }
}
function afterSculpt(){
  rebuildAll(); reseatScenery(); indexBuild();
}

