function makeFence(a,b){
  const g=new T.Group(), len=Math.hypot(b.x-a.x,b.z-a.z);
  if(len<1.5) return null;
  const n=Math.max(1,Math.round(len/1.7)),posts=[];
  for(let k=0;k<=n;k++){
    const x=lerp(a.x,b.x,k/n),z=lerp(a.z,b.z,k/n);
    posts.push({x:x,y:ground(x,z)+0.6,z:z});
  }
  g.add(instanced(bgeo(0.13,1.2,0.13),timber,posts));
  const mx=(a.x+b.x)/2,mz=(a.z+b.z)/2;
  const rail=box(len,0.1,0.08,timber,mx,ground(mx,mz)+0.82,mz);
  rail.rotation.y=Math.atan2(b.x-a.x,b.z-a.z)+PI/2; g.add(rail);
  return {group:shadowy(g),meta:{a:{x:a.x,z:a.z},b:{x:b.x,z:b.z}}};
}
function makeBridge(a,b){
  const g=new T.Group(), len=Math.hypot(b.x-a.x,b.z-a.z);
  if(len<3) return null;
  const y=Math.max(ground(a.x,a.z),ground(b.x,b.z))+0.45;
  const mx=(a.x+b.x)/2,mz=(a.z+b.z)/2;
  const rot=Math.atan2(b.x-a.x,b.z-a.z)+PI/2;
  const deck=box(len,0.45,4.6,timber,mx,y,mz); deck.rotation.y=rot; g.add(deck);
  const steps=Math.max(1,Math.round(len/3));
  [-2.35,2.35].forEach(off=>{
    const piles=[],rails=[];
    for(let k=0;k<=steps;k++){
      const t=k/steps;
      const px=lerp(a.x,b.x,t)+Math.cos(rot)*off, pz=lerp(a.z,b.z,t)-Math.sin(rot)*off;
      const ph=Math.max(1.4,y-ground(px,pz));
      piles.push({x:px,y:y-ph/2,z:pz,sx:1,sy:ph,sz:1});
      rails.push({x:px,y:y+0.85,z:pz});
    }
    g.add(instanced(bgeo(0.4,1,0.4),timber,piles));
    g.add(instanced(bgeo(0.18,1.5,0.18),timber,rails));
    const r=box(len,0.16,0.14,timber,mx+Math.cos(rot)*off,y+1.5,mz-Math.sin(rot)*off);
    r.rotation.y=rot; g.add(r);
  });
  return {group:shadowy(g),meta:{a:{x:a.x,z:a.z},b:{x:b.x,z:b.z},y:y}};
}
function makePath(a,b){
  const g=new T.Group(), len=Math.hypot(b.x-a.x,b.z-a.z);
  if(len<2) return null;
  const n=Math.max(2,Math.round(len/2.4));
  const rot=Math.atan2(b.x-a.x,b.z-a.z)+PI/2;
  for(let k=0;k<n;k++){
    const t=(k+0.5)/n;
    const px=lerp(a.x,b.x,t),pz=lerp(a.z,b.z,t);
    const m=box(len/n+0.5,0.18,3.0,pathM,px,ground(px,pz)-0.04,pz);
    m.rotation.y=rot; m.receiveShadow=true; g.add(m);
  }
  return {group:g,meta:{a:{x:a.x,z:a.z},b:{x:b.x,z:b.z}}};
}
function roofed(g,w,d,h,roofMat){
  g.add(box(w,h,d,plaster,0,h/2,0));
  [-1,1].forEach(s=>g.add(box(0.16,h,d,timber,s*w/2,h/2,0)));
  g.add(box(w+0.1,0.18,d+0.1,timber,0,h-0.09,0));
  g.add(box(w+0.1,0.16,d+0.1,timber,0,h*0.52,0));
  const r=gable(w,d,h*0.72,0.42,roofMat||thatch);
  r.position.y=h; g.add(r);
  g.add(box(w+1.0,0.22,0.30,timber,0,h+h*0.72+0.12,0));           // ridge
  [-1,1].forEach(sd=>g.add(box(w+0.9,0.16,0.22,timber,0,h+0.24,sd*(d/2+0.4))));
  g.add(box(0.95,1.9,0.16,timber,0,0.95,d/2+0.03));
  g.add(box(0.6,0.6,0.14,glassM,w*0.3,h*0.62,d/2+0.03));
  g.add(box(0.6,0.6,0.14,glassM,-w*0.3,h*0.62,d/2+0.03));
  g.add(box(0.8,h*0.9,0.8,stoneD,w*0.32,h+h*0.32,-d*0.18));
}
function dwelling(w,d,h,roofMat,extra){
  return function(x,z,rot){
    const g=new T.Group(); const base=ground(x,z);
    roofed(g,w,d,h,roofMat);
    if(extra) extra(g,w,d,h);
    g.position.set(x,base,z); g.rotation.y=rot;
    const f=fwd(rot), out=d/2+1.4;
    return {group:shadowy(g),meta:{
      door:{x:x+f.x*out,z:z+f.z*out},
      face:{x:x+f.x*(out+1.1),z:z+f.z*(out+1.1),a:rot},
      smoke:new T.Vector3(x+Math.cos(rot)*w*0.32-f.x*d*0.18, base+h*1.75, z-Math.sin(rot)*w*0.32-f.z*d*0.18)}};
  };
}
const makeCottage=dwelling(5.2,4.6,3.6,thatch);
const makeHall=dwelling(8.2,6.4,4.6,slate);
const makeTavern=dwelling(7.0,5.6,4.2,thatch,function(g,w,d,h){
  g.add(box(0.16,0.16,1.5,timber,w*0.34,h*0.86,d/2+0.7));
  g.add(box(0.1,0.5,0.1,timber,w*0.34,h*0.86-0.3,d/2+1.35));
  const sign=box(1.3,0.9,0.1,mat('sign',0x6b4a2e),w*0.34,h*0.86-0.95,d/2+1.35);
  g.add(sign);
  g.add(box(0.9,0.12,0.9,goldM,w*0.34,h*0.86-0.95,d/2+1.29));
  g.add(box(2.4,0.16,0.7,timber,-w*0.2,0.7,d/2+0.9));
  [-1,1].forEach(s=>g.add(box(0.14,0.7,0.14,timber,-w*0.2+s*1.0,0.35,d/2+0.9)));
});
function makeChapel(x,z,rot){
  const g=new T.Group(); const base=ground(x,z);
  g.add(box(5.6,4.8,8.6,stone,0,2.4,0));
  const r=cone(4.4,3.2,4,slate,0,6.2,0); r.rotation.y=PI/4; r.scale.set(0.72,1,1.36); g.add(r);
  g.add(box(2.3,9.4,2.3,stone,0,4.7,-4.8));
  g.add(cone(1.75,3.8,4,slate,0,11.3,-4.8));
  g.add(box(0.16,1.5,0.16,goldM,0,13.9,-4.8));
  g.add(box(1.0,0.16,0.16,goldM,0,13.7,-4.8));
  g.add(box(1.0,2.4,0.16,glassM,0,2.2,4.32));
  [-1,1].forEach(s=>g.add(box(0.5,1.4,0.14,glassM,s*2.85,2.6,-1.5)));
  g.position.set(x,base,z); g.rotation.y=rot;
  const f=fwd(rot);
  return {group:shadowy(g),meta:{door:{x:x+f.x*6.0,z:z+f.z*6.0},
    face:{x:x+f.x*7.2,z:z+f.z*7.2,a:rot}}};
}
function makeSmithy(x,z,rot){
  const g=new T.Group(); const base=ground(x,z);
  g.add(box(5.0,3.2,4.4,plaster,0,1.6,0));
  const r=cone(3.9,2.6,4,thatch,0,4.5,0); r.rotation.y=PI/4; g.add(r);
  g.add(box(1.2,3.6,1.2,stoneD,1.9,3.4,-1.6));
  g.add(box(1.4,0.9,1.4,stoneD,0,0.45,3.0));
  g.add(box(0.5,0.7,0.5,darkM,-1.6,0.35,2.6));
  g.add(box(1.2,0.3,1.2,timber,1.6,0.15,2.8));
  g.position.set(x,base,z); g.rotation.y=rot;
  const f=fwd(rot);
  return {group:shadowy(g),meta:{
    anvil:{x:x+f.x*3.2,z:z+f.z*3.2},
    face:{x:x+f.x*5.0,z:z+f.z*5.0,a:rot},
    forge:new T.Vector3(x+f.x*3.0,base+1.1,z+f.z*3.0),
    smoke:new T.Vector3(x+Math.cos(rot)*1.9,base+5.6,z-Math.sin(rot)*1.9)}};
}
function makeMill(x,z,rot){
  const g=new T.Group(); const base=ground(x,z);
  g.add(cyl(2.0,2.9,9.0,12,plaster,0,4.5,0));
  for(let k=0;k<5;k++) g.add(box(6.0,0.16,0.16,timber,0,1.4+k*1.7,0));
  g.add(cone(2.6,2.4,12,slate,0,10.2,0));
  g.add(box(1.0,1.9,0.16,timber,0,0.95,2.55));
  g.add(box(0.6,0.6,0.14,glassM,1.2,5.4,2.1));
  const hub=new T.Group(); hub.position.set(0,8.6,3.0); g.add(hub);
  const hb=cyl(0.34,0.34,0.9,8,timber,0,0,0); hb.rotation.x=PI/2; hub.add(hb);
  for(let k=0;k<4;k++){
    const arm=new T.Group(); arm.rotation.z=k*PI/2; hub.add(arm);
    arm.add(box(0.22,7.0,0.22,timber,0,3.4,0));
    arm.add(box(1.5,5.2,0.1,mat('sail',0xd9cfae),0.85,3.6,-0.16));
  }
  g.position.set(x,base,z); g.rotation.y=rot;
  const f=fwd(rot);
  return {group:shadowy(g),meta:{
    door:{x:x+f.x*4.4,z:z+f.z*4.4}, sails:hub,
    face:{x:x+f.x*5.6,z:z+f.z*5.6,a:rot}}};
}
function makeStall(x,z,rot){
  const g=new T.Group(); const base=ground(x,z);
  [-1,1].forEach(s=>[-1,1].forEach(t=>g.add(box(0.14,2.1,0.14,timber,s*1.4,1.05,t*0.85))));
  g.add(box(3.4,0.14,2.3,(RG()<0.5?clothR:clothG),0,2.15,0));
  g.add(box(3.0,0.16,1.6,timber,0,1.15,0));
  for(let k=0;k<4;k++) g.add(box(0.3,0.3,0.3,mat('ware'+(k%3),[0xb8823a,0x7f9a4c,0xa5566a][k%3]),
                                -1.1+k*0.75,1.38,(k%2?0.3:-0.3)));
  g.position.set(x,base,z); g.rotation.y=rot;
  const f=fwd(rot);
  return {group:shadowy(g),meta:{front:{x:x+f.x*2.0,z:z+f.z*2.0},
    face:{x:x+f.x*3.0,z:z+f.z*3.0,a:rot}}};
}
function makeWell(x,z){
  const g=new T.Group(); const base=ground(x,z);
  g.add(cyl(1.3,1.4,1.15,14,stoneD,0,0.58,0));
  g.add(cyl(1.2,1.2,0.1,14,mat('wellw',0x2c4a5c),0,1.0,0));
  [-1,1].forEach(s=>g.add(box(0.2,2.6,0.2,timber,s*1.15,2.3,0)));
  const r=cone(2.0,1.1,4,thatch,0,3.9,0); r.rotation.y=PI/4; g.add(r);
  g.add(box(2.8,0.18,0.18,timber,0,3.3,0));
  g.add(box(0.4,0.45,0.4,timber,0,2.5,0));
  g.position.set(x,base,z);
  return {group:shadowy(g),meta:{spot:{x:x+2.2,z:z+1.2}}};
}
function makeCross(x,z){
  const g=new T.Group(); const base=ground(x,z);
  for(let k=0;k<3;k++) g.add(box(3.2-k*0.8,0.35,3.2-k*0.8,stoneD,0,0.17+k*0.35,0));
  g.add(box(0.42,3.4,0.42,stone,0,2.9,0));
  g.add(box(1.7,0.4,0.4,stone,0,4.2,0));
  g.position.set(x,base,z);
  return {group:shadowy(g),meta:{}};
}
function makeField(x,z,rot){
  const g=new T.Group(), spots=[];
  const w=15,d=12,rows=8,cols=5;
  const base=ground(x,z), s=Math.sin(rot), c=Math.cos(rot);
  const soilT=[],cropT=[];
  for(let r=0;r<rows;r++){
    const lz=-d/2+(r+0.5)*(d/rows);
    for(let k=0;k<cols;k++){
      const lx=-w/2+(k+0.5)*(w/cols);
      const wx=x+lx*c+lz*s, wz=z-lx*s+lz*c;
      (r%3===2?cropT:soilT).push({x:lx,y:ground(wx,wz)-base-0.05,z:lz});
    }
    if(r%3===1) for(let k=0;k<2;k++){
      const lx=-w/4+k*(w/2);
      spots.push({x:x+lx*c+lz*s, z:z-lx*s+lz*c});
    }
  }
  const fg=bgeo(w/cols+0.06,0.16,(d/rows)*0.74);
  [[soilT,soilM],[cropT,cropM]].forEach(p=>{
    if(!p[0].length) return;
    const im=instanced(fg,p[1],p[0]); im.castShadow=false; g.add(im);
  });
  g.position.set(x,base,z); g.rotation.y=rot;
  return {group:g,meta:{spots:spots.length?spots:[{x:x,z:z}]}};
}
function makeOrchard(x,z,rot){
  const g=new T.Group(), spots=[];
  const base=ground(x,z), s=Math.sin(rot), c=Math.cos(rot);
  const trunks=[],lowC=[],topC=[];
  for(let r=0;r<4;r++) for(let k=0;k<4;k++){
    const lx=-6+k*4, lz=-6+r*4;
    const wx=x+lx*c+lz*s, wz=z-lx*s+lz*c;
    const sc=0.55+RG()*0.2, y0=ground(wx,wz)-base;
    trunks.push({x:lx,y:y0+1.1*sc,z:lz,s:sc});
    lowC.push({x:lx,y:y0+2.6*sc,z:lz,s:sc});
    topC.push({x:lx,y:y0+3.7*sc,z:lz,s:sc});
    if((r+k)%3===0) spots.push({x:wx,z:wz});
  }
  g.add(instanced(cgeo(0.2,0.3,2.2,6),trunkM,trunks));
  g.add(instanced(kgeo(1.9,2.4,7),leafC,lowC));
  g.add(instanced(kgeo(1.5,2.0,7),leafA,topC));
  g.position.set(x,base,z); g.rotation.y=rot;
  return {group:shadowy(g),meta:{spots:spots.length?spots:[{x:x,z:z}]}};
}
function makePen(x,z,rot){
  const g=new T.Group(); const base=ground(x,z);
  const w=9,d=8;
  const corner=[[-w/2,-d/2],[w/2,-d/2],[w/2,d/2],[-w/2,d/2],[-w/2,-d/2]];
  const pp=[];
  for(let i=0;i<4;i++){
    const a=corner[i],b=corner[i+1];
    const L=Math.hypot(b[0]-a[0],b[1]-a[1]), n=Math.round(L/1.6);
    for(let k=0;k<=n;k++){
      if(i===2&&k>n*0.35&&k<n*0.65) continue;
      pp.push({x:lerp(a[0],b[0],k/n),y:0.58,z:lerp(a[1],b[1],k/n)});
    }
  }
  g.add(instanced(bgeo(0.13,1.15,0.13),timber,pp));
  g.add(box(1.6,0.5,0.7,timber,0,0.25,d/2-1.6));
  g.position.set(x,base,z); g.rotation.y=rot;
  const f=fwd(rot);
  return {group:shadowy(g),meta:{centre:{x:x,z:z},
    face:{x:x+f.x*(d/2+1.6),z:z+f.z*(d/2+1.6),a:rot}}};
}
function makeTree(x,z){
  const g=new T.Group(); const s=0.85+RG()*0.7;
  g.add(cyl(0.22*s,0.36*s,2.4*s,6,trunkM,0,1.2*s,0));
  for(let i=0;i<3;i++) g.add(cone((1.8-i*0.36)*s,2.3*s,7,i%2?leafA:leafB,0,(2.4+i*1.1)*s,0));
  g.position.set(x,ground(x,z),z);
  return {group:shadowy(g),meta:{}};
}
function makeBush(x,z){
  const g=new T.Group();
  for(let i=0;i<4;i++){
    const a=RG()*TAU,d=RG()*0.9,s=0.5+RG()*0.4;
    g.add(cone(0.9*s,1.3*s,6,i%2?leafA:leafC,Math.sin(a)*d,0.55*s,Math.cos(a)*d));
  }
  g.position.set(x,ground(x,z),z);
  return {group:shadowy(g),meta:{}};
}
function makeHay(x,z){
  const g=new T.Group();
  g.add(cone(1.5,2.6,8,thatch,0,1.3,0));
  g.position.set(x,ground(x,z),z);
  return {group:shadowy(g),meta:{}};
}

