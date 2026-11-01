import { ImageResponse } from "next/og";
import { Mark } from "@/lib/brand";

// iOS masks the icon itself and fills transparency with black, so this one is full bleed:
// the maskable artwork (yellow ground, ink A).
export const size = { width: 180, height: 180 };
export const contentType = "image/png";

export default function AppleIcon() {
  return new ImageResponse(<Mark size={size.width} variant="maskable" />, { ...size });
}
