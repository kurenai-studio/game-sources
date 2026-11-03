import { lazy, Suspense, useCallback, useEffect, useId, useMemo, useRef, useState } from 'react'
import {
  Aperture, BarChart3, Box, Building2, Camera, ChevronDown, CircleHelp, Clock3, CloudSun, Eye,
  Factory, FastForward, Flower2, GraduationCap, Hand, HeartPulse, Home, Landmark, Layers3,
  Leaf, Menu, MousePointer2, Pause, Play, Plus, Redo2, RotateCcw, Save, ScanLine, Settings2, Sparkles, Clapperboard,
  Trash2, Undo2, Users, X, Zap,
} from 'lucide-react'
import { CITY_TEMPLATES, readCityLibrary, snapshotSummary, writeCityLibrary } from './cityLibrary'
import type { CitySaveRecord, CityTemplate } from './cityLibrary'
import { controlContextNote, controlDisabledReason } from './controlApplicability'
import { ARCHITECTURAL_TRAJECTORIES, CELL, COMPOSITIONS, DESIGN_LANGUAGES, HALF, PROFILES, PROGRAMS, TONES, TYPOLOGIES, initialBuildings, lots, makeBuilding } from './data'
import type { Building, CameraMode, CityMetrics, CitySignals, Composition, DecisionRecord, DesignLanguage, DistrictCharter, DistrictMood, FacadeStrategy, GameSnapshot, GraphicsQuality, GraphicsSettings, Plaza, Profile, Program, StructuralSystem, Tone, Tool, Typology, ViewMode } from './types'

const CityScene=lazy(()=>import('./CityScene'))

const GRAPHICS_KEY = 'monument-graphics-v2'
const LEGACY_GRAPHICS_KEY = 'monument-graphics-v1'
const SIM_TICK_MS = 560
const COMPACT_EDITOR_MEDIA = '(max-width: 720px), (max-height: 600px) and (orientation: landscape) and (max-width: 900px)'
const DEFAULT_GRAPHICS:GraphicsSettings={quality:'auto',edgeSmoothing:true}
const normalizeGraphics=(stored:Partial<GraphicsSettings>,resetLegacyHigh=false):GraphicsSettings=>{
  const storedQuality=stored.quality??''
  const validQuality=['auto','low','balanced','high'].includes(storedQuality)
    ? storedQuality as GraphicsQuality
    : 'auto'
  return {
    quality:resetLegacyHigh&&validQuality==='high'?'auto':validQuality,
    edgeSmoothing:typeof stored.edgeSmoothing==='boolean'?stored.edgeSmoothing:DEFAULT_GRAPHICS.edgeSmoothing,
  }
}
const readGraphics=():GraphicsSettings=>{
  if(typeof localStorage==='undefined')return DEFAULT_GRAPHICS
  try{
    const current=localStorage.getItem(GRAPHICS_KEY)
    if(current!==null)return normalizeGraphics(JSON.parse(current) as Partial<GraphicsSettings>)
    const legacy=localStorage.getItem(LEGACY_GRAPHICS_KEY)
    if(legacy!==null){
      const migrated=normalizeGraphics(JSON.parse(legacy) as Partial<GraphicsSettings>,true)
      try{localStorage.setItem(GRAPHICS_KEY,JSON.stringify(migrated))}catch{/* the in-memory preference still works */}
      return migrated
    }
    return DEFAULT_GRAPHICS
  }catch{return DEFAULT_GRAPHICS}
}

function SceneFallback(){
  return <div className="scene-fallback" role="status" aria-live="polite" aria-label="Preparing the city view">
    <div className="scene-fallback-sky" aria-hidden="true"/>
    <div className="scene-fallback-horizon" aria-hidden="true">
      <i className="fallback-mass mass-1"/><i className="fallback-mass mass-2"/><i className="fallback-mass mass-3"/><i className="fallback-mass mass-4"/><i className="fallback-mass mass-5"/><i className="fallback-mass mass-6"/>
      <span className="fallback-deck deck-1"/><span className="fallback-deck deck-2"/><span className="fallback-deck deck-3"/>
    </div>
    <div className="scene-fallback-grid" aria-hidden="true"/>
    <div className="scene-fallback-status"><i/><div><b>Forming the city</b><small>Concrete, light, and public ground</small></div></div>
  </div>
}
const toolDefs: Array<{ id: Tool; label: string; key: string; icon: typeof MousePointer2 }> = [
  { id: 'select', label: 'Select', key: 'V', icon: MousePointer2 },
  { id: 'housing', label: 'Residential', key: '1', icon: Home },
  { id: 'work', label: 'Studio', key: '2', icon: Factory },
  { id: 'civic', label: 'Institution', key: '3', icon: Landmark },
  { id: 'culture', label: 'Gallery', key: '4', icon: Aperture },
  { id: 'mixed', label: 'Hybrid', key: '5', icon: Building2 },
  { id: 'plaza', label: 'Public realm', key: '6', icon: Flower2 },
  { id: 'demolish', label: 'Demolish', key: 'X', icon: Trash2 },
]

const viewDefs: Array<{ id: ViewMode; label: string; icon: typeof Eye }> = [
  { id: 'material', label: 'Material', icon: Box }, { id: 'program', label: 'Program', icon: Layers3 },
  { id: 'structure', label: 'Structure', icon: ScanLine },
  { id: 'daylight', label: 'Daylight', icon: CloudSun }, { id: 'activity', label: 'Activity', icon: Zap },
  { id: 'carbon', label: 'Embodied C', icon: Leaf },
]

const moodDefs: Array<{ id: DistrictMood; label: string; icon: typeof Eye; accent: string; hour: number }> = [
  { id: 'default', label: 'Default', icon: Box, accent: '#d7ff43', hour: 16.5 },
  { id: 'cyberpunk', label: 'Cyberpunk', icon: Sparkles, accent: '#51f4ff', hour: 22 },
  { id: 'green', label: 'Green', icon: Leaf, accent: '#7fe083', hour: 14.5 },
  { id: 'totalitarian', label: 'Totalitarian', icon: Landmark, accent: '#9d111b', hour: 20.5 },
  { id: 'university', label: 'University', icon: GraduationCap, accent: '#f0c65e', hour: 19.75 },
]

const normalizeMood = (mood?: GameSnapshot['mood']): DistrictMood => mood === 'brutalist' || !mood ? 'default' : mood

const namePool = ['Aalto Court', 'Concrete Commons', 'Massing House', 'New Brutal Forum', 'Pilotis Hall', 'Aggregate Works', 'Commons Stack', 'Sunken Assembly', 'Public Plinth', 'Terrace Nine']

type CharterChoice='open'|'quiet'|'shared'|'specialist'|'reuse'|'formal'
type EventChoice = { label:string; detail:string; choice:CharterChoice; impacts:string[] }
type CityEvent = { id:keyof DistrictCharter; sketch:number; kicker:string; title:string; copy:string; choices:EventChoice[] }
type GrowthObjective = {label:string;current:number;target:number;direction?:'min'|'max';unit?:string;decimals?:number;available?:boolean}
type GrowthBrief = {name:string;note:string;reward:string;objectives:GrowthObjective[]}

const CITY_EVENTS:CityEvent[]=[
  {id:'undercroft',sketch:1,kicker:'City choice / ground life',title:'How should the ground live?',copy:'Covered walks, courtyards, and building edges can support late markets and long evenings, or planted thresholds, soft light, and quieter shared gardens.',choices:[{label:'Keep the ground open',detail:'Night stalls and longer evening life appear beneath raised buildings.',choice:'open',impacts:['ADDS NIGHT MARKETS','ACTIVITY +11','LIVELIER EVENINGS']},{label:'Make quiet courtyards',detail:'Planters and soft thresholds turn the ground floor into calm shared gardens.',choice:'quiet',impacts:['ADDS GARDEN ROOMS','APPROVAL +3','CALMER NIGHTS']}]},
  {id:'commons',sketch:2,kicker:'City choice / shared space',title:'What should buildings share?',copy:'The district can weave open common rooms through many buildings, or let workshops, studios, and cultural spaces become more distinct and specialized.',choices:[{label:'Make common rooms',detail:'Warm shared-room bands appear across housing, civic, and mixed buildings.',choice:'shared',impacts:['ADDS COMMON ROOMS','APPROVAL +7','ACTIVITY +4']},{label:'Grow specialist places',detail:'Studios and cultural buildings develop brighter workshops and stronger identities.',choice:'specialist',impacts:['ADDS WORKSHOP LIGHTS','JOBS +8%','CULTURE +8%']}]},
  {id:'aggregate',sketch:3,kicker:'City choice / material language',title:'How should the city age?',copy:'Frames and panels can return in a visibly adapted city, or the district can pursue cleaner joints and a more formal concrete language.',choices:[{label:'Build from what remains',detail:'Reclaimed panels, repairs, and mismatched aggregate become part of the city.',choice:'reuse',impacts:['ADDS RECLAIMED PANELS','CARBON −18%','VISIBLE REPAIR']},{label:'Keep a formal language',detail:'Clean joint bands and slower weathering give the district a composed civic character.',choice:'formal',impacts:['ADDS CLEAN JOINTS','SLOWER WEATHERING','CARBON +6%']}]},
]

interface BuildingPerformance {
  floors: number
  gfa: number
  far: number
  daylight: number
  energy: number
  carbon: number
  egress: number
  publicLife: number
  shadeHours: number
  diversity: number
}

function performanceFor(b: Building, buildings: Building[], plazas: Plaza[]): BuildingPerformance {
  const floors = Math.max(1, Math.floor((b.height - b.pilotis) / b.floorHeight))
  const morphologyEfficiency=Math.max(.54,.82-b.voids*.0024-b.taper*.0011)
  const gfa = b.width * b.depth * floors * morphologyEfficiency
  const neighbors = buildings.filter(n => n.id !== b.id && Math.hypot(n.x - b.x, n.z - b.z) < CELL * 1.65)
  const taller = neighbors.filter(n => n.height > b.height * .72).length
  const diversity = new Set(neighbors.map(n => n.program)).size
  const plazaDistance = plazas.length ? Math.min(...plazas.map(p => Math.hypot(p.x-b.x,p.z-b.z))) : 999
  const publicAccess = plazaDistance < CELL * 1.55 ? 18 : plazaDistance < CELL * 2.5 ? 9 : 0
  const orientationBonus = Math.abs(Math.sin(b.rotation * Math.PI / 180)) * 7
  const daylight = Math.max(19, Math.min(96, 88 - b.depth * 1.38 - taller * 5 + b.porosity * .2 + orientationBonus + b.voids*.16))
  const energy = Math.max(42,Math.round(72 + b.porosity * .76 + b.depth * .86 - b.balconies * .11 - b.vegetation*.08 + b.weathering*.05 + (b.facade === 'brise-soleil' ? -14-b.facadeDepth*3 : 0)))
  const carbon = Math.round(gfa * (b.structural === 'walls' ? .62 : b.structural === 'cores' ? .54 : .48) * (1-b.voids*.0018))
  const egress = Math.min(100, Math.round(38 + b.cores * 23 - Math.max(0, floors - 18) * 1.4 + (b.structural === 'cores' ? 8 : 0)))
  const publicLife = Math.min(100, Math.round(26 + publicAccess + diversity * 8 + b.pilotis * 2 + b.vegetation*.08 + b.voids*.06 + (b.program === 'culture' || b.program === 'civic' ? 16 : 0)))
  return { floors, gfa: Math.round(gfa), far: gfa / ((CELL-4.8)*(CELL-4.8)), daylight: Math.round(daylight), energy, carbon, egress, publicLife, shadeHours: Math.max(1.2, Math.round((b.height/14 + taller*.8)*10)/10), diversity }
}

