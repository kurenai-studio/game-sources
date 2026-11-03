#!/usr/bin/env node
/**
 * Capture the fixed comparison spots on the real GPU (headless ANGLE/D3D11) into
 * shots/<name>/<spot>.png at 1600x900. Adapted from F:\bay-ride\scripts\shoot.mjs.
 *
 *   node scripts/shoot.mjs <name> [--time=golden] [--spots=ground,50m] [--seed=1] [--t=12]
 *                                 [--url=http://localhost:5441/] [--nobuild] [--allow-software]
 *
 * By default it runs `pnpm build`, serves dist/ in-process with vite preview and stops it on exit.
 * --url uses a server you started yourself (left alone). --nobuild skips the build (serves the
 * existing dist/). --time takes a comma list (each time gets its own suffix, golden has none).
 *
 * Every run prints the WebGL renderer and fails on a software rasteriser. Shader compile/link errors
 * are fatal at once, and any other console error, warning or page error fails the run at the end.
 * Teardown (browser, server, build child) runs on every exit path (scripts/lib/harness.mjs).
 */
import fs from "node:fs/promises";
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
const NAME = argv.find((a) => !a.startsWith("--"));
if (!NAME) await bye(2, "usage: node scripts/shoot.mjs <name> [--time=golden] [--spots=...] [--url=...]");
const OUT = path.join(ROOT, "shots", NAME);
const TIMES = arg("time", "golden").split(",").filter(Boolean);
const SEED = arg("seed", "1");
const T = arg("t", "12");
const W = 1600, H = 900;

/**
 * Capture spots. An array is a fixed camera [position, target] (world metres, y up); a string is a
 * script run in the page with `g` = window.__game and `gh(x, z)` = ground height (Phase 3: the
 * spots fly the real balloon; see docs/PROGRESS.md). The village sits at the origin.
 */
// The pilot spots turn the basket so her front takes the golden sun; L(x, y, z) maps basket-frame
// metres (x right, y up, z her front) to world.
const PILOT_FRAME = `const yw = 150 * Math.PI / 180, c = Math.cos(yw), s = Math.sin(yw); g.flight.yaw(150);
    const L = (lx, ly, lz) => [x + lx * c + lz * s, y + ly, z - lx * s + lz * c];`;
