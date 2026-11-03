/* ══════════════ ART · surfaces ══════════════
   Nothing is loaded. Every surface here is drawn onto a canvas at boot —
   albedo in RGB, height in alpha — and then mapped triplanar in world space,
   so a course of masonry runs at the same size across a tower, a wall and a
   sixty-metre keep without a single UV being authored.                      */
const TEX={};
function canv(n){ const c=document.createElement('canvas'); c.width=c.height=n; return c; }
function wrap(ctx,n,fn){                       // draw so the edges meet
  for(let ox=-1;ox<=1;ox++) for(let oy=-1;oy<=1;oy++){
    ctx.save(); ctx.translate(ox*n,oy*n); fn(ctx); ctx.restore();
  }
}
function grain(ctx,n,amt,alpha){
  const img=ctx.getImageData(0,0,n,n),d=img.data;
  for(let i=0;i<d.length;i+=4){
    const g=(Math.random()-0.5)*amt;
    d[i]=clamp(d[i]+g,0,255); d[i+1]=clamp(d[i+1]+g,0,255); d[i+2]=clamp(d[i+2]+g,0,255);
    if(alpha) d[i+3]=clamp(d[i+3]+g*alpha,0,255);
  }
  ctx.putImageData(img,0,0);
}
/* pack a height canvas into the alpha of the colour canvas */
function packed(col,hei,n,repeatWorld){
  const c=canv(n),x=c.getContext('2d');
  x.drawImage(col,0,0);
  const a=x.getImageData(0,0,n,n), hx=hei.getContext('2d').getImageData(0,0,n,n);
  for(let i=0;i<a.data.length;i+=4) a.data[i+3]=hx.data[i];
  x.putImageData(a,0,0);
  const t=new T.CanvasTexture(c);
  t.wrapS=t.wrapT=T.RepeatWrapping;
  t.colorSpace=MODERN?T.SRGBColorSpace:undefined;
  t.anisotropy=SMALL?2:8;
  t.userData.world=repeatWorld||1;
  return t;
}

