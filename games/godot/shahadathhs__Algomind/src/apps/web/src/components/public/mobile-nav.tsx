"use client";

import Link from "next/link";
import { Key } from "@/components/ui/key";
import { usePathname } from "next/navigation";
import { useEffect, useRef } from "react";

export type NavItem = { href: string; label: string };

/**
 * The navigation drawer for phones. It is a <details> element, so it opens and closes with no
 * JavaScript; this component only adds closing after a navigation and on Escape. The menu button
 * is a tile drawn inside a plain <summary> (see globals.css for why the summary has no clip-path
 * and no stacking context of its own).
 */
export function MobileNav({
  items,
  secondary,
}: {
  items: readonly NavItem[];
  secondary: readonly NavItem[];
}) {
  const details = useRef<HTMLDetailsElement>(null);
  const pathname = usePathname();

  const close = () => details.current?.removeAttribute("open");

  // The header stays mounted while the page changes, so close the drawer on every navigation.
  useEffect(() => {
    details.current?.removeAttribute("open");
  }, [pathname]);

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") details.current?.removeAttribute("open");
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  return (
    <details ref={details} className="mobile-nav group md:hidden">
      <summary
        aria-label="Menu"
        className="inline-flex h-11 w-11 list-none items-center justify-center [&::-webkit-details-marker]:hidden"
      >
        {/* Above the panel (z-60 vs 50) so the same button shows a close icon while open. */}
        <Key tone="ink" lip={3} className="relative z-[60]">
          <span
            aria-hidden="true"
            className="tile flex h-11 w-11 items-center justify-center bg-ink text-on-ink"
            style={{ ["--chamfer" as string]: "10px" }}
          >
            <svg
              viewBox="0 0 24 24"
              width="22"
              height="22"
              fill="none"
              stroke="currentColor"
              className="group-open:hidden"
            >
              <path d="M4 7h16M4 12h16M4 17h16" strokeWidth="2.8" strokeLinecap="square" />
            </svg>
            <svg
              viewBox="0 0 24 24"
              width="22"
              height="22"
              fill="none"
              stroke="currentColor"
              className="hidden group-open:block"
            >
              <path d="M5 5l14 14M19 5L5 19" strokeWidth="2.8" strokeLinecap="square" />
            </svg>
          </span>
        </Key>
      </summary>
      <div className="fixed inset-y-0 right-0 z-50 flex w-[min(20rem,85vw)] flex-col border-l-2 border-ink bg-ground px-6 pt-6 pb-8">
        <p className="mb-12 text-xs tracking-[2px] text-mute uppercase">Menu</p>
        <nav aria-label="Menu links">
          <ul>
            {items.map((item) => (
              <li key={item.href} className="border-t-2 border-ink last:border-b-2">
                <Link
                  href={item.href}
                  onClick={close}
                  className="flex min-h-14 items-center text-[22px] tracking-[2px] uppercase"
                >
                  {item.label}
                </Link>
              </li>
            ))}
          </ul>
        </nav>
        <ul className="mt-auto flex gap-6 pt-8">
          {secondary.map((item) => (
            <li key={item.href}>
              <Link
                href={item.href}
                onClick={close}
                className="inline-flex min-h-11 items-center text-[13px] tracking-[2px] text-mute uppercase"
              >
                {item.label}
              </Link>
            </li>
          ))}
        </ul>
      </div>
    </details>
  );
}
