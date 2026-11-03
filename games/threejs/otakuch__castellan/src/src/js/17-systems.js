/* ══════════════ 11 · the systems ══════════════ */
const OFFICES=[
  [0.0,'Deep night','Nothing moves but the watch and a dog that will not settle.'],
  [4.4,'Lauds','Hearths are raked open. The first smoke goes up over the ward.'],
  [6.0,'Prime','The gate opens and the field hands go out to the strips.'],
  [8.6,'Terce','Stalls are up in the ward; the flock is out on the common.'],
  [11.8,'Sext','Work stops at the well. The smith keeps hammering regardless.'],
  [13.4,'None','Back to the strips. A cart works the road.'],
  [17.0,'Vespers','Flocks come in, and the field folk head for the tavern.'],
  [19.6,'Compline','Doors shut. Torches lit along the wall walk.'],
  [21.4,'Night','Only the watch is abroad now, and the crows on the keep.']
];
const officeFor=h=>{let o=OFFICES[0]; for(const e of OFFICES) if(h>=e[0]) o=e; return o;};
const first=a=>a.length?a[0]:null;
const wellSpot=()=>{const w=first(idx.wells); return w?w.meta.spot:null;};
const chapelDoor=()=>{const c=first(idx.chapels); return c?c.meta.door:null;};
const keepDoor=()=>{const k=first(idx.keeps); return k?k.meta.door:null;};
const tavernDoor=()=>{const t=first(idx.taverns); return t?t.meta.door:null;};
const millDoor=()=>{const m=first(idx.mills); return m?m.meta.door:null;};
const anvil=()=>{const s=first(idx.smithies); return s?s.meta.anvil:null;};
const ovenAt=()=>{const b=first(idx.bakehouses); return b?b.meta.oven:null;};
const breadAt=()=>{const b=first(idx.bakehouses); return b?b.meta.door:null;};
const jettyAt=i=>{const j=idx.jetties[i%Math.max(1,idx.jetties.length)]; return j?j.meta.stand:null;};
const gardenAt=()=>{const g=first(idx.gardens); return g?g.meta.tend:null;};
const hiveAt=()=>{const h=first(idx.beehives); return h?h.meta.tend:null;};
const granaryAt=()=>{const g=first(idx.granaries); return g?g.meta.door:null;};
const penCentre=()=>{const p=first(idx.pens); return p?p.meta.centre:null;};
function aSheep(){
  const list=world.query([C.GRAZER,C.TRANSFORM]);
  for(const e of list){ if(world.get(e,C.GRAZER).kind==='sheep') return world.get(e,C.TRANSFORM); }
  return null;
}
function destination(r,h){
  const home=r.home;
  const ox=Math.sin(r.wob*3.1)*3.0,oz=Math.cos(r.wob*2.3)*3.0;
  const near=(p,k)=>p?{x:p.x+ox*(k||1),z:p.z+oz*(k||1)}:home;
  const or=(p,f)=>p||f||home;
  const evening=()=>near(or(tavernDoor(),wellSpot()));
  switch(r.role){
    case 'field':
      if(h<6.4||h>=20.4) return home;
      if(h<11.8) return or(r.plot);
      if(season===2) return h<16.0?or(r.plot):or(granaryAt(),r.plot);   // harvest: no break
      if(h<13.2) return or(breadAt(),wellSpot());   // bread at midday if anyone bakes
      if(h<17.4) return or(r.plot);
      if(h<19.6) return evening();
      return home;
    case 'market':
      if(h<7.4||h>=20.0) return home;
      if(h<18.4) return or(r.stall);
      return evening();
    case 'smith':
      if(h<5.8||h>=20.6) return home;
      if(h<19.0) return or(anvil());
      return evening();
    case 'miller':
      if(h<6.2||h>=20.0) return home;
      if(h<18.6) return or(millDoor());
      return evening();
    case 'baker':
      if(h<4.2||h>=19.0) return home;
      if(h<17.4) return or(ovenAt());
      return evening();
    case 'fisher':
      if(h<5.4||h>=19.4) return home;
      if(h<17.2) return or(jettyAt(r.seat||0));
      return evening();
    case 'herbwife':
      if(h<7.0||h>=19.4) return home;
      if(h<12.0) return or(gardenAt());
      if(h<13.0) return or(wellSpot(),gardenAt());
      if(h<17.8) return or(gardenAt());
      return evening();
    case 'beekeeper':
      if(season===3||h<7.6||h>=19.0) return home;
      if(h<17.0) return or(hiveAt(),gardenAt());
      return evening();
    case 'shepherd':
      if(h<6.4||h>=20.0) return home;
      if(h<17.6){const s=aSheep(); return s?{x:s.x+2,z:s.z+2}:or(penCentre());}
      if(h<19.2) return or(penCentre());
      return home;
    case 'monk':
      if(h<2.0||h>=21.0) return home;
      if(h<3.2) return or(chapelDoor());
      if(h<5.6) return home;
      if(h<7.0) return or(chapelDoor());
      if(h<8.8) return near(or(chapelDoor()));
      if(h<9.8) return or(chapelDoor());
      if(h<11.6) return near(or(chapelDoor()),1.3);
      if(h<12.6) return or(chapelDoor());
      if(h<17.4) return near(or(chapelDoor()));
      return or(chapelDoor());
    case 'servant':
      if(h<5.6||h>=21.0) return home;
      if(h<7.0) return or(wellSpot());
      if(h<9.0) return or(keepDoor());
      if(h<11.0) return or(r.stall,wellSpot());
      if(h<12.6) return or(wellSpot());
      if(h<15.0) return or(keepDoor());
      if(h<17.0) return or(r.stall,wellSpot());
      if(h<19.4) return or(wellSpot());
      return home;
    case 'child':
      if(h<7.4||h>=19.8) return home;
      if(h<9.0) return near(or(wellSpot(),home),1.4);
      if(h<12.0) return {x:idx.centre.x+ox*3.2,z:idx.centre.z+oz*3.2};
      if(h<13.0) return or(wellSpot());
      if(h<18.0) return {x:idx.centre.x-ox*3.0,z:idx.centre.z-oz*3.0};
      return home;
    case 'lord':
      if(h<7.0||h>=21.6) return home;
      if(h<8.4) return or(chapelDoor(),keepDoor());
      if(h<11.6) return or(keepDoor());
      if(h<13.0) return or(r.stall,keepDoor());
      if(h<16.0) return or(keepDoor());
      if(h<18.0){const g=first(idx.gates); return g?g.meta.front:home;}
      return or(chapelDoor(),keepDoor());
  }
  return home;
}
function atHome(role,h){
  switch(role){
    case 'field':return h<6.4||h>=20.6;
    case 'market':return h<7.4||h>=20.2;
    case 'smith':return h<5.8||h>=20.8;
    case 'miller':return h<6.2||h>=20.2;
    case 'baker':return h<4.2||h>=19.2;
    case 'fisher':return h<5.4||h>=19.6;
    case 'herbwife':return h<7.0||h>=19.6;
    case 'beekeeper':return season===3||h<7.6||h>=19.2;
    case 'shepherd':return h<6.4||h>=20.2;
    case 'monk':return (h>=3.6&&h<5.6)||h>=21.2;
    case 'servant':return h<5.6||h>=21.2;
    case 'child':return h<7.4||h>=20.0;
    case 'lord':return h<7.0||h>=21.8;
  }
  return false;
}

