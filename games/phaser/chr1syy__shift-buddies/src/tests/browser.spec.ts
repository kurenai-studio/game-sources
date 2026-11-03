import { test, expect } from "@playwright/test";
import { writeFile } from "node:fs/promises";
import type { Page, TestInfo } from "@playwright/test";
import type { Action, RoomId } from "../src/game/rules.ts";
import { solution, fullSolution, bodySolution, moduleSolution, freightSetup, routesSolution } from "./solution.ts";

const runtimeErrors = new WeakMap<Page, string[]>();
test.beforeEach(async ({ page }) => {
  const errors: string[] = [];
  runtimeErrors.set(page, errors);
  page.on("pageerror", e => errors.push(e.message));
  page.on("console", msg => { if (msg.type() === "error") errors.push(msg.text()); });
});
test.afterEach(async ({ page }) => { expect(runtimeErrors.get(page)).toEqual([]); });

const keyFor = (action: Action): string =>
  action.type === "move" || action.type === "pull"
    ? {
        up: "ArrowUp",
        down: "ArrowDown",
        left: "ArrowLeft",
        right: "ArrowRight",
      }[action.direction]
    : { switch: "Shift", swap: "t", interact: "e" }[action.type];
async function keys(page: Page, actions: Action[]): Promise<void> {
  for (const action of actions) {
    if (action.type === "pull") await page.keyboard.down("e");
    await page.keyboard.press(keyFor(action));
    if (action.type === "pull") await page.keyboard.up("e");
    await expect(page.locator("#game")).toHaveAttribute("data-animating", "false");
  }
}
async function ready(page: Page, room: RoomId = "tech"): Promise<void> {
  await page.goto("/");
  await expect(page.locator("#game")).toHaveAttribute("data-ready", "true");
  await expect(page.locator("canvas")).toBeVisible();
  await page.locator("#room-select").selectOption(room);
}

test("real keyboard solution, persistent power on Shift, exact full undo and restart", async ({
  page,
}) => {
  const errors: string[] = [];
  page.on("pageerror", (error) => errors.push(error.message));
  page.on("console", (msg) => {
    if (msg.type() === "error") errors.push(msg.text());
  });
  await ready(page);
  await page.screenshot({
    path: ".cache/technikraum-start.png",
    fullPage: true,
  });
  await keys(page, solution.swapAndPower);
  await page.screenshot({ path: ".cache/technikraum-module-getauscht.png", fullPage: true });
  await expect(page.getByTestId("robot-pip")).toHaveAttribute(
    "data-module",
    "power",
  );
  await expect(page.locator("#door-status")).toContainText("Strom verbunden");
  await page.keyboard.press("Shift");
  await expect(page.getByTestId("robot-bolt")).toHaveClass(/active/);
  await expect(page.locator("#door-status")).toContainText("Strom verbunden");
  await keys(page, solution.boltToPlate.slice(1));
  await expect(page.getByTestId("robot-bolt")).toHaveAttribute("data-x", "8");
  await expect(page.getByTestId("robot-bolt")).toHaveAttribute("data-y", "7");
  await keys(page, solution.pipToExit);
  await expect(page.locator("#door-status")).toContainText(
    "Bolt hält die Platte",
  );
  await keys(page, solution.boltToExit);
  await expect(page.locator("#feedback")).toContainText("Geschafft!");
  await expect(page.getByTestId("robot-pip")).toHaveAttribute("data-x", "14");
  await expect(page.getByTestId("robot-bolt")).toHaveAttribute("data-x", "15");
  await expect(page.locator("#door-status")).toContainText("A ZU");
  await page.screenshot({
    path: ".cache/technikraum-geloest.png",
    fullPage: true,
  });
  for (let i = 0; i < fullSolution.length; i++) await page.keyboard.press("z");
  await expect(page.locator("#move-count")).toHaveText("0 Aktionen");
  await expect(page.getByTestId("robot-pip")).toHaveAttribute(
    "data-module",
    "magnet",
  );
  await expect(page.getByTestId("robot-pip")).toHaveAttribute("data-x", "3");
  await expect(page.getByTestId("robot-bolt")).toHaveAttribute("data-x", "4");
  await page.keyboard.press("d"); // WASD and R
  await page.keyboard.press("r");
  await expect(page.locator("#move-count")).toHaveText("0 Aktionen");
  await expect(page.getByTestId("robot-pip")).toHaveAttribute("data-x", "3");
  expect(errors).toEqual([]);
});

