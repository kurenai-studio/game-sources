/** What is stored for one solved level. */
export type StoredCompletion = {
  levelVersion: number;
  bestCommands: number;
  completedAt: Date;
};

export type IncomingCompletion = StoredCompletion;

/** What to do with a stored row after seeing a completion from a device. */
export type MergeResult = { action: "none" } | { action: "update"; data: StoredCompletion };

/**
 * The merge rule for one level, the same on every device and every time:
 *  - the newer level version wins, because a score is never read against different content;
 *  - for the same version the fewer commands win;
 *  - an older version never replaces a newer one;
 *  - the earliest completion time is always kept.
 * Applying the same incoming completion again changes nothing (idempotent).
 */
export function mergeCompletion(
  stored: StoredCompletion,
  incoming: IncomingCompletion,
): MergeResult {
  const earliest =
    incoming.completedAt < stored.completedAt ? incoming.completedAt : stored.completedAt;
  let next: StoredCompletion;
  if (incoming.levelVersion > stored.levelVersion) {
    next = {
      levelVersion: incoming.levelVersion,
      bestCommands: incoming.bestCommands,
      completedAt: earliest,
    };
  } else if (incoming.levelVersion === stored.levelVersion) {
    next = {
      levelVersion: stored.levelVersion,
      bestCommands: Math.min(incoming.bestCommands, stored.bestCommands),
      completedAt: earliest,
    };
  } else {
    next = { ...stored, completedAt: earliest };
  }
  const unchanged =
    next.levelVersion === stored.levelVersion &&
    next.bestCommands === stored.bestCommands &&
    next.completedAt.getTime() === stored.completedAt.getTime();
  return unchanged ? { action: "none" } : { action: "update", data: next };
}

/** Last write wins by the player's own timestamp; an equal or older one changes nothing. */
export function shouldReplaceSettings(
  storedUpdatedAt: Date | null,
  incomingUpdatedAt: Date,
): boolean {
  return storedUpdatedAt === null || incomingUpdatedAt > storedUpdatedAt;
}
