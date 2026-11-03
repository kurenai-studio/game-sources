"use client";

import { useEffect, useRef, useState, useSyncExternalStore } from "react";
import type { Game, HudState, IntroView, LoseReason, Phase } from "@/game/engine";
import { isTouchDevice, pickQuality, qualityFromUrl } from "@/game/touch";
import {
  MISSION_ID,
  defaultSave,
  formatTime,
  getSaveStore,
  hasProgress,
  markIntroSeen,
  shouldShowIntro,
  ratingLabel,
  recordStart,
  recordWin,
  withCheckpoint,
  type MissionStats,
} from "@/game/save";
import SettingsPanel from "./SettingsPanel";
import TouchControls, { enterFullscreenLandscape } from "./TouchControls";

const EMPTY: HudState = {
  meter: 0,
  alert: "calm",
  objective: "",
  northDeg: 0,
  objDeg: null,
  eagle: false,
  crouched: false,
  hidden: false,
  knives: 0,
  prompt: "",
  toast: "",
  carrying: false,
  caught: 0,
};

const SERVER_SAVE = defaultSave();

interface WinResult {
  time: number;
  rating: number;
  newBestTime: boolean;
  newBestRating: boolean;
}

declare global {
  interface Window {
    __keris?: Game;
  }
}

const mq = (q: string) => window.matchMedia(q).matches;
const subscribeMQ = (query: string) => (cb: () => void) => {
  const m = window.matchMedia(query);
  m.addEventListener("change", cb);
  return () => m.removeEventListener("change", cb);
};
const subscribeTouch = subscribeMQ("(pointer: coarse)");
const touchSnapshot = () =>
  isTouchDevice({
    coarse: mq("(pointer: coarse)"),
    fine: mq("(pointer: fine)"),
    hasTouchStart: "ontouchstart" in window,
    maxTouchPoints: navigator.maxTouchPoints || 0,
    search: window.location.search,
  });
const subscribePortrait = subscribeMQ("(orientation: portrait)");
const portraitSnapshot = () => mq("(orientation: portrait)");

const CONTROLS: [string, string][] = [
  ["W A S D", "Move"],
  ["Shift", "Run (louder)"],
  ["C / Ctrl", "Crouch (quieter)"],
  ["Space", "Jump / climb ledge"],
  ["Mouse", "Look"],
  ["E", "Tikam: keris takedown from behind"],
  ["Q", "Pisau lempar: stun / distract"],
  ["F", "Carry / drop a body (hide it in hay or bush)"],
  ["V", "Mata Helang vision"],
  ["Esc", "Pause"],
  ["Controller", "Sticks move / look, A jump, X tikam, RT knife, Y carry, B crouch, RB vision, LB run, Start pause"],
];

const TOUCH_CONTROLS: [string, string][] = [
  ["Left thumb", "Move (push to the edge to run, louder)"],
  ["Drag right side", "Look"],
  ["Jump", "Jump / climb a ledge (hold at a wall)"],
  ["C", "Crouch toggle (quieter)"],
  ["E", "Tikam: takedown from behind"],
  ["Q", "Pisau lempar: stun / distract"],
  ["F", "Carry / drop a body (hide it in hay or bush)"],
  ["V", "Mata Helang vision"],
  ["II", "Pause"],
];

function Compass({ north, obj }: { north: number; obj: number | null }) {
  const marks = ["N", "E", "S", "W"];
  return (
    <div className="compass" aria-label="compass">
      <div className="compass-ring" style={{ transform: `rotate(${north}deg)` }}>
        {marks.map((m, i) => (
          <span key={m} style={{ transform: `rotate(${i * 90}deg) translateY(-34px)` }}>
            {m}
          </span>
        ))}
      </div>
      {obj !== null && (
        <div className="compass-obj" style={{ transform: `rotate(${obj}deg)` }}>
          <i />
        </div>
      )}
      <b />
    </div>
  );
}

function Best({ m, className = "" }: { m: MissionStats | undefined; className?: string }) {
  if (!m || (m.bestTime === null && m.bestRating === null)) return null;
  return (
    <p className={`best ${className}`}>
      Best: {formatTime(m.bestTime)} · {ratingLabel(m.bestRating)}
    </p>
  );
}