test("buttons, focus recovery, stale OS repeat and narrow viewport", async ({
  page,
}) => {
  await ready(page, "modules");
  await page.keyboard.press("d");
  await expect(page.locator("#game")).toHaveAttribute("data-animating", "false");
  // A stale OS repeat after keyup must neither add a move nor restart holding.
  await page.locator("#game").dispatchEvent("keydown", { code: "KeyD", repeat: true, bubbles: true });
  await page.waitForTimeout(220);
  await expect(page.getByTestId("robot-pip")).toHaveAttribute("data-x", "4");
  await page.getByRole("button", { name: "T · Module tauschen" }).click();
  await expect(page.getByTestId("robot-pip")).toHaveAttribute(
    "data-module",
    "power",
  );
  await page.getByRole("button", { name: "Z · Undo" }).click();
  await expect(page.getByTestId("robot-pip")).toHaveAttribute(
    "data-module",
    "magnet",
  );
  await page.getByRole("button", { name: "E · Interagieren" }).click();
  await expect(page.locator("#feedback")).toContainText(
    "Magnet bereit",
  );
  await page.getByRole("button", { name: "R · Neustart" }).click();
  await expect(page.locator("#undo")).toBeDisabled();
  await page.getByRole("heading", { name: "Shift Buddies" }).click();
  await page.locator("canvas").click();
  await page.keyboard.press("d");
  await expect(page.getByTestId("robot-pip")).toHaveAttribute("data-x", "4");
  await page.setViewportSize({ width: 800, height: 1000 });
  await expect(page.locator("canvas")).toBeVisible();
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= window.innerWidth,
    ),
  ).toBe(true);
});


test("first entry, two short lessons, next, room-local undo and direct test room selection", async ({ page }) => {
  const errors: string[] = [];
  page.on("pageerror", error => errors.push(error.message));
  page.on("console", msg => { if (msg.type() === "error") errors.push(msg.text()); });
  await page.goto("/");
  await expect(page.locator("#game")).toHaveAttribute("data-ready", "true");
  await expect(page.locator("#game")).toHaveAttribute("data-room", "bodies");
  const switchButton = page.getByRole("button", { name: "Shift · Roboter wechseln" });
  await switchButton.click();
  await expect(page.getByTestId("robot-bolt")).toHaveClass(/active/);
  await expect(page.locator("#game")).toBeFocused();
  await page.keyboard.press("ShiftRight");
  await expect(page.getByTestId("robot-pip")).toHaveClass(/active/);
  await page.getByRole("button", { name: "R · Neustart" }).click();
  await page.screenshot({ path: ".cache/lernraum-koerper-start.png", fullPage: true });
  await keys(page, bodySolution);
  await expect(page.locator("#feedback")).toContainText("Geschafft!");
  await expect(page.locator("#door-status")).toContainText("Bolt hält die Platte");
  await page.screenshot({ path: ".cache/lernraum-koerper-geloest.png", fullPage: true });
  await page.keyboard.press("z");
  await expect(page.locator("#next-room")).toBeHidden();
  await keys(page, bodySolution.slice(-1));
  await page.getByRole("button", { name: "Weiter zum nächsten Raum" }).click();
  await expect(page.locator("#game")).toBeFocused();
  await expect(page.locator("#game")).toHaveAttribute("data-room", "modules");
  await expect(page.locator("#undo")).toBeDisabled();
  await page.keyboard.press("ArrowLeft");
  await page.getByRole("button", { name: "E · Interagieren" }).click();
  await expect(page.locator("#feedback")).toContainText("verankert und nicht magnetisch");
  await page.screenshot({ path: ".cache/lernraum-module-hindernis.png", fullPage: true });
  await page.keyboard.press("r");
  // Click equivalents for every module exchange, interaction and robot switch.
  for (const action of moduleSolution) {
    if (action.type === "move" || action.type === "pull") await keys(page, [action]);
    else {
      await page.locator(`#${action.type}`).click();
      await expect(page.locator("#game")).toBeFocused();
      if (action.type === "swap") {
        await expect(page.getByTestId("robot-pip")).toHaveAttribute("data-module", "power");
        await page.waitForTimeout(500);
        await page.screenshot({ path: ".cache/lernraum-module-getauscht.png", fullPage: true });
      }
    }
  }
  await expect(page.locator("#feedback")).toContainText("Geschafft!");
  await page.screenshot({ path: ".cache/lernraum-module-geloest.png", fullPage: true });
  for (let i = 0; i < moduleSolution.length; i++) await page.keyboard.press("z");
  await expect(page.locator("#move-count")).toHaveText("0 Aktionen");
  await expect(page.getByTestId("robot-pip")).toHaveAttribute("data-x", "3");
  await expect(page.getByTestId("robot-pip")).toHaveAttribute("data-y", "5");
  await keys(page, moduleSolution);
  await page.locator("#next-room").click();
  await expect(page.locator("#game")).toHaveAttribute("data-room", "tech");
  await expect(page.locator("#next-room")).toBeHidden();
  await expect(page.locator("#undo")).toBeDisabled();
  // Switching away and back starts a clean room; undo never leaks across rooms.
  await page.keyboard.press("d");
  await page.locator("#room-select").selectOption("bodies");
  await page.locator("#room-select").selectOption("tech");
  await expect(page.getByTestId("robot-pip")).toHaveAttribute("data-x", "3");
  await expect(page.locator("#undo")).toBeDisabled();
  expect(errors).toEqual([]);
});

