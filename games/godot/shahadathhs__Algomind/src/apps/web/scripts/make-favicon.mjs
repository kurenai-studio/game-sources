// Packs PNG files into src/app/favicon.ico (PNG-compressed ICO entries).
// The mark is drawn by src/lib/brand.tsx; render it at 16, 32 and 48 px (for example by
// downscaling /pwa-icon/512 from a running server with `sips -z 16 16`) and run:
//   node scripts/make-favicon.mjs icon-16.png icon-32.png icon-48.png
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const files = process.argv.slice(2);
if (files.length === 0) {
  console.error("usage: node scripts/make-favicon.mjs <png>...");
  process.exit(1);
}

const images = files.map((file) => {
  const data = readFileSync(file);
  if (data.readUInt32BE(0) !== 0x89504e47) throw new Error(`${file} is not a PNG`);
  return { data, width: data.readUInt32BE(16), height: data.readUInt32BE(20) };
});

const header = Buffer.alloc(6);
header.writeUInt16LE(1, 2); // type: icon
header.writeUInt16LE(images.length, 4);

let offset = 6 + 16 * images.length;
const entries = images.map(({ data, width, height }) => {
  const entry = Buffer.alloc(16);
  entry.writeUInt8(width >= 256 ? 0 : width, 0);
  entry.writeUInt8(height >= 256 ? 0 : height, 1);
  entry.writeUInt16LE(1, 4); // color planes
  entry.writeUInt16LE(32, 6); // bits per pixel
  entry.writeUInt32LE(data.length, 8);
  entry.writeUInt32LE(offset, 12);
  offset += data.length;
  return entry;
});

const out = join(dirname(fileURLToPath(import.meta.url)), "..", "src", "app", "favicon.ico");
writeFileSync(out, Buffer.concat([header, ...entries, ...images.map((i) => i.data)]));
console.log(`wrote ${out}`);
