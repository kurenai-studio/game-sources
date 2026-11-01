import { OG_CONTENT_TYPE, OG_SIZE, renderShareImage } from "@/lib/og";

export const alt =
  "Algomind: a strip of instruction tiles, the first one yellow, and the tile wordmark";
export const size = OG_SIZE;
export const contentType = OG_CONTENT_TYPE;

export default function Image() {
  return renderShareImage({
    title: "A programming puzzle for Android",
    subtitle: "Offline first. No ads. No purchases.",
  });
}
