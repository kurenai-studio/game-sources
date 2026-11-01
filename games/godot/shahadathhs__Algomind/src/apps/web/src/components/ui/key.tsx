import type { ReactNode } from "react";

export type KeyTone = "tile" | "signal" | "ink";

/**
 * A key in the depth look. The wrapper shows the lip and casts the soft shadow (a drop-shadow
 * cannot follow a clip-path, so it cannot sit on the face); its child is the face, a `.tile` that
 * carries the chamfer and the fill. A pressed key sinks onto its lip (see globals.css).
 */
export function Key({
  tone = "tile",
  lip = 4,
  className = "",
  children,
}: {
  tone?: KeyTone;
  /** The thickness of the lip in px; small keys use less. */
  lip?: number;
  className?: string;
  children: ReactNode;
}) {
  return (
    <span className={`key key-${tone} ${className}`} style={{ ["--lip" as string]: `${lip}px` }}>
      {children}
    </span>
  );
}
