import type { LevelStat } from "./social-api";

/** Solvers falling by at least this share from the level before marks a hard step. */
export const SHARP_DROP = 0.4;
/** A drop is only called sharp when the earlier level had at least this many solvers. */
export const MIN_SOLVERS_FOR_DROP = 5;

export type StatRow = LevelStat & {
  /** Share of solvers lost against the previous level in campaign order; null for the first. */
  drop: number | null;
  sharp: boolean;
};

export type StatGroup = { key: string; title: string; rows: StatRow[] };

/** Percent of `part` in `whole`, rounded; "-" when nobody solved the level. */
export function percentOf(part: number, whole: number): string {
  return whole === 0 ? "-" : `${Math.round((part / whole) * 100)}%`;
}

/** Drop-off against the previous campaign level, then groups by world and chapter. Pool last. */
export function groupStats(items: LevelStat[]): StatGroup[] {
  const groups: StatGroup[] = [];
  let previous: LevelStat | null = null;
  for (const item of items) {
    const pool = item.pool || item.world === null;
    const key = pool ? "pool" : `${item.world}/${item.chapter}`;
    const title = pool ? "Daily pool" : `${item.world} / ${item.chapter}`;
    let group = groups.find((g) => g.key === key);
    if (!group) groups.push((group = { key, title, rows: [] }));
    let drop: number | null = null;
    if (!pool && previous && previous.solvers > 0)
      drop = (previous.solvers - item.solvers) / previous.solvers;
    const sharp =
      drop !== null && drop >= SHARP_DROP && (previous?.solvers ?? 0) >= MIN_SOLVERS_FOR_DROP;
    group.rows.push({ ...item, drop, sharp });
    if (!pool) previous = item;
  }
  groups.sort((a, b) => Number(a.key === "pool") - Number(b.key === "pool"));
  return groups;
}

/** The drop-off as words: "40% fewer solvers", "10% more", "No change", or "-" for the first. */
export function dropText(row: StatRow): string {
  if (row.drop === null) return "-";
  const pct = Math.round(Math.abs(row.drop) * 100);
  if (pct === 0) return "No change";
  return row.drop > 0 ? `${pct}% fewer` : `${pct}% more`;
}