function metricsFor(buildings: Building[], plazas: Plaza[]): CityMetrics {
  let capacity = 0, jobs = 0, culture = 0, civic = 0, carbon = 0
  buildings.forEach(b => {
    const perf = performanceFor(b, buildings, plazas)
    const floorArea = perf.gfa
    const homes = b.program === 'housing' ? 1 : b.program === 'mixed' ? .5 : 0
    const work = b.program === 'work' ? 1 : b.program === 'mixed' ? .55 : b.program === 'civic' ? .22 : 0
    capacity += (floorArea / 36) * homes * 2.1
    jobs += (floorArea / 29) * work
    culture += (floorArea / 24) * (b.program === 'culture' ? .72 : b.program === 'mixed' ? .13 : 0)
    civic += (floorArea / 24) * (b.program === 'civic' ? .78 : b.program === 'mixed' ? .1 : 0)
    carbon += floorArea * (b.structural === 'walls' ? .62 : b.structural === 'cores' ? .54 : .48) * (b.tone === 'raw' ? 1.08 : .94)
  })
  const gardens=plazas.filter(p=>p.kind==='garden').length
  const waters=plazas.filter(p=>p.kind==='water').length
  const forums=plazas.filter(p=>p.kind==='forum').length
  culture+=forums*58
  civic+=waters*24+gardens*18
  carbon=Math.max(0,carbon-gardens*46-plazas.reduce((sum,p)=>sum+p.trees*2.2,0))
  capacity = Math.round(capacity)
  const population = Math.round(capacity * Math.min(.94, .61 + (culture + civic + plazas.length * 55) / Math.max(1100, capacity * 2.6)))
  const activity = Math.round(Math.min(100, 24 + buildings.length * 1.15 + plazas.length * 4 + forums*8 + gardens*3 + Math.min(jobs, population) / 85))
  const balance = population ? Math.min(jobs, population) / Math.max(jobs, population) : .5
  const approval = Math.round(Math.min(96, 40 + plazas.length * 3 + gardens*2 + waters + balance * 24 + Math.min(17, (culture + civic) / 75) - Math.max(0, carbon / 12000 - 4)))
  return { population, capacity, jobs: Math.round(jobs), culture: Math.round(culture), civic: Math.round(civic), activity, approval, carbon: Math.round(carbon) }
}

const fmt = (n: number) => n >= 1000 ? `${(n / 1000).toFixed(n >= 10000 ? 0 : 1)}k` : Math.round(n).toString()

function MiniStat({ icon: Icon, value, label, tone }: { icon: typeof Users; value: string; label: string; tone?: string }) {
  return <div className="mini-stat" title={label}><Icon size={14} style={{ color: tone }} /><div><b>{value}</b><span>{label}</span></div></div>
}

function Range({ label, value, min, max, step = 1, unit = '', disabledReason, contextNote, onChange, onStart }: { label: string; value: number; min: number; max: number; step?: number; unit?: string; disabledReason?: string; contextNote?: string; onChange: (v: number) => void; onStart: () => void }) {
  const pct = ((value - min) / (max - min)) * 100
  const reasonId=useId()
  const disabled=Boolean(disabledReason)
  const description=disabledReason??contextNote
  return <label className={`range-control${disabled?' disabled':''}`} title={disabledReason}>
    <span><span>{label}</span><b>{Number.isInteger(value) ? value : value.toFixed(1)}{unit}</b></span>
    <input aria-label={label} aria-describedby={description?reasonId:undefined} type="range" min={min} max={max} step={step} value={value} disabled={disabled} onPointerDown={disabled?undefined:onStart} onChange={e => {if(!disabled)onChange(Number(e.target.value))}} style={{ '--range': `${pct}%` } as React.CSSProperties} />
    {disabledReason&&<small id={reasonId} className="range-disabled-reason">{disabledReason}</small>}
    {!disabledReason&&contextNote&&<small id={reasonId} className="range-context-note">{contextNote}</small>}
  </label>
}

function ProgramBadge({ program }: { program: Program }) {
  return <span className="program-badge" style={{ '--program': PROGRAMS[program].color } as React.CSSProperties}>{PROGRAMS[program].short}</span>
}

function formCharacter(b:Building){
  if(b.composition==='capsule'&&b.branches>4)return {name:'Branching metabolist city',copy:'Inhabited booms leave permanent service spines as airborne streets and terminal rooms.'}
  if(b.composition==='capsule'&&b.taper>38)return {name:'Tapered plug-in monument',copy:'Replaceable pods contract into a legible skyline around a permanent serviced core.'}
  if(b.composition==='capsule')return {name:'Metabolist pod frame',copy:'Service spines, transfer racks and replaceable rooms form an architecture designed to keep changing.'}
  if(b.height>78&&b.crown>58&&b.branches>3&&(['charcoal','terracotta'].includes(b.tone)))return {name:'Neo-noir vertical city',copy:'Layered infrastructure, lit crowns, deep setbacks and airborne streets.'}
  if(b.height>48&&b.vegetation>58&&b.articulation>45)return {name:'Inhabited arcology',copy:'A dense climatic world of gardens, branches, courts and shared sky rooms.'}
  if(b.composition==='cluster'&&b.height<36&&b.articulation>56&&b.moduleDensity>2)return {name:'Hill village',copy:'Fine-grain houses, shifting roofs, lanes and accidental courtyards.'}
  if(b.composition==='megastructure'&&b.articulation>45)return {name:'Open megaframe',copy:'A permanent armature hosting changeable neighborhoods and bridges.'}
  if(b.voids>52&&b.pilotis>4)return {name:'Porous civic condenser',copy:'Open ground and carved social rooms connect the building to the city.'}
  if(b.taper>38||b.profile==='twisted')return {name:'Concrete landform',copy:'A singular silhouette shaped by gravity, light and sectional drift.'}
  return {name:'Evolving urban fabric',copy:'Pull the colored handles; character emerges from proportion and repetition.'}
}

const COMPOSITION_EFFECTS:Record<Composition,string>={
  bar:'One directional plate. BREAK cuts its rhythm without changing the family.',
  split:'Two separated wings held together by intermittent inhabited bridges.',
  cluster:'Rooms and houses aggregate in both directions around a shared center.',
  stack:'Independent plates slide and shrink as they rise, making occupied terraces.',
  court:'Four inhabited edges preserve a real open room at the center.',
  bridge:'Vertical anchors carry distinct airborne rooms across an open ground.',
  ring:'A continuous civic perimeter wraps a tall shared atrium.',
  capsule:'Replaceable pods attach to permanent service spines and transfer arms.',
  megastructure:'A deep structural armature hosts incomplete districts and sky streets.',
}

