/* ══════════════ 2 · the land ══════════════
   height = what the generator made  +  what the player has cut by hand      */
let WATER=-2.8;
const R_MOAT=31.5, MOAT_W=4.6;
const land={seed:1327,relief:1.35,mount:true};

function mulberry32(a){return function(){a|=0;a=a+0x6D2B79F5|0;let t=Math.imul(a^a>>>15,1|a);
  t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296;};}
let RG=mulberry32(land.seed);
const NG=new Float32Array(65536);
function seedNoise(s){
  const r=mulberry32(s);
  for(let i=0;i<65536;i++) NG[i]=r()*2-1;
  RG=mulberry32(s^0x9e37);
}
const nv=(xi,zi)=>NG[((zi&255)<<8)|(xi&255)];
function noise2(x,z){
  const xi=Math.floor(x),zi=Math.floor(z),fx=x-xi,fz=z-zi;
  const u=fx*fx*(3-2*fx),v=fz*fz*(3-2*fz);
  return lerp(lerp(nv(xi,zi),nv(xi+1,zi),u),lerp(nv(xi,zi+1),nv(xi+1,zi+1),u),v);
}
const fbm=(x,z)=>noise2(x,z)*0.56+noise2(x*2.1+31,z*2.1+17)*0.28+noise2(x*4.4+7,z*4.4+53)*0.16;

/* how thickly the wood grows here — nothing within sight of the site */
function forestAt(x,z){
  const d=Math.hypot(x,z);
  const n=fbm(x*0.0078+41,z*0.0078+17)*0.5+0.5;
  return clamp(n*2.1-0.5,0,1)*smooth(52,86,d);
}
function baseGround(x,z){
  const d=Math.hypot(x,z);
  const n=fbm(x*0.0135,z*0.0135);
  const ridge=fbm(x*0.0052+61,z*0.0052+29);
  let h=n*15*land.relief+ridge*11*land.relief+11.5;
  const calm=smooth(80,36,d);
  h=lerp(h,1.5+n*3.0*land.relief*0.4,calm);
  if(land.mount){
    h+=smooth(30,26.5,d)*2.0;
    const tr=Math.max(0,1-Math.abs(d-R_MOAT)/(MOAT_W*0.5+1.5));
    h-=smooth(0,1,tr)*7.0;
  }
  return h;
}

/* the hand-cut layer */
const TSIZE=500, TSEG=QUALITY.now.seg, TSTEP=TSIZE/TSEG;
const HALF=TSIZE/2-14;
const EDN=TSEG+1;                        // one edit cell per terrain vertex
const EDIT=new Float32Array(EDN*EDN);
const gx=x=>(x+TSIZE/2)/TSTEP;           // world -> edit grid
const gw=i=>i*TSTEP-TSIZE/2;             // edit grid -> world
function editAt(x,z){
  const fx=gx(x),fz=gx(z);
  if(fx<0||fz<0||fx>EDN-1||fz>EDN-1) return 0;
  const xi=fx|0,zi=fz|0,tx=fx-xi,tz=fz-zi;
  const x1=Math.min(xi+1,EDN-1),z1=Math.min(zi+1,EDN-1);
  return lerp(lerp(EDIT[zi*EDN+xi],EDIT[zi*EDN+x1],tx),
              lerp(EDIT[z1*EDN+xi],EDIT[z1*EDN+x1],tx),tz);
}
function ground(x,z){ return baseGround(x,z)+editAt(x,z); }
const wet=(x,z)=>ground(x,z)<WATER+0.25;

/* terrain mesh */
const terrainGeo=new T.PlaneGeometry(TSIZE,TSIZE,TSEG,TSEG); terrainGeo.rotateX(-PI/2);
terrainGeo.setAttribute('color',new T.Float32BufferAttribute(
  new Float32Array(terrainGeo.attributes.position.count*3),3));
const terrainMat=new T.MeshStandardMaterial({vertexColors:true,roughness:1.0,metalness:0.0});
if(TEX.earth){ terrainMat.map=TEX.earth; triplanar(terrainMat,TEX.earth.userData.world*0.42,0.30); }
const terrain=new T.Mesh(terrainGeo,terrainMat);
terrain.receiveShadow=true; scene.add(terrain);

/* map (col,row) -> vertex index, so a brush can touch just its own patch */
const tIndex=new Int32Array(EDN*EDN);
(function(){
  const p=terrainGeo.attributes.position;
  for(let i=0;i<p.count;i++){
    const col=Math.round(gx(p.getX(i))), row=Math.round(gx(p.getZ(i)));
    if(col>=0&&col<EDN&&row>=0&&row<EDN) tIndex[row*EDN+col]=i;
  }
})();

