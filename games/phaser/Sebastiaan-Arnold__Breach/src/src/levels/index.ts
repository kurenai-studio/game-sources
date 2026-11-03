import { ARDLEY_LODGE } from './the-top/ardley-lodge';
import { ATLAS_CONFERENCE } from './clean-money/atlas-conference';
import { ATLAS_FLOOR_4 } from './clean-money/atlas-floor-4';
import { ATLAS_PENTHOUSE } from './clean-money/atlas-penthouse';
import { ATLAS_SERVICE } from './clean-money/atlas-service';
import { ATLAS_YARD } from './clean-money/atlas-yard';
import { COLD_STORE } from './supply-chain/cold-store';
import { CORVAN_DEPOT } from './supply-chain/corvan-depot';
import { CORVAN_HEAD_OFFICE } from './supply-chain/corvan-head-office';
import { FENWICK_TERRACE } from './street-crime/fenwick-terrace';
import { FERRY_ROAD } from './supply-chain/ferry-road';
import { GULL_POINT } from './the-top/gull-point';
import { HARBOUR_FREIGHT } from './supply-chain/harbour-freight';
import { HARBOUR_LANE } from './street-crime/harbour-lane';
import { HILLCREST_VILLA } from './the-top/hillcrest-villa';
import { KESTREL_ROAD } from './street-crime/kestrel-road';
import { MARSH_LANE } from './inside-job/marsh-lane';
import { MERCER_STREET } from './street-crime/mercer-street';
import { POLICE_HQ } from './inside-job/police-hq';
import { RANGE } from './academy/range';
import { RECORDS_ARCHIVE } from './inside-job/records-archive';
import { SALTER_STREET } from './supply-chain/salter-street';
import { THE_ANCHOR } from './inside-job/the-anchor';
import { THE_HALCYON } from './the-top/the-halcyon';
import { TOLLGATE_FLATS } from './street-crime/tollgate-flats';
import type { LevelDef } from './types';
import { WESTCLIFF_HOUSE } from './the-top/westcliff-house';
import { WESTQUAY_LOCKUPS } from './street-crime/westquay-lockups';

/** Every playable level, in campaign order. */
export const LEVELS: readonly LevelDef[] = [
  RANGE,
  HARBOUR_LANE, FENWICK_TERRACE, TOLLGATE_FLATS, MERCER_STREET, KESTREL_ROAD, WESTQUAY_LOCKUPS,
  CORVAN_DEPOT, CORVAN_HEAD_OFFICE, SALTER_STREET, COLD_STORE, FERRY_ROAD, HARBOUR_FREIGHT,
  ATLAS_SERVICE, ATLAS_FLOOR_4, ATLAS_CONFERENCE, ATLAS_YARD, ATLAS_PENTHOUSE,
  HILLCREST_VILLA, THE_HALCYON, ARDLEY_LODGE, GULL_POINT, WESTCLIFF_HOUSE,
  MARSH_LANE, RECORDS_ARCHIVE, THE_ANCHOR, POLICE_HQ,
];

export function levelById(id: string): LevelDef {
  const level = LEVELS.find((l) => l.id === id);
  if (!level) throw new Error(`Unknown level: ${id}`);
  return level;
}