// These routes go through DOM keyboard events, never through a debug state setter.
test("six rooms in order, Enter once with button focus/repeat, full undo and final ending", async ({ page }) => {
  test.setTimeout(180_000);
  const { allSolutions } = await import("./solution.ts");
  const errors: string[] = [];
  page.on("pageerror", error => errors.push(error.message));
  page.on("console", msg => { if (msg.type() === "error") errors.push(msg.text()); });
  await page.goto("/");
  await expect(page.locator("#game")).toHaveAttribute("data-ready", "true");
  await page.keyboard.press("Enter");
  await expect(page.locator("#game")).toHaveAttribute("data-room", "bodies");
  const rooms = Object.entries(allSolutions);
  for (let i = 0; i < rooms.length; i++) {
    const [room, actions] = rooms[i];
    await expect(page.locator("#game")).toHaveAttribute("data-room", room);
    await keys(page, actions);
    await expect(page.locator("#game")).toHaveAttribute("data-won", "true");
    await expect(page.locator("#move-count")).toHaveText(`${actions.length} Aktionen`);
    await page.screenshot({ path: `.cache/expansion-${room}-won.png`, fullPage: true });
    for (let n = 0; n < actions.length; n++) await page.keyboard.press("z");
    await expect(page.locator("#move-count")).toHaveText("0 Aktionen");
    await expect(page.locator("#undo")).toBeDisabled();
    // Replay without motion to also verify reduced-motion solutions.
    await page.emulateMedia({ reducedMotion: "reduce" });
    await keys(page, actions);
    if (i < rooms.length - 1) {
      await expect(page.locator("#objective")).toContainText("Enter");
      await page.locator("#next-room").focus();
      await page.keyboard.down("Enter");
      await page.keyboard.down("Enter"); // actual repeated keydown
      await page.keyboard.up("Enter");
      await expect(page.locator("#game")).toHaveAttribute("data-room", rooms[i + 1][0]);
      await expect(page.locator("#move-count")).toHaveText("0 Aktionen");
      await expect(page.locator("#game")).toBeFocused();
    } else {
      await expect(page.locator("#next-room")).toBeHidden();
      await expect(page.locator("#objective")).toContainText("Alle sechs Räume geschafft");
      await page.keyboard.press("Enter");
      await expect(page.locator("#game")).toHaveAttribute("data-room", "bridge");
      await expect(page.locator("#game")).toHaveAttribute("data-won", "true");
    }
    await page.emulateMedia({ reducedMotion: "no-preference" });
  }
  expect(errors).toEqual([]);
});

