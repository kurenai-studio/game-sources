/* ══════════════ 6 · scenery ══════════════ */
const scenery=new T.Group(); scene.add(scenery);
let sceneryData=null;
/* a wood, not a sprinkle: candidates are accepted against the density field,
   so the trees clump into stands and leave clearings between them */
function scatter(){
  while(scenery.children.length){
    const c=scenery.children[0]; scenery.remove(c); disposeTree(c);
  }
  const want=QUALITY.now.scenery;
  const conif=[],broad=[],rocks=[];
  let tries=0;
  while(conif.length+broad.length<want&&tries<want*30){
    tries++;
    const a=RG()*TAU, d=Math.sqrt(RG())*HALF;
    const x=Math.sin(a)*d, z=Math.cos(a)*d;
    const f=forestAt(x,z);
    if(f<0.03||RG()>f) continue;
    if(wet(x,z)) continue;
    (RG()<0.62?conif:broad).push({x:x,z:z,s:0.8+RG()*0.95});
  }
  for(let i=0;i<want*0.22;i++){
    const a=RG()*TAU, d=Math.sqrt(RG())*HALF;
    const x=Math.sin(a)*d, z=Math.cos(a)*d;
    if(wet(x,z)) continue;
    rocks.push({x:x,z:z,s:0.35+RG()*1.1,rx:RG()*3,ry:RG()*3,rz:RG()*3});
  }
  sceneryData={conif:conif,broad:broad,rocks:rocks};
  rebuildScenery();
}
/* seven draw calls for the whole forest */
function rebuildScenery(){
  if(!sceneryData) return;
  while(scenery.children.length){
    const c=scenery.children[0]; scenery.remove(c); disposeTree(c);
  }
  const dry=o=>!wet(o.x,o.z);
  const C=sceneryData.conif.filter(dry), B=sceneryData.broad.filter(dry),
        R=sceneryData.rocks.filter(dry);
  const at=(o,y)=>({x:o.x,y:ground(o.x,o.z)+y*o.s,z:o.z,s:o.s});
  if(C.length){
    scenery.add(instanced(cgeo(0.22,0.36,2.4,6),trunkM,C.map(o=>at(o,1.2))));
    [0,1,2].forEach(k=>scenery.add(instanced(kgeo(1.8-k*0.36,2.3,7),k%2?leafB:leafA,
      C.map(o=>at(o,2.4+k*1.1)))));
  }
  if(B.length){
    scenery.add(instanced(cgeo(0.26,0.42,3.0,6),trunkM,B.map(o=>at(o,1.5))));
    scenery.add(instanced(igeo(1.75,0),leafC,B.map(o=>({x:o.x,y:ground(o.x,o.z)+3.5*o.s,z:o.z,
      s:o.s,ry:o.s*3.1}))));
    scenery.add(instanced(igeo(1.2,0),leafB,B.map(o=>({x:o.x,y:ground(o.x,o.z)+4.9*o.s,z:o.z,
      s:o.s,ry:o.s*1.7}))));
  }
  if(R.length) scenery.add(instanced(igeo(1,0),mat('rock',0x7c7768),
    R.map(o=>({x:o.x,y:ground(o.x,o.z)+o.s*0.4,z:o.z,s:o.s,rx:o.rx,ry:o.ry,rz:o.rz}))));
}
function reseatScenery(){ rebuildScenery(); }

