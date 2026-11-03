/* ══════════════ ART · architecture ══════════════
   Everything load-bearing is turned or extruded from a drawn profile now:
   walls batter inward as they rise, towers carry a corbel table under the
   parapet, gates are arched openings cut through the mass, roofs are gabled
   with an overhang and a ridge. No box is left doing a stone's work.        */
function lathe(pts,seg,m,phi){
  const v=pts.map(p=>new T.Vector2(Math.max(p[0],0.0001),p[1]));
  const g=new T.LatheGeometry(v,seg||18,0,phi||TAU);
  g.computeVertexNormals();
  return new T.Mesh(g,m);
}
/* a square or oblong block that leans in as it rises */
function batter(wB,dB,wT,dT,h,m){
  const g=new T.CylinderGeometry(0.7071,0.7071,1,4,1);
  g.rotateY(PI/4);
  const p=g.attributes.position;
  for(let i=0;i<p.count;i++){
    const y=p.getY(i), t=y+0.5;
    p.setX(i,p.getX(i)/0.7071*0.5*lerp(wB,wT,t));
    p.setZ(i,p.getZ(i)/0.7071*0.5*lerp(dB,dT,t));
    p.setY(i,t*h);
  }
  g.computeVertexNormals();
  return new T.Mesh(g,m);
}
/* a wall of masonry with an arch cut clean through it */
function archWall(w,h,d,aw,ah,m){
  const s=new T.Shape();
  s.moveTo(-w/2,0); s.lineTo(w/2,0); s.lineTo(w/2,h); s.lineTo(-w/2,h); s.closePath();
  const o=new T.Path();
  const r=aw/2, spring=ah-r;
  o.moveTo(-r,0); o.lineTo(-r,spring);
  o.absarc(0,spring,r,PI,0,true);
  o.lineTo(r,0); o.closePath();
  s.holes.push(o);
  const g=new T.ExtrudeGeometry(s,{depth:d,bevelEnabled:false,curveSegments:14});
  g.translate(0,0,-d/2); g.computeVertexNormals();
  return new T.Mesh(g,m);
}
/* gabled roof: a triangle run along the ridge, with eaves that overhang */
function gable(w,d,rise,over,m){
  const s=new T.Shape();
  s.moveTo(-w/2-over,0); s.lineTo(w/2+over,0);
  s.lineTo(w/2+over,0.16); s.lineTo(0.0,rise+0.16);
  s.lineTo(-w/2-over,0.16); s.closePath();
  const g=new T.ExtrudeGeometry(s,{depth:d+over*2,bevelEnabled:false});
  g.translate(0,0,-(d+over*2)/2); g.computeVertexNormals();
  return new T.Mesh(g,m);
}
/* a merlon with a weathered cap */
function merlonGeo(w,h,t){
  const s=new T.Shape();
  s.moveTo(-w/2,0); s.lineTo(w/2,0); s.lineTo(w/2,h*0.78);
  s.lineTo(w*0.18,h); s.lineTo(-w*0.18,h); s.lineTo(-w/2,h*0.78); s.closePath();
  const g=new T.ExtrudeGeometry(s,{depth:t,bevelEnabled:false});
  g.translate(0,0,-t/2); g.computeVertexNormals();
  return g;
}
const MERLON=()=>cacheGeo('merlon',()=>merlonGeo(1.05,1.35,1.25));
function cacheGeo(k,make){ let g=GEO[k]; if(!g){ g=make(); g.userData.cached=true; GEO[k]=g; } return g; }

