#!/usr/bin/env node
/**
 * Phone check: the built game under Playwright device emulation (iPhone 13, portrait and landscape:
 * touch, coarse pointer, phone user agent, so the phone tier and the touch buttons are on), headless
 * on the discrete GPU (renderer printed and asserted). Writes shots/<name>/mobile_portrait.png and
 * mobile_landscape.png, and holds the burner button for a moment to check it lights the flame.
 *
 *   node scripts/mobile.mjs <name> [--nobuild]
 */
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { devices } from "playwright";
import { assertGpu, bye, fatalShaderErrors, launchBrowser, own, serve } from "./lib/harness.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const argv = process.argv.slice(2);
const NAME = argv.find((a) => !a.startsWith("--")) ?? "mobile";
const OUT = path.join(ROOT, "shots", NAME);

function build() {
  return new Promise((res, rej) => {
    const child = spawn("pnpm", ["build"], { cwd: ROOT, stdio: "inherit", shell: process.platform === "win32" });
    try { os.setPriority(child.pid, os.constants.priority.PRIORITY_BELOW_NORMAL); } catch {}
    const handle = own({ close: async () => { if (child.exitCode === null) child.kill(); } });
    child.on("error", rej);
    child.on("exit", (code) => {
      handle.close = async () => {};
      code === 0 ? res() : rej(new Error(`pnpm build exited with ${code}`));
    });
  });
}

await fs.mkdir(OUT, { recursive: true });
if (!argv.includes("--nobuild")) await build();
const URL = await serve(ROOT, "preview", 5440);
const browser = await launchBrowser(["--hide-scrollbars", "--mute-audio"]);
const errors = [];
let checked = false;
for (const [tag, dev] of [["portrait", devices["iPhone 13"]], ["landscape", devices["iPhone 13 landscape"]]]) {
  const ctx = await browser.newContext({ ...dev });
  const page = await ctx.newPage();
  fatalShaderErrors(page, tag);
  page.on("pageerror", (e) => errors.push(`[${tag}] pageerror: ${e.message}`));
  page.on("console", (m) => m.type() === "error" && errors.push(`[${tag}] ${m.text().slice(0, 300)}`));
  await page.goto(`${URL}?time=golden&seed=1&t=12&capture=1`, { waitUntil: "load" });
  if (!checked) {
    await assertGpu(page);
    checked = true;
  }
  await page.waitForFunction(() => !!window.__game, null, { timeout: 300_000, polling: 100 });
  await page.evaluate(() => window.__game.ready);
  const info = await page.evaluate(() => ({ w: innerWidth, h: innerHeight, dpr: devicePixelRatio, canvas: [document.querySelector("canvas").width, document.querySelector("canvas").height], buttons: document.querySelectorAll("[data-btn]").length }));
  console.log(`[${tag}] viewport ${info.w}x${info.h} dpr ${info.dpr}, canvas ${info.canvas.join("x")}, ${info.buttons} touch buttons`);
  // Hold the burner button (bottom left) for a moment: the flame must light.
  const b = await page.$('[aria-label="burner"]');
  const box = await b.boundingBox();
  await page.touchscreen.tap(box.x + box.width / 2, box.y + box.height / 2);
  await page.dispatchEvent('[aria-label="burner"]', "pointerdown", { pointerId: 7, pointerType: "touch", isPrimary: true });
  await page.evaluate(() => window.__game.frames(20));
  const flame = await page.evaluate(() => window.__game.ride.player.flame.level);
  await page.screenshot({ path: path.join(OUT, `mobile_${tag}.png`) });
  await page.dispatchEvent('[aria-label="burner"]', "pointerup", { pointerId: 7, pointerType: "touch", isPrimary: true });
  console.log(`[${tag}] burner held: flame ${flame.toFixed(2)} -> shots/${NAME}/mobile_${tag}.png`);
  if (flame < 0.5) errors.push(`[${tag}] the burner button did not light the flame (${flame})`);
  await ctx.close();
}
if (errors.length) console.error("errors:\n  " + errors.join("\n  "));
await bye(errors.length ? 1 : 0);
