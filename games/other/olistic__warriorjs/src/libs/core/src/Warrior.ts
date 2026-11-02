import { type AbilitySpec } from './Ability.js';
import Action from './Action.js';
import Unit from './Unit.js';

class Warrior extends Unit {
  override readonly name: string;
  override readonly maxHealth: number;
  override readonly enemy = false;

  constructor(name: string, maxHealth: number) {
    super();
    this.name = name;
    this.maxHealth = maxHealth;
  }

  override isWarrior(): boolean {
    return true;
  }

  performTurn(): void {
    super.performTurn();
    if (!this.turn?.action || this.isBound()) {
      this.emit({ type: 'idle', description: 'does nothing', params: {} });
    }
  }

  earnPoints(points: number): void {
    super.earnPoints(points);
    this.emit({
      type: 'earnPoints',
      description: 'earns {points} points',
      params: { points },
    });
  }

  losePoints(points: number): void {
    super.losePoints(points);
    this.emit({
      type: 'losePoints',
      description: 'loses {points} points',
      params: { points },
    });
  }

  getAbilities(): AbilitySpec[] {
    return [...this.abilities]
      .map(([name, ability]) => ({
        name,
        description: ability.description,
        meta: ability.meta,
        isAction: ability instanceof Action,
      }))
      .sort((a, b) => a.name.localeCompare(b.name));
  }

  getStatus(): { health: number; score: number } {
    return {
      health: this.health,
      score: this.score,
    };
  }
}

export default Warrior;
