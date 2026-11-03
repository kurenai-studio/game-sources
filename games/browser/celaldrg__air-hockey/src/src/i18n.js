// All visible strings in English and Turkish.

export const LANGUAGES = Object.freeze(['en', 'tr']);

const STRINGS = {
  en: {
    title: 'Air Hockey',
    newGame: 'New game',
    pause: 'Pause',
    resume: 'Resume',
    restart: 'Restart',
    mute: 'Mute sound',
    unmute: 'Turn sound on',
    langButton: 'TR',
    langLabel: 'TR: switch to Turkish',
    setupTitle: 'New game',
    mode: 'Mode',
    modeCpu: 'vs computer',
    modePvp: 'Two players',
    level: 'Level',
    easy: 'Easy',
    medium: 'Medium',
    hard: 'Hard',
    goals: 'Goals to win',
    record: 'Your record on {level}: {wins} W · {losses} L',
    hintCpu: 'Drag to move your mallet (bottom). Arrow keys or WASD work too. P or Esc pauses.',
    hintPvp: 'Each player drags in their own half. Keys: arrows for the bottom, WASD for the top.',
    start: 'Start',
    back: 'Back',
    paused: 'Paused',
    pausedHint: 'Press P or Esc to resume',
    goal: 'Goal!',
    you: 'You',
    cpu: 'CPU',
    p1: 'P1',
    p2: 'P2',
    youWin: 'You win!',
    cpuWins: 'The computer wins',
    playerWins: 'Player {n} wins!',
    finalScore: 'Final score {a} – {b}',
    rematch: 'Rematch',
    scoreLine: '{a}: {sa}, {b}: {sb}',
    canvasLabel: 'Air hockey table',
    footerLicense: 'MIT',
    footerSource: 'Source on GitHub',
  },
  tr: {
    title: 'Hava Hokeyi',
    newGame: 'Yeni oyun',
    pause: 'Duraklat',
    resume: 'Devam et',
    restart: 'Yeniden başlat',
    mute: 'Sesi kapat',
    unmute: 'Sesi aç',
    langButton: 'EN',
    langLabel: 'EN: İngilizceye geç',
    setupTitle: 'Yeni oyun',
    mode: 'Mod',
    modeCpu: 'Bilgisayara karşı',
    modePvp: 'İki oyuncu',
    level: 'Seviye',
    easy: 'Kolay',
    medium: 'Orta',
    hard: 'Zor',
    goals: 'Kazanmak için gol',
    record: '{level} seviyesindeki karnen: {wins} G · {losses} M',
    hintCpu: 'Tokacını (altta) sürükleyerek oyna. Ok tuşları veya WASD da çalışır. P ya da Esc duraklatır.',
    hintPvp: 'Herkes kendi yarısında sürükler. Tuşlar: alttaki için oklar, üstteki için WASD.',
    start: 'Başla',
    back: 'Geri',
    paused: 'Duraklatıldı',
    pausedHint: 'Devam için P ya da Esc',
    goal: 'Gol!',
    you: 'Sen',
    cpu: 'PC',
    p1: 'O1',
    p2: 'O2',
    youWin: 'Kazandın!',
    cpuWins: 'Bilgisayar kazandı',
    playerWins: '{n}. oyuncu kazandı!',
    finalScore: 'Sonuç {a} – {b}',
    rematch: 'Rövanş',
    scoreLine: '{a}: {sa}, {b}: {sb}',
    canvasLabel: 'Hava hokeyi masası',
    footerLicense: 'MIT',
    footerSource: 'GitHub\'da kaynak kodu',
  },
};

/**
 * Picks a supported language, falling back to English.
 * @param {unknown} lang
 * @returns {'en' | 'tr'}
 */
export function normalizeLang(lang) {
  return lang === 'tr' ? 'tr' : 'en';
}

/**
 * Returns the string for `key` in `lang` with {placeholders} filled in.
 * @param {'en' | 'tr'} lang
 * @param {string} key
 * @param {Record<string, string | number>} [vars]
 * @returns {string}
 */
export function t(lang, key, vars = {}) {
  const table = STRINGS[normalizeLang(lang)];
  const text = table[key] ?? STRINGS.en[key] ?? key;
  return text.replace(/\{(\w+)\}/g, (m, name) => (name in vars ? String(vars[name]) : m));
}

/**
 * Lists every string key (used by tests to compare languages).
 * @param {'en' | 'tr'} lang
 * @returns {string[]}
 */
export function keys(lang) {
  return Object.keys(STRINGS[normalizeLang(lang)]);
}
