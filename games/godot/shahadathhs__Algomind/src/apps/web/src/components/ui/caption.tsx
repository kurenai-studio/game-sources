import type { ReactNode } from "react";

/** A small capitalised label. Use `as="h2"` when it also names a section. */
export function Caption({
  as: Tag = "p",
  children,
  className = "",
}: {
  as?: "p" | "h2" | "h3";
  children: ReactNode;
  className?: string;
}) {
  return (
    <Tag className={`text-xs font-bold tracking-[2px] text-mute uppercase ${className}`}>
      {children}
    </Tag>
  );
}
