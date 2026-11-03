#!/usr/bin/env node
/**
 * Evaluate a JS expression in the built game page (debug helper): node scripts/probe.mjs "<expr>" [--nobuild]
 * Serves dist/ with vite preview, launches the GPU browser (asserted), waits for __game.ready, prints the result.
 */
import path from "node:path";
import { fileURLToPath } from "node:url";
import { assertGpu, bye, fatalShaderErrors, launchBrowser, serve } from "./lib/harness.mjs";
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const expr = process.argv.slice(2).find((a) => !a.startsWith("--"));
const URL = await serve(ROOT, "preview", 5440);
const browser = await launchBrowser(["--hide-scrollbars", "--mute-audio"]);
const page = await (await browser.newContext({ viewport: { width: 1600, height: 900 } })).newPage();
fatalShaderErrors(page, "probe");
page.on("console", (m) => { if (m.type() === "error" || m.type() === "warning") console.log("[console]", m.text().slice(0, 300)); });
await page.goto(`${URL}?time=golden&seed=1&t=12&capture=1`, { waitUntil: "load" });
await assertGpu(page);
await page.waitForFunction(() => !!window.__game, null, { timeout: 300_000 });
await page.evaluate(() => window.__game.ready);
const out = await page.evaluate(`(async () => { const g = window.__game; return (${expr}); })()`);
console.log(JSON.stringify(out, null, 1));
const shot = process.argv.find((a) => a.startsWith("--shot="));
if (shot) {
  await page.evaluate(() => window.__game.frames(8));
  await page.screenshot({ path: shot.slice(7) });
  console.log("[shot]", shot.slice(7));
}
await bye(0);