test("held E pull: no forward/lateral turn, repeat, release, blur, obstruction and resets", async ({ page }) => {
  await ready(page, "modules");
  await keys(page, moduleSolution.slice(0, 5)); // Pip 5/2 facing right
  const game = page.locator("#game"), pip = page.getByTestId("robot-pip");
  const count = await page.locator("#move-count").textContent();
  await page.keyboard.press("e");
  await expect(game).toHaveAttribute("data-crate", "6,2");
  await expect(page.locator("#move-count")).toHaveText(count!);
  await page.keyboard.down("e");
  await expect(game).toHaveAttribute("data-pulling", "true");
  for (const key of ["ArrowUp", "ArrowDown", "ArrowRight"]) await page.keyboard.press(key);
  await expect(pip).toHaveAttribute("data-facing", "right");
  await expect(pip).toHaveAttribute("data-x", "5");
  await page.keyboard.down("ArrowLeft");
  await page.keyboard.down("ArrowLeft"); // repeat must not pull twice
  await page.keyboard.up("ArrowLeft");
  await expect(pip).toHaveAttribute("data-x", "4");
  await expect(game).toHaveAttribute("data-crate", "5,2");
  await expect(pip).toHaveAttribute("data-facing", "right");
  await expect(game).toHaveAttribute("data-animating", "false");
  await page.screenshot({ path: ".cache/expansion-magnet-link.png", fullPage: true });
  await page.keyboard.up("e");
  await expect(game).toHaveAttribute("data-pulling", "false");
  await page.keyboard.press("ArrowDown");
  await expect(pip).toHaveAttribute("data-y", "3");
  await expect(game).toHaveAttribute("data-animating", "true");
  await page.keyboard.press("z");
  await expect(game).toHaveAttribute("data-animating", "false");
  await expect(pip).toHaveAttribute("data-y", "2");
  for (const key of ["Shift", "z", "r"]) {
    await page.keyboard.down("e");
    await page.keyboard.press(key);
    await expect(game).toHaveAttribute("data-pulling", "false");
    await page.keyboard.up("e");
  }
  await page.keyboard.press("r");
  await page.keyboard.press("d"); // beside Bolt at 4/6
  await page.keyboard.down("e");
  await page.keyboard.press("t");
  await expect(pip).toHaveAttribute("data-module", "power");
  await expect(game).toHaveAttribute("data-pulling", "false");
  await page.keyboard.up("e");
  await page.keyboard.press("z");
  await page.keyboard.down("e");
  await page.locator("#room-select").selectOption("modules");
  await expect(game).toHaveAttribute("data-pulling", "false");
  await page.keyboard.up("e");
  await page.keyboard.down("e");
  await page.locator("#room-select").focus();
  await expect(game).toHaveAttribute("data-pulling", "false");
  await page.keyboard.up("e");
  await game.focus();
  await page.keyboard.down("e");
  // Explicit DOM event; headless windows do not reproduce physical OS focus.
  await page.evaluate(() => window.dispatchEvent(new Event("blur")));
  await expect(game).toHaveAttribute("data-pulling", "false");
  await page.keyboard.up("e");
  await page.keyboard.press("ArrowRight");
  await expect(pip).toHaveAttribute("data-x", "4");
  await page.keyboard.press("r");
  await keys(page, moduleSolution.slice(0, 5));
  await page.keyboard.down("e");
  for (let n = 0; n < 3; n++) {
    await page.keyboard.press("ArrowLeft");
    await expect(game).toHaveAttribute("data-animating", "false");
  }
  await expect(pip).toHaveAttribute("data-x", "3");
  await expect(game).toHaveAttribute("data-crate", "4,2");
  await expect(page.locator("#feedback")).toContainText("Kein Platz");
  await page.keyboard.up("e");
});

test("Bolt pushes with either module, never E alone or normal driving; undo and E release", async ({ page }) => {
  await ready(page, "freight");
  await keys(page, freightSetup);
  const game = page.locator("#game"), bolt = page.getByTestId("robot-bolt");
  await expect(bolt).toHaveAttribute("data-module", "magnet");
  await expect(bolt).toHaveAttribute("data-facing", "down");
  for (const key of ["ArrowDown", "e"]) await page.keyboard.press(key);
  await expect(game).toHaveAttribute("data-crate", "5,3");
  await page.keyboard.down("e");
  await page.keyboard.press("ArrowRight");
  await expect(bolt).toHaveAttribute("data-facing", "down");
  await page.keyboard.down("ArrowDown");
  await page.keyboard.down("ArrowDown");
  await page.keyboard.up("ArrowDown");
  await expect(game).toHaveAttribute("data-crate", "5,4");
  await expect(bolt).toHaveAttribute("data-y", "3");
  await expect(game).toHaveAttribute("data-animating", "false");
  await page.keyboard.press("ArrowDown"); // wall behind crate
  await expect(game).toHaveAttribute("data-crate", "5,4");
  await page.keyboard.up("e");
  await page.keyboard.press("z");
  await expect(game).toHaveAttribute("data-crate", "5,3");
  await expect(bolt).toHaveAttribute("data-y", "2");
  await page.screenshot({ path: ".cache/cooperation-push.png", fullPage: true });
  // Alternate room-5 solution: after the second T, Bolt carries battery.
  await page.locator("#room-select").selectOption("routes");
  const swap = routesSolution.map(a => a.type).lastIndexOf("swap");
  await keys(page, routesSolution.slice(0, swap + 1));
  await keys(page, [{ type: "switch" }, { type: "move", direction: "up" },
    { type: "move", direction: "up" }, { type: "move", direction: "right" },
    { type: "move", direction: "down" }]);
  await expect(bolt).toHaveAttribute("data-module", "power");
  await page.keyboard.press("e");
  await expect(game).toHaveAttribute("data-crate", "9,6");
  await keys(page, [{ type: "pull", direction: "down" }]);
  await expect(game).toHaveAttribute("data-crate", "9,7");
  await expect(bolt).toHaveAttribute("data-y", "6");
  await expect(bolt).toHaveAttribute("data-module", "power");
  await page.screenshot({ path: ".cache/cooperation-battery-push.png", fullPage: true });
});

