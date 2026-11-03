import * as THREE from 'three';
import { RoundedBoxGeometry } from 'three/addons/geometries/RoundedBoxGeometry.js';
import { clueNeighbors, type Game } from './engine';
import { BoardGesture, type GestureAction, type TileHit } from './gestures';

const colors = ['#596fa2', '#558976', '#bc657a', '#8573ae', '#b07845', '#4e919c', '#7c7182', '#514454'];
export class BoardScene {
  private renderer: THREE.WebGLRenderer;
  private scene = new THREE.Scene();
  private camera = new THREE.OrthographicCamera();
  private board = new THREE.Group();
  private targets: THREE.Object3D[] = [];
  private ray = new THREE.Raycaster();
  private yaw = Math.PI / 4;
  private zoom = 1;
  private center = new THREE.Vector3();
  private observer: ResizeObserver;
  private tile = new RoundedBoxGeometry(.94, .34, .94, 2, .045);
  private cap = new RoundedBoxGeometry(.81, .055, .81, 2, .025);
  private materials = new Map<string, THREE.MeshStandardMaterial>();
  private dimmed = false;
  private textures = new Map<string, THREE.CanvasTexture>();
  private gesture = new BoardGesture();
  private game?: Game;
  private active = -1;
  private hold?: ReturnType<typeof setTimeout>;
  constructor(private host: HTMLElement, private action: (floor:number,index:number,flag:boolean,doubleTap?:boolean)=>void) {
    this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    this.renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.setClearColor(0xfaf8f5, 0);
    host.append(this.renderer.domElement);
    this.scene.add(new THREE.HemisphereLight(0xfffaf2, 0xc9b3c8, 1.9));
    const sun = new THREE.DirectionalLight(0xfff6e4, 2.1);
    sun.position.set(-6, 12, 5); sun.castShadow = true;
    sun.shadow.mapSize.set(2048, 2048);
    Object.assign(sun.shadow.camera, {left:-15,right:15,top:15,bottom:-15});
    sun.shadow.normalBias = .03;
    this.scene.add(sun, this.board);
    const ground = new THREE.Mesh(new THREE.PlaneGeometry(200,200), new THREE.ShadowMaterial({opacity:.08}));
    ground.rotation.x = -Math.PI/2; ground.position.y = -.65; ground.receiveShadow = true; this.scene.add(ground);
    this.observer = new ResizeObserver(()=>this.resize()); this.observer.observe(host);
    host.addEventListener('pointerdown', this.down);
    host.addEventListener('pointermove', this.move);
    host.addEventListener('pointerup', this.up);
    host.addEventListener('pointercancel', this.cancel);
    host.addEventListener('contextmenu', e=>e.preventDefault());
    window.addEventListener('blur', this.cancel);
    host.addEventListener('wheel', e=>{e.preventDefault();this.cancel();this.zoom=THREE.MathUtils.clamp(this.zoom-e.deltaY*.001,.75,1.65);this.resize();},{passive:false});
  }
  private material(color:string) {
    const key=color+(this.dimmed?':dim':'');
    if(!this.materials.has(key)) this.materials.set(key,new THREE.MeshStandardMaterial({color,roughness:.78,transparent:this.dimmed,opacity:this.dimmed ? .3 : 1,depthWrite:!this.dimmed}));
    return this.materials.get(key)!;
  }
  private mesh(geometry:THREE.BufferGeometry,color:string,parent:THREE.Object3D,x=0,y=0,z=0) {
    const m=new THREE.Mesh(geometry,this.material(color));m.position.set(x,y,z);m.castShadow=!this.dimmed;m.receiveShadow=true;parent.add(m);return m;
  }
  private label(text:string,color:string,parent:THREE.Object3D) {
    const key=text+color;
    if(!this.textures.has(key)) {
      const c=document.createElement('canvas');c.width=c.height=128;
      const ctx=c.getContext('2d')!;ctx.fillStyle=color;ctx.font=`bold ${text.length > 1 ? 55 : 86}px Arial`;ctx.textAlign='center';ctx.textBaseline='middle';ctx.fillText(text,64,69);
      const texture=new THREE.CanvasTexture(c);texture.colorSpace=THREE.SRGBColorSpace;this.textures.set(key,texture);
    }
    const m=new THREE.Mesh(new THREE.PlaneGeometry(.63,.63),new THREE.MeshBasicMaterial({map:this.textures.get(key),transparent:true,depthWrite:false,opacity:this.dimmed ? .35 : 1}));
    m.rotation.x=-Math.PI/2;m.position.y=.225;parent.add(m);
  }
  update(game:Game, active:number, exploded:boolean, inspected?:TileHit) {
    if (game !== this.game || active !== this.active) this.cancel();
    this.game = game; this.active = active;
    const source = inspected && game.cells[inspected.floor]?.[inspected.index]?.revealed
      && !game.cells[inspected.floor][inspected.index].mine ? inspected : undefined;
    const footprint = new Set(source ? clueNeighbors(game,source.floor,source.index).map(p=>`${p.floor}:${p.index}`) : []);
    this.board.traverse(o=>{if(o instanceof THREE.Mesh){if(o.geometry!==this.tile&&o.geometry!==this.cap)o.geometry.dispose();if(o.material instanceof THREE.MeshBasicMaterial)o.material.dispose();}else if(o instanceof THREE.Line){o.geometry.dispose();(o.material as THREE.Material).dispose();}});
    this.board.clear();this.targets=[];
    const {width,height,floors}=game.config;
    for(let f=0;f<floors;f++) {
      if(!exploded&&f!==active)continue;
      this.dimmed=f!==active;
      const floor=new THREE.Group();
      floor.position.set(exploded?(f-(floors-1)/2)*1.4:0,exploded?f*2.3:0,exploded?-(f-(floors-1)/2)*1.4:0);this.board.add(floor);
      game.cells[f].forEach((cell,i)=>{
        const group=new THREE.Group();group.position.set(i%width-(width-1)/2,0,Math.floor(i/width)-(height-1)/2);floor.add(group);
        const hit=game.exploded?.floor===f&&game.exploded.index===i;
        const mine=cell.mine&&(cell.revealed||game.status==='lost');
        const base=this.mesh(this.tile,hit?'#ca617b':cell.revealed?'#d8d8e5':f===active?'#dc91ac':'#dfb1bf',group);
        base.userData={floor:f,index:i,revealed:cell.revealed&&!cell.mine};if(f===active)this.targets.push(base);
        const selected=source?.floor===f&&source.index===i;
        const targeted=footprint.has(`${f}:${i}`);
        this.mesh(this.cap,hit?'#f18f9d':selected?'#efcf94':targeted?'#b8dbe0':cell.revealed?'#f4f0eb':f===active?'#f5bdce':'#efd5dc',group,0,.19);
        if(selected||targeted){
          const corners=[[-.43,-.43],[.43,-.43],[.43,.43],[-.43,.43]].map(([x,z])=>new THREE.Vector3(x,.235,z));
          const line=new THREE.LineLoop(new THREE.BufferGeometry().setFromPoints(corners),new THREE.LineBasicMaterial({color:selected?'#957035':'#477c90'}));group.add(line);
        }
        if(cell.flagged&&!mine) {
          this.mesh(new THREE.BoxGeometry(.045,.62,.045),'#94734d',group,0,.5);
          this.mesh(new THREE.BoxGeometry(.33,.24,.065),'#c95379',group,.14,.68);
          this.mesh(new THREE.BoxGeometry(.25,.045,.25),'#e9bc79',group,0,.25);
        } else if(mine) {
          this.mesh(new THREE.IcosahedronGeometry(.23,0),'#645773',group,0,.42);
          for(let a=0;a<4;a++){const s=this.mesh(new THREE.BoxGeometry(.08,.12,.08),'#e9d9d5',group,Math.cos(a*Math.PI/2)*.2,.44,Math.sin(a*Math.PI/2)*.2);s.rotation.z=a*Math.PI/2;}
          this.mesh(new THREE.BoxGeometry(.07,.14,.07),'#e9d9d5',group,0,.65);
        } else if(cell.revealed&&(cell.adjacent||cell.clueType==='above'||cell.clueType==='below')) {
          const arrow=cell.clueType==='above'?'↑':cell.clueType==='below'?'↓':'';
          this.label(`${arrow}${cell.adjacent}`,arrow?'#615486':colors[cell.adjacent-1]??'#514454',group);
        }
        else if(!cell.revealed) this.mesh(new THREE.BoxGeometry(.13,.025,.13),'#f9d5de',group,0,.23);
      });
    }
    const box=new THREE.Box3().setFromObject(this.board);box.getCenter(this.center);
    this.resize();
  }
  private resize() {
    const w=this.host.clientWidth,h=this.host.clientHeight;if(!w||!h)return;
    this.renderer.setSize(w,h);const aspect=w/h;
    this.camera.position.copy(this.center).add(new THREE.Vector3(Math.sin(this.yaw)*20,18,Math.cos(this.yaw)*20));this.camera.lookAt(this.center);this.camera.updateMatrixWorld();
    const box=new THREE.Box3().setFromObject(this.board);
    let extentX=1,extentY=1;
    for(const x of [box.min.x,box.max.x])for(const y of [box.min.y,box.max.y])for(const z of [box.min.z,box.max.z]){
      const p=new THREE.Vector3(x,y,z).applyMatrix4(this.camera.matrixWorldInverse);
      extentX=Math.max(extentX,Math.abs(p.x));extentY=Math.max(extentY,Math.abs(p.y));
    }
    const v=Math.max(extentY*2,extentX*2/aspect)*1.16/this.zoom;
    this.camera.left=-v*aspect/2;this.camera.right=v*aspect/2;this.camera.top=v/2;this.camera.bottom=-v/2;
    this.camera.near=.1;this.camera.far=150;this.camera.updateProjectionMatrix();this.render();
  }
  private render(){this.renderer.render(this.scene,this.camera);}
  private pick(x:number,y:number){const r=this.host.getBoundingClientRect();this.ray.setFromCamera(new THREE.Vector2((x-r.left)/r.width*2-1,-(y-r.top)/r.height*2+1),this.camera);return this.ray.intersectObjects(this.targets)[0]?.object.userData;}
  private apply(action:GestureAction|undefined){
    if(!action)return;
    if(action.type==='rotate'){this.yaw-=action.delta*.008;this.resize();}
    else if(action.type==='zoom'){this.zoom=THREE.MathUtils.clamp(this.zoom*action.ratio,.75,1.65);this.resize();}
    else this.action(action.tile.floor,action.tile.index,action.type==='flag',action.type==='chord');
  }
  private down=(e:PointerEvent)=>{
    if(e.button!==0&&e.button!==2)return;
    this.host.setPointerCapture(e.pointerId);clearTimeout(this.hold);
    const hit=this.pick(e.clientX,e.clientY) as TileHit|undefined;
    this.apply(this.gesture.down(e.pointerId,e.clientX,e.clientY,e.button,hit));
    if(e.button===0)this.hold=setTimeout(()=>{const action=this.gesture.hold();this.apply(action);if(action)navigator.vibrate?.(15);},480);
  };
  private move=(e:PointerEvent)=>{this.apply(this.gesture.move(e.pointerId,e.clientX,e.clientY));};
  private up=(e:PointerEvent)=>{clearTimeout(this.hold);this.apply(this.gesture.up(e.pointerId));};
  private cancel=()=>{clearTimeout(this.hold);this.gesture.cancel();};
  reset(){this.cancel();this.yaw=Math.PI/4;this.zoom=1;this.resize();}
}
