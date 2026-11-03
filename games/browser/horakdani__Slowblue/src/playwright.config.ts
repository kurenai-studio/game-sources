import { defineConfig } from '@playwright/test';

// Slowblue: e2e runs against the production build on a phone-sized viewport, because
// touch handling and safe-area layout are the things we need to trust.
// Chromium (not WebKit) because the touch-injection test drives raw CDP events.

/**
 * The port, and why it is a variable.
 *
 * `reuseExistingServer` asks one question - does *something* answer on this URL -
 * and it cannot ask the only question that matters, which is whether that
 * something is this game. A static server left on 4173 by an unrelated project on
 * the same machine is therefore a server the whole suite will run against, and it
 * does not fail fast: every spec waits on a `window.__slowblue` that is never coming,
 * and five of them time out at five minutes each before anyone sees a message.
 *
 * So the port can be moved out of the way (`SLOWBLUE_E2E_PORT=4271 npm run e2e`), and
 * setting it also turns reuse off, because a port you had to ask for is a port you
 * want this run to own. `--strictPort` makes the remaining case loud: vite now
 * refuses to start on a taken port rather than quietly picking the next one and
 * leaving `baseURL` pointing at whatever was already there.
 */
const PORT = Number(process.env.SLOWBLUE_E2E_PORT ?? 4173);

export default defineConfig({
  testDir: './e2e',
  timeout: 60_000,
  fullyParallel: false,
  workers: 1,
  reporter: [['list']],
  use: {
    baseURL: `http://127.0.0.1:${PORT}`,
    browserName: 'chromium',
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 3,
    hasTouch: true,
    isMobile: true,
  },
  webServer: {
    command: `npx vite preview --port ${PORT} --strictPort`,
    url: `http://127.0.0.1:${PORT}`,
    reuseExistingServer: !process.env.CI && process.env.SLOWBLUE_E2E_PORT === undefined,
    timeout: 120_000,
  },
});
