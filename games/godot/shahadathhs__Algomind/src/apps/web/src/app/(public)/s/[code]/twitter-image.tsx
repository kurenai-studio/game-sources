import { OG_CONTENT_TYPE, OG_SIZE } from "@/lib/og";
import { shareImageFor } from "@/lib/share-image";

export const alt = "A result shared from Algomind, with the tile wordmark";
export const size = OG_SIZE;
export const contentType = OG_CONTENT_TYPE;

export default async function Image({ params }: { params: Promise<{ code: string }> }) {
  const { code } = await params;
  return shareImageFor(code);
}