test("in-flight Shift/restart/room, rotation views, supplied and occupied bridge, audio opt-in", async ({ page }) => {
  await ready(page, "modules");
  const game = page.locator("#game");
  for (const [key, facing] of [["ArrowRight", "right"], ["ArrowUp", "up"], ["ArrowLeft", "left"], ["ArrowDown", "down"]]) {
    await page.keyboard.press(key);
    await expect(game).toHaveAttribute("data-animating", "false");
    await expect(page.getByTestId("robot-pip")).toHaveAttribute("data-facing", facing);
    await page.screenshot({ path: `.cache/expansion-facing-${facing}.png`, fullPage: true });
  }
  await page.keyboard.press("r");
  await page.keyboard.press("d");
  await expect(game).toHaveAttribute("data-animating", "true");
  await page.keyboard.press("Shift");
  await expect(game).toHaveAttribute("data-animating", "false");
  await expect(page.getByTestId("robot-pip")).toHaveAttribute("data-x", "4");
  await page.keyboard.press("z");
  await page.keyboard.press("w");
  await page.keyboard.press("r");
  await expect(page.locator("#move-count")).toHaveText("0 Aktionen");
  await page.keyboard.press("d");
  await page.locator("#room-select").selectOption("bridge");
  await expect(game).toHaveAttribute("data-animating", "false");
  const { bridgeSolution } = await import("./solution.ts");
  await keys(page, bridgeSolution.slice(0, 10)); // Bolt just on bridge at 7/5
  await expect(page.getByTestId("robot-bolt")).toHaveAttribute("data-x", "7");
  await page.screenshot({ path: ".cache/expansion-bridge-powered.png", fullPage: true });
  await page.keyboard.press("Shift");
  await page.keyboard.press("e"); // supplier disconnects while Bolt occupies span
  await expect(page.locator("#door-status")).toContainText("BESETZT · SICHER");
  await page.screenshot({ path: ".cache/expansion-bridge-occupied.png", fullPage: true });
  await page.keyboard.press("Shift");
  await keys(page, [{ type: "move", direction: "right" }]);
  await expect(page.getByTestId("robot-bolt")).toHaveAttribute("data-x", "8");
  await expect(page.locator("#door-status")).toContainText("C ZU");
  await page.screenshot({ path: ".cache/expansion-bridge-retracted.png", fullPage: true });
  await page.locator("#room-select").selectOption("modules");
  await keys(page, moduleSolution.slice(0, 5));
  await expect(page.locator("#mute")).toHaveText("Ton: aus");
  await page.locator("#mute").click();
  await expect(page.locator("#mute")).toHaveAttribute("aria-pressed", "true");
  await keys(page, [{ type: "pull", direction: "left" }]);
  await page.locator("#mute").click();
  await expect(page.locator("#mute")).toHaveAttribute("aria-pressed", "false");
});

