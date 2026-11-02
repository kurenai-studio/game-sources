// Theme Manager - handles theme switching and color overrides
import { DEFAULT_THEMES } from './theme.js';

export class ThemeManager {
  constructor() {
    this.customTheme = null; // Custom color overrides
    this.themeMode = null; // 'dark' | 'light' | null (auto-detect)
    this.isDark = this.getThemeMode() === 'dark';
    this.themeMediaQuery = null;
    this.themeMediaQueryListener = null;
    this.colorCache = new Map(); // Cache for frequently accessed colors
    this.cacheMaxSize = 100; // Maximum cache size
  }

  getThemeMode() {
    if (this.themeMode !== null) {
      return this.themeMode;
    }
    // Auto-detect from system preference
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }

  getColor(path, defaultValue = null) {
    // Check cache first
    const cacheKey = `${this.getThemeMode()}-${path}`;
    if (this.colorCache.has(cacheKey)) {
      return this.colorCache.get(cacheKey);
    }

    // Path can be: 'background', 'player.normal.main', 'ui.score', etc.
    const theme = DEFAULT_THEMES[this.getThemeMode()];
    const parts = path.split('.');
    let value = theme;

    // Navigate through theme object
    for (const part of parts) {
      if (value && typeof value === 'object' && part in value) {
        value = value[part];
      } else {
        const result = defaultValue;
        this.cacheColor(cacheKey, result);
        return result;
      }
    }

    // Apply custom overrides if they exist
    if (this.customTheme) {
      const customValue = this.getCustomColor(path);
      if (customValue !== undefined) {
        this.cacheColor(cacheKey, customValue);
        return customValue;
      }
    }

    const result = value !== undefined ? value : defaultValue;
    this.cacheColor(cacheKey, result);
    return result;
  }

  cacheColor(key, value) {
    // Limit cache size
    if (this.colorCache.size >= this.cacheMaxSize) {
      // Remove oldest entry (simple FIFO)
      const firstKey = this.colorCache.keys().next().value;
      this.colorCache.delete(firstKey);
    }
    this.colorCache.set(key, value);
  }

  clearColorCache() {
    this.colorCache.clear();
  }

  getCustomColor(path) {
    if (!this.customTheme) return undefined;
    const parts = path.split('.');
    let value = this.customTheme;

    for (const part of parts) {
      if (value && typeof value === 'object' && part in value) {
        value = value[part];
      } else {
        return undefined;
      }
    }

    return value;
  }

  setTheme(mode) {
    // mode: 'dark' | 'light' | 'auto' | null
    if (mode === 'auto' || mode === null) {
      this.themeMode = null;
    } else if (mode === 'dark' || mode === 'light') {
      this.themeMode = mode;
    } else {
      console.warn('Invalid theme mode:', mode);
      return;
    }

    const wasDark = this.isDark;
    this.isDark = this.getThemeMode() === 'dark';

    // Clear cache when theme changes
    if (wasDark !== this.isDark) {
      this.clearColorCache();
    }

    // Notify parent if embedded
    if (window.parent !== window) {
      window.parent.postMessage({
        type: 'theme-changed',
        data: { mode: this.getThemeMode(), isDark: this.isDark }
      }, '*');
    }

    return wasDark !== this.isDark; // Return true if theme actually changed
  }

  setCustomColors(colors) {
    // colors: { background: 0x..., player: { normal: { main: 0x... } }, ... }
    // Deep merge with existing custom theme
    if (!this.customTheme) {
      this.customTheme = {};
    }

    this.customTheme = this.deepMerge(this.customTheme, colors);
    
    // Clear cache when custom colors change
    this.clearColorCache();

    // Notify parent if embedded
    if (window.parent !== window) {
      window.parent.postMessage({
        type: 'colors-updated',
        data: { colors: this.customTheme }
      }, '*');
    }
  }

  clearCustomColors() {
    this.customTheme = null;
    this.clearColorCache();

    // Notify parent if embedded
    if (window.parent !== window) {
      window.parent.postMessage({ type: 'colors-reset' }, '*');
    }
  }

  deepMerge(target, source) {
    const output = { ...target };
    for (const key in source) {
      if (source[key] && typeof source[key] === 'object' && !Array.isArray(source[key])) {
        output[key] = this.deepMerge(target[key] || {}, source[key]);
      } else {
        output[key] = source[key];
      }
    }
    return output;
  }

  setupSystemThemeListener(callback) {
    // Listen for system theme changes (only if auto mode)
    this.themeMediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    this.themeMediaQueryListener = () => {
      if (this.themeMode === null) { // Only auto-update if in auto mode
        const wasDark = this.isDark;
        this.isDark = this.getThemeMode() === 'dark';
        if (wasDark !== this.isDark && callback) {
          callback();
        }
      }
    };
    this.themeMediaQuery.addEventListener('change', this.themeMediaQueryListener);
  }

  cleanup() {
    if (this.themeMediaQuery && this.themeMediaQueryListener) {
      this.themeMediaQuery.removeEventListener('change', this.themeMediaQueryListener);
    }
  }
}


