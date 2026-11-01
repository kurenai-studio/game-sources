// Drives the web game in headless Chrome: plays whole games by clicking the real buttons, checks the landing page
// on a Mac and an iPhone, and fails on any console error. Usage: node art/qa_web.mjs [base url] [screenshot dir]
// Needs Chrome and a server for web/ (python3 -m http.server 8765 --directory web).
import { spawn } from "node:child_process";
import { mkdirSync, writeFileSync } from "node:fs";

const BASE = process.argv[2] || "http://localhost:8765", OUT = process.argv[3] || "/tmp/hamurapi-qa";
const CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome", PORT = 9333;
mkdirSync(OUT, { recursive: true });
const chrome = spawn(CHROME, ["--headless=new", `--remote-debugging-port=${PORT}`, "--disable-gpu", "--hide-scrollbars", "--mute-audio",
  `--user-data-dir=${OUT}/profile`, "about:blank"], { stdio: "ignore" });
const sleep = ms => new Promise(r => setTimeout(r, ms));
const problems = [];

async function page() {
  for (let i = 0; i < 50; i++) { try { await fetch(`http://localhost:${PORT}/json/version`); break; } catch { await sleep(200); } }
  const tab = await (await fetch(`http://localhost:${PORT}/json/new?about:blank`, { method: "PUT" })).json();
  const ws = new WebSocket(tab.webSocketDebuggerUrl);
  await new Promise(r => ws.addEventListener("open", r));
  let id = 0; const waiting = new Map();
  ws.addEventListener("message", m => {
    const msg = JSON.parse(m.data);
    if (msg.id) { waiting.get(msg.id)?.(msg); waiting.delete(msg.id); }
    else if (msg.method === "Runtime.exceptionThrown") problems.push("exception: " + (msg.params.exceptionDetails.exception?.description || msg.params.exceptionDetails.text));
    else if (msg.method === "Runtime.consoleAPICalled" && msg.params.type === "error") problems.push("console.error: " + msg.params.args.map(a => a.value ?? a.description).join(" "));
    else if (msg.method === "Network.loadingFailed" && !msg.params.canceled) problems.push("load failed: " + msg.params.errorText);
    else if (msg.method === "Network.responseReceived" && msg.params.response.status >= 400) problems.push(`${msg.params.response.status} ${msg.params.response.url}`);
  });
  const send = (method, params = {}) => new Promise(r => { waiting.set(++id, r); ws.send(JSON.stringify({ id, method, params })); });
  const js = async expr => { const r = await send("Runtime.evaluate", { expression: expr, awaitPromise: true, returnByValue: true }); if (r.result.exceptionDetails) problems.push("eval: " + expr.slice(0, 60)); return r.result.result?.value; };
  await send("Runtime.enable"); await send("Network.enable"); await send("Page.enable");
  return {
    js,
    async open(url, w, h, ua, mobile = false) {
      await send("Emulation.setDeviceMetricsOverride", { width: w, height: h, deviceScaleFactor: mobile ? 3 : 1, mobile });
      if (ua) await send("Emulation.setUserAgentOverride", { userAgent: ua });
      await send("Page.navigate", { url }); await sleep(1800);
    },
    async shot(name, full = false) {
      const r = await send("Page.captureScreenshot", { format: "png", captureBeyondViewport: full });
      writeFileSync(`${OUT}/${name}.png`, Buffer.from(r.result.data, "base64"));
    },
  };
}

const MAC = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15";
const IPHONE = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1";
const click = sel => `(() => { const b = document.querySelector(${JSON.stringify(sel)}); if (!b || b.disabled) return false; b.click(); return true; })()`;