class ClockSystem extends System{
  get always(){return true;}
  update(dt){
    const c=this.world.singletons.clock;
    if(!c.running) return;
    const before=c.hour;
    c.hour=(c.hour+dt*c.pace*HOURS_PER_SEC)%24;
    if(c.hour<before) noteDay();
    const b=Math.floor(c.hour*4);
    if(b!==c.bucket){ c.bucket=b; c.retask=true; }
  }
}
class RoutineSystem extends System{
  constructor(w){ super(w,[C.ROUTINE,C.TRANSFORM,C.PATH,C.RENDER]); }
  update(dt){
    const c=this.world.singletons.clock, h=workHour(c.hour);
    const force=c.retask; c.retask=false;
    this.entities().forEach(e=>{
      const r=this.world.get(e,C.ROUTINE),tr=this.world.get(e,C.TRANSFORM),
            p=this.world.get(e,C.PATH),rd=this.world.get(e,C.RENDER);
      const indoors=atHome(r.role,h);
      rd.visible=!indoors;
      if(indoors){ p.queue.length=0; return; }
      if(force||!p.dest){
        const d=destination(r,h);
        if(!p.dest||Math.hypot(p.dest.x-d.x,p.dest.z-d.z)>1.4) routeTo(tr,p,d.x,d.z);
      }
      if(!p.queue.length){
        r.idle-=dt;
        if(r.idle<0){
          r.idle=rnd(2.5,8);
          const d=p.dest||r.home;
          routeTo(tr,p,d.x+rnd(-2.2,2.2),d.z+rnd(-2.2,2.2));
        }
      }
    });
  }
}
class PathSystem extends System{
  constructor(w){ super(w,[C.PATH,C.TRANSFORM,C.LOCO,C.GAIT]); }
  update(dt){
    this.entities().forEach(e=>{
      const p=this.world.get(e,C.PATH),tr=this.world.get(e,C.TRANSFORM),
            lo=this.world.get(e,C.LOCO),g=this.world.get(e,C.GAIT);
      tr.moved=0;
      let guard=0;
      while(p.queue.length&&guard++<4){
        const w=p.queue[0];
        const near=p.queue.length>1?1.5:(lo.arrive||0.6);
        if(Math.hypot(w.x-tr.x,w.z-tr.z)<near){ p.queue.shift(); continue; }
        seek(tr,lo,w.x,w.z,dt);
        break;
      }
      g.moving=tr.moved>0.0001;
      if(g.moving) g.phase+=tr.moved*g.rate;
    });
  }
}
class GrazeSystem extends System{
  constructor(w){ super(w,[C.GRAZER,C.TRANSFORM,C.LOCO,C.GAIT]); }
  update(dt){
    const h=this.world.singletons.clock.hour;
    const penned=(season===3)||(workHour(h)<6.4)||(workHour(h)>=18.6);
    const t=perf;
    this.entities().forEach(e=>{
      const gz=this.world.get(e,C.GRAZER),tr=this.world.get(e,C.TRANSFORM),
            lo=this.world.get(e,C.LOCO),g=this.world.get(e,C.GAIT);
      let c,rad;
      if(gz.kind==='horse'||gz.kind==='hen'){ c=gz.home; rad=gz.kind==='hen'?5:7; }
      else if(gz.kind==='pig'){ c=gz.home; rad=2.6; }
      else if(penned){ c=gz.home; rad=3.0; }
      else { c={x:gz.common.x+Math.sin(t*0.045)*4,z:gz.common.z+Math.cos(t*0.037)*4}; rad=6; }
      gz.wait-=dt;
      if(gz.wait<0||!gz.target){
        const a=RG()*TAU,d=RG()*rad;
        gz.target={x:c.x+Math.sin(a)*d,z:c.z+Math.cos(a)*d};
        gz.wait=gz.kind==='hen'?rnd(0.4,1.6):(gz.kind==='dog'?rnd(1,3):rnd(3,11));
      }
      tr.moved=0;
      const arrived=seek(tr,lo,gz.target.x,gz.target.z,dt);
      g.moving=tr.moved>0.0001;
      if(g.moving) g.phase+=tr.moved*g.rate;
      if(gz.neck) gz.neck.rotation.x=lerp(gz.neck.rotation.x,
        (arrived&&gz.kind!=='hen')?0.85:0.05, dt*(arrived?2:4));
      tr.hop=(gz.kind==='hen'&&g.moving)?Math.abs(Math.sin(g.phase*0.5))*0.05:0;
    });
  }
}
class SentrySystem extends System{
  constructor(w){ super(w,[C.SENTRY,C.TRANSFORM,C.GAIT]); }
  update(dt){
    this.entities().forEach(e=>{
      const s=this.world.get(e,C.SENTRY),tr=this.world.get(e,C.TRANSFORM),
            g=this.world.get(e,C.GAIT);
      if(s.mode==='gate'){
        g.moving=false; tr.grounded=true;
        tr.rot=s.rot0+Math.sin(perf*0.5+tr.x)*0.25;
        return;
      }
      if(s.mode==='butts'){
        g.moving=false; tr.grounded=true; tr.rot=s.rot0;
        const c=(perf*0.55+s.off)%3.4;                     // nock, draw, loose, wait
        const draw=c<1.9?smooth(0,1.6,c):smooth(2.1,1.9,c);
        g.armR.rotation.x=-1.5-draw*0.15;
        g.armL.rotation.x=-1.5;
        this.world.get(e,C.RENDER).visible=(hour>7&&hour<18.5);
        return;
      }
      tr.grounded=false;
      if(s.mode==='wall'&&patrolWalls.length){
        if(s.w>=patrolWalls.length) s.w=0;
        const w=patrolWalls[s.w];
        if(s.pause>0){ s.pause-=dt; g.moving=false; }
        else{
          s.t+=s.dir*dt*(1.6/Math.max(4,w.len));
          g.moving=true; g.phase+=dt*3.4;
          if(RG()<dt*0.05) s.pause=rnd(1.5,4.5);
          if(s.t>1||s.t<0){
            const nodeI=s.t>1?w.n2:w.n1, node=patrolNodes[nodeI];
            const opts=node.links.filter(k=>k!==s.w);
            if(opts.length){
              const nw=opts[Math.floor(RG()*opts.length)],W=patrolWalls[nw];
              s.w=nw;
              if(W.n1===nodeI){s.t=0; s.dir=1;} else {s.t=1; s.dir=-1;}
            }else{ s.dir*=-1; s.t=clamp(s.t,0,1); }
          }
        }
        const W=patrolWalls[s.w],t=clamp(s.t,0,1);
        tr.x=lerp(W.a.x,W.b.x,t); tr.z=lerp(W.a.z,W.b.z,t); tr.y=W.y+0.05;
        tr.rot=Math.atan2((W.b.x-W.a.x)*s.dir,(W.b.z-W.a.z)*s.dir);
      }else{
        g.moving=false; tr.rot+=dt*0.25;
        tr.x=s.post.x; tr.z=s.post.z; tr.y=s.post.y;
      }
    });
  }
}
class FlightSystem extends System{
  constructor(w){ super(w,[C.FLYER,C.RENDER]); }
  update(dt){
    const h=this.world.singletons.clock.hour;
    const roosting=(h<5.2||h>19.8);
    this.entities().forEach(e=>{
      const f=this.world.get(e,C.FLYER),rd=this.world.get(e,C.RENDER);
      f.a+=f.spd*dt;
      const r=roosting?(f.roostR||3.4):f.r;
      const y=roosting?f.roostY:f.h+Math.sin(f.a*2.1)*1.4;
      rd.obj.position.set(f.cx+Math.sin(f.a)*r,y,f.cz+Math.cos(f.a)*r);
      rd.obj.rotation.y=f.a+PI/2;
      rd.obj.rotation.z=roosting?0:-0.35;
      f.flap+=dt*(roosting?1.5:11);
      const w=roosting?0.05:Math.sin(f.flap)*0.85;
      f.wl.rotation.z=w; f.wr.rotation.z=-w;
    });
  }
}
class CartSystem extends System{
  constructor(w){ super(w,[C.CART,C.TRANSFORM,C.PATH,C.RENDER]); }
  update(dt){
    const h=this.world.singletons.clock.hour;
    const daylight=(h>5.6&&h<19.5);
    this.entities().forEach(e=>{
      const c=this.world.get(e,C.CART),tr=this.world.get(e,C.TRANSFORM),
            p=this.world.get(e,C.PATH),rd=this.world.get(e,C.RENDER);
      rd.visible=daylight;
      if(!p.queue.length){ c.leg=(c.leg+1)%c.stops.length; const s=c.stops[c.leg];
                           p.queue.push({x:s.x,z:s.z}); }
      if(daylight&&tr.moved>0.0001) c.wheels.forEach(w=>w.rotation.x-=tr.moved*1.6);
    });
  }
}
class GaitSystem extends System{
  constructor(w){ super(w,[C.GAIT]); }
  update(){
    this.entities().forEach(e=>{
      const g=this.world.get(e,C.GAIT);
      const sw=g.moving?Math.sin(g.phase)*0.55:0;
      if(g.legL){ g.legL.rotation.x=sw; g.legR.rotation.x=-sw;
                  g.armL.rotation.x=-sw*0.8; g.armR.rotation.x=sw*0.8; }
      if(g.legs){ g.legs[0].rotation.x=sw; g.legs[1].rotation.x=-sw;
                  g.legs[2].rotation.x=-sw; g.legs[3].rotation.x=sw; }
    });
  }
}
/* the two bits of hand-work that read as work: hammering and stooping */
class LabourSystem extends System{
  constructor(w){ super(w,[C.ROUTINE,C.GAIT,C.TRANSFORM]); }
  update(){
    if(!this.world.singletons.clock.running) return;
    this.entities().forEach(e=>{
      const r=this.world.get(e,C.ROUTINE),g=this.world.get(e,C.GAIT),tr=this.world.get(e,C.TRANSFORM);
      if(g.moving){ tr.tilt=0; return; }
      if(r.role==='smith'){ g.armR.rotation.x=-1.5+Math.abs(Math.sin(perf*5.5))*1.7; }
      else if(r.role==='field'){
        const s=Math.sin(perf*2.4+r.wob);
        g.armR.rotation.x=-0.5-s*0.8; g.armL.rotation.x=-0.5-s*0.8;
        tr.tilt=0.18+s*0.06;
      }
    });
  }
}
class SyncSystem extends System{
  constructor(w){ super(w,[C.RENDER,C.TRANSFORM]); }
  update(){
    this.entities().forEach(e=>{
      const rd=this.world.get(e,C.RENDER),tr=this.world.get(e,C.TRANSFORM);
      rd.obj.visible=rd.visible;
      if(!rd.visible) return;
      if(tr.grounded!==false) tr.y=ground(tr.x,tr.z);
      rd.obj.position.set(tr.x,tr.y+(tr.hop||0),tr.z);
      rd.obj.rotation.y=tr.rot;
      rd.obj.rotation.x=tr.tilt||0;
    });
  }
}

