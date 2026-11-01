/**
 * Visual variants of a tile. Class names are written out in full so Tailwind finds them; the
 * colors behind them come from the design tokens only.
 *
 * - solid: executed, solved (ink)
 * - signal: current, the primary action (yellow)
 * - outline: upcoming, on a `floor` fill
 * - ghost: secondary button, on a `ground` fill
 * - faint: locked
 * - dashed: empty slot, not downloaded
 */
export type TileVariant = "solid" | "signal" | "outline" | "ghost" | "faint" | "dashed";

export const TILE_FILL: Record<TileVariant, string> = {
  solid: "fill-ink",
  signal: "fill-signal",
  outline: "fill-ink",
  ghost: "fill-ink",
  faint: "fill-faint",
  dashed: "fill-none",
};

export const TILE_INNER_FILL: Partial<Record<TileVariant, string>> = {
  outline: "fill-floor",
  ghost: "fill-ground",
  faint: "fill-ground",
};

/** Fill and stroke classes for content (icons, text) drawn on a tile of this variant. */
export const TILE_TONE: Record<TileVariant, string> = {
  solid: "fill-on-ink stroke-on-ink",
  signal: "fill-on-signal stroke-on-signal",
  outline: "fill-ink stroke-ink",
  ghost: "fill-ink stroke-ink",
  faint: "fill-faint stroke-faint",
  dashed: "fill-slot stroke-slot",
};
