# Phase 11 — Quick wins (Mortgage Crisis + versioning + AI polish)

Phase 11 is a “quick wins” phase focused on **naming/versioning consistency** and **playtest-quality AI/UX tweaks**.

## What shipped

### Rename: Property Deal → Mortgage Crisis

- Project naming was standardized on **Mortgage Crisis** (docs + cartridge metadata).
- Global namespace was renamed from `PD` → `MC` (source + tests + docs) to match the new project identity.

### Versioning: stop hardcoding phase text

- The HUD version string is now driven by config: `MC.config.meta.version`.
- Cartridge version is now **`v0.11`**.

### AI narration copy

- AI toasts now use the shorter prefix **`AI:`** (instead of `Opponent:`).

### AI heuristics (small, composable policies)

We expanded the policy system with small, tunable heuristics that improve playtest outcomes without introducing heavyweight simulation.

- **Debt payment**: prefer paying from **bank** before transferring properties (soft bias).
- **Rent gating**: prefer `playRent` only when the opponent has anything payable (avoid wasting Rent).
- **Early-turn discipline**:
  - bank money/house up to a small buffer first
  - avoid dumping multiple valuable actions into the bank when there are no other play options
  - allow “empty-hand draw-5 chase” when hand size is very small (≤2)
- **Sly Deal bias**: when a Sly target exists, prefer stealing (`playSlyDeal`) over banking the Sly card.

### UX: Source-only actions are disallowed

- When a card interaction would have only the **Source** destination available (no actionable commands), the UI now disallows entering the action and shows a clear `No actions` feedback instead of silently doing nothing.

## Notes / follow-ups

- The AI remains a **weighted random** picker over legal moves; the new behaviors are expressed as independent weights so they can be tuned in `src/05_config.js`.

