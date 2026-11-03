export type WeaponId = 'pistol' | 'shotgun' | 'rifle' | 'sniper';

export interface WeaponDef {
  id: WeaponId;
  name: string;
  /** For the briefing's loadout row, where every gun has to fit on one line. */
  short: string;
  magSize: number;
  spareMags: number;
  auto: boolean;
  /** Minimum ms between shots. */
  fireDelay: number;
  /** Seconds. */
  reloadTime: number;
  pellets: number;
  /** Pellet spread in degrees either side of the laser. */
  spread: number;
  /** Laser wobble in degrees at full instability. Heavier guns wobble more. */
  wobble: number;
  /** Instability added per shot. */
  recoil: number;
  /** How fast the operator can swing the gun round, degrees per second. */
  turnRate: number;
  /** Noise radius in px, unsuppressed. Gunfire is heard through a whole building. */
  noise: number;
  range: number;
  /** Damage per bullet (per pellet for the shotgun). Vested suspects take 2 to stop. */
  damage: number;
  /** What the gun is good at, for the loadout choice. */
  blurb: string;
  /** Takes a suppressor once one is issued. The shotgun doesn't. */
  suppressible: boolean;
  /** Bolt action: the bolt is worked after every shot, during `fireDelay`. */
  bolt?: boolean;
  /** Has a scope (hold Space): vision and the camera reach far down the aim. */
  scope?: boolean;
}

/** Handling matters as much as damage: heavier guns wobble more and turn more slowly. */
export const WEAPONS: Record<WeaponId, WeaponDef> = {
  pistol: {
    id: 'pistol', name: 'Pistol', short: 'Pistol', magSize: 12, spareMags: 3, auto: false, fireDelay: 140, reloadTime: 1.3,
    pellets: 1, spread: 0, wobble: 2.5, recoil: 0.12, turnRate: 620, noise: 1000, range: 900,
    damage: 1, blurb: 'Accurate and quick to aim. Vested suspects need a double tap.', suppressible: true,
  },
  shotgun: {
    id: 'shotgun', name: 'Shotgun', short: 'Shotgun', magSize: 6, spareMags: 4, auto: false, fireDelay: 650, reloadTime: 2.4,
    pellets: 8, spread: 8, wobble: 4, recoil: 0.4, turnRate: 430, noise: 1200, range: 460,
    damage: 1, blurb: 'Stops anyone up close in one shot. Spread risks civilians. Slow reload.', suppressible: false,
  },
  rifle: {
    id: 'rifle', name: 'Assault rifle', short: 'AR', magSize: 30, spareMags: 3, auto: true, fireDelay: 110, reloadTime: 2.1,
    pellets: 1, spread: 0, wobble: 5, recoil: 0.12, turnRate: 300, noise: 1300, range: 1400,
    damage: 2, blurb: 'One hit stops a vested suspect. Accurate at range, slow to swing.', suppressible: true,
  },
  sniper: {
    id: 'sniper', name: 'Sniper rifle', short: 'Sniper', magSize: 5, spareMags: 3, auto: false, fireDelay: 1250, reloadTime: 3.2,
    pellets: 1, spread: 0, wobble: 7, recoil: 0.9, turnRate: 200, noise: 1600, range: 2600,
    damage: 3, blurb: 'Stops anyone in one hit at any range. Hold Space to scope. Slow bolt action.',
    suppressible: true, bolt: true, scope: true,
  },
};

/** A suppressor cuts how far a shot is heard to this fraction: a few rooms, not the house. */
export const SUPPRESSED_NOISE = 0.15;

export class WeaponState {
  mag: number;
  reserve: number;
  reloadLeft = 0;
  /** Fitted when suppressors are issued and the briefing has them on. */
  suppressed = false;
  private cooldown = 0;

  constructor(public def: WeaponDef) {
    this.mag = def.magSize;
    this.reserve = def.magSize * def.spareMags;
  }

  get reloading(): boolean {
    return this.reloadLeft > 0;
  }

  /** How far this gun's shots are heard right now. */
  get noise(): number {
    return this.def.noise * (this.suppressed ? SUPPRESSED_NOISE : 1);
  }

  update(dt: number): void {
    this.cooldown = Math.max(0, this.cooldown - dt * 1000);
    if (this.reloadLeft > 0) {
      this.reloadLeft -= dt;
      if (this.reloadLeft <= 0) {
        this.reloadLeft = 0;
        const take = Math.min(this.def.magSize - this.mag, this.reserve);
        this.mag += take;
        this.reserve -= take;
      }
    }
  }

  canFire(): boolean {
    return this.cooldown <= 0 && !this.reloading && this.mag > 0;
  }

  fire(): void {
    this.mag--;
    this.cooldown = this.def.fireDelay;
  }

  startReload(): boolean {
    if (this.reloading || this.mag >= this.def.magSize || this.reserve <= 0) return false;
    this.reloadLeft = this.def.reloadTime;
    return true;
  }

  refill(): void {
    this.reserve = this.def.magSize * this.def.spareMags;
  }
}
