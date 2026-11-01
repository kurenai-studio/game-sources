import QRCode from "qrcode";
import { siteUrl } from "@/lib/site";

/** The QR code encodes the download page, not the APK, so it never goes stale. */
export function qrPayload(): string {
  return `${siteUrl()}/download`;
}

export type QrMatrix = { size: number; dark: (x: number, y: number) => boolean };

export function qrMatrix(text: string): QrMatrix {
  const qr = QRCode.create(text, { errorCorrectionLevel: "M" });
  const { size, data } = qr.modules;
  return { size, dark: (x, y) => data[y * size + x] === 1 };
}

/** One SVG path: a rectangle per horizontal run of dark modules, in module units. */
export function qrPath(matrix: QrMatrix): string {
  const parts: string[] = [];
  for (let y = 0; y < matrix.size; y++) {
    let x = 0;
    while (x < matrix.size) {
      if (!matrix.dark(x, y)) {
        x++;
        continue;
      }
      const start = x;
      while (x < matrix.size && matrix.dark(x, y)) x++;
      parts.push(`M${start} ${y}h${x - start}v1h${start - x}z`);
    }
  }
  return parts.join("");
}
