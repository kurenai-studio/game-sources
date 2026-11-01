import { ImageResponse } from "next/og";
import { Mark } from "@/lib/brand";

// Manifest icons: /pwa-icon/192, /pwa-icon/512, /pwa-icon/maskable-192, /pwa-icon/maskable-512.
export const dynamic = "force-static";

const VARIANTS = ["192", "512", "maskable-192", "maskable-512"] as const;

export function generateStaticParams() {
  return VARIANTS.map((variant) => ({ variant }));
}

export async function GET(_request: Request, { params }: { params: Promise<{ variant: string }> }) {
  const { variant } = await params;
  const match = /^(maskable-)?(192|512)$/.exec(variant);
  if (!match) return new Response("Not found", { status: 404 });
  const px = Number(match[2]);
  return new ImageResponse(<Mark size={px} variant={match[1] ? "maskable" : "any"} />, {
    width: px,
    height: px,
  });
}
