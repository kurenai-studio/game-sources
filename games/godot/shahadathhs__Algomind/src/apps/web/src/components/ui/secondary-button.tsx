import Link from "next/link";
import type { ReactNode } from "react";
import { Key } from "@/components/ui/key";

/** A secondary action: a light key with the top-right corner cut. */
export function SecondaryButton({ href, children }: { href: string; children: ReactNode }) {
  return (
    <Key>
      <Link
        href={href}
        className="tile flex h-14 w-full items-center bg-tile px-6 text-base tracking-[2px] uppercase"
        style={{ ["--chamfer" as string]: "12px" }}
      >
        {children}
      </Link>
    </Key>
  );
}
