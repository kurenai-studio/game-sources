import * as THREE from 'three';

const socket = io();
const $ = id => document.getElementById(id);
const menu = $('menu'), lobby = $('lobby'), hud = $('hud'), result = $('result');
let scene, camera, renderer, clock, localId = null, roomCode = null, gameState = null, running = false;
let myCart = null, carts = new Map(), bullets = new Map(), arenaGroup = null;
let keys = {}, mouse = { x: 0, y: 0 }, aimYaw = 0, fireHeld = false, moveTouch = {x:0,y:0}, aimTouch = {x:0,y:0}, touchFire = false;
let lastInputAt = 0, toastTimer;
const raycaster = new THREE.Raycaster(), pointer = new THREE.Vector2(), groundPlane = new THREE.Plane(new THREE.Vector3(0,1,0),0);

function showToast(message){$('toast').textContent=message;$('toast').classList.add('show');clearTimeout(toastTimer);toastTimer=setTimeout(()=>$('toast').classList.remove('show'),2200)}
function showOnly(which){[menu,lobby,hud,result].forEach(el=>el.classList.add('hidden'));which.classList.remove('hidden')}
function setError(message){$('menuError').textContent=message||''}
function init3D(){
  if(renderer)return;
  scene=new THREE.Scene();scene.background=new THREE.Color(0x91b6c8);scene.fog=new THREE.Fog(0x91b6c8,85,180);
  camera=new THREE.PerspectiveCamera(65,innerWidth/innerHeight,.1,220);
  renderer=new THREE.WebGLRenderer({antialias:true});renderer.setPixelRatio(Math.min(devicePixelRatio,1.8));renderer.setSize(innerWidth,innerHeight);renderer.shadowMap.enabled=false;renderer.outputColorSpace=THREE.SRGBColorSpace;$('game').appendChild(renderer.domElement);
  scene.add(new THREE.HemisphereLight(0xe5f5ff,0x52634b,2.0));
  const sun=new THREE.DirectionalLight(0xfff1d5,2.2);sun.position.set(-25,45,20);sun.castShadow=false;scene.add(sun);
  buildArena();clock=new THREE.Clock();window.addEventListener('resize',onResize);renderer.domElement.addEventListener('pointermove',onPointerMove);renderer.domElement.addEventListener('pointerdown',e=>{if(e.pointerType==='mouse'&&e.button===0)fireHeld=true});window.addEventListener('pointerup',e=>{if(e.pointerType==='mouse')fireHeld=false});animate();
}
function buildArena(){
  arenaGroup=new THREE.Group();scene.add(arenaGroup);
  const floor=new THREE.Mesh(new THREE.PlaneGeometry(110,110),new THREE.MeshStandardMaterial({color:0x668b58,roughness:1,side:THREE.DoubleSide}));floor.rotation.x=-Math.PI/2;floor.receiveShadow=true;arenaGroup.add(floor);
  const road=new THREE.Mesh(new THREE.PlaneGeometry(58,58),new THREE.MeshStandardMaterial({color:0x59636b,roughness:.95,side:THREE.DoubleSide}));road.rotation.x=-Math.PI/2;road.position.y=.015;arenaGroup.add(road);
  const grid=new THREE.GridHelper(58,29,0x8b969b,0x77848a);grid.position.y=.04;arenaGroup.add(grid);
  const lineMat=new THREE.MeshStandardMaterial({color:0xe4d99a});
  for(let i=-24;i<=24;i+=8){const dash=new THREE.Mesh(new THREE.BoxGeometry(.18,.025,3.2),lineMat);dash.position.set(i,.06,0);arenaGroup.add(dash)}
  const wallMat=new THREE.MeshStandardMaterial({color:0x35434a,roughness:.9});
  [[0,-30,60,2],[0,30,60,2],[-30,0,2,60],[30,0,2,60]].forEach(([x,z,w,d])=>{const wall=new THREE.Mesh(new THREE.BoxGeometry(w,2.3,d),wallMat);wall.position.set(x,1.15,z);wall.castShadow=true;wall.receiveShadow=true;arenaGroup.add(wall)});
  const obstacleMat=new THREE.MeshStandardMaterial({color:0x9c7650,roughness:1});
  [[-12,-10],[12,10],[-13,12],[13,-12],[0,17],[0,-17]].forEach(([x,z],i)=>{const rock=new THREE.Mesh(new THREE.DodecahedronGeometry(i%2?2.1:1.6,0),obstacleMat);rock.position.set(x,1,z);rock.scale.y=1.2;rock.castShadow=true;rock.receiveShadow=true;arenaGroup.add(rock)});
  const treeMat=new THREE.MeshStandardMaterial({color:0x2f6848});const trunkMat=new THREE.MeshStandardMaterial({color:0x705039});
  for(let i=0;i<18;i++){const a=i/18*Math.PI*2;const x=Math.cos(a)*37,z=Math.sin(a)*37;const trunk=new THREE.Mesh(new THREE.CylinderGeometry(.35,.5,2.5,7),trunkMat);trunk.position.set(x,1.25,z);arenaGroup.add(trunk);const top=new THREE.Mesh(new THREE.ConeGeometry(2.2,5,7),treeMat);top.position.set(x,4,z);top.castShadow=true;arenaGroup.add(top)}
}
function makeCart(color){
  const root=new THREE.Group();const bodyMat=new THREE.MeshStandardMaterial({color,roughness:.48,metalness:.08});const dark=new THREE.MeshStandardMaterial({color:0x202a35,roughness:.8});const glass=new THREE.MeshStandardMaterial({color:0x9edcff,metalness:.3,roughness:.2});
  const chassis=new THREE.Mesh(new THREE.BoxGeometry(2.25,.62,3.25),bodyMat);chassis.position.y=.85;chassis.castShadow=true;chassis.receiveShadow=true;root.add(chassis);
  const nose=new THREE.Mesh(new THREE.BoxGeometry(1.5,.35,.8),bodyMat);nose.position.set(0,.72,1.7);root.add(nose);
  const seat=new THREE.Mesh(new THREE.BoxGeometry(1.05,.75,1.05),dark);seat.position.set(0,1.35,-.35);root.add(seat);
  const windshield=new THREE.Mesh(new THREE.BoxGeometry(1.25,.48,.12),glass);windshield.position.set(0,1.55,.38);root.add(windshield);
  for(const x of [-1.13,1.13])for(const z of [-1,1]){const wheel=new THREE.Mesh(new THREE.CylinderGeometry(.48,.48,.35,16),dark);wheel.rotation.z=Math.PI/2;wheel.position.set(x,.52,z);wheel.castShadow=true;root.add(wheel)}
  const gun=new THREE.Group();const barrel=new THREE.Mesh(new THREE.CylinderGeometry(.16,.2,1.15,10),dark);barrel.rotation.x=Math.PI/2;barrel.position.set(0,1.5,1.0);gun.add(barrel);const mount=new THREE.Mesh(new THREE.BoxGeometry(.55,.2,.6),dark);mount.position.set(0,1.27,.4);gun.add(mount);root.add(gun);root.userData.gun=gun;
  const marker=new THREE.Mesh(new THREE.CylinderGeometry(.12,.12,.12,12),new THREE.MeshStandardMaterial({color:0xffffff,emissive:color,emissiveIntensity:1.3}));marker.position.set(0,2.1,0);root.add(marker);
  return root;
}
function ensureCart(p){let cart=carts.get(p.id);if(!cart){cart=makeCart(p.color||0x36a2ff);scene.add(cart);carts.set(p.id,cart)}return cart}
function onResize(){if(!renderer)return;camera.aspect=innerWidth/innerHeight;camera.updateProjectionMatrix();renderer.setSize(innerWidth,innerHeight)}
function onPointerMove(e){const rect=renderer.domElement.getBoundingClientRect();pointer.x=((e.clientX-rect.left)/rect.width)*2-1;pointer.y=-((e.clientY-rect.top)/rect.height)*2+1;mouse.x=e.clientX;mouse.y=e.clientY}
function updateAim(){if(!myCart)return;raycaster.setFromCamera(pointer,camera);const target=new THREE.Vector3();if(raycaster.ray.intersectPlane(groundPlane,target)){const dx=target.x-myCart.position.x,dz=target.z-myCart.position.z;if(Math.hypot(dx,dz)>.5)aimYaw=Math.atan2(dx,dz)}if(Math.hypot(aimTouch.x,aimTouch.y)>.2)aimYaw=myCart.rotation.y+Math.atan2(-aimTouch.x,-aimTouch.y)}
function updateCamera(dt){if(!myCart)return;const yaw=myCart.rotation.y;const distance=14;const behind=new THREE.Vector3(-Math.sin(yaw)*distance,10.5,-Math.cos(yaw)*distance);const desired=myCart.position.clone().add(behind);camera.position.lerp(desired,1-Math.pow(.0005,dt));const ahead=new THREE.Vector3(Math.sin(yaw)*2.2,1.1,Math.cos(yaw)*2.2);const look=myCart.position.clone().add(ahead);camera.lookAt(look)}
function animate(){requestAnimationFrame(animate);if(!renderer)return;const dt=Math.min(clock.getDelta(),.05);if(running&&myCart){updateAim();updateCamera(dt);sendInput()}renderer.render(scene,camera)}
function sendInput(){const now=performance.now();if(now-lastInputAt<33)return;lastInputAt=now;let forward=0,turn=0;if(keys.KeyW||keys.ArrowUp)forward+=1;if(keys.KeyS||keys.ArrowDown)forward-=1;if(keys.KeyA||keys.ArrowLeft)turn+=1;if(keys.KeyD||keys.ArrowRight)turn-=1;forward=Math.max(-1,Math.min(1,forward+(-moveTouch.y)));turn=Math.max(-1,Math.min(1,turn+moveTouch.x));socket.emit('input',{forward,turn,aimYaw,fire:fireHeld||touchFire})}
function updateSnapshot(state){gameState=state;if(!state)return;for(const p of state.players){const cart=ensureCart(p);cart.position.set(p.x,0,p.z);cart.rotation.y=p.yaw;if(p.id===localId)myCart=cart;const gun=cart.userData.gun;if(gun)gun.rotation.y=p.aimYaw-p.yaw;}
  const active=new Set(state.players.map(p=>p.id));for(const [id,obj] of carts)if(!active.has(id)){scene.remove(obj);carts.delete(id)}
  const bulletActive=new Set();for(const b of state.bullets||[]){bulletActive.add(b.id);let mesh=bullets.get(b.id);if(!mesh){mesh=new THREE.Mesh(new THREE.SphereGeometry(.22,10,8),new THREE.MeshStandardMaterial({color:0xffe08a,emissive:0xffa52c,emissiveIntensity:1.5}));scene.add(mesh);bullets.set(b.id,mesh)}mesh.position.set(b.x,.95,b.z)}for(const [id,obj] of bullets)if(!bulletActive.has(id)){scene.remove(obj);bullets.delete(id)}
  const me=state.players.find(p=>p.id===localId),op=state.players.find(p=>p.id!==localId);if(me){$('myName').textContent=me.name;$('myHealth').style.width=me.health+'%';$('myHealthText').textContent=Math.ceil(me.health)+' HP'}if(op){$('opName').textContent=op.name;$('opHealth').style.width=op.health+'%';$('opHealthText').textContent=Math.ceil(op.health)+' HP'}$('timer').textContent=formatTime(state.timeLeft);}
