import { spawn } from "node:child_process";
import { mkdtemp, rm } from "node:fs/promises";
import { createServer } from "node:net";
import { tmpdir } from "node:os";
import { join } from "node:path";

const url =
  process.env.STAR_SLING_URL ||
  `http://127.0.0.1:${process.env.STAR_SLING_PORT || 5224}/index.html?date=2026-06-04&v=browser-smoke`;
const chromePath =
  process.env.CHROME_BIN ||
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const cdpPort = Number(process.env.CDP_PORT || await findFreePort());
const userDataDir = await mkdtemp(join(tmpdir(), "star-sling-chrome-"));
let server;

const chrome = spawn(chromePath, [
  "--headless=new",
  "--disable-gpu",
  "--no-first-run",
  "--no-default-browser-check",
  "--remote-debugging-address=127.0.0.1",
  `--remote-debugging-port=${cdpPort}`,
  `--user-data-dir=${userDataDir}`,
  "about:blank"
], {
  stdio: "ignore"
});

try {
  if (!process.env.STAR_SLING_URL) {
    server = spawn("python3", ["-m", "http.server", String(process.env.STAR_SLING_PORT || 5224), "--bind", "127.0.0.1"], {
      stdio: "ignore"
    });
    await waitForServer(url);
  }

  await waitForChrome(cdpPort);
  const desktop = await runViewport({ width: 1280, height: 860, mobile: false });
  const mobile = await runViewport({ width: 390, height: 844, mobile: true });
  console.log(
    `browser smoke passed: desktop ${desktop.run.score} pts ${desktop.run.collectedCount}/7 stars, ` +
      `mobile overflow ${mobile.layout.scrollWidth}/${mobile.layout.clientWidth}`
  );
} finally {
  if (server && !server.killed) server.kill("SIGTERM");
  chrome.kill("SIGTERM");
  if (server) await waitForExit(server);
  await waitForExit(chrome);
  await rm(userDataDir, { force: true, recursive: true, maxRetries: 5, retryDelay: 120 });
}

async function runViewport(viewport) {
  const target = await createTarget("about:blank");
  const cdp = await connectCdp(target.webSocketDebuggerUrl);
  await cdp.send("Page.enable");
  await cdp.send("Runtime.enable");
  await cdp.send("Emulation.setDeviceMetricsOverride", {
    width: viewport.width,
    height: viewport.height,
    deviceScaleFactor: viewport.mobile ? 2 : 1,
    mobile: viewport.mobile
  });
  await cdp.send("Page.navigate", { url });
  await cdp.waitFor("Page.loadEventFired", 10000);

  const loaded = await evaluate(cdp, `(() => {
    const root = document.documentElement;
    const canvasNode = document.querySelector('#field');
    const startNode = document.querySelector('#start-button');
    if (!canvasNode || !startNode) {
      return {
        title: document.title,
        h1: document.querySelector('h1')?.textContent || '',
        missingGameNodes: true,
        bodyText: document.body.textContent.slice(0, 120),
        scrollWidth: root.scrollWidth,
        clientWidth: root.clientWidth
      };
    }
    const canvas = canvasNode.getBoundingClientRect();
    const start = startNode.getBoundingClientRect();
    return {
      title: document.title,
      h1: document.querySelector('h1')?.textContent,
      dateValue: document.querySelector('#challenge-date')?.value,
      status: document.querySelector('#status-line')?.textContent,
      canvasWidth: Math.round(canvas.width),
      canvasHeight: Math.round(canvas.height),
      startVisible: start.width > 0 && start.height > 0 && start.top < window.innerHeight,
      resultHidden: document.querySelector('#result-panel').hidden,
      scrollWidth: root.scrollWidth,
      clientWidth: root.clientWidth
    };
  })()`);

  if (
    loaded.title !== "Star Sling" ||
    loaded.h1 !== "Star Sling" ||
    loaded.dateValue !== "2026-06-04" ||
    loaded.status !== "Press Start Round." ||
    loaded.canvasWidth < (viewport.mobile ? 360 : 760) ||
    loaded.canvasHeight < (viewport.mobile ? 220 : 420) ||
    !loaded.startVisible ||
    !loaded.resultHidden ||
    loaded.scrollWidth > loaded.clientWidth
  ) {
    throw new Error(`unexpected load state: ${JSON.stringify(loaded)}`);
  }

  await evaluate(cdp, `window.StarSling.start()`);
  const started = await evaluate(cdp, `window.StarSling.getState()`);
  if (!started.run.active || started.run.done || started.run.shots.length !== 0) {
    throw new Error(`start failed: ${JSON.stringify(started)}`);
  }

  const solved = await evaluate(cdp, `window.StarSling.solveToday()`);
  const state = await evaluate(cdp, `(() => {
    const appState = window.StarSling.getState();
    const root = document.documentElement;
    const canvas = document.querySelector('#field').getBoundingClientRect();
    const start = document.querySelector('#start-button').getBoundingClientRect();
    return {
      ...appState,
      layout: {
        scrollWidth: root.scrollWidth,
        clientWidth: root.clientWidth,
        canvasWidth: Math.round(canvas.width),
        canvasHeight: Math.round(canvas.height),
        startTop: Math.round(start.top)
      },
      resultOpen: !document.querySelector('#result-panel').hidden,
      copyDisabled: document.querySelector('#copy-button').disabled,
      visibleStatus: document.querySelector('#status-line')?.textContent
    };
  })()`);

  if (!solved.run.docked || !state.run.docked || state.run.collectedCount !== 7) {
    throw new Error(`solution did not finish: ${JSON.stringify(state)}`);
  }
  if (state.run.score < 2200 || state.run.heat !== 0 || state.run.shots.length > 8) {
    throw new Error(`solution score state is weak: ${JSON.stringify(state)}`);
  }
  if (!state.resultOpen || state.copyDisabled) {
    throw new Error(`finished controls are wrong: ${JSON.stringify(state)}`);
  }
  if (
    !state.shareText.includes("Star Sling 2026-06-04") ||
    !state.shareText.includes("S grade") ||
    !state.shareText.includes("docked")
  ) {
    throw new Error(`share text is missing context: ${JSON.stringify(state)}`);
  }
  if (state.layout.scrollWidth > state.layout.clientWidth) {
    throw new Error(`horizontal overflow: ${JSON.stringify(state)}`);
  }
  if (state.layout.canvasWidth < (viewport.mobile ? 360 : 760)) {
    throw new Error(`canvas too narrow: ${JSON.stringify(state)}`);
  }

  await cdp.close();
  return state;
}

