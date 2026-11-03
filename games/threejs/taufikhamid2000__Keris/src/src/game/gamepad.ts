// Gamepad input (standard mapping: Xbox, PlayStation, Steam Deck). Pure helpers; the engine polls navigator.getGamepads().

/** Standard-mapping button index → the key code it acts as. */
export const PAD_KEYS: Record<number, string> = {
  0: "Space", // A / Cross: jump, hold against a wall to climb
  1: "KeyC", // B / Circle: crouch toggle
  2: "KeyE", // X / Square: takedown
  3: "KeyF", // Y / Triangle: carry body
  5: "KeyV", // RB / R1: eagle vision
  7: "KeyQ", // RT / R2: throw knife
};
export const PAD_RUN = [4, 10]; // LB / L1 or left stick click
export const PAD_START = 9;
export const PAD_CONFIRM = 0;
/** Look speed at full right-stick deflection, in mouse pixels per second. */
export const PAD_LOOK_RATE = 900;

export interface PadLike {
  axes: readonly number[];
  buttons: readonly { pressed: boolean; value: number }[];
}

export interface PadState {
  /** x strafe right, y forward, -1..1 */
  move: { x: number; y: number };
  /** x right, y down, -1..1 */
  look: { x: number; y: number };
  buttons: boolean[];
}

/** Radial deadzone, rescaled so output starts at 0 just past the edge. */
export function deadzone(x: number, y: number, dz = 0.15): { x: number; y: number } {
  const m = Math.hypot(x, y);
  if (m <= dz) return { x: 0, y: 0 };
  const k = Math.min(1, (m - dz) / (1 - dz)) / m;
  return { x: x * k, y: y * k };
}

export function readPad(pad: PadLike): PadState {
  const a = (i: number) => pad.axes[i] ?? 0;
  const mv = deadzone(a(0), a(1));
  const lk = deadzone(a(2), a(3));
  // squared response curve: fine aim near centre, fast turns at the edge
  const curve = (v: number) => Math.sign(v) * v * v;
  return {
    move: { x: mv.x, y: -mv.y },
    look: { x: curve(lk.x), y: curve(lk.y) },
    buttons: pad.buttons.map((b) => b.pressed || b.value > 0.5),
  };
}

/** Buttons that went down or up since the previous poll. */
export function diffButtons(prev: readonly boolean[], cur: readonly boolean[]): { down: number[]; up: number[] } {
  const down: number[] = [];
  const up: number[] = [];
  const n = Math.max(prev.length, cur.length);
  for (let i = 0; i < n; i++) {
    const was = !!prev[i];
    const is = !!cur[i];
    if (is && !was) down.push(i);
    if (was && !is) up.push(i);
  }
  return { down, up };
}

/** First connected pad, preferring one with the standard layout. */
export function pickPad<T extends { connected: boolean; mapping: string }>(pads: readonly (T | null)[]): T | null {
  const live = pads.filter((p): p is T => !!p && p.connected);
  return live.find((p) => p.mapping === "standard") ?? live[0] ?? null;
}