// Check the rendered face, not just a direction attribute. The two pale eyes
// must remain visible at the chassis front under both screen-upright modules.
test("both modules leave both robots' eyes readable in all four directions", async ({ page }) => {
  await ready(page, "modules");
  const failures: string[] = [];
  const directions = [["ArrowRight", "right", 1, 0], ["ArrowUp", "up", 0, -1],
    ["ArrowLeft", "left", -1, 0], ["ArrowDown", "down", 0, 1]] as const;
  for (const distribution of ["initial", "swapped"] as const) {
    if (distribution === "swapped") {
      await page.keyboard.press("Shift"); // back to Pip
      await keys(page, [{ type: "move", direction: "right" }, { type: "swap" }]);
    }
    for (const id of ["pip", "bolt"] as const) {
      if (id === "bolt") await page.keyboard.press("Shift");
      const card = page.getByTestId(`robot-${id}`);
      for (const [key, direction, dx, dy] of directions) {
        await page.keyboard.press(key);
        await expect(page.locator("#game")).toHaveAttribute("data-animating", "false");
        await expect(card).toHaveAttribute("data-facing", direction);
        await page.evaluate(() => new Promise<void>(resolve => requestAnimationFrame(() => resolve())));
        await page.waitForTimeout(200); // inspect the settled face after the stop reaction
        const cx = Number(await card.getAttribute("data-x")) * 50 + 25;
        const cy = Number(await card.getAttribute("data-y")) * 50 + 25;
        const eyes = await page.locator("canvas").evaluate((canvas: HTMLCanvasElement, { cx, cy, dx, dy }) => {
          const context = canvas.getContext("2d")!;
          return [-3.5, 3.5].map(side => {
            const x = Math.round(cx + dx * 10 - dy * side);
            const y = Math.round(cy + dy * 10 + dx * side);
            const pixels = context.getImageData(x - 1, y - 1, 3, 3).data;
            let visible = 0;
            for (let i = 0; i < pixels.length; i += 4)
              if (pixels[i] > 225 && pixels[i + 1] > 230 && pixels[i + 2] > 230) visible++;
            return visible;
          });
        }, { cx, cy, dx, dy });
        const module = await card.getAttribute("data-module");
        if (eyes.some(count => count < 4)) failures.push(`${id}/${module}/${direction}: eye pixels ${eyes}`);
        await page.locator("canvas").screenshot({ path: `.cache/review-facing-2026-11-02/${id}-${module}-${direction}.png` });
      }
    }
  }
  expect(failures, "Each eye should retain its bright core within the 3×3 sample").toEqual([]);
});

// rAF samples of the coordinates actually passed to the shared canvas renderer,
// plus canvas pixels. These prove progression between centres, not just a HUD end state.
async function recordFrames(page: Page, milliseconds: number): Promise<void> {
  await page.evaluate(duration => {
    const target = window as unknown as { driveFrames: unknown[]; driveRecording: boolean };
    target.driveFrames = []; target.driveRecording = true;
    const start = performance.now();
    function sample() {
      const game = document.querySelector<HTMLElement>("#game")!;
      const canvas = document.querySelector<HTMLCanvasElement>("canvas")!;
      const data = canvas.getContext("2d", { willReadFrequently: true })!.getImageData(140, 90, 250, 310).data;
      let hash = 2166136261;
      for (let i = 0; i < data.length; i += 64) hash = Math.imul(hash ^ data[i], 16777619);
      target.driveFrames.push({ t: performance.now(), pip: JSON.parse(game.dataset.visualPip!),
        bolt: JSON.parse(game.dataset.visualBolt!), crate: game.dataset.visualCrate ? JSON.parse(game.dataset.visualCrate) : null,
        hash: hash >>> 0, actions: document.querySelector("#move-count")!.textContent });
      if (performance.now() - start < duration) requestAnimationFrame(sample);
      else target.driveRecording = false;
    }
    requestAnimationFrame(sample);
  }, milliseconds);
}
async function frames(page: Page) {
  await page.waitForFunction(() => !(window as unknown as { driveRecording: boolean }).driveRecording);
  return page.evaluate(() => (window as unknown as { driveFrames: {
    t: number; pip: { x: number; y: number; angle: number; leftPhase: number; rightPhase: number };
    bolt: { x: number; y: number; angle: number; leftPhase: number; rightPhase: number };
    crate: { x: number; y: number } | null; hash: number; actions: string;
  }[] }).driveFrames);
}

async function attachEvidence(info: TestInfo, name: string, samples: unknown): Promise<void> {
  const path = info.outputPath(name);
  await writeFile(path, JSON.stringify(samples, null, 2));
  await info.attach(name, { path, contentType: "application/json" });
}

