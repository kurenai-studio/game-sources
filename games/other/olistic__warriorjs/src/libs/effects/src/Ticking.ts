import { Effect, type EffectBinding } from '@warriorjs/core';

interface TickingConfig {
  time: number;
}

class Ticking extends Effect {
  readonly description = 'Kills you and all surrounding units when time reaches zero.';

  time: number;

  constructor(unit: any, { time }: TickingConfig) {
    super(unit);
    this.time = time;
  }

  passTurn(): void {
    if (this.time) {
      this.time -= 1;
    }

    this.unit.emit({ type: 'tick', description: 'is ticking', params: {} });

    if (!this.time) {
      this.trigger();
    }
  }

  trigger(): void {
    this.unit.emit({
      type: 'explode',
      description: 'explodes, collapsing the ceiling and killing every unit',
      params: {},
    });
    [...this.unit.getOtherUnits(), this.unit].forEach((anotherUnit: any) =>
      anotherUnit.takeDamage(anotherUnit.health),
    );
  }

  static with(config: TickingConfig): EffectBinding {
    return [Ticking, config];
  }
}

export default Ticking;