const SPOTS = {
  // On the ground near the village, looking up at the balloon 50 m up.
  ground: `const bx = -170, bz = 120; g.flight.place(bx, gh(bx, bz) + 50, bz);
    const cx = -214, cz = 178; g.setCamera([cx, gh(cx, cz) + 1.7, cz], [bx, gh(bx, bz) + 60, bz]);`,
  // Third person at 50 / 200 / 500 m, looking past the balloon toward the village.
  "50m": `const x = -330, z = 300; g.flight.place(x, gh(x, z) + 50, z); g.flight.view("chase"); g.flight.chaseToward(0, 0, 8, 46);`,
  "200m": `const x = -430, z = 470; g.flight.place(x, gh(x, z) + 200, z); g.flight.view("chase"); g.flight.chaseToward(0, 0, 18, 52);`,
  // 500 m: pitched up enough to show the mid cumulus whole (lit crowns over the hills), not sliced
  // by the frame top.
  "500m": `const x = -700, z = 820; g.flight.place(x, gh(x, z) + 500, z); g.flight.view("chase"); g.flight.chaseToward(0, 0, 16, 60);`,
  // The basket view looking straight down from 300 m over the village, with a low wisp below.
  down: `
    return (async () => {
      // Straight down from 300 m: low wisps drifting between the basket and the village, and another
      // one's shadow on the fields. The frozen clock is searched (deterministic) for the moment the
      // drifting wisps line up with this view (the clock only moves drift and small animation).
      const x = 30, z = 25;
      g.flight.place(x, gh(x, z) + 300, z); g.flight.yaw(20); g.flight.view("basket"); g.flight.look(20, -89);
      await g.frames(2);
      const cam = g.camera, v = new cam.position.constructor();
      const scr = (px, py, pz) => { v.set(px, py, pz).project(cam); return [(v.x + 1) / 2, (1 - v.y) / 2]; };
      const L = g.ride.clouds.layers[2], P = L.spec.period, w = L.wind;
      const S = L.mesh.material.uniforms.uCloudLight.value, ly = Math.max(S.y, 0.12);
      const wrap = (a, o) => o + ((((a - o + P / 2) % P) + P) % P) - P / 2;
      const box = (p, x0, x1, y0, y1) => Math.hypot(Math.max(x0 - p[0], 0, p[0] - x1), Math.max(y0 - p[1], 0, p[1] - y1));
      const g0 = gh(x, z);
      let best = [1e9, 12];
      for (let t = 12; t < 15000; t += 0.5) {
        let dA = 1e9, dA2 = 1e9, dB = 1e9;
        for (const c of L.clouds) {
          const cx = wrap(c.x + w.x * t, x), cz = wrap(c.z + w.y * t, z);
          if (Math.abs(cx - x) > 900 || Math.abs(cz - z) > 900) continue;
          const sp = scr(cx, c.base + c.h * 0.4, cz);
          dA = Math.min(dA, box(sp, 0.16, 0.3, 0.2, 0.38));
          dA2 = Math.min(dA2, box(sp, 0.42, 0.92, 0.04, 0.42));
          const yc = c.base + c.h * 0.4 - 15;
          dB = Math.min(dB, box(scr(cx - (S.x / ly) * yc, g0, cz - (S.z / ly) * yc), 0.74, 0.95, 0.06, 0.34));
        }
        const d = 3 * dA + dB + dA2;
        if (d < best[0]) best = [d, t];
        if (d === 0) break;
      }
      g.setClock(best[1]);
      return best;
    })();`,
  // The V view at 250 m, looking out and down toward the village.
  basket: `const x = -260, z = 240; g.flight.place(x, gh(x, z) + 250, z); g.flight.yaw(-47); g.flight.view("basket"); g.flight.lookToward(0, 0, -24);`,
  // Just above the low cloud layer, looking over a puff.
  cloud: `const c = g.flight.nearestCloud(0, -400, 300); g.flight.place(c.x + c.w * 1.25, c.top + 22, c.z + c.w * 0.4);
    g.flight.view("chase"); g.flight.chaseToward(c.x, c.z, 26, 64);`,
  // Inside a low cloud (extra): the whiteout, from the basket.
  incloud: `const c = g.flight.nearestCloud(0, -400, 300); g.flight.place(c.x, c.base + (c.top - c.base) * 0.35 - 1.5, c.z);
    g.flight.view("basket"); g.flight.look(0, -20);`,
  // Close on the burner flame.
  burner: `const x = -300, z = 250, y = gh(x, z) + 150; g.flight.place(x, y, z); g.flight.burner(true);
    g.setCamera([x + 2.6, y + 1.5, z + 2.4], [x, y + 4.3, z]);`,
  // Phase 7, the pilot: a close three-quarter look at her in the basket at golden hour (idle, both
  // hands resting on the front rim), mid-hold with the lever pulled down and the burner roaring (from
  // her right and below, so her upturned face, the lever, the flame and its glow share the frame),
  // and leaning on the front rim looking down over the edge (from outside, a little below the rim).
  pilot: `const x = -300, z = 250, y = gh(x, z) + 140; g.flight.place(x, y, z); ${PILOT_FRAME} g.pilot.pose("idle", 0.6);
    g.setCamera(L(0.45, 1.9, 1.55), L(0.12, 1.45, 0.08));`,
  pilot_burner: `const x = -300, z = 250, y = gh(x, z) + 140; g.flight.place(x, y, z); ${PILOT_FRAME} g.flight.burner(true);
    g.pilot.pose("burner", 1.2); g.setCamera(L(-0.85, 1.6, 2.2), L(-0.12, 2.1, 0.05));`,
  pilot_look: `const x = -300, z = 250, y = gh(x, z) + 140; g.flight.place(x, y, z); ${PILOT_FRAME} g.pilot.pose("lookOver", 2.4);
    g.setCamera(L(0.8, 0.75, 2.3), L(0.1, 1.25, 0.35));`,
  // The link-preview image (not in the default set): 1200x630, golden hour, the balloon over the
  // village, the river and the fields. Written to shots/<name>/og.png and copied to public/og.png.
  og: `const x = -330, z = 300, y = gh(x, z) + 120; g.flight.place(x, y, z); g.flight.yaw(-40);
    const L = Math.hypot(x, z), fx = -x / L, fz = -z / L, rx = -fz, rz = fx;
    g.setCamera([x - fx * 46 - rx * 16, y + 24, z - fz * 46 - rz * 16], [x + fx * 60 + rx * 14.4, y - 8, z + fz * 60 + rz * 14.4]);`,
  // Extra close looks (not in the default set): the bridge over the river, the lake from the south-west.
  river: [[-70, 34, 235], [2, 2, 132]],
  // Low over the village heart (gardens, square, churchyard close up).
  vlow: [[-90, 75, 95], [15, 0, -25]],
  lake: [[300, 170, -230], [700, 0, -660]],
};
/** Spots that need their own frame size (everything else is W x H). */
const SIZES = { og: [1200, 630] };
const DEFAULT_SPOTS = ["ground", "50m", "200m", "500m", "down", "basket", "cloud", "burner", "pilot", "pilot_burner", "pilot_look"];
const WANT = arg("spots", DEFAULT_SPOTS.join(",")).split(",").filter(Boolean);
for (const s of WANT) if (!SPOTS[s]) await bye(2, `unknown spot "${s}" (have ${Object.keys(SPOTS).join(", ")})`);

