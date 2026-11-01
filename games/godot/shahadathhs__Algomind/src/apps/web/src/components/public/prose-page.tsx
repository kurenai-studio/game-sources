import type { ReactNode } from "react";
import { Container } from "@/components/ui/container";

/**
 * A plain text page: a heading, a short lead, and sections. By default the text sits in one readable
 * column. A `wide` page lets each section use the page width: its title on the left and its text
 * beside any figure (see ProseSection).
 */
export function ProsePage({
  title,
  lead,
  wide = false,
  children,
}: {
  title: string;
  lead?: string;
  wide?: boolean;
  children: ReactNode;
}) {
  return (
    <Container className="pt-6 pb-16 sm:pb-24">
      <div data-wide={wide || undefined} className="group/prose">
        <div className="max-w-[680px]">
          <h1 className="rise text-[40px] leading-none tracking-[1px] uppercase sm:text-[56px]">
            {title}
          </h1>
          {lead && (
            <p className="mt-5 text-lg leading-normal font-semibold tracking-[0.3px] text-mute">
              {lead}
            </p>
          )}
        </div>
        <div className={`mt-10 flex flex-col gap-10 ${wide ? "" : "max-w-[680px]"}`}>
          {children}
        </div>
      </div>
    </Container>
  );
}
