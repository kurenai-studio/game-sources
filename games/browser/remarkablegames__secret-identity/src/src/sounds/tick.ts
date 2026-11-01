import { Howl } from 'howler';

export const tick = new Howl({
  src: ['/sounds/tick.webm', '/sounds/tick.ogg', '/sounds/tick.mp3'],
  volume: 0.3,
});
