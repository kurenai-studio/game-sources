#!/usr/bin/env node
/**
 * Record the cinematic (C mode) to recordings/balloon-ride-cinematic.mp4: 1920x1080, 60 fps, the
 * whole ~50 s path. Deterministic frame stepping: the page runs with its clock frozen, and for
 * every frame we call __game.cinematic.seek(i / 60) (which draws exactly that frame, one fixed 1/60 s
 * step), grab it over CDP as a JPEG and pipe it straight into ffmpeg's stdin, encoded on the GPU
 * with NVENC (h264_nvenc). No frames are written to disk.
 *
 *   node scripts/record.mjs [--nobuild] [--seconds=50] [--time=golden] [--allow-software]
 *
 * Headless Chrome on the discrete GPU (renderer printed and asserted), shader errors fatal, and
 * teardown on every exit path: browser, preview server and the ffmpeg child (scripts/lib/harness.mjs).
 * ffmpeg runs attached at below-normal priority; an interrupted run deletes its partial output.
 */
import fs from "node:fs/promises";
import { existsSync, unlinkSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { assertGpu, bye, fatalShaderErrors, launchBrowser, own, serve } from "./lib/harness.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const argv = process.argv.slice(2);
const arg = (n, d) => {
  const hit = argv.find((a) => a.startsWith(`--${n}=`));
  return hit ? hit.slice(n.length + 3) : d;
};
const W = 1920, H = 1080, FPS = 60;
const TIME = arg("time", "golden");
const OUT_DIR = path.join(ROOT, "recordings");
const OUT = path.join(OUT_DIR, "balloon-ride-cinematic.mp4");
const PART = OUT + ".part.mp4";

function run(cmd, args) {
  return new Promise((res, rej) => {
    const child = spawn(cmd, args, { cwd: ROOT, stdio: "inherit", shell: process.platform === "win32" });
    try { os.setPriority(child.pid, os.constants.priority.PRIORITY_BELOW_NORMAL); } catch {}
    const handle = own({ close: async () => { if (child.exitCode === null) child.kill(); } });
    child.on("error", rej);
    child.on("exit", (code) => {
      handle.close = async () => {};
      code === 0 ? res() : rej(new Error(`${cmd} exited with ${code}`));
    });
  });
}

/** ffmpeg reading JPEG frames from stdin, NVENC out. Owned: teardown kills it and drops the partial file. */
function encoder() {
  const args = [
    "-hide_banner", "-loglevel", "warning", "-y",
    "-f", "image2pipe", "-framerate", String(FPS), "-c:v", "mjpeg", "-i", "-",
    "-c:v", "h264_nvenc", "-preset", "p5", "-cq", "19", "-b:v", "0", "-pix_fmt", "yuv420p",
    "-r", String(FPS), "-movflags", "+faststart", PART,
  ];
  const ff = spawn("ffmpeg", args, { cwd: ROOT, stdio: ["pipe", "inherit", "inherit"] });
  try { os.setPriority(ff.pid, os.constants.priority.PRIORITY_BELOW_NORMAL); } catch {}
  const done = new Promise((res, rej) => {
    ff.on("error", rej);
    ff.on("exit", (code) => (code === 0 ? res() : rej(new Error(`ffmpeg exited with ${code}`))));
  });
  const handle = own({
    close: async () => {
      if (ff.exitCode === null) {
        try { ff.stdin.destroy(); } catch {}
        ff.kill();
        await new Promise((r) => setTimeout(r, 300));
      }
      try { if (existsSync(PART)) unlinkSync(PART); } catch {}
    },
  });
  const write = (buf) => new Promise((res, rej) => (ff.stdin.write(buf, (e) => (e ? rej(e) : res()))));
  const end = async () => {
    ff.stdin.end();
    await done;
    handle.close = async () => {};
  };
  return { write, end };
}

await fs.mkdir(OUT_DIR, { recursive: true });
if (!argv.includes("--nobuild")) await run("pnpm", ["build"]);
const URL = await serve(ROOT, "preview", 5440);
console.log(`[serve] preview ${URL}`);

const browser = await launchBrowser(["--hide-scrollbars", "--mute-audio"]);
const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
const page = await ctx.newPage();
fatalShaderErrors(page, "record");
const errors = [];
page.on("pageerror", (e) => errors.push(`pageerror: ${e.message}`));
page.on("console", (m) => {
  if (m.type() === "error") errors.push(`console error: ${m.text().slice(0, 400)}`);
});
// res=1: no adaptive resolution (slow captured frames would otherwise lower it).
await page.goto(`${URL}?cinematic=1&time=${TIME}&seed=1&t=12&capture=1&res=1`, { waitUntil: "load" });
await assertGpu(page);
await page.waitForFunction(() => !!window.__game, null, { timeout: 300_000, polling: 100 });
await page.evaluate(() => window.__game.ready);
console.log(`[record] in-page renderer: ${await page.evaluate(() => window.__game.renderer())}`);
const dur = await page.evaluate(() => window.__game.cinematic.duration);
const seconds = Math.min(dur, Number(arg("seconds", String(dur))));
const N = Math.round(seconds * FPS);
console.log(`[record] ${N} frames (${seconds} s at ${FPS} fps) -> ${path.relative(ROOT, OUT)}`);

const cdp = await ctx.newCDPSession(page);
const enc = encoder();
// Warm up: a few frames at t = 0 so every pass (shadows, reflections) has settled.
for (let i = 0; i < 4; i++) await page.evaluate(() => window.__game.cinematic.seek(0));
const t0 = Date.now();
for (let i = 0; i < N; i++) {
  await page.evaluate((s) => window.__game.cinematic.seek(s), i / FPS);
  const { data } = await cdp.send("Page.captureScreenshot", { format: "jpeg", quality: 94, captureBeyondViewport: false });
  await enc.write(Buffer.from(data, "base64"));
  if (errors.length) await bye(1, `page errors while recording:\n  ${errors.join("\n  ")}`);
  if (i % 300 === 299) {
    const el = (Date.now() - t0) / 1000;
    console.log(`  ${i + 1}/${N} frames, ${(el / (i + 1) * 1000).toFixed(0)} ms/frame, ~${Math.round((el / (i + 1)) * (N - i - 1))} s left`);
  }
}
await enc.end();
await fs.rename(PART, OUT);
console.log(`[record] wrote ${path.relative(ROOT, OUT)} in ${((Date.now() - t0) / 1000).toFixed(0)} s`);
await bye(0);
