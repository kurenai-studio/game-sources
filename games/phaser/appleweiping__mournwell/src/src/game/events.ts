import type { GameDebugSnapshot, GameResult, ItemDefinition } from '@/game/types';

type EventMap = {
  snapshot: GameDebugSnapshot;
  phase: GameDebugSnapshot['phase'];
  result: GameResult;
  toast: { title: string; subtitle: string; duration?: number };
  item: { item: ItemDefinition; stacks: number };
};

type Handler<T> = (detail: T) => void;

class TypedEventBus {
  private readonly target = new EventTarget();

  on<K extends keyof EventMap>(name: K, handler: Handler<EventMap[K]>): () => void {
    const listener = (event: Event): void => handler((event as CustomEvent<EventMap[K]>).detail);
    this.target.addEventListener(name, listener);
    return () => this.target.removeEventListener(name, listener);
  }

  emit<K extends keyof EventMap>(name: K, detail: EventMap[K]): void {
    this.target.dispatchEvent(new CustomEvent(name, { detail }));
  }
}

export const gameEvents = new TypedEventBus();
