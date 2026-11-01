const STORAGE_KEY = "projectile-defense:high-score";

export function getHighScore(): number {
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    const value = raw === null ? 0 : Number(raw);
    return Number.isFinite(value) ? value : 0;
  } catch {
    return 0;
  }
}

export function setHighScore(score: number): void {
  try {
    window.localStorage.setItem(STORAGE_KEY, String(score));
  } catch {
    // Storage unavailable (private mode, blocked, etc.) - ignore.
  }
}
