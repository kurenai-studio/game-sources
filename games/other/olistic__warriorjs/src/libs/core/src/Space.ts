import {
  getAbsoluteOffset,
  getRelativeOffset,
  type Location,
  type RelativeOffset,
  translateLocation,
} from '@warriorjs/spatial';
import invariant from 'tiny-invariant';

import type Floor from './Floor.js';
import { type FloorSpace } from './Floor.js';
import type Unit from './Unit.js';

export interface SensedSpace {
  getLocation(): RelativeOffset;
  getUnit(): SensedUnit | null;
  isEmpty(): boolean;
  isStairs(): boolean;
  isUnit(): boolean;
  isWall(): boolean;
}

export interface SensedUnit {
  isBound(): boolean;
  isEnemy(): boolean;
  isUnderEffect(name: string): boolean;
}

class Space {
  floor: Floor;
  location: Location;

  static from(sensedSpace: SensedSpace, unit: Unit): Space {
    invariant(unit.position, `${unit.name} has no position (unit is not on the floor).`);
    const { floor, location, orientation } = unit.position;
    const offset = getAbsoluteOffset(sensedSpace.getLocation(), orientation);
    const spaceLocation = translateLocation(location, offset);
    return new Space(floor, spaceLocation);
  }

  constructor(floor: Floor, location: Location) {
    this.floor = floor;
    this.location = location;
  }

  isEmpty(): boolean {
    return !this.isUnit() && !this.isWall();
  }

  isStairs(): boolean {
    return this.floor.isStairs(this.location);
  }

  isWall(): boolean {
    return this.floor.isOutOfBounds(this.location);
  }

  isUnit(): boolean {
    return !!this.getUnit();
  }

  getUnit(): Unit | undefined {
    return this.floor.getUnitAt(this.location);
  }

  as(unit: Unit): SensedSpace {
    invariant(unit.position, `${unit.name} has no position (unit is not on the floor).`);
    const unitPosition = unit.position;
    return {
      getLocation: () =>
        getRelativeOffset(this.location, unitPosition.location, unitPosition.orientation),
      getUnit: () => {
        const spaceUnit = this.getUnit.call(this);
        return spaceUnit ? spaceUnit.as(unit) : null;
      },
      isEmpty: this.isEmpty.bind(this),
      isStairs: this.isStairs.bind(this),
      isUnit: this.isUnit.bind(this),
      isWall: this.isWall.bind(this),
    };
  }

  toString(): string {
    const unit = this.getUnit();
    if (unit) {
      return unit.toString();
    }

    if (this.isWall()) {
      return 'wall';
    }

    return 'nothing';
  }

  toJSON(): FloorSpace {
    const space: FloorSpace = {};
    if (this.isWall()) space.wall = true;
    if (this.isStairs()) space.stairs = true;
    const unit = this.getUnit();
    if (unit) {
      space.unit = {
        name: unit.name,
        maxHealth: unit.maxHealth,
        ...(unit === this.floor.warrior && { warrior: true }),
      };
    }
    return space;
  }
}

export default Space;
