// LocalStorage utilities

const HIGH_SCORE_KEY = 'spaceRunnerHighScore';

export function loadHighScore() {
  try {
    return parseInt(localStorage.getItem(HIGH_SCORE_KEY) || '0', 10);
  } catch {
    return 0;
  }
}

export function saveHighScore(score) {
  try {
    localStorage.setItem(HIGH_SCORE_KEY, score.toString());
  } catch {
    // Ignore storage errors
  }
}






