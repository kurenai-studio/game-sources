const MINUTE = 60;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;
const WEEK = 7 * DAY;
const MONTH = 30 * DAY;
const YEAR = 365 * DAY;

function pluralize(count: number, unit: string): string {
  return `${count} ${unit}${count === 1 ? '' : 's'} ago`;
}

export function formatRelativeTime(isoString: string): string {
  const seconds = Math.floor((Date.now() - new Date(isoString).getTime()) / 1000);

  if (seconds < MINUTE) return 'just now';
  if (seconds < HOUR) return pluralize(Math.floor(seconds / MINUTE), 'minute');
  if (seconds < DAY) return pluralize(Math.floor(seconds / HOUR), 'hour');
  if (seconds < WEEK) return pluralize(Math.floor(seconds / DAY), 'day');
  if (seconds < MONTH) return pluralize(Math.floor(seconds / WEEK), 'week');
  if (seconds < YEAR) return pluralize(Math.floor(seconds / MONTH), 'month');
  return pluralize(Math.floor(seconds / YEAR), 'year');
}
