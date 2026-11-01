/** Ranks come from total points. They are titles only: they unlock nothing. */
export const RANKS = [
  { name: "Novice", from: 0 },
  { name: "Apprentice", from: 100 },
  { name: "Adept", from: 300 },
  { name: "Expert", from: 700 },
  { name: "Master", from: 1500 },
] as const;

export type RankView = {
  name: string;
  /** The next rank and the points it needs, or null at the top. */
  next: { name: string; at: number } | null;
};

export function rankFor(total: number): RankView {
  let index = 0;
  RANKS.forEach((rank, i) => {
    if (total >= rank.from) index = i;
  });
  const next = RANKS[index + 1];
  return { name: RANKS[index]!.name, next: next ? { name: next.name, at: next.from } : null };
}
