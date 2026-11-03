import type { WeaponId } from '../game/weapons';

/** Ranks in order; a campaign is played at one rank and promotes to the next. */
export const RANKS = ['Recruit', 'Officer', 'Senior Officer', 'Sergeant', 'Lieutenant', 'Captain', 'Superintendent'] as const;

/**
 * How sharp enemies are. Every rank's campaign is harder than the last: faster reactions,
 * quicker to notice you, tighter aim and a faster rate of fire.
 */
export interface Difficulty {
  /** Multiplier on how long an enemy takes to react before its first shot. */
  reaction: number;
  /** Multiplier on how long an enemy takes to notice the operator. */
  notice: number;
  /** Angular error of an enemy's shot, in degrees. */
  spread: number;
  /** Seconds between an enemy's shots, min and max. */
  fireInterval: [number, number];
  /** Damage it takes to stop a suspect: 1 unarmoured, 2 in a light vest. Each gun's damage counts against it. */
  toughness: number;
}

/** Indexed by rank (see RANKS). The Range has no enemies, so Recruit shares Officer's values. */
export const DIFFICULTY: readonly Difficulty[] = [
  { reaction: 1, notice: 1, spread: 4, fireInterval: [0.7, 1.1], toughness: 1 },
  { reaction: 1, notice: 1, spread: 4, fireInterval: [0.7, 1.1], toughness: 1 },
  { reaction: 0.85, notice: 0.8, spread: 3.2, fireInterval: [0.6, 0.95], toughness: 2 },
  { reaction: 0.72, notice: 0.65, spread: 2.6, fireInterval: [0.5, 0.85], toughness: 2 },
  { reaction: 0.6, notice: 0.55, spread: 2.2, fireInterval: [0.45, 0.75], toughness: 2 },
  { reaction: 0.52, notice: 0.48, spread: 2, fireInterval: [0.42, 0.7], toughness: 2 },
];

/**
 * Suppressors are the last issue: they come with promotion to Lieutenant, after the sniper rifle.
 * Then earlier cases can be replayed quietly.
 */
export const SUPPRESSOR_RANK = 4;

/**
 * The breach charge is the very last issue, with promotion to Captain: one per mission, to blow a
 * hole in a wall and stun whoever is behind it.
 */
export const BREACH_RANK = 5;

export interface CampaignDef {
  id: string;
  title: string;
  /** The campaign's story in one line, for the menu. */
  blurb: string;
  /** Index into RANKS: the rank this campaign is played at. */
  rank: number;
  /** Level ids, in order. Each unlocks when the previous one is completed. */
  levels: string[];
  promotion: {
    /** Stars needed across the campaign, on top of completing every level. */
    minStars: number;
    /** A gun issued with the promotion. */
    unlocks?: WeaponId;
    /** The note on the promotion screen. */
    note: string[];
    /** Who signs it, when it isn't the captain. */
    from?: string;
  };
}

export const CAMPAIGNS: readonly CampaignDef[] = [
  {
    id: 'academy',
    title: 'Academy',
    blurb: 'Qualify on the Range: movement, aim, doors, and when not to shoot.',
    rank: 0,
    levels: ['range'],
    promotion: {
      minStars: 1,
      unlocks: 'shotgun',
      note: [
        'Range qualification passed.',
        'Assigned to Ashby Narcotics as Officer, effective immediately.',
        'First warrant: 14 Harbour Lane. Read the briefing. Plans are not always accurate.',
      ],
    },
  },
  {
    id: 'officer',
    title: 'Street crime',
    blurb: 'Raids on the Ashby estate, on dealers who keep naming the same supplier.',
    rank: 1,
    levels: ['harbour-lane', 'fenwick-terrace', 'tollgate-flats', 'mercer-street', 'kestrel-road', 'westquay-lockups'],
    promotion: {
      minStars: 12,
      unlocks: 'rifle',
      note: [
        'Six warrants on the Ashby estate. Every one leads to Corvan Logistics.',
        'Promoted to Senior Officer. Transferred to the Supply Chain unit, effective Monday.',
      ],
    },
  },
  {
    id: 'senior',
    title: 'Supply chain',
    blurb: 'A logistics firm moving more than parcels, from the depot to the docks.',
    rank: 2,
    levels: ['corvan-depot', 'corvan-head-office', 'salter-street', 'cold-store', 'ferry-road', 'harbour-freight'],
    promotion: {
      minStars: 12,
      unlocks: 'sniper',
      note: [
        "Corvan's supply chain is shut down. Elias Rook is in custody.",
        'Promoted to Sergeant. Transferred to Financial Crime.',
        'Next target: Meridian Partners, Grand Atlas Hotel.',
      ],
    },
  },
  {
    id: 'sergeant',
    title: 'Clean money',
    blurb: "The ring's accountants, over one night at the Grand Atlas Hotel.",
    rank: 3,
    levels: ['atlas-service', 'atlas-floor-4', 'atlas-conference', 'atlas-yard', 'atlas-penthouse'],
    promotion: {
      minStars: 10,
      note: [
        'Meridian Partners is shut down. Leonard Voight is in custody.',
        'Promoted to Lieutenant.',
        "Voight's contacts are under review. Await orders.",
      ],
    },
  },
  {
    id: 'lieutenant',
    title: 'The top',
    blurb: 'The people behind it all, and their friends in high places.',
    rank: 4,
    levels: ['hillcrest-villa', 'the-halcyon', 'ardley-lodge', 'gull-point', 'westcliff-house'],
    promotion: {
      minStars: 10,
      note: [
        'Deputy Commissioner Calloway in custody. Councillors Pryce and Kessler charged.',
        'The network from Harbour Lane to Westcliff House is closed.',
        'Promoted to Captain, effective immediately.',
      ],
      from: 'Commissioner Adeyemi',
    },
  },
  {
    id: 'captain',
    title: 'Inside job',
    blurb: 'Calloway was not the only one. Someone at headquarters is cleaning up.',
    rank: 5,
    levels: ['marsh-lane', 'records-archive', 'the-anchor', 'police-hq'],
    promotion: {
      minStars: 8,
      note: [
        'Superintendent Hale in custody. His team charged.',
        'Every case from Harbour Lane to Westcliff House stands.',
        'Promoted to Superintendent. You take his post.',
      ],
      from: 'Commissioner Adeyemi',
    },
  },
];

export function campaignOf(levelId: string): CampaignDef | undefined {
  return CAMPAIGNS.find((c) => c.levels.includes(levelId));
}
