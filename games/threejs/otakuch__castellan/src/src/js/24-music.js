/* ══════════════ 17 · music ══════════════
   Nothing sampled: a bagpipe drone, a plucked psaltery, a recorder and a tabor,
   built out of oscillators and a Karplus-Strong string. The mode follows the
   season, the tempo and the instrumentation follow the hour.                  */
const Music=(function(){
  let ctx=null, master=null, droneGain=null, droneOsc=[], timer=null;
  let level=0.55, wanted=false, nextT=0, beat=0, bpm=104;
  let root=50, scale=[0,2,3,5,7,9,10], phrase=[], pIdx=0, clos=false;
  const KS={};
  const MODES={
    0:[0,2,3,5,7,9,10],   // spring  · dorian
    1:[0,2,4,5,7,9,10],   // summer  · mixolydian
    2:[0,2,3,5,7,8,10],   // harvest · aeolian
    3:[0,1,3,5,7,8,10]    // winter  · phrygian
  };
  const hz=m=>440*Math.pow(2,(m-69)/12);

  /* a plucked string, rendered once per pitch and cached */
  function pluck(m){
    const key=Math.round(m);
    if(KS[key]) return KS[key];
    const f=hz(key), sr=ctx.sampleRate, dur=2.2, N=(sr*dur)|0;
    const buf=ctx.createBuffer(1,N,sr), d=buf.getChannelData(0);
    const L=Math.max(2,Math.round(sr/f)), line=new Float32Array(L);
    for(let i=0;i<L;i++) line[i]=Math.random()*2-1;
    let idx=0, prev=0;
    for(let i=0;i<N;i++){
      const cur=line[idx];
      const v=(cur+prev)*0.5*0.9965;
      line[idx]=v; prev=cur;
      d[i]=v*Math.exp(-i/(sr*0.85));
      idx=(idx+1)%L;
    }
    KS[key]=buf; return buf;
  }
  function psaltery(m,t,g){
    const s=ctx.createBufferSource(); s.buffer=pluck(m);
    const gain=ctx.createGain(); gain.gain.value=g;
    const lp=ctx.createBiquadFilter(); lp.type='lowpass'; lp.frequency.value=3200;
    s.connect(lp); lp.connect(gain); gain.connect(master);
    s.start(t); s.stop(t+2.2);
  }
  /* recorder: triangle plus a soft octave, with breath at the front */
  function recorder(m,t,dur,g){
    const f=hz(m);
    const o=ctx.createOscillator(); o.type='triangle'; o.frequency.value=f;
    const o2=ctx.createOscillator(); o2.type='sine'; o2.frequency.value=f*2;
    const vib=ctx.createOscillator(); vib.type='sine'; vib.frequency.value=5.2;
    const vibG=ctx.createGain(); vibG.gain.value=f*0.007;
    vib.connect(vibG); vibG.connect(o.frequency);
    const g1=ctx.createGain(), g2=ctx.createGain(), out=ctx.createGain();
    g1.gain.value=0.7; g2.gain.value=0.18;
    out.gain.setValueAtTime(0.0001,t);
    out.gain.exponentialRampToValueAtTime(g,t+0.07);
    out.gain.setValueAtTime(g,t+dur*0.7);
    out.gain.exponentialRampToValueAtTime(0.0001,t+dur);
    o.connect(g1); o2.connect(g2); g1.connect(out); g2.connect(out); out.connect(master);
    o.start(t); o2.start(t); vib.start(t);
    o.stop(t+dur+0.05); o2.stop(t+dur+0.05); vib.stop(t+dur+0.05);
  }
  /* tabor: a skin thump and a little rattle */
  function tabor(t,strong){
    const N=(ctx.sampleRate*0.14)|0;
    const buf=ctx.createBuffer(1,N,ctx.sampleRate), d=buf.getChannelData(0);
    for(let i=0;i<N;i++) d[i]=(Math.random()*2-1)*Math.exp(-i/(N*0.16));
    const s=ctx.createBufferSource(); s.buffer=buf;
    const bp=ctx.createBiquadFilter(); bp.type='bandpass';
    bp.frequency.value=strong?190:340; bp.Q.value=1.1;
    const g=ctx.createGain(); g.gain.value=strong?0.30:0.13;
    s.connect(bp); bp.connect(g); g.connect(master); s.start(t);
    const o=ctx.createOscillator(); o.type='sine';
    o.frequency.setValueAtTime(strong?104:150,t);
    o.frequency.exponentialRampToValueAtTime(52,t+0.16);
    const og=ctx.createGain();
    og.gain.setValueAtTime(strong?0.34:0.15,t);
    og.gain.exponentialRampToValueAtTime(0.0001,t+0.2);
    o.connect(og); og.connect(master); o.start(t); o.stop(t+0.22);
  }
  function startDrone(){
    stopDrone();
    droneGain=ctx.createGain(); droneGain.gain.value=0.0001;
    const lp=ctx.createBiquadFilter(); lp.type='lowpass'; lp.frequency.value=760; lp.Q.value=0.7;
    droneGain.connect(lp); lp.connect(master);
    [[root-12,-5],[root-12,5],[root-5,0]].forEach(p=>{      // root and its fifth
      const o=ctx.createOscillator(); o.type='sawtooth';
      o.frequency.value=hz(p[0]); o.detune.value=p[1];
      const g=ctx.createGain(); g.gain.value=p[0]===root-5?0.16:0.13;
      o.connect(g); g.connect(droneGain); o.start();
      droneOsc.push(o);
    });
    droneGain.gain.exponentialRampToValueAtTime(0.34,ctx.currentTime+2.5);
  }
  function stopDrone(){
    droneOsc.forEach(o=>{ try{o.stop();}catch(e){} });
    droneOsc=[]; droneGain=null;
  }

  /* an estampie-ish phrase: eight beats, ending open, then closed */
  function newPhrase(){
    const pats=[[2,2,2,2],[2,1,1,2,2],[1,1,2,2,2],[2,2,1,1,1,1],[3,1,2,2],[2,2,4]];
    const rh=pats[(Math.random()*pats.length)|0];
    let deg=clos?0:4;
    phrase=rh.map((len,i)=>{
      const last=(i===rh.length-1);
      if(last) deg=clos?0:1;
      else{
        const step=[-2,-1,-1,0,1,1,2][(Math.random()*7)|0];
        deg=clamp(deg+step,-1,7);
      }
      return {len:len,deg:deg,accent:i===0};
    });
    clos=!clos;
    pIdx=0;
  }
  function pitchOf(deg){
    let d=deg, oct=0;
    while(d<0){ d+=7; oct--; }
    while(d>6){ d-=7; oct++; }
    return root+12+scale[d]+oct*12;
  }

  /* what the hour asks for */
  function texture(){
    const h=hour;
    if(h<5.0||h>=21.5) return {tempo:70,mel:0,pluck:0.5,drum:0,gain:0.55};
    if(h<7.5)          return {tempo:84,mel:0.5,pluck:0.7,drum:0,gain:0.75};
    if(h<17.5)         return {tempo:112,mel:1,pluck:1,drum:1,gain:1};
    if(h<19.8)         return {tempo:96,mel:0.8,pluck:1,drum:0.5,gain:0.9};
    return {tempo:78,mel:0.3,pluck:0.7,drum:0,gain:0.65};
  }
  function step(t){
    const tx=texture();
    bpm=tx.tempo;
    const inBar=beat%8;
    if(tx.drum&&inBar%2===0) tabor(t,inBar===0||inBar===4);
    if(tx.drum>0.7&&inBar===6) tabor(t,false);
    if(!phrase.length||pIdx>=phrase.length) newPhrase();
    const note=phrase[pIdx];
    if(note.cursor===undefined) note.cursor=0;
    if(note.cursor===0){
      const m=pitchOf(note.deg);
      const dur=note.len*(30/bpm);
      if(Math.random()<tx.pluck) psaltery(m,t,(note.accent?0.34:0.24)*tx.gain);
      if(Math.random()<tx.mel) recorder(m,t,dur*0.92,0.09*tx.gain);
      if(note.accent&&Math.random()<tx.mel*0.6) psaltery(m-12,t,0.16*tx.gain);
    }
    note.cursor++;
    if(note.cursor>=note.len){ note.cursor=0; pIdx++; }
  }
  function tick(){
    if(!ctx) return;
    const ahead=ctx.currentTime+0.6;
    let guard=0;
    while(nextT<ahead&&guard++<32){
      step(nextT);
      beat++;
      nextT+=30/bpm;
    }
  }

  return {
    get on(){ return wanted&&level>0; },
    /* must be called from a click: browsers will not start audio otherwise */
    start(v){
      if(v!==undefined) level=v;
      wanted=true;
      if(!ctx){
        const AC=window.AudioContext||window.webkitAudioContext;
        if(!AC) return false;
        ctx=new AC();
        master=ctx.createGain(); master.gain.value=0;
        const cmp=ctx.createDynamicsCompressor();
        cmp.threshold.value=-16; cmp.ratio.value=3;
        master.connect(cmp); cmp.connect(ctx.destination);
        nextT=ctx.currentTime+0.15; beat=0;
      }
      if(ctx.state==='suspended') ctx.resume();
      this.season(season);
      if(!droneOsc.length) startDrone();
      master.gain.cancelScheduledValues(ctx.currentTime);
      master.gain.setValueAtTime(Math.max(master.gain.value,0.0001),ctx.currentTime);
      master.gain.exponentialRampToValueAtTime(Math.max(level,0.0001),ctx.currentTime+1.2);
      if(!timer) timer=setInterval(tick,110);
      return true;
    },
    stop(){
      wanted=false;
      if(!ctx) return;
      master.gain.cancelScheduledValues(ctx.currentTime);
      master.gain.setValueAtTime(master.gain.value,ctx.currentTime);
      master.gain.exponentialRampToValueAtTime(0.0001,ctx.currentTime+0.9);
      setTimeout(()=>{ if(!wanted){ clearInterval(timer); timer=null; stopDrone(); } },1100);
    },
    setLevel(v){
      level=v;
      if(v<=0){ this.stop(); return; }
      if(!wanted){ this.start(v); return; }
      master.gain.cancelScheduledValues(ctx.currentTime);
      master.gain.setValueAtTime(master.gain.value,ctx.currentTime);
      master.gain.exponentialRampToValueAtTime(Math.max(v,0.0001),ctx.currentTime+0.4);
    },
    /* the season chooses the mode, and the drone retunes to it */
    season(s){
      scale=MODES[s]||MODES[1];
      const newRoot=[50,50,48,47][s]||50;      // D, D, C, B — winter sits lowest
      if(newRoot!==root){
        root=newRoot;
        if(droneOsc.length&&wanted) startDrone();
      }
      phrase=[];
    },
    setPaused(p){
      if(!ctx||!wanted) return;
      if(p&&ctx.state==='running') ctx.suspend();
      if(!p&&ctx.state==='suspended') ctx.resume();
    }
  };
})();


