import os from 'node:os';
import path from 'node:path';

export default function formatDirectory(directory: string): string {
  const resolved = path.resolve(directory);
  const home = os.homedir();
  if (resolved === home) return '~';
  if (resolved.startsWith(`${home}/`)) return `~/${resolved.slice(home.length + 1)}`;
  return resolved;
}
