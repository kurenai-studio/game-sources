import type { Dir } from "@/lib/board";

/**
 * The camera of the depth board, the same one the game uses (apps/game/scripts/ui/board_projection.gd):
 * a fixed camera tilted by `pitch` degrees with a little perspective, steeper and flatter as the
 * board grows so a big board stays readable. Pure geometry; the unit is a cell, scaled by UNIT.
 */

/** Heights of the pieces, in cells. */
export const Z = { plate: -0.4, floor: 0.12, goal: 0.24, wall: 0.62, automaton: 0.5, top: 0.72 };

/** Screen units per cell before the drawing is fitted to its box. */
export const UNIT = 60;
const PLATE_MARGIN = 0.3;
const CAMERA_DISTANCE = 1.4;

export type Pt = readonly [number, number];

export function cameraFor(cols: number, rows: number): { pitch: number; perspective: number } {
  const t = Math.min(1, Math.max(0, (Math.max(cols, rows) - 6) / 6));
  return { pitch: 62 + 18 * t, perspective: 0.06 - 0.04 * t };
}

/** East is 0, south a quarter turn; the wedge of the automaton uses it. */
export const DIR_VECTOR: Record<Dir, Pt> = { N: [0, -1], E: [1, 0], S: [0, 1], W: [-1, 0] };

export class BoardProjection {
  readonly perspective: number;
  private readonly sin: number;
  private readonly cos: number;
  private readonly camera: Pt;

  constructor(
    readonly cols: number,
    readonly rows: number,
  ) {
    const { pitch, perspective } = cameraFor(cols, rows);
    this.perspective = perspective;
    this.sin = Math.sin((pitch * Math.PI) / 180);
    this.cos = Math.cos((pitch * Math.PI) / 180);
    this.camera = [0, rows / 2 + CAMERA_DISTANCE];
  }

  /** The screen point of a board point (x east, y south, z up), in UNIT-scaled units. */
  project(x: number, y: number, z: number): Pt {
    const rx = x - this.cols / 2;
    const ry = y - this.rows / 2;
    const f = 1 / (1 - this.perspective * (ry * this.sin + z * this.cos));
    return [rx * f * UNIT, (ry * this.sin - z * this.cos) * f * UNIT];
  }

  /** Smaller is farther from the camera, so an ascending sort paints far to near. */
  depth(x: number, y: number): number {
    return -Math.hypot(x - this.cols / 2 - this.camera[0], y - this.rows / 2 - this.camera[1]);
  }

  /** Is the vertical face through (px, py) with outward normal (nx, ny) seen by the camera? */
  sees(px: number, py: number, nx: number, ny: number): boolean {
    const dx = this.camera[0] - (px - this.cols / 2);
    const dy = this.camera[1] - (py - this.rows / 2);
    return nx * dx + ny * dy > 0.001;
  }

  /** The box that holds the plate, the tallest piece and the shadows, for a viewBox. */
  bounds(): { x: number; y: number; width: number; height: number } {
    const xs: number[] = [];
    const ys: number[] = [];
    for (const cx of [-PLATE_MARGIN, this.cols + PLATE_MARGIN]) {
      for (const cy of [-PLATE_MARGIN, this.rows + PLATE_MARGIN]) {
        for (const z of [Z.plate - 0.25, Z.top]) {
          const [px, py] = this.project(cx, cy, z);
          xs.push(px);
          ys.push(py);
        }
      }
    }
    const pad = UNIT * 0.2;
    const x = Math.min(...xs) - pad;
    const y = Math.min(...ys) - pad;
    return { x, y, width: Math.max(...xs) + pad - x, height: Math.max(...ys) + pad - y };
  }
}
