/* ══════════════ 1 · renderer, camera ══════════════ */
const SMALL=matchMedia('(pointer:coarse)').matches||innerWidth<760;
const renderer=new T.WebGLRenderer({antialias:!SMALL,powerPreference:'high-performance'});
renderer.setSize(innerWidth,innerHeight);
if(MODERN){ renderer.outputColorSpace=T.SRGBColorSpace; T.ColorManagement.enabled=true; }
else { renderer.outputEncoding=T.sRGBEncoding; }
renderer.shadowMap.enabled=true;
renderer.shadowMap.type=MODERN?T.PCFShadowMap:T.PCFSoftShadowMap;
if(MODERN){ renderer.toneMapping=T.ACESFilmicToneMapping; renderer.toneMappingExposure=1.15; }
/* ANGLE's D3D compiler emits X4122 constant-folding warnings for three's own
   depth-packing constants (255/256) on Windows. They are harmless and there is
   no way to keep the errors while dropping the warnings, so we check the shaders
   once at boot, report anything genuinely broken, and then go quiet. */
renderer.debug.checkShaderErrors=true;
renderer.debug.onShaderError=function(gl,prog,vs,fs){
  console.error('CASTELLAN: shader failed to link\n',
    gl.getShaderInfoLog(vs)||'',gl.getShaderInfoLog(fs)||'');
};
let shaderWatch=6;                       // frames to keep the checking on for
function settleShaderChecks(){
  if(shaderWatch<=0) return;
  if(--shaderWatch===0) renderer.debug.checkShaderErrors=false;
}
document.body.appendChild(renderer.domElement);

/* ── device tier + quality presets (adaptive, and overridable) ── */
const QUALITY={
  tiers:{
    low :{label:'Low',   dpr:1,   shadow:0,    seg:140, pop:16, beasts:14, birds:4,  smoke:16, scenery:520},
    mid :{label:'Medium',dpr:1.5, shadow:1024, seg:200, pop:32, beasts:28, birds:8,  smoke:40, scenery:1300},
    high:{label:'High',  dpr:2,   shadow:2048, seg:260, pop:48, beasts:46, birds:12, smoke:72, scenery:2600}
  },
  auto:true, name:'high', detected:'high', now:null
};
(function detectTier(){
  let score=0;
  const coarse=matchMedia('(pointer:coarse)').matches;
  const cores=navigator.hardwareConcurrency||4;
  const mem=navigator.deviceMemory||4;
  score+=cores>=8?2:(cores>=4?1:0);
  score+=mem>=8?2:(mem>=4?1:0);
  score+=coarse?0:2;
  score+=innerWidth*devicePixelRatio>2200?0:1;
  try{
    const gl=renderer.getContext();
    const dbg=gl.getExtension('WEBGL_debug_renderer_info');
    const name=dbg?String(gl.getParameter(dbg.UNMASKED_RENDERER_WEBGL)):'';
    if(/swiftshader|software|llvmpipe/i.test(name)) score-=4;
    if(/apple m\d|rtx|radeon rx|geforce/i.test(name)) score+=2;
  }catch(e){}
  QUALITY.detected=score>=6?'high':(score>=3?'mid':'low');
  QUALITY.name=QUALITY.detected;
  QUALITY.now=QUALITY.tiers[QUALITY.name];
})();
function applyQuality(name,quiet){
  QUALITY.name=name; QUALITY.now=QUALITY.tiers[name];
  const q=QUALITY.now;
  renderer.setPixelRatio(Math.min(devicePixelRatio,q.dpr));
  renderer.setSize(innerWidth,innerHeight);
  renderer.shadowMap.enabled=q.shadow>0;
  if(q.shadow>0){
    sunLight.shadow.mapSize.set(q.shadow,q.shadow);
    if(sunLight.shadow.map){ sunLight.shadow.map.dispose(); sunLight.shadow.map=null; }
  }
  sunLight.castShadow=q.shadow>0;
  if(typeof onQualityChanged==='function') onQualityChanged(quiet);
}

const scene=new T.Scene();
scene.fog=new T.FogExp2(0x9fc0dd,0.0011);
const camera=new T.PerspectiveCamera(46,innerWidth/innerHeight,0.6,1500);

const LX=MODERN?Math.PI:1;   // r155+ lights are physical: old values scale by ~PI
const PLX=MODERN?11:1;       // point lights moved to candela
const sunLight=new T.DirectionalLight(0xfff0dc,1.1*LX);
sunLight.castShadow=true;
sunLight.shadow.mapSize.set(2048,2048);
const shc=sunLight.shadow.camera;
shc.left=-64; shc.right=64; shc.top=64; shc.bottom=-64; shc.near=1; shc.far=260;
sunLight.shadow.bias=-0.0013;
scene.add(sunLight,sunLight.target);
const moonLight=new T.DirectionalLight(0x9fb6e0,0); scene.add(moonLight);
const hemi=new T.HemisphereLight(0xbcd8f2,0x4c4527,0.6*LX); scene.add(hemi);

const cam={yaw:0.58,pitch:0.50,dist:118,tx:0,ty:2,tz:-3};
function applyCam(){
  cam.pitch=clamp(cam.pitch,0.05,1.36);
  cam.dist=clamp(cam.dist,12,340);
  const cp=Math.cos(cam.pitch);
  camera.position.set(cam.tx+Math.sin(cam.yaw)*cp*cam.dist,
                      cam.ty+Math.sin(cam.pitch)*cam.dist,
                      cam.tz+Math.cos(cam.yaw)*cp*cam.dist);
  camera.lookAt(cam.tx,cam.ty,cam.tz);
}

