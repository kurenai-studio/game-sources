import { Attack, Feel } from '@warriorjs/abilities';

import MeleeUnit from './MeleeUnit.js';

class Sludge extends MeleeUnit {
  static declaredAbilities = {
    attack: Attack.with({ power: 3 }),
    feel: Feel,
  };

  readonly name = 'Sludge';
  readonly maxHealth = 12;
}

export default Sludge;
