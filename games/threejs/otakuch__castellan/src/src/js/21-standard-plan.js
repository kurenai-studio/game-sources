/* ══════════════ 13 · the standard plan ══════════════ */
function tryPlace(k,x,z,rot){ return wet(x,z)?null:place(k,x,z,rot); }
function preset(){
  clearBuild();
  const face=(x,z,tx,tz)=>Math.atan2((tx||0)-x,(tz||0)-z);   // face the middle by default
  const R=25,S=8,vert=i=>{const a=i/S*TAU-PI/S; return {x:Math.sin(a)*R,z:Math.cos(a)*R};};
  for(let i=0;i<S;i++){
    const a=vert(i),b=vert(i+1);
    if(i===0){
      place('wall',0,0,0,a,{x:-4.5,z:23.2});
      place('wall',0,0,0,{x:4.5,z:23.2},b);
    } else place('wall',0,0,0,a,b);
    tryPlace('tower',a.x,a.z,0);
  }
  tryPlace('gate',0,23.4,0);                       // arrow points out over the causeway
  place('bridge',0,0,0,{x:0,z:26},{x:0,z:39});
  place('path',0,0,0,{x:0,z:39},{x:0,z:60});
  tryPlace('keep',-5.5,-7.5,face(-5.5,-7.5,0,6));
  tryPlace('chapel',-14.5,13.5,face(-14.5,13.5,0,4));
  tryPlace('well',0.5,2.5,0);
  tryPlace('hall',9.5,-6.5,face(9.5,-6.5,0,4));
  tryPlace('smithy',12.0,5.0,face(12,5,0,4));
  tryPlace('tavern',-9.0,-1.0,face(-9,-1,0,6));
  for(let i=0;i<5;i++){
    const a=-0.95+i*0.44;
    tryPlace('stall',Math.sin(a)*14.5,Math.cos(a)*14.5,a+PI);
  }
  [[-11.5,9.0],[-2.5,11.5],[6.0,12.5],[-15.0,-3.5]].forEach(c=>
    tryPlace('cottage',c[0],c[1],face(c[0],c[1],0,2)));
  [[-26,42],[17,44],[23,38],[-16,47]].forEach(c=>
    tryPlace('cottage',c[0],c[1],face(c[0],c[1],0,30)));
  tryPlace('mill',34,-16,face(34,-16,0,0));
  tryPlace('field',40,6,0.1); tryPlace('field',42,24,0.1);
  tryPlace('orchard',-40,-22,0);
  tryPlace('pen',-28,34,face(-28,34,-46,26));      // the gap opens onto the common
  tryPlace('pen',-44,22,face(-44,22,-52,30));
  tryPlace('cross',0,45,0);
  for(let i=0;i<6;i++) tryPlace('hay',44+RG()*8-4,-2+RG()*44,0);
  indexBuild();
}