function texAshlar(){
  const n=512,c=canv(n),h=canv(n),x=c.getContext('2d'),y=h.getContext('2d');
  x.fillStyle='#7d766a'; x.fillRect(0,0,n,n);
  y.fillStyle='#4a4a4a'; y.fillRect(0,0,n,n);
  const rows=8, rh=n/rows;
  for(let r=0;r<rows;r++){
    let px=(r%2)*rh*0.6;
    while(px<n+80){
      const w=rh*(1.1+Math.random()*1.1);
      const l=0.72+Math.random()*0.42;
      const col='rgb('+Math.round(150*l)+','+Math.round(143*l)+','+Math.round(128*l)+')';
      wrap(x,n,g=>{ g.fillStyle=col; g.fillRect(px+1.6,r*rh+1.6,w-3.2,rh-3.2); });
      wrap(y,n,g=>{
        const v=Math.round(150+Math.random()*60);
        g.fillStyle='rgb('+v+','+v+','+v+')';
        g.fillRect(px+2.2,r*rh+2.2,w-4.4,rh-4.4);
        g.fillStyle='rgba(255,255,255,.35)';
        g.fillRect(px+2.2,r*rh+2.2,w-4.4,2.4);           // a lit top arris
      });
      px+=w;
    }
  }
  grain(x,n,13); grain(y,n,11);
  return packed(c,h,n,0.115);
}
function texLimewash(){
  const n=512,c=canv(n),h=canv(n),x=c.getContext('2d'),y=h.getContext('2d');
  x.fillStyle='#cfc4ab'; x.fillRect(0,0,n,n);
  y.fillStyle='#9a9a9a'; y.fillRect(0,0,n,n);
  for(let i=0;i<170;i++){
    const px=Math.random()*n,py=Math.random()*n,r=8+Math.random()*54;
    const l=0.86+Math.random()*0.22;
    wrap(x,n,g=>{
      g.globalAlpha=0.16;
      g.fillStyle='rgb('+Math.round(207*l)+','+Math.round(196*l)+','+Math.round(171*l)+')';
      g.beginPath(); g.arc(px,py,r,0,TAU); g.fill(); g.globalAlpha=1;
    });
  }
  grain(x,n,12); grain(y,n,10);
  return packed(c,h,n,0.09);
}
function texWood(){
  const n=512,c=canv(n),h=canv(n),x=c.getContext('2d'),y=h.getContext('2d');
  x.fillStyle='#5a4630'; x.fillRect(0,0,n,n);
  y.fillStyle='#8c8c8c'; y.fillRect(0,0,n,n);
  for(let i=0;i<220;i++){
    const px=Math.random()*n,w=0.7+Math.random()*3.2;
    const l=0.7+Math.random()*0.6;
    wrap(x,n,g=>{
      g.strokeStyle='rgba('+Math.round(96*l)+','+Math.round(74*l)+','+Math.round(48*l)+',.55)';
      g.lineWidth=w; g.beginPath();
      g.moveTo(px,0);
      for(let s=0;s<=n;s+=32) g.lineTo(px+Math.sin(s*0.03+i)*2.4,s);
      g.stroke();
    });
    wrap(y,n,g=>{
      g.strokeStyle='rgba(0,0,0,.30)'; g.lineWidth=w; g.beginPath(); g.moveTo(px,0);
      for(let s=0;s<=n;s+=32) g.lineTo(px+Math.sin(s*0.03+i)*2.4,s);
      g.stroke();
    });
  }
  grain(x,n,16); grain(y,n,18);
  return packed(c,h,n,0.19);
}
function texTile(){
  const n=512,c=canv(n),h=canv(n),x=c.getContext('2d'),y=h.getContext('2d');
  x.fillStyle='#3c434b'; x.fillRect(0,0,n,n);
  y.fillStyle='#3a3a3a'; y.fillRect(0,0,n,n);
  const rows=11, rh=n/rows;
  for(let r=0;r<rows;r++){
    const off=(r%2)*rh*0.5;
    for(let k=-1;k<rows+1;k++){
      const px=off+k*rh, py=r*rh;
      const l=0.78+Math.random()*0.44;
      wrap(x,n,g=>{
        g.fillStyle='rgb('+Math.round(88*l)+','+Math.round(98*l)+','+Math.round(110*l)+')';
        g.beginPath();
        g.moveTo(px+1,py+rh); g.lineTo(px+1,py+rh*0.42);
        g.quadraticCurveTo(px+rh*0.5,py-rh*0.12,px+rh-1,py+rh*0.42);
        g.lineTo(px+rh-1,py+rh); g.closePath(); g.fill();
      });
      wrap(y,n,g=>{
        const v=Math.round(160+Math.random()*50);
        g.fillStyle='rgb('+v+','+v+','+v+')';
        g.beginPath();
        g.moveTo(px+2,py+rh); g.lineTo(px+2,py+rh*0.44);
        g.quadraticCurveTo(px+rh*0.5,py-rh*0.08,px+rh-2,py+rh*0.44);
        g.lineTo(px+rh-2,py+rh); g.closePath(); g.fill();
      });
    }
  }
  grain(x,n,18); grain(y,n,20);
  return packed(c,h,n,0.16);
}
function texStraw(){
  const n=512,c=canv(n),h=canv(n),x=c.getContext('2d'),y=h.getContext('2d');
  x.fillStyle='#8e6f34'; x.fillRect(0,0,n,n);
  y.fillStyle='#7a7a7a'; y.fillRect(0,0,n,n);
  for(let i=0;i<2600;i++){
    const px=Math.random()*n,py=Math.random()*n,len=10+Math.random()*30;
    const ang=PI/2+(Math.random()-0.5)*0.34;
    const l=0.7+Math.random()*0.7;
    const dx=Math.cos(ang)*len,dy=Math.sin(ang)*len;
    wrap(x,n,g=>{
      g.strokeStyle='rgb('+Math.round(178*l)+','+Math.round(141*l)+','+Math.round(72*l)+')';
      g.lineWidth=0.8+Math.random()*1.5;
      g.beginPath(); g.moveTo(px,py); g.lineTo(px+dx,py+dy); g.stroke();
    });
    wrap(y,n,g=>{
      const v=Math.round(90+Math.random()*140);
      g.strokeStyle='rgb('+v+','+v+','+v+')'; g.lineWidth=1.4;
      g.beginPath(); g.moveTo(px,py); g.lineTo(px+dx,py+dy); g.stroke();
    });
  }
  grain(x,n,16); grain(y,n,14);
  return packed(c,h,n,0.13);
}
function texEarth(){
  const n=256,c=canv(n),h=canv(n),x=c.getContext('2d'),y=h.getContext('2d');
  x.fillStyle='#6a5a3c'; x.fillRect(0,0,n,n);
  y.fillStyle='#808080'; y.fillRect(0,0,n,n);
  for(let i=0;i<900;i++){
    const px=Math.random()*n,py=Math.random()*n,r=1+Math.random()*5;
    const l=0.7+Math.random()*0.7;
    wrap(x,n,g=>{
      g.fillStyle='rgba('+Math.round(120*l)+','+Math.round(101*l)+','+Math.round(66*l)+',.6)';
      g.beginPath(); g.arc(px,py,r,0,TAU); g.fill();
    });
  }
  grain(x,n,30); grain(y,n,44);
  return packed(c,h,n,0.28);
}
function texCloth(){
  const n=128,c=canv(n),h=canv(n),x=c.getContext('2d'),y=h.getContext('2d');
  x.fillStyle='#b0b0b0'; x.fillRect(0,0,n,n);
  y.fillStyle='#8a8a8a'; y.fillRect(0,0,n,n);
  for(let i=0;i<n;i+=3){
    x.fillStyle='rgba(255,255,255,.10)'; x.fillRect(i,0,1.4,n);
    x.fillStyle='rgba(0,0,0,.10)'; x.fillRect(0,i,n,1.4);
  }
  grain(x,n,14); grain(y,n,26);
  return packed(c,h,n,0.6);
}
function buildTextures(){
  TEX.ashlar=texAshlar(); TEX.limewash=texLimewash(); TEX.wood=texWood();
  TEX.tile=texTile(); TEX.straw=texStraw(); TEX.earth=texEarth(); TEX.cloth=texCloth();
}

