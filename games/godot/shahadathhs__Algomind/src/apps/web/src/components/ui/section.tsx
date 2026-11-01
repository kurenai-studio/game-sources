import type { ReactNode } from "react";
import { Container } from "@/components/ui/container";
import { Reveal } from "@/components/ui/reveal";
import { Rule } from "@/components/ui/rule";

/** A page section: a rule above (unless it opens the page), generous spacing, one column. */
export function Section({
  id,
  rule = true,
  reveal = false,
  children,
  className = "",
}: {
  id?: string;
  rule?: boolean;
  /** Slide in as it scrolls into view (see Reveal). */
  reveal?: boolean;
  children: ReactNode;
  className?: string;
}) {
  return (
    <section id={id} className="scroll-mt-4">
      <Container>
        {rule && <Rule />}
        {reveal ? (
          <Reveal className={`py-12 sm:py-[72px] ${className}`}>{children}</Reveal>
        ) : (
          <div className={`py-12 sm:py-[72px] ${className}`}>{children}</div>
        )}
      </Container>
    </section>
  );
}
