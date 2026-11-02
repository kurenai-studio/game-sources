// Default color themes - can be overridden via API
export const DEFAULT_THEMES = {
  dark: {
    background: 0x111827,
    text: 0xe5e7eb,
    textSecondary: 0x9ca3af,
    border: 0x374151,
    player: {
      normal: { main: 0x60a5fa, accent: 0x93c5fd, dark: 0x3b82f6, glow: 0xdbeafe },
      hyperspeed: { main: 0xfbbf24, accent: 0xfcd34d, dark: 0xd97706, glow: 0xf59e0b },
      wallhack: { main: 0x10b981, accent: 0x34d399, dark: 0x059669 }
    },
    bullet: { main: 0x60a5fa, accent: 0x93c5fd, glow: 0xdbeafe },
    bossBullet: { main: 0xa78bfa, accent: 0xc4b5fd, glow: 0xddd6fe },
    asteroid: { outer: 0x9ca3af, middle: 0x6b7280, inner: 0x4b5563, highlight: 0xd1d5db },
    comet: { main: 0xd1d5db, core: 0xe5e7eb, trail: 0x60a5fa, trailBright: 0x93c5fd },
    fastEnemy: { main: 0xf87171, accent: 0xfca5a5, core: 0xdc2626, dark: 0x991b1b, eyes: 0xfbbf24 },
    bigEnemy: { outer: 0x6b7280, middle: 0x9ca3af, inner: 0xd1d5db, dark: 0x4b5563, darkest: 0x1f2937 },
    energy: { main: 0xfbbf24, accent: 0xfcd34d, core: 0xfde047 },
    powerup: {
      rapid: { main: 0x8b5cf6, accent: 0xa78bfa, light: 0xc4b5fd },
      triple: { main: 0xec4899, accent: 0xf472b6 },
      shield: { main: 0x10b981, accent: 0x34d399, light: 0x6ee7b7 },
      life: { main: 0xef4444, accent: 0xf87171, light: 0xfca5a5 },
      autoAim: { main: 0x06b6d4, accent: 0x22d3ee, light: 0x67e8f9 },
      magnet: { main: 0x3b82f6, accent: 0x60a5fa, light: 0x93c5fd },
      slowMotion: { main: 0x8b5cf6, accent: 0xa78bfa, light: 0xc4b5fd }
    },
    particles: {
      default: 0x60a5fa,
      explosion: 0xef4444,
      level: 0x10b981,
      hyperspeed: 0x8b5cf6,
      triple: 0xec4899,
      shield: 0x10b981,
      life: 0xef4444,
      autoAim: 0x06b6d4,
      magnet: 0x3b82f6,
      slowMotion: 0x8b5cf6,
      boss: 0xef4444,
      bossKill: 0xfbbf24
    },
    ui: {
      score: 0xe5e7eb,
      lives: 0xef4444,
      combo: 0xfbbf24,
      powerup: 0xfbbf24,
      progressBg: 0x374151,
      progressFill: 0x60a5fa,
      healthGood: 0x10b981,
      healthMedium: 0xf59e0b,
      healthLow: 0xef4444
    },
    stars: 0xe5e7eb, // Light gray/white stars for dark theme
    starsConfig: { count: 80, brightness: { min: 0.2, max: 1.0 } }
  },
  light: {
    background: 0xf8fafc,
    text: 0x0f172a,
    textSecondary: 0x475569,
    border: 0xcbd5e1,
    player: {
      normal: { main: 0x2563eb, accent: 0x3b82f6, dark: 0x1e40af, glow: 0xbfdbfe },
      hyperspeed: { main: 0xea580c, accent: 0xf97316, dark: 0xc2410c, glow: 0xf59e0b },
      wallhack: { main: 0x16a34a, accent: 0x22c55e, dark: 0x15803d }
    },
    bullet: { main: 0x1e3a8a, accent: 0x1e40af, glow: 0x1e3a8a },
    bossBullet: { main: 0x4c1d95, accent: 0x5b21b6, glow: 0x6d28d9 },
    asteroid: { outer: 0x475569, middle: 0x334155, inner: 0x1e293b, highlight: 0x64748b },
    comet: { main: 0x64748b, core: 0x475569, trail: 0x1e40af, trailBright: 0x1e3a8a },
    fastEnemy: { main: 0xdc2626, accent: 0xef4444, core: 0xb91c1c, dark: 0x7f1d1d, eyes: 0xf59e0b },
    bigEnemy: { outer: 0x475569, middle: 0x334155, inner: 0x64748b, dark: 0x111827, darkest: 0x030712 },
    energy: { main: 0xd97706, accent: 0xea580c, core: 0xf97316 },
    powerup: {
      rapid: { main: 0x6d28d9, accent: 0x7c3aed, light: 0x8b5cf6 },
      triple: { main: 0xbe185d, accent: 0xdb2777 },
      shield: { main: 0x16a34a, accent: 0x22c55e, light: 0x4ade80 },
      life: { main: 0xdc2626, accent: 0xfca5a5, light: 0xfee2e2 },
      autoAim: { main: 0x0891b2, accent: 0x06b6d4, light: 0x22d3ee },
      magnet: { main: 0x2563eb, accent: 0x3b82f6, light: 0x60a5fa },
      slowMotion: { main: 0x6d28d9, accent: 0x7c3aed, light: 0x8b5cf6 }
    },
    particles: {
      default: 0x1d4ed8,
      explosion: 0xdc2626,
      level: 0x15803d,
      hyperspeed: 0x7c3aed,
      triple: 0xdb2777,
      shield: 0x16a34a,
      life: 0xdc2626,
      autoAim: 0x0891b2,
      magnet: 0x2563eb,
      slowMotion: 0x6d28d9,
      boss: 0xdc2626,
      bossKill: 0xd97706
    },
    ui: {
      score: 0x0f172a,
      lives: 0xdc2626,
      combo: 0xea580c,
      powerup: 0xea580c,
      progressBg: 0xcbd5e1,
      progressFill: 0x2563eb,
      healthGood: 0x16a34a,
      healthMedium: 0xd97706,
      healthLow: 0xdc2626
    },
    stars: 0x475569, // Dark gray stars for light theme
    starsConfig: { count: 120, brightness: { min: 0.5, max: 1.0 } }
  }
};

