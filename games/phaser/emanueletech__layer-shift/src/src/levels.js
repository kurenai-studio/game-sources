// Print queue for the night shift. Rows are listed TOP to BOTTOM as they look on the blueprint;
// the game prints them bottom-up. '#' = filament, '.' = empty. Every row is COLS wide.
export const COLS = 12;

export const LEVELS = [
  {
    id: 'cube',
    name: 'Calibration Cube',
    hint: 'Line up each layer with the blueprint. Left Shift ⟵  ·  Right Shift ⟶',
    layerTime: 3.2,
    maxOffset: 2,
    guide: true,
    rows: [
      '...######...',
      '...######...',
      '...######...',
      '...##..##...',
      '...##..##...',
      '...######...',
      '...######...',
      '...######...',
    ],
  },
  {
    id: 'vase',
    name: 'Spiral Vase',
    hint: 'Thin walls: a layer printed over air turns into spaghetti.',
    layerTime: 2.6,
    maxOffset: 3,
    guide: false,
    rows: [
      '..##....##..',
      '...#....#...',
      '....#..#....',
      '....#..#....',
      '...#....#...',
      '..#......#..',
      '..#......#..',
      '..#......#..',
      '...#....#...',
      '...######...',
      '....####....',
    ],
  },
  {
    id: 'rocket',
    name: 'Launch Rocket',
    hint: 'Last job of the night. Print it clean and it might just fly.',
    layerTime: 2.2,
    maxOffset: 3,
    guide: false,
    rows: [
      '.....##.....',
      '.....##.....',
      '....####....',
      '....####....',
      '....####....',
      '....#..#....',
      '....#..#....',
      '....####....',
      '....####....',
      '...######...',
      '..########..',
      '..#.####.#..',
      '..#..##..#..',
    ],
  },
];

// Bottom-up array of boolean rows.
export function layersOf(level) {
  return level.rows.slice().reverse().map((r) => [...r].map((c) => c === '#'));
}
