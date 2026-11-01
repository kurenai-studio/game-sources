import { readFileSync, readdirSync } from 'node:fs';
import { resolve } from 'node:path';

const dist = resolve('dist');
const index = readFileSync(resolve(dist, 'index.html'), 'utf8');
const license = readFileSync(resolve(dist, 'LICENSE'), 'utf8');
const notices = readFileSync(resolve(dist, 'THIRD_PARTY_NOTICES.txt'), 'utf8');
const assetNames = readdirSync(resolve(dist, 'assets'));

if (!index.includes('Content-Security-Policy') || !index.includes('./assets/')) {
  throw new Error('Production HTML is missing the CSP or relative asset URLs');
}
if (!license.includes('Copyright (c) 2026 appleweiping')) {
  throw new Error('Project license was not shipped with the distribution');
}
if (!notices.includes('Richard Davey, Phaser Studio Inc.') || !notices.includes('Arnout Kazemier')) {
  throw new Error('Third-party MIT notices were not shipped with the distribution');
}
if (assetNames.some((name) => name.endsWith('.map'))) {
  throw new Error('Production source maps must not be shipped');
}

console.log(`Verified production artifact: ${assetNames.length} bundled assets and complete legal notices.`);