function formatTime(s){const n=Math.ceil(s);return String(Math.floor(n/60)).padStart(2,'0')+':'+String(n%60).padStart(2,'0')}
function enterGame(snapshot){init3D();showOnly(hud);running=true;updateSnapshot(snapshot);showToast('Match started — good luck!')}
function setLobby(snapshot){$('displayCode').textContent=roomCode||snapshot.code;const players=snapshot.players||[];$('lobbyPlayers').innerHTML='';for(let i=0;i<2;i++){const p=players[i];const div=document.createElement('div');div.className='playerChip '+(i===0?'blue':'red');div.innerHTML=`<span>${i===0?'BLUE TEAM':'RED TEAM'}</span><b>${p?escapeHtml(p.name):'Waiting...'}</b>`;$('lobbyPlayers').appendChild(div)}}
function escapeHtml(s){return String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}
$('createBtn').onclick=()=>{setError('');$('createBtn').disabled=true;socket.emit('createRoom',{name:$('nickname').value.trim()||'Player'},res=>{$('createBtn').disabled=false;if(!res?.ok)return setError(res?.error||'Could not create room.');localId=res.playerId;roomCode=res.code;setLobby(res.snapshot);showOnly(lobby)})};
$('joinBtn').onclick=()=>{setError('');socket.emit('joinRoom',{code:$('roomCode').value,name:$('nickname').value.trim()||'Player'},res=>{if(!res?.ok)return setError(res?.error||'Could not join room.');localId=res.playerId;roomCode=res.code;setLobby(res.snapshot);showOnly(lobby)})};
$('copyBtn').onclick=async()=>{try{await navigator.clipboard.writeText(roomCode);showToast('Room code copied')}catch{showToast('Room code: '+roomCode)}};
socket.on('lobbyUpdate',setLobby);socket.on('gameStarted',enterGame);socket.on('state',updateSnapshot);
socket.on('gameOver',data=>{running=false;showOnly(result);const won=data.winner===localId;$('resultTitle').textContent=won?'VICTORY':data.winner?'DEFEAT':'DRAW';$('resultText').textContent=data.reason==='elimination'?'A cart was destroyed.': 'Time is up.'});
socket.on('opponentDisconnected',()=>{running=false;showOnly(result);$('resultTitle').textContent='OPPONENT LEFT';$('resultText').textContent='Your opponent disconnected.'});
$('backBtn').onclick=()=>{socket.emit('leaveRoom');location.reload()};
window.addEventListener('keydown',e=>{keys[e.code]=true;if(['ArrowUp','ArrowDown','ArrowLeft','ArrowRight','Space'].includes(e.code))e.preventDefault()});window.addEventListener('keyup',e=>{keys[e.code]=false});
function bindStick(zoneId,stickId,onMove){const zone=$(zoneId),stick=$(stickId);let pointerId=null;zone.addEventListener('pointerdown',e=>{pointerId=e.pointerId;zone.setPointerCapture(pointerId);move(e)});zone.addEventListener('pointermove',e=>{if(e.pointerId===pointerId)move(e)});zone.addEventListener('pointerup',end);zone.addEventListener('pointercancel',end);function move(e){const r=zone.getBoundingClientRect(),cx=r.left+r.width/2,cy=r.top+r.height/2;let x=(e.clientX-cx)/(r.width/2),y=(e.clientY-cy)/(r.height/2);const m=Math.hypot(x,y);if(m>1){x/=m;y/=m}stick.style.transform=`translate(${x*30}px,${y*30}px)`;onMove(x,y)}function end(e){if(pointerId!==null&&e.pointerId!==pointerId)return;pointerId=null;stick.style.transform='';onMove(0,0)}}
bindStick('moveZone','moveStick',(x,y)=>moveTouch={x,y});bindStick('aimZone','aimStick',(x,y)=>aimTouch={x,y});
$('fireTouch').addEventListener('pointerdown',e=>{e.preventDefault();touchFire=true});['pointerup','pointercancel','pointerleave'].forEach(ev=>$('fireTouch').addEventListener(ev,()=>touchFire=false));
$('boostTouch').onclick=()=>showToast('Boosters will be added in a later update');
showOnly(menu);
