import type { ButtonHTMLAttributes, ReactNode } from "react";

/** A small underlined text action (tertiary): Up, Down, Rename, Delete, and the like. */
export function TextAction({
  children,
  ...button
}: ButtonHTMLAttributes<HTMLButtonElement> & { children: ReactNode }) {
  return (
    <button
      type="button"
      className="inline-flex min-h-11 items-center text-[13px] font-bold tracking-[2px] uppercase underline decoration-2 underline-offset-[6px] disabled:text-mute disabled:no-underline"
      {...button}
    >
      {children}
    </button>
  );
}
