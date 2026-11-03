import { Canvas, useFrame, useThree } from '@react-three/fiber'
import { AdaptiveEvents, Edges, Html, OrbitControls, PerformanceMonitor } from '@react-three/drei'
import { Bloom, EffectComposer, SMAA, Vignette } from '@react-three/postprocessing'
import { useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react'
import * as THREE from 'three'
import type { Building, CameraMode, CitySignals, DistrictMood, FacadeStrategy, GraphicsSettings, Plaza, Tool, ViewMode } from './types'
import { CELL, GRID, PROGRAMS, TONES, TYPOLOGIES, lots } from './data'
import { controlDisabledReason } from './controlApplicability'

interface SceneProps {
  buildings: Building[]
  plazas: Plaza[]
  selectedId: string | null
  tool: Tool
  viewMode: ViewMode
  mood: DistrictMood
  cameraMode: CameraMode
  cameraRevision: number
  hour: number
  paused: boolean
  focusMode: boolean
  preview: boolean
  performanceKey: string
  graphics: GraphicsSettings
  signals: CitySignals
  onEffectiveQualityChange: (quality:RenderQuality)=>void
  onSelect: (id: string | null) => void
  onLot: (x: number, z: number) => void
  onDemolish: (id: string) => void
  onBuildingChange: (id:string, patch:Partial<Building>)=>void
  onEditStart: ()=>void
}

type Body = { x: number; y: number; z: number; w: number; h: number; d: number; ry?:number; facade?: boolean; kind?:'box'|'capsule'; role?:'mass'|'core'|'transfer'; branch?:boolean; crown?:boolean }
type RenderQuality = 'low' | 'balanced' | 'high'

const RENDER_PROFILES: Record<RenderQuality, {
  dpr: [number, number]
  shadowMap: number
  facadeFloors: number
  facadeBays: number
  cyberSegments: number
  accentLights: boolean
  microLights: boolean
}> = {
  low: { dpr: [.78, 1], shadowMap: 768, facadeFloors: 8, facadeBays: 4, cyberSegments: 2, accentLights: false, microLights: false },
  balanced: { dpr: [1, 1.3], shadowMap: 1024, facadeFloors: 11, facadeBays: 6, cyberSegments: 3, accentLights: true, microLights: false },
  high: { dpr: [1.15, 1.6], shadowMap: 1536, facadeFloors: 16, facadeBays: 8, cyberSegments: 4, accentLights: true, microLights: true },
}

const qualityDown = (quality: RenderQuality): RenderQuality => quality === 'high' ? 'balanced' : 'low'
const automaticQualityUp = (quality: RenderQuality): RenderQuality => quality === 'low' ? 'balanced' : quality
const hashText = (text: string) => [...text].reduce((sum, ch) => sum + ch.charCodeAt(0), 0)

const concreteShader = (shader: THREE.WebGLProgramParametersWithUniforms) => {
  shader.fragmentShader = shader.fragmentShader.replace(
    '#include <dithering_fragment>',
    `float concreteGrain = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898,78.233))) * 43758.5453);
    gl_FragColor.rgb *= 0.991 + concreteGrain * 0.018;
    #include <dithering_fragment>`
  )
}

let concreteTextureCanvas: HTMLCanvasElement | undefined
let sharedConcreteTexture: THREE.CanvasTexture | undefined
const getConcreteTextureCanvas = () => {
  if (typeof document === 'undefined') return undefined
  if (concreteTextureCanvas) return concreteTextureCanvas
  const size = 128
  const canvas = document.createElement('canvas')
  canvas.width = size
  canvas.height = size
  const ctx = canvas.getContext('2d')!
  const image = ctx.createImageData(size, size)
  for (let y = 0; y < size; y++) for (let x = 0; x < size; x++) {
    const i = (y * size + x) * 4
    const grain = Math.sin(x * .31 + y * .07) * 5 + Math.sin(y * .61) * 3 + ((x * 17 + y * 31) % 13) - 6
    const lift = (y % 32 < 1) ? -24 : 0
    const tie = ((x - 21) % 48 < 2 && (y - 15) % 32 < 2) ? -38 : 0
    const v = Math.max(150, Math.min(235, 218 + grain + lift + tie))
    image.data[i] = v
    image.data[i + 1] = v
    image.data[i + 2] = v
    image.data[i + 3] = 255
  }
  ctx.putImageData(image, 0, 0)
  concreteTextureCanvas = canvas
  return canvas
}

const getConcreteTexture=()=>{
  if(sharedConcreteTexture)return sharedConcreteTexture
  const canvas=getConcreteTextureCanvas()
  if(!canvas)return undefined
  const texture=new THREE.CanvasTexture(canvas)
  texture.wrapS=texture.wrapT=THREE.RepeatWrapping
  texture.repeat.set(2.2,2.2)
  texture.colorSpace=THREE.SRGBColorSpace
  texture.anisotropy=4
  sharedConcreteTexture=texture
  return texture
}

const viewColor = (b: Building, mode: ViewMode) => {
  if (mode === 'program') return PROGRAMS[b.program].color
  if (mode === 'structure') return b.structural === 'frame' ? '#91a7b8' : b.structural === 'walls' ? '#d4ad67' : '#a98ebd'
  if (mode === 'carbon') {
    const intensity = Math.min(1, b.height * b.width * b.depth / 48000)
    return new THREE.Color().lerpColors(new THREE.Color('#a7c97b'), new THREE.Color('#d64e3a'), intensity).getStyle()
  }
  if (mode === 'activity') {
    const energy = b.program === 'culture' || b.program === 'mixed' ? .9 : b.program === 'civic' ? .62 : .28
    return new THREE.Color().lerpColors(new THREE.Color('#25313c'), new THREE.Color('#e69a37'), energy).getStyle()
  }
  if (mode === 'daylight') {
    const access = Math.max(.12, 1 - b.depth / 38)
    return new THREE.Color().lerpColors(new THREE.Color('#3b4f69'), new THREE.Color('#e8c87b'), access).getStyle()
  }
  const material=new THREE.Color(TONES[b.tone].color)
  const livedWeathering=Math.min(100,b.weathering+(100-(b.condition??94))*.55+Math.min(160,b.age??0)*.12)
  material.offsetHSL(0,-livedWeathering*.00035,-livedWeathering*.0007)
  return material.getStyle()
}

type SceneBounds={x:number;z:number;radius:number;height:number}

function CameraRig({ mode, selected, revision, bounds, enabled=true }: { mode: CameraMode; selected?: Building; revision:number;bounds:SceneBounds; enabled?:boolean }) {
  const { camera,size } = useThree()
  const controls = useRef<any>(null)
  const keys = useRef(new Set<string>())

  useEffect(() => {
    const center=new THREE.Vector3(selected?.x??bounds.x,selected?Math.min(selected.height*.38,48):Math.max(8,Math.min(34,bounds.height*.24)),selected?.z??bounds.z)
    if (mode === 'aerial') {
      camera.position.set(center.x+8,Math.max(150,selected?(selected.height+150):bounds.radius*1.18),center.z+10)
    } else if (mode === 'street') {
      camera.position.set(center.x-24,3.2,center.z+42)
      center.y=7
    } else {
      const portraitPullback=selected&&size.width/Math.max(1,size.height)<.7?1.34:1
      const radius=selected?Math.max(58,Math.min(430,selected.height*1.42+Math.max(selected.width,selected.depth)*2.15))*portraitPullback:bounds.radius
      camera.position.set(center.x+radius*.5,center.y+Math.max(68,radius*.66),center.z+radius*.58)
    }
    if(controls.current){controls.current.target.copy(center);controls.current.update()}
    camera.lookAt(center)
  }, [mode, selected?.id, revision, camera,size.width,size.height,bounds.x,bounds.z,bounds.radius,bounds.height])

  const wasEnabled=useRef(enabled)
  useEffect(()=>{
    if(enabled&&!wasEnabled.current&&selected&&controls.current){
      controls.current.target.set(selected.x,Math.min(selected.height*.38,48),selected.z)
      controls.current.update()
    }
    wasEnabled.current=enabled
  },[enabled,selected?.x,selected?.z,selected?.height])

  useEffect(()=>{
    const down=(e:KeyboardEvent)=>keys.current.add(e.key.toLowerCase())
    const up=(e:KeyboardEvent)=>keys.current.delete(e.key.toLowerCase())
    window.addEventListener('keydown',down);window.addEventListener('keyup',up)
    return()=>{window.removeEventListener('keydown',down);window.removeEventListener('keyup',up)}
  },[])

  useFrame(({clock},delta) => {
    if(!enabled)return
    if(mode==='cinematic'){
      const t=clock.getElapsedTime()*.075
      const center=new THREE.Vector3(selected?.x??bounds.x,selected?selected.height*.28:Math.max(10,bounds.height*.22),selected?.z??bounds.z)
      const radius=selected?Math.max(76,Math.min(230,selected.height*1.35+Math.max(selected.width,selected.depth))):Math.max(92,bounds.radius*.92)
      camera.position.set(center.x+Math.cos(t)*radius,center.y+radius*.38+Math.sin(t*.43)*radius*.09,center.z+Math.sin(t)*radius)
      if(controls.current)controls.current.target.lerp(center,.08)
    }
    if(mode==='street'&&keys.current.size){
      const forward=new THREE.Vector3();camera.getWorldDirection(forward);forward.y=0;forward.normalize()
      const right=new THREE.Vector3(forward.z,0,-forward.x)
      const movement=new THREE.Vector3()
      if(keys.current.has('w'))movement.add(forward)
      if(keys.current.has('s'))movement.sub(forward)
      if(keys.current.has('d'))movement.add(right)
      if(keys.current.has('a'))movement.sub(right)
      if(movement.lengthSq()>0){movement.normalize().multiplyScalar(delta*22);camera.position.add(movement);controls.current?.target.add(movement)}
    }
    controls.current?.update()
  })

  return <OrbitControls ref={controls} makeDefault enabled={enabled&&mode!=='cinematic'} enableDamping dampingFactor={.07} enablePan zoomToCursor keyPanSpeed={28} panSpeed={1.25} rotateSpeed={.82} zoomSpeed={1.35} minDistance={mode === 'street' ? 2 : 7} maxDistance={650} maxPolarAngle={Math.PI*.495} minPolarAngle={.01} screenSpacePanning />
}

const clamp=(value:number,min:number,max:number)=>Math.max(min,Math.min(max,value))
const LOT_SURFACE_Y=.23
const LOT_DEPTH=.42
const LOT_CENTER_Y=LOT_SURFACE_Y-LOT_DEPTH/2
const SHORE_Z=-190
const buildingBase=(b:Building,cap=.28)=>Math.min(Math.max(0,b.pilotis),Math.max(0,b.height)*cap)
const roundTo=(value:number,step=.1)=>Math.round(value/step)*step

const MOOD_SCENES:Record<DistrictMood,{
  day:[string,string,string]
  night:[string,string,string]
  backgroundDay:string
  backgroundNight:string
  fogDay:string
  fogNight:string
  groundDay:string
  groundNight:string
  roadDay:string
  roadNight:string
  window:string
  windowAlt:string
  lamp:string
  accent:string
  bloom:number
  windowIntensity:number
  lampIntensity:number
}>={
  default:{day:['#5f91aa','#b7c3bc','#d0c2a5'],night:['#111a24','#24313c','#0d1216'],backgroundDay:'#b9b29f',backgroundNight:'#10171c',fogDay:'#b7c1b8',fogNight:'#10171c',groundDay:'#6f746d',groundNight:'#17201e',roadDay:'#777875',roadNight:'#3f423f',window:'#ffd89b',windowAlt:'#f6c16f',lamp:'#ffd19a',accent:'#d7ff43',bloom:.12,windowIntensity:.65,lampIntensity:18},
  cyberpunk:{day:['#243f54','#6c7f8f','#9b927d'],night:['#020509','#06111c','#020304'],backgroundDay:'#82919a',backgroundNight:'#02060d',fogDay:'#8e989e',fogNight:'#050f18',groundDay:'#4f5f60',groundNight:'#070d0e',roadDay:'#3f4b51',roadNight:'#090d12',window:'#38f6ff',windowAlt:'#d7ff43',lamp:'#ff386c',accent:'#d7ff43',bloom:.78,windowIntensity:.86,lampIntensity:34},
  green:{day:['#6f967e','#c2c9af','#c6b986'],night:['#0f1d18','#203b2e','#07120d'],backgroundDay:'#b9bea0',backgroundNight:'#0b1712',fogDay:'#b9c6ad',fogNight:'#112119',groundDay:'#697766',groundNight:'#12251c',roadDay:'#70766d',roadNight:'#29382e',window:'#c9f0a2',windowAlt:'#7fe083',lamp:'#c6ff9a',accent:'#7fe083',bloom:.32,windowIntensity:.8,lampIntensity:18},
  totalitarian:{day:['#65747b','#a7adb0','#c1bcae'],night:['#070a0d','#19222a','#050607'],backgroundDay:'#9fa4a5',backgroundNight:'#080b0e',fogDay:'#a6abad',fogNight:'#0c1116',groundDay:'#626a6b',groundNight:'#11171b',roadDay:'#5b6367',roadNight:'#181f23',window:'#8fa8b7',windowAlt:'#5f737d',lamp:'#a8bfd0',accent:'#9d111b',bloom:.18,windowIntensity:.56,lampIntensity:30},
  university:{day:['#688ca0','#c2bda8','#d0bd8f'],night:['#111827','#27304b','#100f12'],backgroundDay:'#b9b099',backgroundNight:'#111827',fogDay:'#b9b7aa',fogNight:'#1a2034',groundDay:'#6d7169',groundNight:'#1b2430',roadDay:'#7b6e5c',roadNight:'#313234',window:'#ffc86b',windowAlt:'#f0c65e',lamp:'#ffd58a',accent:'#7aa4e8',bloom:.35,windowIntensity:.95,lampIntensity:20},
}

const moodScene=(mood:DistrictMood)=>MOOD_SCENES[mood]??MOOD_SCENES.default

type GizmoDrag=(dx:number,dy:number,clientX?:number,clientY?:number,precision?:number)=>void
type GizmoKeyboardStep=(direction:-1|1)=>void
type AxisFallback='left'|'right'|'up'|'down'
const FORM_RAIL={void:.075,taper:.075,break:.06,repeat:.7,branch:.55,crown:.06} as const
const formatGizmoValue=(value:number)=>Number.isInteger(value)?String(value):value.toFixed(1)

function GizmoHandle({position,label,cursor='grab',shape='box',axis='x',color='#d7ff43',value,min,max,onDrag,onKeyboardStep,onStart,onManipulating}:{position:[number,number,number];label:string;cursor?:string;shape?:'box'|'sphere'|'diamond';axis?:'x'|'y'|'form'|'rotate'|'move';color?:string;value?:number;min?:number;max?:number;onDrag:GizmoDrag;onKeyboardStep?:GizmoKeyboardStep;onStart:(clientX?:number,clientY?:number)=>void;onManipulating:(active:boolean)=>void}){
  const dragging=useRef(false)
  const pointerId=useRef<number|null>(null)
  const labelRef=useRef<HTMLDivElement|null>(null)
  const [hovered,setHovered]=useState(false)
  const [active,setActive]=useState(false)
  const cleanup=useRef<(()=>void)|null>(null)
  useEffect(()=>()=>cleanup.current?.(),[])
  const begin=(clientX:number,clientY:number,id?:number)=>{
    if(dragging.current)return
    dragging.current=true;pointerId.current=id??null;setActive(true);onStart(clientX,clientY);onManipulating(true);document.body.style.cursor=cursor==='grab'?'grabbing':cursor
    const move=(event:PointerEvent)=>{if(dragging.current&&(pointerId.current===null||event.pointerId===pointerId.current)){
      const dx=event.clientX-clientX,dy=event.clientY-clientY,length=Math.hypot(dx,dy),stretch=Math.min(7,length*.22),scale=length?stretch/length:0
      labelRef.current?.style.setProperty('--drag-x',`${dx*scale}px`);labelRef.current?.style.setProperty('--drag-y',`${dy*scale}px`)
      onDrag(dx,dy,event.clientX,event.clientY,event.shiftKey?.2:1)
    }}
    const finish=(event?:Event)=>{if(!dragging.current||(event instanceof PointerEvent&&pointerId.current!==null&&event.pointerId!==pointerId.current))return;dragging.current=false;pointerId.current=null;labelRef.current?.style.setProperty('--drag-x','0px');labelRef.current?.style.setProperty('--drag-y','0px');setActive(false);onManipulating(false);document.body.style.cursor='default';window.removeEventListener('pointermove',move);window.removeEventListener('pointerup',finish);window.removeEventListener('pointercancel',finish);window.removeEventListener('blur',finish);cleanup.current=null}
    cleanup.current=finish
    window.addEventListener('pointermove',move);window.addEventListener('pointerup',finish);window.addEventListener('pointercancel',finish);window.addEventListener('blur',finish)
  }
  const testId=`gizmo-${label.split(' ')[0].toLowerCase()}`
  const controlName=label.split(' ')[0]
  const inferredRange:Record<string,[number,number]>={HEIGHT:[12,160],SPAN:[8,128],DEPTH:[8,96],CANTILEVER:[0,14],VOID:[0,70],TAPER:[0,65],BREAK:[0,100],REPEAT:[1,5],BRANCH:[0,8],CROWN:[0,100]}
  const range=inferredRange[controlName]??(axis==='rotate'?[0,359]:undefined)
  const sliderValue=value??(axis==='move'?undefined:Number(label.match(/-?\d+(?:\.\d+)?/)?.[0]))
  const glyph=axis==='move'?'+':axis==='y'?'↕':axis==='rotate'?'↻':axis==='form'?'◆':'↔'
  return <group position={position} scale={active?1.22:hovered?1.1:1}>
    <mesh
      onPointerDown={(e)=>{e.stopPropagation();const native=e.nativeEvent as PointerEvent;begin(native.clientX,native.clientY,native.pointerId)}}
      onPointerOver={e=>{e.stopPropagation();setHovered(true);if(!dragging.current)document.body.style.cursor=cursor}}
      onPointerOut={()=>{setHovered(false);if(!dragging.current)document.body.style.cursor='default'}} castShadow>
      {shape==='sphere'?<sphereGeometry args={[1.35,18,18]}/>:shape==='diamond'?<octahedronGeometry args={[1.55,0]}/>:<boxGeometry args={[2.15,2.15,2.15]}/>}<meshStandardMaterial color={color} emissive={color} emissiveIntensity={active?.75:.32} roughness={.42}/>
    </mesh>
    <Html center distanceFactor={50} position={[0,2.15,0]} style={{pointerEvents:'auto'}}><div ref={labelRef} data-testid={testId} role={sliderValue===undefined?'button':'slider'} aria-label={label} aria-valuemin={sliderValue===undefined?undefined:min??range?.[0]} aria-valuemax={sliderValue===undefined?undefined:max??range?.[1]} aria-valuenow={sliderValue} tabIndex={0} className={`morph-handle ${active?'dragging':''}`} style={{cursor,'--handle':color} as React.CSSProperties} onPointerEnter={()=>setHovered(true)} onPointerLeave={()=>setHovered(false)} onPointerDown={(e:any)=>{e.preventDefault();e.stopPropagation();e.currentTarget.setPointerCapture?.(e.pointerId);begin(e.clientX,e.clientY,e.pointerId)}} onKeyDown={(e:any)=>{const keys:Record<string,[number,number]>={ArrowUp:[0,-16],ArrowDown:[0,16],ArrowRight:[16,0],ArrowLeft:[-16,0]};const delta=keys[e.key];if(!delta)return;e.preventDefault();e.stopPropagation();onStart();if(onKeyboardStep){onKeyboardStep(e.key==='ArrowUp'||e.key==='ArrowRight'?1:-1);return}onDrag(delta[0],delta[1],undefined,undefined,e.shiftKey?.2:1)}}><span>{glyph}</span>{label}</div></Html>
  </group>
}

function MassingGizmo({b,onChange,onStart,onManipulating}:{b:Building;onChange:(patch:Partial<Building>)=>void;onStart:()=>void;onManipulating:(active:boolean)=>void}){
  const { camera,gl } = useThree()
  const dragStart=useRef<Building>(b)
  const dragCamera=useRef<THREE.Camera>(camera.clone())
  const dragRect=useRef<DOMRect|null>(null)
  const moveHit=useRef<THREE.Vector3|null>(null)
  const historyCaptured=useRef(false)
  const raycaster=useRef(new THREE.Raycaster())
  const ring=Math.max(b.width,b.depth)*.67
  const lowY=Math.max(2.2,buildingBase(b)*.45)
  const voidZ=-b.depth/2-2.2-b.voids*FORM_RAIL.void
  const taperX=-b.width/2-2.2-b.taper*FORM_RAIL.taper
  const breakZ=b.depth/2+3+b.articulation*FORM_RAIL.break
  const repeatZ=b.depth/2+3+(b.moduleDensity-1)*FORM_RAIL.repeat
  const branchZ=b.depth/2+3+b.branches*FORM_RAIL.branch
  const crownX=-Math.max(5,b.width*.18)-b.crown*FORM_RAIL.crown
  const canCantilever=!controlDisabledReason(b,'cantilever')
  const canVoid=!controlDisabledReason(b,'voids')
  const canTaper=!controlDisabledReason(b,'taper')
  const canBreak=!controlDisabledReason(b,'articulation')
  const canBranch=!controlDisabledReason(b,'branches')
  const canCrown=!controlDisabledReason(b,'crown')
  const beginDrag=()=>{
    dragStart.current={...b}
    camera.updateMatrixWorld(true)
    dragCamera.current=camera.clone()
    dragCamera.current.updateMatrixWorld(true)
    dragRect.current=gl.domElement.getBoundingClientRect()
    moveHit.current=null
    historyCaptured.current=false
  }
  const emitChange=(patch:Partial<Building>)=>{
    const start=dragStart.current
    const changed=(Object.keys(patch) as (keyof Building)[]).some(key=>patch[key]!==start[key])
    if(!changed)return
    if(!historyCaptured.current){historyCaptured.current=true;onStart()}
    onChange(patch)
  }
  const localToWorld=(point:[number,number,number],start=dragStart.current)=>new THREE.Vector3(...point)
    .applyAxisAngle(new THREE.Vector3(0,1,0),start.rotation*Math.PI/180)
    .add(new THREE.Vector3(start.x,LOT_SURFACE_Y,start.z))
  const toScreen=(point:THREE.Vector3)=>{
    const rect=dragRect.current
    if(!rect)return new THREE.Vector2()
    const projected=point.clone().project(dragCamera.current)
    return new THREE.Vector2((projected.x*.5+.5)*rect.width,(.5-projected.y*.5)*rect.height)
  }
  const worldPerPixel=(point:THREE.Vector3)=>{
    const rect=dragRect.current
    const frozen=dragCamera.current as THREE.PerspectiveCamera
    if(!rect)return .2
    const cameraPoint=point.clone().applyMatrix4(frozen.matrixWorldInverse)
    const depth=Math.max(.1,Math.abs(cameraPoint.z))
    return frozen.isPerspectiveCamera?2*depth*Math.tan(THREE.MathUtils.degToRad(frozen.fov)*.5)/Math.max(1,rect.height):depth*.0018
  }
  const axisProjection=(point:[number,number,number],axis:[number,number,number],fallback:AxisFallback='right')=>{
    const start=dragStart.current
    const origin=localToWorld(point,start)
    const worldAxis=new THREE.Vector3(...axis).applyAxisAngle(new THREE.Vector3(0,1,0),start.rotation*Math.PI/180).normalize()
    const reference=1.5
    const screenStart=toScreen(origin.clone().addScaledVector(worldAxis,-reference*.5))
    const screenEnd=toScreen(origin.clone().addScaledVector(worldAxis,reference*.5))
    let screenAxis=screenEnd.sub(screenStart)
    let pixelsPerWorld=screenAxis.length()/reference
    if(!Number.isFinite(pixelsPerWorld)||pixelsPerWorld<.65){
      const fallbackVectors:Record<AxisFallback,THREE.Vector2>={left:new THREE.Vector2(-1,0),right:new THREE.Vector2(1,0),up:new THREE.Vector2(0,-1),down:new THREE.Vector2(0,1)}
      screenAxis=fallbackVectors[fallback].clone()
      pixelsPerWorld=1/Math.max(.0001,worldPerPixel(origin))
    }
    screenAxis.normalize()
    return {screenAxis,pixelsPerWorld}
  }
  const axisTravel=(dx:number,dy:number,point:[number,number,number],axis:[number,number,number],precision=1,fallback:AxisFallback='right')=>{
    const {screenAxis,pixelsPerWorld}=axisProjection(point,axis,fallback)
    return (dx*screenAxis.x+dy*screenAxis.y)/Math.max(.0001,pixelsPerWorld)*precision
  }
  const discreteAxisValue=(startValue:number,dx:number,dy:number,point:[number,number,number],axis:[number,number,number],railStep:number,min:number,max:number,precision=1,fallback:AxisFallback='down')=>{
    const {screenAxis,pixelsPerWorld}=axisProjection(point,axis,fallback)
    const signedPixels=(dx*screenAxis.x+dy*screenAxis.y)*precision
    const pixelsPerStep=clamp(pixelsPerWorld*railStep,10,16)
    return Math.round(clamp(startValue+signedPixels/pixelsPerStep,min,max))
  }
  const groundPoint=(clientX?:number,clientY?:number)=>{
    const rect=dragRect.current
    if(clientX===undefined||clientY===undefined||!rect)return null
    const pointer=new THREE.Vector2((clientX-rect.left)/Math.max(1,rect.width)*2-1,-((clientY-rect.top)/Math.max(1,rect.height))*2+1)
    raycaster.current.setFromCamera(pointer,dragCamera.current)
    const ray=raycaster.current.ray
    if(Math.abs(ray.direction.y)<.12)return null
    const distance=(LOT_SURFACE_Y-ray.origin.y)/ray.direction.y
    return distance>0?ray.at(distance,new THREE.Vector3()):null
  }
  const beginMove=(clientX?:number,clientY?:number)=>{
    beginDrag()
    moveHit.current=groundPoint(clientX,clientY)
  }
  const moveFromDrag:GizmoDrag=(dx,dy,clientX,clientY,precision=1)=>{
    const start=dragStart.current
    const currentHit=groundPoint(clientX,clientY)
    let deltaX=0,deltaZ=0
    if(moveHit.current&&currentHit){
      deltaX=(currentHit.x-moveHit.current.x)*precision
      deltaZ=(currentHit.z-moveHit.current.z)*precision
    }else{
      const frozen=dragCamera.current
      const right=new THREE.Vector3().setFromMatrixColumn(frozen.matrixWorld,0);right.y=0
      const forward=new THREE.Vector3();frozen.getWorldDirection(forward);forward.y=0
      if(right.lengthSq()<.001)right.set(1,0,0);else right.normalize()
      if(forward.lengthSq()<.001)forward.set(0,0,-1);else forward.normalize()
      const meters=worldPerPixel(new THREE.Vector3(start.x,Math.min(start.height*.35,48),start.z))*precision
      deltaX=(right.x*dx-forward.x*dy)*meters;deltaZ=(right.z*dx-forward.z*dy)*meters
    }
    const angle=start.rotation*Math.PI/180,c=Math.abs(Math.cos(angle)),s=Math.abs(Math.sin(angle))
    const halfX=(c*(start.width+5)+s*(start.depth+5))/2,halfZ=(s*(start.width+5)+c*(start.depth+5))/2
    const siteEdge=(GRID-1)*CELL/2+(CELL-4.8)/2
    const limitX=Math.max(0,siteEdge-halfX),limitZ=Math.max(0,siteEdge-halfZ)
    emitChange({x:roundTo(clamp(start.x+deltaX,-limitX,limitX)),z:roundTo(clamp(start.z+deltaZ,-limitZ,limitZ))})
  }
  return <group>
    <group position={[0,.62,0]}>
      <mesh raycast={()=>null}><boxGeometry args={[Math.min(34,b.width+8),.08,.42]}/><meshBasicMaterial color="#ffffff" transparent opacity={.62}/></mesh>
      <mesh raycast={()=>null}><boxGeometry args={[.42,.08,Math.min(34,b.depth+8)]}/><meshBasicMaterial color="#ffffff" transparent opacity={.62}/></mesh>
      <mesh raycast={()=>null}><boxGeometry args={[Math.min(22,b.width+5),.07,Math.min(22,b.depth+5)]}/><meshBasicMaterial color="#d7ff43" transparent opacity={.12}/></mesh>
    </group>
    <GizmoHandle position={[0,3.25,0]} label={`MOVE ${Math.round(b.x)}, ${Math.round(b.z)}`} cursor="move" shape="box" axis="move" color="#ffffff" onStart={beginMove} onManipulating={onManipulating} onDrag={moveFromDrag}/>
    <mesh position={[0,b.height+1.7,0]}><cylinderGeometry args={[.055,.055,3.4,8]}/><meshBasicMaterial color="#d7ff43"/></mesh>
    <GizmoHandle position={[0,b.height+3.4,0]} label={`HEIGHT ${Math.round(b.height)}m`} cursor="ns-resize" shape="diamond" axis="y" onStart={beginDrag} onManipulating={onManipulating} onDrag={(dx,dy,_x,_y,p=1)=>{const s=dragStart.current,height=roundTo(clamp(s.height+axisTravel(dx,dy,[0,s.height+3.4,0],[0,1,0],p,'up')*1.1,12,160));emitChange({height,cores:height>110?Math.max(3,s.cores):height>58?Math.max(2,s.cores):s.cores})}}/>
    <mesh position={[b.width/2+1.05,lowY,0]} rotation={[0,0,Math.PI/2]}><cylinderGeometry args={[.045,.045,2.1,8]}/><meshBasicMaterial color="#d7ff43"/></mesh>
    <GizmoHandle position={[b.width/2+2.1,lowY,0]} label={`SPAN ${b.width.toFixed(1)}m`} color="#ffb35c" onStart={beginDrag} onManipulating={onManipulating} onDrag={(dx,dy,_x,_y,p=1)=>{const s=dragStart.current,width=roundTo(clamp(s.width+axisTravel(dx,dy,[s.width/2+2.1,Math.max(2.2,buildingBase(s)*.45),0],[1,0,0],p,'right')*2,8,128));emitChange({width,cores:width>76?Math.max(4,s.cores):width>44?Math.max(3,s.cores):width>34?Math.max(2,s.cores):s.cores})}}/>
    <mesh position={[0,lowY,b.depth/2+1.05]} rotation={[Math.PI/2,0,0]}><cylinderGeometry args={[.045,.045,2.1,8]}/><meshBasicMaterial color="#7fd9d0"/></mesh>
    <GizmoHandle position={[0,lowY,b.depth/2+2.1]} label={`DEPTH ${b.depth.toFixed(1)}m`} shape="sphere" axis="x" color="#69d8d0" onStart={beginDrag} onManipulating={onManipulating} onDrag={(dx,dy,_x,_y,p=1)=>{const s=dragStart.current;emitChange({depth:roundTo(clamp(s.depth+axisTravel(dx,dy,[0,Math.max(2.2,buildingBase(s)*.45),s.depth/2+2.1],[0,0,1],p,'down')*2,8,96))})}}/>
    {canCantilever&&<>{b.cantilever>.05&&<mesh raycast={()=>null} position={[b.width*.18+b.cantilever/2,b.height*.73,b.depth/2+1]}><boxGeometry args={[b.cantilever,.07,.07]}/><meshBasicMaterial color="#f18ac2" transparent opacity={.68}/></mesh>}<GizmoHandle position={[b.cantilever+b.width*.18,b.height*.73,b.depth/2+1]} label={`CANTILEVER ${b.cantilever.toFixed(1)}m`} shape="diamond" axis="form" color="#f18ac2" onStart={beginDrag} onManipulating={onManipulating} onDrag={(dx,dy,_x,_y,p=1)=>{const s=dragStart.current;emitChange({cantilever:roundTo(clamp(s.cantilever+axisTravel(dx,dy,[s.cantilever+s.width*.18,s.height*.73,s.depth/2+1],[1,0,0],p,'right'),0,14))})}}/></>}
    {canVoid&&<><mesh raycast={()=>null} position={[0,b.height*.52,(-b.depth/2+voidZ)/2]}><boxGeometry args={[.07,.07,Math.abs(voidZ+b.depth/2)]}/><meshBasicMaterial color="#8fe083" transparent opacity={.62}/></mesh><GizmoHandle position={[0,b.height*.52,voidZ]} label={`VOID ${formatGizmoValue(b.voids)}%`} shape="sphere" axis="form" color="#8fe083" onStart={beginDrag} onManipulating={onManipulating} onDrag={(dx,dy,_x,_y,p=1)=>{const s=dragStart.current,startZ=-s.depth/2-2.2-s.voids*FORM_RAIL.void;emitChange({voids:roundTo(clamp(s.voids+axisTravel(dx,dy,[0,s.height*.52,startZ],[0,0,-1],p,'up')/FORM_RAIL.void,0,70),.5)})}}/></>}
    {canTaper&&<><mesh raycast={()=>null} position={[(-b.width/2+taperX)/2,b.height*.82,0]}><boxGeometry args={[Math.abs(taperX+b.width/2),.07,.07]}/><meshBasicMaterial color="#b8a0ff" transparent opacity={.62}/></mesh><GizmoHandle position={[taperX,b.height*.82,0]} label={`TAPER ${formatGizmoValue(b.taper)}%`} shape="diamond" axis="form" color="#b8a0ff" onStart={beginDrag} onManipulating={onManipulating} onDrag={(dx,dy,_x,_y,p=1)=>{const s=dragStart.current,startX=-s.width/2-2.2-s.taper*FORM_RAIL.taper;emitChange({taper:roundTo(clamp(s.taper+axisTravel(dx,dy,[startX,s.height*.82,0],[-1,0,0],p,'left')/FORM_RAIL.taper,0,65),.5)})}}/></>}
    {canBreak&&<><mesh raycast={()=>null} position={[-b.width*.28,b.height*.34,(b.depth/2+breakZ)/2]}><boxGeometry args={[.07,.07,breakZ-b.depth/2]}/><meshBasicMaterial color="#ff735f" transparent opacity={.62}/></mesh><GizmoHandle position={[-b.width*.28,b.height*.34,breakZ]} label={`BREAK ${formatGizmoValue(b.articulation)}%`} shape="diamond" axis="form" color="#ff735f" onStart={beginDrag} onManipulating={onManipulating} onDrag={(dx,dy,_x,_y,p=1)=>{const s=dragStart.current,startZ=s.depth/2+3+s.articulation*FORM_RAIL.break;emitChange({articulation:roundTo(clamp(s.articulation+axisTravel(dx,dy,[-s.width*.28,s.height*.34,startZ],[0,0,1],p,'down')/FORM_RAIL.break,0,100),.5)})}}/></>}
    <mesh raycast={()=>null} position={[0,b.height*.2,(b.depth/2+repeatZ)/2]}><boxGeometry args={[.07,.07,repeatZ-b.depth/2]}/><meshBasicMaterial color="#f2cf58" transparent opacity={.62}/></mesh>
    <GizmoHandle position={[0,b.height*.2,repeatZ]} label={`REPEAT ${b.moduleDensity}`} shape="sphere" axis="form" color="#f2cf58" onStart={beginDrag} onManipulating={onManipulating} onKeyboardStep={direction=>{const s=dragStart.current;emitChange({moduleDensity:Math.round(clamp(s.moduleDensity+direction,1,5))})}} onDrag={(dx,dy,_x,_y,p=1)=>{const s=dragStart.current,startZ=s.depth/2+3+(s.moduleDensity-1)*FORM_RAIL.repeat;emitChange({moduleDensity:discreteAxisValue(s.moduleDensity,dx,dy,[0,s.height*.2,startZ],[0,0,1],FORM_RAIL.repeat,1,5,p,'down')})}}/>
    {canBranch&&<><mesh raycast={()=>null} position={[b.width*.28,b.height*.48,(b.depth/2+branchZ)/2]}><boxGeometry args={[.07,.07,branchZ-b.depth/2]}/><meshBasicMaterial color="#55c8ff" transparent opacity={.62}/></mesh><GizmoHandle position={[b.width*.28,b.height*.48,branchZ]} label={`BRANCH ${b.branches}`} shape="diamond" axis="form" color="#55c8ff" onStart={beginDrag} onManipulating={onManipulating} onKeyboardStep={direction=>{const s=dragStart.current;emitChange({branches:Math.round(clamp(s.branches+direction,0,8))})}} onDrag={(dx,dy,_x,_y,p=1)=>{const s=dragStart.current,startZ=s.depth/2+3+s.branches*FORM_RAIL.branch;emitChange({branches:discreteAxisValue(s.branches,dx,dy,[s.width*.28,s.height*.48,startZ],[0,0,1],FORM_RAIL.branch,0,8,p,'down')})}}/></>}
    {canCrown&&<><mesh raycast={()=>null} position={[(crownX-Math.max(5,b.width*.18))/2,b.height+3.4,0]}><boxGeometry args={[Math.abs(crownX+Math.max(5,b.width*.18)),.07,.07]}/><meshBasicMaterial color="#ff82c8" transparent opacity={.62}/></mesh><GizmoHandle position={[crownX,b.height+3.4,0]} label={`CROWN ${formatGizmoValue(b.crown)}%`} shape="sphere" axis="form" color="#ff82c8" onStart={beginDrag} onManipulating={onManipulating} onDrag={(dx,dy,_x,_y,p=1)=>{const s=dragStart.current,startX=-Math.max(5,s.width*.18)-s.crown*FORM_RAIL.crown;emitChange({crown:roundTo(clamp(s.crown+axisTravel(dx,dy,[startX,s.height+3.4,0],[-1,0,0],p,'left')/FORM_RAIL.crown,0,100),.5)})}}/></>}
    <group position={[0,.55,0]}>
      <mesh raycast={()=>null} position={[0,0,ring]}><boxGeometry args={[ring*2,.08,.18]}/><meshBasicMaterial color="#d7ff43" transparent opacity={.68}/></mesh>
      <mesh raycast={()=>null} position={[0,0,-ring]}><boxGeometry args={[ring*2,.08,.18]}/><meshBasicMaterial color="#d7ff43" transparent opacity={.68}/></mesh>
      <mesh raycast={()=>null} position={[ring,0,0]}><boxGeometry args={[.18,.08,ring*2]}/><meshBasicMaterial color="#d7ff43" transparent opacity={.68}/></mesh>
      <mesh raycast={()=>null} position={[-ring,0,0]}><boxGeometry args={[.18,.08,ring*2]}/><meshBasicMaterial color="#d7ff43" transparent opacity={.68}/></mesh>
    </group>
    <GizmoHandle position={[ring,.58,0]} label={`${Math.round(b.rotation)}°`} shape="sphere" axis="rotate" onStart={beginDrag} onManipulating={onManipulating} onDrag={(dx,dy,_x,_y,p=1)=>{const s=dragStart.current,startRing=Math.max(s.width,s.depth)*.67,arc=axisTravel(dx,dy,[startRing,.58,0],[0,0,-1],p,'up');emitChange({rotation:roundTo(((s.rotation+THREE.MathUtils.radToDeg(arc/Math.max(4,startRing)))%360+360)%360,1)})}}/>
  </group>
}

function ConcreteBody({ body, color, selected, hovered, ghost }: { body: Body; color: string; selected: boolean; hovered: boolean; ghost: boolean }) {
  const texture=getConcreteTexture()
  const surface=body.role==='transfer'?new THREE.Color(color).multiplyScalar(.72).getStyle():body.role==='core'?new THREE.Color(color).multiplyScalar(.84).getStyle():color
  return <mesh position={[body.x, body.y, body.z]} rotation={body.kind==='capsule'?[0,0,Math.PI/2]:[0,0,0]} scale={body.kind==='capsule'?[body.h,body.w/2,body.d]:[1,1,1]} castShadow receiveShadow>
    {body.kind==='capsule'?<capsuleGeometry args={[.5,1,6,16]}/>:<boxGeometry args={[body.w, body.h, body.d]} />}
    <meshStandardMaterial color={surface} map={ghost?undefined:texture} bumpMap={ghost?undefined:texture} bumpScale={.055} roughness={.93} metalness={.015} wireframe={ghost} transparent={ghost} depthWrite={!ghost} opacity={ghost ? .24 : 1} emissive={selected || hovered ? '#d7ff43' : '#000'} emissiveIntensity={selected ? .055 : hovered ? .018 : 0} onBeforeCompile={concreteShader} />
    {(selected || hovered)&&body.kind!=='capsule'&&body.role!=='transfer'&&<Edges color={selected ? '#d7ff43' : '#f4efe4'} lineWidth={selected ? 1.6 : .75} />}
  </mesh>
}

const bodyWorldPoint=(body:Body,position:[number,number,number])=>new THREE.Vector3(...position).applyAxisAngle(new THREE.Vector3(0,1,0),body.ry??0)

function ConstructionJoints({ body, tone }: { body: Body; tone: Building['tone'] }) {
  if (!body.facade) return null
  const lifts = Math.max(3, Math.min(9, Math.round(body.h / 9)))
  const color = tone === 'charcoal' ? '#292d2b' : '#6d6e68'
  return <>{Array.from({length:lifts-1},(_,i)=>{
    const y=body.y-body.h/2+(i+1)*body.h/lifts
    return <group key={i}>
      <mesh position={[body.x,y,body.z+body.d/2+.035]}><boxGeometry args={[body.w*.97,.045,.04]} /><meshBasicMaterial color={color} transparent opacity={.45} /></mesh>
      <mesh position={[body.x,y,body.z-body.d/2-.035]}><boxGeometry args={[body.w*.97,.045,.04]} /><meshBasicMaterial color={color} transparent opacity={.45} /></mesh>
      <mesh position={[body.x+body.w/2+.035,y,body.z]}><boxGeometry args={[.04,.045,body.d*.97]} /><meshBasicMaterial color={color} transparent opacity={.38} /></mesh>
      <mesh position={[body.x-body.w/2-.035,y,body.z]}><boxGeometry args={[.04,.045,body.d*.97]} /><meshBasicMaterial color={color} transparent opacity={.38} /></mesh>
    </group>
  })}</>
}

function BeamBetween({from,to,width=.28,color='#6c6f68'}:{from:[number,number,number];to:[number,number,number];width?:number;color?:string}){
  const a=new THREE.Vector3(...from),d=new THREE.Vector3(...to).sub(a),length=d.length(),mid=a.clone().add(d.clone().multiplyScalar(.5))
  const quaternion=new THREE.Quaternion().setFromUnitVectors(new THREE.Vector3(0,1,0),d.normalize())
  return <mesh position={mid} quaternion={quaternion} castShadow><cylinderGeometry args={[width,width,length,6]}/><meshStandardMaterial color={color} roughness={.9}/></mesh>
}

function GlowBeam({from,to,radius=.75,color='#9fb6c4',opacity=.12}:{from:[number,number,number];to:[number,number,number];radius?:number;color?:string;opacity?:number}){
  const a=new THREE.Vector3(...from),d=new THREE.Vector3(...to).sub(a),length=d.length(),mid=a.clone().add(d.clone().multiplyScalar(.5))
  const quaternion=new THREE.Quaternion().setFromUnitVectors(new THREE.Vector3(0,1,0),d.normalize())
  return <mesh position={mid} quaternion={quaternion} raycast={()=>null}>
    <cylinderGeometry args={[radius,radius*.22,length,8,1,true]}/>
    <meshBasicMaterial color={color} transparent opacity={opacity} depthWrite={false} blending={THREE.AdditiveBlending} side={THREE.DoubleSide}/>
  </mesh>
}

const signTextureCache=new Map<string,THREE.CanvasTexture>()

function SignPanel({text,width,height,bg='#071018',fg='#28d7ff',accent='#d7ff43',position=[0,0,0],rotation=[0,0,0],opacity=1,variant='text'}:{text:string;width:number;height:number;bg?:string;fg?:string;accent?:string;position?:[number,number,number];rotation?:[number,number,number];opacity?:number;variant?:'text'|'glyph'}){
  const texture=useMemo(()=>{
    if(typeof document==='undefined')return undefined
    const cacheKey=JSON.stringify([text,bg,fg,accent,variant])
    const cached=signTextureCache.get(cacheKey)
    if(cached)return cached
    const canvas=document.createElement('canvas')
    const logicalWidth=768,logicalHeight=256
    canvas.width=384;canvas.height=128
    const ctx=canvas.getContext('2d')
    if(!ctx)return undefined
    ctx.setTransform(.5,0,0,.5,0,0)
    const seed=[...text].reduce((sum,ch)=>sum+ch.charCodeAt(0),0)
    ctx.fillStyle=bg;ctx.fillRect(0,0,logicalWidth,logicalHeight)
    ctx.fillStyle='rgba(255,255,255,.05)'
    for(let x=0;x<logicalWidth;x+=32)ctx.fillRect(x,0,2,logicalHeight)
    for(let y=0;y<logicalHeight;y+=32)ctx.fillRect(0,y,logicalWidth,2)
    ctx.fillStyle=accent;ctx.fillRect(0,0,logicalWidth,18);ctx.fillRect(0,logicalHeight-18,logicalWidth,18)
    ctx.fillStyle='rgba(255,255,255,.14)';ctx.fillRect(20,34,logicalWidth-40,2)
    if(variant==='glyph'){
      ctx.shadowColor=fg;ctx.shadowBlur=16
      for(let i=0;i<34;i++){
        const x=36+((seed+i*47)%690),y=48+((seed*3+i*29)%146)
        const w=10+((seed+i*17)%84),h=6+((seed+i*11)%28)
        ctx.fillStyle=i%5===0?accent:i%3===0?'rgba(232,255,247,.78)':fg
        ctx.globalAlpha=.26+(i%7)*.08
        if(i%4===0){ctx.fillRect(x,y,w,3);ctx.fillRect(x+w-3,y,3,h)}
        else if(i%4===1){ctx.strokeStyle=ctx.fillStyle;ctx.lineWidth=3;ctx.strokeRect(x,y,w,h)}
        else ctx.fillRect(x,y,w,h)
      }
      ctx.globalAlpha=1;ctx.shadowBlur=0
      ctx.strokeStyle=accent;ctx.lineWidth=3
      for(let i=0;i<9;i++){
        const x=44+i*78+((seed+i*13)%22),y=logicalHeight-42
        ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(x+22,y);ctx.lineTo(x+34,y-12);ctx.stroke()
      }
      ctx.fillStyle='rgba(255,255,255,.16)'
      for(let i=0;i<22;i++)ctx.fillRect(28+i*32,28+((seed+i*19)%18),18,2)
    }else{
      const lines=text.split('|')
      ctx.textAlign='center';ctx.textBaseline='middle'
      ctx.font=`900 ${lines.length>1?68:92}px ui-monospace, SFMono-Regular, Menlo, Consolas, monospace`
      ctx.shadowColor=fg;ctx.shadowBlur=18
      lines.forEach((line,i)=>{ctx.fillStyle=fg;ctx.fillText(line,logicalWidth/2,logicalHeight/2+(i-(lines.length-1)/2)*76)})
      ctx.shadowBlur=0;ctx.fillStyle=accent;ctx.font='700 24px ui-monospace, monospace';ctx.textAlign='left';ctx.fillText('MONUMENT://DISTRICT',24,logicalHeight-32)
    }
    const t=new THREE.CanvasTexture(canvas)
    t.colorSpace=THREE.SRGBColorSpace
    t.anisotropy=1
    t.generateMipmaps=false
    t.minFilter=THREE.LinearFilter
    t.magFilter=THREE.LinearFilter
    signTextureCache.set(cacheKey,t)
    return t
  },[text,bg,fg,accent,variant])
  return <mesh position={position} rotation={rotation} raycast={()=>null}>
    <planeGeometry args={[width,height]}/>
    <meshBasicMaterial map={texture} color="#ffffff" transparent opacity={opacity} toneMapped={false} side={THREE.DoubleSide}/>
  </mesh>
}

function FacadeLayer({ b, body, strategy, mode, night, mood, quality, occupancy }: { b: Building; body: Body; strategy: FacadeStrategy; mode: ViewMode; night:boolean; mood:DistrictMood; quality:RenderQuality;occupancy:number }) {
  if (body.h < b.floorHeight * 1.35 || !body.facade || body.kind==='capsule') return null
  const profile=RENDER_PROFILES[quality]
  const floors=Math.max(1,Math.min(profile.facadeFloors,Math.floor(body.h/b.floorHeight)))
  const bays=Math.max(2,Math.min(profile.facadeBays,Math.round(body.w/b.baySpacing)))
  const sideBays=Math.max(2,Math.min(Math.max(4,profile.facadeBays-1),Math.round(body.d/b.baySpacing)))
  const floor=body.h/floors,bay=body.w/bays,sideBay=body.d/sideBays
  const scene=moodScene(mood)
  const lit=night||mode==='activity'
  const windowMaterial=(seed:number)=>{
    if(mode==='activity')return {glass:'#ffc36e',emissive:'#ff8a25',intensity:.72}
    if(!lit)return {glass:'#111e26',emissive:'#000000',intensity:0}
    const random=Math.abs(Math.sin(seed*12.9898+body.x*.17+body.z*.11)*43758.5453)%1
    if(mood==='totalitarian'){
      const active=random<clamp(.04+occupancy*.28,.04,.32)
      const c=seed%4===0?scene.window:scene.windowAlt
      return {glass:new THREE.Color(c).multiplyScalar(active ? .34 : .08).getStyle(),emissive:c,intensity:active?scene.windowIntensity*.5:scene.windowIntensity*.035}
    }
    if(mood==='cyberpunk'){
      const active=random<clamp(.18+occupancy*.68,.18,.9)
      const palette=['#38f6ff','#d7ff43','#ffa33b','#738282','#ff386c','#2e5159']
      const c=palette[Math.abs(seed)%palette.length]
      const hot=seed%17===0
      return {glass:new THREE.Color(c).multiplyScalar(active ? (hot ? .76 : .32) : .055).getStyle(),emissive:c,intensity:active?scene.windowIntensity*(hot ? 1.35 : .42):scene.windowIntensity*.025}
    }
    const active=random<clamp(.16+occupancy*.7,.16,.88)
    const c=seed%3===0?scene.windowAlt:scene.window
    return {glass:new THREE.Color(c).multiplyScalar(active ? .52 : .2).getStyle(),emissive:c,intensity:active?scene.windowIntensity:scene.windowIntensity*.18}
  }
  const concrete=TONES[b.tone].color,accent=b.tone==='white'?'#a95f49':b.tone==='charcoal'?'#c1945c':'#6e5847'
  const elements:React.ReactNode[]=[]
  const continuous=strategy!=='punched'
  const gridish=['deep-grid','brise-soleil','exoskeleton'].includes(strategy)
  const projection=strategy==='brise-soleil'?b.facadeDepth:strategy==='exoskeleton'?Math.max(1.2,b.facadeDepth):Math.max(.35,b.facadeDepth*.55)

  for(let f=0;f<floors;f++){
    const y=body.y-body.h/2+floor*(f+.53)
    const windowH=Math.max(.72,floor*(strategy==='ribbon'?.5:.38))
    for(const face of [-1,1]){
      const z=body.z+face*(body.d/2+.022)
      if(continuous){
        if(mood==='cyberpunk'){
          const segments=Math.max(3,Math.min(profile.cyberSegments,Math.round(body.w/Math.max(3.5,b.baySpacing*.9))))
          for(let i=0;i<segments;i++){
            const seed=f*31+i*7+face+Math.round(body.x*1.7)
            if(seed%5===0)continue
            const w=windowMaterial(seed)
            const segW=body.w*.78/segments*(.52+((seed%4)+4)%4*.13)
            const x=body.x-body.w*.39+body.w*.78*(i+.5)/segments
            elements.push(<mesh key={`cfz-${f}-${face}-${i}`} position={[x,y,z]} rotation={[0,face<0?Math.PI:0,0]}><planeGeometry args={[segW,windowH*(seed%6===0?.54:.82)]}/><meshStandardMaterial color={w.glass} emissive={w.emissive} emissiveIntensity={w.intensity} roughness={.36} metalness={.08}/></mesh>)
          }
          if(f%4===1)elements.push(<mesh key={`dead-fz-${f}-${face}`} position={[body.x+body.w*.23*face,y,body.z+face*(body.d/2+.032)]} rotation={[0,face<0?Math.PI:0,0]}><planeGeometry args={[body.w*.22,windowH*.72]}/><meshStandardMaterial color="#020506" emissive="#000" roughness={1}/></mesh>)
        }else{
          const w=windowMaterial(f*11+face+Math.round(body.x));elements.push(<mesh key={`fz-${f}-${face}`} position={[body.x,y,z]} rotation={[0,face<0?Math.PI:0,0]}><planeGeometry args={[body.w*.92,windowH]}/><meshStandardMaterial color={w.glass} emissive={w.emissive} emissiveIntensity={w.intensity} roughness={.25} metalness={.16}/></mesh>)
        }
      }
      else for(let i=0;i<bays;i++){
        const x=body.x-body.w/2+bay*(i+.5),winW=bay*Math.min(.72,b.porosity/88)
        const w=windowMaterial(f*17+i*5+face+Math.round(body.z))
        elements.push(<group key={`pz-${f}-${face}-${i}`}><mesh position={[x,y,z]} rotation={[0,face<0?Math.PI:0,0]}><planeGeometry args={[winW,windowH]}/><meshStandardMaterial color={w.glass} emissive={w.emissive} emissiveIntensity={w.intensity*.72}/></mesh>{f%2===0&&<mesh position={[x,y+windowH/2+.14,body.z+face*(body.d/2+b.facadeDepth*.34)]}><boxGeometry args={[winW+.45,.25,Math.max(.35,b.facadeDepth*.65)]}/><meshStandardMaterial color={concrete} roughness={.97}/></mesh>}</group>)
      }
      if(gridish&&(strategy!=='deep-grid'||f%2===0||f===floors-1))elements.push(<mesh key={`bz-${f}-${face}`} position={[body.x,y+windowH/2+.15,body.z+face*(body.d/2+projection*.46)]} castShadow><boxGeometry args={[body.w+.2,.3,projection]}/><meshStandardMaterial color={concrete} roughness={.96}/></mesh>)
    }
    for(const face of [-1,1]){
      const x=body.x+face*(body.w/2+.022)
      if(continuous){
        if(mood==='cyberpunk'){
          const segments=Math.max(3,Math.min(profile.cyberSegments,Math.round(body.d/Math.max(3.5,b.baySpacing*.9))))
          for(let i=0;i<segments;i++){
            const seed=f*37+i*5+face+Math.round(body.z*1.3)
            if(seed%5===0)continue
            const w=windowMaterial(seed)
            const segD=body.d*.78/segments*(.5+((seed%5)+5)%5*.09)
            const z=body.z-body.d*.39+body.d*.78*(i+.5)/segments
            elements.push(<mesh key={`cfx-${f}-${face}-${i}`} position={[x,y,z]} rotation={[0,face>0?Math.PI/2:-Math.PI/2,0]}><planeGeometry args={[segD,windowH*(seed%7===0?.5:.8)]}/><meshStandardMaterial color={w.glass} emissive={w.emissive} emissiveIntensity={w.intensity} roughness={.36} metalness={.08}/></mesh>)
          }
          if(f%4===2)elements.push(<mesh key={`dead-fx-${f}-${face}`} position={[body.x+face*(body.w/2+.032),y,body.z-body.d*.18*face]} rotation={[0,face>0?Math.PI/2:-Math.PI/2,0]}><planeGeometry args={[body.d*.24,windowH*.7]}/><meshStandardMaterial color="#020506" emissive="#000" roughness={1}/></mesh>)
        }else{
          const w=windowMaterial(f*13+face+Math.round(body.z));elements.push(<mesh key={`fx-${f}-${face}`} position={[x,y,body.z]} rotation={[0,face>0?Math.PI/2:-Math.PI/2,0]}><planeGeometry args={[body.d*.92,windowH]}/><meshStandardMaterial color={w.glass} emissive={w.emissive} emissiveIntensity={w.intensity} roughness={.25} metalness={.16}/></mesh>)
        }
      }
      else for(let i=0;i<sideBays;i++){
        const z=body.z-body.d/2+sideBay*(i+.5),winW=sideBay*Math.min(.72,b.porosity/88)
        const w=windowMaterial(f*19+i*3+face+Math.round(body.x))
        elements.push(<group key={`px-${f}-${face}-${i}`}><mesh position={[x,y,z]} rotation={[0,face>0?Math.PI/2:-Math.PI/2,0]}><planeGeometry args={[winW,windowH]}/><meshStandardMaterial color={w.glass} emissive={w.emissive} emissiveIntensity={w.intensity*.72}/></mesh>{f%2===0&&<mesh position={[body.x+face*(body.w/2+b.facadeDepth*.34),y+windowH/2+.14,z]}><boxGeometry args={[Math.max(.35,b.facadeDepth*.65),.25,winW+.45]}/><meshStandardMaterial color={concrete} roughness={.97}/></mesh>}</group>)
      }
      if(gridish&&(strategy!=='deep-grid'||f%2===0||f===floors-1))elements.push(<mesh key={`bx-${f}-${face}`} position={[body.x+face*(body.w/2+projection*.46),y+windowH/2+.15,body.z]} castShadow><boxGeometry args={[projection,.3,body.d+.2]}/><meshStandardMaterial color={concrete} roughness={.96}/></mesh>)
    }
  }

  if(gridish){
    for(let i=0;i<=bays;i++){const x=body.x-body.w/2+bay*i;for(const face of [-1,1])elements.push(<mesh key={`vz-${i}-${face}`} position={[x,body.y,body.z+face*(body.d/2+projection*.5)]} castShadow><boxGeometry args={[.24,body.h*.96,projection]}/><meshStandardMaterial color={concrete} roughness={.96}/></mesh>)}
    for(let i=0;i<=sideBays;i++){const z=body.z-body.d/2+sideBay*i;for(const face of [-1,1])elements.push(<mesh key={`vx-${i}-${face}`} position={[body.x+face*(body.w/2+projection*.5),body.y,z]} castShadow><boxGeometry args={[projection,body.h*.96,.24]}/><meshStandardMaterial color={concrete} roughness={.96}/></mesh>)}
  }else if(strategy==='ribbon'){
    for(let i=1;i<bays;i++){const x=body.x-body.w/2+bay*i;for(const face of [-1,1])elements.push(<mesh key={`mz-${i}-${face}`} position={[x,body.y,body.z+face*(body.d/2+.1)]}><boxGeometry args={[.12,body.h*.95,.22]}/><meshStandardMaterial color="#383c3a"/></mesh>)}
    for(let i=1;i<sideBays;i++){const z=body.z-body.d/2+sideBay*i;for(const face of [-1,1])elements.push(<mesh key={`mx-${i}-${face}`} position={[body.x+face*(body.w/2+.1),body.y,z]}><boxGeometry args={[.22,body.h*.95,.12]}/><meshStandardMaterial color="#383c3a"/></mesh>)}
  }

  if(strategy==='screen'){
    const louverDepth=Math.max(.65,b.facadeDepth)
    for(let i=0;i<=bays*2;i++){const x=body.x-body.w/2+body.w*i/(bays*2);for(const face of [-1,1])elements.push(<mesh key={`sz-${i}-${face}`} position={[x,body.y,body.z+face*(body.d/2+louverDepth*.46)]} castShadow><boxGeometry args={[.12,body.h*.94,louverDepth]}/><meshStandardMaterial color={concrete}/></mesh>)}
    for(let i=0;i<=sideBays*2;i++){const z=body.z-body.d/2+body.d*i/(sideBays*2);for(const face of [-1,1])elements.push(<mesh key={`sx-${i}-${face}`} position={[body.x+face*(body.w/2+louverDepth*.46),body.y,z]} castShadow><boxGeometry args={[louverDepth,body.h*.94,.12]}/><meshStandardMaterial color={concrete}/></mesh>)}
  }

  if(strategy==='exoskeleton')for(const face of [-1,1]){
    const z=body.z+face*(body.d/2+projection*.58),x=body.x+face*(body.w/2+projection*.58)
    elements.push(<BeamBetween key={`exo-z-a-${face}`} from={[body.x-body.w*.48,body.y-body.h*.48,z]} to={[body.x+body.w*.48,body.y+body.h*.48,z]} width={Math.max(.25,b.facadeDepth*.13)} color={accent}/>,<BeamBetween key={`exo-z-b-${face}`} from={[body.x+body.w*.48,body.y-body.h*.48,z]} to={[body.x-body.w*.48,body.y+body.h*.48,z]} width={Math.max(.25,b.facadeDepth*.13)} color={accent}/>,<BeamBetween key={`exo-x-a-${face}`} from={[x,body.y-body.h*.48,body.z-body.d*.48]} to={[x,body.y+body.h*.48,body.z+body.d*.48]} width={Math.max(.25,b.facadeDepth*.13)} color={accent}/>,<BeamBetween key={`exo-x-b-${face}`} from={[x,body.y-body.h*.48,body.z+body.d*.48]} to={[x,body.y+body.h*.48,body.z-body.d*.48]} width={Math.max(.25,b.facadeDepth*.13)} color={accent}/>)
  }

  const balconyStep=b.balconies>66?2:b.balconies>28?3:b.balconies>5?5:99
  for(let f=1;f<floors;f+=balconyStep){const y=body.y-body.h/2+floor*(f+.17);for(const face of [-1,1])elements.push(<group key={`balcony-${f}-${face}`}><mesh position={[body.x,y,body.z+face*(body.d/2+.55+b.facadeDepth*.34)]} castShadow><boxGeometry args={[body.w*.94,.2,1.1+b.facadeDepth*.7]}/><meshStandardMaterial color={concrete} roughness={.96}/></mesh><mesh position={[body.x,y+.65,body.z+face*(body.d/2+1.05+b.facadeDepth*.68)]}><boxGeometry args={[body.w*.94,.72,.08]}/><meshStandardMaterial color={accent} roughness={.5}/></mesh></group>)}
  return <>{elements}</>
}

function structuralBodies(b: Building): Body[] {
  if(b.composition==='ring')return []
  const base=buildingBase(b)
  const usable=Math.max(7,b.height-base)
  const floorCount=Math.max(1,Math.floor(usable/b.floorHeight))
  const articulationTierBonus=['bar','megastructure'].includes(b.composition)?Math.floor(b.articulation/45):0
  const requestedTiers=Math.max(b.terraces,Math.ceil(floorCount/7)+Math.floor((b.moduleDensity-3)/2)+articulationTierBonus)
  // Keep short buildings from becoming stacks of paper-thin plates. A form
  // change should read as a new silhouette at a glance.
  const tierCount=Math.round(clamp(requestedTiers,1,Math.max(1,Math.min(9,floorCount))))
  const tierH=usable/tierCount
  const bodies:Body[]=[]
  // Composition is an explicit player decision. Proportion and grammar may
  // articulate it, but must never silently replace it with another family.
  const composition=b.composition

  const profileAt=(i:number)=>{
    const t=tierCount===1?.5:i/(tierCount-1)
    const amount=b.taper/100
    let scaleW=1,scaleD=1,x=0,z=0,ry=0
    if(b.profile==='stepped'){scaleW=1-t*amount*.5;scaleD=1-t*amount*.34;z=-t*(b.cantilever+b.depth*.08)}
    if(b.profile==='tapered'){scaleW=1-t*amount*.78;scaleD=1-t*amount*.58}
    if(b.profile==='top-heavy'){scaleW=.66+t*(.34+amount*.42);scaleD=.76+t*(.24+amount*.25)}
    if(b.profile==='offset'){x=(t-.5)*(b.cantilever*2+(composition==='bar'?0:b.voids*.1));z=Math.sin(t*Math.PI*2)*b.cantilever*.3;scaleW=1-amount*.12*t}
    if(b.profile==='twisted'){ry=(t-.5)*(.16+(composition==='megastructure'?0:amount*1.65));scaleW=1-amount*.18*t;scaleD=1-amount*.12*t}
    x+=t*b.cantilever*.42
    return {t,scaleW:Math.max(.42,scaleW),scaleD:Math.max(.46,scaleD),x,z,ry}
  }

  if(b.podiumHeight>0&&composition!=='bridge')bodies.push({x:0,y:b.podiumHeight/2,z:0,w:b.width+Math.min(8,b.cantilever),h:b.podiumHeight,d:b.depth+Math.min(7,b.cantilever),facade:true})

  if(composition==='capsule'){
    const seed=hashText(b.id)
    const density=(b.moduleDensity-1)/4
    const desiredRows=Math.round(clamp(5+Math.min(5,floorCount*.18)+density*5,5,14))
    const lanes=1+Number(b.moduleDensity>=3&&b.depth>18)+Number(b.moduleDensity===5&&b.depth>38)
    const spines=Math.round(clamp(Math.max(b.cores,lanes),1,3))
    const rows=Math.min(desiredRows,Math.max(4,Math.floor(64/(spines*2)))),rowH=usable/rows
    const coreW=clamp(b.width*.13,4.5,10),coreD=clamp(b.depth/(spines+1)*.68,4.5,8.5)
    const laneZ=Array.from({length:spines},(_,lane)=>(lane-(spines-1)/2)*Math.min(13,b.depth*.3))
    const structureH=base+usable
    for(const z of laneZ)bodies.push({x:0,y:structureH/2,z,w:coreW,h:structureH,d:coreD,facade:false,role:'core'})
    const basePodW=clamp(b.width*(.22+b.moduleDensity*.012)+b.cantilever*.3,8,28)
    const basePodD=clamp(b.depth/(spines+1)*.78,4.8,11)
    const taper=clamp(b.taper/65,0,1),articulation=b.articulation/100
    const voidBandCount=b.voids<20?0:b.voids<42?1:b.voids<60?2:3
    const voidRows=[.34,.61,.82].slice(0,voidBandCount).map(t=>Math.round((rows-1)*t))
    const capsuleProfile=(row:number)=>{
      const t=rows===1?.5:row/(rows-1),smooth=t*t*(3-2*t)
      let reachScale=1-taper*.48*smooth,depthScale=1-taper*.18*smooth,driftX=t*b.cantilever*.08,driftZ=0,turn=0
      if(b.profile==='stepped'){
        const band=Math.min(2,Math.floor(t*3));reachScale*=1-band*.08;depthScale*=1-band*.05;driftZ-=band*(b.depth*.035+b.cantilever*.15)
      }
      if(b.profile==='tapered'){reachScale*=1-smooth*.2;depthScale*=1-smooth*.16}
      if(b.profile==='top-heavy'){reachScale*=.66+smooth*.62;depthScale*=.76+smooth*.3}
      if(b.profile==='offset'){
        driftX+=(t-.5)*(b.cantilever*1.7+b.width*(.08+taper*.12));driftZ=Math.sin(t*Math.PI*2)*b.depth*.06
      }
      if(b.profile==='twisted'){
        turn=(t-.5)*(.55+taper*1.2);driftX+=Math.sin(t*Math.PI*2)*b.cantilever*.18
      }
      return {t,reachScale:clamp(reachScale,.38,1.28),depthScale:clamp(depthScale,.52,1.18),driftX,driftZ,turn}
    }
    for(let i=0;i<rows;i++){
      if(voidRows.includes(i))continue
      const p=capsuleProfile(i),podH=Math.min(rowH*(.62+articulation*.12),b.floorHeight*1.65)
      for(const side of [-1,1])for(let lane=0;lane<spines;lane++){
        const rhythm=((seed+i*17+lane*11+(side>0?3:0))%5)-2
        const projection=1+rhythm*articulation*.045
        const podW=clamp(basePodW*p.reachScale*projection,6.2,28)
        const podD=clamp(basePodD*p.depthScale*(1+((rhythm+2)%3-1)*articulation*.035),4.4,11)
        const reach=coreW*.48+podW*.44+b.cantilever*.07*(1-p.t*.35)
        const x=p.driftX+side*reach
        const z=p.driftZ+laneZ[lane]+(i%2?podD*.12:-podD*.12)+rhythm*articulation*.11
        const y=base+rowH*(i+.5)+rhythm*rowH*articulation*.018
        bodies.push({x,y,z,w:podW,h:podH,d:podD,ry:p.turn,kind:'capsule',facade:false,role:'mass'})
        bodies.push({x:p.driftX+side*reach*.48,y,z:p.driftZ+laneZ[lane],w:reach*.94,h:Math.max(.48,podH*.18),d:podD*.58,ry:p.turn,facade:false,role:'transfer'})
      }
    }
    const deckCount=Math.round(clamp(b.terraces,0,6))
    for(let deck=0;deck<deckCount;deck++){
      const row=Math.round((deck+1)/(deckCount+1)*(rows-1)),p=capsuleProfile(row)
      bodies.push({x:p.driftX,y:base+rowH*(row+.12),z:p.driftZ,w:Math.max(coreW*2.2,b.width*.24),h:.48,d:Math.max(coreD*1.8,Math.abs(laneZ.at(-1)??0)*2+coreD*1.25),ry:p.turn,facade:false,role:'transfer'})
    }
    const occupiedRows=Array.from({length:rows},(_,i)=>i).filter(i=>!voidRows.includes(i))
    for(let branch=0;branch<b.branches;branch++){
      const row=occupiedRows[Math.round((branch+1)/(b.branches+1)*Math.max(0,occupiedRows.length-1))]??Math.floor(rows/2)
      const p=capsuleProfile(row),direction=branch%2?1:-1
      const y=base+rowH*(row+.5),x=p.driftX+((branch%3)-1)*coreW*.42
      const outerLane=Math.max(coreD*.5,...laneZ.map(z=>Math.abs(z)+coreD*.5))
      const armReach=outerLane+5+b.cantilever*(.42+(branch%3)*.08)+(branch%2)*1.5
      const terminalW=clamp(basePodW*p.reachScale*(.74+b.moduleDensity*.035),7,22)
      const terminalD=clamp(basePodD*(.9+(branch%2)*.08),4.8,10)
      bodies.push({x,y,z:p.driftZ+direction*armReach*.5,w:Math.max(1.1,coreW*.25+b.moduleDensity*.14),h:.62,d:armReach,ry:p.turn,facade:false,role:'transfer',branch:true})
      bodies.push({x,y:y+rowH*.08,z:p.driftZ+direction*(armReach+terminalD*.46),w:terminalW,h:Math.min(rowH*.82,b.floorHeight*1.75),d:terminalD,ry:p.turn,kind:'capsule',facade:false,role:'mass',branch:true})
    }
    if(b.crown>20){
      const crownY=base+usable-Math.max(.45,rowH*.16),crownReach=clamp(b.width*(.2+b.crown*.0016),7,20)
      bodies.push({x:0,y:crownY,z:0,w:crownReach*1.35,h:.72,d:Math.max(coreD*1.6,b.depth*.28),facade:false,role:'transfer',crown:true})
      if(b.crown>44)for(const side of [-1,1])bodies.push({x:side*crownReach*.44,y:crownY+Math.min(rowH*.38,2.4),z:0,w:crownReach,h:Math.min(rowH*.72,b.floorHeight*1.55),d:basePodD*.86,kind:'capsule',facade:false,role:'mass',crown:true})
      if(b.crown>76)for(const zSide of [-1,1])bodies.push({x:0,y:crownY+Math.min(rowH*.82,4.4),z:zSide*basePodD*.55,w:crownReach*.76,h:Math.min(rowH*.64,b.floorHeight*1.4),d:basePodD*.74,kind:'capsule',facade:false,role:'mass',crown:true})
    }
    return bodies
  }

  if(composition==='megastructure'){
    const seed=[...b.id].reduce((sum,ch)=>sum+ch.charCodeAt(0),0)
    const bays=Math.round(clamp(Math.round(b.width/Math.max(10,b.baySpacing*2.25))+b.moduleDensity-2,3,10))
    const bayW=b.width/bays,levels=Math.round(clamp(tierCount+b.moduleDensity-2,3,9)),levelH=usable/levels
    const frameDepth=Math.max(8,b.depth*.68),post=Math.max(.75,Math.min(1.8,bayW*.085))
    const frameXs=Array.from({length:bays+1},(_,i)=>-b.width/2+i*bayW)
    // The permanent armature: legible posts and sky-street beams instead of a solid tower.
    const structureH=base+usable
    for(const x of frameXs)for(const z of [-frameDepth/2,frameDepth/2])bodies.push({x,y:structureH/2,z,w:post,h:structureH,d:post,facade:false,role:'core'})
    for(let i=0;i<=levels;i++){
      const y=base+Math.min(usable-.45,i*levelH)+.3
      bodies.push({x:0,y,z:-frameDepth/2,w:b.width+post,h:.72,d:post,facade:false,role:'transfer'})
      bodies.push({x:0,y,z:frameDepth/2,w:b.width+post,h:.72,d:post,facade:false,role:'transfer'})
      for(let bay=0;bay<=bays;bay+=2)bodies.push({x:frameXs[bay],y,z:0,w:post,h:.72,d:frameDepth+post,facade:false,role:'transfer'})
    }
    // Inhabited pieces plug into selected bays. Void, repeat and break change the pattern continuously.
    for(let level=0;level<levels;level++)for(let bay=0;bay<bays;bay++){
      const chance=(seed+level*37+bay*61)%100
      if(chance<clamp(b.voids*.72-b.moduleDensity*5,8,58))continue
      const p=profileAt(Math.round(level/Math.max(1,levels-1)*(tierCount-1)))
      const side=((seed+level+bay)%2?1:-1),jitter=(((seed+bay*17+level*13)%9)-4)*b.articulation*.0028
      const moduleW=Math.max(4,bayW*(.7+b.moduleDensity*.035)),moduleH=Math.max(b.floorHeight*1.35,levelH*(.38+b.articulation*.0022))
      const moduleD=Math.max(5,b.depth*(.23+b.moduleDensity*.025)),x=-b.width/2+bayW*(bay+.5)+p.x*.24
      const z=side*(frameDepth*.23+moduleD*.2+b.cantilever*.1)+jitter*b.depth
      bodies.push({x,y:base+levelH*(level+.5),z,w:moduleW,h:Math.min(levelH*.84,moduleH),d:moduleD,ry:p.ry,facade:true,role:'mass'})
      if(b.articulation>64&&chance%3===0)bodies.push({x:x+side*bayW*.12,y:base+levelH*(level+.72),z:-z*.76,w:moduleW*.58,h:moduleH*.48,d:moduleD*.78,ry:-p.ry,facade:true,role:'mass'})
    }
    // Pulling BRANCH grows inhabited streets out of the frame at deterministic levels and sides.
    for(let branch=0;branch<b.branches;branch++){
      const side=branch%2?1:-1,level=1+(branch*2+seed)%Math.max(2,levels-1),y=base+levelH*(level+.42)
      const x=-b.width*.32+(branch%Math.max(2,bays-1))*b.width/Math.max(2,bays-1)
      const reach=frameDepth*.5+b.cantilever+5+branch%3*2
      bodies.push({x,y:y-levelH*.13,z:side*reach*.52,w:Math.max(1.1,bayW*.7),h:.72,d:reach,facade:false,role:'transfer'})
      bodies.push({x,y,z:side*(reach+2+b.moduleDensity*.7),w:Math.max(5,bayW*.9),h:Math.max(b.floorHeight*1.5,levelH*.56),d:Math.max(6,b.depth*.24),facade:true,role:'mass'})
    }
    return bodies
  }

  const village=composition==='cluster'&&b.height<36&&b.articulation>56&&b.moduleDensity>2
  if(village){
    const seed=[...b.id].reduce((sum,ch)=>sum+ch.charCodeAt(0),0)
    const columns=Math.round(clamp(b.moduleDensity+Math.floor(b.articulation/42),4,7))
    const rows=Math.round(clamp(Math.ceil(b.depth/9),2,6))
    const cellW=b.width/columns,cellD=b.depth/rows
    for(let row=0;row<rows;row++)for(let col=0;col<columns;col++){
      const chance=(seed+row*41+col*29)%100
      if(chance<b.voids*.46)continue
      const laneShift=(row%2?.16:-.16)*cellW
      const x=-b.width/2+cellW*(col+.5)+laneShift
      const z=-b.depth/2+cellD*(row+.5)
      const variation=((seed+row*13+col*17)%7)/6
      const h=clamp(b.height*(.38+variation*.48),Math.max(5,b.floorHeight*1.6),b.height*.9)
      bodies.push({x,y:base+h/2,z,w:Math.max(3.2,cellW*(.62+variation*.1)),h,d:Math.max(3.5,cellD*.68),facade:true,role:'mass'})
    }
    if(b.crown>54)bodies.push({x:b.width*.18,y:base+b.height*.48,z:-b.depth*.12,w:Math.max(3.8,cellW*.7),h:b.height*.96,d:Math.max(4,cellD*.72),facade:true,role:'mass'})
    return bodies
  }

  const needsSpine=b.cantilever>2||b.profile==='offset'||b.profile==='twisted'||composition==='stack'||composition==='cluster'
  if(needsSpine)bodies.push({x:0,y:base+usable/2,z:0,w:Math.max(3.8,b.width*.14),h:usable,d:Math.max(4.2,b.depth*.22),facade:false,role:'core'})

  if(composition==='bridge'){
    const coreW=Math.max(3.8,b.width*(.14+(100-b.voids)*.0011))
    const spread=Math.max(coreW*.7,b.width*(.3+b.voids*.0015))
    const structureH=base+usable
    bodies.push(
      {x:-spread,y:structureH/2,z:0,w:coreW,h:structureH,d:b.depth*.72,facade:true,role:'core'},
      {x:spread,y:structureH/2,z:0,w:coreW,h:structureH,d:b.depth*.72,facade:true,role:'core'},
    )
    for(let i=0;i<tierCount;i++){
      const p=profileAt(i)
      const bridgeH=Math.max(b.floorHeight*1.45,tierH*(.26+b.voids*.002))
      bodies.push({x:p.x,y:base+tierH*(i+.58),z:p.z,w:b.width*p.scaleW+Math.min(10,b.cantilever),h:bridgeH,d:b.depth*p.scaleD,ry:p.ry,facade:true})
    }
    return bodies
  }

  for(let i=0;i<tierCount;i++){
    const p=profileAt(i)
    const y=base+tierH*(i+.5)
    const h=tierH*1.015
    const plateW=b.width*p.scaleW
    const plateD=b.depth*p.scaleD
    if(i>0&&(b.cantilever>1.2||composition==='stack'||composition==='cluster'))bodies.push({x:p.x*.5,y:base+tierH*i+.34,z:p.z*.5,w:Math.min(b.width+Math.abs(p.x),plateW+Math.abs(p.x)+2),h:.68,d:Math.min(b.depth+Math.abs(p.z),plateD+Math.abs(p.z)+1),ry:p.ry*.5,facade:false,role:'transfer'})
    if(composition==='split'){
      const gap=clamp(plateW*(.08+b.voids*.0042),2,plateW*.48)
      const wing=Math.max(2.8,(plateW-gap)/2)
      bodies.push(
        {x:p.x-(gap+wing)/2,y,z:p.z,w:wing,h,d:plateD,ry:p.ry,facade:true},
        {x:p.x+(gap+wing)/2,y,z:p.z,w:wing,h,d:plateD,ry:p.ry,facade:true},
      )
      if(i%2===1||tierCount===1)bodies.push({x:p.x,y:y+h*.2,z:p.z,w:gap+1.2,h:Math.min(h*.32,b.floorHeight*1.4),d:plateD+Math.min(4,b.cantilever),ry:p.ry,facade:true})
    }else if(composition==='cluster'){
      // Keep real air between the pieces. Earlier modules overlapped enough
      // that a cluster still read as a bar from most camera angles.
      const moduleW=Math.max(4.2,plateW*(plateW>32?.36:.42))
      const moduleD=Math.max(4.2,plateD*.42)
      const drift=(i%2?1:-1)*(b.cantilever*.28+b.voids*.025)
      bodies.push(
        {x:p.x-plateW*.27+drift,y,z:p.z-plateD*.25,w:moduleW,h,d:moduleD,ry:p.ry,facade:true},
        {x:p.x+plateW*.27+drift,y,z:p.z+plateD*.25,w:moduleW,h,d:moduleD,ry:p.ry,facade:true},
      )
      if(b.moduleDensity>3||plateD>21||plateW>34)bodies.push({x:p.x,y:y-h*.1,z:p.z+plateD*.3,w:moduleW*.72,h:h*.8,d:moduleD*.76,ry:p.ry,facade:true})
      if(b.moduleDensity===5&&plateW>42)bodies.push({x:p.x-plateW*.08,y:y+h*.12,z:p.z-plateD*.34,w:moduleW*.62,h:h*.76,d:moduleD*.68,ry:p.ry,facade:true})
    }else if(composition==='stack'){
      const alternate=i%2===0?-1:1
      const drift=alternate*(b.cantilever*.42+b.voids*.035)
      bodies.push({x:p.x+drift,y,z:p.z-drift*.35,w:plateW*(i%3===0?.92:1),h,d:plateD*(i%2===0?1:.82),ry:p.ry,facade:true})
      if(i%Math.max(1,5-b.moduleDensity)===0)bodies.push({x:p.x-drift*.7,y,z:p.z+plateD*.28,w:plateW*.46,h:h*.72,d:plateD*.48,ry:p.ry,facade:true})
    }else if(composition==='court'){
      const edge=clamp(Math.min(plateW,plateD)*(.13+(100-b.voids)*.0013),3.2,7.5)
      const sideDepth=Math.max(3,plateD-edge*2)
      bodies.push(
        {x:p.x,y,z:p.z-plateD/2+edge/2,w:plateW,h,d:edge,ry:p.ry,facade:true},
        {x:p.x,y,z:p.z+plateD/2-edge/2,w:plateW,h,d:edge,ry:p.ry,facade:true},
        {x:p.x-plateW/2+edge/2,y,z:p.z,w:edge,h,d:sideDepth,ry:p.ry,facade:true},
        {x:p.x+plateW/2-edge/2,y,z:p.z,w:edge,h,d:sideDepth,ry:p.ry,facade:true},
      )
    }else if(b.articulation>28&&plateW>12){
      const pieces=Math.round(clamp(1+Math.floor(b.articulation/20)+Math.max(0,b.moduleDensity-3),2,7))
      const gap=clamp(.35+b.articulation*.018,.7,2.2),pieceW=Math.max(3,(plateW-gap*(pieces-1))/pieces)
      for(let piece=0;piece<pieces;piece++){
        const variance=((piece*7+i*3)%5)/4
        const pieceH=h*(.78+variance*.22),pieceY=base+tierH*i+pieceH/2
        const x=p.x-plateW/2+pieceW/2+piece*(pieceW+gap)
        const z=p.z+(((piece+i)%3)-1)*b.articulation*.022
        bodies.push({x:x+b.cantilever*.08,y:pieceY,z,w:pieceW,h:pieceH,d:plateD*(.8+((piece+i)%2)*.2),ry:p.ry,facade:true,role:'mass'})
      }
    }else{
      bodies.push({x:p.x+b.cantilever*.08,y,z:p.z,w:plateW,h,d:plateD,ry:p.ry,facade:true,role:'mass'})
    }
  }
  if(b.branches>0&&composition!=='court')for(let branch=0;branch<b.branches;branch++){
    const side=branch%2?1:-1
    const y=base+usable*(.26+((branch*29)%55)/100)
    const x=((branch%3)-1)*b.width*.24
    const reach=b.depth*.5+3+b.cantilever+branch%2*2
    bodies.push({x,y,z:side*reach*.52,w:Math.max(1.1,b.width*.14),h:.55,d:reach,facade:false,role:'transfer'})
    bodies.push({x,y:y+Math.max(2,b.floorHeight*.8),z:side*(reach+2),w:Math.max(5,b.width*(.16+b.moduleDensity*.018)),h:Math.max(b.floorHeight*1.6,usable*.12),d:Math.max(5,b.depth*.34),facade:true,role:'mass'})
  }
  return bodies
}

function specialLightColor(mood:DistrictMood, scene:ReturnType<typeof moodScene>, seed:number){
  if(mood==='cyberpunk')return ['#38f6ff','#d7ff43','#ff386c','#ffd166'][Math.abs(seed)%4]
  if(mood==='green')return seed%3===0?scene.windowAlt:scene.accent
  if(mood==='totalitarian')return seed%4===0?scene.accent:scene.lamp
  if(mood==='university')return seed%3===0?scene.windowAlt:scene.accent
  return seed%2===0?scene.window:scene.windowAlt
}

function ServiceBodyLighting({body,mood,active,index}:{body:Body;mood:DistrictMood;active:boolean;index:number}){
  if(!active||body.facade||body.kind==='capsule')return null
  const scene=moodScene(mood)
  const c=specialLightColor(mood,scene,index+Math.round(body.x*3+body.y+body.z*5))
  const intensity=mood==='cyberpunk'?1.25:mood==='totalitarian' ? .42 : .72
  if(body.role==='transfer')return <group>
    <mesh position={[body.x,body.y+body.h*.18,body.z+body.d*.52]}>
      <boxGeometry args={[Math.max(.8,body.w*.56),Math.max(.06,Math.min(.18,body.h*.18)),.08]}/>
      <meshBasicMaterial color={c} transparent opacity={mood==='totalitarian' ? .34 : .72} toneMapped={false}/>
    </mesh>
    <mesh position={[body.x,body.y-body.h*.32,body.z-body.d*.52]}>
      <boxGeometry args={[Math.max(.8,body.w*.34),Math.max(.05,Math.min(.14,body.h*.14)),.08]}/>
      <meshStandardMaterial color={c} emissive={c} emissiveIntensity={intensity*.32} roughness={.45}/>
    </mesh>
  </group>
  return <group>
    {[-.24,.24].map((offset,j)=><mesh key={j} position={[body.x+body.w*.51,body.y+body.h*offset,body.z]}>
      <boxGeometry args={[.08,Math.max(.9,Math.min(4.2,body.h*.18)),Math.max(.55,body.d*.28)]}/>
      <meshStandardMaterial color={c} emissive={c} emissiveIntensity={intensity} roughness={.38}/>
    </mesh>)}
    {mood==='cyberpunk'&&<mesh position={[body.x-body.w*.51,body.y,body.z+body.d*.18]}>
      <boxGeometry args={[.08,Math.max(1.4,body.h*.42),.18]}/>
      <meshBasicMaterial color="#ff386c" transparent opacity={.62} toneMapped={false}/>
    </mesh>}
  </group>
}

function ForumArchitecture({b,color,selected,structure,active,mood,quality}:{b:Building;color:string;selected:boolean;structure:boolean;active:boolean;mood:DistrictMood;quality:RenderQuality}){
  const scene=moodScene(mood)
  const profile=RENDER_PROFILES[quality]
  const base=buildingBase(b,.24)
  const usable=Math.max(8,b.height-base)
  const tiers=Math.round(clamp(Math.max(2,Math.ceil(usable/(b.floorHeight*2.4))),2,6))
  const tierH=usable/tiers
  const segments=Math.round(clamp(Math.round(b.width/Math.max(2.5,b.rhythm)*3+b.moduleDensity*1.5),12,38))
  const ringDepth=clamp(Math.min(b.width,b.depth)*(.18+(100-b.voids)*.001),3.2,8)
  const modules:React.ReactNode[]=[]
  for(let level=0;level<tiers;level++){
    const t=tiers===1?.5:level/(tiers-1)
    let scale=1,x=0,z=0,turn=0
    if(b.profile==='tapered')scale=1-t*b.taper*.0075
    if(b.profile==='top-heavy')scale=.68+t*(.32+b.taper*.004)
    if(b.profile==='stepped'){scale=1-t*b.taper*.0045;z=-t*(b.cantilever+b.depth*.06)}
    if(b.profile==='offset')x=(t-.5)*(b.cantilever*2+b.voids*.08)
    if(b.profile==='twisted')turn=(t-.5)*.18
    const radius=Math.max(5,(Math.min(b.width,b.depth)*.5-ringDepth*.45)*scale)
    const arc=Math.max(1.7,Math.PI*2*radius/segments*.82)
    const skipEvery=Math.max(3,Math.round(12-b.voids*.1))
    for(let i=0;i<segments;i++){
      if(b.voids>18&&(i+level*2)%skipEvery===0)continue
      const a=i/segments*Math.PI*2+turn
      const c=specialLightColor(mood,scene,i+level*11)
      const lit=active&&(i+level)%3!==0
      modules.push(<group key={`${level}-${i}`} position={[x+Math.sin(a)*radius,base+tierH*(level+.5),z+Math.cos(a)*radius]} rotation={[0,a,0]}>
        <mesh castShadow receiveShadow><boxGeometry args={[arc,tierH*.9,ringDepth]} /><meshStandardMaterial color={active&&level%2?new THREE.Color(color).lerp(new THREE.Color(c),.22).getStyle():color} emissive={lit?c:'#000'} emissiveIntensity={lit?(mood==='cyberpunk' ? .68 : .32):0} roughness={.94} wireframe={structure} transparent={structure} opacity={structure?.3:1} /></mesh>
        {lit&&mood!=='totalitarian'&&<mesh position={[0,tierH*.18,ringDepth*.52]}><boxGeometry args={[Math.max(.65,arc*.5),Math.max(.09,tierH*.045),.08]}/><meshBasicMaterial color={c} transparent opacity={.86} toneMapped={false}/></mesh>}
        {lit&&mood!=='cyberpunk'&&mood!=='totalitarian'&&profile.microLights&&level%2===0&&i%8===0&&<pointLight position={[0,0,ringDepth*.8]} color={c} intensity={2.8} distance={18} decay={1.8}/>}
      </group>)
    }
    modules.push(<group key={`slab-${level}`} position={[x,base+tierH*level+.18,z]} rotation={[Math.PI/2,0,0]}>
      <mesh><torusGeometry args={[radius,ringDepth*.48,6,Math.max(24,segments*2)]}/><meshStandardMaterial color={structure?'#d7ff43':TONES[b.tone].color} roughness={.96}/></mesh>
      {active&&<mesh position={[0,0,.12]}><torusGeometry args={[radius,Math.max(.045,ringDepth*.035),5,Math.max(24,segments*2)]}/><meshBasicMaterial color={specialLightColor(mood,scene,level)} transparent opacity={mood==='cyberpunk' ? .7 : .38} toneMapped={false}/></mesh>}
    </group>)
  }
  const topRadius=Math.max(4,Math.min(b.width,b.depth)*.34*(b.profile==='tapered'?1-b.taper*.004:1))
  return <group>
    {base>.1&&Array.from({length:Math.max(8,Math.min(18,segments))},(_,i)=>{const a=i/Math.max(8,Math.min(18,segments))*Math.PI*2;const r=Math.min(b.width,b.depth)*.34;return <mesh key={`support-${i}`} position={[Math.sin(a)*r,base/2,Math.cos(a)*r]} castShadow><cylinderGeometry args={[.3,.42,base,10]} /><meshStandardMaterial color={TONES[b.tone].color} roughness={.96} /></mesh>})}
    {modules}
    {active&&mood!=='cyberpunk'&&mood!=='totalitarian'&&profile.accentLights&&<pointLight position={[0,base+usable*.45,0]} color={scene.lamp} intensity={54*(quality==='balanced'?.62:1)} distance={Math.max(34,b.width*1.6)} decay={1.7}/>}
    <mesh position={[0,b.height+.35,0]} rotation={[Math.PI/2,0,0]} castShadow><torusGeometry args={[topRadius,Math.max(.45,ringDepth*.28),10,48]} /><meshStandardMaterial color={b.vegetation>35?'#697b59':color} roughness={.96} /></mesh>
    {b.vegetation>45&&<group position={[0,b.height+.45,0]}>{[0,1,2,3].map(i=>{const a=i*Math.PI/2+.45;return <Tree key={i} x={Math.sin(a)*topRadius*.72} z={Math.cos(a)*topRadius*.72} scale={.18}/>})}</group>}
    {Array.from({length:6},(_,i)=><mesh key={`step-${i}`} position={[0,.4+i*.36,b.depth*.42+i*.6]} castShadow><boxGeometry args={[9-i*.45,.36,2.2]} /><meshStandardMaterial color={TONES[b.tone].color} roughness={1} /></mesh>)}
    <mesh position={[0,.5,b.depth*.34]}><boxGeometry args={[4.5,3.8,.18]} /><meshStandardMaterial color="#b77b3f" emissive="#6d371a" emissiveIntensity={.1} /></mesh>
    {selected&&<mesh position={[0,base+usable/2,0]}><cylinderGeometry args={[b.width*.52,b.width*.52,usable,48,1,true]} /><meshBasicMaterial color="#d7ff43" wireframe transparent opacity={.2} /></mesh>}
  </group>
}

function StructuralSkeleton({b,body}:{b:Building;body:Body}){
  const floors=Math.max(1,Math.min(22,Math.floor(body.h/b.floorHeight)))
  const bays=Math.max(2,Math.min(7,Math.round(body.w/b.baySpacing)))
  const elements:React.ReactNode[]=[]
  for(let f=0;f<=floors;f++){
    const y=body.y-body.h/2+f*body.h/floors
    elements.push(<mesh key={`slab-${f}`} position={[body.x,y,body.z]}><boxGeometry args={[body.w*.96,.22,body.d*.96]} /><meshStandardMaterial color="#d7ff43" emissive="#8ba42b" emissiveIntensity={.2} roughness={.8} /></mesh>)
  }
  for(let i=0;i<=bays;i++){
    const x=body.x-body.w*.43+i*(body.w*.86/bays)
    for(const z of [body.z-body.d*.38,body.z+body.d*.38])elements.push(<mesh key={`col-${i}-${z}`} position={[x,body.y,z]}><boxGeometry args={[.38,body.h,.38]} /><meshStandardMaterial color={b.structural==='frame'?'#d7ff43':'#e2b65e'} emissive="#81972e" emissiveIntensity={.18} /></mesh>)
  }
  return <>{elements}</>
}

function Pilotis({ b }: { b: Building }) {
  const base=buildingBase(b)
  if (base <= .2 || ['bridge','ring','capsule','megastructure'].includes(b.composition)) return null
  const colsX = Math.max(2, Math.min(5, Math.round(b.width / b.baySpacing)))
  const xs = Array.from({ length: colsX }, (_, i) => -b.width * .42 + i * (b.width * .84 / (colsX - 1)))
  return <group>{xs.flatMap((x, i) => [-1, 1].map((side) => <mesh key={`${i}-${side}`} position={[x, base / 2, side * b.depth * .35]} castShadow>
    <cylinderGeometry args={[.33, .43, base, b.structural === 'frame' ? 12 : 4]} /><meshStandardMaterial color={TONES[b.tone].color} roughness={.96} />
  </mesh>))}<mesh position={[0, base * .42, 0]}><boxGeometry args={[b.width * .52, base * .7, b.depth * .58]} /><meshPhysicalMaterial color="#28404b" roughness={.15} metalness={.1} transmission={.1} /></mesh></group>
}

function CoreVolumes({ b }: { b: Building }) {
  if (['bridge','ring','capsule','megastructure'].includes(b.composition)) return null
  const required=Math.max(b.cores,b.height>110?3:b.height>58?2:1,b.width>36?2:1)
  const coreH=b.height*.92
  return <>{Array.from({ length: required }, (_, i) => {
    const z = (i - (required - 1) / 2) * Math.min(8, b.depth * .38)
    const x = -b.width / 2 - 1.15
    return <group key={i} position={[x, coreH/2, z]}>
      <mesh castShadow><boxGeometry args={[2.35, coreH, 4]} /><meshStandardMaterial color={TONES[b.tone].color} roughness={.98} /></mesh>
      {Array.from({ length: Math.min(16, Math.floor(coreH / 4.2)) }, (_, f) => <mesh key={f} position={[-1.185, -coreH/2+2.4+f*4.2, 0]} rotation={[0,-Math.PI/2,0]}><planeGeometry args={[1.1,.62]} /><meshStandardMaterial color="#17232a" /></mesh>)}
    </group>
  })}</>
}

function CapsuleDetails({b,bodies,active,mood,quality}:{b:Building;bodies:Body[];active:boolean;mood:DistrictMood;quality:RenderQuality}){
  const pods=bodies.filter(body=>body.kind==='capsule')
  if(!pods.length)return null
  const cores=bodies.filter(body=>body.role==='core')
  const branchArms=bodies.filter(body=>body.role==='transfer'&&body.branch)
  const scene=moodScene(mood)
  const microLights=RENDER_PROFILES[quality].microLights
  const pipeCount=quality==='low'?2:3
  const dark=mood==='totalitarian'?'#11171c':'#13232b'
  const balconyEvery=b.balconies>72?1:b.balconies>38?2:b.balconies>12?3:999
  return <>
    {pods.map((body,i)=><group key={`pod-detail-${i}`} rotation={[0,body.ry??0,0]}>
      {[-1,1].map(face=>{
        const c=specialLightColor(mood,scene,i+face*3),lit=active&&(i+face)%4!==0
        return <group key={face}>
          <mesh position={[body.x+face*body.w*.505,body.y,body.z]} rotation={[0,face*Math.PI/2,0]} scale={[body.d*.34,body.h*.34,1]}>
            <circleGeometry args={[1,quality==='low'?14:20]}/>
            <meshPhysicalMaterial color={lit?new THREE.Color(c).multiplyScalar(mood==='cyberpunk'?.82:.54).getStyle():dark} emissive={lit?c:'#000'} emissiveIntensity={lit?(mood==='cyberpunk'?1.2:.58):0} metalness={.26} roughness={lit?.1:.22}/>
          </mesh>
          {(quality==='high'||body.branch||body.crown)&&<mesh position={[body.x+face*body.w*.512,body.y,body.z]} rotation={[0,face*Math.PI/2,0]} scale={[body.d*.41,body.h*.41,1]}>
            <torusGeometry args={[1,.08,7,20]}/><meshStandardMaterial color={lit?new THREE.Color(TONES[b.tone].color).lerp(new THREE.Color(c),.28).getStyle():TONES[b.tone].color} emissive={lit?c:'#000'} emissiveIntensity={lit?.2:0} roughness={.88}/>
          </mesh>}
        </group>
      })}
      {quality!=='low'&&[-.2,.2].slice(0,quality==='high'?2:1).map((offset,j)=>{
        const c=specialLightColor(mood,scene,i+j*5),lit=active&&(i+j)%3!==0
        return <mesh key={`side-port-${j}`} position={[body.x+body.w*offset,body.y,body.z+body.d*.505]} scale={[body.w*.095,body.h*.22,1]}>
          <circleGeometry args={[1,14]}/><meshPhysicalMaterial color={lit?new THREE.Color(c).multiplyScalar(.62).getStyle():dark} emissive={lit?c:'#000'} emissiveIntensity={lit?.54:0} roughness={lit?.12:.24} metalness={.2}/>
        </mesh>
      })}
      <mesh position={[body.x,body.y-body.h*.47,body.z+body.d*.54]}><boxGeometry args={[body.w*.56,Math.max(.06,body.h*.055),.08]}/><meshBasicMaterial color={specialLightColor(mood,scene,i+17)} transparent opacity={active?(mood==='cyberpunk'?.86:.5):.1} toneMapped={false}/></mesh>
      {i%balconyEvery===0&&<mesh position={[body.x,body.y-body.h*.57,body.z]}><boxGeometry args={[body.w*.46,.12,body.d*1.14]}/><meshStandardMaterial color={TONES[b.tone].color} roughness={.92}/></mesh>}
    </group>)}
    {cores.map((core,i)=><group key={`service-spine-${i}`} rotation={[0,core.ry??0,0]}>
      {Array.from({length:pipeCount},(_,pipe)=>{const offset=(pipe-(pipeCount-1)/2)*core.w*.24,c=specialLightColor(mood,scene,i*7+pipe);return <mesh key={pipe} position={[core.x+offset,core.y,core.z+core.d*.52]}><boxGeometry args={[.14,core.h*.9,.13]}/><meshStandardMaterial color={c} emissive={active?c:'#000'} emissiveIntensity={active?(mood==='cyberpunk'?.68:.22):0} roughness={.44} metalness={.52}/></mesh>})}
      {Array.from({length:Math.min(5,Math.max(1,b.terraces+1))},(_,band)=><mesh key={`service-band-${band}`} position={[core.x,core.h*(band+1)/(Math.min(5,Math.max(1,b.terraces+1))+1),core.z]}><boxGeometry args={[core.w*1.28,.2,core.d*1.3]}/><meshStandardMaterial color="#59605c" roughness={.84} metalness={.16}/></mesh>)}
    </group>)}
    {branchArms.map((arm,i)=>{
      const direction=Math.sign(arm.z)||1
      const end=bodyWorldPoint(arm,[arm.x,arm.y+arm.h*.55,arm.z+direction*arm.d*.5])
      const startY=Math.min(b.height*.92,Math.max(end.y+5,b.height*(.58+i*.025)))
      const c=specialLightColor(mood,scene,i+31)
      return <group key={`branch-rig-${i}`}>
        <BeamBetween from={[0,startY,0]} to={[end.x,end.y,end.z]} width={.052} color={mood==='cyberpunk'?'#17353c':'#444b49'}/>
        <mesh position={end} raycast={()=>null}><octahedronGeometry args={[.34,0]}/><meshStandardMaterial color={c} emissive={c} emissiveIntensity={active?1.5:.15} metalness={.5}/></mesh>
        {(mood==='green'||b.vegetation>55)&&<group position={[end.x,arm.y+arm.h*.8,end.z-direction*arm.d*.28]}><mesh><boxGeometry args={[Math.max(2.2,arm.w*2.2),.24,Math.max(2.6,arm.d*.36)]}/><meshStandardMaterial color="#4f744f" roughness={1}/></mesh></group>}
      </group>
    })}
    {active&&mood!=='cyberpunk'&&mood!=='totalitarian'&&microLights&&pods.filter((_,i)=>i%Math.max(1,Math.ceil(pods.length/4))===0).slice(0,4).map((body,i)=>{const c=specialLightColor(mood,scene,i+53);const position=bodyWorldPoint(body,[body.x+body.w*.58,body.y,body.z]);return <pointLight key={`pod-light-${i}`} position={position} color={c} intensity={2.4} distance={18} decay={1.8}/>})}
  </>
}

function CantileverStructure({b}:{b:Building}){
  if(b.cantilever<1.5||['ring','capsule','megastructure'].includes(b.composition))return null
  const base=Math.min(b.pilotis,b.height*.28),usable=Math.max(7,b.height-base),floors=Math.max(1,Math.floor(usable/b.floorHeight)),tiers=Math.round(clamp(Math.max(b.terraces,Math.ceil(floors/7)),1,6)),tierH=usable/tiers
  const braces:React.ReactNode[]=[]
  for(let i=1;i<tiers;i++){
    const t=i/(tiers-1),y=base+tierH*i+.2,shift=t*b.cantilever*.42
    for(const face of [-1,1]){
      const z=face*b.depth*.47
      braces.push(<BeamBetween key={`a-${i}-${face}`} from={[0,y-tierH*.42,z]} to={[shift+b.width*.4,y,z]} width={.32} color="#4d514d"/>,<BeamBetween key={`b-${i}-${face}`} from={[0,y-tierH*.42,z]} to={[shift-b.width*.4,y,z]} width={.32} color="#4d514d"/>)
    }
  }
  return <group>{braces}</group>
}

function Roofscape({ b,bodies }: { b: Building;bodies:Body[] }) {
  const inhabitable=bodies.filter(body=>body.facade&&body.kind!=='capsule')
  const candidates=inhabitable.length?inhabitable:bodies.filter(body=>body.role!=='transfer'&&body.kind!=='capsule')
  if(!candidates.length)return null
  const topBody=candidates.reduce((highest,body)=>body.y+body.h/2>highest.y+highest.h/2?body:highest)
  const center=new THREE.Vector3(topBody.x,0,topBody.z).applyAxisAngle(new THREE.Vector3(0,1,0),topBody.ry??0)
  const offset=new THREE.Vector3(topBody.w*.22,0,-topBody.d*.18).applyAxisAngle(new THREE.Vector3(0,1,0),topBody.ry??0)
  const top=topBody.y+topBody.h/2
  const plantW=clamp(topBody.w*(.2+b.crown*.0018),2,8),plantD=clamp(topBody.d*(.22+b.crown*.0015),2,7)
  const plantH=.65+b.crown*.026
  return <>
    {b.crown>6&&<mesh position={[center.x,top+plantH/2,center.z]} rotation={[0,topBody.ry??0,0]} castShadow><boxGeometry args={[plantW,plantH,plantD]} /><meshStandardMaterial color="#555951" roughness={1} /></mesh>}
    {b.crown>28&&<group position={[center.x,top+plantH,center.z]}><mesh position={[0,(2+b.crown*.055)/2,0]}><cylinderGeometry args={[.1,.18,2+b.crown*.055,8]} /><meshStandardMaterial color="#353a38" metalness={.65} /></mesh><mesh position={[0,2+b.crown*.055,0]}><sphereGeometry args={[.26,8,8]} /><meshStandardMaterial color={b.crown>62?'#ff6b4a':'#d7ff43'} emissive={b.crown>62?'#ff3b22':'#d7ff43'} emissiveIntensity={2.4} /></mesh></group>}
    {b.crown>48&&<mesh position={[center.x+offset.x,top+(1.2+b.crown*.018)/2,center.z+offset.z]} castShadow><cylinderGeometry args={[.7+b.crown*.006,.7+b.crown*.006,1.2+b.crown*.018,16]} /><meshStandardMaterial color="#343b3b" metalness={.42} roughness={.62} /></mesh>}
  </>
}

function GreenRoof({b,bodies}:{b:Building;bodies:Body[]}){
  if(b.vegetation<8||b.composition==='ring'||!bodies.length)return null
  const inhabitable=bodies.filter(body=>body.facade&&body.kind!=='capsule')
  if(!inhabitable.length)return null
  const roofCount=b.vegetation>70?inhabitable.length:b.vegetation>32?Math.ceil(inhabitable.length/2):1
  const roofs=(['stack','cluster','court'].includes(b.composition)?inhabitable:inhabitable.slice(-1)).slice(-Math.min(roofCount,8))
  return <>{roofs.map((body,i)=><group key={i} rotation={[0,body.ry??0,0]}><group position={[body.x,body.y+body.h/2+.16,body.z]}>
    <mesh receiveShadow><boxGeometry args={[body.w*.58,.25,body.d*.42]} /><meshStandardMaterial color="#647654" roughness={1} /></mesh>
    {i%2===0&&<><mesh position={[body.w*.18,.38,0]}><boxGeometry args={[body.w*.18,.55,body.d*.2]} /><meshStandardMaterial color="#716e61" roughness={1} /></mesh><Tree x={-body.w*.15} z={0} scale={.2}/></>}
  </group></group>)}</>
}

function CharacterDetails({b,bodies}:{b:Building;bodies:Body[]}){
  const masses=bodies.filter(body=>body.facade&&body.kind!=='capsule')
  const village=b.composition==='cluster'&&b.height<36&&b.articulation>56&&b.moduleDensity>2
  const noir=b.height>72&&b.crown>55&&b.branches>2&&(['charcoal','terracotta'].includes(b.tone))
  const arcology=b.height>48&&b.vegetation>58&&b.articulation>45&&!controlDisabledReason(b,'articulation')&&!controlDisabledReason(b,'branches')
  return <>
    {village&&masses.filter(body=>body.y+body.h/2>b.height*.52).slice(-14).map((body,i)=>{
      const angle=.43,roofD=Math.max(2,body.d*.58),rise=Math.sin(angle)*roofD*.5
      return <group key={`roof-${i}`} position={[body.x,body.y+body.h/2+rise*.46,body.z]} rotation={[0,body.ry??0,0]}>
        <mesh position={[0,rise*.25,-body.d*.22]} rotation={[angle,0,0]} castShadow><boxGeometry args={[body.w*1.04,.24,roofD]}/><meshStandardMaterial color={b.tone==='terracotta'?'#743e32':'#5a5549'} roughness={1}/></mesh>
        <mesh position={[0,rise*.25,body.d*.22]} rotation={[-angle,0,0]} castShadow><boxGeometry args={[body.w*1.04,.24,roofD]}/><meshStandardMaterial color={b.tone==='terracotta'?'#874a39':'#6b6555'} roughness={1}/></mesh>
        {i%3===0&&<mesh position={[body.w*.28,rise*.75,0]} castShadow><boxGeometry args={[.65,rise+1,.65]}/><meshStandardMaterial color="#57534b" roughness={1}/></mesh>}
      </group>
    })}
    {noir&&masses.slice(0,22).map((body,i)=>i%2===0?<group key={`neon-${i}`} position={[body.x,body.y,body.z+body.d/2+.08]} rotation={[0,body.ry??0,0]}>
      <mesh position={[((i%3)-1)*body.w*.2,0,0]}><boxGeometry args={[Math.max(.18,body.w*.025),body.h*.46,.08]}/><meshStandardMaterial color={i%4===0?'#ff315a':'#46d7ff'} emissive={i%4===0?'#ff1f3d':'#1caeff'} emissiveIntensity={3}/></mesh>
    </group>:null)}
    {arcology&&b.branches>1&&Array.from({length:Math.min(4,b.branches)},(_,i)=>{
      const y=b.height*(.3+i*.14),side=i%2?1:-1
      return <group key={`garden-bridge-${i}`} position={[0,y,side*(b.depth*.42+b.cantilever*.35)]}>
        <mesh><boxGeometry args={[b.width*.48,.45,2.6]}/><meshStandardMaterial color="#6d715f" roughness={1}/></mesh>
        <mesh position={[0,.34,0]}><boxGeometry args={[b.width*.42,.24,1.65]}/><meshStandardMaterial color="#58714d" roughness={1}/></mesh>
      </group>
    })}
  </>
}

function MoodBuildingDetails({b,bodies,mood,night,quality}:{b:Building;bodies:Body[];mood:DistrictMood;night:boolean;quality:RenderQuality}){
  if(mood==='default'||b.composition==='ring')return null
  const masses=bodies.filter(body=>body.facade&&body.kind!=='capsule')
  if(!masses.length)return null
  const scene=moodScene(mood)
  const profile=RENDER_PROFILES[quality]
  const top=masses.reduce((highest,body)=>body.y+body.h/2>highest.y+highest.h/2?body:highest,masses[0])
  const facadeLimit=quality==='low'?4:quality==='balanced'?6:8
  const facadeSet=masses.filter((_,i)=>i%2===0).slice(0,facadeLimit)

  if(mood==='cyberpunk'){
    const signColors=[scene.window,scene.accent,'#ff386c','#ffd166','#f4fff8']
    const labels=['mesh-a','relay-07','stack-cut','illegal-skin','service-12','wet-node']
    return <>
      {facadeSet.slice(0,quality==='low'?2:3).map((body,i)=><group key={`cyber-sign-${i}`} rotation={[0,body.ry??0,0]}>
        <mesh position={[body.x+((i%3)-1)*body.w*.18,body.y+body.h*(i%2?.18:.08),body.z+body.d/2+.13]}>
          <boxGeometry args={[clamp(body.w*(.28+(i%2)*.12),3.8,11.5),clamp(body.h*.08,1.1,2.8),.22]}/>
          <meshStandardMaterial color="#071015" emissive={signColors[i%signColors.length]} emissiveIntensity={night ? .95 : .12} roughness={.58} metalness={.45}/>
        </mesh>
        <SignPanel text={labels[i%labels.length]} variant="glyph" width={clamp(body.w*(.26+(i%2)*.11),3.6,11)} height={clamp(body.h*.072,1,2.55)} bg="#02070d" fg={signColors[i%signColors.length]} accent={i%2?scene.accent:'#ff386c'} position={[body.x+((i%3)-1)*body.w*.18,body.y+body.h*(i%2?.18:.08),body.z+body.d/2+.26]} opacity={night?1:.72}/>
        <mesh position={[body.x+((i%3)-1)*body.w*.18,body.y+body.h*(i%2?.18:.08)-clamp(body.h*.052,.72,1.8),body.z+body.d/2+.32]}>
          <boxGeometry args={[clamp(body.w*(.34+(i%2)*.16),4.4,13),.18,.14]}/>
          <meshBasicMaterial color={signColors[(i+2)%signColors.length]} transparent opacity={night?.95:.38} toneMapped={false}/>
        </mesh>
        <mesh position={[body.x-body.w*.44,body.y-body.h*.18,body.z+body.d/2+.14]}>
          <boxGeometry args={[.16,clamp(body.h*.34,3.2,12),.14]}/>
          <meshStandardMaterial color="#1d3b42" emissive={scene.window} emissiveIntensity={night ? 1.8 : .14}/>
        </mesh>
        <mesh position={[body.x+body.w*.44,body.y+body.h*.08,body.z+body.d/2+.16]}>
          <boxGeometry args={[.13,clamp(body.h*.42,4,15),.16]}/>
          <meshBasicMaterial color={signColors[(i+1)%signColors.length]} transparent opacity={night?.88:.26} toneMapped={false}/>
        </mesh>
        {[0,1,2].map(j=><mesh key={`duct-${j}`} position={[body.x-body.w*.28+j*body.w*.18,body.y-body.h*.31,body.z+body.d/2+.2]}>
          <boxGeometry args={[clamp(body.w*.11,1,2.8),.42,.38]}/>
          <meshStandardMaterial color={j%2?'#17242a':'#263139'} roughness={.68} metalness={.45}/>
        </mesh>)}
        <BeamBetween from={[body.x-body.w*.46,body.y-body.h*.06,body.z+body.d/2+.24]} to={[body.x+body.w*.44,body.y-body.h*.22,body.z+body.d/2+.24]} width={.055} color="#15272d"/>
      </group>)}
      <group position={[top.x,top.y+top.h/2,top.z]} rotation={[0,top.ry??0,0]}>
        <mesh position={[0,2.7,0]}><cylinderGeometry args={[.08,.16,5.4,7]}/><meshStandardMaterial color="#22313a" metalness={.7} roughness={.36}/></mesh>
        <mesh position={[0,5.65,0]}><octahedronGeometry args={[.46,0]}/><meshStandardMaterial color={scene.accent} emissive={scene.accent} emissiveIntensity={night?3.6:.32}/></mesh>
        <BeamBetween from={[-top.w*.32,3.8,-top.d*.24]} to={[top.w*.34,4.9,top.d*.2]} width={.045} color="#172a30"/>
        <BeamBetween from={[top.w*.22,3.2,-top.d*.26]} to={[-top.w*.18,5.3,top.d*.25]} width={.035} color="#2f3f3e"/>
      </group>
    </>
  }

  if(mood==='totalitarian'){
    const featuredSearchlights=hashText(b.id)%2===0
    return <>
      {facadeSet.map((body,i)=><group key={`state-banner-${i}`} rotation={[0,body.ry??0,0]}>
        <mesh position={[body.x-body.w*.32,body.y+body.h*.08,body.z+body.d/2+.13]}>
          <boxGeometry args={[clamp(body.w*.11,1.1,2.6),clamp(body.h*.62,4.8,21),.16]}/>
          <meshStandardMaterial color="#7b1015" emissive="#2b0205" emissiveIntensity={night?.42:.04} roughness={.78}/>
        </mesh>
        <mesh position={[body.x+body.w*.32,body.y+body.h*.08,body.z+body.d/2+.13]}>
          <boxGeometry args={[clamp(body.w*.08,.9,2),clamp(body.h*.46,3.8,16),.15]}/>
          <meshStandardMaterial color="#26323a" emissive={scene.lamp} emissiveIntensity={night?.16:0} roughness={.72}/>
        </mesh>
      </group>)}
      <group position={[top.x,top.y+top.h/2,top.z]} rotation={[0,top.ry??0,0]}>
        <mesh position={[-top.w*.26,1.1,top.d*.36]}><boxGeometry args={[1.8,2.2,1.2]}/><meshStandardMaterial color="#1b2024" metalness={.25}/></mesh>
        <mesh position={[top.w*.26,1.1,top.d*.36]}><boxGeometry args={[1.8,2.2,1.2]}/><meshStandardMaterial color="#1b2024" metalness={.25}/></mesh>
      </group>
      {night&&featuredSearchlights&&[-.34,.34].map((x,i)=><group key={`underlight-${i}`} position={[x*b.width,0,b.depth/2+2.6]}>
        <mesh position={[0,.42,0]}><boxGeometry args={[3.4,.26,1.1]}/><meshStandardMaterial color="#15191d" emissive={scene.lamp} emissiveIntensity={.28}/></mesh>
        <GlowBeam from={[0,.55,0]} to={[0,24,0]} radius={3.7} color={scene.lamp} opacity={.1}/>
      </group>)}
      {night&&featuredSearchlights&&<group position={[0,Math.min(b.height*.58,58),b.depth/2+3.5]}>
        <GlowBeam from={[-b.width*.42,0,0]} to={[b.width*.42,Math.min(20,b.height*.22),-b.depth*.38]} radius={1.1} color={scene.lamp} opacity={.12}/>
        <GlowBeam from={[b.width*.42,0,0]} to={[-b.width*.42,Math.min(20,b.height*.22),-b.depth*.38]} radius={1.1} color={scene.lamp} opacity={.12}/>
      </group>}
    </>
  }

  if(mood==='green'){
    return <>
      {facadeSet.map((body,i)=><group key={`bio-facade-${i}`} rotation={[0,body.ry??0,0]}>
        <mesh position={[body.x-body.w*.34,body.y,body.z+body.d/2+.12]}>
          <boxGeometry args={[clamp(body.w*.08,.75,2.2),body.h*.72,.12]}/>
          <meshStandardMaterial color="#3f6b49" emissive="#7fe083" emissiveIntensity={night?.32:.04} roughness={1}/>
        </mesh>
        <mesh position={[body.x+body.w*.08,body.y+body.h*.05,body.z+body.d/2+.13]}>
          <boxGeometry args={[clamp(body.w*.34,3,11),.5,.16]}/>
          <meshStandardMaterial color={i%2?'#6c8c54':'#4f7651'} emissive="#7fe083" emissiveIntensity={night?.24:.02} roughness={1}/>
        </mesh>
        <mesh position={[body.x,body.y+body.h/2+.18,body.z]}><boxGeometry args={[body.w*.5,.18,body.d*.34]}/><meshStandardMaterial color="#54714c" roughness={1}/></mesh>
      </group>)}
    </>
  }

  return <>
    {facadeSet.slice(0,7).map((body,i)=><group key={`campus-banners-${i}`} rotation={[0,body.ry??0,0]}>
      <mesh position={[body.x-body.w*.36,body.y+body.h*.06,body.z+body.d/2+.14]}>
        <boxGeometry args={[clamp(body.w*.09,.9,2.2),clamp(body.h*.42,3.6,13),.15]}/>
        <meshStandardMaterial color={i%2?'#234b78':'#b99b43'} emissive={i%2?'#102b4c':'#4d390e'} emissiveIntensity={night?.22:.02} roughness={.72}/>
      </mesh>
      <mesh position={[body.x+body.w*.12,body.y-body.h*.12,body.z+body.d/2+.16]}>
        <boxGeometry args={[clamp(body.w*.48,4.2,13),clamp(body.h*.045,.7,1.35),.18]}/>
        <meshStandardMaterial color={scene.windowAlt} emissive={scene.windowAlt} emissiveIntensity={night?1.25:.1} roughness={.45}/>
      </mesh>
    </group>)}
  </>
}

function programOccupancy(b:Building,hour:number,signals:CitySignals){
  const h=(hour+24)%24
  let use=b.program==='housing'?(h>=18||h<7?.86:.44)
    :b.program==='work'?(h>=7&&h<19?.92:.12)
      :b.program==='civic'?(h>=8&&h<20?.76:.15)
        :b.program==='culture'?(h>=14&&h<23?.9:h>=10?.34:.1)
          :(h>=7&&h<23?.72:.42)
  if(signals.sharedRooms&&['housing','mixed','civic'].includes(b.program))use+=.08
  if(h>=21||h<6)use*=signals.nightAccess==='open'?1.18:signals.nightAccess==='quiet'?.62:.78
  return clamp(use*(.54+signals.activity*.0046),.04,1)
}

function CharterEvidence({b,signals,night}:{b:Building;signals:CitySignals;night:boolean}){
  const seed=hashText(b.id),front=b.depth/2+.18
  const eligibleCommons=['housing','mixed','civic'].includes(b.program)
  return <>
    {signals.sharedRooms&&eligibleCommons&&<mesh position={[0,Math.min(5.2,Math.max(2.5,b.height*.12)),front]}><boxGeometry args={[Math.max(3.8,b.width*.46),.72,.16]}/><meshStandardMaterial color={night?'#ffc86b':'#876f49'} emissive={night?'#ffc86b':'#000000'} emissiveIntensity={night?.88:0} roughness={.58}/></mesh>}
    {signals.reuse&&seed%2===0&&[[-.22,.24],[.19,.38]].map(([x,y],i)=><mesh key={`reuse-panel-${i}`} position={[b.width*x,Math.max(4,b.height*y),front+.03]}><boxGeometry args={[Math.max(2.2,b.width*(i?.16:.22)),Math.max(1.1,Math.min(4,b.height*.08)),.12]}/><meshStandardMaterial color={i?'#7b776d':'#9a8068'} roughness={1}/></mesh>)}
    {signals.formal&&<mesh position={[0,Math.max(4,b.height*.22),front+.02]}><boxGeometry args={[b.width*.72,.18,.13]}/><meshStandardMaterial color="#c4c2b9" roughness={.84}/></mesh>}
    {night&&signals.nightAccess==='open'&&b.pilotis>1.2&&seed%2===0&&[-1,0,1].map((slot,i)=><group key={`night-stall-${i}`} position={[slot*Math.min(3.4,b.width*.18),.9,front+1.2]}><mesh position={[0,.82,0]}><boxGeometry args={[2.4,.12,1.4]}/><meshStandardMaterial color={i%2?'#d7ff43':'#e28a55'} emissive={i%2?'#7d9325':'#8a3a1f'} emissiveIntensity={.42}/></mesh><mesh><boxGeometry args={[1.9,1.2,1.1]}/><meshStandardMaterial color="#4c4640" roughness={.9}/></mesh></group>)}
    {signals.nightAccess==='quiet'&&b.pilotis>1.2&&seed%2===0&&<group position={[0,.42,front+.9]}>{[-1,0,1].map((slot,i)=><group key={`quiet-garden-${i}`} position={[slot*Math.min(3.6,b.width*.2),0,0]}><mesh><boxGeometry args={[2.7,.72,1.5]}/><meshStandardMaterial color="#796f5e" roughness={1}/></mesh><mesh position={[0,.48,0]}><boxGeometry args={[2.3,.22,1.15]}/><meshStandardMaterial color={i%2?'#647b56':'#536c50'} roughness={1}/></mesh>{night&&<mesh position={[0,.72,.72]}><boxGeometry args={[.18,.26,.12]}/><meshStandardMaterial color="#ffd99a" emissive="#ffd99a" emissiveIntensity={.62}/></mesh>}</group>)}</group>}
    {signals.specialistGrowth&&['work','culture'].includes(b.program)&&<group><mesh position={[0,Math.min(7,b.height*.18),front+.04]}><boxGeometry args={[Math.max(4,b.width*.54),.42,.13]}/><meshStandardMaterial color={b.program==='culture'?'#bc86de':'#7aa4e8'} emissive={night?(b.program==='culture'?'#bc86de':'#7aa4e8'):'#000000'} emissiveIntensity={night?.72:0} roughness={.48}/></mesh><mesh position={[b.width*.31,2.1,front+.45]}><boxGeometry args={[Math.max(1.8,b.width*.13),2.8,.5]}/><meshStandardMaterial color="#6a6257" roughness={.82}/></mesh></group>}
  </>
}

function PreviewForum({b,color}:{b:Building;color:string}){
  const radius=Math.max(5,Math.min(b.width,b.depth)*.34)
  return <group>
    <mesh position={[0,b.height*.47,0]} castShadow><cylinderGeometry args={[radius,radius,b.height*.88,24,1,true]}/><meshStandardMaterial color={color} roughness={.94} side={THREE.DoubleSide}/></mesh>
    <mesh position={[0,b.height*.92,0]} rotation={[Math.PI/2,0,0]}><torusGeometry args={[radius,Math.max(.65,Math.min(b.width,b.depth)*.055),7,32]}/><meshStandardMaterial color={color} roughness={.92}/></mesh>
    <mesh position={[0,.5,0]}><cylinderGeometry args={[radius*.72,radius*.8,1,24]}/><meshStandardMaterial color="#77786f" roughness={1}/></mesh>
  </group>
}

function BrutalistBuilding({ b, selected, viewMode, night, mood, quality, occupancy, signals, preview=false, compactPreview=false, onClick, onChange, onEditStart, onManipulating }: { b: Building; selected: boolean; viewMode: ViewMode; night:boolean; mood:DistrictMood; quality:RenderQuality;occupancy:number;signals:CitySignals;preview?:boolean;compactPreview?:boolean; onClick?: () => void; onChange:(patch:Partial<Building>)=>void; onEditStart:()=>void; onManipulating:(active:boolean)=>void }) {
  const [hovered, setHovered] = useState(false)
  const color = viewColor(b, viewMode)
  const scene=moodScene(mood)
  const profile=RENDER_PROFILES[quality]
  const specialLightingActive=(night&&occupancy>.18)||viewMode==='activity'
  const activeFacade:FacadeStrategy=b.composition==='cluster'&&b.height<36&&b.articulation>56&&b.moduleDensity>2?'punched':b.facade
  const accent:Record<Building['program'],string>={housing:'#92513f',work:'#516975',civic:'#aa923e',culture:'#a95847',mixed:'#697951'}
  const bodies = useMemo(() => structuralBodies(b), [b])
  const pendingPatch=useRef<Partial<Building>|null>(null)
  const patchFrame=useRef<number|null>(null)
  const applyPendingChange=useCallback(()=>{
    const next=pendingPatch.current
    pendingPatch.current=null
    if(next)onChange(next)
  },[onChange])
  const scheduleChange=useCallback((patch:Partial<Building>)=>{
    pendingPatch.current={...pendingPatch.current,...patch}
    if(patchFrame.current!==null)return
    patchFrame.current=window.requestAnimationFrame(()=>{
      patchFrame.current=null
      applyPendingChange()
    })
  },[applyPendingChange])
  const flushChange=useCallback(()=>{
    if(patchFrame.current!==null){window.cancelAnimationFrame(patchFrame.current);patchFrame.current=null}
    applyPendingChange()
  },[applyPendingChange])
  useEffect(()=>()=>{if(patchFrame.current!==null)window.cancelAnimationFrame(patchFrame.current)},[])
  const handleManipulating=useCallback((active:boolean)=>{
    if(!active)flushChange()
    onManipulating(active)
  },[flushChange,onManipulating])
  const buildingLightSeed=hashText(b.id)
  const buildingLight=!preview&&night&&mood!=='cyberpunk'&&mood!=='totalitarian'&&occupancy>.42&&profile.accentLights&&(selected||quality==='high'||buildingLightSeed%Math.max(2,Math.round(5-occupancy*3))===0)
  return <group position={[b.x, LOT_SURFACE_Y, b.z]} rotation={[0, b.rotation * Math.PI / 180, 0]} onClick={onClick?e => { e.stopPropagation(); onClick() }:undefined} onPointerOver={onClick?e => { e.stopPropagation(); setHovered(true); document.body.style.cursor='pointer' }:undefined} onPointerOut={onClick?() => { setHovered(false); document.body.style.cursor='default' }:undefined}>
    <mesh position={[0,.22,0]} receiveShadow><boxGeometry args={[b.width+5,.44,b.depth+5]} /><meshStandardMaterial color="#77786f" roughness={1} /></mesh>
    {b.composition!=='ring'&&<Pilotis b={b} />}
    {b.composition==='ring'?(preview&&compactPreview?<PreviewForum b={b} color={color}/>:<ForumArchitecture b={b} color={color} selected={selected} structure={viewMode==='structure'} active={!preview&&specialLightingActive} mood={mood} quality={quality}/>):bodies.map((body,i) => <group key={`${b.composition}-${body.kind??'box'}-${body.role??'mass'}-${i}`} rotation={[0,body.ry??0,0]}><ConcreteBody body={body} color={color} selected={selected} hovered={hovered} ghost={viewMode==='structure'} />{viewMode==='structure'?(b.composition!=='capsule'||body.role==='core'?<StructuralSkeleton b={b} body={body}/>:null):<>{!compactPreview&&<ConstructionJoints body={body} tone={b.tone} />}<FacadeLayer b={b} body={body} strategy={activeFacade} mode={viewMode} night={night} mood={mood} quality={quality} occupancy={occupancy}/>{!preview&&<ServiceBodyLighting body={body} mood={mood} active={specialLightingActive} index={i}/>}</>}</group>)}
    {selected&&b.composition==='capsule'&&<mesh position={[0,b.height*.5,0]} raycast={()=>null}><boxGeometry args={[Math.max(8,b.width+b.cantilever*2),b.height,Math.max(8,b.depth+(5+b.cantilever)*2)]}/><meshBasicMaterial color="#d7ff43" wireframe transparent opacity={.075}/></mesh>}
    {b.composition==='capsule'&&<CapsuleDetails b={b} bodies={bodies} active={!preview&&specialLightingActive} mood={mood} quality={quality}/>} {!compactPreview&&<CantileverStructure b={b}/>}
    {b.composition!=='ring'&&<>{!compactPreview&&<CoreVolumes b={b} />}<Roofscape b={b} bodies={bodies}/></>}
    <GreenRoof b={b} bodies={bodies}/>
    {(!preview||!compactPreview)&&<CharacterDetails b={b} bodies={bodies}/>} {!preview&&<><MoodBuildingDetails b={b} bodies={bodies} mood={mood} night={night} quality={quality}/><CharterEvidence b={b} signals={signals} night={night}/></>}
    <mesh position={[0,.08,b.depth/2+2.1]} castShadow><boxGeometry args={[Math.min(9,b.width*.5),.16,3.4]} /><meshStandardMaterial color="#aaa69a" roughness={1} /></mesh>
    {b.composition!=='ring'&&<><mesh position={[0,1.85,b.depth/2+.13]}><boxGeometry args={[Math.min(5.2,b.width*.3),3.2,.22]} /><meshStandardMaterial color={accent[b.program]} roughness={.7} /></mesh><mesh position={[0,3.7,b.depth/2+1.15]} castShadow><boxGeometry args={[Math.min(7,b.width*.4),.24,2.25]} /><meshStandardMaterial color={TONES[b.tone].color} roughness={.95} /></mesh></>}
    {buildingLight&&<pointLight position={[0,Math.max(6,b.height*.44),0]} color={scene.window} intensity={Math.min(42,10+b.height*.12)*scene.windowIntensity*(quality==='balanced'?.52:1)} distance={Math.max(24,Math.min(86,Math.max(b.width,b.depth)*1.7))} decay={1.9}/>}
    {selected&&<MassingGizmo b={b} onChange={scheduleChange} onStart={onEditStart} onManipulating={handleManipulating}/>}
  </group>
}

function Tree({ x, z, scale = 1 }: { x: number; z: number; scale?: number }) {
  return <group position={[x,0,z]} scale={scale}><mesh position={[0,2.2,0]} castShadow><cylinderGeometry args={[.16,.26,4.4,8]} /><meshStandardMaterial color="#4a3727" roughness={1} /></mesh><mesh position={[0,4.8,0]} castShadow><icosahedronGeometry args={[2.25,2]} /><meshStandardMaterial color="#536249" roughness={1} /></mesh><mesh position={[.9,4.1,.2]} castShadow><icosahedronGeometry args={[1.55,1]} /><meshStandardMaterial color="#647054" roughness={1} /></mesh></group>
}

function Palm({x,z,scale=1}:{x:number;z:number;scale?:number}){
  return <group position={[x,0,z]} scale={scale}><mesh position={[0,2.7,0]} rotation={[0,0,-.06]} castShadow><cylinderGeometry args={[.13,.28,5.4,9]} /><meshStandardMaterial color="#76523a" roughness={1} /></mesh><group position={[0,5.25,0]}>{Array.from({length:7},(_,i)=>{const a=i/7*Math.PI*2;return <mesh key={i} position={[Math.sin(a)*1.15,.05,Math.cos(a)*1.15]} rotation={[.12,a,Math.sin(a)*.22]} castShadow><boxGeometry args={[.36,.1,2.8]} /><meshStandardMaterial color={i%2?'#506f4b':'#617e54'} roughness={1} /></mesh>})}</group></group>
}

function Human({ x, z, color = '#b74e3d' }: { x: number; z: number; color?: string }) {
  return <group position={[x,.35,z]}><mesh position={[0,1.3,0]} castShadow><capsuleGeometry args={[.2,1.05,4,8]} /><meshStandardMaterial color={color} roughness={.85} /></mesh><mesh position={[0,2.05,0]} castShadow><sphereGeometry args={[.24,10,10]} /><meshStandardMaterial color="#9a755e" roughness={.9} /></mesh></group>
}

function PlazaObject({ plaza, selected, interactive=true, onClick }: { plaza: Plaza; selected: boolean;interactive?:boolean;onClick:()=>void }) {
  const [hovered,setHovered]=useState(false)
  const trees = Array.from({ length: plaza.trees }, (_, i) => {
    const a = i / plaza.trees * Math.PI * 2
    return plaza.kind==='water'&&i%2===0?<Palm key={i} x={Math.cos(a)*8.2} z={Math.sin(a)*8.2} scale={.76+(i%3)*.06}/>:<Tree key={i} x={Math.cos(a)*8.2} z={Math.sin(a)*8.2} scale={.78 + (i%3)*.08} />
  })
  return <group position={[plaza.x,.3,plaza.z]} onClick={interactive?e=>{e.stopPropagation();onClick()}:undefined} onPointerOver={interactive?e=>{e.stopPropagation();setHovered(true);document.body.style.cursor='pointer'}:undefined} onPointerOut={interactive?()=>{setHovered(false);document.body.style.cursor='default'}:undefined}>
    <mesh receiveShadow><boxGeometry args={[CELL-5,.6,CELL-5]} /><meshStandardMaterial color={selected ? '#cde83e' : plaza.kind==='garden'?'#948e78':'#b4a78f'} roughness={1} />{(selected||hovered)&&<Edges color={selected?'#d7ff43':'#f5ebcd'} lineWidth={1.4}/>}</mesh>
    {plaza.kind==='water'&&<><mesh position={[0,.37,0]}><boxGeometry args={[20,.22,7.5]} /><meshStandardMaterial color="#5b6965" roughness={1} /></mesh><mesh position={[0,.51,0]}><boxGeometry args={[18.8,.08,6.4]} /><meshPhysicalMaterial color="#77a9b5" roughness={.08} metalness={.1} transmission={.22} transparent opacity={.9} /></mesh>{[-7,-3.5,0,3.5,7].map((x,i)=><mesh key={i} position={[x,.61,0]}><boxGeometry args={[1.5,.15,1.5]} /><meshStandardMaterial color="#d3c5a6" /></mesh>)}{[-4,0,4].map((x,i)=><group key={`fountain-${i}`} position={[x,.6,-1.8]}><mesh position={[0,1.1,0]}><cylinderGeometry args={[.045,.09,2.2,8]} /><meshPhysicalMaterial color="#bde8ee" transparent opacity={.72} transmission={.2} /></mesh><mesh position={[0,2.25,0]}><sphereGeometry args={[.16,8,8]} /><meshPhysicalMaterial color="#d9f7f8" transparent opacity={.62} /></mesh></group>)}<mesh position={[0,3.2,-6]} rotation={[0,0,.16]} castShadow><boxGeometry args={[.8,6,1.3]} /><meshStandardMaterial color="#b45739" roughness={.7} /></mesh></>}
    {plaza.kind==='garden'&&<><mesh position={[0,.42,0]}><boxGeometry args={[19,.25,17]} /><meshStandardMaterial color="#687a55" roughness={1} /></mesh><mesh position={[0,.58,0]} rotation={[0,.35,0]}><boxGeometry args={[22,.12,2.2]} /><meshStandardMaterial color="#d0bf9d" roughness={1} /></mesh><mesh position={[0,.58,0]} rotation={[0,-.75,0]}><boxGeometry args={[16,.12,1.5]} /><meshStandardMaterial color="#d0bf9d" roughness={1} /></mesh></>}
    {plaza.kind==='forum'&&<><mesh position={[0,.36,0]}><boxGeometry args={[22,.34,18]} /><meshStandardMaterial color="#b4a78f" roughness={1} /></mesh><mesh position={[0,.62,0]}><boxGeometry args={[17,.34,13]} /><meshStandardMaterial color="#9b8f79" roughness={1} /></mesh><mesh position={[0,.88,0]}><boxGeometry args={[11,.34,8]} /><meshStandardMaterial color="#b4a78f" roughness={1} /></mesh><mesh position={[0,1.45,-1.4]}><boxGeometry args={[5.8,1.8,3.2]} /><meshStandardMaterial color="#a56147" roughness={.8} /></mesh></>}
    {trees}{Array.from({length:10},(_,i)=><Human key={i} x={(i%5-2)*2.6} z={(Math.floor(i/5)-.5)*5.2} color={['#a84c3e','#d7c058','#41556d','#6f835c'][i%4]} />)}
  </group>
}

type BoxInstance={position:[number,number,number];scale:[number,number,number];rotation?:number}

function InstancedBoxes({items,color,roughness=1,metalness=0,emissive='#000000',emissiveIntensity=0,opacity=1,receiveShadow=false}:{items:BoxInstance[];color:string;roughness?:number;metalness?:number;emissive?:string;emissiveIntensity?:number;opacity?:number;receiveShadow?:boolean}){
  const ref=useRef<THREE.InstancedMesh>(null)
  useLayoutEffect(()=>{
    if(!ref.current||!items.length)return
    const dummy=new THREE.Object3D()
    items.forEach((item,index)=>{
      dummy.position.set(...item.position);dummy.scale.set(...item.scale);dummy.rotation.set(0,item.rotation??0,0);dummy.updateMatrix()
      ref.current!.setMatrixAt(index,dummy.matrix)
    })
    ref.current.instanceMatrix.needsUpdate=true
    ref.current.computeBoundingSphere()
  },[items])
  if(!items.length)return null
  return <instancedMesh ref={ref} args={[undefined,undefined,items.length]} castShadow={false} receiveShadow={receiveShadow}>
    <boxGeometry args={[1,1,1]}/>
    <meshStandardMaterial color={color} roughness={roughness} metalness={metalness} emissive={emissive} emissiveIntensity={emissiveIntensity} transparent={opacity<1} opacity={opacity}/>
  </instancedMesh>
}

function StreetLamp({ x, z, night=false, mood='default', quality='balanced', realLight=false }: { x: number; z: number; night?:boolean; mood?:DistrictMood; quality?:RenderQuality;realLight?:boolean }) {
  const scene=moodScene(mood)
  const lampLight=RENDER_PROFILES[quality].accentLights
  return <group position={[x,LOT_SURFACE_Y,z]}><mesh position={[0,3.1,0]} castShadow><cylinderGeometry args={[.08,.13,6.2,8]} /><meshStandardMaterial color={mood==='totalitarian'?'#1b1d1d':'#2d302d'} metalness={.65} roughness={.45} /></mesh><mesh position={[0,6.2,0]}><boxGeometry args={[.7,.14,.34]} /><meshStandardMaterial color={night?scene.lamp:'#1d201e'} emissive={night?scene.lamp:'#000'} emissiveIntensity={night?1.55:0} /></mesh>{night&&lampLight&&realLight&&<pointLight position={[0,6,0]} intensity={scene.lampIntensity*(quality==='balanced'?.46:1)} distance={quality==='balanced'?18:26} decay={1.8} color={scene.lamp} />}</group>
}

function CivicBench({x,z,rotate=false}:{x:number;z:number;rotate?:boolean}){
  return <group position={[x,.55,z]} rotation={[0,rotate?Math.PI/2:0,0]}><mesh castShadow><boxGeometry args={[3.2,.22,.65]} /><meshStandardMaterial color="#a46645" roughness={.8} /></mesh>{[-1.25,1.25].map(v=><mesh key={v} position={[v,-.35,0]}><boxGeometry args={[.14,.7,.5]} /><meshStandardMaterial color="#3c433f" metalness={.4} roughness={.55} /></mesh>)}</group>
}

function CivicPlanter({x,z,rotate=false}:{x:number;z:number;rotate?:boolean}){
  return <group position={[x,.42,z]} rotation={[0,rotate?Math.PI/2:0,0]}><mesh castShadow><boxGeometry args={[4.8,.8,1.5]} /><meshStandardMaterial color="#98735f" roughness={1} /></mesh><mesh position={[0,.48,0]}><boxGeometry args={[4.35,.22,1.15]} /><meshStandardMaterial color="#59704f" roughness={1} /></mesh></group>
}

function MoodStreetLanguage({mood,night,extent,quality}:{mood:DistrictMood;night:boolean;extent:number;quality:RenderQuality}){
  const scene=moodScene(mood)
  const profile=RENDER_PROFILES[quality]
  if(mood==='default')return null

  if(mood==='cyberpunk')return <group>
    {Array.from({length:quality==='low'?12:quality==='balanced'?20:28},(_,i)=>{
      const x=-152+((i*43)%304),z=-144+((i*67)%288),horizontal=i%2===0
      const c=i%5===0?scene.accent:i%3===0?'#ff386c':scene.window
      return <group key={`service-cut-${i}`} position={[x,.105,z]} rotation={[0,horizontal?0:Math.PI/2,0]}>
        <mesh><boxGeometry args={[18+(i%4)*5,.07,1.65]}/><meshStandardMaterial color="#10191c" roughness={.62} metalness={.32}/></mesh>
        <mesh position={[-7,.04,0]}><boxGeometry args={[2.4,.05,.28]}/><meshStandardMaterial color={c} emissive={c} emissiveIntensity={night?1.45:.12}/></mesh>
        <mesh position={[7,.04,0]}><boxGeometry args={[1.2,.05,.24]}/><meshStandardMaterial color="#f4fff8" emissive="#f4fff8" emissiveIntensity={night?.78:.08}/></mesh>
      </group>
    })}
    {Array.from({length:quality==='low'?10:quality==='balanced'?16:22},(_,i)=>{
      const x=-150+((i*71)%300),z=-150+((i*47)%300),horizontal=i%2===0
      const color=i%4===0?'#ff386c':i%4===1?scene.window:i%4===2?scene.accent:'#f4fff8'
      return <group key={`traffic-trace-${i}`} position={[x,.18,z]} rotation={[0,horizontal?0:Math.PI/2,0]}>
        <mesh><boxGeometry args={[5.6+(i%3)*2.2,.09,.22]}/><meshBasicMaterial color={color} transparent opacity={night?.78:.18} toneMapped={false}/></mesh>
        <mesh position={[0,.015,0]}><boxGeometry args={[8+(i%2)*4,.035,.82]}/><meshBasicMaterial color={color} transparent opacity={night?.18:.05} toneMapped={false}/></mesh>
      </group>
    })}
    {Array.from({length:quality==='low'?8:quality==='balanced'?12:18},(_,i)=>{
      const x=-146+((i*59)%292),z=-136+((i*31)%272)
      return <mesh key={`wet-road-${i}`} position={[x,.075,z]} rotation={[-Math.PI/2,0,(i%7)*.23]}>
        <planeGeometry args={[10+(i%4)*4,3+(i%3)*1.4]}/>
        <meshPhysicalMaterial color="#071012" emissive={i%3===0?scene.window:i%3===1?scene.accent:'#ff386c'} emissiveIntensity={night?.08:.015} roughness={.08} metalness={.08} transmission={.05} transparent opacity={.66}/>
      </mesh>
    })}
    {[-120,-40,40,120].map((x,i)=><group key={`utility-mast-${i}`} position={[x,.45,i%2?-118:118]}>
      <mesh position={[0,4.2,0]}><boxGeometry args={[.42,8.4,.42]}/><meshStandardMaterial color="#17252a" roughness={.55} metalness={.5}/></mesh>
      <mesh position={[0,8.65,0]}><boxGeometry args={[2.2,.36,1.1]}/><meshStandardMaterial color="#0a1115" emissive={i%2?scene.accent:scene.window} emissiveIntensity={night?.85:.08}/></mesh>
      <SignPanel text={`mast-${i}`} variant="glyph" width={2.8} height={1.1} bg="#02070d" fg={i%2?scene.accent:scene.window} accent="#ff386c" position={[0,9.45,.62]} opacity={night?1:.72}/>
    </group>)}
    {[-120,-40,40].map((x,i)=><BeamBetween key={`overhead-cable-${i}`} from={[x,7.8,i%2?-118:118]} to={[x+80,8.7,i%2?118:-118]} width={.045} color="#17272c"/>)}
    {Array.from({length:10},(_,i)=><group key={`steam-${i}`} position={[-136+((i*41)%272),.3,-126+((i*73)%252)]}>
      <mesh position={[0,.18,0]}><boxGeometry args={[2.2,.24,1.2]}/><meshStandardMaterial color="#172023" metalness={.35} roughness={.45}/></mesh>
      <GlowBeam from={[0,.35,0]} to={[0,8+(i%4)*2,0]} radius={1.6+(i%3)*.45} color="#b8c7bd" opacity={night?.06:.025}/>
    </group>)}
  </group>

  if(mood==='totalitarian')return <group>
    {[-132,-66,66,132].map((z,i)=><group key={`checkpoint-${z}`} position={[0,.55,z]}>
      <mesh position={[-15,4,0]}><boxGeometry args={[1.5,8,1.5]}/><meshStandardMaterial color="#11161a" roughness={.62} metalness={.28}/></mesh>
      <mesh position={[15,4,0]}><boxGeometry args={[1.5,8,1.5]}/><meshStandardMaterial color="#11161a" roughness={.62} metalness={.28}/></mesh>
      <mesh position={[0,8,0]}><boxGeometry args={[33,1.1,1.2]}/><meshStandardMaterial color="#7b1015" emissive="#390307" emissiveIntensity={night?.65:.08}/></mesh>
      <SignPanel text={i%2?'ORDER':'WATCH'} width={10} height={2.1} bg="#0d1115" fg="#a8bfd0" accent={scene.accent} position={[0,10.1,0]}/>
    </group>)}
    {[-144,-96,-48,48,96,144].flatMap((z,zi)=>[-5,5].map((x,xi)=><mesh key={`bollard-${zi}-${xi}`} position={[x,.85,z]}>
      <cylinderGeometry args={[.42,.5,1.7,8]}/>
      <meshStandardMaterial color={xi?'#7b1015':'#1a1f24'} emissive={xi&&night?'#7b1015':'#000'} emissiveIntensity={xi&&night?.35:0}/>
    </mesh>))}
    {[-18,18].flatMap((x,i)=>[
      <mesh key={`flood-strip-z-${i}`} position={[x,.13,0]}><boxGeometry args={[.34,.06,extent*.86]}/><meshBasicMaterial color={scene.lamp} transparent opacity={night?.42:.08}/></mesh>,
      <mesh key={`flood-strip-x-${i}`} position={[0,.14,x]}><boxGeometry args={[extent*.86,.06,.34]}/><meshBasicMaterial color={scene.lamp} transparent opacity={night?.32:.07}/></mesh>,
    ])}
  </group>

  if(mood==='green')return <group>
    {[-18,18].flatMap((x,i)=>[
      <mesh key={`bike-z-${i}`} position={[x,.11,0]}><boxGeometry args={[2.2,.08,extent*.82]}/><meshStandardMaterial color="#477d52" emissive="#7fe083" emissiveIntensity={night?.26:.02} roughness={1}/></mesh>,
      <mesh key={`bike-x-${i}`} position={[0,.12,x]}><boxGeometry args={[extent*.82,.08,2.2]}/><meshStandardMaterial color="#477d52" emissive="#7fe083" emissiveIntensity={night?.26:.02} roughness={1}/></mesh>,
    ])}
  </group>

  return <group>
    {[-112,-56,56,112].map((z,i)=><mesh key={`campus-crossing-${i}`} position={[0,.12,z]}>
      <boxGeometry args={[36,.08,2.4]}/>
      <meshStandardMaterial color={i%2?'#d2bc80':'#63724f'} emissive={i%2?scene.windowAlt:'#000'} emissiveIntensity={night?.16:0} roughness={.9}/>
    </mesh>)}
  </group>
}

function StreetNetwork({ night, mood, quality }: { night: boolean; mood:DistrictMood; quality:RenderQuality }) {
  const scene=moodScene(mood)
  const boundaries = useMemo(()=>Array.from({length:GRID-1},(_,i)=>(i-(GRID-2)/2)*CELL),[])
  const extent = GRID*CELL
  const landNorth=extent/2+130
  const landDepth=landNorth-SHORE_Z
  const landCenter=(landNorth+SHORE_Z)/2
  const wetCyber=mood==='cyberpunk'&&night
  const kit=useMemo(()=>{
    const road:BoxInstance[]=[],curb:BoxInstance[]=[],gutter:BoxInstance[]=[],markings:BoxInstance[]=[],crossings:BoxInstance[]=[],drains:BoxInstance[]=[],horizonRoads:BoxInstance[]=[],horizonLights:BoxInstance[]=[]
    const blockCenters=Array.from({length:GRID},(_,i)=>(i-(GRID-1)/2)*CELL)
    for(const v of boundaries){
      road.push({position:[v,-.018,0],scale:[4.8,.12,extent]},{position:[0,-.018,v],scale:[extent,.12,4.8]})
      for(const side of [-1,1])for(const center of blockCenters){
        curb.push({position:[v+side*2.48,.13,center],scale:[.2,.2,CELL-4.8]},{position:[center,.13,v+side*2.48],scale:[CELL-4.8,.2,.2]})
        gutter.push({position:[v+side*2.22,.052,center],scale:[.22,.025,CELL-4.8]},{position:[center,.052,v+side*2.22],scale:[CELL-4.8,.025,.22]})
      }
    }
    const collectors=boundaries.filter(v=>[16,80,144].includes(Math.abs(v)))
    const dashStep=quality==='low'?24:quality==='balanced'?18:15
    const dashCount=Math.ceil(extent/dashStep)
    for(const v of collectors)for(let i=0;i<dashCount;i++){
      const d=-extent/2+dashStep/2+i*dashStep
      markings.push({position:[v,.057,d],scale:[.1,.024,4.2]},{position:[d,.057,v],scale:[4.2,.024,.1]})
    }
    for(const cx of [-CELL/2,CELL/2])for(const cz of [-CELL/2,CELL/2]){
      for(let i=-2;i<=2;i++){
        crossings.push({position:[cx,.055,cz+4.4+i*.62],scale:[4.1,.022,.3]})
        crossings.push({position:[cx+4.4+i*.62,.055,cz],scale:[.3,.022,4.1]})
      }
      drains.push(
        {position:[cx-2.16,.055,cz+6.35],scale:[.32,.026,1.12]},
        {position:[cx+2.16,.055,cz-6.35],scale:[.32,.026,1.12]},
        {position:[cx+6.35,.055,cz+2.16],scale:[1.12,.026,.32]},
        {position:[cx-6.35,.055,cz-2.16],scale:[1.12,.026,.32]},
      )
    }
    for(const v of collectors){
      horizonRoads.push(
        {position:[v,.007,extent/2+72],scale:[4.8,.07,144]},
        {position:[extent/2+72,.007,v],scale:[144,.07,4.8]},
        {position:[-extent/2-72,.007,v],scale:[144,.07,4.8]},
      )
    }
    if(quality!=='low')for(const side of [-1,1])for(let i=0;i<10;i++){
      const away=extent/2+18+i*12
      horizonLights.push({position:[side*16,.12,away],scale:[.16,.08,.7]},{position:[away,.12,side*16],scale:[.7,.08,.16]},{position:[-away,.12,side*16],scale:[.7,.08,.16]})
    }
    return {road,curb,gutter,markings,crossings,drains,horizonRoads,horizonLights}
  },[boundaries,extent,quality])
  const curbColor=mood==='cyberpunk'?'#344148':mood==='green'?'#87917a':mood==='totalitarian'?'#a1a6a4':mood==='university'?'#b9a77f':night?'#54554f':'#b3aa97'
  const markingColor=mood==='totalitarian'?'#c7c8c3':mood==='university'?'#d8c37f':mood==='green'?'#a8c58c':wetCyber?'#788582':'#d0c39b'
  return <group>
    <mesh rotation={[-Math.PI/2,0,0]} position={[0,-.12,landCenter]} receiveShadow><planeGeometry args={[extent+260,landDepth]} /><meshStandardMaterial color={night ? scene.groundNight : scene.groundDay} roughness={.98} /></mesh>
    <InstancedBoxes items={kit.road} color={night?scene.roadNight:scene.roadDay} roughness={wetCyber?.55:.92} metalness={wetCyber?.08:0} receiveShadow/>
    <InstancedBoxes items={kit.horizonRoads} color={night?scene.roadNight:scene.roadDay} roughness={.96}/>
    <InstancedBoxes items={kit.curb} color={curbColor} roughness={.96}/>
    <InstancedBoxes items={kit.gutter} color={mood==='cyberpunk'?'#111b20':'#555953'} roughness={.75} metalness={.12}/>
    <InstancedBoxes items={kit.markings} color={markingColor} roughness={.82} emissive={wetCyber?'#182222':'#000000'} emissiveIntensity={wetCyber?.12:0}/>
    <InstancedBoxes items={kit.crossings} color={markingColor} roughness={.86}/>
    <InstancedBoxes items={kit.drains} color="#252a29" roughness={.55} metalness={.44}/>
    <InstancedBoxes items={kit.horizonLights} color={night?scene.lamp:'#6f746c'} emissive={night?scene.lamp:'#000000'} emissiveIntensity={night?.72:0} roughness={.5}/>
    <MoodStreetLanguage mood={mood} night={night} extent={extent} quality={quality}/>
    {boundaries.filter((_,i)=>i%2===0).flatMap((v,i)=>[
      <StreetLamp key={`la-${i}`} x={v-2} z={-extent/2+3} night={night} mood={mood} quality={quality} realLight={quality==='high'&&(i===1||i===3)}/>,
      <StreetLamp key={`lb-${i}`} x={v+2} z={extent/2-3} night={night} mood={mood} quality={quality} realLight={quality==='high'&&(i===1||i===3)}/>,
    ])}
    {Array.from({length:quality==='low'?4:8},(_,i)=><StreetLamp key={`civic-light-${i}`} x={i%2?-19:19} z={-96+Math.floor(i/2)*64} night={night} mood={mood} quality={quality} realLight={i%2===0}/>)}
    {[-16,16].flatMap((x,xi)=>Array.from({length:quality==='low'?5:10},(_,i)=><Tree key={`median-${xi}-${i}`} x={x+(xi?2.4:-2.4)} z={-144+i*(quality==='low'?64:32)} scale={.48+(i%3)*.06}/>))}
    {Array.from({length:8},(_,i)=><CivicBench key={`bench-${i}`} x={i%2?-12.5:12.5} z={-112+Math.floor(i/2)*64} rotate={i%2===0}/>)}
    {Array.from({length:8},(_,i)=><CivicPlanter key={`planter-${i}`} x={-112+Math.floor(i/2)*64} z={i%2?-12.5:12.5} rotate />)}
  </group>
}

function BackgroundCity({quality,mood,night}:{quality:RenderQuality;mood:DistrictMood;night:boolean}) {
  const scene=moodScene(mood)
  const palette={
    default:{a:'#817c72',b:'#6e716d',far:'#596565',roof:'#48504e',ridge:'#68705f',green:'#596b4e'},
    cyberpunk:{a:'#18232a',b:'#263139',far:'#0d171e',roof:'#111b21',ridge:'#1a252b',green:'#243f38'},
    green:{a:'#788277',b:'#67766d',far:'#53665c',roof:'#53615a',ridge:'#526b57',green:'#587b55'},
    totalitarian:{a:'#70777a',b:'#555d62',far:'#3b474e',roof:'#343d42',ridge:'#49555a',green:'#46564d'},
    university:{a:'#8a8170',b:'#716f69',far:'#59646a',roof:'#525957',ridge:'#64705d',green:'#597151'},
  }[mood]
  const skyline=useMemo(()=>{
    const massesA:BoxInstance[]=[],massesB:BoxInstance[]=[],upper:BoxInstance[]=[],roofs:BoxInstance[]=[]
    const windowsDark:BoxInstance[]=[],windowsA:BoxInstance[]=[],windowsB:BoxInstance[]=[],greenRoofs:BoxInstance[]=[],serviceAccents:BoxInstance[]=[],farMasses:BoxInstance[]=[],monuments:BoxInstance[]=[]
    const seeded=(seed:number)=>{const value=Math.sin(seed*12.9898+hashText(mood)*.017)*43758.5453;return value-Math.floor(value)}
    const maxLod=quality==='low'?0:1
    const limit=quality==='low'?24:quality==='balanced'?48:72
    const zones=[
      {kind:'north' as const,fixed:218,start:-190,end:190,lod:0},
      {kind:'west' as const,fixed:-218,start:-150,end:195,lod:0},
      {kind:'east' as const,fixed:218,start:-150,end:195,lod:0},
      {kind:'north' as const,fixed:272,start:-224,end:224,lod:1},
      {kind:'west' as const,fixed:-274,start:-165,end:215,lod:1},
      {kind:'east' as const,fixed:274,start:-165,end:215,lod:1},
    ]
    let placed=0
    zones.forEach((zone,zoneIndex)=>{
      if(zone.lod>maxLod||placed>=limit)return
      let cursor=zone.start,index=0
      while(cursor<zone.end&&placed<limit){
        const seed=zoneIndex*101+index*17+11
        let frontage=14+seeded(seed)*23
        let gap=6+seeded(seed+3)*11
        if(mood==='green'){frontage*=.92;gap*=1.35}
        if(mood==='totalitarian'){frontage*=1.22;gap*=.82}
        cursor+=frontage/2
        if(cursor+frontage/2>zone.end)break
        const deep=14+seeded(seed+7)*13
        const along=cursor+(seeded(seed+9)-.5)*3.5
        const offset=zone.fixed+(zone.lod?seeded(seed+13)*22:seeded(seed+13)*12)
        const x=zone.kind==='north'?along:offset
        const z=zone.kind==='north'?offset:along
        const w=zone.kind==='north'?frontage:deep
        const d=zone.kind==='north'?deep:frontage
        let h=(zone.lod?30:18)+seeded(seed+19)*(zone.lod?74:48)
        if(mood==='green')h*=.78
        if(mood==='university')h=Math.min(h*.82,72)
        if(mood==='cyberpunk')h*=.92+seeded(seed+23)*.42
        if(mood==='totalitarian')h=[36,54,72,96][Math.min(3,Math.floor(seeded(seed+21)*4))]
        const grammar=Math.floor(seeded(seed+29)*3)
        const primary=placed%3?massesA:massesB
        if(grammar===0)primary.push({position:[x,h/2,z],scale:[w,h,d]})
        else if(grammar===1){
          const lower=h*.62
          primary.push({position:[x,lower/2,z],scale:[w,lower,d]})
          upper.push({position:[x,lower+(h-lower)/2,z],scale:[w*(.68+seeded(seed+31)*.16),h-lower,d*(.68+seeded(seed+33)*.16)]})
        }else{
          const podium=Math.max(6,h*.2)
          massesB.push({position:[x,podium/2,z],scale:[w,podium,d]})
          upper.push({position:[x,podium+(h-podium)/2,z],scale:[w*(.48+seeded(seed+35)*.24),h-podium,d*(.5+seeded(seed+37)*.22)]})
        }
        roofs.push({position:[x,h+.65,z],scale:[Math.max(3,w*.24),1.3,Math.max(3,d*.24)]})
        const bands=quality==='low'?1:quality==='balanced'?2:3
        for(let band=0;band<bands;band++){
          const y=3+(band+1)/(bands+1)*Math.min(h*.62,39)
          const face:BoxInstance=zone.kind==='north'
            ?{position:[x,y,z-d/2-.08],scale:[w*.67,.7,.16]}
            :zone.kind==='west'
              ?{position:[x+w/2+.08,y,z],scale:[.16,.7,d*.67]}
              :{position:[x-w/2-.08,y,z],scale:[.16,.7,d*.67]}
          const lightSeed=seeded(seed+band*43)
          if(lightSeed>.72)(lightSeed>.92?windowsB:windowsA).push(face)
          else windowsDark.push(face)
        }
        if(mood==='green'||(mood==='university'&&placed%4===0))greenRoofs.push({position:[x,h+1.37,z],scale:[Math.max(2,w*.2),.16,Math.max(2,d*.2)]})
        if((mood==='cyberpunk'&&placed%3===0)||(mood==='totalitarian'&&placed%6===0))serviceAccents.push({position:[x,h+2.4,z],scale:[.32,3.4,.32]})
        cursor+=frontage/2+gap;index++;placed++
      }
    })
    const farCount=quality==='low'?14:quality==='balanced'?22:30
    for(let i=0;i<farCount;i++){
      const angle=i/farCount*Math.PI*2+.08
      const radius=390+seeded(600+i)*74
      const h=18+seeded(800+i)*70
      farMasses.push({position:[Math.sin(angle)*radius,h/2-2,Math.cos(angle)*radius],scale:[16+seeded(900+i)*28,h,15+seeded(1000+i)*20],rotation:-angle})
    }
    if(quality!=='low'){
      if(mood==='totalitarian')monuments.push(
        {position:[0,55,304],scale:[72,110,24]},
        {position:[-48,43,298],scale:[16,86,18]},
        {position:[48,43,298],scale:[16,86,18]},
      )
      else if(mood==='cyberpunk')monuments.push(
        {position:[-76,58,298],scale:[18,116,19]},
        {position:[82,46,306],scale:[24,92,22]},
        {position:[-304,37,92],scale:[20,74,20]},
      )
      else if(mood==='green')monuments.push(
        {position:[-82,30,298],scale:[56,60,30]},
        {position:[76,38,304],scale:[42,76,26]},
      )
      else if(mood==='university')monuments.push(
        {position:[-70,35,295],scale:[48,70,26]},
        {position:[68,29,300],scale:[62,58,28]},
      )
      else monuments.push(
        {position:[-70,43,298],scale:[54,86,24]},
        {position:[74,32,304],scale:[38,64,28]},
      )
    }
    return {massesA,massesB,upper,roofs,windowsDark,windowsA,windowsB,greenRoofs,serviceAccents,farMasses,monuments}
  },[quality,mood])
  const ridgeGeometry=useMemo(()=>{
    const segments=quality==='low'?48:quality==='balanced'?72:96
    const positions:number[]=[],indices:number[]=[]
    const heightScale=mood==='green'?1.5:mood==='totalitarian'?.62:1
    for(let i=0;i<=segments;i++){
      const angle=i/segments*Math.PI*2,radius=520+Math.sin(i*2.17)*18+Math.sin(i*.63)*24
      const top=(18+Math.sin(i*.77)*9+Math.sin(i*1.91)*5)*heightScale
      positions.push(Math.sin(angle)*radius,-34,Math.cos(angle)*radius,Math.sin(angle)*radius,top,Math.cos(angle)*radius)
      if(i<segments){const a=i*2;indices.push(a,a+1,a+3,a,a+3,a+2)}
    }
    const geometry=new THREE.BufferGeometry()
    geometry.setAttribute('position',new THREE.Float32BufferAttribute(positions,3));geometry.setIndex(indices);geometry.computeVertexNormals()
    return geometry
  },[quality,mood])
  useEffect(()=>()=>ridgeGeometry.dispose(),[ridgeGeometry])
  return <group>
    <mesh geometry={ridgeGeometry} castShadow={false} receiveShadow={false}><meshStandardMaterial color={palette.ridge} roughness={1}/></mesh>
    <InstancedBoxes items={skyline.farMasses} color={palette.far} roughness={1}/>
    <InstancedBoxes items={skyline.massesA} color={palette.a} roughness={1}/>
    <InstancedBoxes items={skyline.massesB} color={palette.b} roughness={1}/>
    <InstancedBoxes items={skyline.upper} color={palette.b} roughness={.98}/>
    <InstancedBoxes items={skyline.monuments} color={mood==='totalitarian'?'#4a5358':palette.a} roughness={.96}/>
    <InstancedBoxes items={skyline.roofs} color={palette.roof} roughness={.9} metalness={.08}/>
    <InstancedBoxes items={skyline.windowsDark} color="#222b2e" roughness={.58}/>
    <InstancedBoxes items={skyline.windowsA} color={night?scene.window:'#293238'} roughness={.5} emissive={night?scene.window:'#000000'} emissiveIntensity={night?.64:0}/>
    <InstancedBoxes items={skyline.windowsB} color={night?scene.windowAlt:'#31383a'} roughness={.5} emissive={night?scene.windowAlt:'#000000'} emissiveIntensity={night?.52:0}/>
    <InstancedBoxes items={skyline.greenRoofs} color={palette.green} roughness={1} emissive={night&&mood==='green'?'#24472e':'#000000'} emissiveIntensity={night&&mood==='green'?.12:0}/>
    <InstancedBoxes items={skyline.serviceAccents} color={palette.roof} roughness={.62} metalness={.28} emissive={night?scene.accent:'#000000'} emissiveIntensity={night?.32:0}/>
    {mood==='university'&&quality==='high'&&<mesh position={[68,62,300]} castShadow={false}><sphereGeometry args={[7,18,10,0,Math.PI*2,0,Math.PI/2]}/><meshStandardMaterial color="#6d746f" roughness={.72} metalness={.16}/></mesh>}
  </group>
}

function WaterfrontEdge({mood,night,quality}:{mood:DistrictMood;night:boolean;quality:RenderQuality}){
  const scene=moodScene(mood)
  const colors={
    default:{water:'#3f5962',stone:'#8d887b',face:'#555d5b',deck:'#6b6255',green:'#55664c'},
    cyberpunk:{water:'#071821',stone:'#273237',face:'#111b21',deck:'#26343a',green:'#284238'},
    green:{water:'#345e56',stone:'#7d897b',face:'#52645d',deck:'#665f4e',green:'#4f7855'},
    totalitarian:{water:'#263741',stone:'#909795',face:'#4b5559',deck:'#697072',green:'#46574f'},
    university:{water:'#3e6077',stone:'#9b9079',face:'#5e6260',deck:'#776650',green:'#536f50'},
  }[mood]
  const kit=useMemo(()=>{
    const promenade:BoxInstance[]=[{position:[0,.11,-182],scale:[376,.22,16]}]
    const seawall:BoxInstance[]=[{position:[0,.18,-189.6],scale:[392,.22,1.8]},{position:[0,-.55,-190.2],scale:[392,1.45,1.3]}]
    const stairs:BoxInstance[]=[],piers:BoxInstance[]=[],piles:BoxInstance[]=[],markers:BoxInstance[]=[],boats:BoxInstance[]=[],ripples:BoxInstance[]=[],greenery:BoxInstance[]=[],service:BoxInstance[]=[]
    const stairXs=quality==='low'?[0]:quality==='balanced'?[-104,0,112]:[-158,-104,0,112,160]
    for(const x of stairXs)for(let step=0;step<6;step++)stairs.push({position:[x,.18-step*.07,-185.5-step*.9],scale:[11,.14,1.1]})
    const master=mood==='totalitarian'
      ?[{x:-96,length:46,width:7,lod:0},{x:0,length:58,width:8,lod:0},{x:96,length:46,width:7,lod:0}]
      :[{x:-124,length:42,width:6.2,lod:0},{x:76,length:34,width:5.2,lod:0},{x:-40,length:52,width:6.5,lod:1},{x:142,length:40,width:5.4,lod:1},{x:22,length:62,width:7,lod:2},{x:-164,length:30,width:4.8,lod:2}]
    const maxLod=quality==='low'?0:quality==='balanced'?1:2
    for(const pier of master){
      if(pier.lod>maxLod||(mood==='green'&&pier.x===142)||(mood==='university'&&pier.lod>1))continue
      piers.push({position:[pier.x,.02,SHORE_Z-pier.length/2],scale:[pier.width,.28,pier.length]})
      for(let along=6;along<pier.length;along+=9)for(const side of [-1,1]){
        piles.push({position:[pier.x+side*(pier.width/2+.32),-.48,SHORE_Z-along],scale:[.34,1.5,.34]})
        if(quality!=='low'&&along%18<9)markers.push({position:[pier.x+side*(pier.width/2+.14),.32,SHORE_Z-along],scale:[.16,.38,.16]})
      }
    }
    const markerCount=quality==='low'?12:quality==='balanced'?24:32
    for(let i=0;i<markerCount;i++)markers.push({position:[-178+i/(markerCount-1)*356,.43,-188.82],scale:[.15,.44,.15]})
    if(quality!=='low')boats.push(
      {position:[-88,-.02,-238],scale:[5.2,1.1,17],rotation:.08},
      {position:[54,-.03,-225],scale:[7,1.2,22],rotation:-.05},
      ...(quality==='high'?[{position:[138,-.04,-260] as [number,number,number],scale:[6,1,15] as [number,number,number],rotation:.18}]:[]),
    )
    const rippleCount=quality==='low'?18:quality==='balanced'?34:52
    for(let i=0;i<rippleCount;i++)ripples.push({position:[-310+((i*83)%620),-.263,-205-((i*47)%220)],scale:[4+((i*7)%13),.012,.12],rotation:(i%7-3)*.025})
    if(mood==='green')for(let i=0;i<18;i++)greenery.push({position:[-168+i*19,.39,-179+(i%3)*1.2],scale:[5.5,.32,1.8]})
    if(mood==='university')service.push({position:[-148,2.8,-181],scale:[18,5.2,10]},{position:[145,2.1,-181],scale:[13,3.8,9]})
    if(mood==='cyberpunk')for(const x of [-150,-78,18,104,158])service.push({position:[x,1.1,-181],scale:[6,1.8,5]})
    return {promenade,seawall,stairs,piers,piles,markers,boats,ripples,greenery,service}
  },[mood,quality])
  return <group>
    <mesh rotation={[-Math.PI/2,0,0]} position={[0,-.28,SHORE_Z-130]} receiveShadow={false}><planeGeometry args={[760,260]}/><meshStandardMaterial color={colors.water} roughness={mood==='cyberpunk'?.42:.34} metalness={.1} emissive={night?colors.water:'#000000'} emissiveIntensity={night?.16:0}/></mesh>
    <InstancedBoxes items={kit.ripples} color={night?scene.windowAlt:'#b8c9c7'} emissive={night?scene.windowAlt:'#000000'} emissiveIntensity={night?.16:0} opacity={night?.13:.16} roughness={.4}/>
    <InstancedBoxes items={kit.promenade} color={colors.stone} roughness={.98} receiveShadow/>
    <InstancedBoxes items={kit.seawall} color={colors.face} roughness={.9}/>
    <InstancedBoxes items={kit.stairs} color={colors.stone} roughness={.98}/>
    <InstancedBoxes items={kit.piers} color={colors.deck} roughness={.88} metalness={mood==='cyberpunk'?.22:.04}/>
    <InstancedBoxes items={kit.piles} color={mood==='cyberpunk'?'#132126':'#3e4744'} roughness={.72} metalness={.25}/>
    <InstancedBoxes items={kit.markers} color={night?scene.lamp:'#5c625e'} emissive={night?scene.lamp:'#000000'} emissiveIntensity={night?.82:0} roughness={.42}/>
    <InstancedBoxes items={kit.boats} color={mood==='totalitarian'?'#555f63':mood==='cyberpunk'?'#152329':'#807665'} roughness={.62} metalness={.12}/>
    <InstancedBoxes items={kit.greenery} color={colors.green} roughness={1}/>
    <InstancedBoxes items={kit.service} color={colors.face} roughness={.86} emissive={night&&mood==='cyberpunk'?scene.accent:'#000000'} emissiveIntensity={night&&mood==='cyberpunk'?.18:0}/>
  </group>
}

function Vehicle({ x, z, horizontal, color, moving=true, reverse=false, mood='default', night=false, quality='balanced' }: { x:number;z:number;horizontal?:boolean;color:string;moving?:boolean;reverse?:boolean;mood?:DistrictMood;night?:boolean;quality?:RenderQuality }) {
  const ref=useRef<THREE.Group>(null)
  useFrame((_,delta)=>{
    if(!moving||!ref.current)return
    const axis=horizontal?'x':'z';const limit=GRID*CELL/2+8
    ref.current.position[axis]+=(reverse?-1:1)*delta*(8+(Math.abs(x+z)%7))
    if(ref.current.position[axis]>limit)ref.current.position[axis]=-limit
    if(ref.current.position[axis]<-limit)ref.current.position[axis]=limit
  })
  const cyber=mood==='cyberpunk'&&night
  const head=reverse?'#ff386c':'#38f6ff'
  const tail=reverse?'#38f6ff':'#ff386c'
  return <group ref={ref} position={[x,.4,z]} rotation={[0,horizontal?Math.PI/2:0,0]}>
    <mesh castShadow><boxGeometry args={[1.8,.7,4.1]} /><meshStandardMaterial color={cyber?'#11181d':color} metalness={.35} roughness={.5} /></mesh>
    <mesh position={[0,.55,0]}><boxGeometry args={[1.6,.55,2.1]} /><meshStandardMaterial color={cyber?'#050b12':'#26343b'} emissive={cyber?'#0b1c22':'#000'} emissiveIntensity={cyber?.22:0} roughness={.2} metalness={.25} /></mesh>
    <mesh position={[0,-.28,1.2]} rotation={[0,0,Math.PI/2]}><cylinderGeometry args={[.3,.3,2.05,10]} /><meshStandardMaterial color="#171918" /></mesh>
    <mesh position={[0,-.28,-1.2]} rotation={[0,0,Math.PI/2]}><cylinderGeometry args={[.3,.3,2.05,10]} /><meshStandardMaterial color="#171918" /></mesh>
    {cyber&&<>
      <mesh position={[0,.25,2.12]}><boxGeometry args={[1.45,.1,.12]}/><meshBasicMaterial color={head} toneMapped={false}/></mesh>
      <mesh position={[0,.25,-2.12]}><boxGeometry args={[1.45,.1,.12]}/><meshBasicMaterial color={tail} toneMapped={false}/></mesh>
      <mesh position={[0,.18,reverse?2.9:-2.9]}><boxGeometry args={[1.1,.035,3.8]}/><meshBasicMaterial color={tail} transparent opacity={.36} toneMapped={false}/></mesh>
    </>}
  </group>
}

function PlacementPreview({x,z,tool}:{x:number;z:number;tool:Tool}){
  if(tool==='select'||tool==='demolish')return null
  if(tool==='plaza')return <group position={[x,.5,z]}>{[0,1,2].map(i=><mesh key={i} position={[(i-1)*5,1.8,(i%2)*4-2]} raycast={()=>null}><cylinderGeometry args={[1.3,.2,3.6,8]} /><meshStandardMaterial color="#d7ff43" transparent opacity={.3} depthWrite={false} /></mesh>)}<mesh raycast={()=>null}><boxGeometry args={[CELL-5,.5,CELL-5]} /><meshStandardMaterial color="#d7ff43" transparent opacity={.2} depthWrite={false} /><Edges color="#d7ff43" /></mesh></group>
  const program=tool as Building['program']
  const typology=program==='culture'?'forum':program==='civic'?'citadel':program==='work'?'bridge':program==='mixed'?'terrace':'slab'
  const p=TYPOLOGIES[typology]
  const preview:Building={id:'preview',name:'preview',x:0,z:0,program,typology,height:p.height,width:p.width,depth:p.depth,terraces:p.terraces,cantilever:p.cantilever,rotation:0,porosity:44,rhythm:5,tone:'raw',condition:100,age:0,floorHeight:p.floorHeight,baySpacing:p.baySpacing,structural:p.structural,facade:p.facade,pilotis:p.pilotis,balconies:p.balconies,cores:p.cores,podiumHeight:p.podiumHeight,language:'civic',voids:28,taper:12,facadeDepth:1,weathering:20,vegetation:30,composition:p.composition,profile:p.profile,moduleDensity:3,articulation:34,branches:1,crown:24}
  const bodies=structuralBodies(preview)
  return <group position={[x,LOT_SURFACE_Y,z]}>{p.composition==='ring'?<><mesh position={[0,8,0]} raycast={()=>null}><cylinderGeometry args={[10,10,10,32]} /><meshStandardMaterial color="#d7ff43" transparent opacity={.19} depthWrite={false} wireframe /></mesh><mesh position={[0,15,0]} raycast={()=>null}><cylinderGeometry args={[12,10,5,32]} /><meshStandardMaterial color="#d7ff43" transparent opacity={.19} depthWrite={false} wireframe /></mesh></>:bodies.map((body,i)=><mesh key={i} position={[body.x,body.y,body.z]} rotation={[0,body.ry??0,0]} raycast={()=>null}><boxGeometry args={[body.w,body.h,body.d]} /><meshStandardMaterial color="#d7ff43" transparent opacity={.19} depthWrite={false} /><Edges color="#d7ff43" lineWidth={1.2} /></mesh>)}</group>
}

const solarModel=(hour:number)=>{
  const phase=(hour-6.5)/(19.5-6.5)*Math.PI
  const elevation=Math.sin(phase)
  const direction=new THREE.Vector3(Math.cos(phase)*.82,elevation,-.52).normalize()
  return {direction,daylight:THREE.MathUtils.smoothstep(elevation,-.1,.12)}
}

const SKY_VERTEX=`
varying vec3 vDir;
void main(){vDir=normalize(position);vec4 clip=projectionMatrix*modelViewMatrix*vec4(position,1.0);gl_Position=clip.xyww;}
`

const SKY_FRAGMENT=`
precision highp float;
uniform float uTime;uniform float uDaylight;uniform float uHaze;uniform float uCloudiness;uniform float uCloudDetail;uniform float uStarIntensity;uniform float uSunStrength;
uniform vec3 uSunDir;uniform vec3 uMoonDir;uniform vec3 uDayTop;uniform vec3 uDayHorizon;uniform vec3 uDayGround;uniform vec3 uNightTop;uniform vec3 uNightHorizon;uniform vec3 uNightGround;
uniform vec3 uHazeDay;uniform vec3 uHazeNight;uniform vec3 uTwilightColor;uniform vec3 uSunColor;uniform vec3 uMoonColor;uniform vec3 uCloudDay;uniform vec3 uCloudNight;
varying vec3 vDir;const float TAU=6.28318530718;
float hash21(vec2 p){p=fract(p*vec2(123.34,456.21));p+=dot(p,p+45.32);return fract(p.x*p.y);}
float noise2(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);float a=hash21(i),b=hash21(i+vec2(1.,0.)),c=hash21(i+vec2(0.,1.)),d=hash21(i+vec2(1.,1.));return mix(mix(a,b,f.x),mix(c,d,f.x),f.y);}
void main(){
  vec3 dir=normalize(vDir);float h=clamp(dir.y,-1.,1.),day=clamp(uDaylight,0.,1.),nightAmount=1.-day;
  vec3 top=mix(uNightTop,uDayTop,day),horizon=mix(uNightHorizon,uDayHorizon,day),ground=mix(uNightGround,uDayGround,day);
  vec3 upper=mix(horizon,top,pow(max(h,0.),.58)),lower=mix(horizon,ground,clamp(-h*3.,0.,1.));vec3 color=mix(lower,upper,step(0.,h));
  float horizonBand=1.-smoothstep(.02,.36,abs(h));vec2 viewAzimuth=normalize(dir.xz+vec2(.00001,0.)),sunAzimuth=normalize(uSunDir.xz+vec2(.00001,0.));float sunFacing=smoothstep(-.25,.95,dot(viewAzimuth,sunAzimuth));
  vec3 hazeColor=mix(uHazeNight,uHazeDay,day);color=mix(color,hazeColor,clamp(uHaze*horizonBand*(.58+.42*sunFacing),0.,.84));
  float twilight=smoothstep(-.28,-.04,uSunDir.y)*(1.-smoothstep(.02,.22,uSunDir.y))*horizonBand;color=mix(color,uTwilightColor,twilight*(.12+.38*sunFacing));
  float cloudFade=smoothstep(.06,.22,h);vec2 cloudUv=dir.xz/max(.14,h)*.42+vec2(uTime*.0014,uTime*.00035);float cloudNoise=noise2(cloudUv*1.35);if(uCloudDetail>.5)cloudNoise=cloudNoise*.68+noise2(cloudUv*2.75+7.1)*.32;cloudNoise=cloudNoise*.8+(.5+.5*sin(cloudUv.x*1.7+cloudUv.y*.34))*.2;
  float cloudThreshold=mix(.76,.49,uCloudiness),cloud=smoothstep(cloudThreshold,cloudThreshold+.13,cloudNoise)*cloudFade;vec3 cloudColor=mix(uCloudNight,uCloudDay,day);color=mix(color,cloudColor,cloud*(.07+.2*uCloudiness)*mix(.72,1.,day));
  float longitude=atan(dir.z,dir.x)/TAU+.5;vec2 starP=vec2(longitude,h*.5+.5)*vec2(320.,140.),starCell=floor(starP),starLocal=fract(starP)-.5;float starSeed=hash21(starCell+19.19);vec2 starJitter=vec2(hash21(starCell+3.1),hash21(starCell+7.7))-.5;
  float starDistance=length(starLocal-starJitter*.55),starRadius=mix(.025,.07,hash21(starCell+29.7)),starAA=max(.012,fwidth(starDistance)*1.25);float star=(1.-smoothstep(starRadius,starRadius+starAA,starDistance))*step(.993,starSeed);
  float starBrightness=mix(.45,1.55,clamp((starSeed-.993)/.007,0.,1.));vec3 starColor=mix(vec3(.70,.82,1.),vec3(1.,.84,.66),hash21(starCell+41.3));star*=nightAmount*nightAmount*smoothstep(.02,.16,h)*uStarIntensity*(1.-cloud*.82);color+=starColor*star*starBrightness;
  float sunDot=dot(dir,normalize(uSunDir)),sunVisible=smoothstep(-.08,.03,uSunDir.y)*day,sunHalo=smoothstep(.985,.99965,sunDot),sunDisc=smoothstep(.99970,.99991,sunDot);color+=uSunColor*(sunHalo*.11+sunDisc*uSunStrength)*sunVisible*(1.-cloud*.48);
  float moonDot=dot(dir,normalize(uMoonDir)),moonVisible=smoothstep(-.05,.12,uMoonDir.y)*nightAmount,moonHalo=smoothstep(.992,.99965,moonDot),moonDisc=smoothstep(.99962,.99988,moonDot);color+=uMoonColor*(moonHalo*.045+moonDisc*.68)*moonVisible*(1.-cloud*.55);
  color+=(hash21(gl_FragCoord.xy)-.5)/255.;gl_FragColor=vec4(max(color,vec3(0.)),1.);
  #include <tonemapping_fragment>
  #include <colorspace_fragment>
}
`

function Atmosphere({hour,daylight,mood,quality}:{hour:number;daylight:number;mood:DistrictMood;quality:RenderQuality}) {
  const sphere=useRef<THREE.Mesh>(null)
  const uniforms=useMemo(()=>({
    uTime:{value:0},uDaylight:{value:1},uSunDir:{value:new THREE.Vector3()},uMoonDir:{value:new THREE.Vector3()},
    uDayTop:{value:new THREE.Color()},uDayHorizon:{value:new THREE.Color()},uDayGround:{value:new THREE.Color()},uNightTop:{value:new THREE.Color()},uNightHorizon:{value:new THREE.Color()},uNightGround:{value:new THREE.Color()},
    uHazeDay:{value:new THREE.Color()},uHazeNight:{value:new THREE.Color()},uTwilightColor:{value:new THREE.Color()},uSunColor:{value:new THREE.Color()},uMoonColor:{value:new THREE.Color()},uCloudDay:{value:new THREE.Color()},uCloudNight:{value:new THREE.Color()},
    uHaze:{value:.55},uCloudiness:{value:.55},uCloudDetail:{value:1},uStarIntensity:{value:.5},uSunStrength:{value:.8},
  }),[])
  useEffect(()=>{
    const scene=moodScene(mood),solar=solarModel(hour),moon=solar.direction.clone().negate();moon.y+=.08;moon.normalize()
    const character={
      default:{haze:.45,clouds:.6,stars:.5,sun:.82,twilight:'#d89567',cloudDay:'#d6d3c8',cloudNight:'#1a2530'},
      cyberpunk:{haze:.7,clouds:.48,stars:.16,sun:.52,twilight:'#b56d3f',cloudDay:'#657079',cloudNight:'#08131d'},
      green:{haze:.6,clouds:.7,stars:.32,sun:.72,twilight:'#e0b978',cloudDay:'#d1d8c8',cloudNight:'#172b22'},
      totalitarian:{haze:.82,clouds:.88,stars:.05,sun:.4,twilight:'#9d9184',cloudDay:'#adb2b3',cloudNight:'#151d23'},
      university:{haze:.34,clouds:.36,stars:.72,sun:.9,twilight:'#e2a66b',cloudDay:'#e2d6be',cloudNight:'#20283c'},
    }[mood]
    uniforms.uDaylight.value=daylight;uniforms.uSunDir.value.copy(solar.direction);uniforms.uMoonDir.value.copy(moon)
    uniforms.uDayTop.value.set(scene.day[0]);uniforms.uDayHorizon.value.set(scene.day[1]);uniforms.uDayGround.value.set(scene.day[2]);uniforms.uNightTop.value.set(scene.night[0]);uniforms.uNightHorizon.value.set(scene.night[1]);uniforms.uNightGround.value.set(scene.night[2])
    uniforms.uHazeDay.value.set(scene.fogDay);uniforms.uHazeNight.value.set(scene.fogNight);uniforms.uTwilightColor.value.set(character.twilight);uniforms.uSunColor.value.set(mood==='totalitarian'?'#d7dedf':mood==='cyberpunk'?'#ffbd72':'#ffe1aa');uniforms.uMoonColor.value.set(mood==='cyberpunk'?'#8ed9d4':'#b9c9dd')
    uniforms.uCloudDay.value.set(character.cloudDay);uniforms.uCloudNight.value.set(character.cloudNight);uniforms.uHaze.value=character.haze;uniforms.uCloudiness.value=character.clouds;uniforms.uCloudDetail.value=quality==='low'?0:1;uniforms.uStarIntensity.value=quality==='low'?0:character.stars;uniforms.uSunStrength.value=character.sun
  },[daylight,hour,mood,quality,uniforms])
  useFrame(({camera,clock})=>{if(sphere.current)sphere.current.position.copy(camera.position);uniforms.uTime.value=clock.getElapsedTime()})
  return <mesh ref={sphere} scale={760} frustumCulled={false} renderOrder={-1000} raycast={()=>null}>
    <sphereGeometry args={[1,quality==='low'?24:32,quality==='low'?14:20]}/>
    <shaderMaterial side={THREE.BackSide} depthWrite={false} depthTest={false} uniforms={uniforms} toneMapped vertexShader={SKY_VERTEX} fragmentShader={SKY_FRAGMENT}/>
  </mesh>
}

function SweepingSearchlight({x,z,phase,night,color,quality}:{x:number;z:number;phase:number;night:boolean;color:string;quality:RenderQuality}){
  const sweep=useRef<THREE.Group>(null)
  useFrame(({clock})=>{if(sweep.current)sweep.current.rotation.y=phase+Math.sin(clock.getElapsedTime()*.42+phase)*.72})
  if(!night)return null
  return <group position={[x,.45,z]}>
    <mesh position={[0,10,0]}><boxGeometry args={[2.2,20,2.2]}/><meshStandardMaterial color="#10151a" roughness={.58} metalness={.34}/></mesh>
    <mesh position={[0,20.9,0]}><boxGeometry args={[5.8,1.6,3.2]}/><meshStandardMaterial color="#182029" emissive={color} emissiveIntensity={.22} roughness={.4}/></mesh>
    <group ref={sweep} position={[0,20.8,0]}>
      <GlowBeam from={[0,0,0]} to={[72,15,0]} radius={4.2} color={color} opacity={.18}/>
      {RENDER_PROFILES[quality].accentLights&&<pointLight position={[4,1,0]} color={color} intensity={quality==='balanced'?9:20} distance={56} decay={1.6}/>}
    </group>
  </group>
}

function MoodDistrictDetails({ mood, night, quality }: { mood:DistrictMood; night:boolean; quality:RenderQuality }) {
  const scene=moodScene(mood)
  const profile=RENDER_PROFILES[quality]
  const extent=GRID*CELL
  if(mood==='default')return null

  if(mood==='cyberpunk')return <group>
    {Array.from({length:quality==='low'?8:quality==='balanced'?14:20},(_,i)=>{
      const x=-142+((i*53)%284),z=-132+((i*79)%264),horizontal=i%2===0
      const c=i%6===0?scene.accent:i%4===0?'#ff386c':scene.window
      return <group key={`buried-feed-${i}`} position={[x,.13,z]} rotation={[0,horizontal?0:Math.PI/2,0]}>
        <mesh><boxGeometry args={[10+(i%5)*4,.08,.55]}/><meshStandardMaterial color="#0c1417" roughness={.5} metalness={.42}/></mesh>
        <mesh position={[(i%3-1)*3,.055,0]}><boxGeometry args={[1.6,.055,.18]}/><meshStandardMaterial color={c} emissive={c} emissiveIntensity={night?1.1:.08}/></mesh>
      </group>
    })}
    {[-132,-72,-8,62,126].slice(0,quality==='low'?3:5).map((x,i)=><group key={`media-skin-${i}`} position={[x,.6,[-104,-36,42,-76,114][i]]} rotation={[0,[.38,-.7,.92,-.2,.64][i],0]}>
      <mesh position={[-10,8.8,0]}><boxGeometry args={[.7,17.6,.7]}/><meshStandardMaterial color="#17252b" metalness={.5} roughness={.48}/></mesh>
      <mesh position={[10,8.8,0]}><boxGeometry args={[.7,17.6,.7]}/><meshStandardMaterial color="#17252b" metalness={.5} roughness={.48}/></mesh>
      <mesh position={[0,16.3,0]}><boxGeometry args={[22,6.4,.38]}/><meshStandardMaterial color="#03080a" emissive={i%2?scene.accent:scene.window} emissiveIntensity={night?1.25:.12} roughness={.55} metalness={.25}/></mesh>
      <SignPanel text={`fractured-media-${i}`} variant="glyph" width={21.2} height={5.6} bg="#020607" fg={i%2?scene.accent:scene.window} accent={i===1?'#ff386c':'#f4fff8'} position={[0,16.3,.25]} opacity={night?1:.66}/>
      <mesh position={[0,11.9,.24]}><boxGeometry args={[20,.28,.16]}/><meshBasicMaterial color={i%2?'#ff386c':scene.accent} transparent opacity={night?.82:.22} toneMapped={false}/></mesh>
      <mesh position={[-8.7,16.3,.27]}><boxGeometry args={[.28,5.8,.16]}/><meshBasicMaterial color={i%2?scene.window:'#ff386c'} transparent opacity={night?.86:.24} toneMapped={false}/></mesh>
    </group>)}
    {(quality==='low'?[-112,112]:[-112,0,112]).flatMap((x,xi)=>[-96,96].map((z,zi)=><group key={`relay-${x}-${z}`} position={[x,.5,z]}>
      <mesh position={[0,6.5,0]}><boxGeometry args={[.72,13,.52]}/><meshStandardMaterial color="#14242a" emissive={scene.window} emissiveIntensity={night?.46:.04} roughness={.58} metalness={.48}/></mesh>
      <mesh position={[0,13.5,0]}><boxGeometry args={[3.8,.7,1.2]}/><meshStandardMaterial color="#071015" emissive={(xi+zi)%2?scene.accent:scene.window} emissiveIntensity={night?.9:.09}/></mesh>
      <SignPanel text={`relay-${xi}-${zi}`} variant="glyph" width={3.5} height={1.15} bg="#02070d" fg={(xi+zi)%2?scene.accent:scene.window} accent="#ff386c" position={[0,14.2,.65]} opacity={night?.92:.66}/>
    </group>))}
    {[[-104,-34,78,.16],[-28,92,92,-.42],[84,-88,68,.55],[34,-8,116,Math.PI/2.1]].map(([x,z,len,rot],i)=><group key={`duct-run-${i}`} position={[x as number,7.8+(i%2)*2.2,z as number]} rotation={[0,rot as number,0]}>
      <mesh castShadow><boxGeometry args={[len as number,.85,2.4]}/><meshStandardMaterial color="#10181b" roughness={.54} metalness={.46}/></mesh>
      <mesh position={[0,-.62,-.72]}><boxGeometry args={[(len as number)*.92,.18,.22]}/><meshStandardMaterial color="#25383c" emissive={i%2?scene.window:scene.accent} emissiveIntensity={night?.62:.05}/></mesh>
      {[-.36,.36].map((side,j)=><BeamBetween key={j} from={[-(len as number)*.46,.5,side*1.9]} to={[(len as number)*.46,.5,side*1.9]} width={.18} color="#18262a"/>)}
    </group>)}
    {Array.from({length:quality==='low'?4:8},(_,i)=><group key={`roof-rig-${i}`} position={[-138+((i*47)%276),5.8+(i%3)*1.6,-118+((i*83)%236)]} rotation={[0,(i%6)*.31,0]}>
      <mesh><boxGeometry args={[8+(i%4)*3,.52,1.1]}/><meshStandardMaterial color="#111a1d" roughness={.62} metalness={.5}/></mesh>
      <mesh position={[0,.45,0]}><boxGeometry args={[5+(i%3)*2,.18,.32]}/><meshStandardMaterial color={i%3? '#2f3f3e':'#6f753e'} emissive={i%3?scene.window:scene.accent} emissiveIntensity={night?.78:.06}/></mesh>
    </group>)}
    {[-120,-64,0,72].map((x,i)=><BeamBetween key={`hack-cable-${i}`} from={[x,9+(i%2)*2,-126]} to={[-x*.65,11+(i%3),126]} width={.045} color={i%2?'#263b3f':'#1a2a2e'}/>)}
    {Array.from({length:quality==='low'?24:quality==='balanced'?44:72},(_,i)=><mesh key={`rain-streak-${i}`} position={[-156+((i*37)%312),11+(i%7)*3,-148+((i*61)%296)]} rotation={[0,(i%5)*.16,.22]}>
      <boxGeometry args={[.035,7+(i%5)*2,.035]}/>
      <meshBasicMaterial color="#aeb9a8" transparent opacity={night?.14:.045}/>
    </mesh>)}
  </group>

  if(mood==='green')return <group>
    {[-128,-64,0,64,128].map((z,i)=><group key={`eco-corridor-${z}`} position={[0,.62,z+(i%2?10:-10)]}>
      <mesh><boxGeometry args={[extent*.72,.18,3.4]}/><meshStandardMaterial color="#4e744f" emissive="#7fe083" emissiveIntensity={night ? .42 : .04} roughness={1}/></mesh>
      {[-120,-80,-40,0,40,80,120].map((x,j)=><Tree key={`${z}-${j}`} x={x} z={0} scale={.32+(j%3)*.04}/>)}
    </group>)}
    {[-96,-32,32,96].map((x,i)=><group key={`solar-walk-${x}`} position={[x,.75,i%2?-22:22]}>
      <mesh><boxGeometry args={[21,.22,2.3]}/><meshStandardMaterial color="#283c3b" emissive="#7fe083" emissiveIntensity={night ? .28 : .02} metalness={.25} roughness={.34}/></mesh>
      {night&&profile.microLights&&<pointLight position={[0,2.8,0]} color="#9cff8d" intensity={9} distance={28} decay={1.9}/>}
    </group>)}
  </group>

  if(mood==='totalitarian')return <group>
    <mesh position={[0,.06,0]}><boxGeometry args={[26,.12,extent*.9]}/><meshStandardMaterial color="#252b2f" roughness={.92}/></mesh>
    <mesh position={[0,.08,0]}><boxGeometry args={[extent*.9,.12,26]}/><meshStandardMaterial color="#252b2f" roughness={.92}/></mesh>
    <mesh position={[0,.2,0]}><boxGeometry args={[4.4,.1,extent*.92]}/><meshBasicMaterial color={scene.accent} transparent opacity={night ? .58 : .28}/></mesh>
    <mesh position={[0,.21,0]}><boxGeometry args={[extent*.92,.1,4.4]}/><meshBasicMaterial color={scene.accent} transparent opacity={night ? .48 : .2}/></mesh>
    <group position={[0,.48,0]}>
      <mesh position={[0,1.5,0]}><boxGeometry args={[22,3,12]}/><meshStandardMaterial color="#20262b" roughness={.86}/></mesh>
      <mesh position={[0,3.25,0]}><boxGeometry args={[14,.9,7]}/><meshStandardMaterial color="#7b1015" emissive="#2b0205" emissiveIntensity={night?.35:.03}/></mesh>
    </group>
    {[-132,-66,66,132].map((x,i)=><group key={`pylon-${x}`} position={[x,.4,i%2?132:-132]}>
      <mesh position={[0,12,0]}><boxGeometry args={[2.8,24,2.8]}/><meshStandardMaterial color="#15191d" emissive="#273844" emissiveIntensity={night?.28:.02} roughness={.7}/></mesh>
      <mesh position={[0,24.7,0]}><boxGeometry args={[5.6,1.2,1]}/><meshStandardMaterial color={scene.accent} emissive={scene.accent} emissiveIntensity={night?1.3:.08}/></mesh>
      {night&&profile.accentLights&&<pointLight position={[0,20,0]} color={scene.lamp} intensity={quality==='balanced'?14:32} distance={88} decay={1.6}/>}
    </group>)}
    {(quality==='low'?[[-146,-146],[146,146]]:[[-146,-146],[-146,146],[146,-146],[146,146]]).map(([x,z],i)=><SweepingSearchlight key={`search-${x}-${z}`} x={x} z={z} phase={i*1.7} night={night} color={scene.lamp} quality={quality}/>)}
    {night&&quality!=='low'&&[-112,112].flatMap((x,xi)=>[-112,112].map((z,zi)=><GlowBeam key={`fixed-search-${x}-${z}`} from={[x,4,z]} to={[xi===zi?-18:18,36,xi===zi?120:-120]} radius={3.2} color={scene.lamp} opacity={.1}/>))}
  </group>

  return <group>
    <mesh position={[0,.08,0]}><boxGeometry args={[74,.16,54]}/><meshStandardMaterial color="#63724f" roughness={1}/></mesh>
    <mesh position={[0,.22,0]}><boxGeometry args={[78,.1,3.2]}/><meshStandardMaterial color="#c3b18a" roughness={1}/></mesh>
    <mesh position={[0,.23,0]}><boxGeometry args={[3.2,.1,58]}/><meshStandardMaterial color="#c3b18a" roughness={1}/></mesh>
    {[-84,84].flatMap((x,xi)=>[-84,84].map((z,zi)=><group key={`campus-lamp-${x}-${z}`} position={[x,.45,z]}>
      <mesh position={[0,4.6,0]}><boxGeometry args={[.38,8.4,.38]}/><meshStandardMaterial color="#29323c" roughness={.6}/></mesh>
      <mesh position={[0,8.9,0]}><boxGeometry args={[2.6,.28,1.1]}/><meshStandardMaterial color={xi===zi?scene.accent:scene.windowAlt} emissive={xi===zi?scene.accent:scene.windowAlt} emissiveIntensity={night?1.2:.18}/></mesh>
      {night&&profile.microLights&&<pointLight position={[0,8,0]} color={scene.window} intensity={18} distance={42} decay={1.8}/>}
    </group>))}
    <group position={[0,.4,-92]}>
      <mesh position={[0,7,0]}><boxGeometry args={[8,14,8]}/><meshStandardMaterial color="#6d695f" roughness={.94}/></mesh>
      <mesh position={[0,15.2,0]}><boxGeometry args={[5,2.4,5]}/><meshStandardMaterial color="#334d73" emissive="#172a48" emissiveIntensity={night?.22:0}/></mesh>
      {night&&profile.accentLights&&<pointLight position={[0,13,0]} color={scene.windowAlt} intensity={quality==='balanced'?9:16} distance={38} decay={1.8}/>}
    </group>
  </group>
}

function MoodPostProcessing({mood,night,quality,edgeSmoothing,structure}:{mood:DistrictMood;night:boolean;quality:RenderQuality;edgeSmoothing:boolean;structure:boolean}){
  const scene=moodScene(mood)
  const filter = mood==='cyberpunk'
    ? {vignette:.48,bloom:.76,threshold:night ? .16 : .44}
    : mood==='totalitarian'
      ? {vignette:.66,bloom:-.12,threshold:night ? .44 : 1.05}
      : mood==='green'
        ? {vignette:.26,bloom:.05,threshold:night ? .36 : 1.04}
        : mood==='university'
          ? {vignette:.3,bloom:.1,threshold:night ? .34 : 1.02}
          : {vignette:.34,bloom:0,threshold:night ? .32 : 1.04}
  if(structure&&!edgeSmoothing)return null
  return <EffectComposer multisampling={0}>
    {structure?<></>:<Bloom intensity={Math.max(.04,(night ? .55 : .12)+scene.bloom+filter.bloom)*(quality==='low'?.62:quality==='balanced'?.82:1)} luminanceThreshold={filter.threshold} mipmapBlur={quality!=='low'&&mood!=='cyberpunk'&&mood!=='totalitarian'} />}
    {structure?<></>:<Vignette eskil={false} offset={mood==='totalitarian' ? .08 : .18} darkness={filter.vignette} />}
    {edgeSmoothing?<SMAA/>:<></>}
  </EffectComposer>
}

function CityWorld(props: SceneProps & { renderQuality: RenderQuality; compactPreview:boolean; previewShadows:boolean }) {
  const [hoveredLot,setHoveredLot]=useState<{x:number;z:number}|null>(null)
  const [manipulating,setManipulating]=useState(false)
  const selected = props.buildings.find(b=>b.id===props.selectedId)
  const scene=moodScene(props.mood)
  const profile=RENDER_PROFILES[props.renderQuality]
  const occupied = useMemo(()=>{
    const keys=new Set(props.plazas.map(p=>`${Math.round(p.x/CELL)},${Math.round(p.z/CELL)}`))
    for(const b of props.buildings){
      const a=b.rotation*Math.PI/180,c=Math.abs(Math.cos(a)),s=Math.abs(Math.sin(a)),halfX=(c*b.width+s*b.depth)/2+5,halfZ=(s*b.width+c*b.depth)/2+5
      for(const lot of lots)if(Math.abs(lot.x-b.x)<=halfX&&Math.abs(lot.z-b.z)<=halfZ)keys.add(`${lot.gx},${lot.gz}`)
    }
    return keys
  },[props.buildings,props.plazas])
  const cameraBounds=useMemo<SceneBounds>(()=>{
    if(props.buildings.length===0&&props.plazas.length===0)return {x:0,z:0,radius:150,height:24}
    let minX=Infinity,maxX=-Infinity,minZ=Infinity,maxZ=-Infinity,maxHeight=18
    for(const building of props.buildings){const half=Math.max(building.width,building.depth)*.55;minX=Math.min(minX,building.x-half);maxX=Math.max(maxX,building.x+half);minZ=Math.min(minZ,building.z-half);maxZ=Math.max(maxZ,building.z+half);maxHeight=Math.max(maxHeight,building.height)}
    for(const plaza of props.plazas){minX=Math.min(minX,plaza.x-CELL*.45);maxX=Math.max(maxX,plaza.x+CELL*.45);minZ=Math.min(minZ,plaza.z-CELL*.45);maxZ=Math.max(maxZ,plaza.z+CELL*.45)}
    const extent=Math.max(maxX-minX,maxZ-minZ)
    return {x:(minX+maxX)/2,z:(minZ+maxZ)/2,radius:clamp(extent*.46+maxHeight*.3+30,92,245),height:maxHeight}
  },[props.buildings,props.plazas])
  const solar=solarModel(props.hour)
  const daylight=props.viewMode==='activity'?0:solar.daylight
  const night=daylight<.2
  const sun=[solar.direction.x*220,Math.max(8,solar.direction.y*220),solar.direction.z*220] as [number,number,number]
  const blend=(from:string,to:string)=>new THREE.Color(from).lerp(new THREE.Color(to),daylight).getStyle()
  const background=blend(scene.backgroundNight,scene.backgroundDay)
  const fogColor=blend(scene.fogNight,scene.fogDay)
  const lightColor=blend(scene.lamp,'#ffd19a')
  const ambientDay=props.mood==='green'?.5:.42
  const fogNear=THREE.MathUtils.lerp(props.mood==='cyberpunk'?185:220,280,daylight)
  const fogFar=props.mood==='green'?760:props.mood==='cyberpunk'?620:props.mood==='totalitarian'?650:690
  const nightCrowd=night?(props.signals.nightAccess==='open'?1.28:props.signals.nightAccess==='quiet'?.58:.78):1
  const peopleBase=props.renderQuality==='low'?18:36
  const peopleCount=Math.round(clamp(peopleBase*(.48+props.signals.activity*.006)*nightCrowd,6,props.renderQuality==='low'?24:48))
  const verticalTraffic=props.signals.specialistGrowth?6:night&&props.signals.nightAccess==='quiet'?4:5
  const horizontalTraffic=props.signals.specialistGrowth?5:night&&props.signals.nightAccess==='quiet'?3:4
  const richPreview=!props.preview||!props.compactPreview
  return <>
    <color attach="background" args={[background]} />
    <fog attach="fog" args={[fogColor,fogNear,fogFar]} />
    <Atmosphere hour={props.hour} daylight={daylight} mood={props.mood} quality={props.renderQuality} />
    <ambientLight intensity={THREE.MathUtils.lerp(props.mood==='cyberpunk'?.18:.15,ambientDay,daylight)} />
    <hemisphereLight args={[blend(scene.window,'#fff0cf'),'#3a4031',THREE.MathUtils.lerp(.34,.86,daylight)]} />
    <directionalLight castShadow={!props.preview||props.previewShadows} position={sun} intensity={THREE.MathUtils.lerp(.28,3.1,daylight)} color={lightColor} shadow-mapSize={[profile.shadowMap,profile.shadowMap]} shadow-camera-left={-190} shadow-camera-right={190} shadow-camera-top={190} shadow-camera-bottom={-190} shadow-bias={-.00015} shadow-normalBias={.025} shadow-radius={THREE.MathUtils.lerp(1.4,2.4,daylight)} />
    <StreetNetwork night={night} mood={props.mood} quality={props.renderQuality} />
    {!props.preview&&<><WaterfrontEdge mood={props.mood} night={night} quality={props.renderQuality}/><MoodDistrictDetails mood={props.mood} night={night} quality={props.renderQuality} /></>}
    {richPreview&&<BackgroundCity quality={props.renderQuality} mood={props.mood} night={night} />}
    {lots.map(lot=>{
      const taken=occupied.has(`${lot.gx},${lot.gz}`)
      const shade=(Math.abs(lot.gx*7+lot.gz*11)%5)
      return <group key={`${lot.gx}-${lot.gz}`} position={[lot.x,0,lot.z]}>
        <mesh position={[0,LOT_CENTER_Y,0]} receiveShadow onClick={e=>{e.stopPropagation();if(!props.focusMode&&!taken)props.onLot(lot.x,lot.z)}} onPointerOver={()=>{if(!props.focusMode&&!taken&&props.tool!=='select'){document.body.style.cursor='crosshair';setHoveredLot({x:lot.x,z:lot.z})}}} onPointerOut={()=>{document.body.style.cursor='default';setHoveredLot(null)}}>
          <boxGeometry args={[CELL-4.8,LOT_DEPTH,CELL-4.8]} /><meshStandardMaterial color={!props.focusMode&&!taken&&props.tool!=='select'?'#b6c27b':['#a8a28f','#b2aa95','#9da18c','#b8ad93','#a7a991'][shade]} roughness={1} />{richPreview&&<Edges color="#8f8a78" lineWidth={.35} />}
        </mesh>
        {richPreview&&!taken&&shade===1&&<mesh position={[7,.28,-7]} receiveShadow><boxGeometry args={[10,.12,6]} /><meshStandardMaterial color="#727f67" roughness={1} /></mesh>}
        {richPreview&&!taken&&shade===3&&<>{[-7,0,7].map((x,i)=><mesh key={i} position={[x,.35,5]}><boxGeometry args={[4,.32,9]} /><meshStandardMaterial color={['#71805b','#866f53','#657652'][i]} roughness={1} /></mesh>)}{props.renderQuality!=='low'&&<Tree x={8} z={-7} scale={.55}/>}</>}
        {richPreview&&!taken&&shade===4&&<><mesh position={[0,.34,0]}><boxGeometry args={[19,.24,5.8]} /><meshStandardMaterial color="#7c8b64" roughness={1} /></mesh><mesh position={[-5.8,.48,-4.4]}><boxGeometry args={[7.2,.2,2.8]} /><meshStandardMaterial color="#697b57" roughness={1} /></mesh><mesh position={[5.4,.48,4.2]}><boxGeometry args={[8.4,.2,3.2]} /><meshStandardMaterial color="#8b7d5e" roughness={1} /></mesh><Tree x={-8} z={6.5} scale={.5}/></>}
        {richPreview&&!taken&&shade===0&&props.renderQuality!=='low'&&<><Tree x={-8} z={-8} scale={.62}/><Tree x={8} z={7} scale={.55}/></>}
        {richPreview&&!taken&&shade===2&&<mesh position={[0,.45,-8]} castShadow><boxGeometry args={[7,.6,1.1]} /><meshStandardMaterial color="#686960" roughness={1} /></mesh>}
      </group>
    })}
    {!props.focusMode&&hoveredLot&&<PlacementPreview x={hoveredLot.x} z={hoveredLot.z} tool={props.tool}/>}
    {props.buildings.map(b=><BrutalistBuilding key={b.id} b={b} selected={!props.focusMode&&b.id===props.selectedId} viewMode={props.viewMode} night={night} mood={props.mood} quality={props.renderQuality} occupancy={programOccupancy(b,props.hour,props.signals)} signals={props.signals} preview={props.preview} compactPreview={props.compactPreview} onClick={props.focusMode?undefined:()=>props.tool==='demolish'?props.onDemolish(b.id):props.onSelect(b.id)} onChange={patch=>props.onBuildingChange(b.id,patch)} onEditStart={props.onEditStart} onManipulating={setManipulating}/>)}
    {props.plazas.map(p=>props.preview&&props.compactPreview?<mesh key={p.id} position={[p.x,.18,p.z]}><boxGeometry args={[CELL-7,.3,CELL-7]}/><meshStandardMaterial color={p.kind==='water'?'#5f8188':p.kind==='garden'?'#647756':'#a59a82'} roughness={.92}/></mesh>:<PlazaObject key={p.id} plaza={p} selected={!props.focusMode&&p.id===props.selectedId} interactive={!props.focusMode} onClick={()=>props.tool==='demolish'?props.onDemolish(p.id):props.onSelect(p.id)} />)}
    {!props.preview&&Array.from({length:verticalTraffic},(_,i)=>{const z=-144+i*(288/Math.max(1,verticalTraffic-1));return <Vehicle key={i} x={-16} z={z} moving={!props.paused} reverse={i%2===0} mood={props.mood} night={night} quality={props.renderQuality} color={['#a44b3d','#d0a541','#4b6575','#ddd6c5','#6a7354'][i%5]}/>})}
    {!props.preview&&Array.from({length:horizontalTraffic},(_,i)=>{const x=-144+i*(288/Math.max(1,horizontalTraffic-1));return <Vehicle key={`h${i}`} x={x} z={16} horizontal moving={!props.paused} reverse={i%2===1} mood={props.mood} night={night} quality={props.renderQuality} color={['#c8c0ac','#82564b','#4f6d6a','#a98942'][i%4]}/>})}
    {!props.preview&&Array.from({length:peopleCount},(_,i)=>{const lane=i%4,slots=Math.ceil(peopleCount/4),slot=Math.floor(i/4),along=-138+slot*(276/Math.max(1,slots-1));const vertical=lane<2,x=vertical?(lane?-12.2:12.2):along,z=vertical?along:(lane===2?-12.2:12.2);return <Human key={i} x={x} z={z} color={['#af4c3c','#d3b54a','#435d71','#6b714c','#9a6b88'][i%5]}/>})}
    <CameraRig mode={props.cameraMode} selected={selected} revision={props.cameraRevision} bounds={cameraBounds} enabled={!manipulating}/>
    {richPreview&&<MoodPostProcessing mood={props.mood} night={night} quality={props.renderQuality} edgeSmoothing={props.graphics.edgeSmoothing} structure={props.viewMode==='structure'}/>}
  </>
}

export default function CityScene(props: SceneProps) {
  const automatic=props.graphics.quality==='auto'
  const automaticKey=props.performanceKey
  const [automaticState,setAutomaticState]=useState<{key:string;quality:RenderQuality}>(()=>({key:automaticKey,quality:'low'}))
  const [warmedKey,setWarmedKey]=useState('')
  const [viewport,setViewport]=useState(() => ({width:typeof window==='undefined'?1440:window.innerWidth,height:typeof window==='undefined'?900:window.innerHeight}))
  const cooldown=useRef<{key:string;until:number}>({key:automaticKey,until:Date.now()+2400})
  const automaticQuality=automaticState.key===automaticKey?automaticState.quality:'low'
  const updateAutomaticQuality=useCallback((update:(quality:RenderQuality)=>RenderQuality)=>{
    setAutomaticState(current=>{
      const currentQuality=current.key===automaticKey?current.quality:'low'
      const nextQuality=update(currentQuality)
      return current.key===automaticKey&&current.quality===nextQuality?current:{key:automaticKey,quality:nextQuality}
    })
  },[automaticKey])
  const handleDecline=useCallback(()=>{
    cooldown.current={key:automaticKey,until:Date.now()+12000}
    updateAutomaticQuality(qualityDown)
  },[automaticKey,updateAutomaticQuality])
  const handleIncline=useCallback(()=>{
    const now=Date.now()
    if(cooldown.current.key!==automaticKey)cooldown.current={key:automaticKey,until:now+1800}
    if(now<cooldown.current.until)return
    updateAutomaticQuality(automaticQualityUp)
  },[automaticKey,updateAutomaticQuality])
  useEffect(()=>{
    if(props.preview)return
    const timer=window.setTimeout(()=>setWarmedKey(automaticKey),1200)
    return ()=>window.clearTimeout(timer)
  },[automaticKey,props.preview])
  useEffect(()=>{
    let frame:number|null=null
    const onResize=()=>{
      if(frame!==null)return
      frame=window.requestAnimationFrame(()=>{frame=null;setViewport({width:window.innerWidth,height:window.innerHeight})})
    }
    window.addEventListener('resize',onResize)
    return ()=>{window.removeEventListener('resize',onResize);if(frame!==null)window.cancelAnimationFrame(frame)}
  },[])
  const compactViewport=viewport.width<=720||viewport.height<=520
  let requestedQuality:RenderQuality=props.preview?(compactViewport?'low':'balanced'):automatic?automaticQuality:props.graphics.quality==='auto'?'low':props.graphics.quality
  if(!props.preview&&warmedKey!==automaticKey&&requestedQuality==='high')requestedQuality='balanced'
  const protectedMood=props.mood==='cyberpunk'||props.mood==='totalitarian'||compactViewport
  const renderQuality:RenderQuality=protectedMood&&requestedQuality==='high'?'balanced':requestedQuality
  const profile=RENDER_PROFILES[renderQuality]
  const pixelBudget=props.preview?1600000:renderQuality==='low'?1800000:renderQuality==='balanced'?3200000:5000000
  const cssPixels=Math.max(1,viewport.width*viewport.height)
  const deviceDpr=typeof window==='undefined'?1:window.devicePixelRatio||1
  const dprCap=Math.max(.4,Math.min(profile.dpr[1],deviceDpr,Math.sqrt(pixelBudget/cssPixels)))
  const dprRange:[number,number]=[Math.min(profile.dpr[0],dprCap),dprCap]
  useEffect(()=>props.onEffectiveQualityChange(renderQuality),[props.onEffectiveQualityChange,renderQuality])
  const world=<><AdaptiveEvents/><CityWorld {...props} renderQuality={renderQuality} compactPreview={props.preview&&compactViewport} previewShadows={props.preview&&!compactViewport}/></>
  return <Canvas shadows={!props.preview||!compactViewport} dpr={dprRange} camera={{position:[128,78,152],fov:42,near:.2,far:1100}} gl={{antialias:false,toneMapping:THREE.ACESFilmicToneMapping,toneMappingExposure:1.04,powerPreference:'high-performance'}} onPointerMissed={()=>{if(!props.focusMode)props.onSelect(null)}}>
    {automatic&&!props.preview?<PerformanceMonitor key={automaticKey} iterations={5} ms={400} threshold={.6} bounds={()=>[40,55]} flipflops={Infinity} onDecline={handleDecline} onIncline={handleIncline}>{world}</PerformanceMonitor>:world}
  </Canvas>
}
