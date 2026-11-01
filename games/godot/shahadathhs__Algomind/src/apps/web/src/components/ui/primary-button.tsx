import Link from "next/link";
import type { ReactNode } from "react";
import { Key } from "@/components/ui/key";

/** The one primary action on a screen: a signal-yellow tile link, full width on phones. */
export function PrimaryButton({
  href,
  children,
  external = false,
  icon,
  size = "lg",
  className = "",
}: {
  href: string;
  children: ReactNode;
  /** A direct file or off-site link; rendered as a plain anchor. */
  external?: boolean;
  icon?: ReactNode;
  size?: "md" | "lg";
  className?: string;
}) {
  // Smaller type and padding on phones so the label stays on one line; full size from sm up.
  const classes = `tile inline-flex w-full items-center justify-center gap-2.5 bg-signal tracking-[1.5px] text-on-signal sm:tracking-[2px] ${
    size === "lg"
      ? "h-16 px-4 text-[18px] sm:px-8 sm:text-[22px]"
      : "h-14 px-4 text-base sm:px-6 sm:text-lg"
  }`;
  const style = { ["--chamfer" as string]: size === "lg" ? "14px" : "12px" };
  const content = (
    <>
      {icon}
      <span className="uppercase">{children}</span>
    </>
  );
  return (
    <Key tone="signal" className={className}>
      {external ? (
        <a href={href} className={classes} style={style} rel="noopener">
          {content}
        </a>
      ) : (
        <Link href={href} className={classes} style={style}>
          {content}
        </Link>
      )}
    </Key>
  );
}
