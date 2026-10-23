// Every browser test imports test and expect from here. In Chromium each
// test records which parts of the page's own scripts ran, for
// scripts/browser-coverage.js to merge into a coverage report.

import { test as base, expect } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

export const COVERAGE_DIR = path.resolve('coverage/browser');

export const test = base.extend({
  recordCoverage: [async ({ page, browserName }, use, testInfo) => {
    if (browserName !== 'chromium') {
      await use();
      return;
    }
    await page.coverage.startJSCoverage({ resetOnNavigation: false });
    await use();
    const entries = (await page.coverage.stopJSCoverage()).filter(entry => /\/script\.js$/.test(new URL(entry.url).pathname));
    fs.mkdirSync(COVERAGE_DIR, { recursive: true });
    fs.writeFileSync(path.join(COVERAGE_DIR, `${testInfo.testId}-${testInfo.repeatEachIndex}.json`), JSON.stringify(entries));
  }, { auto: true }]
});

export { expect };
