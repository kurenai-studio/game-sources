# Product vision and scope

## Identity

The game will be a **complete vertical shoot 'em up, structured by levels**, with free ship movement inside the playable area, a scrolling scenario, enemies organised through waves and patterns, and normally a boss at the end of each level.

The inspiration comes from a space game the author made when starting out in programming. The homage consists of returning to Java and to the space shooter fantasy; not of preserving mechanics, aesthetics, content or architecture from that project.

The DNA that is preserved is:

- a ship controlled by the player;
- threats arriving mainly from above;
- dodging and positioning;
- shooting and destroying enemies;
- an arcade feel accompanied by score.

## Project goal

The product must be:

- functional and playable;
- publishable and easy to show;
- suitable for a portfolio;
- representative of several years of technical growth;
- extensible enough to add campaign, modes, ships and content without rebuilding the core systems.

The portfolio must demonstrate the complete body of work: modular architecture, systems design, testing, continuous integration, performance, documentation, artistic finish, publication and deployment.

The purpose is not “to practise OOP”. Java will be used and there will be objects where appropriate, but the emphasis will be on systems design, modular architecture, finish, tests and the ability to complete and publish the product.

## Confirmed general scope

- Project created 100 % from scratch.
- Single-player and local as the initial scope.
- Java as the main language.
- Retro/pixel-art aesthetic.
- Dependencies allowed only with compatible licences.
- No in-house UI framework will be developed.
- No old code or assets will be reused.
- The main mode will be a level-based campaign.
- Endless and Survival modes will belong to later stages.

## Gameplay fantasy

The player initially pilots an experimental human ship activated during the first wave of an alien invasion. The campaign begins defending Earth, escalates towards orbit and the Moon, reveals a more organic and dangerous alien force, and culminates in a final defence of Earth.

Combat must combine:

- reading patterns and trajectories;
- fast movement to reposition;
- slow movement to dodge with precision;
- prioritised destruction of threats;
- conserving lives, power-ups and attachments;
- strategic use of bombs/special abilities;
- chasing score.

The game was not defined as a pure bullet hell. It may incorporate projectile density and precision, but killing enemies in time, recognising priorities, managing resources and adapting to formations also matter.

## Delivery scales

### MVP

One complete, publishable level with the indispensable systems, a single ship and a simple boss. It must demonstrate the loop, the audiovisual presentation and the technical capability of the product.

### Near post-MVP

Complete the first stage of 3–5 levels, add hangars, more ships and attachments, unlocks, profiles and saving, and prepare the Survival mode.

### Full vision

A five-stage campaign with roughly 15–25 levels, multiple ships with their own styles, attachments, meta-progression, a limited shop, varied bosses, three profiles, Survival, Endless and a possible narrative continuation away from Earth.

## Design principles

### Identity through behaviour

Ships and enemies must be differentiated by how they play, not only by HP, speed or damage. One ship may use sustained shooting, another manual shooting, another charging; some may favour mobility, rate of fire, damage or special abilities.

### Content composition

Enemy type, trajectory, shot pattern, formation and moment of appearance are separable concepts. A basic enemy is not bound forever to a fixed trajectory.

### Contextual progression

Attachments must appear when the level makes their usefulness understandable. For example, countermeasures in a stage with many projectiles or missiles, facing targets against which they are especially useful.

### Difficulty through pressure

Difficulty must not depend only on raising health and damage. It can increase through density, speed, combinations, entrances, patterns, obstacles, available space and simultaneous pressure.

### Content open to iteration

Not all ships, bosses, patterns or stats will be fixed now. The design must allow changing and balancing those elements as real gameplay exists.

## Process constraints

The agreed sequence is:

1. consolidate and review the functional specification;
2. practically validate the web option with Java;
3. decide platform and stack;
4. design the architecture;
5. split tasks;
6. implement the MVP.

Neither the architecture nor the platform should yet be considered closed.

## Project visibility

The repository will be private during the initial stage. Upon reaching the MVP it will be evaluated whether it is worth making it public at that point or waiting until the product is finished. There is no confirmed target date yet.

*Resolved on 25/08/2026: the repository was made public on shipping the MVP.*
