// Clears coverage from earlier runs, so each report reflects one full run.
import fs from 'node:fs';
import { COVERAGE_DIR } from './fixtures.js';

export default function globalSetup() {
  fs.rmSync(COVERAGE_DIR, { recursive: true, force: true });
}
