import { ImageResponse } from "next/og";
import { Mark } from "@/lib/brand";

// The browser-tab icon (32 px). favicon.ico carries 16, 32 and 48 px of the same tile.
export const size = { width: 32, height: 32 };
export const contentType = "image/png";

export default function Icon() {
  return new ImageResponse(<Mark size={size.width} />, { ...size });
}
