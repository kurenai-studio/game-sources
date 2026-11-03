/* ══════════════ 16 · the frame ══════════════ */
let fps=60, fpsAcc=0, fpsN=0, fpsT=0, sagT=0, looping=true;
function onQualityChanged(quiet){
  if(sceneryData) rebuildScenery();
  if(mode==='run') buildPop();
  const qs=document.getElementById('detail');
  if(qs)[...qs.children].forEach(b=>b.setAttribute('aria-pressed',
    String(b.dataset.q===(QUALITY.auto?'auto':QUALITY.name))));
  if(!quiet) say('Detail set to '+QUALITY.now.label.toLowerCase()+'.');
}
function stepDown(){
  const order=['high','mid','low'];
  const i=order.indexOf(QUALITY.name);
  if(i<0||i>=order.length-1) return false;
  applyQuality(order[i+1],true);
  say('Frames were dropping, so the detail went down to '+QUALITY.now.label.toLowerCase()+
      '. Set it yourself under Detail if you would rather.');
  return true;
}

let last=performance.now();
function frame(now){
  if(!looping) return;
  requestAnimationFrame(frame);
  const dt=clamp((now-last)/1000,0,0.05); last=now;
  perf+=dt;

  /* rolling frame rate, and an automatic climb-down if it sags */
  if(dt>0){ fpsAcc+=1/dt; fpsN++; fpsT+=dt; }
  if(fpsT>=0.5){ fps=fpsAcc/fpsN; fpsAcc=0; fpsN=0; fpsT=0; }
  if(QUALITY.auto&&fps<38){ sagT+=dt; if(sagT>3){ sagT=-6; stepDown(); } }
  else sagT=Math.max(0,sagT-dt*0.5);

  if(sculpting){
    const m=PIECES[tool].sculpt;
    let rate=(m==='raise'||m==='lower')?5.5*dt:3.0*dt;
    if(sculpting.fine) rate*=0.35;                 // shift during a stroke, for fine work
    sculpt(sculpting.x,sculpting.z,brush,m,rate,sculpting.level);
  }
  if(!photo){
    const fast=(keys.ShiftLeft||keys.ShiftRight)?2.8:1;
    const sp=cam.dist*0.62*dt*fast;
    let f=0,r=0;
    if(keys.KeyW) f+=1; if(keys.KeyS) f-=1;
    if(keys.KeyD) r+=1; if(keys.KeyA) r-=1;
    if(f||r){
      const cy=Math.cos(cam.yaw),sy=Math.sin(cam.yaw);
      cam.tx+=(-sy*f+cy*r)*sp; cam.tz+=(-cy*f-sy*r)*sp;
      cam.tx=clamp(cam.tx,-HALF,HALF); cam.tz=clamp(cam.tz,-HALF,HALF);
      applyCam();
    }
    if(keys.KeyQ||keys.KeyE){
      cam.yaw+=((keys.KeyE?1:0)-(keys.KeyQ?1:0))*1.25*dt*fast; applyCam();
    }
  }else{
    camAuto+=dt;
    cam.yaw+=dt*0.045;
    cam.pitch=clamp(cam.pitch+Math.sin(camAuto*0.12)*dt*0.012,0.12,1.2);
    applyCam();
  }

  const simDt=(mode==='run'&&running)?dt*Math.min(pace,3.2):0;
  world.update(dt,simDt);

  hud(dt);
  renderer.render(scene,camera);
  settleShaderChecks();
}
addEventListener('resize',()=>{
  camera.aspect=innerWidth/innerHeight; camera.updateProjectionMatrix();
  renderer.setSize(innerWidth,innerHeight);
});
/* a hidden tab should cost nothing, and should not wake to a one-minute delta */
document.addEventListener('visibilitychange',()=>{
  Music.setPaused(document.hidden);
  if(document.hidden){ looping=false; }
  else if(!looping){ looping=true; last=performance.now(); requestAnimationFrame(frame); }
});