function makeTower(x,z,rot){
  const g=new T.Group(); const base=ground(x,z)-3.0, tall=12.4;
  /* plinth · batter · string course · corbel table · parapet */
  const prof=[
    [0,0],[3.55,0],[3.55,1.5],[3.15,2.2],[3.15,tall*0.42],
    [3.3,tall*0.45],[3.3,tall*0.5],[2.86,tall*0.54],
    [2.86,tall-1.5],[3.34,tall-0.95],[3.42,tall-0.55],[3.42,tall],[3.02,tall],[3.02,tall-0.7],[0,tall-0.7]
  ];
  const body=lathe(prof,20,stone); g.add(body);
  /* the crown */
  const mg=MERLON(), n=12;
  for(let k=0;k<n;k++){
    const a=k/n*TAU;
    const mm=new T.Mesh(mg,stoneD);
    mm.position.set(Math.sin(a)*3.2,tall,Math.cos(a)*3.2);
    mm.rotation.y=a; g.add(mm);
  }
  /* conical cap with a slight ogee, and a vane */
  const rf=lathe([[3.55,0],[3.2,1.1],[2.3,2.7],[1.1,4.3],[0,5.4]],20,slate);
  rf.position.y=tall+0.5; g.add(rf);
  g.add(cyl(0.09,0.09,1.5,6,mat('iron',0x2f3237),0,tall+6.1,0));
  const vane=box(0.9,0.5,0.06,mat('iron',0x2f3237),0.35,tall+6.6,0); g.add(vane);
  /* arrow loops, recessed */
  for(let k=0;k<4;k++){
    const a=k/4*TAU+0.4;
    const lp=box(0.34,1.5,0.5,darkM,Math.sin(a)*2.9,tall*0.62,Math.cos(a)*2.9);
    lp.rotation.y=a; g.add(lp);
    const cr=box(1.1,0.32,0.5,darkM,Math.sin(a)*2.9,tall*0.62+0.2,Math.cos(a)*2.9);
    cr.rotation.y=a; g.add(cr);
  }
  g.position.set(x,base,z);
  return {group:shadowy(g),meta:{torch:new T.Vector3(x,base+tall+1.0,z),top:base+tall+0.25}};
}

function makeWall(a,b,flip){
  const g=new T.Group();
  const len=Math.hypot(b.x-a.x,b.z-a.z);
  if(len<2) return null;
  const s=flip?-1:1;
  let lo=1e9;
  for(let i=0;i<=6;i++){const t=i/6; lo=Math.min(lo,ground(lerp(a.x,b.x,t),lerp(a.z,b.z,t)));}
  const topY=Math.max(ground(a.x,a.z),ground(b.x,b.z))+WALL_TOP;
  const base=lo-2.6, h=topY-base;
  /* cross-section: a battered curtain with a chamfered wall-walk */
  const sec=new T.Shape();
  sec.moveTo(-2.1,0); sec.lineTo(2.1,0);
  sec.lineTo(1.55,h*0.30); sec.lineTo(1.72,h*0.33); sec.lineTo(1.42,h*0.37);
  sec.lineTo(1.42,h); sec.lineTo(-1.42,h);
  sec.lineTo(-1.42,h*0.37); sec.lineTo(-1.72,h*0.33); sec.lineTo(-1.55,h*0.30);
  sec.closePath();
  const wg=new T.ExtrudeGeometry(sec,{depth:len,bevelEnabled:false});
  wg.translate(0,0,-len/2); wg.rotateY(PI/2); wg.computeVertexNormals();
  g.add(new T.Mesh(wg,stone));
  /* wall walk and parapet */
  g.add(box(len,0.3,2.9,stoneD,0,h+0.14,0));
  const mg=MERLON(), n=Math.max(2,Math.floor(len/1.95));
  for(let i=0;i<n;i++){
    const mm=new T.Mesh(mg,stoneD);
    mm.position.set(((i+0.5)/n-0.5)*len,h+0.25,1.35*s);
    mm.rotation.y=PI/2; g.add(mm);
  }
  g.add(box(len,0.55,0.42,stoneD,0,h+0.5,-1.42*s));      // inner curb
  const slits=[];
  for(let k=0;k<Math.floor(len/6);k++) slits.push({x:-len/2+3.5+k*6,y:h*0.62,z:1.3*s});
  if(slits.length) g.add(instanced(bgeo(0.3,1.2,0.5),darkM,slits));
  const rot=Math.atan2(b.x-a.x,b.z-a.z)+PI/2;
  g.position.set((a.x+b.x)/2,base,(a.z+b.z)/2);
  g.rotation.y=rot;
  const outA=flip?rot+PI:rot;
  return {group:shadowy(g),meta:{a:{x:a.x,z:a.z},b:{x:b.x,z:b.z},topY:topY,
    face:{x:(a.x+b.x)/2+Math.sin(outA)*3.6,z:(a.z+b.z)/2+Math.cos(outA)*3.6,a:outA}}};
}

