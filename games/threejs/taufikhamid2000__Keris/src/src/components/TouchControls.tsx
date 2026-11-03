"use client";

import { useCallback, useEffect, useRef } from "react";
import type { Game, HudState } from "@/game/engine";
import { clampToRadius, joystickVector, lookDelta } from "@/game/touch";

const JOY_R = 56; // px, thumb travel from the stick centre to the edge (run zone)

/** Ask for fullscreen and landscape. Both are best-effort: iPhone Safari allows neither for pages. */
export function enterFullscreenLandscape() {
  try {
    const el = document.documentElement;
    const req = el.requestFullscreen?.bind(el) ?? (el as unknown as { webkitRequestFullscreen?: () => Promise<void> }).webkitRequestFullscreen?.bind(el);
    const p = req?.() as Promise<void> | undefined;
    p?.then?.(() => (screen.orientation as unknown as { lock?: (o: string) => Promise<void> }).lock?.("landscape")?.catch(() => {}))?.catch?.(() => {});
  } catch {
    /* unsupported */
  }
}

interface BtnProps {
  code: string;
  label: string;
  sub?: string;
  cls?: string;
  on?: boolean;
  dim?: boolean;
  game: Game | null;
}

function Btn({ code, label, sub, cls = "", on, dim, game }: BtnProps) {
  const down = useRef<number | null>(null);
  const release = useCallback(() => {
    if (down.current !== null) game?.releaseKey(code);
    down.current = null;
  }, [game, code]);
  return (
    <button
      type="button"
      className={`tbtn ${cls} ${on ? "on" : ""} ${dim ? "dim" : ""}`}
      data-act={code}
      onPointerDown={(e) => {
        e.preventDefault();
        e.currentTarget.setPointerCapture?.(e.pointerId);
        down.current = e.pointerId;
        game?.pressKey(code);
      }}
      onPointerUp={release}
      onPointerCancel={release}
      onLostPointerCapture={release}
      onContextMenu={(e) => e.preventDefault()}
    >
      <b>{label}</b>
      {sub && <i>{sub}</i>}
    </button>
  );
}

export default function TouchControls({ game, hud }: { game: Game | null; hud: HudState }) {
  const base = useRef<HTMLDivElement>(null);
  const knob = useRef<HTMLDivElement>(null);
  const joy = useRef<{ id: number; ox: number; oy: number } | null>(null);
  const lk = useRef<{ id: number; x: number; y: number } | null>(null);

  const setKnob = (dx: number, dy: number, active: boolean) => {
    if (knob.current) knob.current.style.transform = `translate(${dx}px, ${dy}px)`;
    base.current?.classList.toggle("active", active);
  };
  const stopMove = useCallback(() => {
    joy.current = null;
    game?.setTouchMove(0, 0, false);
    setKnob(0, 0, false);
  }, [game]);

  // never leave the player running if the controls unmount or the game changes
  useEffect(() => () => game?.setTouchMove(0, 0, false), [game]);

  const t = hud.prompt;
  return (
    <div className="touch" onContextMenu={(e) => e.preventDefault()}>
      <div
        className="move-zone"
        data-zone="move"
        onPointerDown={(e) => {
          if (joy.current) return;
          e.preventDefault();
          e.currentTarget.setPointerCapture?.(e.pointerId);
          const rect = e.currentTarget.getBoundingClientRect();
          joy.current = { id: e.pointerId, ox: e.clientX, oy: e.clientY };
          if (base.current) {
            base.current.style.left = `${e.clientX - rect.left}px`;
            base.current.style.top = `${e.clientY - rect.top}px`;
          }
          setKnob(0, 0, true);
        }}
        onPointerMove={(e) => {
          const j = joy.current;
          if (!j || j.id !== e.pointerId) return;
          const dx = e.clientX - j.ox;
          const dy = e.clientY - j.oy;
          const v = joystickVector(dx, dy, JOY_R);
          game?.setTouchMove(v.x, v.y, v.run);
          const c = clampToRadius(dx, dy, JOY_R);
          setKnob(c.x, c.y, true);
          base.current?.classList.toggle("run", v.run);
        }}
        onPointerUp={(e) => joy.current?.id === e.pointerId && stopMove()}
        onPointerCancel={(e) => joy.current?.id === e.pointerId && stopMove()}
        onLostPointerCapture={(e) => joy.current?.id === e.pointerId && stopMove()}
      >
        <div className="joy-hint">MOVE</div>
        <div className="joy-base" ref={base}>
          <div className="joy-knob" ref={knob} />
        </div>
      </div>

      <div
        className="look-zone"
        data-zone="look"
        onPointerDown={(e) => {
          if (lk.current) return;
          e.preventDefault();
          e.currentTarget.setPointerCapture?.(e.pointerId);
          lk.current = { id: e.pointerId, x: e.clientX, y: e.clientY };
        }}
        onPointerMove={(e) => {
          const l = lk.current;
          if (!l || l.id !== e.pointerId) return;
          const d = lookDelta(e.clientX - l.x, e.clientY - l.y);
          l.x = e.clientX;
          l.y = e.clientY;
          game?.look(d.dx, d.dy);
        }}
        onPointerUp={(e) => {
          if (lk.current?.id === e.pointerId) lk.current = null;
        }}
        onPointerCancel={(e) => {
          if (lk.current?.id === e.pointerId) lk.current = null;
        }}
        onLostPointerCapture={(e) => {
          if (lk.current?.id === e.pointerId) lk.current = null;
        }}
      />

      <button
        type="button"
        className="tbtn pause-btn"
        aria-label="Pause"
        data-act="Pause"
        onPointerDown={(e) => {
          e.preventDefault();
          game?.pause();
        }}
      >
        II
      </button>

      <div className="btn-grid">
        <Btn game={game} code="KeyV" label="V" sub="Mata Helang" cls="eagle" on={hud.eagle} />
        <Btn game={game} code="KeyF" label="F" sub={hud.carrying ? "Drop" : "Carry"} cls="carry" on={hud.carrying || t.startsWith("F")} />
        <Btn game={game} code="KeyC" label="C" sub="Crouch" cls="crouch" on={hud.crouched} />
        <Btn game={game} code="KeyQ" label="Q" sub={`Lempar x${hud.knives}`} cls="throw" dim={hud.knives <= 0} />
        <Btn game={game} code="KeyE" label="E" sub="Tikam" cls="stab" on={t.startsWith("E")} />
        <Btn game={game} code="Space" label="Jump" sub="Climb" cls="jump" />
      </div>
    </div>
  );
}