test("continuous drive: tap, hold across centres, release, smooth turns, pixel/timing evidence and undo", async ({ page }, info) => {
  await ready(page, "freight");
  await page.keyboard.press("Shift"); // Freight row 7 is clear from x4 through x8.
  const game = page.locator("#game"), bolt = page.getByTestId("robot-bolt");
  await page.keyboard.press("d");
  await expect(game).toHaveAttribute("data-animating", "false");
  await page.waitForTimeout(240);
  await expect(bolt).toHaveAttribute("data-x", "5");
  await page.keyboard.press("z");
  await recordFrames(page, 780);
  await page.keyboard.down("d");
  await page.waitForTimeout(420);
  await page.keyboard.up("d");
  const samples = await frames(page);
  await attachEvidence(info, "continuous-canvas-frames.json", samples);
  await expect(bolt).toHaveAttribute("data-x", "7"); // 3 legal raster moves
  await expect(page.locator("#move-count")).toHaveText("4 Aktionen");
  expect(samples.length).toBeGreaterThan(8);
  expect(new Set(samples.map(f => f.hash)).size).toBeGreaterThan(6);
  // The two interior boundaries (x=275 and x=325) retain travel speed.
  for (const centre of [275, 325]) {
    const index = samples.findIndex(f => f.bolt.x >= centre);
    expect(index).toBeGreaterThan(1);
    const span = samples.slice(index - 2, index + 2);
    const velocity = (span.at(-1)!.bolt.x - span[0].bolt.x) / (span.at(-1)!.t - span[0].t);
    expect(velocity).toBeGreaterThan(0.20);
    expect(velocity).toBeLessThan(0.35);
  }
  expect(samples.at(-1)!.bolt.x).toBe(375);
  expect(samples.at(-1)!.bolt.y).toBe(375);
  // Turn 90 degrees: inspect intermediate angles, not only facing metadata.
  await recordFrames(page, 300);
  await page.keyboard.press("s");
  const turning = await frames(page);
  expect(turning.some(f => f.bolt.angle > Math.PI / 2 + 0.05 && f.bolt.angle < Math.PI - 0.05)).toBe(true);
  await attachEvidence(info, "turn-canvas-frames.json", turning);
  for (let n = 0; n < 4; n++) await page.keyboard.press("z");
  await expect(bolt).toHaveAttribute("data-x", "4");
  await expect(bolt).toHaveAttribute("data-y", "7");
  await expect(bolt).toHaveAttribute("data-facing", "up");
  await expect(page.locator("#move-count")).toHaveText("1 Aktionen");
});

test("held magnet load stays synchronous, looks backward, stops at obstacle without feedback/undo flood", async ({ page }, info) => {
  await ready(page, "modules");
  await keys(page, moduleSolution.slice(0, 5));
  const game = page.locator("#game"), pip = page.getByTestId("robot-pip");
  await page.keyboard.down("e");
  await recordFrames(page, 1000);
  await page.keyboard.down("a");
  await page.waitForTimeout(650);
  await expect(pip).toHaveAttribute("data-x", "3");
  await expect(pip).toHaveAttribute("data-facing", "right");
  await expect(game).toHaveAttribute("data-crate", "4,2");
  await expect(page.locator("#move-count")).toHaveText("7 Aktionen");
  const message = await page.locator("#feedback").textContent();
  await page.waitForTimeout(350);
  await expect(page.locator("#feedback")).toHaveText(message!);
  await expect(page.locator("#move-count")).toHaveText("7 Aktionen");
  await page.keyboard.up("a"); await page.keyboard.up("e");
  const samples = await frames(page);
  for (const f of samples) {
    expect(f.crate!.x - f.pip.x).toBeCloseTo(50, 6);
    expect(f.crate!.y).toBe(f.pip.y);
    expect(f.pip.angle).toBeCloseTo(Math.PI / 2, 6);
  }
  expect(new Set(samples.map(f => f.hash)).size).toBeGreaterThan(6);
  await attachEvidence(info, "magnet-canvas-frames.json", samples);
  await page.keyboard.press("z");
  await expect(pip).toHaveAttribute("data-x", "4");
  await expect(game).toHaveAttribute("data-crate", "5,2");
  await page.keyboard.press("z");
  await expect(pip).toHaveAttribute("data-x", "5");
  await expect(game).toHaveAttribute("data-crate", "6,2");
  // Bolt's push uses exactly the same clock and interpolation for its load.
  await page.locator("#room-select").selectOption("freight");
  await keys(page, freightSetup);
  await page.keyboard.down("e");
  await recordFrames(page, 600);
  await page.keyboard.down("s");
  const pushing = await frames(page);
  await page.keyboard.up("s"); await page.keyboard.up("e");
  for (const f of pushing) {
    expect(f.crate!.y - f.bolt.y).toBeCloseTo(50, 6);
    expect(f.crate!.x).toBe(f.bolt.x);
  }
  await expect(game).toHaveAttribute("data-crate", "5,4");
  await expect(page.locator("#move-count")).toHaveText(`${freightSetup.length + 1} Aktionen`);
  await attachEvidence(info, "push-canvas-frames.json", pushing);
});

