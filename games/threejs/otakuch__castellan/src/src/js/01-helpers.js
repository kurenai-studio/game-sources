/* ══════════════ 0 · helpers ══════════════ */
const T=THREE, PI=Math.PI, TAU=PI*2;
const rnd=(a,b)=>a+Math.random()*(b-a);
const clamp=(v,a,b)=>v<a?a:v>b?b:v;
const lerp=(a,b,t)=>a+(b-a)*t;
const smooth=(e0,e1,x)=>{const t=clamp((x-e0)/(e1-e0),0,1);return t*t*(3-2*t);};
const pick=a=>a[Math.floor(Math.random()*a.length)];
function angDiff(a,b){let d=(b-a)%TAU; if(d>PI)d-=TAU; if(d<-PI)d+=TAU; return d;}

const M={};
function mat(n,hex,o){
  if(M[n]) return M[n];
  const s=(typeof SURFACE!=='undefined')?SURFACE[n]:null;
  const p=Object.assign({color:hex,roughness:s?s[3]:0.92,metalness:s&&s[2]===0.85?0.55:0.0},o||{});
  const m=new T.MeshStandardMaterial(p);
  if(s&&s[0]&&TEX[s[0]]){ m.map=TEX[s[0]]; triplanar(m,TEX[s[0]].userData.world*s[1],s[2]); }
  M[n]=m; return m;
}
const GEO={};
function cache(k,make){ let g=GEO[k]; if(!g){ g=make(); g.userData.cached=true; GEO[k]=g; } return g; }
function bgeo(w,h,d){return cache('b'+w+'|'+h+'|'+d,()=>new T.BoxGeometry(w,h,d));}
function cgeo(rt,rb,h,s){return cache('c'+rt+'|'+rb+'|'+h+'|'+s,()=>new T.CylinderGeometry(rt,rb,h,s));}
function kgeo(r,h,s){return cache('k'+r+'|'+h+'|'+s,()=>new T.ConeGeometry(r,h,s));}
function igeo(r,d){return cache('i'+r+'|'+d,()=>new T.IcosahedronGeometry(r,d||0));}
/* pieces come and go constantly, so give back what is not shared */
function disposeTree(o){
  o.traverse(n=>{
    if(n.isInstancedMesh) n.dispose();
    if(n.isMesh&&n.geometry&&!n.geometry.userData.cached) n.geometry.dispose();
  });
}
function box(w,h,d,m,x,y,z){const b=new T.Mesh(bgeo(w,h,d),m); b.position.set(x||0,y||0,z||0); return b;}
/* one draw call for a repeated shape — merlons, furrows, posts, orchard trees */
const _m4=new T.Matrix4(),_q=new T.Quaternion(),_v=new T.Vector3(),_s=new T.Vector3(),_e=new T.Euler();
function instanced(geo,material,list){
  const im=new T.InstancedMesh(geo,material,list.length);
  list.forEach((t,i)=>{
    _e.set(t.rx||0,t.ry||0,t.rz||0); _q.setFromEuler(_e);
    _v.set(t.x||0,t.y||0,t.z||0); _s.setScalar(t.s===undefined?1:t.s);
    if(t.sx!==undefined) _s.set(t.sx,t.sy,t.sz);
    im.setMatrixAt(i,_m4.compose(_v,_q,_s));
  });
  im.instanceMatrix.needsUpdate=true;
  im.castShadow=true; im.receiveShadow=true;
  im.userData.shared=true;
  return im;
}
function cyl(rt,rb,h,s,m,x,y,z){const c=new T.Mesh(cgeo(rt,rb,h,s),m); c.position.set(x||0,y||0,z||0); return c;}
function cone(r,h,s,m,x,y,z){const c=new T.Mesh(kgeo(r,h,s),m); c.position.set(x||0,y||0,z||0); return c;}
function shadowy(g){ g.traverse(o=>{ if(o.isMesh){o.castShadow=true; o.receiveShadow=true;} }); return g; }

