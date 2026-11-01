#!/usr/bin/env node

/**
 * Zips the production `dist` folder using the system `zip` command and fails if
 * the archive exceeds the js13kGames limit.
 */
import { execFileSync } from 'node:child_process';
import { readdir, rm, stat } from 'node:fs/promises';
import { join } from 'node:path';

const LIMIT_BYTES = 13 * 1024;
const DIST_PATH = 'dist';
const ZIP_PATH = 'dist.zip';

async function getDirectorySize(dir) {
  let total = 0;
  const entries = await readdir(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = join(dir, entry.name);
    if (entry.isDirectory()) {
      total += await getDirectorySize(fullPath);
    } else {
      const stats = await stat(fullPath);
      total += stats.size;
    }
  }
  return total;
}

async function main() {
  const unpacked = await getDirectorySize(DIST_PATH);
  await rm(ZIP_PATH, { force: true });
  execFileSync('zip', ['-r', '-q', ZIP_PATH, DIST_PATH]);
  const zipped = (await stat(ZIP_PATH)).size;

  console.log(`Unpacked: ${unpacked} bytes`);
  console.log(`Zipped:   ${zipped} bytes (limit ${LIMIT_BYTES} bytes)`);

  if (zipped > LIMIT_BYTES) {
    console.error(
      `Build exceeds js13kGames limit by ${zipped - LIMIT_BYTES} bytes.`,
    );
    process.exit(1);
  }

  console.log('Build is within the js13kGames size limit.');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