async function waitForChrome(debugPort) {
  const deadline = Date.now() + 10000;
  while (Date.now() < deadline) {
    try {
      await fetchJson(`http://127.0.0.1:${debugPort}/json/version`);
      return;
    } catch {
      await delay(100);
    }
  }
  throw new Error("Chrome remote debugging port did not become ready");
}

async function waitForServer(target) {
  const deadline = Date.now() + 10000;
  let lastError;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(target);
      if (response.ok) return;
      lastError = new Error(`${target} returned ${response.status}`);
    } catch (error) {
      lastError = error;
    }
    await delay(100);
  }
  throw lastError || new Error(`Timed out waiting for ${target}`);
}

async function fetchJson(requestUrl) {
  const response = await fetch(requestUrl);
  if (!response.ok) throw new Error(`${requestUrl} returned ${response.status}`);
  return response.json();
}

async function createTarget(targetUrl) {
  const requestUrl = `http://127.0.0.1:${cdpPort}/json/new?${encodeURIComponent(targetUrl)}`;
  const response = await fetch(requestUrl, { method: "PUT" });
  if (!response.ok) throw new Error(`${requestUrl} returned ${response.status}`);
  return response.json();
}

async function connectCdp(webSocketUrl) {
  const socket = new WebSocket(webSocketUrl);
  const pending = new Map();
  const listeners = new Map();
  let nextId = 1;

  await new Promise((resolve, reject) => {
    socket.addEventListener("open", resolve, { once: true });
    socket.addEventListener("error", reject, { once: true });
  });

  socket.addEventListener("message", (event) => {
    const message = JSON.parse(event.data);
    if (message.id && pending.has(message.id)) {
      const { resolve, reject } = pending.get(message.id);
      pending.delete(message.id);
      if (message.error) reject(new Error(message.error.message));
      else resolve(message.result || {});
      return;
    }

    const waiting = listeners.get(message.method);
    if (waiting) {
      listeners.delete(message.method);
      waiting.resolve(message.params || {});
    }
  });

  return {
    send(method, params = {}) {
      const id = nextId;
      nextId += 1;
      socket.send(JSON.stringify({ id, method, params }));
      return new Promise((resolve, reject) => {
        pending.set(id, { resolve, reject });
        setTimeout(() => {
          if (!pending.has(id)) return;
          pending.delete(id);
          reject(new Error(`${method} timed out`));
        }, 10000);
      });
    },
    waitFor(method, timeout = 10000) {
      return new Promise((resolve, reject) => {
        const timer = setTimeout(() => {
          listeners.delete(method);
          reject(new Error(`${method} timed out`));
        }, timeout);
        listeners.set(method, {
          resolve: (value) => {
            clearTimeout(timer);
            resolve(value);
          }
        });
      });
    },
    close() {
      socket.close();
    }
  };
}

async function evaluate(cdp, expression) {
  const result = await cdp.send("Runtime.evaluate", {
    expression,
    awaitPromise: true,
    returnByValue: true
  });
  if (result.exceptionDetails) {
    throw new Error(result.exceptionDetails.text || "Runtime.evaluate failed");
  }
  return result.result.value;
}

async function findFreePort() {
  return new Promise((resolve, reject) => {
    const server = createServer();
    server.listen(0, "127.0.0.1", () => {
      const address = server.address();
      server.close(() => resolve(address.port));
    });
    server.on("error", reject);
  });
}

function waitForExit(child) {
  return new Promise((resolve) => {
    if (child.exitCode !== null) {
      resolve();
      return;
    }
    child.once("exit", resolve);
    setTimeout(resolve, 1200);
  });
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
