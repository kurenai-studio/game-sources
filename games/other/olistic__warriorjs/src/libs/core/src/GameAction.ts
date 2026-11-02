export interface UnitRef {
  type: 'unit';
  name: string;
  warrior?: boolean;
}

export interface GameAction {
  type: string;
  description: string;
  params: Record<string, unknown>;
}
