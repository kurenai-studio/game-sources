/* ══════════════ 10 · steering ══════════════ */
function seek(tr,lo,tx,tz,dt){
  const dx=tx-tr.x,dz=tz-tr.z,d=Math.hypot(dx,dz);
  if(d<(lo.arrive||0.6)) return true;
  const want=Math.atan2(dx,dz);
  tr.rot+=clamp(angDiff(tr.rot,want),-lo.turn*dt,lo.turn*dt);
  const v=lo.speed*dt*(0.35+0.65*Math.max(0,Math.cos(angDiff(tr.rot,want))));
  const nx=tr.x+Math.sin(tr.rot)*v,nz=tr.z+Math.cos(tr.rot)*v;
  if(wet(nx,nz)&&!onBridge(nx,nz)){ tr.rot+=0.55; tr.moved=0; return false; }
  tr.x=nx; tr.z=nz; tr.moved=v;
  return false;
}
function routeTo(tr,path,tx,tz){
  path.queue.length=0; path.dest={x:tx,z:tz};
  if(idx.gates.length&&walledOff(tr.x,tr.z,tx,tz)){
    let best=null,bd=1e9;
    idx.gates.forEach(g=>{
      const m=g.meta;
      const d1=Math.hypot(tr.x-m.front.x,tr.z-m.front.z)+Math.hypot(tx-m.back.x,tz-m.back.z);
      const d2=Math.hypot(tr.x-m.back.x,tr.z-m.back.z)+Math.hypot(tx-m.front.x,tz-m.front.z);
      if(d1<bd){bd=d1;best=[m.front,m.mid,m.back];}
      if(d2<bd){bd=d2;best=[m.back,m.mid,m.front];}
    });
    if(best) best.forEach(p=>path.queue.push({x:p.x,z:p.z}));
  }
  path.queue.push({x:tx,z:tz});
}