function makeGate(x,z,rot){
  const g=new T.Group(); const base=ground(x,z)-2.4;
  const H=12.4;
  /* the mass, with the passage cut through it */
  const blk=archWall(9.4,H,6.2,3.9,5.6,stone); blk.position.y=H/2; 
  blk.position.y=0; g.add(blk);
  /* flanking drums */
  [-1,1].forEach(sd=>{
    const d=lathe([[0,0],[2.5,0],[2.5,1.2],[2.15,2.0],[2.15,H-1.4],[2.55,H-0.8],[2.55,H+0.2],
                   [2.2,H+0.2],[2.2,H-0.4],[0,H-0.4]],16,stone);
    d.position.set(sd*4.9,0,0); g.add(d);
    const mg=MERLON();
    for(let k=0;k<9;k++){
      const a=k/9*TAU;
      const mm=new T.Mesh(mg,stoneD);
      mm.position.set(sd*4.9+Math.sin(a)*2.35,H+0.2,Math.cos(a)*2.35);
      mm.rotation.y=a; mm.scale.setScalar(0.8); g.add(mm);
    }
    const rf=lathe([[2.7,0],[2.3,1.0],[1.4,2.4],[0,3.6]],16,slate);
    rf.position.set(sd*4.9,H+0.6,0); g.add(rf);
  });
  /* machicolations over the arch, and a parapet */
  for(let k=0;k<5;k++) g.add(box(0.8,1.1,1.5,stoneD,-2.6+k*1.3,H-1.2,3.2));
  g.add(box(9.4,0.5,1.9,stoneD,0,H-0.35,3.0));
  const mg=MERLON();
  for(let k=0;k<5;k++){
    const mm=new T.Mesh(mg,stoneD);
    mm.position.set(-2.6+k*1.3,H-0.1,3.0); g.add(mm);
  }
  /* portcullis and gates */
  const bars=[];
  for(let k=0;k<7;k++) bars.push({x:-1.7+k*0.57,y:2.6,z:2.55});
  for(let k=0;k<5;k++) bars.push({x:0,y:0.7+k*1.1,z:2.55,rz:PI/2,sy:3.7/5.2});
  g.add(instanced(bgeo(0.14,5.2,0.14),mat('iron',0x2f3237),bars));
  g.add(box(3.7,4.9,0.2,timber,0,2.45,-2.7));
  g.position.set(x,base,z); g.rotation.y=rot;
  const f=fwd(rot);
  return {group:shadowy(g),meta:{
    front:{x:x+f.x*7.0,z:z+f.z*7.0}, mid:{x:x,z:z}, back:{x:x-f.x*7.0,z:z-f.z*7.0},
    face:{x:x+f.x*8.4,z:z+f.z*8.4,a:rot},
    torch:new T.Vector3(x+f.x*3.6,base+H+0.7,z+f.z*3.6)}};
}