function Inspector({ building, performance, onUpdate, onCapture, onClose, onDuplicate, onDemolish }: { building: Building; performance: BuildingPerformance; onUpdate: (patch: Partial<Building>) => void; onCapture: () => void; onClose: () => void; onDuplicate: () => void; onDemolish: () => void }) {
  const [section, setSection] = useState<'form' | 'skin' | 'use' | 'analysis'>('form')
  const remix=()=>{
    const compositions=Object.keys(COMPOSITIONS) as Composition[]
    const profiles=Object.keys(PROFILES) as Profile[]
    const nextComposition=compositions[(compositions.indexOf(building.composition)+2+building.terraces)%compositions.length]
    const nextProfile=profiles[(profiles.indexOf(building.profile)+1+building.cores)%profiles.length]
    onCapture();onUpdate({composition:nextComposition,profile:nextProfile,voids:(building.voids+23)%68+2,taper:(building.taper+31)%62+3,cantilever:(building.cantilever+3.7)%13,terraces:building.terraces%7+1})
  }
  const siteOptions=[
    {id:'parcel',label:'Parcel',sub:'one block',width:28,depth:28},
    {id:'cross',label:'Cross-block',sub:'two-block span',width:62,depth:28},
    {id:'linear',label:'Urban bar',sub:'three-block span',width:94,depth:28},
    {id:'court',label:'Megacourt',sub:'two by two',width:62,depth:62},
    {id:'super',label:'Superblock',sub:'three by two',width:94,depth:62},
  ]
  const floors=Math.max(1,Math.floor((building.height-building.pilotis)/building.floorHeight))
  const blocksX=Math.max(1,Math.round(building.width/CELL)),blocksZ=Math.max(1,Math.round(building.depth/CELL))
  const podFloors=Math.max(1,Math.floor((building.height-Math.min(building.pilotis,building.height*.28))/building.floorHeight))
  const podDesiredRows=Math.round(Math.max(5,Math.min(14,5+Math.min(5,podFloors*.18)+(building.moduleDensity-1)/4*5)))
  const podLanes=1+Number(building.moduleDensity>=3&&building.depth>18)+Number(building.moduleDensity===5&&building.depth>38)
  const podSpines=Math.round(Math.max(1,Math.min(3,Math.max(building.cores,podLanes))))
  const podRows=Math.min(podDesiredRows,Math.max(4,Math.floor(64/(podSpines*2))))
  const podVoidBands=building.voids<20?0:building.voids<42?1:building.voids<60?2:3
  const podCrown=building.crown>76?4:building.crown>44?2:0
  const articulationTierBonus=['bar','megastructure'].includes(building.composition)?Math.floor(building.articulation/45):0
  const requestedTiers=Math.max(building.terraces,Math.ceil(floors/7)+Math.floor((building.moduleDensity-3)/2)+articulationTierBonus)
  const generatedCount=building.composition==='capsule'?(podRows-podVoidBands)*2*podSpines+building.branches+podCrown:Math.min(floors,requestedTiers)
  const character=formCharacter(building)
  const directMoves=[
    'repeat',
    !controlDisabledReason(building,'cantilever')&&'cantilever',
    !controlDisabledReason(building,'voids')&&'void',
    !controlDisabledReason(building,'taper')&&'taper',
    !controlDisabledReason(building,'articulation')&&'break',
    !controlDisabledReason(building,'branches')&&'branch',
    !controlDisabledReason(building,'crown')&&'crown',
  ].filter(Boolean).join(' · ')
  const siteLimit=HALF*CELL
  const snapToBlock=()=>{onCapture();onUpdate({x:Math.round(building.x/CELL)*CELL,z:Math.round(building.z/CELL)*CELL})}
  const nudge=(dx:number,dz:number)=>{onCapture();onUpdate({x:Math.max(-siteLimit,Math.min(siteLimit,building.x+dx)),z:Math.max(-siteLimit,Math.min(siteLimit,building.z+dz))})}
  return <aside className="inspector panel" data-testid="building-inspector">
    <div className="inspector-head"><div><span className="eyebrow">Selected structure</span><input aria-label="Building name" className="building-name" value={building.name} onFocus={onCapture} onChange={e => onUpdate({ name: e.target.value })} /></div><button className="icon-btn" onClick={onClose} aria-label="Close inspector"><X size={18} /></button></div>
    <div className="inspector-meta"><ProgramBadge program={building.program} /><span>{performance.floors} levels</span><span>{fmt(performance.gfa)} m² GFA</span></div>
    <div className="segmented tabs">
      <button className={section === 'form' ? 'active' : ''} onClick={() => setSection('form')}>Massing</button>
      <button className={section === 'skin' ? 'active' : ''} onClick={() => setSection('skin')}>Envelope</button>
      <button className={section === 'use' ? 'active' : ''} onClick={() => setSection('use')}>Use</button>
      <button className={section === 'analysis' ? 'active' : ''} onClick={() => setSection('analysis')}>Analysis</button>
    </div>
    {section === 'form' && <div className="control-stack">
      <div className="character-readout"><span>Form becoming</span><b>{character.name}</b><p>{character.copy}</p><small>Direct handles: drag <i>move</i>; pull {directMoves}.</small></div>
      <div className="label-row"><span>Site placement</span><span className="hint">move the selected structure</span></div>
      <div className="site-position">
        <div><span>East / west</span><b>{Math.round(building.x)}m</b></div>
        <div><span>North / south</span><b>{Math.round(building.z)}m</b></div>
        <button onClick={snapToBlock}>Snap to block</button>
      </div>
      <div className="site-nudges" aria-label="Nudge building by one block">
        <button onClick={()=>nudge(0,-CELL)}>N</button>
        <button onClick={()=>nudge(-CELL,0)}>W</button>
        <button onClick={()=>nudge(CELL,0)}>E</button>
        <button onClick={()=>nudge(0,CELL)}>S</button>
      </div>
      <Range label="East / west" value={building.x} min={-siteLimit} max={siteLimit} step={1} unit="m" onStart={onCapture} onChange={x=>onUpdate({x})}/>
      <Range label="North / south" value={building.z} min={-siteLimit} max={siteLimit} step={1} unit="m" onStart={onCapture} onChange={z=>onUpdate({z})}/>
      <div className="label-row"><span>Site extent</span><span className="hint">cross streets and combine blocks</span></div>
      <div className="site-grid">{siteOptions.map(site=><button key={site.id} className={Math.abs(building.width-site.width)<4&&Math.abs(building.depth-site.depth)<4?'active':''} onClick={()=>{onCapture();onUpdate({width:site.width,depth:site.depth})}}><i className={site.id}/><b>{site.label}</b><small>{site.sub}</small></button>)}</div>
      <div className="procedural-readout" data-testid="procedural-readout"><div><span>Site</span><b>{blocksX} × {blocksZ} blocks</b></div><div><span>{building.composition==='capsule'?'Generated pods':'Generated tiers'}</span><b>{generatedCount}</b></div><div><span>Density</span><b>{building.moduleDensity} / 5</b></div></div>
      <div className="label-row"><span>Architectural trajectories</span><span className="hint">strong starting propositions</span></div>
      <div className="trajectory-grid">{Object.entries(ARCHITECTURAL_TRAJECTORIES).map(([id,entry])=><button key={id} onClick={()=>{onCapture();onUpdate(entry.patch)}}><i className={id}/><div><b>{entry.label}</b><small>{entry.subtitle}</small><em>{entry.description}</em></div></button>)}</div>
      <div className="label-row"><span>Character grammar</span><span className="hint">mix freely after applying</span></div>
      <div className="language-grid">{(Object.keys(DESIGN_LANGUAGES) as DesignLanguage[]).map(language=>{const entry=DESIGN_LANGUAGES[language];return <button key={language} className={building.language===language?'active':''} onClick={()=>{onCapture();onUpdate(entry.patch)}}><i className={language}/><div><b>{entry.label}</b><small>{entry.subtitle}</small></div></button>})}</div>
      <div className="label-row"><span>Design moves</span><span className="hint">coordinated gestures</span></div>
      <div className="design-moves">
        <button onClick={()=>{onCapture();onUpdate({pilotis:Math.max(5,building.pilotis),porosity:Math.max(48,building.porosity),structural:'frame'})}}><i className="move-ground"/><div><b>Open the ground</b><small>Pilotis · civic threshold</small></div></button>
        <button onClick={()=>{onCapture();onUpdate({composition:'stack',profile:'stepped',terraces:Math.max(4,building.terraces),depth:Math.min(62,building.depth+3),balconies:Math.max(65,building.balconies)})}}><i className="move-step"/><div><b>Step to light</b><small>Terraces · inhabited roofs</small></div></button>
        <button onClick={()=>{onCapture();onUpdate({structural:'frame',facade:'deep-grid',baySpacing:Math.max(4.2,building.baySpacing),porosity:Math.max(55,building.porosity)})}}><i className="move-frame"/><div><b>Expose the frame</b><small>Deep grid · clear load path</small></div></button>
        <button onClick={remix}><i className="move-remix"/><div><b>Recombine form</b><small>New composition · same program</small></div></button>
      </div>
      <div className="label-row"><span>Composition engine</span><span className="hint">the governing spatial rule</span></div>
      <div className="composition-rule" key={building.composition} aria-live="polite"><span>Active rule</span><b>{COMPOSITIONS[building.composition].label}</b><p>{COMPOSITION_EFFECTS[building.composition]}</p></div>
      <div className="gene-grid composition-grid">{(Object.keys(COMPOSITIONS) as Composition[]).map(c=><button key={c} data-testid={`composition-${c}`} aria-pressed={building.composition===c} className={building.composition===c?'active':''} onClick={()=>{if(c!==building.composition){onCapture();onUpdate({composition:c})}}}><i className={c}/><b>{COMPOSITIONS[c].label}</b><small>{COMPOSITIONS[c].subtitle}</small></button>)}</div>
      <div className="label-row"><span>Growth profile</span><span className="hint">how added floors behave</span></div>
      <div className="gene-grid profile-grid">{(Object.keys(PROFILES) as Profile[]).map(p=><button key={p} className={building.profile===p?'active':''} onClick={()=>{onCapture();onUpdate({profile:p})}}><i className={p}/><b>{PROFILES[p].label}</b><small>{PROFILES[p].subtitle}</small></button>)}</div>
      <div className="label-row"><span>Archetype</span><span className="hint">a starting point, never a limit</span></div>
      <div className="typology-grid">{(Object.keys(TYPOLOGIES) as Typology[]).map(t => <button key={t} className={building.typology === t ? 'active' : ''} onClick={() => { const p = TYPOLOGIES[t]; onCapture(); onUpdate({ typology: t, composition:p.composition, profile:p.profile, height: p.height, width: p.width, depth: p.depth, terraces: p.terraces, cantilever: p.cantilever, floorHeight: p.floorHeight, baySpacing: p.baySpacing, structural: p.structural, facade: p.facade, pilotis: p.pilotis, balconies: p.balconies, cores: p.cores, podiumHeight: p.podiumHeight }) }}><i className={`massing-icon ${t}`} /><b>{TYPOLOGIES[t].label.replace('The ', '')}</b><small>{TYPOLOGIES[t].subtitle.split(' / ')[0]}</small></button>)}</div>
      <Range label="Height" value={building.height} min={12} max={160} unit="m" onStart={onCapture} onChange={v => onUpdate({ height: v })} />
      <Range label="Footprint X" value={building.width} min={8} max={128} step={1} unit="m" onStart={onCapture} onChange={v => onUpdate({ width: v })} />
      <Range label="Footprint Y" value={building.depth} min={8} max={96} step={1} unit="m" onStart={onCapture} onChange={v => onUpdate({ depth: v })} />
      <div className="label-row density-label"><span>Module density</span><span className="hint">how much the system generates</span></div>
      <div className="density-strip">{[1,2,3,4,5].map(value=><button key={value} aria-label={`Density ${value}`} className={building.moduleDensity===value?'active':''} onClick={()=>{onCapture();onUpdate({moduleDensity:value})}}><b>{value}</b><small>{['sparse','measured','rich','dense','maximal'][value-1]}</small></button>)}</div>
      <Range label="Break apart" value={building.articulation} min={0} max={100} step={.5} unit="%" disabledReason={controlDisabledReason(building,'articulation')} onStart={onCapture} onChange={articulation=>onUpdate({articulation})}/>
      <Range label="Lateral branches" value={building.branches} min={0} max={8} disabledReason={controlDisabledReason(building,'branches')} onStart={onCapture} onChange={branches=>onUpdate({branches})}/>
      <Range label="Crown intensity" value={building.crown} min={0} max={100} step={.5} unit="%" disabledReason={controlDisabledReason(building,'crown')} onStart={onCapture} onChange={crown=>onUpdate({crown})}/>
      <Range label="Floor-to-floor" value={building.floorHeight} min={2.8} max={5.4} step={.05} unit="m" onStart={onCapture} onChange={v => onUpdate({ floorHeight: v })} />
      <Range label="Structural bay" value={building.baySpacing} min={2.7} max={7.5} step={.1} unit="m" disabledReason={controlDisabledReason(building,'baySpacing')} contextNote={controlContextNote(building,'baySpacing')} onStart={onCapture} onChange={v => onUpdate({ baySpacing: v })} />
      <Range label="Terrace cuts" value={building.terraces} min={1} max={7} disabledReason={controlDisabledReason(building,'terraces')} onStart={onCapture} onChange={v => onUpdate({ terraces: v })} />
      <Range label="Cantilever" value={building.cantilever} min={0} max={14} step={.2} unit="m" disabledReason={controlDisabledReason(building,'cantilever')} onStart={onCapture} onChange={v => onUpdate({ cantilever: v })} />
      <Range label="Carved void" value={building.voids} min={0} max={70} step={.5} unit="%" disabledReason={controlDisabledReason(building,'voids')} onStart={onCapture} onChange={v=>onUpdate({voids:v})}/>
      <Range label="Vertical taper" value={building.taper} min={0} max={65} step={.5} unit="%" disabledReason={controlDisabledReason(building,'taper')} onStart={onCapture} onChange={v=>onUpdate({taper:v})}/>
      <Range label="Pilotis / undercroft" value={building.pilotis} min={0} max={9} step={.2} unit="m" onStart={onCapture} onChange={v => onUpdate({ pilotis: v })} />
      <Range label="Exposed balconies" value={building.balconies} min={0} max={100} unit="%" disabledReason={controlDisabledReason(building,'balconies')} onStart={onCapture} onChange={v => onUpdate({ balconies: v })} />
      <div className="label-row"><span>Structural logic</span><span className="hint">load path</span></div>
      <div className="option-strip">{(['frame','walls','cores'] as StructuralSystem[]).map(s => <button key={s} className={building.structural === s ? 'active' : ''} onClick={() => { onCapture(); onUpdate({ structural: s }) }}>{s}</button>)}</div>
      <Range label="Orientation" value={building.rotation} min={0} max={315} step={45} unit="°" onStart={onCapture} onChange={v => onUpdate({ rotation: v })} />
    </div>}
    {section === 'skin' && <div className="control-stack">
      <div className="label-row"><span>Concrete finish</span><span className="hint">material palette</span></div>
      <div className="swatches">{(Object.keys(TONES) as Tone[]).map(t => <button title={TONES[t].label} aria-label={TONES[t].label} key={t} className={building.tone === t ? 'active' : ''} style={{ '--swatch': TONES[t].color } as React.CSSProperties} onClick={() => { onCapture(); onUpdate({ tone: t }) }} />)}</div>
      <div className="label-row"><span>Facade system</span><span className="hint">depth & shadow</span></div>
      <div className="option-strip facade-options">{(['ribbon','deep-grid','brise-soleil','punched','exoskeleton','screen'] as FacadeStrategy[]).map(s => <button key={s} className={building.facade === s ? 'active' : ''} onClick={() => { onCapture(); onUpdate({ facade: s }) }}>{s}</button>)}</div>
      <Range label="Facade rhythm" value={building.rhythm} min={2} max={8} disabledReason={controlDisabledReason(building,'rhythm')} onStart={onCapture} onChange={v => onUpdate({ rhythm: v })} />
      <Range label="Glazing ratio" value={building.porosity} min={15} max={80} unit="%" contextNote={controlContextNote(building,'porosity')} onStart={onCapture} onChange={v => onUpdate({ porosity: v })} />
      <Range label="Facade depth" value={building.facadeDepth} min={.2} max={4.5} step={.1} unit="m" disabledReason={controlDisabledReason(building,'facadeDepth')} onStart={onCapture} onChange={v=>onUpdate({facadeDepth:v})}/>
      <Range label="Weathering" value={building.weathering} min={0} max={100} unit="%" onStart={onCapture} onChange={v=>onUpdate({weathering:v})}/>
      <Range label="Vegetation" value={building.vegetation} min={0} max={100} unit="%" disabledReason={controlDisabledReason(building,'vegetation')} onStart={onCapture} onChange={v=>onUpdate({vegetation:v})}/>
      <div className="material-note"><Sparkles size={16} /><p><b>Board-mark direction</b><br />Horizontal lifts emphasize the building as a constructed geological mass.</p></div>
      <div className="performance-row"><div><span>Daylight</span><b>{Math.max(18,Math.round(96 - building.depth * 1.8 + building.porosity * .15))}%</b></div><div><span>Heat load</span><b>{Math.round(18 + building.porosity * .55)}%</b></div></div>
    </div>}
    {section === 'use' && <div className="control-stack">
      <div className="label-row"><span>Occupancy model</span><span className="hint">secondary to architecture</span></div>
      <div className="program-list">{(Object.keys(PROGRAMS) as Program[]).map(p => <button key={p} className={building.program === p ? 'active' : ''} style={{ '--program': PROGRAMS[p].color } as React.CSSProperties} onClick={() => { onCapture(); onUpdate({ program: p }) }}><span className="program-dot" /><div><b>{PROGRAMS[p].label}</b><small>{PROGRAMS[p].description}</small></div></button>)}</div>
      <div className="performance-row"><div><span>Gross floor area</span><b>{fmt(building.width * building.depth * Math.floor((building.height-building.pilotis)/building.floorHeight))}m²</b></div><div><span>Public life</span><b>{performance.publicLife}/100</b></div></div>
    </div>}
    {section === 'analysis' && <div className="control-stack analysis-stack">
      <div className="analysis-hero"><div><span>Building performance</span><b>{Math.round((performance.daylight + performance.egress + performance.publicLife) / 3)}</b><small>integrated score / 100</small></div><i style={{ '--score': `${Math.round((performance.daylight + performance.egress + performance.publicLife) / 3)}%` } as React.CSSProperties} /></div>
      <div className="analysis-grid">
        <div><span>Gross floor area</span><b>{fmt(performance.gfa)} m²</b><small>FAR {performance.far.toFixed(1)}</small></div>
        <div><span>Embodied carbon</span><b>{fmt(performance.carbon)} t</b><small>{Math.round(performance.carbon/performance.gfa*1000)} kg/m²</small></div>
        <div><span>Useful daylight</span><b>{performance.daylight}%</b><small>{performance.shadeHours}h shade / day</small></div>
        <div><span>Energy demand</span><b>{performance.energy}</b><small>kWh/m²·yr</small></div>
      </div>
      <div className="label-row"><span>Design checks</span><span className="hint">live model</span></div>
      {[['Daylight autonomy',performance.daylight],['Egress resilience',performance.egress],['Public interface',performance.publicLife],['Program diversity',Math.min(100,performance.diversity*25)]].map(([label,value])=><div className="analysis-bar" key={label as string}><span>{label}</span><i><b style={{width:`${value}%`}} /></i><em>{value}</em></div>)}
      <div className={`design-advice ${performance.egress<70?'warning':''}`}><b>{performance.egress<70?'Egress pressure':'Spatial reading'}</b><p>{performance.egress<70?'Height and occupancy exceed the current core strategy. Add a core or reduce the floor plate.':performance.daylight<55?'Deep floor plates are limiting useful daylight. Narrow the section or increase facade porosity.':'The structure has a legible load path, viable daylight, and an active relationship to the district.'}</p></div>
    </div>}
    <div className="inspector-actions"><button onClick={onDuplicate}><Plus size={15} /> Grow sibling</button><button className="danger" onClick={onDemolish}><Trash2 size={15} /> Remove</button></div>
  </aside>
}

