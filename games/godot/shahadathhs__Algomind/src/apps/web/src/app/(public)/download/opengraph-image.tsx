import { OG_CONTENT_TYPE, OG_SIZE, renderShareImage } from "@/lib/og";

export const alt = "Download Algomind for Android, with the tile wordmark";
export const size = OG_SIZE;
export const contentType = OG_CONTENT_TYPE;

export default function Image() {
  return renderShareImage({
    title: "Download for Android",
    subtitle: "Install the APK in four steps. Free, offline first, no ads.",
  });
}
