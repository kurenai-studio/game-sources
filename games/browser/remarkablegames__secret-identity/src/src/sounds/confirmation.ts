import { Howl } from 'howler';

export const confirmation = new Howl({
  src: [
    '/sounds/confirmation.webm',
    '/sounds/confirmation.ogg',
    '/sounds/confirmation.mp3',
  ],
  volume: 0.5,
});
