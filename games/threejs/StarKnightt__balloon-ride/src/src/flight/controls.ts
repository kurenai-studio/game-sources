/**
 * Keys and touch. Space held = burner, S held = vent, V = basket / chase view, T = next time of
 * day, C = cinematic camera, M = mute, H = a tiny controls hint (hidden by default, bottom left).
 * On touch screens: a burner button (flame) bottom left, vent bottom right, a small V button above
 * the vent; hold to act, drag anywhere else to look around. No other text anywhere on screen.
 */
import { PHONE } from "../core/tier";

export interface ControlHooks {
  view: () => void;
  time: () => void;
  cinematic: () => void;
  mute: () => void;
  first: () => void;
}

export class Controls {
  burner = false;
  vent = false;
  private touchBurn = false;
  private touchVent = false;
  private hint: HTMLDivElement;
  /** Touch buttons (hidden while the cinematic runs). */
  private readonly buttons: HTMLElement[] = [];

  constructor(on: ControlHooks) {
    const key = (e: KeyboardEvent, v: boolean) => {
      if (e.code === "Space") {
        e.preventDefault();
        this.burner = v;
      } else if (e.code === "KeyS" || e.code === "ArrowDown") {
        this.vent = v;
      } else if (v && !e.repeat) {
        if (e.code === "KeyV") on.view();
        else if (e.code === "KeyT") on.time();
        else if (e.code === "KeyC") on.cinematic();
        else if (e.code === "KeyM") on.mute();
        else if (e.code === "KeyH") this.toggleHint();
      }
    };
    addEventListener("keydown", (e) => {
      on.first();
      key(e, true);
    });
    addEventListener("keyup", (e) => key(e, false));
    addEventListener("pointerdown", on.first);
    addEventListener("blur", () => {
      this.burner = this.vent = this.touchBurn = this.touchVent = false;
    });

    const touch = PHONE || matchMedia("(pointer: coarse)").matches;
    const hint = document.createElement("div");
    hint.style.cssText =
      `position:fixed;left:16px;bottom:${touch ? 118 : 14}px;display:none;pointer-events:none;` +
      "font:italic 13px/1.65 'Iowan Old Style','Palatino Linotype',Palatino,Georgia,serif;letter-spacing:.02em;" +
      "color:rgba(255,250,240,.92);background:rgba(40,28,22,.22);backdrop-filter:blur(3px);-webkit-backdrop-filter:blur(3px);" +
      "padding:7px 12px 8px;border-radius:10px;text-shadow:0 1px 2px rgba(50,25,10,.35);white-space:pre";
    hint.textContent = touch
      ? "flame  burner     ·     vent  sink\nV  view     ·     drag  look"
      : "space  burner   ·   S  vent\nV  view   ·   T  time of day\nC  cinematic   ·   M  sound\ndrag  look   ·   wheel  zoom";
    document.body.appendChild(hint);
    this.hint = hint;

    if (touch) {
      const btn = (css: string, size: number, label: string, icon: string, hold: ((v: boolean) => void) | null, tap?: () => void) => {
        const b = document.createElement("div");
        b.dataset.btn = "1";
        b.setAttribute("role", "button");
        b.setAttribute("aria-label", label);
        b.style.cssText =
          `position:fixed;${css};width:${size}px;height:${size}px;border-radius:50%;display:flex;align-items:center;justify-content:center;` +
          "background:rgba(255,244,225,.2);border:1.5px solid rgba(255,244,225,.55);touch-action:none;user-select:none;-webkit-user-select:none;" +
          "backdrop-filter:blur(3px);-webkit-backdrop-filter:blur(3px);transition:background .12s";
        b.innerHTML = icon;
        const down = (e: PointerEvent) => {
          e.stopPropagation();
          e.preventDefault();
          on.first();
          hold?.(true);
          tap?.();
          b.style.background = "rgba(255,244,225,.42)";
        };
        const up = () => {
          hold?.(false);
          b.style.background = "rgba(255,244,225,.2)";
        };
        b.addEventListener("pointerdown", down);
        b.addEventListener("pointerup", up);
        b.addEventListener("pointercancel", up);
        b.addEventListener("pointerleave", up);
        b.addEventListener("contextmenu", (e) => e.preventDefault());
        document.body.appendChild(b);
        this.buttons.push(b);
      };
      const pad = "max(18px, env(safe-area-inset-bottom))";
      const flame =
        '<svg width="30" height="38" viewBox="0 0 30 38"><defs><radialGradient id="fl" cx="50%" cy="72%" r="60%">' +
        '<stop offset="0" stop-color="#fff4c2"/><stop offset=".5" stop-color="#ffb347"/><stop offset="1" stop-color="#e8622a"/></radialGradient></defs>' +
        '<path d="M15 2c2 7 10 11 10 21a10 10 0 0 1-20 0c0-5 3-8 5-11 0 4 2 6 4 6-2-6 0-11 1-16z" fill="url(#fl)" stroke="rgba(255,240,220,.7)" stroke-width="1"/></svg>';
      const vent =
        '<svg width="34" height="30" viewBox="0 0 34 30" fill="none" stroke="#fff4e1" stroke-width="2.4" stroke-linecap="round">' +
        '<path d="M5 8h24M9 15h16M13 22h8"/><path d="M17 24v4M14 26l3 3 3-3" stroke-width="2"/></svg>';
      const eye =
        '<svg width="24" height="18" viewBox="0 0 24 18" fill="none" stroke="#fff4e1" stroke-width="2" stroke-linecap="round">' +
        '<path d="M2 9c3-5 7-7 10-7s7 2 10 7c-3 5-7 7-10 7S5 14 2 9z"/><circle cx="12" cy="9" r="3"/></svg>';
      btn(`left:max(20px, env(safe-area-inset-left));bottom:${pad}`, 80, "burner", flame, (v) => (this.touchBurn = v));
      btn(`right:max(20px, env(safe-area-inset-right));bottom:${pad}`, 80, "vent", vent, (v) => (this.touchVent = v));
      btn(`right:calc(max(20px, env(safe-area-inset-right)) + 14px);bottom:calc(${pad} + 96px)`, 52, "view", eye, null, on.view);
    }
  }

  toggleHint(): void {
    this.hint.style.display = this.hint.style.display === "none" ? "block" : "none";
  }

  /** Hide the touch buttons (the cinematic). */
  setButtons(visible: boolean): void {
    for (const b of this.buttons) b.style.display = visible ? "flex" : "none";
  }

  get burning(): boolean {
    return this.burner || this.touchBurn;
  }

  get venting(): boolean {
    return this.vent || this.touchVent;
  }
}
