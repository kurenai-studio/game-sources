import Link from "next/link";
import type { ReactNode } from "react";

/** A tertiary action: underlined capitals. External links are plain anchors. */
export function TextLink({
  href,
  children,
  external = false,
  className = "",
}: {
  href: string;
  children: ReactNode;
  external?: boolean;
  className?: string;
}) {
  const classes = `thicken inline-flex min-h-11 items-center text-[13px] font-bold tracking-[2px] uppercase underline decoration-2 underline-offset-[6px] ${className}`;
  if (external) {
    return (
      <a href={href} className={classes} rel="noopener">
        {children}
      </a>
    );
  }
  return (
    <Link href={href} className={classes}>
      {children}
    </Link>
  );
}