function PublicRealmInspector({plaza,onUpdate,onCapture,onClose,onRemove}:{plaza:Plaza;onUpdate:(patch:Partial<Plaza>)=>void;onCapture:()=>void;onClose:()=>void;onRemove:()=>void}){
  const titles={water:'Reflecting court',garden:'Canopy garden',forum:'Civic forum'}
  const kind=plaza.kind??'garden'
  const shade=Math.min(96,18+plaza.trees*7+(kind==='garden'?20:0))
  const water=kind==='water'?94:kind==='garden'?72:38
  const social=kind==='forum'?96:kind==='garden'?78:68
  return <aside className="inspector panel realm-inspector" data-testid="public-realm-inspector">
    <div className="inspector-head"><div><span className="eyebrow">Selected public realm</span><div className="realm-title">{titles[kind]}</div></div><button className="icon-btn" onClick={onClose} aria-label="Close public realm inspector"><X size={18}/></button></div>
    <div className="inspector-meta"><ProgramBadge program="civic"/><span>{plaza.trees} canopy trees</span><span>{Math.round((CELL-5)*(CELL-5))} m²</span></div>
    <div className="control-stack">
      <div className="label-row"><span>Civic landscape</span><span className="hint">spatial character</span></div>
      <div className="realm-kinds">{(['garden','water','forum'] as const).map(k=><button key={k} className={kind===k?'active':''} onClick={()=>{onCapture();onUpdate({kind:k})}}><i className={k}/><div><b>{titles[k]}</b><small>{k==='garden'?'shade · ecology':k==='water'?'reflection · cooling':'assembly · performance'}</small></div></button>)}</div>
      <Range label="Canopy density" value={plaza.trees} min={0} max={14} onStart={onCapture} onChange={v=>onUpdate({trees:v})}/>
      <div className="label-row realm-performance-label"><span>Public performance</span><span className="hint">live model</span></div>
      {[['Summer shade',shade],['Stormwater capture',water],['Social intensity',social]].map(([label,value])=><div className="analysis-bar" key={label as string}><span>{label}</span><i><b style={{width:`${value}%`}}/></i><em>{value}</em></div>)}
      <div className="design-advice"><b>{kind==='water'?'A civic horizon':kind==='garden'?'A room of trees':'An open institution'}</b><p>{kind==='water'?'A shallow rill cools the hard landscape, reflects the concrete frame, and creates a slow ceremonial threshold.':kind==='garden'?'Dense canopy turns the superblock into an inhabited microclimate with shade, habitat, and informal rooms.':'Terraced ground gives assembly a visible form without prescribing what citizens gather to do.'}</p></div>
    </div>
    <div className="inspector-actions"><button onClick={()=>{onCapture();onUpdate({trees:Math.min(14,plaza.trees+3)})}}><Leaf size={15}/> Intensify</button><button className="danger" onClick={onRemove}><Trash2 size={15}/> Remove</button></div>
  </aside>
}

function TemplatePlan({template}:{template:CityTemplate}){
  const preview=useMemo(()=>template.create(`plan-${template.id}`),[template])
  return <CityMiniMap snapshot={preview}/>
}

function Welcome({selectedTemplate,onSelect,onStart,saves,onOpenSave,onOpenLibrary}:{selectedTemplate:CityTemplate;onSelect:(id:CityTemplate['id'])=>void;onStart:(template:CityTemplate)=>void;saves:CitySaveRecord[];onOpenSave:(save:CitySaveRecord)=>void;onOpenLibrary:()=>void}) {
  return <div className="modal-scrim welcome" role="dialog" aria-modal="true" aria-labelledby="welcome-title" style={{'--template-accent':selectedTemplate.accent} as React.CSSProperties}>
    <div className="welcome-stage" aria-hidden="true"><div className="title-lockup"><span>Form · light · life</span><b>MONUMENT</b><em>BRUTALIST CITY PLAYGROUND</em></div><div className="preview-readout"><span>Live city preview</span><b>{selectedTemplate.name}</b><p>{selectedTemplate.description}</p><div><i>SHAPE</i><i>INHABIT</i><i>WANDER</i></div></div></div>
    <section className="welcome-card"><div className="welcome-copy"><span className="eyebrow">A brutalist city playground</span><h1 id="welcome-title">Shape buildings.<br /><i>Grow a city.</i></h1><p>Pull, repeat, branch, and carve each structure. Then guide its use, atmosphere, public spaces, and the life that gathers around it.</p><div className="cover-promises"><span><b>01</b> Shape freely</span><span><b>02</b> Watch it live</span><span><b>03</b> Guide growth</span></div>
      <div className="approach template-approach"><span>Start a city</span>{CITY_TEMPLATES.map(template=><button key={template.id} className={selectedTemplate.id===template.id?'active':''} onClick={()=>onSelect(template.id)} style={{'--template-accent':template.accent} as React.CSSProperties}><TemplatePlan template={template}/><div><b>{template.name}</b><small>{template.label} · {template.description}</small></div></button>)}</div>
      {saves.length>0&&<div className="welcome-saves"><span>Continue a city</span>{saves.slice(0,2).map(save=><button key={save.id} onClick={()=>onOpenSave(save)}><b>{save.name}</b><small>Day {save.snapshot.day} · {save.snapshot.buildings.length} structures</small><em>Open →</em></button>)}<button className="all-cities" onClick={onOpenLibrary}><b>City library</b><small>{saves.length} saved on this device</small><em>View all →</em></button></div>}
      <button className="primary start" data-testid="start-city" onClick={()=>onStart(selectedTemplate)}>Open {selectedTemplate.name} <span>→</span></button><small className="welcome-tip">Cities are saved on this device and can be reopened from the library.</small>
    </div></section>
  </div>
}

function CityMiniMap({snapshot}:{snapshot:GameSnapshot}){
  return <svg className="city-minimap" viewBox="-190 -190 380 380" aria-hidden="true"><rect x="-190" y="-190" width="380" height="380" fill="#bdb6a5"/>{snapshot.plazas.map(plaza=><rect key={plaza.id} x={plaza.x-11} y={plaza.z-11} width="22" height="22" fill={plaza.kind==='water'?'#709aa3':plaza.kind==='forum'?'#a96b50':'#637b58'} opacity=".82"/>)}{snapshot.buildings.slice(0,80).map(building=><rect key={building.id} x={building.x-building.width/2} y={building.z-building.depth/2} width={building.width} height={building.depth} fill={PROGRAMS[building.program].color} stroke="#222720" strokeWidth="1.4" transform={`rotate(${building.rotation} ${building.x} ${building.z})`}/>)}</svg>
}