function makeGranary(x,z,rot){
  const g=new T.Group(); const base=ground(x,z);
  const legs=[];
  for(let i=0;i<3;i++) for(let k=0;k<2;k++)
    legs.push({x:-2.4+i*2.4,y:0.55,z:-1.5+k*3.0});
  g.add(instanced(cgeo(0.34,0.5,1.1,8),stoneD,legs));   // staddle stones keep the rats out
  g.add(instanced(cgeo(0.6,0.6,0.16,8),stoneD,legs.map(l=>({x:l.x,y:1.16,z:l.z}))));
  g.add(box(6.0,3.0,4.0,timber,0,2.75,0));
  for(let i=0;i<5;i++) g.add(box(0.16,3.0,4.05,plaster,-2.4+i*1.2,2.75,0));
  const r=cone(4.6,2.2,4,thatch,0,5.4,0); r.rotation.y=PI/4; g.add(r);
  g.add(box(1.2,1.8,0.16,timber,0,2.1,2.03));
  for(let i=0;i<5;i++) g.add(box(1.6,0.14,0.3,timber,0,0.4+i*0.4,2.5+i*0.18));
  g.position.set(x,base,z); g.rotation.y=rot;
  const f=fwd(rot);
  return {group:shadowy(g),meta:{door:{x:x+f.x*3.6,z:z+f.z*3.6},
    face:{x:x+f.x*4.8,z:z+f.z*4.8,a:rot}}};
}
function makeBakehouse(x,z,rot){
  const g=new T.Group(); const base=ground(x,z);
  g.add(box(4.6,2.8,4.0,plaster,0,1.4,0));
  const r=cone(3.7,2.2,4,thatch,0,4.0,0); r.rotation.y=PI/4; g.add(r);
  const dome=new T.Mesh(new T.SphereGeometry(1.5,12,8,0,TAU,0,PI/2),stoneD);
  dome.position.set(0,1.0,-2.1); dome.userData.keep=1; g.add(dome);
  g.add(cyl(1.6,1.7,1.0,12,stoneD,0,0.5,-2.1));
  g.add(box(1.1,2.9,1.1,stoneD,1.5,4.0,-1.4));
  g.add(box(1.0,1.2,0.2,darkM,0,0.7,-3.5));
  g.add(box(1.1,1.9,0.16,timber,0,0.95,2.03));
  g.add(box(2.2,0.2,1.0,timber,-1.4,0.9,2.6));
  g.position.set(x,base,z); g.rotation.y=rot;
  const f=fwd(rot);
  return {group:shadowy(g),meta:{door:{x:x+f.x*3.4,z:z+f.z*3.4},
    face:{x:x+f.x*4.6,z:z+f.z*4.6,a:rot},
    oven:{x:x-f.x*2.6,z:z-f.z*2.6},
    forge:new T.Vector3(x-f.x*3.4,base+0.8,z-f.z*3.4),
    smoke:new T.Vector3(x+Math.cos(rot)*1.5+f.x*1.4,base+5.6,z-Math.sin(rot)*1.5+f.z*1.4)}};
}
function makeDovecote(x,z,rot){
  const g=new T.Group(); const base=ground(x,z);
  g.add(cyl(2.0,2.3,6.4,14,plaster,0,3.2,0));
  g.add(cyl(2.35,2.35,0.3,14,stoneD,0,4.6,0));
  const holes=[];
  for(let r=0;r<3;r++) for(let k=0;k<10;k++){
    const a=k/10*TAU+r*0.3;
    holes.push({x:Math.sin(a)*2.06,y:3.2+r*0.9,z:Math.cos(a)*2.06,ry:a});
  }
  g.add(instanced(bgeo(0.26,0.3,0.16),darkM,holes));
  g.add(cone(2.7,2.0,14,slate,0,7.4,0));
  g.add(cyl(0.3,0.3,0.7,8,timber,0,8.6,0));
  g.add(box(0.9,1.8,0.16,timber,0,0.9,2.18));
  g.position.set(x,base,z); g.rotation.y=rot;
  const f=fwd(rot);
  return {group:shadowy(g),meta:{door:{x:x+f.x*3.6,z:z+f.z*3.6},
    face:{x:x+f.x*4.8,z:z+f.z*4.8,a:rot},
    perch:{x:x,y:base+8.0,z:z}}};
}
function makeBeehive(x,z,rot){
  const g=new T.Group(); const base=ground(x,z);
  g.add(box(3.4,0.2,1.1,timber,0,0.6,0));
  [-1,0,1].forEach(k=>{
    const s=new T.Group(); s.position.set(k*1.1,0.7,0);
    for(let i=0;i<4;i++) s.add(cyl(0.42-i*0.09,0.5-i*0.09,0.22,10,thatch,0,i*0.2,0));
    s.add(cone(0.28,0.24,10,thatch,0,0.84,0));
    g.add(s);
  });
  [-1,1].forEach(sd=>[-1,1].forEach(t=>g.add(box(0.12,0.6,0.12,timber,sd*1.5,0.3,t*0.4))));
  g.position.set(x,base,z); g.rotation.y=rot;
  const f=fwd(rot);
  return {group:shadowy(g),meta:{tend:{x:x+f.x*2.2,z:z+f.z*2.2},
    face:{x:x+f.x*3.2,z:z+f.z*3.2,a:rot}}};
}
function makeJetty(x,z,rot){
  const g=new T.Group(); const base=Math.max(ground(x,z),WATER)+0.5;
  const f=fwd(rot);
  const planks=[],piles=[];
  for(let k=0;k<7;k++){
    planks.push({x:0,y:0,z:k*1.3});
    if(k%2===0)[-1,1].forEach(s=>{
      const px=x+f.x*(k*1.3)+(-f.z)*s*0.85, pz=z+f.z*(k*1.3)+f.x*s*0.85;
      const ph=Math.max(1.2,base-ground(px,pz));
      piles.push({x:s*0.85,y:-ph/2,z:k*1.3,sx:1,sy:ph,sz:1});
    });
  }
  g.add(instanced(bgeo(2.1,0.22,1.2),timber,planks));
  g.add(instanced(bgeo(0.3,1,0.3),timber,piles));
  const boat=new T.Group(); boat.position.set(1.9,-0.35,6.0); boat.rotation.y=0.3;
  boat.add(box(1.1,0.5,3.0,timber,0,0,0));
  boat.add(box(0.9,0.16,2.6,darkM,0,0.2,0));
  boat.add(box(0.9,0.12,0.2,timber,0,0.16,0.6));
  boat.add(box(0.12,0.1,2.2,timber,0.7,0.3,-0.4));
  g.add(boat);
  g.position.set(x,base,z); g.rotation.y=rot;
  return {group:shadowy(g),meta:{
    stand:{x:x+f.x*7.2,z:z+f.z*7.2}, deckY:base,
    face:{x:x+f.x*9.4,z:z+f.z*9.4,a:rot}, boat:boat}};
}
function makeButts(x,z,rot){
  const g=new T.Group(); const base=ground(x,z);
  const f=fwd(rot);
  [-1.6,1.6].forEach(sd=>{
    const t=new T.Group(); t.position.set(sd,0,0);
    t.add(box(0.2,1.8,0.2,timber,-0.55,0.9,0));
    t.add(box(0.2,1.8,0.2,timber,0.55,0.9,0));
    const boss=new T.Mesh(cgeo(0.7,0.7,0.22,14),thatch);
    boss.rotation.x=PI/2; boss.position.y=1.4; t.add(boss);
    t.add(box(0.34,0.34,0.06,clothR,0,1.4,0.14));
    g.add(t);
  });
  g.add(box(5.4,0.16,0.5,soilM,0,0.06,7.5));
  for(let k=0;k<3;k++) g.add(box(0.1,0.9,0.1,timber,-2+k*2,0.45,7.5));
  g.position.set(x,base,z); g.rotation.y=rot;
  return {group:shadowy(g),meta:{
    mark:{x:x+f.x*7.5,z:z+f.z*7.5}, aim:rot+PI,
    face:{x:x+f.x*9.0,z:z+f.z*9.0,a:rot}}};
}
function makeGarden(x,z,rot){
  const g=new T.Group(); const base=ground(x,z);
  const w=7,d=5.5;
  const wat=[];
  const edge=[[-w/2,-d/2],[w/2,-d/2],[w/2,d/2],[-w/2,d/2],[-w/2,-d/2]];
  for(let i=0;i<4;i++){
    const a=edge[i],b=edge[i+1];
    const L=Math.hypot(b[0]-a[0],b[1]-a[1]),n=Math.round(L/0.55);
    for(let k=0;k<=n;k++){
      if(i===2&&k>n*0.4&&k<n*0.6) continue;
      wat.push({x:lerp(a[0],b[0],k/n),y:0.42,z:lerp(a[1],b[1],k/n),ry:RG()*0.4});
    }
  }
  g.add(instanced(bgeo(0.09,0.85,0.09),timber,wat));
  const beds=[],herbs=[];
  for(let r=0;r<3;r++) for(let k=0;k<4;k++){
    beds.push({x:-2.4+k*1.6,y:0.1,z:-1.6+r*1.6});
    herbs.push({x:-2.4+k*1.6+RG()*0.4-0.2,y:0.38,z:-1.6+r*1.6+RG()*0.3-0.15,s:0.5+RG()*0.4});
  }
  g.add(instanced(bgeo(1.3,0.2,1.2),soilM,beds));
  g.add(instanced(kgeo(0.5,0.7,6),leafC,herbs));
  g.position.set(x,base,z); g.rotation.y=rot;
  const f=fwd(rot);
  return {group:shadowy(g),meta:{tend:{x:x+f.x*1.4,z:z+f.z*1.4},
    face:{x:x+f.x*(d/2+1.6),z:z+f.z*(d/2+1.6),a:rot}}};
}
function makeBeacon(x,z){
  const g=new T.Group(); const base=ground(x,z);
  for(let k=0;k<3;k++){
    const a=k/3*TAU;
    g.add(box(0.24,7.0,0.24,timber,Math.sin(a)*0.9,3.5,Math.cos(a)*0.9));
  }
  g.add(cyl(0.16,0.16,2.0,6,timber,0,1.6,0));
  g.add(cyl(1.0,0.7,0.9,10,stoneD,0,7.3,0));
  const fire=new T.Mesh(new T.SphereGeometry(0.7,9,7),flameM);
  fire.position.y=7.9; g.add(fire);
  g.add(box(2.6,0.16,0.16,timber,0,6.6,0));
  g.position.set(x,base,z);
  return {group:shadowy(g),meta:{torch:new T.Vector3(x,base+7.9,z),beacon:true}};
}

