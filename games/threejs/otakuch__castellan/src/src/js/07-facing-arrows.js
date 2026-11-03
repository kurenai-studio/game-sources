/* ══════════════ 4 · arrows that show which way a thing faces ══════════════ */
const arrowGeo=(function(){
  const s=new T.Shape();
  s.moveTo(-0.30,1.15); s.lineTo(0.30,1.15); s.lineTo(0.30,-0.30);
  s.lineTo(0.85,-0.30); s.lineTo(0,-1.35); s.lineTo(-0.85,-0.30);
  s.lineTo(-0.30,-0.30); s.closePath();
  const g=new T.ShapeGeometry(s); g.rotateX(-PI/2); g.userData.cached=true;
  return g;
})();
const arrowMat=new T.MeshBasicMaterial({color:0xF0D488,transparent:true,opacity:0.95,
  side:T.DoubleSide,depthWrite:false});
const arrowMatDim=new T.MeshBasicMaterial({color:0xEADFC6,transparent:true,opacity:0.7,
  side:T.DoubleSide,depthWrite:false});
const arrowBack=new T.MeshBasicMaterial({color:0x1C1710,transparent:true,opacity:0.55,
  side:T.DoubleSide,depthWrite:false});
function arrow(x,z,ang,scale,dim){
  const g=new T.Group();
  const b=new T.Mesh(arrowGeo,arrowBack); b.scale.setScalar(1.24); b.position.y=-0.02; g.add(b);
  g.add(new T.Mesh(arrowGeo,dim?arrowMatDim:arrowMat));
  g.position.set(x,Math.max(ground(x,z),WATER+0.1)+0.24,z);
  g.rotation.y=ang; g.scale.setScalar(scale||2.0);
  return g;
}
const markers=new T.Group(); scene.add(markers);

