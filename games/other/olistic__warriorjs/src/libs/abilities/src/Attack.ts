import { type AbilityBinding, Action } from '@warriorjs/core';
import { BACKWARD, FORWARD, type RelativeDirection } from '@warriorjs/spatial';

import { type AbilityMeta, type Unit } from './types.js';

const defaultDirection = FORWARD;

interface AttackConfig {
  power: number;
}

class Attack extends Action {
  readonly description: string;
  readonly meta: AbilityMeta = {
    params: [{ name: 'direction', type: 'Direction', optional: true }],
    returns: 'void',
  };

  private power: number;

  constructor(unit: Unit, { power }: AttackConfig) {
    super(unit);
    this.description = `Attacks a unit in the given direction (\`'${defaultDirection}'\` by default), dealing ${power} HP of damage.`;
    this.power = power;
  }

  perform(direction: RelativeDirection = defaultDirection): void {
    const receiver = this.unit.getSpaceAt(direction).getUnit();
    if (receiver) {
      this.unit.emit({
        type: 'attack',
        description: 'attacks {direction} and hits {target}',
        params: {
          direction,
          target: { type: 'unit', name: receiver.name, warrior: receiver.isWarrior() },
          hit: true,
        },
      });
      const attackingBackward = direction === BACKWARD;
      const amount = attackingBackward ? Math.ceil(this.power / 2.0) : this.power;
      this.unit.damage(receiver, amount);
    } else {
      this.unit.emit({
        type: 'attack',
        description: 'attacks {direction} and hits nothing',
        params: { direction, hit: false },
      });
    }
  }

  static with(config: AttackConfig): AbilityBinding {
    return [Attack, config];
  }
}

export default Attack;
