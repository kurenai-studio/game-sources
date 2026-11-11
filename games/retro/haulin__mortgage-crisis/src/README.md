# Mortgage Crisis

A card game inspired by Monopoly Deal, built for the [TIC-80](https://tic80.com) fantasy console.

Collect 3 complete property sets to win. Bank money, charge rent, steal properties, and cancel attacks with Just Say No. Play against an AI opponent.

**Demo v0.22** — playable start to finish.  
Full version in development.

🎮 Play on itch.io: [haulin.itch.io/mortgage-crisis](https://haulin.itch.io/mortgage-crisis)  
🕹️ Play on tic80.com: [tic80.com/play?cart=4646](https://tic80.com/play?cart=4646)

---

## Feedback & Bugs

Found a bug? Have feedback? [Open an issue](https://github.com/haulin/mortgage-crisis/issues)
— all reports welcome.

---

## About the Project

Built on TIC-80 using JavaScript (ES5-compatible, Duktape/QuickJS portable). ~12k LOC, 200+ unit tests.

Developed with AI pair programming (Claude, GPT). One of the goals of this project was exploring what vibe-coding a complete game from scratch looks like in practice.

Inspired by Monopoly Deal by Hasbro. Not affiliated with Hasbro.

---

## Development

### Prerequisites

- [TIC-80 Pro](https://nesbox.itch.io/tic80) (for external file workflow)
- Node.js (for build + tests)

### Build

```bash
npm run build    # concatenates src/ into game.js
npm test         # unit tests
```

### Running

In TIC-80: `import code game.js`

Or paste `game.js` into the TIC-80 code editor

(subject to size limits in non-Pro builds)

### Project Structure

```
src/          source files (edit these, not game.js)
docs/         phase plans, sprite map, user manual
tic-80-docs/  TIC-80 API + offline wiki (reference)
other/        old experiments and discarded assets
game.js       generated cartridge (do not edit directly)
```

### Contributing

This is a personal project but issues and PRs are welcome.  
See [`docs/development.md`](docs/development.md) for dev workflow notes.  
See `AGENTS.md` for AI coding guidelines.

---

## License

MIT — see `LICENSE`.  
Mechanics inspired by Monopoly Deal (Hasbro).
All code and assets original.

