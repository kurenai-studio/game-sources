import { type GameAction, type SensedSpace } from '@warriorjs/core';
import { type AbsoluteDirection, type Location, type RelativeDirection } from '@warriorjs/spatial';

export interface Space {
  location: Location;
  getUnit(): Unit | null;
  isEmpty(): boolean;
  isStairs(): boolean;
  isUnit(): boolean;
  isWall(): boolean;
}

export interface Unit {
  health: number;
  maxHealth: number;
  position: {
    location: Location;
    orientation: AbsoluteDirection;
  };
  getSpaceAt(direction: RelativeDirection, forward?: number, right?: number): Space;
  getSensedSpaceAt(direction: RelativeDirection, forward?: number, right?: number): SensedSpace;
  getDirectionOf(space: SensedSpace): RelativeDirection;
  getDirectionOfStairs(): RelativeDirection;
  getDistanceOf(space: SensedSpace): number;
  getOtherUnits(): Array<{ getSpace(): { location: Location } }>;
  getSpace(): { location: Location };
  move(direction: RelativeDirection): void;
  rotate(direction: RelativeDirection): void;
  damage(receiver: Unit, amount: number): void;
  heal(amount: number): void;
  release(receiver: Unit): void;
  bind(): void;
  isBound(): boolean;
  isUnderEffect(effect: string): boolean;
  triggerEffect(effect: string): void;
  emit(action: GameAction): void;
  isWarrior(): boolean;
  name: string;
}

export interface AbilityParam {
  name: string;
  type: 'Direction' | 'Space' | 'number' | 'any';
  optional?: boolean;
  rest?: boolean;
}

export interface AbilityMeta {
  params: AbilityParam[];
  returns: 'void' | 'number' | 'string' | 'Direction' | 'Space' | 'Space[]';
}
