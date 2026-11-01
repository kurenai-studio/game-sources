import Link from "next/link";
import { MobileNav, type NavItem } from "@/components/public/mobile-nav";
import { ThemeToggle } from "@/components/public/theme-toggle";
import { Container } from "@/components/ui/container";
import { Wordmark } from "@/components/ui/wordmark";

const NAV: readonly NavItem[] = [
  { href: "/levels", label: "Levels" },
  { href: "/how-to-play", label: "How to play" },
  { href: "/play", label: "Play" },
  { href: "/download", label: "Download" },
];

const SECONDARY: readonly NavItem[] = [
  { href: "/privacy", label: "Privacy" },
  { href: "/contact", label: "Contact" },
];

export function SiteHeader() {
  return (
    <header className="site-header">
      <Container className="flex h-[84px] items-center justify-between">
        <Link href="/" aria-label="Algomind home" className="inline-flex min-h-11 items-center">
          <Wordmark />
        </Link>
        <div className="flex items-center gap-2 min-[340px]:gap-3 md:gap-7">
          <nav aria-label="Main" className="hidden items-center gap-7 md:flex">
            {NAV.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className="sweep inline-flex min-h-11 items-center text-sm tracking-[2px] whitespace-nowrap uppercase"
              >
                {item.label}
              </Link>
            ))}
          </nav>
          <ThemeToggle />
          <MobileNav items={NAV} secondary={SECONDARY} />
        </div>
      </Container>
    </header>
  );
}
