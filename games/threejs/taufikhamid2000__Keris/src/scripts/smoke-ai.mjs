// Headless smoke check for guard pathfinding: put the player on a rooftop, alert the guards,
// and assert a guard climbs up and reaches them. Usage: node scripts/smoke-ai.mjs [url] [timeoutSec]
import { chromium } from "playwright";
const url = process.argv[2] || "http://localhost:3000";
const timeoutSec = Number(process.argv[3] || 90);
const b = await chromium.launch({ args: ["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"] });
const pg = await b.newPage({ viewport: { width: 1024, height: 576 } });
const errs = [];
pg.on("pageerror", (e) => errs.push(String(e)));
let code = 1;
try {
  await pg.goto(url, { waitUntil: "networkidle" });
  await pg.waitForFunction(() => window.__keris, null, { timeout: 30000 });
  await pg.click("text=Begin");
  await pg.keyboard.press("Space"); // skip the first-run intro
  await pg.waitForTimeout(500);
  const spot = await pg.evaluate(() => window.__keris.debugRoofSpot());
  if (!spot) throw new Error("no climbable rooftop spot found in the nav graph");
  console.log("roof spot", JSON.stringify(spot));
  await pg.evaluate((s) => window.__keris.debugAlertAt(s.x, s.y, s.z), spot);
  const t0 = Date.now();
  let maxY = 0;
  let minD = Infinity;
  let sawClimb = false;
  let reached = false;
  while (Date.now() - t0 < timeoutSec * 1000) {
    await pg.waitForTimeout(250);
    const d = await pg.evaluate(() => window.__keris.debug());
    for (const g of d.guards) {
      if (g.dead) continue;
      sawClimb ||= g.climbing;
      maxY = Math.max(maxY, g.y);
      const dist = Math.hypot(g.x - spot.x, g.z - spot.z);
      if (g.y > spot.y - 0.5) minD = Math.min(minD, dist);
      if (g.y > spot.y - 0.5 && dist < 3) reached = true;
    }
    if (reached) break;
    if (d.phase !== "playing") break;
  }
  console.log(JSON.stringify({ reached, sawClimb, maxGuardY: +maxY.toFixed(2), minRoofDist: Number.isFinite(minD) ? +minD.toFixed(2) : null, seconds: +((Date.now() - t0) / 1000).toFixed(1), errors: errs }));
  code = reached && !errs.length ? 0 : 1;
} catch (e) {
  console.error("smoke failed:", e.message);
} finally {
  await b.close();
}
process.exit(code);
