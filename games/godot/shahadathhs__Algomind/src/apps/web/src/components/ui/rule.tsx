/** A 2 px ink rule. Sections are separated by rules and spacing, never boxes. */
export function Rule({ className = "" }: { className?: string }) {
  return <hr className={`h-0.5 border-0 bg-ink ${className}`} />;
}
