/** localStorage key for the visitor's explicit theme choice (never sent anywhere). */
export const THEME_STORAGE_KEY = "algomind-theme";

/** Fired on window after the toggle changes the theme, so subscribers re-read it. */
export const THEME_CHANGE_EVENT = "algomind-theme-change";

export type Theme = "light" | "dark";

export function isTheme(value: unknown): value is Theme {
  return value === "light" || value === "dark";
}

export function otherTheme(theme: Theme): Theme {
  return theme === "dark" ? "light" : "dark";
}

/**
 * Runs in the head before first paint so a saved choice does not flash. Without it, or without
 * JavaScript, the page simply follows prefers-color-scheme (see tokens.css).
 */
export const THEME_INIT_SCRIPT = `try{var t=localStorage.getItem(${JSON.stringify(THEME_STORAGE_KEY)});if(t==="light"||t==="dark")document.documentElement.dataset.theme=t}catch(e){}`;
