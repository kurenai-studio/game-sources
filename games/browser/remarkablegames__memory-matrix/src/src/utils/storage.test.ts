import {
  DEFAULT_SETTINGS,
  loadSettings,
  saveBest,
  saveSettings,
  STORAGE_KEY,
} from './storage';

describe('storage', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it('exposes the documented key', () => {
    expect(STORAGE_KEY).toBe('org.remarkablegames.memory-matrix');
  });

  it('returns defaults when nothing is stored', () => {
    expect(loadSettings()).toEqual(DEFAULT_SETTINGS);
    expect(loadSettings().volume).toBe(0.5);
  });

  it('reads valid stored settings', () => {
    localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify({ best: { classic: 12, timed: 9 }, volume: 1 }),
    );

    expect(loadSettings()).toEqual({
      best: { classic: 12, timed: 9 },
      volume: 1,
    });
  });

  it('returns defaults for malformed JSON', () => {
    localStorage.setItem(STORAGE_KEY, '{nope');

    expect(loadSettings()).toEqual(DEFAULT_SETTINGS);
  });

  it('fills per-field defaults for a partial blob', () => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ volume: 0 }));

    expect(loadSettings()).toEqual({
      best: { classic: 0, timed: 0 },
      volume: 0,
    });
  });

  it('discards invalid best values', () => {
    localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify({ best: { classic: 'many', timed: -4 } }),
    );

    expect(loadSettings().best).toEqual({ classic: 0, timed: 0 });
  });

  it('clamps volume into the 0-1 range', () => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ volume: 7 }));

    expect(loadSettings().volume).toBe(1);
  });

  it('falls back to the default volume for non-numeric values', () => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ volume: 'loud' }));

    expect(loadSettings().volume).toBe(0.5);
  });

  it('returns defaults when the blob is not an object', () => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify('hi'));

    expect(loadSettings()).toEqual(DEFAULT_SETTINGS);
  });

  it('survives a storage that throws on read', () => {
    const spy = vi
      .spyOn(Storage.prototype, 'getItem')
      .mockImplementation(() => {
        throw new Error('denied');
      });

    expect(loadSettings()).toEqual(DEFAULT_SETTINGS);
    spy.mockRestore();
  });

  it('merges a patch without clobbering other fields', () => {
    saveSettings({ volume: 1 });

    expect(loadSettings()).toEqual({
      best: { classic: 0, timed: 0 },
      volume: 1,
    });

    saveSettings({ best: { classic: 5, timed: 0 } });

    expect(loadSettings()).toEqual({
      best: { classic: 5, timed: 0 },
      volume: 1,
    });
  });

  it('merges a partial best record', () => {
    saveSettings({ best: { classic: 3, timed: 4 } });
    saveSettings({ best: { ...loadSettings().best, classic: 8 } });

    expect(loadSettings().best).toEqual({ classic: 8, timed: 4 });
  });

  it('ignores writes when storage throws', () => {
    const spy = vi
      .spyOn(Storage.prototype, 'setItem')
      .mockImplementation(() => {
        throw new Error('quota');
      });

    expect(() => {
      saveSettings({ volume: 1 });
    }).not.toThrow();
    spy.mockRestore();
  });

  it('saves a best score for one mode only', () => {
    saveSettings({ volume: 1 });
    saveBest('classic', 6);

    expect(loadSettings()).toEqual({
      best: { classic: 6, timed: 0 },
      volume: 1,
    });
  });
});
