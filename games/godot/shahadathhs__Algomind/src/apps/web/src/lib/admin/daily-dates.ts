/** Today's UTC date as YYYY-MM-DD: the daily challenge changes at midnight UTC. */
export function todayUtc(): string {
  return new Date().toISOString().slice(0, 10);
}

/** "Tue 20 Oct" for a YYYY-MM-DD date, read as UTC so the day never shifts with the time zone. */
export function dayLabel(date: string): string {
  return new Date(`${date}T00:00:00Z`).toLocaleDateString(undefined, {
    timeZone: "UTC",
    weekday: "short",
    day: "numeric",
    month: "short",
  });
}
