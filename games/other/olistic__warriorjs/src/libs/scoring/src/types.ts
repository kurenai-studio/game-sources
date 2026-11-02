export interface ScoringFloorSpace {
  unit?: unknown;
}

export interface ScoringEvent {
  warriorStatus?: { score: number };
  floorMap: ScoringFloorSpace[][];
}
