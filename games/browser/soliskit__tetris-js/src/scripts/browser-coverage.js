// Merges the browser coverage recorded by the Chromium tests into one
// report for public/script.js, prints it, writes an HTML report to
// coverage/browser-report/ and fails when coverage is below the threshold.

import fs from 'node:fs';
import path from 'node:path';
import libCoverage from 'istanbul-lib-coverage';
import libReport from 'istanbul-lib-report';
import reports from 'istanbul-reports';
import v8ToIstanbul from 'v8-to-istanbul';

export const THRESHOLD = 100;

const root = path.resolve('.');
const sourceFile = path.join(root, 'public/script.js');
const coverageDir = path.join(root, 'coverage/browser');

const files = fs.existsSync(coverageDir) ? fs.readdirSync(coverageDir).filter(file => file.endsWith('.json')) : [];
if (files.length === 0) {
  console.error('No browser coverage found. Run the browser tests first: npm run test:e2e');
  process.exit(1);
}

const map = libCoverage.createCoverageMap({});
const source = fs.readFileSync(sourceFile, 'utf8');
for (const file of files) {
  for (const entry of JSON.parse(fs.readFileSync(path.join(coverageDir, file), 'utf8'))) {
    const converter = v8ToIstanbul(sourceFile, 0, { source });
    await converter.load();
    converter.applyCoverage(entry.functions);
    map.merge(converter.toIstanbul());
  }
}

const context = libReport.createContext({ dir: path.join(root, 'coverage/browser-report'), coverageMap: map });
reports.create('text').execute(context);
reports.create('html').execute(context);

const summary = map.getCoverageSummary();
const failures = ['lines', 'branches', 'functions']
  .filter(kind => summary[kind].pct < THRESHOLD)
  .map(kind => `${kind} ${summary[kind].pct}%`);
if (failures.length > 0) {
  console.error(`Browser coverage of public/script.js is below ${THRESHOLD}%: ${failures.join(', ')}`);
  process.exit(1);
}
console.log(`Browser coverage of public/script.js: ${THRESHOLD}% of lines, branches and functions.`);
