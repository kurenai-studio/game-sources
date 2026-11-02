import { Look, Shoot } from '@warriorjs/abilities';

import RangedUnit from './RangedUnit.js';

class Archer extends RangedUnit {
  static declaredAbilities = {
    look: Look.with({ range: 3 }),
    shoot: Shoot.with({ range: 3, power: 3 }),
  };

  readonly name = 'Archer';
  readonly maxHealth = 7;
}

export default Archer;
