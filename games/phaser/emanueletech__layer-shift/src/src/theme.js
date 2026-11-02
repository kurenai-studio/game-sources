// Shared look: sizes, palette and fonts.
export const W = 960;
export const H = 540;

export const CW = 26;   // cell width (one filament "bit")
export const CH = 14;   // cell height (one layer)

export const C = {
  bg0: 0x06080d,
  bg1: 0x0d1420,
  panel: 0x101826,
  panelEdge: 0x22324a,
  frame: 0x2a3446,
  frameHi: 0x4a5a74,
  steel: 0x8b97ab,
  green: 0x2ee66b,
  greenDark: 0x0f8f3d,
  greenGlow: 0x5cff95,
  amber: 0xffb020,
  hot: 0xff6a2a,
  red: 0xff4d5e,
  blueprint: 0x0d2c52,
  blueprintLine: 0x2f6db3,
  blueprintInk: 0xcfe3ff,
  white: 0xffffff,
  text: 0xe6edf6,
  muted: 0x8a97ab,
};

export const hex = (n) => '#' + n.toString(16).padStart(6, '0');

export const FONT = {
  display: 'Poppins, "Segoe UI", Arial, sans-serif',
  mono: 'PrinterMono, "DejaVu Sans Mono", Menlo, monospace',
};

export function txt(scene, x, y, str, size, color = C.text, opts = {}) {
  return scene.add.text(x, y, str, {
    fontFamily: opts.mono ? FONT.mono : FONT.display,
    fontStyle: opts.weight ?? '700',
    fontSize: `${size}px`,
    color: hex(color),
    align: opts.align ?? 'left',
    letterSpacing: opts.spacing ?? 0,
    stroke: opts.stroke,
    strokeThickness: opts.strokeThickness ?? 0,
  }).setOrigin(opts.ox ?? 0, opts.oy ?? 0);
}