function CityLibraryModal({currentName,saves,onNameChange,onSave,onOpen,onDelete,onTemplate,onClose}:{currentName:string;saves:CitySaveRecord[];onNameChange:(name:string)=>void;onSave:()=>void;onOpen:(save:CitySaveRecord)=>void;onDelete:(id:string)=>void;onTemplate:(template:CityTemplate)=>void;onClose:()=>void}){
  const [deleteId,setDeleteId]=useState<string|null>(null)
  return <div className="modal-scrim city-library-scrim"><section className="city-library" role="dialog" aria-modal="true" aria-labelledby="city-library-title">
    <header><div><span className="eyebrow">Saved on this device</span><h2 id="city-library-title">City library</h2></div><button className="icon-btn" aria-label="Close city library" onClick={onClose}><X/></button></header>
    <div className="library-current"><div><span>Current city</span><input aria-label="Current city name" value={currentName} maxLength={40} onChange={event=>onNameChange(event.target.value)}/></div><button onClick={onSave}><Save/> Save current</button></div>
    <div className="library-scroll">
      <section><div className="label-row"><span>Start a city</span><span className="hint">your current city saves before switching</span></div><div className="library-grid template-grid">{CITY_TEMPLATES.map(template=><button className="template-card" key={template.id} onClick={()=>onTemplate(template)} style={{'--template-accent':template.accent} as React.CSSProperties}><TemplatePlan template={template}/><i/><span>{template.label}</span><b>{template.name}</b><small>{template.description}</small><em>Open city →</em></button>)}</div></section>
      <section><div className="label-row"><span>My cities</span><span className="hint">{saves.length} saved on this device</span></div>{saves.length===0?<p className="empty-library">Your saved cities will appear here.</p>:<div className="library-grid">{saves.map(save=>{const summary=snapshotSummary(save.snapshot);return <article className="save-card" key={save.id}><CityMiniMap snapshot={save.snapshot}/><div><span>{new Date(save.updatedAt).toLocaleDateString()}</span><b>{save.name}</b><small>Day {summary.day} · {summary.structures} structures · {summary.plazas} spaces · {summary.mood}</small></div><footer><button onClick={()=>onOpen(save)}>Open</button><button className={deleteId===save.id?'confirm-delete':''} aria-label={`${deleteId===save.id?'Confirm delete':'Delete'} ${save.name}`} onClick={()=>{if(deleteId===save.id){onDelete(save.id);setDeleteId(null)}else setDeleteId(save.id)}}>{deleteId===save.id?'Confirm':'Delete'}</button></footer></article>})}</div>}
      </section>
    </div>
  </section></div>
}

function FocusDock({day,hour,paused,onExit,onPause,onHour,onCamera,onSave}:{day:number;hour:number;paused:boolean;onExit:()=>void;onPause:()=>void;onHour:(hour:number)=>void;onCamera:()=>void;onSave:()=>void}){
  return <div className="focus-dock panel" aria-label="Focus controls"><button className="focus-exit" onClick={onExit} title="Return to editing" aria-label="Exit focus mode"><MousePointer2/><span>Edit</span></button><button onClick={onPause} title={paused?'Play city':'Pause city'} aria-label={paused?'Play city':'Pause city'}>{paused?<Play/>:<Pause/>}</button><div><span>Day {day}</span><b>{String(Math.floor(hour)).padStart(2,'0')}:{hour%1>=.5?'30':'00'}</b></div><input aria-label="Time of day" type="range" min={0} max={23.75} step={.25} value={hour} onChange={event=>onHour(Number(event.target.value))}/><button onClick={onCamera} title="Next camera" aria-label="Cycle camera"><Camera/></button><button onClick={onSave} title="Save city" aria-label="Save city"><Save/></button></div>
}

function HelpModal({ onClose }: { onClose: () => void }) {
  return <div className="modal-scrim"><div className="help-card" role="dialog" aria-modal="true" aria-labelledby="help-title"><button className="icon-btn close" onClick={onClose} aria-label="Close field manual"><X /></button><span className="eyebrow">Field manual</span><h2 id="help-title">Design with intent.</h2><div className="help-grid"><div><MousePointer2 /><b>Shape the city</b><p>Choose a program and click an empty parcel. Select any building to tune its form, envelope, and use.</p></div><div><BarChart3 /><b>Read the design</b><p>Use lenses to see structure, program, daylight, activity, and embodied carbon.</p></div><div><Clock3 /><b>Let it live</b><p>Play time to watch rooms light up, streets fill, and concrete weather through the day.</p></div><div><Camera /><b>Experience space</b><p>Move between orbit, aerial plan, and street-level views. Light changes across the day.</p></div></div><div className="shortcut-row"><kbd>1—6</kbd> build <kbd>V</kbd> select <kbd>X</kbd> demolish <kbd>Space</kbd> pause <kbd>F</kbd> focus <kbd>?</kbd> help</div></div></div>
}

function GraphicsSettingsPanel({settings,effectiveQuality,focusMode,onChange,onFocusChange,onClose}:{settings:GraphicsSettings;effectiveQuality:Exclude<GraphicsQuality,'auto'>;focusMode:boolean;onChange:(patch:Partial<GraphicsSettings>)=>void;onFocusChange:(active:boolean)=>void;onClose:()=>void}){
  const qualityOptions:Array<[GraphicsQuality,string,string]>=[
    ['auto','Auto','Starts light · adds detail when steady'],['low','Performance','Fewer lights · lighter shadows'],['balanced','Balanced','Full city detail'],['high','High','Maximum detail and shadows'],
  ]
  return <aside id="display-settings" className="settings-panel panel" role="dialog" aria-modal="false" aria-labelledby="display-settings-title" data-testid="display-settings">
    <div className="settings-head"><div><span className="eyebrow">Renderer</span><h2 id="display-settings-title">Display settings</h2></div><button className="icon-btn" aria-label="Close display settings" onClick={onClose}><X/></button></div>
    <fieldset><legend>Graphics quality</legend><div className="settings-options">{qualityOptions.map(([id,label,copy])=><label key={id} className={settings.quality===id?'active':''}><input type="radio" name="graphics-quality" value={id} checked={settings.quality===id} onChange={()=>onChange({quality:id})}/><i/><span><b>{label}{id==='auto'&&<em>Recommended</em>}</b><small>{copy}</small></span></label>)}</div>{(settings.quality==='auto'||settings.quality!==effectiveQuality)&&<p className="effective-quality">Effective quality <b>{effectiveQuality}</b></p>}</fieldset>
    <fieldset><legend>Edge smoothing</legend><div className="settings-options compact">{[[false,'Off','Sharpest performance'],[true,'SMAA','Smooths rails and silhouettes']].map(([enabled,label,copy])=><label key={label as string} className={settings.edgeSmoothing===enabled?'active':''}><input type="radio" name="edge-smoothing" checked={settings.edgeSmoothing===enabled} onChange={()=>onChange({edgeSmoothing:enabled as boolean})}/><i/><span><b>{label as string}</b><small>{copy as string}</small></span></label>)}</div></fieldset>
    <fieldset><legend>Interface</legend><label className="settings-switch"><input type="checkbox" checked={focusMode} onChange={event=>onFocusChange(event.target.checked)}/><i><span/></i><span><b>Focus mode</b><small>Hide editing chrome and experience the city. Press F to toggle.</small></span></label></fieldset>
    <p className="settings-note">Auto adds detail after the scene is steady. High increases pixel density; dense night moods use a stable lighting profile.</p>
  </aside>
}

function EventModal({event,onChoose}:{event:CityEvent;onChoose:(choice:EventChoice)=>void}){
  const titleId=`event-${event.id}-title`,copyId=`event-${event.id}-copy`
  return <div className="event-scrim"><div className="event-card" role="dialog" aria-modal="true" aria-labelledby={titleId} aria-describedby={copyId}><div className="event-index"><span>CITY<br/>CHOICE</span><b>{String(event.sketch).padStart(2,'0')}</b><em>SKETCH</em></div><div className="event-content"><span className="eyebrow">{event.kicker}</span><h2 id={titleId}>{event.title}</h2><p id={copyId}>{event.copy}</p><div className="event-choices">{event.choices.map((choice,i)=><button key={choice.label} autoFocus={i===0} onClick={()=>onChoose(choice)}><i>0{i+1}</i><div><b>{choice.label}</b><small>{choice.detail}</small><span className="impact-chips">{choice.impacts.map(impact=><em key={impact}>{impact}</em>)}</span></div><span>→</span></button>)}</div></div></div></div>
}

function SystemsPanel({ metrics, charter, decisions, onClose }: { metrics: CityMetrics; charter:DistrictCharter;decisions:DecisionRecord[];onClose: () => void }) {
  const charterRows:Array<{id:keyof DistrictCharter;title:string;pending:string;labels:Record<string,[string,string]>}>=[
    {id:'undercroft',title:'Life at ground level',pending:'Complete growth sketch 01',labels:{open:['Open after dark','night markets · +11 activity'],quiet:['Quiet courtyards','garden rooms · +3 approval']}},
    {id:'commons',title:'Shared life',pending:'Complete growth sketch 02',labels:{shared:['Common rooms','shared bands · +7 approval'],specialist:['Specialist places','workshops · +8% jobs and culture']}},
    {id:'aggregate',title:'Material language',pending:'Complete growth sketch 03',labels:{reuse:['Build from remains','reclaimed panels · −18% carbon'],formal:['Formal concrete','clean joints · +6% carbon']}},
  ]
  const bars = [
    ['Housing', Math.min(100, metrics.population / Math.max(1, metrics.capacity) * 100), '#e96b50'],
    ['Employment', Math.min(100, metrics.jobs / Math.max(1, metrics.population) * 100), '#7aa4e8'],
    ['Civic care', Math.min(100, metrics.civic / 4), '#d7ff43'],
    ['Culture', Math.min(100, metrics.culture / 4), '#bc86de'],
  ] as const
  return <aside className="systems-panel panel" data-testid="systems-panel">
    <div className="systems-head"><div><span className="eyebrow">City life</span><h2>How this city is growing</h2></div><button className="icon-btn" onClick={onClose} aria-label="Close city life panel"><X /></button></div>
    <div className="systems-score"><div><span>Public life index</span><b>{metrics.activity}</b><i style={{ '--score': `${metrics.activity}%` } as React.CSSProperties} /></div><div><span>Approval</span><b>{metrics.approval}%</b><small>{metrics.approval >= 72 ? 'thriving' : 'needs care'}</small></div></div>
    <section className="systems-section"><div className="label-row"><span>Program balance</span><span className="hint">live capacity</span></div>{bars.map(([label,value,color]) => <div className="system-bar" key={label}><span>{label}</span><i><b style={{ width: `${value}%`, background: color }} /></i><em>{Math.round(value)}%</em></div>)}</section>
    <section className="systems-section"><div className="label-row"><span>Growth principles</span><span className="hint">what the city becomes</span></div><div className="charter-list">{charterRows.map(row=>{const value=charter[row.id],record=decisions.find(d=>d.eventId===row.id),resolved=value?row.labels[value]:null;return <div key={row.id} className={resolved?'resolved':'pending'}><i>{resolved?'◆':'○'}</i><div><span>{row.title}</span><b>{resolved?.[0]??'Still emerging'}</b><small>{resolved?.[1]??row.pending}</small></div>{record&&<em>DAY {record.day}</em>}</div>})}</div></section>
    <section className="systems-section footprint"><Leaf /><div><span>Embodied carbon</span><b>{fmt(metrics.carbon)} tCO₂e</b><small>{charter.aggregate==='reuse'?'Reclaimed frames and panels are reducing new material demand.':charter.aggregate==='formal'?'Formal concrete standards trade additional carbon for slower weathering.':'A material choice unlocks with growth sketch 03.'}</small></div></section>
  </aside>
}

