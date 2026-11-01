import { TOKEN_COLORS } from "@/lib/token-colors.generated";

/**
 * The Algomind mark: one chamfered signal-yellow tile with an ink "A" (the first tile of the
 * wordmark). Drawn as paths on a 64 unit grid, not set in a font, so it renders the same
 * everywhere and stays heavy enough to read at 16 px. Colors come from the design tokens.
 */
export const MARK_TILE = "M0 0H48L64 16V64H0Z";
// Outer shape of the A and its counter (filled with the even-odd rule).
export const MARK_LETTER = "M25 11H39L56 53H43.5L40.5 45H23.5L20.5 53H8Z M32 23L27.5 35H36.5Z";

type Theme = "light" | "dark";

/**
 * The mark as an SVG element for ImageResponse.
 * "any" is the tile on a transparent ground. "maskable" fills the whole canvas with yellow and
 * keeps the letter inside the 80 percent safe zone, because the OS crops the icon to its own shape.
 */
export function Mark({
  size,
  variant = "any",
  theme = "light",
}: {
  size: number;
  variant?: "any" | "maskable";
  theme?: Theme;
}) {
  const colors = TOKEN_COLORS[theme];
  if (variant === "maskable") {
    return (
      <svg width={size} height={size} viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
        <rect width="64" height="64" fill={colors.signal} />
        <g transform="translate(12.8 12.8) scale(0.6)">
          <path d={MARK_LETTER} fill={colors.onSignal} fillRule="evenodd" />
        </g>
      </svg>
    );
  }
  return (
    <svg width={size} height={size} viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
      <path d={MARK_TILE} fill={colors.signal} />
      <path d={MARK_LETTER} fill={colors.onSignal} fillRule="evenodd" />
    </svg>
  );
}
