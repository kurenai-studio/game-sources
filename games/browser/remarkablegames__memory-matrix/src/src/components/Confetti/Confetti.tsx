const PIECE_COLORS = [
  'bg-sky-400',
  'bg-emerald-400',
  'bg-amber-400',
  'bg-rose-400',
  'bg-violet-400',
] as const;

const PIECE_COUNT = 24;

interface Piece {
  left: number;
  delay: number;
  duration: number;
  color: string;
}

const PIECES: Piece[] = Array.from({ length: PIECE_COUNT }, (_, index) => ({
  left: (index * 37) % 100,
  delay: (index % 8) * 0.15,
  duration: 1.8 + ((index * 7) % 10) / 5,
  color: PIECE_COLORS[index % PIECE_COLORS.length],
}));

function prefersReducedMotion(): boolean {
  return (
    typeof window.matchMedia === 'function' &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches
  );
}

/**
 * Falling confetti shown when the player sets a new record. Hidden
 * entirely when the player prefers reduced motion.
 *
 * @returns The confetti overlay, or nothing when motion is reduced.
 */
export function Confetti() {
  if (prefersReducedMotion()) {
    return null;
  }

  return (
    <div
      aria-hidden="true"
      className="pointer-events-none fixed inset-0 z-50 overflow-hidden"
    >
      {PIECES.map((piece) => (
        <span
          key={piece.left}
          className={`motion-safe:animate-confetti absolute top-0 h-3 w-2 rounded-sm ${piece.color}`}
          style={{
            left: `${String(piece.left)}%`,
            animationDelay: `${String(piece.delay)}s`,
            animationDuration: `${String(piece.duration)}s`,
          }}
        />
      ))}
    </div>
  );
}