function makeKeep(x,z,rot){
  const g=new T.Group(); const base=ground(x,z)-2.2;
  const H=19.5;
  const body=batter(14.6,13.0,13.0,11.6,H,stone); g.add(body);
  /* pilaster buttresses on the long faces */
  [-1,1].forEach(sd=>{
    [-4.4,0,4.4].forEach(o=>{
      const b=batter(1.9,1.3,1.5,1.0,H*0.86,stoneD);
      b.position.set(o,0,sd*6.3); g.add(b);
    });
  });
  /* corner turrets, corbelled out near the top */
  [[-6.6,-5.8],[6.6,-5.8],[-6.6,5.8],[6.6,5.8]].forEach(p=>{
    const t=lathe([[0,0],[2.0,0],[2.0,1.0],[1.72,1.9],[1.72,H+2.4],[2.15,H+3.0],[2.15,H+4.0],
                   [1.8,H+4.0],[1.8,H+3.4],[0,H+3.4]],16,stoneD);
    t.position.set(p[0],0,p[1]); g.add(t);
    const rf=lathe([[2.3,0],[1.95,0.9],[1.15,2.2],[0,3.5]],16,slate);
    rf.position.set(p[0],H+4.2,p[1]); g.add(rf);
  });
  /* machicolated parapet all round */
  const mg=MERLON();
  const ring=(w,d,y)=>{
    const nx=Math.floor(w/1.7), nz=Math.floor(d/1.7);
    for(let i=0;i<nx;i++){
      [-1,1].forEach(sd=>{
        const m1=new T.Mesh(mg,stoneD);
        m1.position.set(-w/2+(i+0.5)*(w/nx),y,sd*d/2); g.add(m1);
      });
    }
    for(let i=0;i<nz;i++){
      [-1,1].forEach(sd=>{
        const m1=new T.Mesh(mg,stoneD);
        m1.position.set(sd*w/2,y,-d/2+(i+0.5)*(d/nz)); m1.rotation.y=PI/2; g.add(m1);
      });
    }
  };
  g.add(box(14.4,0.7,12.8,stoneD,0,H+0.35,0));
  ring(13.6,12.0,H+1.0);
  /* mullioned openings */
  for(let f=0;f<3;f++) for(let i=0;i<4;i++){
    const y=5.4+f*4.6;
    g.add(box(1.15,2.0,0.3,darkM,-4.8+i*3.2,y,6.05));
    g.add(box(0.18,2.0,0.34,stoneD,-4.8+i*3.2,y,6.1));
    g.add(box(1.3,0.22,0.34,stoneD,-4.8+i*3.2,y+1.1,6.1));
    g.add(box(0.95,1.6,0.16,glassM,-4.8+i*3.2,y-0.15,6.16));
  }
  /* forebuilding and the door */
  const fb=batter(4.6,3.4,4.2,3.0,6.4,stone); fb.position.set(0,0,7.2); g.add(fb);
  const arch=archWall(4.2,5.4,3.2,2.2,3.4,stone); arch.position.set(0,0,7.2); g.add(arch);
  g.add(box(2.1,3.0,0.24,timber,0,1.5,8.75));
  const bg=new T.PlaneGeometry(3.0,4.0,12,12);
  const ban=new T.Mesh(bg,new T.MeshStandardMaterial({color:0x9c2f1c,side:T.DoubleSide,roughness:0.92}));
  ban.position.set(1.7,H+7.0,5.2);
  ban.userData.base=Float32Array.from(bg.attributes.position.array);
  g.add(ban);
  g.add(cyl(0.14,0.14,9,6,timber,0.15,H+6.0,5.2));
  g.position.set(x,base,z); g.rotation.y=rot;
  const f=fwd(rot);
  return {group:shadowy(g),meta:{
    door:{x:x+f.x*10.4,z:z+f.z*10.4}, banner:ban,
    face:{x:x+f.x*11.8,z:z+f.z*11.8,a:rot},
    smoke:new T.Vector3(x,base+H+3,z), torch:new T.Vector3(x+f.x*9.0,base+3.0,z+f.z*9.0)}};
}

const fwd=r=>({x:Math.sin(r),z:Math.cos(r)});

