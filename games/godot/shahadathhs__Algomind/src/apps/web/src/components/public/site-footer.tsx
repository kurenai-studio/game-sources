import Link from "next/link";
import { Container } from "@/components/ui/container";
import { Rule } from "@/components/ui/rule";

const LINKS = [
  { href: "/play", label: "Play in browser" },
  { href: "/privacy", label: "Privacy" },
  { href: "/contact", label: "Contact" },
];

export function SiteFooter() {
  return (
    <footer>
      <Container className="pb-8">
        <Rule />
        <div className="flex flex-wrap items-center justify-between gap-x-6 pt-4 text-[13px] tracking-[2px] text-mute uppercase">
          <nav aria-label="Footer" className="flex gap-6">
            {LINKS.map((link) => (
              <Link key={link.href} href={link.href} className="inline-flex min-h-11 items-center">
                {link.label}
              </Link>
            ))}
          </nav>
          <span>© 2026 Algomind</span>
        </div>
      </Container>
    </footer>
  );
}
