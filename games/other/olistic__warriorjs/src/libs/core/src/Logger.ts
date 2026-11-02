import type Floor from './Floor.js';
import { type FloorSpace } from './Floor.js';
import { type GameAction } from './GameAction.js';
import type Unit from './Unit.js';

export interface TurnEvent {
  action: GameAction;
  actor: { name: string; warrior: boolean } | null;
  floorMap: FloorSpace[][];
  warriorStatus: { health: number; score: number } | undefined;
}

const Logger: {
  floor: Floor | null;
  turns: TurnEvent[][];
  lastTurn: TurnEvent[] | null;
  initialState: TurnEvent | null;
  play(floor: Floor): void;
  turn(): void;
  unit(unit: Unit, action: GameAction): void;
} = {
  floor: null,
  turns: [],
  lastTurn: null,
  initialState: null,

  play(floor: Floor) {
    Logger.floor = floor;
    Logger.turns = [];
    Logger.lastTurn = null;
    Logger.initialState = {
      action: { type: 'init', description: '', params: {} },
      actor: null,
      floorMap: JSON.parse(JSON.stringify(floor.getMap())),
      warriorStatus: floor.warrior?.getStatus(),
    };
  },

  turn() {
    Logger.lastTurn = [];
    Logger.turns.push(Logger.lastTurn);
  },

  unit(unit: Unit, action: GameAction) {
    Logger.lastTurn?.push({
      action,
      actor: { name: unit.name, warrior: unit === Logger.floor?.warrior },
      floorMap: JSON.parse(JSON.stringify(Logger.floor?.getMap())),
      warriorStatus: Logger.floor?.warrior?.getStatus(),
    });
  },
};

export default Logger;
