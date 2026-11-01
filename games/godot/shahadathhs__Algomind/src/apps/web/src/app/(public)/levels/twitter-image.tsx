import { OG_CONTENT_TYPE, OG_SIZE, renderShareImage } from "@/lib/og";

export const alt = "Algomind levels, with the tile wordmark";
export const size = OG_SIZE;
export const contentType = OG_CONTENT_TYPE;

export default function Image() {
  return renderShareImage({
    title: "Levels",
    subtitle: "Worlds that each teach one idea, unlocked in order.",
  });
}
