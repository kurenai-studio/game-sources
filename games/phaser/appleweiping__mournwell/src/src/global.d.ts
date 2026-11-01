import type { GameDebugBridge } from './game/types';

declare global {
  const __APP_VERSION__: string;

  interface Window {
    __game: GameDebugBridge;
  }
}

export {};