function Controls({ touch }: { touch: boolean }) {
  return (
    <table className="controls">
      <tbody>
        {(touch ? TOUCH_CONTROLS : CONTROLS).map(([k, d]) => (
          <tr key={k}>
            <td>
              <kbd>{k}</kbd>
            </td>
            <td>{d}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

export default function GameClient() {
  const mount = useRef<HTMLDivElement>(null);
  const [game, setGame] = useState<Game | null>(null);
  const [phase, setPhase] = useState<Phase>("title");
  const [reason, setReason] = useState<LoseReason>(null);
  const [hud, setHud] = useState<HudState>(EMPTY);
  const [failed, setFailed] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [win, setWin] = useState<WinResult | null>(null);
  const [introView, setIntroView] = useState<IntroView | null>(null);
  /** what to do when the cutscene ends: go on into the mission, or back to the title (replay) */
  const introMode = useRef<"mission" | "replay">("mission");
  const store = getSaveStore();
  const save = useSyncExternalStore(store.subscribe, store.getSnapshot, () => SERVER_SAVE);
  const mission = save.missions[MISSION_ID];
  const qualityPref = save.settings.quality;
  const touch = useSyncExternalStore(subscribeTouch, touchSnapshot, () => false);
  const portrait = useSyncExternalStore(subscribePortrait, portraitSnapshot, () => false) && touch;

  useEffect(() => {
    if (!mount.current) return;
    let disposed = false;
    let inst: Game | null = null;
    import("@/game/engine")
      .then(({ Game }) => {
        if (disposed || !mount.current) return;
        inst = new Game(
          mount.current,
          {
            onHud: setHud,
            onPhase: (p, r) => {
              if (p === "won" && inst) {
                const out = recordWin(store.get(), inst.stats());
                store.set(out.data);
                setWin({ time: inst.stats().time, rating: out.rating, newBestTime: out.newBestTime, newBestRating: out.newBestRating });
              }
              setPhase(p);
              setReason(r);
            },
            onIntro: setIntroView,
            onIntroEnd: () => {
              if (!inst) return;
              setIntroView(null);
              if (introMode.current === "mission") {
                store.update(markIntroSeen);
                setWin(null);
                inst.start("start");
              } else inst.showTitle();
            },
            // the primary (non-ghost) button of whichever menu is showing
            onPadConfirm: () => document.querySelector<HTMLButtonElement>(".overlay .btn:not(.ghost):not(:disabled)")?.click(),
            onCheckpoint: (cp) => store.update((d) => (cp === "start" ? recordStart(d) : withCheckpoint(d, cp))),
          },
          { quality: pickQuality(touch, window.location.search, qualityPref), touch },
        );
        window.__keris = inst;
        setGame(inst);
      })
      .catch(() => setFailed(true));
    return () => {
      disposed = true;
      inst?.dispose();
      delete window.__keris;
    };
  }, [touch, qualityPref, store]);

  useEffect(() => {
    game?.setLookSettings(save.settings.lookSens, save.settings.invertY);
  }, [game, save.settings.lookSens, save.settings.invertY]);

  // a rotated phone must not keep playing under the "rotate" prompt
  useEffect(() => {
    if (portrait) game?.pause();
  }, [portrait, game, phase]);

  const g = () => game;
  const begin = (from: "start" | "kapitan" = "start") => {
    if (touch) enterFullscreenLandscape();
    setWin(null);
    // the cutscene plays before the very first mission only; "Replay intro" in Settings shows it again
    if (from === "start" && shouldShowIntro(store.get())) playIntro("mission");
    else g()?.start(from);
  };
  const playIntro = (mode: "mission" | "replay") => {
    introMode.current = mode;
    setIntroView(null);
    g()?.playIntro(mq("(prefers-reduced-motion: reduce)"));
  };
  const skipIntro = () => g()?.skipIntro();
  const canContinue = hasProgress(save);
  const settingsBtn = (
    <button className="btn ghost" onClick={() => setShowSettings(true)}>
      Settings
    </button>
  );
  const resume = () => {
    if (touch) enterFullscreenLandscape();
    g()?.resume();
  };
  const alertCls = hud.alert === "calm" ? "" : hud.alert;

  return (
    <div className={`root${touch ? " touch-ui" : ""}`} onContextMenu={(e) => touch && e.preventDefault()}>
      <div ref={mount} className="stage" />
      {failed && (
        <div className="overlay">
          <div className="panel">
            <h2>WebGL unavailable</h2>
            <p>The game could not start in this browser.</p>
          </div>
        </div>
      )}

      {phase === "playing" && (
        <div className="hud">
          <div className="topleft">
            <div className="objective">
              <span className="label">Objective</span>
              {hud.objective}
            </div>
            <div className={`meter ${alertCls}`}>
              <div className="meter-fill" style={{ width: `${Math.round(hud.meter * 100)}%` }} />
              <span>{hud.alert === "calm" ? "Unseen" : hud.alert}</span>
            </div>
            <div className="chips">
              {hud.hidden && <em>Hidden</em>}
              {hud.crouched && <em>Crouched</em>}
              {hud.eagle && <em className="gold">Mata Helang</em>}
              <em>Pisau lempar x{hud.knives}</em>
            </div>
          </div>
          <Compass north={hud.northDeg} obj={hud.objDeg} />
          {hud.caught > 0.02 && (
            <div className="caught">
              <span>Caught!</span>
              <div style={{ width: `${hud.caught * 100}%` }} />
            </div>
          )}
          {hud.prompt && <div className="prompt">{touch ? hud.prompt.replace(/^[EF]s+/, "") : hud.prompt}</div>}
          {hud.toast && <div className="toast">{hud.toast}</div>}
          <div className="hint">
            WASD move · Shift run · C crouch · Space climb · E tikam · Q throw · F carry body · V Mata Helang · Esc pause
          </div>
        </div>
      )}

      {phase === "intro" && (
        <div className="intro" onPointerDown={skipIntro} role="region" aria-label="Intro cutscene">
          <div className="intro-bar top" />
          <div className="intro-bar bottom" />
          <div className="intro-fade" style={{ opacity: introView?.fade ?? 1 }} />
          <p className="intro-caption" style={{ opacity: introView?.opacity ?? 0 }} aria-live="polite">
            {introView?.text}
          </p>
          <button
            className="btn ghost intro-skip"
            onPointerDown={(e) => e.stopPropagation()}
            onClick={skipIntro}
          >
            Skip
          </button>
          {!touch && <span className="intro-hint">Space, Enter or Esc to skip</span>}
        </div>
      )}

      {phase === "playing" && touch && <TouchControls game={game} hud={hud} />}

      {phase === "title" && (
        <div className="overlay title">
          <div className="panel wide">
            <p className="kicker">Malacca, July 1511</p>
            <h1>Keris</h1>
            <p className="story">
              The Portuguese fleet lies in the roads and their battery commands the bridge. The elder Hang Tuah has chosen you, Pendekar, to
              silence the Kapitan before the guns are turned on the town. Move over the atap roofs and through the kampung lanes, strike once with your
              keris, and slip out by the jetty.
            </p>
            <Controls touch={touch} />
            {canContinue ? (
              <>
                <button className="btn" onClick={() => begin(save.checkpoint ?? "start")} disabled={!game}>
                  Continue
                </button>
                <button className="btn ghost" onClick={() => begin("start")} disabled={!game}>
                  New game
                </button>
              </>
            ) : (
              <button className="btn" onClick={() => begin("start")} disabled={!game}>
                {touch ? "Tap to play" : "Begin"}
              </button>
            )}
            {settingsBtn}
            {canContinue && (
              <p className="dim small">{save.checkpoint === "kapitan" ? "Checkpoint: the Kapitan is down" : "Checkpoint: mission start"}</p>
            )}
            <Best m={mission} />
            <p className="dim small">
              {touch ? "Best in landscape. Fullscreen is requested where your browser allows it." : "Click Begin to capture the mouse."}
            </p>
          </div>
        </div>
      )}

      {phase === "paused" && (
        <div className="overlay">
          <div className="panel">
            <h2>Paused</h2>
            <Controls touch={touch} />
            <button className="btn" onClick={resume}>
              Resume
            </button>
            <button className="btn ghost" onClick={() => begin("start")}>
              Restart
            </button>
            {settingsBtn}
          </div>
        </div>
      )}

      {phase === "won" && (
        <div className="overlay">
          <div className="panel">
            <h2>The Kapitan is silenced</h2>
            <p>You reached the jetty and vanished into the harbour. The battery will wait for a new commander.</p>
            {win && (
              <p className={`best ${win.newBestTime || win.newBestRating ? "new" : ""}`}>
                Time {formatTime(win.time)} · {ratingLabel(win.rating)}
                {(win.newBestTime || win.newBestRating) && " · New best!"}
              </p>
            )}
            <Best m={mission} />
            <button className="btn" onClick={() => begin("start")}>
              Play again
            </button>
          </div>
        </div>
      )}

      {phase === "lost" && (
        <div className="overlay lost">
          <div className="panel">
            <h2>{reason === "caught" ? "You were caught" : "Mission failed"}</h2>
            <p>The alarm spread through the lanes. Try another route.</p>
            {save.checkpoint === "kapitan" && (
              <button className="btn" onClick={() => begin("kapitan")}>
                Retry from checkpoint
              </button>
            )}
            <button className={`btn${save.checkpoint === "kapitan" ? " ghost" : ""}`} onClick={() => begin("start")}>
              {save.checkpoint === "kapitan" ? "Restart mission" : "Restart"}
            </button>
            <Best m={mission} />
          </div>
        </div>
      )}

      {showSettings && (
        <SettingsPanel
          store={store}
          save={save}
          canChangeQuality={phase === "title"}
          urlQuality={qualityFromUrl(window.location.search)}
          onReplayIntro={
            phase === "title" && game
              ? () => {
                  setShowSettings(false);
                  playIntro("replay");
                }
              : undefined
          }
          onClose={() => setShowSettings(false)}
        />
      )}

      {portrait && phase !== "intro" && (
        <div className="overlay rotate" role="alert">
          <div className="panel">
            <div className="rotate-icon" aria-hidden="true" />
            <h2>Rotate your phone</h2>
            <p>Keris plays in landscape.</p>
          </div>
        </div>
      )}
    </div>
  );
}
