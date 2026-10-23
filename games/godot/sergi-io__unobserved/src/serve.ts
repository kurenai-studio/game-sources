const ROOT = "./build/web"; // cambia esto por la carpeta de tu export web
const PORT = 3000;

const mimeTypes: Record<string, string> = {
  ".html": "text/html",
  ".js": "text/javascript",
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".svg": "image/svg+xml",
  ".ogg": "audio/ogg",
  ".mp3": "audio/mpeg",
  ".wav": "audio/wav",
  ".json": "application/json",
  ".css": "text/css",
};

function getMimeType(path: string): string {
  const ext = path.substring(path.lastIndexOf("."));
  return mimeTypes[ext] ?? "application/octet-stream";
}

Bun.serve({
  port: PORT,

  async fetch(req) {
    const url = new URL(req.url);

    let pathname = decodeURIComponent(url.pathname);
    if (pathname === "/") pathname = "/index.html";

    const filePath = `${ROOT}${pathname}`;
    const file = Bun.file(filePath);

    if (!(await file.exists())) {
      return new Response("Not found", { status: 404 });
    }

    return new Response(file, {
      headers: {
        "Content-Type": getMimeType(filePath),

        // Required for Godot Web exports using SharedArrayBuffer / threads
        "Cross-Origin-Opener-Policy": "same-origin",
        "Cross-Origin-Embedder-Policy": "require-corp",

        // Usually useful for same-origin assets
        "Cross-Origin-Resource-Policy": "same-origin",
      },
    });
  },
});

console.log(`Serving ${ROOT} at http://localhost:${PORT}`);