const cGrass=new T.Color(0x6d8a45),cDry=new T.Color(0x96984f),cMud=new T.Color(0x7d6644),
      cSand=new T.Color(0xbfae82),cBed=new T.Color(0x4b4834),cRock=new T.Color(0x8b8778),
      cSnow=new T.Color(0xe8ecef),cForest=new T.Color(0x4a6236);
let SNOW=0;
const _c=new T.Color();
function shapeRegion(c0,c1,r0,r1){
  const p=terrainGeo.attributes.position,col=terrainGeo.attributes.color,nm=terrainGeo.attributes.normal;
  c0=Math.max(0,c0); r0=Math.max(0,r0); c1=Math.min(EDN-1,c1); r1=Math.min(EDN-1,r1);
  const e=TSTEP;
  for(let r=r0;r<=r1;r++) for(let c=c0;c<=c1;c++){
    const i=tIndex[r*EDN+c];
    const x=gw(c), z=gw(r), h=ground(x,z);
    p.setY(i,h);
    const hx=ground(x+e,z)-ground(x-e,z), hz=ground(x,z+e)-ground(x,z-e);
    let nx=-hx, ny=2*e, nz=-hz;
    const L=Math.hypot(nx,ny,nz)||1;
    nm.setXYZ(i,nx/L,ny/L,nz/L);
    const slope=(Math.abs(hx)+Math.abs(hz))/(2*e)*1.6;
    const d=Math.hypot(x,z);
    _c.copy(cGrass);
    _c.lerp(cDry,(fbm(x*0.031+5,z*0.031+9)*0.5+0.5)*0.55);
    _c.lerp(cMud,smooth(28,25.5,d)*0.42);
    _c.lerp(cRock,smooth(0.55,1.5,slope)*0.7);
    _c.lerp(cSand,smooth(WATER+1.6,WATER+0.2,h)*0.85);
    _c.lerp(cForest,forestAt(x,z)*0.42);
    _c.lerp(cBed,smooth(WATER,WATER-2.2,h));
    if(SNOW>0) _c.lerp(cSnow,SNOW*(0.55+0.45*smooth(1.4,0.3,slope))*smooth(WATER+0.4,WATER+2.4,h));
    col.setXYZ(i,_c.r,_c.g,_c.b);
  }
  p.needsUpdate=true; col.needsUpdate=true; nm.needsUpdate=true;
}
const shapeTerrain=()=>shapeRegion(0,EDN-1,0,EDN-1);

/* the brush */
function sculpt(cx,cz,radius,mode,strength,target){
  const c0=Math.floor(gx(cx-radius)),c1=Math.ceil(gx(cx+radius));
  const r0=Math.floor(gx(cz-radius)),r1=Math.ceil(gx(cz+radius));
  const src=(mode==='smooth')?Float32Array.from(EDIT):null;
  for(let r=Math.max(0,r0);r<=Math.min(EDN-1,r1);r++)
    for(let c=Math.max(0,c0);c<=Math.min(EDN-1,c1);c++){
      const x=gw(c),z=gw(r);
      const w=smooth(radius,radius*0.1,Math.hypot(x-cx,z-cz));
      if(w<=0) continue;
      const k=r*EDN+c;
      if(mode==='raise')  EDIT[k]+=strength*w;
      else if(mode==='lower') EDIT[k]-=strength*w;
      else if(mode==='flat'){
        const want=target-baseGround(x,z);
        EDIT[k]=lerp(EDIT[k],want,clamp(w*strength*1.6,0,1));
      }else if(mode==='smooth'){
        let sum=0,n=0;
        for(let dr=-2;dr<=2;dr++) for(let dc=-2;dc<=2;dc++){
          const rr=r+dr,cc=c+dc;
          if(rr<0||cc<0||rr>=EDN||cc>=EDN) continue;
          sum+=baseGround(gw(cc),gw(rr))+src[rr*EDN+cc]; n++;
        }
        const avg=sum/n;
        EDIT[k]=lerp(EDIT[k],avg-baseGround(x,z),clamp(w*strength*1.4,0,1));
      }
    }
  shapeRegion(c0-2,c1+2,r0-2,r1+2);
}

/* water sheet */
const waterGeo=new T.PlaneGeometry(TSIZE+40,TSIZE+40,60,60); waterGeo.rotateX(-PI/2);
const waterBase=Float32Array.from(waterGeo.attributes.position.array);
const water=new T.Mesh(waterGeo,new T.MeshStandardMaterial({color:0x24455c,transparent:true,
  opacity:0.92,roughness:0.16,metalness:0.22}));
water.position.y=WATER; scene.add(water);