try {
  const p = await page();

  // 1. Play whole games through the real buttons, at desktop and phone sizes, in every mode.
  for (const [w, h, mode, mobile] of [[1280, 800, "begin", false], [390, 845, "begin", true], [1280, 800, "classic", false], [390, 845, "daily", true]]) {
    await p.open(`${BASE}/play/`, w, h, mobile ? IPHONE : MAC, mobile);
    await p.js("localStorage.clear()");
    await p.open(`${BASE}/play/`, w, h, mobile ? IPHONE : MAC, mobile);
    const robot = mode !== "classic";  // one game takes the default orders as they come; the rest play to win
    if (!await p.js(click(`[data-act=${mode}]`))) problems.push(`no ${mode} button`);
    let cards = 0, years = 0, shots = new Set();
    for (let guard = 0; guard < 80; guard++) {
      const phase = await p.js("G.phase");
      if (!shots.has(phase)) { shots.add(phase); await sleep(350); await p.shot(`play-${mode}-${w}-${phase}`); }
      const overflow = await p.js("document.documentElement.scrollWidth > innerWidth + 1 || [...document.querySelectorAll('#panel,#hud')].some(e => e.getBoundingClientRect().right > innerWidth + 1)");
      if (overflow) problems.push(`${mode} ${w}px: ${phase} overflows the screen`);
      const tall = await p.js("document.querySelector('#panel').getBoundingClientRect().top < document.querySelector('#hud').getBoundingClientRect().bottom");
      if (tall) problems.push(`${mode} ${w}px: ${phase} panel runs into the top bar`);
      if (phase === "over") break;
      if (phase === "card") { cards++; if (!await p.js(click("#panel button:not(:disabled)"))) problems.push("card with no usable button"); }
      else if (phase === "orders") {
        if (years === 0) {  // exercise the controls once: stepper, slider, quick buttons
          await p.js(click("[data-act=more-buy]")); await p.js(click("[data-act=less-buy]"));
          await p.js("(() => { const r = document.querySelector('[data-range=plant]'); r.value = 0; r.dispatchEvent(new Event('input', { bubbles: true })); })()");
          if (await p.js("G.orders.plant") !== 0) problems.push("plant slider did not move the order");
          await p.js(click("[data-act=quick-feed]")); await p.js(click("[data-act=quick-plant]"));
        }
        if (robot) await p.js("G.orders = Ruler.legal(G.city); refreshOrders()");
        if (await p.js("error()")) problems.push("orders were refused");
        years++; await p.js(click("[data-act=submit]"));
      } else if (phase === "report") await p.js(click("[data-act=next]"));
      else { problems.push("stuck in " + phase); break; }
      await sleep(60);
    }
    const end = await p.js("({ phase: G.phase, grade: grade(G.city), years: G.log.length, reigns: G.reigns, saved: localStorage.getItem('hamurabi.saved') })");
    if (end.phase !== "over") problems.push(`${mode}: game never ended`);
    if (end.reigns !== 1) problems.push(`${mode}: finished game was not counted`);
    if (end.saved) problems.push(`${mode}: a finished game left a save behind`);
    if (mode === "begin" && cards < 1) problems.push("story mode showed no cards");
    if (mode !== "begin" && cards) problems.push(`${mode} showed story cards`);
    console.log(`  ${mode.padEnd(7)} ${w}px: ${end.years} years, ${cards} cards, grade ${end.grade}`);
  }

  // 2. Quit mid-game and come back.
  await p.open(`${BASE}/play/`, 1280, 800, MAC);
  await p.js("localStorage.clear()"); await p.js(click("[data-act=classic]")); await p.js(click("[data-act=submit]")); await p.js(click("[data-act=next]"));
  const before = await p.js("JSON.stringify([G.city.year, G.city.grain, G.city.people])");
  await p.open(`${BASE}/play/`, 1280, 800, MAC);
  if (!await p.js(click("[data-act=resume]"))) problems.push("no Keep playing button after a reload");
  if (await p.js("JSON.stringify([G.city.year, G.city.grain, G.city.people])") !== before) problems.push("resumed game does not match the one left");

  // 3. Settings open, change and persist. The robot demo runs.
  await p.js(click("[data-act=settings]"));
  await p.js("(() => { const s = document.querySelector('#hard'); s.value = 'hard'; s.dispatchEvent(new Event('change')); })()");
  await p.shot("settings");
  if (await p.js("localStorage.getItem('hamurabi.difficulty')") !== '"hard"') problems.push("difficulty did not save");
  await p.js(click("[data-act=close]")); await p.js(click("[data-act=menu]"));
  await p.open(`${BASE}/play/?demo`, 1280, 800, MAC); await sleep(4500);
  if (await p.js("G.log.length") < 1) problems.push("demo did not play a year in 6 seconds");
  await p.shot("demo");

  // 4. The landing page, on a Mac and on an iPhone.
  for (const [name, w, h, ua, mobile] of [["mac", 1280, 800, MAC, false], ["iphone", 390, 845, IPHONE, true]]) {
    await p.open(`${BASE}/`, w, h, ua, mobile); await sleep(1500);
    const info = await p.js(`({ wide: document.documentElement.scrollWidth > innerWidth + 1, links: [...document.querySelectorAll('a')].map(a => a.href),
      game: !!document.querySelector('#game').contentDocument.querySelector('#panel button'), canvas: document.querySelector('#game').contentDocument.querySelector('canvas').width,
      top: document.querySelector('#game').getBoundingClientRect().top, tall: document.querySelector('#game').getBoundingClientRect().height })`);
    if (info.wide) problems.push(`landing ${name}: page scrolls sideways`);
    if (!info.game || !info.canvas) problems.push(`landing ${name}: the game at the top did not start`);
    if (info.top > 1 || info.tall < 500) problems.push(`landing ${name}: the game is not the top of the page`);
    for (const need of ["github.com/nulljosh/labs/tree/main/hamurapi", "/play/", "LICENSE"]) if (!info.links.some(l => l.includes(need))) problems.push(`landing: no link to ${need}`);
    await p.shot(`landing-${name}`); await p.shot(`landing-${name}-full`, true);
    console.log(`  landing ${name}: game ${Math.round(info.tall)}px tall`);
  }
} finally { chrome.kill(); }

console.log(problems.length ? "PROBLEMS:\n  " + [...new Set(problems)].join("\n  ") : "web QA clean");
process.exit(problems.length ? 1 : 0);
