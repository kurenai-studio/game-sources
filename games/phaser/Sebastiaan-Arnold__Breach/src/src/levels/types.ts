import type { WeaponId } from '../game/weapons';
import type { FloorLabel, StationDef } from './academy/range';

/** A position in tile units; fractions are allowed (0.5 is a tile's centre). */
export interface TilePos {
  tx: number;
  ty: number;
}

export interface EntryDef {
  id: string;
  /** Shown on the briefing map and in the intro, e.g. "front door". */
  name: string;
  /**
   * The intro walk: from the drop-off point to where the operator stands at the entry. The
   * drop-off can differ per entry, so far-side entries don't need a long walk round.
   */
  approach: TilePos[];
}

/**
 * Lookouts hold a post, patrollers walk a route, hiders wait behind cover with a shotgun and only
 * fire at close range. Heavies are contractors in plate carriers with rifles: they take an extra
 * hit and always push towards a fight.
 */
export type HostileType = 'lookout' | 'patroller' | 'hider' | 'heavy';

/**
 * How a hostile reacts to a fight it hears: pushers come for you, holders dig in and cover the
 * door you'd come through.
 */
export type Temperament = 'pusher' | 'holder';

export interface HostileSlot {
  type: HostileType;
  tx: number;
  ty: number;
  /** Degrees, 0 = east, 90 = south. */
  facing: number;
  /** Patrollers walk this loop. */
  route?: TilePos[];
  /** Fixes the reaction to a fight; rolled per deploy when left out. */
  temperament?: Temperament;
  /** Always there, whatever the roll (a hostage's captor, say). */
  always?: boolean;
}

export interface CivilianSlot {
  tx: number;
  ty: number;
}

export type Reliability = 'Confirmed' | 'Likely' | 'Unverified';

/**
 * A case. Briefing text is terse and procedural, the way a real one reads: names, times,
 * counts. No flourishes.
 */
export interface MissionDef {
  title: string;
  location: string;
  /** Local time of the operation, e.g. '23:40'. */
  time: string;
  /** Short lines: who, where, what's known. Shown as bullets. */
  situation: string[];
  /** What the warrant says to do, in one line. */
  objective: string;
  hostiles: { min: number; max: number };
  loadout: string;
  civilians: { min: number; max: number; text: string };
  reliability: Reliability;
  hostileSlots: HostileSlot[];
  civilianSlots: CivilianSlot[];
  /** Areas the plans don't cover; greyed out on the briefing map. Tile rectangles, inclusive. */
  unknownZones: { x0: number; y0: number; x1: number; y1: number }[];
  /** A line for the debrief once the site is secured. */
  debriefNote: string;
  /** A specialty mission issues its own primary gun instead of the player's choice. */
  issued?: WeaponId;
  /** What makes this case different, as one highlighted line in the briefing's intel. */
  twist?: { label: string; text: string };
  /**
   * Someone held against their will. Once the alarm goes up (a suspect sees you, or a shot or
   * shout), the operator has `seconds` to reach and secure them, or the mission fails.
   */
  hostage?: TilePos & { seconds: number };
  /**
   * Evidence that gets destroyed (shredded, flushed) if the alarm goes up: the nearest suspect
   * runs to it, and after `seconds` there it's gone, and with it the first star.
   */
  evidence?: TilePos & { seconds: number };
  /**
   * Overwatch: the operator holds a roof and doesn't move in. The camera pulls right out and
   * sight reaches across the map. Once the alarm goes up, every suspect makes for `getaway`;
   * one reaching it fails the mission. Ground units secure the civilians.
   */
  overwatch?: { getaway: TilePos };
  /**
   * Alarm panels. When guards hear or see trouble they push or dig in as usual, and the alerted
   * guard nearest a panel runs for it. If he reaches it and sets it off, the mission fails;
   * drop him first and the next alerted guard takes up the run. Made for suppressors.
   */
  alarmPanels?: TilePos[];
}

/** Vehicles and site kit: solid, drawn over the floor. */
export type VehicleKind = 'van' | 'car' | 'container' | 'rack' | 'truck';

/**
 * Furniture: what a block of furniture tiles ('T') in the map actually is. The map keeps the
 * collision (blocks movement, not sight or bullets); the prop only says how it's drawn.
 */
export type FurnitureKind =
  | 'bed' | 'sofa' | 'armchair' | 'table' | 'lowtable' | 'desk' | 'kitchen' | 'bath' | 'wc'
  | 'wardrobe' | 'shelf' | 'tv' | 'plant' | 'bench' | 'crates' | 'pallet' | 'drums' | 'cabinet'
  | 'bins' | 'counter' | 'pool';

/** Floor dressing: drawn on open floor, blocks nothing. */
export type FloorKind = 'rug' | 'clutter';

/** What lies about in a `clutter` patch. */
export type ClutterStyle = 'party' | 'drugs' | 'trash' | 'office' | 'tools' | 'laundry';

/**
 * Set dressing drawn into the level art. Vehicles, containers and racking are solid in their own
 * right (cars and containers also sit on furniture tiles in the map); furniture sits on furniture
 * tiles; rugs and clutter lie on open floor.
 */
export interface PropDef {
  kind: VehicleKind | FurnitureKind | FloorKind;
  tx: number;
  ty: number;
  /** Vehicles and containers lie east-west unless vertical. */
  vertical?: boolean;
  /** Size in tiles (furniture and floor dressing default to one tile). */
  w?: number;
  h?: number;
  color?: number;
  /** Furniture: the side it stands against (a bed's head, a sofa's back, a worktop's back). */
  side?: 'n' | 'e' | 's' | 'w';
  /** Clutter: what's lying about. */
  style?: ClutterStyle;
}

export interface LevelDef {
  id: string;
  name: string;
  map: readonly string[];
  labels: readonly FloorLabel[];
  props?: readonly PropDef[];
  entries: EntryDef[];
  /** Radio lines played over the intro walk. `{entry}` is replaced by the entry's name. */
  intro: string[];
  /** Training stations; present on the Range only. */
  stations?: readonly StationDef[];
  mission?: MissionDef;
}
