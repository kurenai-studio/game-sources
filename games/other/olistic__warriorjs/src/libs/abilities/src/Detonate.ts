import { type AbilityBinding, Action } from '@warriorjs/core';
import { FORWARD, type RelativeDirection, type RelativeOffset } from '@warriorjs/spatial';

import { type AbilityMeta, type Space, type Unit } from './types.js';

const defaultDirection = FORWARD;
const surroundingOffsets: RelativeOffset[] = [
  [1, 1],
  [1, -1],
  [2, 0],
  [0, 0],
];

interface DetonateConfig {
  targetPower: number;
  surroundingPower: number;
}

class Detonate extends Action {
  readonly description: string;
  readonly meta: AbilityMeta = {
    params: [{ name: 'direction', type: 'Direction', optional: true }],
    returns: 'void',
  };

  private targetPower: number;
  private surroundingPower: number;

  constructor(unit: Unit, { targetPower, surroundingPower }: DetonateConfig) {
    super(unit);
    this.description = `Detonates a bomb in a given direction (\`'${defaultDirection}'\` by default), dealing ${targetPower} HP of damage to that space and ${surroundingPower} HP of damage to surrounding 4 spaces (including yourself).`;
    this.targetPower = targetPower;
    this.surroundingPower = surroundingPower;
  }

  perform(direction: RelativeDirection = defaultDirection): void {
    this.unit.emit({
      type: 'detonate',
      description: 'detonates a bomb {direction} launching a deadly explosion',
      params: { direction },
    });
    const targetSpace = this.unit.getSpaceAt(direction);
    this.bomb(targetSpace, this.targetPower);
    surroundingOffsets
      .map(([forward, right]) => this.unit.getSpaceAt(direction, forward, right))
      .forEach((surroundingSpace) => {
        this.bomb(surroundingSpace, this.surroundingPower);
      });
  }

  private bomb(space: Space, power: number): void {
    const receiver = space.getUnit();
    if (receiver) {
      this.unit.damage(receiver, power);
      if (receiver.isUnderEffect('ticking')) {
        receiver.emit({
          type: 'chainDetonate',
          description: 'caught in the blast, detonating the ticking explosive',
          params: {},
        });
        receiver.triggerEffect('ticking');
      }
    }
  }

  static with(config: DetonateConfig): AbilityBinding {
    return [Detonate, config];
  }
}

export default Detonate;
