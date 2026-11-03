/* ══════════════ ART · air and water ══════════════ */
const SKY_FRAG=`
precision highp float;
varying vec3 vDir;
uniform vec3 uTop, uHorizon, uSun, uSunCol, uCloudCol;
uniform float uNight, uTime, uCloud;
float h21(vec2 p){ return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float vn(vec2 p){
  vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
  return mix(mix(h21(i),h21(i+vec2(1,0)),f.x),mix(h21(i+vec2(0,1)),h21(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p){
  float v=0.0, a=0.5;
  for(int i=0;i<5;i++){ v+=a*vn(p); p*=2.03; a*=0.5; }
  return v;
}
void main(){
  vec3 d=normalize(vDir);
  float y=clamp(d.y,-0.2,1.0);
  vec3 col=mix(uHorizon,uTop,pow(max(y,0.0),0.62));
  /* the sun, and the glow it throws around itself */
  float cd=max(dot(d,normalize(uSun)),0.0);
  col+=uSunCol*pow(cd,900.0)*3.4;
  col+=uSunCol*pow(cd,14.0)*0.34;
  col+=uSunCol*pow(cd,3.0)*0.09;
  /* cloud deck, projected onto a flat ceiling */
  if(d.y>0.015){
    vec2 p=d.xz/d.y*0.42;
    p+=vec2(uTime*0.0055,uTime*0.0028);
    float f=fbm(p*1.35);
    f=smoothstep(0.46,0.86,f+uCloud*0.22);
    float fade=smoothstep(0.015,0.30,d.y);
    float lit=0.55+0.45*pow(max(dot(d,normalize(uSun)),0.0),2.0);
    col=mix(col,uCloudCol*lit,f*fade*0.88);
  }
  /* stars come through as the light goes */
  if(uNight>0.02&&d.y>0.0){
    float s=h21(floor(d.xz*260.0+d.y*77.0));
    float tw=step(0.9975,s)*(0.6+0.4*sin(uTime*2.4+s*90.0));
    col+=vec3(0.75,0.80,0.95)*tw*uNight*1.5;
  }
  gl_FragColor=vec4(col,1.0);
  #include <tonemapping_fragment>
  #include <colorspace_fragment>
}`;
const SKY_VERT=`
varying vec3 vDir;
void main(){ vDir=position; gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.0); }`;

const skyUni={
  uTop:{value:new T.Color(0x2f6fbe)}, uHorizon:{value:new T.Color(0xbcd7ea)},
  uSun:{value:new T.Vector3(0.3,0.7,0.3)}, uSunCol:{value:new T.Color(0xffe9c4)},
  uCloudCol:{value:new T.Color(0xffffff)}, uNight:{value:0}, uTime:{value:0},
  uCloud:{value:0}
};
const skyMat=new T.ShaderMaterial({uniforms:skyUni,vertexShader:SKY_VERT,fragmentShader:SKY_FRAG,
  side:T.BackSide,depthWrite:false,fog:false,toneMapped:false});
const skyDome=new T.Mesh(new T.SphereGeometry(1,42,26),skyMat);
skyDome.scale.setScalar(1200); skyDome.renderOrder=-1; skyDome.frustumCulled=false;
scene.add(skyDome);

/* the same sky, rendered small, gives every surface something to reflect */
let pmrem=null, envRT=null, envDue=0;
const envScene=new T.Scene();
const envDome=new T.Mesh(skyDome.geometry,skyMat);
envDome.scale.setScalar(50); envScene.add(envDome);
function refreshEnv(){
  if(!MODERN) return;
  if(!pmrem){ pmrem=new T.PMREMGenerator(renderer); pmrem.compileEquirectangularShader(); }
  const rt=pmrem.fromScene(envScene,0,1,110);
  if(envRT) envRT.dispose();
  envRT=rt; scene.environment=rt.texture; scene.environmentIntensity=0.42;
}

/* ── water: two scrolling ripple fields, a fresnel rim and sun glitter ── */
function texRipple(){
  const n=256,c=canv(n),x=c.getContext('2d');
  x.fillStyle='#808080'; x.fillRect(0,0,n,n);
  for(let i=0;i<90;i++){
    const px=Math.random()*n,py=Math.random()*n,r=6+Math.random()*40;
    wrap(x,n,g=>{
      const gr=g.createRadialGradient(px,py,0,px,py,r);
      gr.addColorStop(0,'rgba(255,255,255,.16)');
      gr.addColorStop(0.55,'rgba(0,0,0,.10)');
      gr.addColorStop(1,'rgba(128,128,128,0)');
      g.fillStyle=gr; g.beginPath(); g.arc(px,py,r,0,TAU); g.fill();
    });
  }
  grain(x,n,10);
  const t=new T.CanvasTexture(c); t.wrapS=t.wrapT=T.RepeatWrapping;
  return t;
}
function dressWater(m){
  const rip=texRipple();
  m.onBeforeCompile=function(sh){
    sh.uniforms.uRip={value:rip};
    sh.uniforms.uT={value:0};
    m.userData.sh=sh;
    sh.vertexShader='varying vec3 vWP;\n'+sh.vertexShader.replace('#include <begin_vertex>',
      '#include <begin_vertex>\n vWP=(modelMatrix*vec4(transformed,1.0)).xyz;');
    sh.fragmentShader='varying vec3 vWP; uniform sampler2D uRip; uniform float uT;\n'+
      sh.fragmentShader.replace('#include <normal_fragment_maps>',
      `#include <normal_fragment_maps>
       {
         float a=texture2D(uRip,vWP.xz*0.030+vec2(uT*0.010,uT*0.005)).r;
         float b=texture2D(uRip,vWP.xz*0.012-vec2(uT*0.005,uT*0.008)).r;
         float hgt=(a+b)-1.0;
         vec3 dpx=dFdx(vWP), dpy=dFdy(vWP);
         float dhx=dFdx(hgt), dhy=dFdy(hgt);
         vec3 r1=cross(dpy,normal), r2=cross(normal,dpx);
         float det=dot(dpx,r1);
         if(abs(det)>1e-6) normal=normalize(normal-1.1*((r1*dhx+r2*dhy)/det));
       }`)
      .replace('#include <opaque_fragment>',
      `float fres=pow(1.0-abs(dot(normalize(vViewPosition),normal)),4.0);
       outgoingLight+=vec3(0.10,0.15,0.20)*fres*0.75;
       #include <opaque_fragment>`);
  };
  m.customProgramCacheKey=()=>'water';
  return m;
}
dressWater(water.material);


/* stars */
const starGeo=new T.BufferGeometry();
(function(){
  const n=900,pos=new Float32Array(n*3);
  for(let i=0;i<n;i++){
    const a=rnd(0,TAU),e=rnd(0.05,1.4),r=420;
    pos[i*3]=Math.sin(a)*Math.cos(e)*r; pos[i*3+1]=Math.sin(e)*r; pos[i*3+2]=Math.cos(a)*Math.cos(e)*r;
  }
  starGeo.setAttribute('position',new T.BufferAttribute(pos,3));
})();
const stars=new T.Points(starGeo,new T.PointsMaterial({color:0xdce6ff,size:1.8,sizeAttenuation:false,
  transparent:true,opacity:0,fog:false}));
scene.add(stars);

