import { act } from 'react';

export const waitForRender = () => act(() => new Promise((resolve) => setTimeout(resolve, 50)));

export function getLastContentFrame(frames: string[]): string {
  for (let i = frames.length - 1; i >= 0; i--) {
    if (frames[i].trim()) return frames[i];
  }
  return '';
}
