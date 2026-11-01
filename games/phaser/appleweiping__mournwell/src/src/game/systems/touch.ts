import type { Vector2Like } from '@/game/types';

export interface TouchInputState {
  move: Vector2Like;
  shoot: Vector2Like;
  active: boolean;
}

export const touchInput: TouchInputState = {
  move: { x: 0, y: 0 },
  shoot: { x: 0, y: 0 },
  active: false,
};

interface PadBinding {
  remove(): void;
  reset(): void;
}

let resetInstalledPads = (): void => undefined;

export function resetTouchInput(): void {
  touchInput.move = { x: 0, y: 0 };
  touchInput.shoot = { x: 0, y: 0 };
  resetInstalledPads();
}

function normalizedPadVector(event: PointerEvent, element: HTMLElement): Vector2Like {
  const bounds = element.getBoundingClientRect();
  const radius = Math.min(bounds.width, bounds.height) / 2;
  const x = (event.clientX - (bounds.left + bounds.width / 2)) / radius;
  const y = (event.clientY - (bounds.top + bounds.height / 2)) / radius;
  const length = Math.hypot(x, y);
  if (length < 0.16) return { x: 0, y: 0 };
  if (length <= 1) return { x, y };
  return { x: x / length, y: y / length };
}

function attachPad(element: HTMLElement, key: 'move' | 'shoot'): PadBinding {
  const knob = element.querySelector<HTMLElement>('.touch-pad__knob');
  let activePointer: number | null = null;

  const update = (event: PointerEvent): void => {
    if (event.pointerId !== activePointer) return;
    const value = normalizedPadVector(event, element);
    touchInput[key] = value;
    if (knob) knob.style.transform = `translate(${value.x * 72}%, ${value.y * 72}%)`;
  };
  const down = (event: PointerEvent): void => {
    if (activePointer !== null) return;
    activePointer = event.pointerId;
    try {
      element.setPointerCapture(event.pointerId);
    } catch {
      // Synthetic QA events can lack a browser-managed active pointer.
    }
    update(event);
    event.preventDefault();
  };
  const reset = (): void => {
    if (activePointer !== null && element.hasPointerCapture(activePointer)) {
      element.releasePointerCapture(activePointer);
    }
    activePointer = null;
    touchInput[key] = { x: 0, y: 0 };
    if (knob) knob.style.transform = 'translate(0, 0)';
  };
  const up = (event: PointerEvent): void => {
    if (event.pointerId !== activePointer) return;
    reset();
    event.preventDefault();
  };

  element.addEventListener('pointerdown', down);
  element.addEventListener('pointermove', update);
  element.addEventListener('pointerup', up);
  element.addEventListener('pointercancel', up);
  element.addEventListener('lostpointercapture', up);
  return {
    reset,
    remove() {
      reset();
      element.removeEventListener('pointerdown', down);
      element.removeEventListener('pointermove', update);
      element.removeEventListener('pointerup', up);
      element.removeEventListener('pointercancel', up);
      element.removeEventListener('lostpointercapture', up);
    },
  };
}

export function installTouchControls(): () => void {
  const movePad = document.querySelector<HTMLElement>('#move-pad');
  const shootPad = document.querySelector<HTMLElement>('#shoot-pad');
  const controls = document.querySelector<HTMLElement>('#touch-controls');
  const query = new URLSearchParams(window.location.search);
  touchInput.active =
    query.get('mobile') === '1' || window.matchMedia('(hover: none), (pointer: coarse)').matches;
  controls?.classList.toggle('is-active', touchInput.active);
  const bindings = [
    ...(movePad ? [attachPad(movePad, 'move')] : []),
    ...(shootPad ? [attachPad(shootPad, 'shoot')] : []),
  ];
  resetInstalledPads = (): void => bindings.forEach((binding) => binding.reset());
  window.addEventListener('blur', resetTouchInput);
  document.addEventListener('visibilitychange', resetTouchInput);
  return () => {
    bindings.forEach((binding) => binding.remove());
    resetInstalledPads = (): void => undefined;
    window.removeEventListener('blur', resetTouchInput);
    document.removeEventListener('visibilitychange', resetTouchInput);
  };
}
