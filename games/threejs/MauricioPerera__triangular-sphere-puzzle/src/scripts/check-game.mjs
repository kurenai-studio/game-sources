import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const gameFile = resolve(root, 'game', 'GAME.md');
const generatedFile = resolve(root, 'game', 'game-data.generated.js');
const lint = resolve(root, 'vendor', 'game-protocol', 'tools', 'game-lint.js');
const exportTool = resolve(root, 'vendor', 'game-protocol', 'tools', 'game-export.js');
const command = process.argv[2] ?? 'check';

if (!existsSync(gameFile)) {
  console.error(`Missing ${gameFile}. Create the game's GAME.md first.`);
  process.exit(2);
}
mkdirSync(resolve(root, 'game'), { recursive: true });

function run(label, script, args) {
  console.log(`\n== ${label} ==`);
  const result = spawnSync(process.execPath, [script, ...args], {
    cwd: root,
    stdio: 'inherit',
    env: process.env,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}

if (command === 'lint' || command === 'check') run('GAME lint', lint, [gameFile]);
if (command === 'build' || command === 'check') run('GAME export', exportTool, [gameFile, generatedFile]);
if (!['lint', 'build', 'check'].includes(command)) {
  console.error(`Unknown command: ${command}. Use lint, build, or check.`);
  process.exit(2);
}
console.log(`\nGAME Protocol OK: ${generatedFile}`);