/* ── triplanar + derivative bump, patched into the standard material ── */
const TRI_VERT_HEAD='varying vec3 vWPos; varying vec3 vWNrm;\n';
const TRI_FRAG_HEAD='varying vec3 vWPos; varying vec3 vWNrm; uniform float uTriScale; uniform float uBump;\n'+
`vec4 triSample(sampler2D m, vec3 p, vec3 n, float s){
  vec3 b=pow(abs(n),vec3(4.0)); b/=(b.x+b.y+b.z+1e-5);
  return texture2D(m,p.zy*s)*b.x + texture2D(m,p.xz*s)*b.y + texture2D(m,p.xy*s)*b.z;
}\n`;
function triplanar(m,scale,bump){
  m.onBeforeCompile=function(sh){
    sh.uniforms.uTriScale={value:scale};
    sh.uniforms.uBump={value:bump===undefined?1.0:bump};
    sh.vertexShader=TRI_VERT_HEAD+sh.vertexShader
      .replace('#include <begin_vertex>',
        `#include <begin_vertex>
         vec4 triWp=vec4(transformed,1.0);
         #ifdef USE_INSTANCING
           triWp=instanceMatrix*triWp;
         #endif
         vWPos=(modelMatrix*triWp).xyz;`)
      .replace('#include <beginnormal_vertex>',
        `#include <beginnormal_vertex>
         vec3 triN=objectNormal;
         #ifdef USE_INSTANCING
           triN=mat3(instanceMatrix)*triN;
         #endif
         vWNrm=normalize(mat3(modelMatrix)*triN);`);
    sh.fragmentShader=TRI_FRAG_HEAD+sh.fragmentShader
      .replace('#include <map_fragment>',
        `vec4 triC=triSample(map,vWPos,vWNrm,uTriScale);
         diffuseColor.rgb *= triC.rgb*1.9;`)
      .replace('#include <normal_fragment_maps>',
        `#include <normal_fragment_maps>
         {
           float th=triC.a;
           vec3 dpx=dFdx(vWPos), dpy=dFdy(vWPos);
           float dhx=dFdx(th), dhy=dFdy(th);
           vec3 r1=cross(dpy,normal), r2=cross(normal,dpx);
           float det=dot(dpx,r1);
           if(abs(det)>1e-6){
             vec3 grad=(r1*dhx+r2*dhy)/det;
             normal=normalize(normal-uBump*grad);
           }
         }`);
  };
  m.customProgramCacheKey=()=>'tri'+scale+'|'+bump;
  return m;
}

/* which surface each shared material wears */
const SURFACE={
  stone:['ashlar',1.0,0.48,0.88], stoneD:['ashlar',1.0,0.52,0.9],
  rock:['ashlar',0.55,0.6,0.95], wellw:[null,1,0,0.25],
  plaster:['limewash',1.0,0.3,0.95], sign:['wood',1,0.5,0.85],
  timber:['wood',1.0,0.5,0.9], slate:['tile',1.0,0.55,0.72],
  thatch:['straw',1.0,0.62,0.96], soil:['earth',1.0,0.5,1.0],
  crop:['earth',0.7,0.4,1.0], path:['earth',1.0,0.5,1.0],
  clothR:['cloth',1.0,0.6,0.92], clothG:['cloth',1.0,0.6,0.92],
  cloth2:['cloth',1.0,0.6,0.92], sail:['cloth',1.0,0.7,0.9],
  dark:[null,1,0,1.0], gold:[null,1,0.85,0.32], horn:[null,1,0,0.6],
  trunk:['wood',0.55,1.0,0.95]
};

buildTextures();

