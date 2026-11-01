// @ts-check
// Browser smoke test of the dashboard's publish flow, against a running API and web app.
// It signs in, builds a small solvable level, records a playtest, places the level in a new
// chapter, publishes it, then archives it and removes the world and chapter it created.
// The level stays in the database as an archived "Smoke" level. Use a local or scratch database.
//
//   make db-up api-dev     (one terminal)      make web-dev      (another)
//   E2E_EMAIL=... E2E_PASSWORD=... make web-smoke
//
// Needs Google Chrome (playwright-core drives the installed browser).
import { chromium } from "playwright-core";

const BASE = process.env.BASE_URL ?? "http://localhost:3000";
const EMAIL = process.env.E2E_EMAIL;
const PASSWORD = process.env.E2E_PASSWORD;
if (!EMAIL || !PASSWORD) {
  console.error(
    "Set E2E_EMAIL and E2E_PASSWORD to an admin account that needs no password change.",
  );
  process.exit(2);
}

const stamp = Date.now().toString(36);
const title = `Smoke ${stamp}`;
const world = `Smoke world ${stamp}`;
const chapter = `Smoke chapter ${stamp}`;

const browser = await chromium.launch({ channel: "chrome", headless: true });
const page = await (await browser.newContext({ viewport: { width: 1000, height: 900 } })).newPage();
page.setDefaultTimeout(10000);
const problems = [];
page.on("pageerror", (e) => problems.push(`page error: ${e.message}`));
page.on("console", (m) => m.type() === "error" && problems.push(`console: ${m.text()}`));

let failed = false;
async function step(name, fn) {
  try {
    await fn();
    console.log(`ok    ${name}`);
  } catch (e) {
    failed = true;
    console.log(`FAIL  ${name}: ${String(e.message).split("\n")[0]}`);
  }
}
const loaded = (text) => page.getByText(text).waitFor({ state: "hidden" });

await step("sign in", async () => {
  await page.goto(`${BASE}/admin/sign-in`);
  await page.getByLabel("Email").fill(EMAIL);
  await page.getByLabel("Password").fill(PASSWORD);
  await page.getByRole("button", { name: /sign in/i }).click();
  await page.waitForURL(/\/admin$/);
});

await step("create the world and chapter", async () => {
  await page.goto(`${BASE}/admin/campaign`);
  await loaded("Loading campaign");
  await page.getByRole("button", { name: "Add world" }).click();
  await page.getByLabel("World title").fill(world);
  await page.getByRole("button", { name: "Add world" }).last().click();
  await page.getByText("World added.").waitFor();
  await page.getByRole("button", { name: `Add chapter to ${world}` }).click();
  await page.getByLabel(`Chapter title in ${world}`).fill(chapter);
  await page.getByRole("button", { name: "Add chapter", exact: true }).click();
  await page.getByText("Chapter added.").waitFor();
});

let levelUrl = "";
await step("create the level", async () => {
  await page.goto(`${BASE}/admin/levels`);
  await loaded("Loading levels");
  await page.getByRole("button", { name: "New level" }).click();
  await page.getByLabel("Title").fill(title);
  await page.getByRole("button", { name: "Create level" }).click();
  await page.waitForURL(/\/admin\/levels\/[0-9a-f-]{36}/);
  levelUrl = page.url();
});

await step("write a solution and save the draft", async () => {
  await page.getByRole("tab", { name: "Solution" }).click();
  const add = (name) => page.getByRole("button", { name: `Add ${name}` });
  for (let i = 0; i < 4; i += 1) await add("Move forward").click();
  await add("Turn right").click();
  for (let i = 0; i < 4; i += 1) await add("Move forward").click();
  await page.getByRole("button", { name: "Save draft" }).click();
  await page.getByRole("status").filter({ hasText: "Saved" }).waitFor();
});

await step("record a solved playtest", async () => {
  await page.getByRole("tab", { name: "Playtest" }).click();
  await page.getByLabel("Tester").fill("Smoke test");
  await page.getByRole("button", { name: "Record playtest" }).click();
  await page.getByText("Smoke test").first().waitFor();
});

await step("place the level in the chapter", async () => {
  await page.goto(`${BASE}/admin/campaign`);
  await loaded("Loading campaign");
  await page.getByLabel(`Place ${title} in`).selectOption({ label: `${world} / ${chapter}` });
  await page.getByRole("button", { name: "Save order" }).click();
  await page.getByText("Order saved.").waitFor();
});

await step("publish", async () => {
  await page.goto(levelUrl.replace("/levels/", "/publish/"));
  const publish = page.getByRole("button", { name: "Publish", exact: true });
  await publish.waitFor();
  await page.waitForFunction(
    () => !document.querySelector("button[disabled]")?.textContent?.includes("Publish"),
  );
  await publish.click();
  await page.getByRole("heading", { name: "Published" }).waitFor();
});

await step("the level is live in the public catalog", async () => {
  const api = process.env.API_URL ?? "http://localhost:8000/v1";
  const res = await fetch(`${api}/levels`);
  const text = await res.text();
  if (!res.ok || !text.includes(title))
    throw new Error(`catalog status ${res.status}, level missing`);
});

await step("unpublish and archive", async () => {
  await page.goto(levelUrl);
  await page.getByRole("button", { name: "Unpublish", exact: true }).click();
  await page.getByRole("button", { name: "Unpublish and archive" }).click();
  await page.getByText("The level is archived").waitFor();
});

await step("remove the chapter and world", async () => {
  await page.goto(`${BASE}/admin/campaign`);
  await loaded("Loading campaign");
  await page.getByLabel(`Place ${title} in`).selectOption({ label: "Unassigned" });
  await page.getByRole("button", { name: "Save order" }).click();
  await page.getByText("Order saved.").waitFor();
  page.once("dialog", (d) => d.accept());
  await page.getByRole("button", { name: `Delete chapter ${chapter}` }).click();
  await page.getByText("Chapter deleted.").waitFor();
  page.once("dialog", (d) => d.accept());
  await page.getByRole("button", { name: `Delete world ${world}` }).click();
  await page.getByText("World deleted.").waitFor();
});

if (problems.length > 0) {
  failed = true;
  console.log(`Browser errors:\n  ${problems.join("\n  ")}`);
}
await browser.close();
console.log(failed ? "Smoke test FAILED" : "Smoke test passed");
process.exit(failed ? 1 : 0);