test("held input resets on E release, commands, focus, hidden tab, frame pause and motion preference", async ({ page }) => {
  await ready(page, "freight");
  const game = page.locator("#game");
  // Every context command must cancel held direction and its pending intention.
  for (const key of ["Shift", "t", "z", "r"]) {
    await page.keyboard.press("r");
    await page.keyboard.press("Shift");
    await page.keyboard.down("d");
    await page.keyboard.press(key);
    const count = await page.locator("#move-count").textContent();
    await page.waitForTimeout(450);
    await expect(page.locator("#move-count")).toHaveText(count!);
    await page.keyboard.up("d");
  }
  for (const reset of ["window", "field", "hidden", "pause", "room", "motion"]) {
    await page.locator("#room-select").selectOption("freight");
    await page.keyboard.press("Shift");
    await page.keyboard.down("d");
    if (reset === "window") await page.evaluate(() => window.dispatchEvent(new Event("blur")));
    if (reset === "field") await page.locator("#room-select").focus();
    if (reset === "hidden") await page.evaluate(() => {
      Object.defineProperty(document, "hidden", { configurable: true, value: true });
      document.dispatchEvent(new Event("visibilitychange"));
      delete (document as unknown as Record<string, unknown>).hidden;
    });
    if (reset === "pause") await page.evaluate(() => { const end = performance.now() + 420; while (performance.now() < end) { /* simulate stalled frame */ } });
    if (reset === "room") await page.locator("#room-select").selectOption("modules");
    if (reset === "motion") await page.emulateMedia({ reducedMotion: "reduce" });
    const count = await page.locator("#move-count").textContent();
    await page.waitForTimeout(450);
    await expect(page.locator("#move-count")).toHaveText(count!);
    await expect(game).toHaveAttribute("data-animating", "false");
    await page.keyboard.up("d");
    await page.emulateMedia({ reducedMotion: "no-preference" });
    await game.focus();
  }
  await page.locator("#room-select").selectOption("modules");
  await keys(page, moduleSolution.slice(0, 5));
  await page.keyboard.down("e"); await page.keyboard.down("a");
  await page.waitForTimeout(60); await page.keyboard.up("e");
  await page.waitForTimeout(450);
  await expect(page.getByTestId("robot-pip")).toHaveAttribute("data-x", "4");
  await expect(game).toHaveAttribute("data-pulling", "false");
  await page.keyboard.up("a");
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.evaluate(() => new Promise<void>(resolve => requestAnimationFrame(() => requestAnimationFrame(() => resolve()))));
  await page.keyboard.press("r");
  await page.keyboard.down("w");
  await page.waitForTimeout(410); await page.keyboard.up("w");
  await expect(page.getByTestId("robot-pip")).toHaveAttribute("data-y", "2");
  await expect(game).toHaveAttribute("data-animating", "false");
  const visual = JSON.parse((await game.getAttribute("data-visual-pip"))!);
  expect(visual.y).toBe(125);
  // Fast discrete taps must not push the held timer into the future in reduce mode.
  await page.locator("#room-select").selectOption("freight");
  await page.keyboard.press("Shift");
  await page.keyboard.press("d"); await page.keyboard.press("d");
  await page.keyboard.down("d");
  await page.waitForTimeout(240); await page.keyboard.up("d");
  await expect(page.getByTestId("robot-bolt")).toHaveAttribute("data-x", "8");
});

test("multiple directions: last pressed wins, aliases release independently, rapid corner tap waits for centre", async ({ page }) => {
  await ready(page, "freight");
  await page.keyboard.press("Shift");
  const bolt = page.getByTestId("robot-bolt"), game = page.locator("#game");
  await page.keyboard.down("d");
  await page.keyboard.down("s"); // replaces direction at next centre
  await page.keyboard.up("s");
  await page.keyboard.up("d");
  await expect(game).toHaveAttribute("data-animating", "false");
  await expect(bolt).toHaveAttribute("data-x", "5");
  await expect(bolt).toHaveAttribute("data-y", "8");
  await page.waitForTimeout(240);
  await expect(page.locator("#move-count")).toHaveText("3 Aktionen");
  await page.keyboard.press("r"); await page.keyboard.press("Shift");
  await page.keyboard.down("d"); await page.keyboard.down("ArrowRight");
  await page.keyboard.up("d");
  await page.waitForTimeout(230); await page.keyboard.up("ArrowRight");
  await expect(game).toHaveAttribute("data-animating", "false");
  await expect(bolt).toHaveAttribute("data-x", "6");
  await expect(bolt).toHaveAttribute("data-y", "7");
  await page.locator("#room-select").selectOption("bodies");
  await keys(page, bodySolution.slice(0, 6));
  await page.keyboard.down("d");
  await expect(game).toHaveAttribute("data-won", "true");
  const count = await page.locator("#move-count").textContent();
  await page.waitForTimeout(400);
  await expect(page.locator("#move-count")).toHaveText(count!);
  await page.keyboard.press("z");
  await page.waitForTimeout(300);
  await expect(game).toHaveAttribute("data-won", "false");
  await page.keyboard.up("d");
});
