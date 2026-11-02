import { parseArgs as cittyParseArgs } from 'citty';

interface ParsedArgs {
  directory: string;
  level: number | undefined;
  silent: boolean;
}

const argsDef = {
  directory: {
    type: 'string' as const,
    alias: 'd',
    default: '.',
    description: 'Run under given directory',
  },
  level: {
    type: 'string' as const,
    alias: 'l',
    description: 'Practice level (epic mode only)',
  },
  silent: {
    type: 'boolean' as const,
    alias: 's',
    default: false,
    description: 'Suppress play log',
  },
};

function parseArgs(args: string[]): ParsedArgs {
  const parsed = cittyParseArgs(args, argsDef);

  const level = parsed.level !== undefined ? Number.parseInt(parsed.level, 10) : undefined;
  if (level !== undefined && Number.isNaN(level)) {
    throw new Error('Invalid argument: level must be a number');
  }

  return { directory: parsed.directory, level, silent: parsed.silent };
}

export default parseArgs;
