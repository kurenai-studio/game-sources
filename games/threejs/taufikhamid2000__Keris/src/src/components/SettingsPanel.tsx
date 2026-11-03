"use client";

import { useState } from "react";
import { LOOK_SENS_MAX, LOOK_SENS_MIN, hasProgress, updateSettings, type QualityPref, type SaveData, type SaveStore } from "@/game/save";

interface Props {
  store: SaveStore;
  save: SaveData;
  /** quality can only be swapped while no mission is running (it rebuilds the renderer) */
  canChangeQuality: boolean;
  /** ?quality=low|high in the URL: wins over the saved value for this session */
  urlQuality: string | null;
  onClose: () => void;
  /** offered from the title screen only: plays the intro cutscene again without changing the save */
  onReplayIntro?: () => void;
}

export default function SettingsPanel({ store, save, canChangeQuality, urlQuality, onClose, onReplayIntro }: Props) {
  const s = save.settings;
  const [confirming, setConfirming] = useState(false);
  const [code, setCode] = useState("");
  const [msg, setMsg] = useState("");
  const set = (patch: Partial<typeof s>) => store.update((d) => updateSettings(d, patch));

  return (
    <div className="overlay settings" role="dialog" aria-label="Settings">
      <div className="panel">
        <h2>Settings</h2>

        <label className="row">
          <span>Quality</span>
          <select
            value={s.quality}
            disabled={!canChangeQuality || !!urlQuality}
            onChange={(e) => set({ quality: e.target.value as QualityPref })}
            aria-label="Quality"
          >
            <option value="auto">Auto (phones low, desktop high)</option>
            <option value="low">Low</option>
            <option value="high">High</option>
          </select>
        </label>
        {urlQuality && <p className="dim small">?quality={urlQuality} in the address bar overrides this for now.</p>}
        {!urlQuality && !canChangeQuality && <p className="dim small">Change quality from the title screen.</p>}

        <label className="row">
          <span>Look sensitivity {s.lookSens.toFixed(1)}x</span>
          <input
            type="range"
            min={LOOK_SENS_MIN}
            max={LOOK_SENS_MAX}
            step={0.1}
            value={s.lookSens}
            onChange={(e) => set({ lookSens: Number(e.target.value) })}
            aria-label="Look sensitivity"
          />
        </label>
        <label className="row">
          <span>Invert vertical look</span>
          <input type="checkbox" checked={s.invertY} onChange={(e) => set({ invertY: e.target.checked })} aria-label="Invert vertical look" />
        </label>

        {onReplayIntro && (
          <button className="btn ghost" onClick={onReplayIntro}>
            Replay intro
          </button>
        )}

        <details className="codebox">
          <summary>Back up or move your save</summary>
          <textarea value={code} onChange={(e) => setCode(e.target.value)} rows={3} placeholder="Save code" aria-label="Save code" spellCheck={false} />
          <div>
            <button className="btn ghost sm" onClick={() => (setCode(store.exportCode()), setMsg("Code ready to copy."))}>
              Export
            </button>
            <button className="btn ghost sm" onClick={() => setMsg(store.importFrom(code) ? "Imported." : "That code is not valid.")}>
              Import
            </button>
          </div>
        </details>
        {msg && (
          <p className="small" role="status">
            {msg}
          </p>
        )}

        {confirming ? (
          <div className="confirm" role="alertdialog" aria-label="Confirm reset">
            <p>Erase your checkpoint and best times? Settings are kept.</p>
            <button
              className="btn danger"
              onClick={() => {
                store.reset();
                setConfirming(false);
                setMsg("Progress reset.");
              }}
            >
              Yes, reset
            </button>
            <button className="btn ghost" onClick={() => setConfirming(false)}>
              Cancel
            </button>
          </div>
        ) : (
          <button className="btn ghost" onClick={() => setConfirming(true)} disabled={!hasProgress(save) && Object.keys(save.missions).length === 0}>
            Reset progress
          </button>
        )}
        <p className="dim small">Saved in this browser only. Clearing site data erases it.</p>
        <button className="btn" onClick={onClose}>
          Close
        </button>
      </div>
    </div>
  );
}
