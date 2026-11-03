import { restoreGame, type Game } from './engine';

export interface Session {
  game: Game;
  active: number;
  elapsed: number;
  exploded: boolean;
  action: 'reveal' | 'flag' | 'inspect';
  levelId: string | null;
  completed: string[];
}

const MAX_ELAPSED = 7 * 24 * 60 * 60;

/** Versionless saves are the original Classic/Layered envelope. */
export function readSession(raw: string | null, knownLevelIds: readonly string[]): Session | null {
  if (!raw) return null;
  try {
    const saved: unknown = JSON.parse(raw);
    if (!saved || typeof saved !== 'object' || Array.isArray(saved)) return null;
    const data = saved as Record<string, unknown>;
    if (data.version !== undefined && data.version !== 2) return null;
    const game = restoreGame(data.game);
    if (!game) return null;
    const known = new Set(knownLevelIds);
    return {
      game,
      active: typeof data.active === 'number' && Number.isInteger(data.active)
        ? Math.max(0, Math.min(game.config.floors - 1, data.active)) : 0,
      elapsed: typeof data.elapsed === 'number' && Number.isFinite(data.elapsed)
        ? Math.max(0, Math.min(MAX_ELAPSED, Math.floor(data.elapsed))) : 0,
      exploded: data.exploded === true,
      action: data.action === 'flag' || data.action === 'inspect' ? data.action : 'reveal',
      levelId: typeof data.levelId === 'string' && known.has(data.levelId) ? data.levelId : null,
      completed: Array.isArray(data.completed)
        ? [...new Set(data.completed.filter((id): id is string => typeof id === 'string' && known.has(id)))] : [],
    };
  } catch {
    return null;
  }
}

export function writeSession(session: Session): string {
  return JSON.stringify({ ...session, version: 2 });
}
