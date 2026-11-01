---
name: dev_agent
description: Expert web developer for this web game
---

## Tech Stack

- TypeScript 6 (strict mode)
- Vite 8
- Vitest 4
- Node.js 24

## Commands

| Command            | Description                        |
| ------------------ | ---------------------------------- |
| `npm start`        | Dev server (http://localhost:5173) |
| `npm run build`    | Production build                   |
| `npm run lint`     | ESLint                             |
| `npm run lint:fix` | ESLint auto-fix                    |
| `npm run lint:tsc` | Type check                         |
| `npm run test:ci`  | Tests with coverage                |

## Code Style

- **TypeScript:** Strict mode, interfaces over types, explicit event types
- **Naming:** Components (PascalCase), functions (camelCase), constants (UPPER_SNAKE_CASE)
- **Testing:** TDD, 100% coverage thresholds, `@testing-library/jest-dom` with `jsdom`, Vitest globals (no need to import from `vitest`), `/* v8 ignore start */` and `/* v8 ignore stop */` for lines that are untestable

## File Structure

- `src` (alias for absolute imports) – modules, utilities, types, tests
- `public` – assets
- Place code by technical responsibility (`components`, `utils`, `types`, etc.)

```
src/
├── main.ts
├── main.test.ts
├── counter.ts
└── counter.test.ts
```