/** `pnpm build` as an attached child at reduced priority; teardown kills it if we are interrupted. */
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
let URL = arg("url", "");
if (!URL) {
  if (!argv.includes("--nobuild")) await build();
  await fs.access(path.join(ROOT, "dist", "index.html")).catch(() => bye(1, "dist/ missing: the build did not produce it"));
  URL = await serve(ROOT, "preview", 5440);
  console.log(`[serve] preview ${URL}`);
}

const browser = await launchBrowser(["--hide-scrollbars", "--mute-audio"]);
const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
const errors = [];
const SHADER_WARN = /warning X\d{4}|Program Info Log|Shader Info Log|THREE\.WebGLProgram|THREE\.WebGLShader/;

let gpuChecked = false;
for (const time of TIMES) {
  const page = await ctx.newPage();
  fatalShaderErrors(page, time);
  page.on("pageerror", (e) => errors.push(`[${time}] pageerror: ${e.message}`));
  page.on("console", (m) => {
    const txt = m.text();
    if (SHADER_WARN.test(txt)) errors.push(`[${time}] shader ${m.type()}: ${txt.slice(0, 600)}`);
    else if (m.type() === "error" || m.type() === "warning") errors.push(`[${time}] ${m.type()}: ${txt}`);
  });
  const t0 = Date.now();
  const sep = URL.includes("?") ? "&" : "?";
  await page.goto(`${URL}${sep}time=${time}&seed=${SEED}&t=${T}&capture=1`, { waitUntil: "load" });
  if (!gpuChecked) {
    await assertGpu(page);
    gpuChecked = true;
  }
  await page.waitForFunction(() => !!window.__game, null, { timeout: 300_000, polling: 100 });
  await page.evaluate(() => window.__game.ready);
  console.log(`[${time}] ready in ${((Date.now() - t0) / 1000).toFixed(1)}s, in-page renderer: ${await page.evaluate(() => window.__game.renderer())}`);
  for (const spot of WANT) {
    const spec = SPOTS[spot];
    const [sw, sh] = SIZES[spot] ?? [W, H];
    const vp = page.viewportSize();
    if (vp.width !== sw || vp.height !== sh) {
      await page.setViewportSize({ width: sw, height: sh });
      await page.evaluate(() => window.__game.frames(4));
    }
    await page.evaluate(async ([spec, isScript, clock]) => {
      const g = window.__game;
      const gh = (x, z) => Math.max(0, g.groundHeight(x, z));
      // Every spot starts from the same frozen clock (a spot may move it, see "down").
      g.setClock(clock);
      g.flight.burner(null);
      g.flight.view("chase");
      g.pilot.pose(null);
      if (isScript) {
        await new Function("g", "gh", spec)(g, gh);
        // The festival: the other balloons in a fan ahead of this view, round the player.
        g.flight.resetOthers();
      } else g.setCamera(spec[0], spec[1]);
    }, [spec, typeof spec === "string", Number(T)]);
    await page.evaluate(() => window.__game.frames(8));
    const file = path.join(OUT, `${spot}${time === "golden" ? "" : "_" + time}.png`);
    await page.screenshot({ path: file });
    if (spot === "og" && time === "golden") {
      await fs.copyFile(file, path.join(ROOT, "public", "og.png"));
      console.log("          copied to public/og.png");
    }
    const st = await page.evaluate(() => window.__game.stats());
    const extra = Object.entries(st).filter(([k]) => !["calls", "tris", "programs", "scale"].includes(k)).map(([k, v]) => `${k}=${v}`).join(" ");
    console.log(`  ${spot.padEnd(7)} calls=${st.calls} tris=${(st.tris / 1e6).toFixed(2)}M programs=${st.programs} -> ${path.relative(ROOT, file)}`);
    if (extra) console.log(`          ${extra}`);
  }
  await page.close();
}
await ctx.close();

if (errors.length) {
  console.error("\nConsole errors / warnings (run fails):");
  for (const e of [...new Set(errors)].slice(0, 40)) console.error("  " + e);
}
await bye(errors.length ? 1 : 0);
