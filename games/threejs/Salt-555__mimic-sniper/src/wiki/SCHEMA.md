# Wiki Schema

## Domain
Mimic Sniper — a low-poly Three.js multiplayer game. One player controls a generative tentacled blob ("the Mimic") that moves around and can transform into nearby objects. The other player is a stationary sniper at a vantage point trying to spot and eliminate the Mimic. Think Prop Hunt meets Hitman sniper mode.

Target platform: Raspberry Pi 5 browser (Chromium kiosk) or web deployment.
Tech stack: Three.js, vanilla JS, local multiplayer on single machine or networked via WebRTC/WebSockets.

## Conventions
- File names: lowercase, hyphens, no spaces (e.g., `mimic-transformation-mechanic.md`)
- Every wiki page starts with YAML frontmatter (see below)
- Use `[[wikilinks]]` to link between pages (minimum 2 outbound links per page)
- When updating a page, always bump the `updated` date
- Every new page must be added to `index.md` under the correct section
- Every action must be appended to `log.md`
- Code examples use JavaScript/TypeScript with Three.js r160+
- Research pages cite primary sources (Three.js docs, GitHub issues, Stack Overflow) not aggregated lists

## Frontmatter
```yaml
---
title: Page Title
created: YYYY-MM-DD
updated: YYYY-MM-DD
type: entity | concept | comparison | query | summary
tags: [from taxonomy below]
sources: [raw/articles/source-name.md]
---
```

## Tag Taxonomy
**Mechanics:** mechanic, input, physics, collision, ai, animation, transformation, ballistics, camera, ui
**Assets:** model, texture, material, low-poly, procedural, shader, audio
**Architecture:** rendering, scene-graph, networking, state-machine, performance, pi5-optimization
**Design:** level-design, game-loop, win-condition, difficulty, art-direction
**Research:** best-practice, threejs-pattern, benchmark, reference

Rule: every tag on a page must appear in this taxonomy. If a new tag is needed, add it here first, then use it.

## Page Thresholds
- **Create a page** when a mechanic/concept appears in 2+ sources OR is central to game design
- **Add to existing page** when a source mentions something already covered
- **DON'T create a page** for passing Three.js API details — link to official docs instead
- **Split a page** when it exceeds ~200 lines — break into sub-topics with cross-links

## Entity Pages
Game entities: the Mimic, the Sniper, environments, transformable objects. Include:
- Visual description and low-poly aesthetic guidelines
- Behavior / capabilities
- Technical implementation approach
- Relationships to other entities ([[wikilinks]])

## Concept Pages
Mechanics, systems, research findings. Include:
- Definition / how it works in-game
- Three.js implementation strategy with code patterns
- Known pitfalls and performance considerations (especially Pi 5 constraints)
- Related concepts ([[wikilinks]])

## Comparison Pages
Side-by-side analyses of approaches (e.g., WebRTC vs WebSocket for multiplayer). Include:
- What is being compared and why
- Dimensions of comparison (table format preferred)
- Verdict or recommendation
- Sources

## Update Policy
When new information conflicts with existing content:
1. Check the dates — newer sources generally supersede older ones
2. If genuinely contradictory, note both positions with dates and sources
3. Mark the contradiction in frontmatter: `contradictions: [page-name]`
4. Flag for user review
