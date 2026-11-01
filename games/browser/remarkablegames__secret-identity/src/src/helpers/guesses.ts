import { MAX_GUESSES } from 'src/constants';

function getDate(): string {
  return new Date().toLocaleDateString();
}

function getGuesses(): number {
  return Number(localStorage.getItem(getDate()));
}

export function incrementGuesses(): void {
  localStorage.setItem(getDate(), String(getGuesses() + 1));
}

export function overMaxGuesses(): boolean {
  return getGuesses() > MAX_GUESSES;
}
