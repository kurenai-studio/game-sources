import { Action } from '@warriorjs/core';
import { FORWARD, type RelativeDirection } from '@warriorjs/spatial';

import { type AbilityMeta } from './types.js';

const defaultDirection = FORWARD;

class Walk extends Action {
  readonly description =
    `Moves one space in the given direction (\`'${defaultDirection}'\` by default).`;
  readonly meta: AbilityMeta = {
    params: [{ name: 'direction', type: 'Direction', optional: true }],
    returns: 'void',
  };

  perform(direction: RelativeDirection = defaultDirection): void {
    const space = this.unit.getSpaceAt(direction);
    if (space.isEmpty()) {
      this.unit.move(direction);
      this.unit.emit({
        type: 'walk',
        description: 'walks {direction}',
        params: { direction, blocked: false },
      });
    } else {
      const unit = space.getUnit();
      this.unit.emit({
        type: 'walk',
        description: 'walks {direction} and bumps into {obstacle}',
        params: {
          direction,
          obstacle: unit
            ? { type: 'unit', name: unit.name, warrior: unit.isWarrior() }
            : String(space),
          blocked: true,
        },
      });
    }
  }
}

export default Walk;
