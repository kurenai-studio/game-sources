# Rainbow Climb — Development Guide

## Build & Test

```bash
# Desktop (dev)
JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ./gradlew desktop:run

# Android debug APK
JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ./gradlew android:assembleDebug

# Compile check
JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ./gradlew desktop:classes
```

## Sustainability Baseline (April 2026)

- **SCI**: ~0.44 gCO2eq per game session (5 min, 3W phone, global avg grid)
- **APK**: 2.1 MB debug
- **Network**: zero requests (fully offline)
- **Audio**: 100% procedural (zero audio files)
- **Assets**: ~656 KB total (pixel art sprites, generated backgrounds)

### Green architecture decisions

1. **Procedural audio** — zero file I/O, zero network, minimal storage
2. **Object pooling** — particles, entities, staging lists avoid GC pressure
3. **Chunk recycling** — only 3 chunks in memory, ring buffer reuse
4. **No analytics/tracking** — zero background network, zero data collection
5. **Client-only** — no server infrastructure, no cloud dependency

### Feature addition checklist

When adding a feature:
1. Write the feature
2. Write tests (when test framework is set up)
3. Run compile check — must pass
4. Check for per-frame allocations (avoid `new` in render/update loops)
5. Verify APK size stays < 5 MB
6. Update SPEC.md if gameplay/architecture changed
7. Run `/adversarial-verify` before committing complex changes

### Performance budget

| Metric | Limit |
|--------|-------|
| APK size | < 5 MB |
| Draw calls per frame | < 20 (with texture atlas) |
| Per-frame allocations | 0 |
| Target FPS | 60 |
| Asset total | < 1 MB |

## Repository

- Remote: `fullo/rainbow-climb` on GitHub
- Branch: `main`
- CI: GitHub Actions (build.yml + release.yml)
