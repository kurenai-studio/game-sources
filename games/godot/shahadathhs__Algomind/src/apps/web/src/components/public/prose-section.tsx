import type { ReactNode } from "react";

/**
 * A titled block of body text inside a ProsePage. Paragraphs are the children. On a wide page the title
 * stands in a left column from the lg breakpoint, and an optional `figure` sits beside the text.
 */
export function ProseSection({
  title,
  figure,
  spread = false,
  children,
}: {
  title: string;
  figure?: ReactNode;
  /** Let the text use the whole column on a wide page, for a list that sets itself in columns. */
  spread?: boolean;
  children: ReactNode;
}) {
  return (
    <section className="border-t-2 border-ink pt-5 lg:group-data-[wide]/prose:grid lg:group-data-[wide]/prose:grid-cols-[220px_minmax(0,1fr)] lg:group-data-[wide]/prose:gap-x-10">
      <h2 className="mb-3 text-[22px] leading-tight tracking-[1px] uppercase">{title}</h2>
      <div
        className={
          figure ? "flex flex-col gap-6 lg:flex-row lg:items-start lg:gap-12" : "flex flex-col"
        }
      >
        <div
          className={`flex min-w-0 flex-col ${spread ? "" : "max-w-[680px]"} gap-3 text-base leading-relaxed font-semibold text-mute lg:flex-1 [&_a]:text-ink [&_a]:underline [&_a]:underline-offset-4 [&_li]:pl-1 [&_ul]:list-disc [&_ul]:pl-5`}
        >
          {children}
        </div>
        {figure && (
          <div className="order-first w-full max-w-[320px] flex-none lg:order-last">{figure}</div>
        )}
      </div>
    </section>
  );
}
