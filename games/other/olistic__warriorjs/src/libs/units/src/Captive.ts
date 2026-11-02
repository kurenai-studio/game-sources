import { Unit } from '@warriorjs/core';

class Captive extends Unit {
  readonly name = 'Captive';
  readonly maxHealth = 1;
  readonly enemy = false;
  override bound = true;

  override get reward(): number {
    return 20;
  }
}

export default Captive;
