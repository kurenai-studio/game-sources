export type Program = 'housing' | 'work' | 'civic' | 'culture' | 'mixed'
export type Tool = 'select' | Program | 'plaza' | 'demolish'
export type ViewMode = 'material' | 'program' | 'structure' | 'daylight' | 'activity' | 'carbon'
export type CameraMode = 'orbit' | 'street' | 'aerial' | 'cinematic'
export type DistrictMood = 'default' | 'cyberpunk' | 'green' | 'totalitarian' | 'university'
export type GraphicsQuality = 'auto' | 'low' | 'balanced' | 'high'

export interface GraphicsSettings {
  quality: GraphicsQuality
  edgeSmoothing: boolean
}

export interface DistrictCharter {
  undercroft?: 'open' | 'quiet'
  commons?: 'shared' | 'specialist'
  aggregate?: 'reuse' | 'formal'
}

export interface DecisionRecord {
  eventId: keyof DistrictCharter
  choice: string
  day: number
}

export interface CitySignals {
  activity: number
  nightAccess: 'neutral' | 'open' | 'quiet'
  sharedRooms: boolean
  specialistGrowth: boolean
  reuse: boolean
  formal: boolean
}
export type Tone = 'raw' | 'warm' | 'sand' | 'terracotta' | 'charcoal' | 'white'
export type Typology = 'slab' | 'tower' | 'terrace' | 'citadel' | 'bridge' | 'forum'
export type StructuralSystem = 'frame' | 'walls' | 'cores'
export type FacadeStrategy = 'ribbon' | 'deep-grid' | 'brise-soleil' | 'punched' | 'exoskeleton' | 'screen'
export type DesignLanguage = 'monolithic' | 'civic' | 'metabolist' | 'tropical' | 'infrastructural' | 'garden'
export type Composition = 'bar' | 'split' | 'cluster' | 'stack' | 'court' | 'bridge' | 'ring' | 'capsule' | 'megastructure'
export type Profile = 'straight' | 'stepped' | 'tapered' | 'top-heavy' | 'offset' | 'twisted'

export interface Building {
  id: string
  name: string
  x: number
  z: number
  height: number
  width: number
  depth: number
  rotation: number
  terraces: number
  cantilever: number
  porosity: number
  rhythm: number
  tone: Tone
  program: Program
  typology: Typology
  condition: number
  age: number
  floorHeight: number
  baySpacing: number
  structural: StructuralSystem
  facade: FacadeStrategy
  pilotis: number
  balconies: number
  cores: number
  podiumHeight: number
  language: DesignLanguage
  voids: number
  taper: number
  facadeDepth: number
  weathering: number
  vegetation: number
  composition: Composition
  profile: Profile
  moduleDensity: number
  articulation: number
  branches: number
  crown: number
}

export interface Plaza {
  id: string
  x: number
  z: number
  trees: number
  kind?: 'water' | 'garden' | 'forum'
}

export interface CityMetrics {
  population: number
  capacity: number
  jobs: number
  culture: number
  civic: number
  activity: number
  approval: number
  carbon: number
}

export interface GameSnapshot {
  buildings: Building[]
  plazas: Plaza[]
  day: number
  briefStage: number
  mood?: DistrictMood | 'brutalist'
  hour?: number
  charter?: DistrictCharter
  decisions?: DecisionRecord[]
}
