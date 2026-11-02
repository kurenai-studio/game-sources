import path from 'node:path';
import { fs as memfs, vol } from 'memfs';

interface FsConfig {
  [key: string]: string | FsConfig;
}

function flatten(
  config: FsConfig,
  basePath: string,
): { files: Record<string, string>; dirs: string[] } {
  const files: Record<string, string> = {};
  const dirs: string[] = [];

  for (const [key, value] of Object.entries(config)) {
    const fullPath = basePath ? `${basePath}/${key}` : key;
    if (typeof value === 'string') {
      files[fullPath] = value;
    } else if (Object.keys(value).length === 0) {
      dirs.push(fullPath);
    } else {
      const nested = flatten(value, fullPath);
      Object.assign(files, nested.files);
      dirs.push(...nested.dirs);
    }
  }

  return { files, dirs };
}

/**
 * Sets up an in-memory filesystem from a nested config (mock-fs compatible).
 * Use with vi.mock('node:fs') pointing to memfs.
 */
export function mockFs(config: FsConfig): void {
  vol.reset();
  const { files, dirs } = flatten(config, '');
  if (Object.keys(files).length > 0) {
    vol.fromJSON(files);
  }
  for (const dir of dirs) {
    vol.mkdirSync(dir, { recursive: true });
  }
}

mockFs.restore = () => vol.reset();

/**
 * Converts a glob pattern to a regex. Supports `*` (single segment) and `**` (any depth).
 */
function globToRegex(pattern: string): RegExp {
  const escaped = pattern
    .split('/')
    .map((seg) =>
      seg === '**'
        ? '.*'
        : seg
            .replace(/[.+^${}()|[\]\\]/g, '\\$&')
            .replace(/\*/g, '[^/]*')
            .replace(/\?/g, '[^/]'),
    )
    .join('/');
  return new RegExp(`^${escaped}$`);
}

/**
 * Minimal globbySync replacement that reads from memfs.
 * Supports `*` and `**` glob patterns.
 */
export function memfsGlobbySync(
  patterns: string | string[],
  options: { cwd?: string; onlyDirectories?: boolean } = {},
): string[] {
  const patternList = Array.isArray(patterns) ? patterns : [patterns];
  const cwd = options.cwd ?? '/';
  const results: string[] = [];

  // Find the deepest non-glob base directory for a pattern
  function getBaseDir(pattern: string): string {
    const parts = pattern.split('/');
    const base: string[] = [];
    for (const part of parts) {
      if (part.includes('*') || part.includes('?')) break;
      base.push(part);
    }
    return base.join('/') || '/';
  }

  for (const pattern of patternList) {
    const isAbsolute = path.isAbsolute(pattern);
    const fullPattern = isAbsolute ? pattern : path.join(cwd, pattern);
    const baseDir = getBaseDir(fullPattern);
    const regex = globToRegex(fullPattern);

    let entries: string[];
    try {
      entries = memfs.readdirSync(baseDir, { recursive: true }) as string[];
    } catch {
      continue;
    }

    for (const entry of entries) {
      const fullPath = path.join(baseDir, String(entry));

      if (options.onlyDirectories) {
        try {
          if (!memfs.statSync(fullPath).isDirectory()) continue;
        } catch {
          continue;
        }
      } else {
        try {
          if (memfs.statSync(fullPath).isDirectory()) continue;
        } catch {
          continue;
        }
      }

      if (regex.test(fullPath)) {
        if (isAbsolute) {
          results.push(fullPath);
        } else {
          results.push(path.relative(cwd, fullPath));
        }
      }
    }
  }

  return results;
}
