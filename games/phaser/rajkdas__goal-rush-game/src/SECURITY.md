# Security Policy

## Reporting a vulnerability

Please use GitHub's **Private vulnerability reporting**: open the repo's
**Security** tab → **Report a vulnerability**. Do **not** open a public issue
for anything you believe is exploitable.

- Acknowledgement within **48 hours**.
- Fix or mitigation target for critical issues: **7 days**.

## Scope

In scope:

- The leaderboard API (`src/app/api/leaderboard/route.ts`) — input validation,
  rate limiting, injection, abuse of the submit endpoint.
- Server startup scripts (`scripts/seed-demo.mjs`, `npm run start:cloud`).
- Dependency vulnerabilities in the runtime image.

Out of scope:

- This is an arcade demo with **virtual credits only** — there is no real-money
  system, payment flow, or user-account store to attack.
- Client-side `localStorage` tampering (players can always cheat their own browser).

## Supported versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | ✅        |
