import { qrMatrix, qrPath } from "@/lib/qr";

const QUIET = 2;

/**
 * A QR code as inline SVG, generated on the server at build time (no client code, no image).
 * Dark modules use the `qr-dark` color and the quiet zone `qr-light`; see globals.css, which keeps
 * the pair high-contrast in both themes so phones can scan it.
 */
export function QrCode({ text, label }: { text: string; label: string }) {
  const matrix = qrMatrix(text);
  const size = matrix.size + QUIET * 2;
  return (
    <svg
      viewBox={`0 0 ${size} ${size}`}
      role="img"
      aria-label={label}
      className="block h-auto w-full"
      shapeRendering="crispEdges"
    >
      <rect width={size} height={size} className="qr-light" />
      <path d={qrPath(matrix)} transform={`translate(${QUIET} ${QUIET})`} className="qr-dark" />
    </svg>
  );
}
