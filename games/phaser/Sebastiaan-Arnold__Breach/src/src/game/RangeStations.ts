import { RANGE_STATIONS, stationAt, type StationDef, type StationId } from '../levels/academy/range';
import type { Target } from './Target';

const LANE_HITS_NEEDED = 5;
const SPRINT_NEEDED = 0.6;

/** Tracks progress through the Range's training stations. */
export class RangeStations {
  private done = new Set<StationId>();
  private sprintTime = 0;
  private reachedEnd = false;
  private laneHits = 0;

  constructor(private targets: readonly Target[]) {}

  get allDone(): boolean {
    return this.done.size === RANGE_STATIONS.length;
  }

  onSprint(dt: number, tx: number, ty: number): void {
    if (stationAt(tx, ty)?.id === 'movement') this.sprintTime += dt;
  }

  onTargetHit(t: Target): void {
    if (t.station === 'targets') this.laneHits++;
  }

  /** Returns stations that were completed by this check. */
  update(tx: number, ty: number): StationDef[] {
    if (stationAt(tx, ty)?.id === 'movement' && tx >= 52) this.reachedEnd = true;
    const completed: StationDef[] = [];
    for (const s of RANGE_STATIONS) {
      if (this.done.has(s.id) || !this.isComplete(s.id)) continue;
      this.done.add(s.id);
      completed.push(s);
    }
    return completed;
  }

  private suspects(id: StationId): { down: number; total: number } {
    const list = this.targets.filter((t) => t.station === id && t.kind === 'suspect');
    return { down: list.filter((t) => !t.alive).length, total: list.length };
  }

  private isComplete(id: StationId): boolean {
    switch (id) {
      case 'movement':
        return this.reachedEnd && this.sprintTime >= SPRINT_NEEDED;
      case 'targets':
        return this.laneHits >= LANE_HITS_NEEDED;
      case 'doors':
      case 'shoot':
      case 'killhouse': {
        const s = this.suspects(id);
        return s.total > 0 && s.down === s.total;
      }
    }
  }
}