export default function App() {
  const [buildings, setBuildings] = useState<Building[]>(initialBuildings)
  const [plazas, setPlazas] = useState<Plaza[]>([{ id: 'p-1', x: -CELL, z: CELL, trees: 7, kind:'garden' }, { id: 'p-2', x: CELL, z: -CELL, trees: 4, kind:'water' }, { id: 'p-3', x: 0, z: CELL*2, trees: 6, kind:'water' }])
  const [day, setDay] = useState(1)
  const [hour, setHour] = useState(16.5)
  const [paused, setPaused] = useState(true)
  const [speed, setSpeed] = useState(1)
  const [tool, setTool] = useState<Tool>('select')
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [viewMode, setViewMode] = useState<ViewMode>('material')
  const [cameraMode, setCameraMode] = useState<CameraMode>('orbit')
  const [mood, setMood] = useState<DistrictMood>('default')
  const [cameraRevision,setCameraRevision]=useState(0)
  const [welcome, setWelcome] = useState(true)
  const [menuTemplateId,setMenuTemplateId]=useState<CityTemplate['id']>('civic-basin')
  const [help, setHelp] = useState(false)
  const [objectivesOpen, setObjectivesOpen] = useState(()=>typeof window==='undefined'||!window.matchMedia(COMPACT_EDITOR_MEDIA).matches)
  const [toast, setToast] = useState('')
  const [focusMode,setFocusMode]=useState(false)
  const [libraryOpen,setLibraryOpen]=useState(false)
  const [savedCities,setSavedCities]=useState<CitySaveRecord[]>(readCityLibrary)
  const [currentCityId,setCurrentCityId]=useState<string|null>(null)
  const [currentCityName,setCurrentCityName]=useState('Concrete Commons')
  const [mobileTools, setMobileTools] = useState(false)
  const [compactEditor,setCompactEditor]=useState(()=>typeof window!=='undefined'&&window.matchMedia(COMPACT_EDITOR_MEDIA).matches)
  const [selectionPanelOpen,setSelectionPanelOpen]=useState(false)
  const [systemsOpen, setSystemsOpen] = useState(false)
  const [settingsOpen,setSettingsOpen]=useState(false)
  const [graphics,setGraphics]=useState<GraphicsSettings>(readGraphics)
  const [effectiveQuality,setEffectiveQuality]=useState<Exclude<GraphicsQuality,'auto'>>('balanced')
  const [briefStage, setBriefStage] = useState(0)
  const [charter,setCharter]=useState<DistrictCharter>({})
  const [decisions,setDecisions]=useState<DecisionRecord[]>([])
  const [activeEvent,setActiveEvent]=useState<CityEvent|null>(null)
  const history = useRef<GameSnapshot[]>([])
  const future = useRef<GameSnapshot[]>([])
  const completedStage = useRef(-1)
  const pausedBeforeChoice = useRef(true)
  const timer = useRef<number | null>(null)

  const snapshot = useCallback((): GameSnapshot => ({ buildings: structuredClone(buildings), plazas: structuredClone(plazas), day, briefStage, mood, hour, charter:structuredClone(charter), decisions:structuredClone(decisions) }), [buildings, plazas, day, briefStage, mood, hour, charter, decisions])
  const capture = useCallback(() => { history.current.push(snapshot()); if (history.current.length > 60) history.current.shift(); future.current = [] }, [snapshot])
  const notify = useCallback((message: string) => { setToast(message); if (timer.current) clearTimeout(timer.current); timer.current = window.setTimeout(() => setToast(''), 2600) }, [])
  useEffect(()=>{try{localStorage.setItem(GRAPHICS_KEY,JSON.stringify(graphics))}catch{/* graphics preferences remain available for this session */}},[graphics])
  useEffect(()=>{
    const media=window.matchMedia(COMPACT_EDITOR_MEDIA)
    const update=()=>setCompactEditor(media.matches)
    update()
    if(media.addEventListener){media.addEventListener('change',update);return()=>media.removeEventListener('change',update)}
    media.addListener(update);return()=>media.removeListener(update)
  },[])
  const metrics = useMemo(() => {
    const m = metricsFor(buildings, plazas)
    m.population = Math.min(m.capacity, Math.round(m.population * 1.06));m.approval+=2
    if(charter.undercroft==='open')m.activity=Math.min(100,m.activity+11)
    if(charter.undercroft==='quiet')m.approval=Math.min(98,m.approval+3)
    if(charter.commons==='shared'){m.approval=Math.min(98,m.approval+7);m.activity=Math.min(100,m.activity+4)}
    if(charter.commons==='specialist'){m.jobs=Math.round(m.jobs*1.08);m.culture=Math.round(m.culture*1.08);m.activity=Math.min(100,m.activity+3)}
    if(charter.aggregate==='reuse')m.carbon=Math.round(m.carbon*.82)
    if(charter.aggregate==='formal')m.carbon=Math.round(m.carbon*1.06)
    return m
  }, [buildings, plazas, charter])
  const citySignals=useMemo<CitySignals>(()=>({activity:metrics.activity,nightAccess:charter.undercroft??'neutral',sharedRooms:charter.commons==='shared',specialistGrowth:charter.commons==='specialist',reuse:charter.aggregate==='reuse',formal:charter.aggregate==='formal'}),[metrics.activity,charter])
  const menuTemplate=CITY_TEMPLATES.find(template=>template.id===menuTemplateId)??CITY_TEMPLATES[1]
  const menuPreview=useMemo(()=>menuTemplate.create(`menu-${menuTemplate.id}`),[menuTemplate])
  const menuCharter=menuPreview.charter??{}
  const menuSignals=useMemo<CitySignals>(()=>({activity:72,nightAccess:menuCharter.undercroft??'neutral',sharedRooms:menuCharter.commons==='shared',specialistGrowth:menuCharter.commons==='specialist',reuse:menuCharter.aggregate==='reuse',formal:menuCharter.aggregate==='formal'}),[menuCharter])
  const selected = buildings.find(b => b.id === selectedId)
  const selectedPlaza=plazas.find(p=>p.id===selectedId)
  const selectedPerformance = selected ? performanceFor(selected, buildings, plazas) : null

  useEffect(() => {
    if (paused) return
    const id = window.setInterval(() => {
      setHour(h => {
        const next = h + .25 * speed
        if (next >= 24) {
          setDay(d => d + 1)
          const wear=charter.aggregate==='formal'?.012:.03
          setBuildings(bs => bs.map(b => ({ ...b, age: (b.age??0) + .08, condition: Math.max(72, (b.condition??94) - wear) })))
        }
        return next % 24
      })
    }, SIM_TICK_MS)
    return () => clearInterval(id)
  }, [paused, speed, charter.aggregate])

  useEffect(()=>{
    const next=CITY_EVENTS.find(event=>briefStage>=event.sketch&&!charter[event.id])
    if(next&&!activeEvent){pausedBeforeChoice.current=paused;setPaused(true);setActiveEvent(next)}
  },[briefStage,charter,activeEvent,paused])

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.target as HTMLElement).tagName === 'INPUT'&&e.key!=='Escape') return
      if(activeEvent||welcome)return
      if(e.key==='Escape'){
        if(libraryOpen)setLibraryOpen(false)
        else if(compactEditor&&selectionPanelOpen)setSelectionPanelOpen(false)
        else if(compactEditor&&selectedId){setSelectedId(null);setSelectionPanelOpen(false)}
        else if(focusMode)setFocusMode(false)
        else{setSettingsOpen(false);setHelp(false)}
        return
      }
      if(help||settingsOpen||libraryOpen)return
      if(e.key.toLowerCase()==='f'){setFocusMode(active=>{notify(active?'Focus mode off':'Focus mode on · press Escape to exit');return !active});setSystemsOpen(false);setSettingsOpen(false);return}
      if (e.key === ' ') { e.preventDefault(); setPaused(p => !p) }
      if(focusMode)return
      const map: Record<string, Tool> = { v: 'select', '1': 'housing', '2': 'work', '3': 'civic', '4': 'culture', '5': 'mixed', '6': 'plaza', x: 'demolish' }
      if (map[e.key.toLowerCase()]) setTool(map[e.key.toLowerCase()])
      if (e.key === '?') setHelp(h => !h)
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'z') { e.preventDefault(); undo() }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  },[activeEvent,welcome,help,settingsOpen,libraryOpen,focusMode,notify,compactEditor,selectionPanelOpen,selectedId])

  const restore = (s: GameSnapshot, preserveSelection = false) => {
    setBuildings(s.buildings.map(b=>{const preset=TYPOLOGIES[b.typology]??TYPOLOGIES.slab;return Object.assign({condition:94,age:0,floorHeight:preset.floorHeight,baySpacing:preset.baySpacing,structural:preset.structural,facade:preset.facade,pilotis:preset.pilotis,balconies:preset.balconies,cores:preset.cores,podiumHeight:preset.podiumHeight,language:'civic' as DesignLanguage,voids:28,taper:12,facadeDepth:1,weathering:24,vegetation:34,composition:preset.composition,profile:preset.profile,moduleDensity:3,articulation:34,branches:1,crown:24},b)}))
    const legacy=(s.charter??{}) as {undercroft?:'open'|'quiet'|'secure';commons?:'shared'|'specialist'|'delivery';aggregate?:'reuse'|'formal'}
    const restoredCharter:DistrictCharter={...legacy,undercroft:legacy?.undercroft==='secure'?'quiet':legacy?.undercroft,commons:legacy?.commons==='delivery'?'specialist':legacy?.commons}
    setPlazas(s.plazas);setDay(s.day);setHour(s.hour??16.5);setBriefStage(s.briefStage ?? 0);setMood(normalizeMood(s.mood));setCharter(restoredCharter);setDecisions(s.decisions??[]);setActiveEvent(null);completedStage.current=-1
    if (!preserveSelection || !selectedId || ![...s.buildings, ...s.plazas].some(item => item.id === selectedId)) setSelectedId(null)
  }
  const undo = () => { const s = history.current.pop(); if (!s) return; future.current.push(snapshot()); restore(s, true); notify('Last move undone') }
  const redo = () => { const s = future.current.pop(); if (!s) return; history.current.push(snapshot()); restore(s, true); notify('Move restored') }
  const saveCurrent=(silent=false)=>{
    const now=Date.now(),id=currentCityId??`city-${now}`,name=currentCityName.trim()||`City ${savedCities.length+1}`
    const existing=savedCities.find(record=>record.id===id)
    const record:CitySaveRecord={id,name,createdAt:existing?.createdAt??now,updatedAt:now,snapshot:snapshot()}
    const nextRecords=[record,...savedCities.filter(item=>item.id!==id)].slice(0,30)
    if(!writeCityLibrary(nextRecords)){notify(`Could not save ${name} · browser storage is unavailable or full`);return null}
    setSavedCities(nextRecords);setCurrentCityId(id);setCurrentCityName(name)
    if(!silent)notify(`${name} saved to the city library`)
    return record
  }
  const resetCitySession=()=>{
    setPaused(true);setSpeed(1);setTool('select');setSelectedId(null);setSelectionPanelOpen(false);setViewMode('material');setCameraMode('orbit');setCameraRevision(value=>value+1);setSystemsOpen(false);setSettingsOpen(false);setLibraryOpen(false);setFocusMode(false);history.current=[];future.current=[];completedStage.current=-1
  }
  const beginTemplate=(template:CityTemplate)=>{
    const returning=!welcome
    if(returning&&!saveCurrent(true))return
    const next=template.create(`city-${Date.now()}`)
    restore(next);setCurrentCityId(null);setCurrentCityName(template.name);setWelcome(false);resetCitySession();notify(`${template.name} opened`)
  }
  const openSavedCity=(record:CitySaveRecord)=>{
    if(!welcome&&record.id===currentCityId){if(saveCurrent(true)){setLibraryOpen(false);notify(`${record.name} is already open and has been saved`)}return}
    if(!welcome&&!saveCurrent(true))return
    restore(structuredClone(record.snapshot));setCurrentCityId(record.id);setCurrentCityName(record.name);setWelcome(false);resetCitySession();notify(`${record.name} opened`)
  }
  const deleteSavedCity=(id:string)=>{
    const nextRecords=savedCities.filter(record=>record.id!==id)
    if(!writeCityLibrary(nextRecords)){notify('Could not remove that city · browser storage is unavailable');return}
    setSavedCities(nextRecords)
    if(currentCityId===id)setCurrentCityId(null)
    notify('Saved city removed from this device')
  }
  const returnToMenu=()=>{
    const saved=saveCurrent(true)
    if(!saved)return
    setPaused(true);setTool('select');setSelectedId(null);setSelectionPanelOpen(false);setSystemsOpen(false);setSettingsOpen(false);setLibraryOpen(false);setHelp(false);setFocusMode(false);setWelcome(true);notify(`${saved.name} saved`)
  }

  const selectSceneItem=(id:string|null,kind?:'building'|'realm')=>{
    setSelectedId(id)
    if(!id){setSelectionPanelOpen(false);return}
    setTool('select')
    const buildingSelection=kind==='building'||(kind!=='realm'&&buildings.some(building=>building.id===id))
    if(compactEditor&&buildingSelection){
      setSelectionPanelOpen(false);setCameraMode('orbit');setCameraRevision(value=>value+1);setMobileTools(false);setSystemsOpen(false);setSettingsOpen(false)
    }else setSelectionPanelOpen(true)
  }
  const updateBuilding = (patch: Partial<Building>) => setBuildings(bs => bs.map(b => b.id === selectedId ? { ...b, ...patch } : b))
  const demolish = (id: string) => { capture(); const isPlaza=plazas.some(p=>p.id===id); setBuildings(bs => bs.filter(b => b.id !== id)); setPlazas(ps=>ps.filter(p=>p.id!==id)); if (id === selectedId){setSelectedId(null);setSelectionPanelOpen(false)} notify(isPlaza?'Public ground opened for a new use':'Structure carefully deconstructed for the next idea') }
  const place = (x: number, z: number) => {
    if (tool === 'select' || tool === 'demolish') return
    capture()
    if (tool === 'plaza') { const kinds:Plaza['kind'][]=['garden','water','forum']; setPlazas(ps => [...ps, { id: `p-${Date.now()}`, x, z, trees: 6, kind:kinds[ps.length%kinds.length] }]); notify('New public ground established'); return }
    const program = tool as Program
    const archetypes:Typology[]=['slab','tower','terrace','citadel','bridge','forum']
    const typology=archetypes[(buildings.length+Math.abs(Math.round(x/CELL))+Math.abs(Math.round(z/CELL)))%archetypes.length]
    const b = makeBuilding(x, z, program, typology, buildings.length)
    b.name = namePool[buildings.length % namePool.length]
    setBuildings(bs => [...bs, b]);selectSceneItem(b.id,'building');notify('A new building has joined the city')
  }
  const duplicate = () => {
    if (!selected) return
    const extents=(b:Pick<Building,'width'|'depth'|'rotation'>)=>{const r=b.rotation*Math.PI/180,c=Math.abs(Math.cos(r)),s=Math.abs(Math.sin(r));return {x:(b.width*c+b.depth*s)/2+3,z:(b.width*s+b.depth*c)/2+3}}
    const selectedExt=extents(selected)
    const candidates=lots.filter(l=>!l.road).map(l=>[l.x,l.z] as [number,number]).sort((a,b)=>Math.hypot(a[0]-selected.x,a[1]-selected.z)-Math.hypot(b[0]-selected.x,b[1]-selected.z))
    const spot=candidates.find(([x,z])=>{
      if(Math.abs(x-selected.x)<1&&Math.abs(z-selected.z)<1)return false
      if(plazas.some(p=>Math.abs(x-p.x)<selectedExt.x+CELL*.42&&Math.abs(z-p.z)<selectedExt.z+CELL*.42))return false
      return !buildings.some(other=>{const e=extents(other);return Math.abs(x-other.x)<selectedExt.x+e.x&&Math.abs(z-other.z)<selectedExt.z+e.z})
    })
    if (!spot) return notify('No clear site can hold this family member yet')
    const variation=(buildings.length%5)-2
    capture(); const clone = { ...selected, id: `b-${Date.now()}`, name: `${selected.name} · ${buildings.length+1}`, x: spot[0], z: spot[1],height:Math.max(12,selected.height*(.9+variation*.035)),rotation:(selected.rotation+(variation%2?90:0)+360)%360,articulation:Math.max(0,Math.min(100,selected.articulation+variation*7)),branches:Math.max(0,Math.min(8,selected.branches+(variation>0?1:variation<0?-1:0))),crown:Math.max(0,Math.min(100,selected.crown-variation*6)) }
    setBuildings(bs => [...bs, clone]);selectSceneItem(clone.id,'building');notify('A related structure grew from the same architectural grammar')
  }

  const briefs:GrowthBrief[] = [
    { name:'A lived-in neighborhood', note:'Build homes, workplaces, and welcoming public space.', reward:'Unlocks a choice for life at ground level.', objectives:[
      { label: 'House 2,500 residents', current: metrics.population, target: 2500 },
      { label: 'Create 1,200 jobs', current: metrics.jobs, target: 1200 },
      { label: 'Reach 72% public approval', current: metrics.approval, target: 72 },
      { label: 'Build four public spaces', current: plazas.length, target: 4 },
    ]},
    { name:'The carbon commons', note:'Pair civic life with lower-impact buildings and planted ground.', reward:'Unlocks a choice for shared rooms and specialist places.', objectives:[
      { label: 'Reach 4,000 residents', current: metrics.population, target: 4000 },
      { label: 'Create six public spaces', current: plazas.length, target: 6 },
      { label: 'Establish 500 civic capacity', current: metrics.civic, target: 500 },
      { label: 'Keep carbon below 6t per resident', current: metrics.population?metrics.carbon/metrics.population:0, target: 6, direction:'max', unit:'t', decimals:1, available:metrics.population>0 },
    ]},
    { name:'The open metropolis', note:'Bring many kinds of buildings and public life together.', reward:'Unlocks a choice for the city’s material language.', objectives:[
      { label: 'House 7,500 residents', current: metrics.population, target: 7500 },
      { label: 'Create 4,500 jobs', current: metrics.jobs, target: 4500 },
      { label: 'Reach 85 public-life index', current: metrics.activity, target: 85 },
      { label: 'Shape 28 structures', current: buildings.length, target: 28 },
    ]},
  ]
  const brief = briefStage<briefs.length?briefs[briefStage]:null
  const objectives = brief?.objectives??[]
  const objectiveDone=(objective:GrowthObjective)=>objective.available!==false&&(objective.direction==='max'?objective.current<=objective.target:objective.current>=objective.target)
  const completed = objectives.filter(objectiveDone).length
  const objectiveProgress=(objective:GrowthObjective)=>{
    const value=objective.available===false?'—':objective.decimals!==undefined?objective.current.toFixed(objective.decimals):Math.round(objective.current).toLocaleString()
    const target=objective.decimals!==undefined?objective.target.toFixed(objective.decimals):Math.round(objective.target).toLocaleString()
    return objective.direction==='max'?`${value}${objective.unit??''} / ≤ ${target}${objective.unit??''}`:`${value} / ${target}${objective.unit??''}`
  }
  useEffect(() => {
    if (brief&&objectives.length>0&&completed === objectives.length && completedStage.current !== briefStage) {
      completedStage.current = briefStage
      setBriefStage(stage=>Math.min(briefs.length,stage+1))
      notify(`Sketch complete · a city choice is ready`)
    }
  }, [completed, objectives.length, notify, briefStage, brief, briefs.length])

  const resolveEvent=(choice:EventChoice)=>{
    if(!activeEvent)return
    capture()
    const eventId=activeEvent.id
    setCharter(current=>({...current,[eventId]:choice.choice}))
    setDecisions(records=>[...records.filter(record=>record.eventId!==eventId),{eventId,choice:choice.label,day}])
    setActiveEvent(null);setPaused(pausedBeforeChoice.current);notify(`City changed · ${choice.label} · ${choice.impacts[0]}`)
  }

  const sceneBuildings=welcome?menuPreview.buildings:buildings
  const scenePlazas=welcome?menuPreview.plazas:plazas
  const sceneMood=welcome?normalizeMood(menuPreview.mood):mood
  const sceneHour=welcome?(menuPreview.hour??16.5):hour
  const sceneSignals=welcome?menuSignals:citySignals
  const sceneIdentity=welcome?`menu-${menuTemplate.id}`:`city-${currentCityId??buildings[0]?.id??currentCityName}`
  const performanceKey=`${sceneIdentity}:${sceneMood}`
  const directEditing=compactEditor&&Boolean(selected)&&!selectionPanelOpen

  return <main className={`app view-${welcome?'material':viewMode} mood-${sceneMood}${focusMode?' focus-ui':''}${welcome?' welcome-ui':''}${directEditing?' direct-edit-ui':''}`}>
    <div className="scene"><Suspense fallback={<SceneFallback/>}><CityScene buildings={sceneBuildings} plazas={scenePlazas} selectedId={welcome?null:selectedId} tool={tool} viewMode={welcome?'material':viewMode} mood={sceneMood} cameraMode={welcome?'cinematic':cameraMode} cameraRevision={cameraRevision} hour={sceneHour} paused={welcome?false:paused} graphics={graphics} signals={sceneSignals} focusMode={focusMode||welcome} preview={welcome} performanceKey={performanceKey} onEffectiveQualityChange={setEffectiveQuality} onSelect={selectSceneItem} onLot={place} onDemolish={demolish} onBuildingChange={(id,patch)=>setBuildings(bs=>bs.map(b=>b.id===id?{...b,...patch}:b))} onEditStart={capture}/></Suspense></div>
    {!focusMode&&!welcome&&<>
    <header className="topbar panel">
      <div className="brand"><i className="brand-mark"><span /></i><div><b>MONUMENT</b><small>Brutalist city builder</small></div></div>
      <div className="stats-ribbon"><MiniStat icon={Users} value={fmt(metrics.population)} label="Residents"/><MiniStat icon={Factory} value={fmt(metrics.jobs)} label="Jobs"/><MiniStat icon={HeartPulse} value={`${metrics.approval}%`} label="Approval" tone={metrics.approval>70?'#d7ff43':'#f0c65e'}/><MiniStat icon={Zap} value={`${metrics.activity}`} label="Public life" tone="#d7ff43"/></div>
      <div className="top-actions">
        <button className="icon-btn mobile-menu" aria-label="Build tools and city actions" aria-expanded={mobileTools} aria-controls="build-tools" onClick={()=>{setMobileTools(open=>!open);setSystemsOpen(false);setSettingsOpen(false)}}><Plus/></button>
        <button className="top-label-button menu-toggle" onClick={returnToMenu} title="Main menu" aria-label="Main menu"><Menu/><span>Menu</span></button>
        <button className="top-label-button focus-toggle" onClick={()=>{setFocusMode(true);setSystemsOpen(false);setSettingsOpen(false);notify('Focus mode on · press Escape to exit')}} title="Focus mode" aria-label="Enter focus mode" aria-pressed="false"><Eye/><span>Focus</span></button>
        <button className={`icon-btn systems-button ${systemsOpen?'active':''}`} onClick={()=>{setSystemsOpen(!systemsOpen);setSelectedId(null);setSelectionPanelOpen(false)}} title="City life" aria-label="City life"><BarChart3/></button>
        <button className="icon-btn mobile-save" onClick={()=>saveCurrent()} title="Save city" aria-label="Save city"><Save/></button>
        <button className="icon-btn mobile-library" onClick={()=>{setPaused(true);setLibraryOpen(true)}} title="City library" aria-label="City library"><RotateCcw/></button>
        <button className="icon-btn" onClick={undo} title="Undo"><Undo2/></button><button className="icon-btn" onClick={redo} title="Redo"><Redo2/></button>
        <div className="save-menu"><button onClick={()=>saveCurrent()}><Save size={15}/> Save</button><button onClick={()=>{setPaused(true);setLibraryOpen(true)}} title="City library" aria-label="City library"><RotateCcw size={14}/></button></div>
        <button className="icon-btn" onClick={()=>setHelp(true)} title="Field manual"><CircleHelp/></button><button className={`icon-btn ${settingsOpen?'active':''}`} onClick={()=>setSettingsOpen(open=>!open)} title="Display settings" aria-label="Display settings" aria-haspopup="dialog" aria-expanded={settingsOpen} aria-controls="display-settings"><Settings2/></button>
      </div>
    </header>

    <nav id="build-tools" className={`toolrail panel ${mobileTools ? 'open' : ''}`} aria-label="Build tools">
      <span className="rail-label">BUILD / EDIT</span>
      {toolDefs.map(({ id, label, key, icon: Icon }) => <button data-testid={`tool-${id}`} key={id} className={tool === id ? 'active' : ''} onClick={() => { setTool(id); setSelectedId(null); setSelectionPanelOpen(false); setMobileTools(false) }} title={`${label} [${key}]`}><Icon /><span>{label}</span><kbd>{key}</kbd></button>)}
      <div className="mobile-utilities" aria-label="City actions">
        <button onClick={()=>{undo();setMobileTools(false)}} title="Undo"><Undo2/><span>Undo</span></button>
        <button onClick={()=>{redo();setMobileTools(false)}} title="Redo"><Redo2/><span>Redo</span></button>
        <button className={systemsOpen?'active':''} onClick={()=>{setSystemsOpen(true);setSelectedId(null);setSelectionPanelOpen(false);setMobileTools(false)}} title="City life"><BarChart3/><span>City life</span></button>
        <button onClick={()=>{setHelp(true);setMobileTools(false)}} title="Field manual"><CircleHelp/><span>Manual</span></button>
      </div>
    </nav>

    <section className={`objective panel${brief?'':' complete'}`}><button className="objective-head" aria-expanded={objectivesOpen} onClick={() => setObjectivesOpen(!objectivesOpen)}><div><span className="eyebrow">Growth sketches · {Math.min(briefStage+1,briefs.length)} / {briefs.length}</span><b>{brief?.name??'City choices complete'}</b></div><span className="objective-count">{brief?`${completed}/${objectives.length}`:'3/3'}</span><ChevronDown className={objectivesOpen ? 'up' : ''} size={17} /></button>{objectivesOpen && <div className="objective-body">{brief? <>{objectives.map(objective => { const done=objectiveDone(objective); return <div className={done ? 'done' : ''} key={objective.label}><i>{done ? '✓' : ''}</i><span>{objective.label}<small>{objectiveProgress(objective)}</small></span></div>})}<p>{brief.note}</p><div className="sketch-unlock"><Sparkles/><span><b>Completing this sketch</b><small>{brief.reward}</small></span></div></>:<div className="sketch-finished"><Sparkles/><b>All three city choices are unlocked.</b><small>Keep shaping, rebuilding, and watching the city change.</small></div>}</div>}</section>

    {directEditing&&selected&&<section className="mobile-selection-bar panel" aria-label={`Directly editing ${selected.name}`}>
      <button className="mobile-selection-done" onClick={()=>selectSceneItem(null)} aria-label="Finish editing building"><X/></button>
      <div><span>Direct edit · {PROGRAMS[selected.program].short}</span><b>{selected.name}</b><small>Drag the colored handles · pinch or drag to orbit</small></div>
      <button className="mobile-selection-design" onClick={()=>setSelectionPanelOpen(true)} aria-label={`Open design panel for ${selected.name}`}><Settings2/><span>Design</span></button>
    </section>}
    {selected && selectedPerformance && (!compactEditor||selectionPanelOpen) && <Inspector building={selected} performance={selectedPerformance} onUpdate={updateBuilding} onCapture={capture} onClose={() => compactEditor?setSelectionPanelOpen(false):selectSceneItem(null)} onDuplicate={duplicate} onDemolish={() => demolish(selected.id)} />}
    {selectedPlaza&&<PublicRealmInspector plaza={selectedPlaza} onUpdate={patch=>setPlazas(ps=>ps.map(p=>p.id===selectedPlaza.id?{...p,...patch}:p))} onCapture={capture} onClose={()=>selectSceneItem(null)} onRemove={()=>demolish(selectedPlaza.id)}/>}
    {systemsOpen && <SystemsPanel metrics={metrics} charter={charter} decisions={decisions} onClose={() => setSystemsOpen(false)} />}
    {settingsOpen&&<GraphicsSettingsPanel settings={graphics} effectiveQuality={effectiveQuality} focusMode={focusMode} onChange={patch=>setGraphics(current=>({...current,...patch}))} onFocusChange={active=>{setFocusMode(active);if(active){setSettingsOpen(false);setSystemsOpen(false);notify('Focus mode on · press Escape to exit')}}} onClose={()=>setSettingsOpen(false)}/>}

    <div className="view-dock panel"><div className="dock-section"><span>Lens</span>{viewDefs.map(({ id, label, icon: Icon }) => <button key={id} className={viewMode === id ? 'active' : ''} onClick={() => setViewMode(id)} title={label}><Icon /><small>{label}</small></button>)}</div><div className="dock-separator" /><div className="dock-section mood-section"><span>Mood</span>{moodDefs.map(({ id, label, icon: Icon, accent, hour: moodHour }) => <button data-testid={`mood-${id}`} key={id} className={mood === id ? 'active' : ''} style={{ '--mood': accent } as React.CSSProperties} onClick={() => { if (mood !== id) { capture(); setMood(id); setHour(moodHour); notify(`${label} atmosphere selected`) } }} title={`${label} atmosphere`}><Icon /><small>{label}</small></button>)}</div><div className="dock-separator" /><div className="dock-section camera-modes"><span>Camera · click again to refocus</span>{(['orbit','street','aerial','cinematic'] as CameraMode[]).map((m,i) => { const Icon = [Hand,Eye,Camera,Clapperboard][i]; return <button key={m} className={cameraMode === m ? 'active' : ''} onClick={() => {setCameraMode(m);setCameraRevision(v=>v+1)}} title={`${m} view`}><Icon /><small>{m}</small></button> })}</div></div>

    <div className="timebar panel"><button className="play" onClick={() => setPaused(!paused)} aria-label={paused ? 'Play city' : 'Pause city'}>{paused ? <Play /> : <Pause />}</button><div><span>Day {day}</span><b>{String(Math.floor(hour)).padStart(2,'0')}:{hour % 1 >= .5 ? '30' : '00'}</b></div><input aria-label="Time of day" type="range" min={0} max={23.75} step={.25} value={hour} onChange={e => setHour(Number(e.target.value))} /><button className="mobile-camera" onClick={()=>{const modes:CameraMode[]=['orbit','street','aerial','cinematic'];setCameraMode(current=>modes[(modes.indexOf(current)+1)%modes.length]);setCameraRevision(value=>value+1)}} aria-label="Cycle camera" title="Cycle camera"><Camera/></button><div className="speed"><button className={speed === 1 ? 'active' : ''} onClick={() => setSpeed(1)}>1×</button><button className={speed === 3 ? 'active' : ''} onClick={() => setSpeed(3)}>3×</button><button className={speed === 8 ? 'active' : ''} onClick={() => setSpeed(8)} aria-label="Fast city time"><FastForward /></button></div></div>

    <div className="tool-status"><span>{selected?'MORPH':cameraMode === 'street' ? 'WALK' : tool === 'select' ? 'SELECT' : tool.toUpperCase()}</span><b>{selected?'Drag MOVE to relocate · pull along each colored rail · hold Shift for precision':cameraMode === 'street' ? 'WASD to move · drag to look · scroll to change pace' : cameraMode === 'cinematic' ? 'Cinematic district survey · select another camera to exit' : tool === 'select' ? 'Click a structure to edit · drag to orbit · right-drag to pan' : tool === 'demolish' ? 'Choose a structure to deconstruct' : 'Choose an empty parcel'}</b></div>
    {viewMode !== 'material' && <div className="legend panel"><span>{viewDefs.find(v => v.id === viewMode)?.label}</span>{viewMode === 'program' ? <div className="program-legend">{(Object.keys(PROGRAMS) as Program[]).map(p => <i key={p} style={{ '--c': PROGRAMS[p].color } as React.CSSProperties}>{PROGRAMS[p].short}</i>)}</div> : viewMode === 'structure' ? <p className="structure-key">Transparent massing reveals slabs, columns, cores, and the active load path.</p> : <div className="gradient-legend"><i /><small>{viewMode === 'carbon' ? 'low impact' : viewMode === 'daylight' ? 'less sun' : 'quiet'}</small><small>{viewMode === 'carbon' ? 'high impact' : viewMode === 'daylight' ? 'more sun' : 'intense'}</small></div>}</div>}
    </>}
    {focusMode&&!welcome&&<FocusDock day={day} hour={hour} paused={paused} onExit={()=>setFocusMode(false)} onPause={()=>setPaused(value=>!value)} onHour={setHour} onCamera={()=>{const modes:CameraMode[]=['orbit','street','aerial','cinematic'];setCameraMode(current=>modes[(modes.indexOf(current)+1)%modes.length]);setCameraRevision(value=>value+1)}} onSave={()=>saveCurrent()}/>}
    {toast && <div className="toast" role="status" aria-live="polite"><span>◆</span>{toast}</div>}
    {welcome&&<Welcome selectedTemplate={menuTemplate} onSelect={setMenuTemplateId} saves={savedCities} onStart={beginTemplate} onOpenSave={openSavedCity} onOpenLibrary={()=>setLibraryOpen(true)}/>}
    {libraryOpen&&<CityLibraryModal currentName={currentCityName} saves={savedCities} onNameChange={setCurrentCityName} onSave={()=>saveCurrent()} onOpen={openSavedCity} onDelete={deleteSavedCity} onTemplate={beginTemplate} onClose={()=>setLibraryOpen(false)}/>}
    {help && <HelpModal onClose={() => setHelp(false)} />}
    {activeEvent&&<EventModal event={activeEvent} onChoose={resolveEvent}/>} 
  </main>
}
