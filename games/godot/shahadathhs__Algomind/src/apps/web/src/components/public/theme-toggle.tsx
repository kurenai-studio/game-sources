"use client";

import { useSyncExternalStore } from "react";
import { Key } from "@/components/ui/key";
import {
  isTheme,
  otherTheme,
  THEME_CHANGE_EVENT,
  THEME_STORAGE_KEY,
  type Theme,
} from "@/lib/theme";

const DARK_QUERY = "(prefers-color-scheme: dark)";

function currentTheme(): Theme {
  const attr = document.documentElement.dataset.theme;
  if (isTheme(attr)) return attr;
  return window.matchMedia(DARK_QUERY).matches ? "dark" : "light";
}

function subscribe(onChange: () => void): () => void {
  const media = window.matchMedia(DARK_QUERY);
  media.addEventListener("change", onChange);
  window.addEventListener(THEME_CHANGE_EVENT, onChange);
  return () => {
    media.removeEventListener("change", onChange);
    window.removeEventListener(THEME_CHANGE_EVENT, onChange);
  };
}

// No theme is known on the server (it depends on the visitor's device), so the button is not
// rendered until the client takes over.
const serverTheme = (): Theme | null => null;

/**
 * Light/dark toggle, a progressive enhancement. The page follows prefers-color-scheme with no
 * JavaScript; the button only appears once this component has hydrated, so there is never a dead
 * control. The choice is kept in localStorage on the device only.
 */
export function ThemeToggle() {
  const theme = useSyncExternalStore<Theme | null>(subscribe, currentTheme, serverTheme);

  function toggle() {
    const next = otherTheme(theme ?? currentTheme());
    document.documentElement.dataset.theme = next;
    try {
      localStorage.setItem(THEME_STORAGE_KEY, next);
    } catch {
      // Storage can be blocked; the choice then lasts until the page closes.
    }
    window.dispatchEvent(new Event(THEME_CHANGE_EVENT));
  }

  // The wrapper reserves the button's space so the header does not shift when it appears.
  return (
    <span className="inline-block h-11 w-11">
      {theme && (
        <Key lip={3}>
          <button
            type="button"
            onClick={toggle}
            aria-label={`Theme: ${theme}. Switch to ${otherTheme(theme)}.`}
            className="tile flex h-11 w-11 items-center justify-center bg-tile text-[13px] tracking-[1px] text-ink"
            style={{ ["--chamfer" as string]: "10px" }}
          >
            <span aria-hidden="true">{theme === "dark" ? "DK" : "LT"}</span>
          </button>
        </Key>
      )}
    </span>
  );
}
