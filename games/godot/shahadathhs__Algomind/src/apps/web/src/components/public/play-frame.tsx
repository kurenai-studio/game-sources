"use client";

import { useEffect, useRef, useState } from "react";

type GodotEngine = {
  startGame(config: { executable: string }): Promise<void>;
};
type GodotEngineClass = {
  new (config: Record<string, unknown>): GodotEngine;
  isWebGLAvailable(version?: number): boolean;
};

type State =
  | { phase: "idle" }
  | { phase: "loading"; percent: number | null }
  | { phase: "running" }
  | { phase: "failed"; reason: string };

function loadScript(src: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = src;
    script.async = true;
    script.onload = () => resolve();
    script.onerror = () => reject(new Error("The game files could not be downloaded."));
    document.head.appendChild(script);
  });
}

/**
 * Runs the game's Godot web export. Nothing is fetched until the visitor presses Play, so the
 * roughly 10 MB download is a choice, and the press also unlocks audio.
 */
export function PlayFrame({
  executable,
  sizes,
}: {
  executable: string;
  sizes: Record<string, number>;
}) {
  const [state, setState] = useState<State>({ phase: "idle" });
  const canvas = useRef<HTMLCanvasElement>(null);
  const started = useRef(false);

  // The engine does not manage the canvas size (policy 0): keep its drawing buffer matched to
  // the frame in device pixels so the game stays sharp at any width.
  useEffect(() => {
    const element = canvas.current;
    if (!element) return;
    const fit = () => {
      const ratio = window.devicePixelRatio || 1;
      const width = Math.max(1, Math.round(element.clientWidth * ratio));
      const height = Math.max(1, Math.round(element.clientHeight * ratio));
      if (element.width === width && element.height === height) return;
      element.width = width;
      element.height = height;
      window.dispatchEvent(new Event("resize"));
    };
    fit();
    const observer = new ResizeObserver(fit);
    observer.observe(element);
    return () => observer.disconnect();
  }, []);

  async function start() {
    if (started.current) return;
    started.current = true;
    setState({ phase: "loading", percent: null });
    try {
      if (typeof WebAssembly !== "object") throw new Error("This browser cannot run WebAssembly.");
      const w = window as unknown as { Engine?: GodotEngineClass };
      if (!w.Engine) await loadScript(`${executable}.js`);
      const Engine = w.Engine;
      if (!Engine) throw new Error("The game loader did not start.");
      if (!Engine.isWebGLAvailable()) throw new Error("This browser has no WebGL 2 support.");
      const engine = new Engine({
        canvas: canvas.current,
        canvasResizePolicy: 0,
        fileSizes: sizes,
        focusCanvas: true,
        onProgress: (current: number, total: number) => {
          if (total > 0)
            setState({ phase: "loading", percent: Math.round((current / total) * 100) });
        },
        onExit: () => {
          started.current = false;
          setState({ phase: "idle" });
        },
        onPrintError: (...args: unknown[]) => console.error(...args),
      });
      await engine.startGame({ executable });
      setState({ phase: "running" });
    } catch (error) {
      started.current = false;
      setState({
        phase: "failed",
        reason: error instanceof Error ? error.message : "The game could not start.",
      });
    }
  }

  const showCanvas = state.phase === "running" || state.phase === "loading";
  return (
    <div className="flex flex-col gap-4">
      <div
        className="tile bg-ink p-[3px]"
        style={{ ["--chamfer" as string]: "20px", width: "min(100%, calc(78dvh * 390 / 844))" }}
      >
        <div
          className="tile relative bg-ground"
          style={{
            ["--chamfer" as string]: "18.3px",
            aspectRatio: "390 / 844",
          }}
        >
          <canvas
            ref={canvas}
            id="algomind-canvas"
            className={`absolute inset-0 h-full w-full ${showCanvas ? "" : "invisible"}`}
            aria-label="Algomind"
            tabIndex={0}
          />
          {state.phase !== "running" && (
            <div className="absolute inset-0 flex flex-col items-center justify-center gap-6 p-6 text-center">
              {state.phase === "idle" && (
                <>
                  <button
                    type="button"
                    onClick={start}
                    className="tile h-16 bg-signal px-8 text-[22px] tracking-[2px] text-on-signal uppercase"
                    style={{ ["--chamfer" as string]: "14px" }}
                  >
                    Play
                  </button>
                  <p className="text-sm font-semibold text-mute">Downloads about 10 MB once.</p>
                </>
              )}
              {state.phase === "loading" && (
                <div role="status" className="w-full max-w-[240px]">
                  <p className="text-sm font-bold tracking-[2px] uppercase">
                    {state.percent === null ? "Loading" : `Loading ${state.percent}%`}
                  </p>
                  <div className="mt-3 h-3 bg-slot">
                    <div className="h-full bg-ink" style={{ width: `${state.percent ?? 0}%` }} />
                  </div>
                </div>
              )}
              {state.phase === "failed" && (
                <div role="alert" className="flex flex-col items-center gap-4">
                  <p className="text-sm font-bold tracking-[2px] uppercase">
                    The game did not start
                  </p>
                  <p className="text-sm font-semibold text-mute">{state.reason}</p>
                  <button
                    type="button"
                    onClick={start}
                    className="tile bg-ink p-[2px] text-sm tracking-[2px] uppercase"
                    style={{ ["--chamfer" as string]: "10px" }}
                  >
                    <span
                      className="tile flex h-11 items-center bg-ground px-5"
                      style={{ ["--chamfer" as string]: "8.5px" }}
                    >
                      Try again
                    </span>
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
