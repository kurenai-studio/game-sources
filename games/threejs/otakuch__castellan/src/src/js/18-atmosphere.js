/* ══════════════ 12 · wind, hearths and sky ══════════════ */
class WindSystem extends System{
  get always(){return true;}
  constructor(w){ super(w,[]); }
  update(dt){
    const wind=this.world.singletons.wind;
    wind.strength=0.9+Math.sin(perf*0.4)*0.35;
    idx.sails.forEach((s,k)=>{ if(s) s.rotation.z+=dt*(0.55+wind.strength*0.5)*(k%2?-1:1); });
    idx.banners.forEach((b,k)=>{
      if(!b||!b.userData.base) return;
      const p=b.geometry.attributes.position,base=b.userData.base;
      for(let i=0;i<p.count;i++){
        const x=base[i*3],y=base[i*3+1],t=(x+1.3)/2.6;
        p.array[i*3+2]=Math.sin(t*4.2-perf*(4+k)*wind.strength)*0.42*t*t+Math.sin(y*2+perf*3)*0.06*t;
        p.array[i*3]=base[i*3]-t*t*0.18;
      }
      p.needsUpdate=true;
    });
    const wsh=water.material.userData.sh; if(wsh) wsh.uniforms.uT.value=perf;
  const wp=waterGeo.attributes.position;
    for(let i=0;i<wp.count;i++){
      const x=waterBase[i*3],z=waterBase[i*3+2];
      wp.array[i*3+1]=Math.sin(x*0.09+perf*1.3)*0.13+Math.cos(z*0.08-perf*1.0)*0.11;
    }
    wp.needsUpdate=true;
  }
}
const smoke=[];
(function(){
  const c=document.createElement('canvas'); c.width=c.height=64;
  const x=c.getContext('2d');
  const g=x.createRadialGradient(32,32,1,32,32,31);
  g.addColorStop(0,'rgba(210,205,195,.75)'); g.addColorStop(1,'rgba(210,205,195,0)');
  x.fillStyle=g; x.fillRect(0,0,64,64);
  const tex=new T.CanvasTexture(c); if(MODERN) tex.colorSpace=T.SRGBColorSpace;
  const base=new T.SpriteMaterial({map:tex,transparent:true,opacity:0.4,depthWrite:false});
  for(let i=0;i<72;i++){
    const s=new T.Sprite(base.clone()); s.visible=false; scene.add(s);
    smoke.push({sp:s,life:0,max:1,stack:i,t:rnd(0,3)});
  }
})();
class HearthSystem extends System{
  get always(){return true;}
  constructor(w){ super(w,[]); }
  update(dt){
    const wind=this.world.singletons.wind.strength;
    const burn=(hour<8.6||hour>16.4)?1:0.25;
    const budget=QUALITY.now.smoke;
    for(let i=0;i<smoke.length;i++){
      const s=smoke[i];
      if(!idx.smoke.length||i>=budget){ s.sp.visible=false; continue; }
      s.life-=dt*(running?pace:0.35);
      if(s.life<=0){
        if(Math.random()>burn*0.9){ s.sp.visible=false; s.life=rnd(0.4,1.6); continue; }
        const st=idx.smoke[s.stack%idx.smoke.length];
        s.ox=st.x+rnd(-0.15,0.15); s.oy=st.y; s.oz=st.z+rnd(-0.15,0.15);
        s.life=rnd(3.4,6.5); s.max=s.life; s.drift=rnd(-0.5,0.5); s.sp.visible=true;
      }
      const t=1-s.life/s.max;
      s.sp.position.set(s.ox+t*2.4*wind+Math.sin(t*5+s.t)*0.3,s.oy+t*5.2,s.oz+s.drift*t*2);
      const sc=0.5+t*2.6; s.sp.scale.set(sc,sc,1);
      s.sp.material.opacity=Math.min(t*4,1)*(1-t)*0.4;
    }
  }
}
const SKY=[
  [0,0x0a1024,0x070b16],[4.2,0x101a34,0x0c1222],[5.6,0x7a5e6c,0x30293c],
  [6.6,0xd99a63,0x8a7168],[8.0,0x9ec6e8,0x93b3cc],[12.0,0x8ec6ee,0xa2c8e4],
  [16.0,0x9cc6e8,0xa8c4d8],[18.4,0xe2a45e,0x9a8272],[19.8,0x8a5a58,0x3f3750],
  [21.2,0x161f38,0x0e1428],[24.0,0x0a1024,0x070b16]
];
const cA=new T.Color(),cB=new T.Color(),cSky=new T.Color(),cFog=new T.Color();
function sky(h){
  let i=0; while(i<SKY.length-2&&h>=SKY[i+1][0]) i++;
  const t=clamp((h-SKY[i][0])/(SKY[i+1][0]-SKY[i][0]),0,1);
  cA.setHex(SKY[i][1]); cB.setHex(SKY[i+1][1]); cSky.copy(cA).lerp(cB,t);
  cA.setHex(SKY[i][2]); cB.setHex(SKY[i+1][2]); cFog.copy(cA).lerp(cB,t);
  renderer.setClearColor(cSky); scene.fog.color.copy(cFog);
  const s=SN();
  const dayT=(h-s.dawn)/(s.dusk-s.dawn),el=Math.sin(clamp(dayT,-0.35,1.35)*PI),az=dayT*PI;
  const sx=-Math.cos(az)*0.85,sy=Math.max(el,-0.4),sz=0.42;
  const L=Math.hypot(sx,sy,sz);
  sunLight.position.set(cam.tx+sx/L*130,sy/L*130,cam.tz+sz/L*130);
  sunLight.target.position.set(cam.tx,0,cam.tz);
  const up=clamp(el,0,1);
  sunLight.intensity=Math.pow(up,0.5)*1.35*LX;
  sunLight.color.setHSL(0.09,0.55*(1-smooth(0.06,0.35,up))+0.06,0.55+0.35*smooth(0,0.4,up));
  nightF=1-smooth(-0.10,0.24,el);
  moonLight.position.set(-sx/L*130,Math.abs(sy)/L*110+40,-sz/L*130);
  moonLight.intensity=nightF*0.30*LX;
  hemi.intensity=lerp(0.8,0.34,nightF)*LX;
  hemi.color.copy(cSky); hemi.groundColor.setHex(nightF>0.5?0x1a1c24:0x4c4527);
  scene.fog.density=lerp(0.0016,0.0036,nightF)+smooth(0.22,0,up)*0.0009;
  stars.material.opacity=nightF*0.95;
  glassM.color.setRGB(lerp(0.08,1.0,nightF),lerp(0.06,0.66,nightF),lerp(0.04,0.26,nightF));
  const fl=nightF*(0.75+Math.sin(perf*9)*0.12+Math.sin(perf*23)*0.08);
  flameM.color.setRGB(lerp(0.16,1,fl),lerp(0.12,0.62,fl),lerp(0.09,0.2,fl));
  torchLights.forEach((l,k)=>l.intensity=l.userData.on?nightF*(1.6+Math.sin(perf*(9+k*2))*0.3)*11:0);
  forgeLight.intensity=(idx.forge&&hour>5.8&&hour<20.6)?(1.6+Math.sin(perf*6)*0.7)*(0.4+nightF*0.9)*PLX:0;
  const froze=SN().snow*0.7;
  const s2=SN();
  skyUni.uTop.value.copy(cSky).multiplyScalar(0.80).lerp(new T.Color(0x1a3a7a),0.30);
  skyUni.uHorizon.value.copy(cFog).multiplyScalar(1.06);
  skyUni.uSun.value.copy(sunLight.position).sub(new T.Vector3(cam.tx,0,cam.tz)).normalize();
  skyUni.uSunCol.value.copy(sunLight.color).multiplyScalar(0.55+up*0.7);
  skyUni.uCloudCol.value.copy(cSky).lerp(new T.Color(0xffffff),0.55-nightF*0.45);
  skyUni.uNight.value=nightF;
  skyUni.uTime.value=perf;
  skyUni.uCloud.value=(s2.snow>0?0.20:0)+(season===0?0.10:0);
  skyDome.position.set(camera.position.x,0,camera.position.z);
  if(perf>envDue&&QUALITY.name!=='low'){ envDue=perf+14; refreshEnv(); }
  water.material.color.setRGB(lerp(lerp(0.05,0.19,1-nightF),0.62,froze),
                              lerp(lerp(0.09,0.34,1-nightF),0.70,froze),
                              lerp(lerp(0.14,0.44,1-nightF),0.76,froze));
}
class SkySystem extends System{
  get always(){return true;}
  constructor(w){ super(w,[]); }
  update(){ sky(hour); }
}

