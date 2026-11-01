import type { ReactNode } from "react";

/** The page column: 1120 wide with 32 of side padding (20 on phones). */
export function Container({
  children,
  className = "",
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <div className={`mx-auto w-full max-w-[1120px] px-4 min-[340px]:px-5 sm:px-8 ${className}`}>
      {children}
    </div>
  );
}
