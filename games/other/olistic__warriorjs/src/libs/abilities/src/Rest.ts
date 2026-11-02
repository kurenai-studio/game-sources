import { type AbilityBinding, Action } from '@warriorjs/core';

import { type AbilityMeta, type Unit } from './types.js';

interface RestConfig {
  healthGain: number;
}

class Rest extends Action {
  readonly description: string;
  readonly meta: AbilityMeta = {
    params: [],
    returns: 'void',
  };

  private healthGain: number;

  constructor(unit: Unit, { healthGain }: RestConfig) {
    super(unit);
    this.description = `Gains ${healthGain * 100}% of max health back, but does nothing more.`;
    this.healthGain = healthGain;
  }

  perform(): void {
    if (this.unit.health < this.unit.maxHealth) {
      this.unit.emit({ type: 'rest', description: 'rests', params: {} });
      const amount = Math.round(this.unit.maxHealth * this.healthGain);
      this.unit.heal(amount);
    } else {
      this.unit.emit({
        type: 'rest',
        description: 'has nothing to heal',
        params: { atFull: true },
      });
    }
  }

  static with(config: RestConfig): AbilityBinding {
    return [Rest, config];
  }
}

export default Rest;
