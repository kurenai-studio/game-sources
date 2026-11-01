/** Time windows for the points boards. Weeks start on Monday, all in UTC. */
export type Period = "all" | "week" | "month";

const FAR_PAST = new Date(Date.UTC(2000, 0, 1));
const FAR_FUTURE = new Date(Date.UTC(2100, 0, 1));

/** The half-open range [from, to) of a period that contains `now`. */
export function periodRange(period: Period, now: Date): { from: Date; to: Date } {
  if (period === "all") return { from: FAR_PAST, to: FAR_FUTURE };
  if (period === "month") {
    const from = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
    return { from, to: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1)) };
  }
  const day = (now.getUTCDay() + 6) % 7; // Monday is 0
  const from = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - day));
  return { from, to: new Date(from.getTime() + 7 * 24 * 60 * 60 * 1000) };
}