const PIECES={
  raise  :{label:'Raise',     group:'Ground',  sculpt:'raise', dig:true, tip:'Drag on the ground to pull it up. Shift-drag still turns the camera.'},
  lower  :{label:'Lower',     group:'Ground',  sculpt:'lower', dig:true, tip:'Drag to press the ground down. Cut below the water line and it floods.'},
  flat   :{label:'Flatten',   group:'Ground',  sculpt:'flat',  dig:true, tip:'The first point you touch sets the level; drag to bring the rest to it.'},
  smoothT:{label:'Smooth',    group:'Ground',  sculpt:'smooth',dig:true, tip:'Softens whatever you have just cut.'},
  wall   :{label:'Wall',      group:'Defence', line:true, flipk:true, tip:'Click for the start of the wall, then its end. , or . flips which side the parapet faces.'},
  tower  :{label:'Tower',     group:'Defence', r:3.4, tip:'Towers carry the watch — one guard each, and a torch at night.'},
  gate   :{label:'Gatehouse', group:'Defence', r:5.0, rot:true, tip:'The only way through a wall. The arrow points out; turn it with , and .'},
  keep   :{label:'Keep',      group:'Defence', r:8.0, rot:true, tip:'The lord lives here, and the crows above him. The arrow marks the door.'},
  cottage:{label:'Cottage',   group:'Dwelling',r:3.4, rot:true, tip:'Two to a cottage, and smoke over the ward. The arrow is the door.'},
  hall   :{label:'Hall',      group:'Dwelling',r:5.0, rot:true, tip:'Hall and stable. Horses stand in the yard behind it.'},
  tavern :{label:'Tavern',    group:'Dwelling',r:4.6, rot:true, tip:'Where the field folk and traders go between Vespers and dark.'},
  chapel :{label:'Chapel',    group:'Dwelling',r:4.4, rot:true, tip:'A chapel gives you monks, who keep the hours.'},
  smithy :{label:'Smithy',    group:'Work',    r:3.4, rot:true, tip:'The smith works the forge from Prime to Compline.'},
  bakehouse:{label:'Bakehouse',group:'Work',   r:3.6, rot:true, tip:'A baker, and bread at the well by Sext. Keep it clear of the thatch.'},
  granary:{label:'Granary',   group:'Work',    r:4.0, rot:true, tip:'Raised on staddle stones. What the fields bring in ends up here.'},
  garden :{label:'Garden',    group:'Work',    r:4.4, rot:true, tip:'Herb beds, and a herbwife to keep them.'},
  beehive:{label:'Beehives',  group:'Work',    r:2.4, rot:true, tip:'Skeps on a bench. Tended in the warm months only.'},
  jetty  :{label:'Jetty',     group:'Work',    r:5.0, rot:true, water:true, tip:'Runs out over the water. Point it at the deep and a fisher will work it.'},
  mill   :{label:'Mill',      group:'Work',    r:4.0, rot:true, tip:'Sails turn with the wind, and a miller works beneath them.'},
  stall  :{label:'Stall',     group:'Work',    r:2.2, rot:true, tip:'One trader per stall. The arrow is the side they stand.'},
  well   :{label:'Well',      group:'Work',    r:1.8, tip:'Work stops at the well at midday.'},
  field  :{label:'Field',     group:'Work',    r:8.0, rot:true, tip:'Ploughed strips. Each field puts three more hands in the fields.'},
  orchard:{label:'Orchard',   group:'Work',    r:7.0, rot:true, tip:'Fruit trees in rows. Worked like a field.'},
  pen    :{label:'Pen',       group:'Work',    r:5.5, rot:true, tip:'Sheep, cattle and pigs. The arrow marks the gap they file through.'},
  dovecote:{label:'Dovecote',  group:'Dwelling',r:3.2, rot:true, tip:'Doves in the eaves, circling all day and roosting on the cap.'},
  butts  :{label:'Butts',     group:'Defence', r:5.0, rot:true, tip:'Archery marks. Off-duty guards come here to shoot.'},
  beacon :{label:'Beacon',    group:'Defence', r:2.2, tip:'A fire basket on a pole. It burns from dusk to dawn.'},
  path   :{label:'Path',      group:'Land',    line:true, tip:'Click both ends. A trodden track, and nothing more.'},
  fence  :{label:'Fence',     group:'Land',    line:true, tip:'Click one end of the fence, then the other.'},
  bridge :{label:'Bridge',    group:'Land',    line:true, tip:'Click both banks. Without one, nobody crosses the water.'},
  tree   :{label:'Tree',      group:'Land',    r:1.8},
  bush   :{label:'Bush',      group:'Land',    r:1.2},
  hay    :{label:'Haystack',  group:'Land',    r:1.8},
  cross  :{label:'Cross',     group:'Land',    r:2.4, tip:'A market cross. It does nothing, which is rather the point.'},
  remove :{label:'Remove',    group:'Land',    warn:true, tip:'Click anything you have placed to take it away again.'}
};
const MAKERS={tower:makeTower,gate:makeGate,keep:makeKeep,cottage:makeCottage,hall:makeHall,
  granary:makeGranary,bakehouse:makeBakehouse,dovecote:makeDovecote,beehive:makeBeehive,
  jetty:makeJetty,butts:makeButts,garden:makeGarden,beacon:makeBeacon,
  tavern:makeTavern,chapel:makeChapel,smithy:makeSmithy,mill:makeMill,stall:makeStall,
  well:makeWell,field:makeField,orchard:makeOrchard,pen:makePen,tree:makeTree,bush:makeBush,
  hay:makeHay,cross:makeCross,wall:makeWall,fence:makeFence,bridge:makeBridge,path:makePath};

/* a piece built larger or smaller has to take its meaning with it:
   doors, arrows, anvils and smoke all move out from the centre by the same factor */
function scaleMeta(m,x,z,base0,base1,s){
  if(!m||s===1) return m;
  const px=p=>{ const nx=x+(p.x-x)*s, nz=z+(p.z-z)*s;
                p.x=nx; p.z=nz; if(p.y!==undefined) p.y=base1+(p.y-base0)*s; return p; };
  ['door','face','front','back','mid','anvil','oven','stand','tend','mark','centre','spot','perch']
    .forEach(k=>{ if(m[k]&&m[k].x!==undefined) px(m[k]); });
  if(m.spots) m.spots.forEach(px);
  ['torch','forge','smoke'].forEach(k=>{
    if(m[k]) m[k].set(x+(m[k].x-x)*s, base1+(m[k].y-base0)*s, z+(m[k].z-z)*s);
  });
  if(m.top!==undefined) m.top=base1+(m.top-base0)*s;
  return m;
}
function build(rec){
  const def=PIECES[rec.key];
  const made=def.line?MAKERS[rec.key](rec.a,rec.b,rec.flip):MAKERS[rec.key](rec.x,rec.z,rec.rot||0);
  if(!made) return null;
  const s=(def.line?1:(rec.scale||1));
  if(s!==1){
    const g0=ground(rec.x,rec.z), base0=made.group.position.y, off=base0-g0;
    made.group.scale.setScalar(s);
    made.group.position.y=g0+off*s;
    scaleMeta(made.meta,rec.x,rec.z,base0,made.group.position.y,s);
  }
  built.add(made.group);
  rec.group=made.group; rec.meta=made.meta;
  rec.yoff=def.line?0:made.group.position.y-ground(rec.x,rec.z);
  return rec;
}
function place(key,x,z,rot,a,b,flip,scale){
  const def=PIECES[key]; if(!def||!MAKERS[key]) return null;
  const rec={key:key,rot:rot||0,flip:!!flip,a:a,b:b,scale:scale||1,
             x:def.line?(a.x+b.x)/2:x, z:def.line?(a.z+b.z)/2:z};
  if(!build(rec)) return null;
  placed.push(rec);
  return rec;
}
function removeRec(rec){
  const i=placed.indexOf(rec); if(i<0) return;
  placed.splice(i,1); built.remove(rec.group); disposeTree(rec.group);
}
function clearBuild(){ while(placed.length) removeRec(placed[placed.length-1]); }
/* after the ground moves under them, every piece is simply built again */
function rebuildAll(){
  placed.forEach(r=>{ built.remove(r.group); disposeTree(r.group); build(r); });
}
function distToSeg(px,pz,a,b){
  const dx=b.x-a.x,dz=b.z-a.z,L=dx*dx+dz*dz;
  if(L<1e-6) return Math.hypot(px-a.x,pz-a.z);
  const t=clamp(((px-a.x)*dx+(pz-a.z)*dz)/L,0,1);
  return Math.hypot(px-(a.x+dx*t),pz-(a.z+dz*t));
}
function nearestPlaced(x,z,maxD){
  let best=null,bd=maxD||6;
  placed.forEach(r=>{
    const d=(r.a&&r.b)?distToSeg(x,z,r.a,r.b):Math.hypot(r.x-x,r.z-z);
    if(d<bd){bd=d;best=r;}
  });
  return best;
}
(function bind(){
  const el=renderer.domElement;
  let drag=null; const pts=new Map(); let pinch=0;
  const touch=e=>e.pointerType==='touch';
  el.addEventListener('pointerdown',e=>{
    try{el.setPointerCapture(e.pointerId);}catch(x){}
    pts.set(e.pointerId,{x:e.clientX,y:e.clientY});
    if(photo) return;
    const orbit=(e.button===2)||(e.button===0&&e.shiftKey)||(touch(e)&&pts.size===1&&!isSculpt());
    const pan=(e.button===1)||(e.button===0&&e.altKey);
    if(!orbit&&!pan&&e.button===0&&mode==='build'&&isSculpt()&&pts.size===1){
      const hit=pickGround(e.clientX,e.clientY);
      if(hit){ pushHistory({t:'cut',data:Float32Array.from(EDIT)});
               sculpting={x:hit.x,z:hit.z,level:ground(hit.x,hit.z)}; drag=null; return; }
    }
    drag={x:e.clientX,y:e.clientY,pan:pan,orbit:orbit,moved:0,btn:e.button,
          sx:e.clientX,sy:e.clientY};
  });
  el.addEventListener('pointermove',e=>{
    if(sculpting){
      const hit=pickGround(e.clientX,e.clientY);
      if(hit){ sculpting.x=hit.x; sculpting.z=hit.z; }
      sculpting.fine=e.shiftKey;
      updateGhost(e.clientX,e.clientY);
      return;
    }
    if(!pts.has(e.pointerId)){ if(mode==='build'&&!photo) updateGhost(e.clientX,e.clientY); return; }
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
      applyCam();
    }else if(drag.orbit){
      cam.yaw-=dx*0.005; cam.pitch+=dy*0.004; applyCam();
    }
    if(mode==='build'&&!photo) updateGhost(e.clientX,e.clientY);
  });
  const up=e=>{
    if(sculpting){ sculpting=null; pts.delete(e.pointerId); afterSculpt(); return; }
    const was=drag;
    pts.delete(e.pointerId); if(pts.size<2)pinch=0; if(!pts.size)drag=null;
    if(was&&!was.pan&&!was.orbit&&was.moved<6&&was.btn===0&&mode==='build'&&!photo&&pts.size===0){
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
  el.addEventListener('wheel',e=>{
    e.preventDefault();
    if(e.shiftKey) sizeBy(e.deltaY<0?1:-1);
    else { cam.dist*=Math.exp(e.deltaY*0.0011); applyCam(); }
  },{passive:false});
})();

/* brush radius, or the size of the piece in hand */
function sizeBy(dir){
  if(isSculpt()){
    brush=clamp(brush+dir*1.5,4,26);
    const sl=$('brush'); if(sl) sl.value=brush;
    say('Brush '+Math.round(brush)+'.');
  }else if(PIECES[tool]&&!PIECES[tool].line&&tool!=='remove'){
    ghostScale=clamp(+(ghostScale+dir*0.08).toFixed(2),0.6,1.7);
    say(PIECES[tool].label+' at '+Math.round(ghostScale*100)+' per cent.');
  }
}


