# Progression, modes and saving

## The campaign as the main path

The campaign must teach systems, present ships/attachments and unlock modes. The player obtains basic variety simply by progressing; special challenges are reserved for rare or prestigious content.

## Three profiles

The complete game will have **three independent profile slots**.

Each slot saves:

- campaign progress;
- levels and stages completed;
- unlocked ships;
- unlocked attachments;
- unlocked modes;
- permanent shop content;
- scores and records;
- a valid continuation state;
- possible secrets/challenges.

## Global configuration

Preferences must be shared across the three slots:

- master volume;
- music;
- effects;
- mouse enabling;
- keybindings once they exist;
- future fullscreen, resolution and accessibility.

The motivation is that switching profile should not modify the controls or the volume chosen by the same person.

## Saving

### Confirmed events

- Autosave on finishing a level or a stage.
- Autosave on reaching a safe point/hangar where applicable.
- **Save and quit** button.
- **Continue** button, from the slot's last valid state.

### Save and quit during a level

Continuing returns to the **last safe checkpoint**. The exact position within the action is not preserved, but the state the player had when the run was saved is recovered: lives, unconsumed power-ups, bombs, attachment, run currency and other relevant resources.

If there is no intermediate checkpoint, it returns to the checkpoint at the start of the level or section, keeping the saved player snapshot, unless future balancing determines concrete exceptions.

### Checkpoints

- They will be used in long or difficult levels.
- They are not implemented in the MVP.
- The checkpoint defines a safe point and a reasonable initial loadout **only for a new run started from there**.
- Starting from an advanced stage may grant power-ups, bombs or base currency depending on stage/difficulty.

### Two different ways of using a checkpoint

**Continue a saved run:** recovers the player's snapshot in that run and resumes from the corresponding safe checkpoint.

**Start a run from the checkpoint:** creates a new run with the checkpoint's default configuration, tuned to the section and the difficulty.

## Hangar

It normally appears at the end of each stage; there may be limited intermediate points.

It allows:

- changing ship;
- equipping unlocked attachments;
- syncing newly discovered content;
- using the run's run currency;
- saving and preparing the next section.

The hangar turns unlocks into configuration decisions without allowing arbitrary changes in the middle of combat.

## Mode unlocking

- **Survival:** on completing the first stage, as an early reward.
- **Endless:** on completing the whole campaign, as a final reward.
- Codes/cheat codes: possible for testing, easter eggs or special unlocking, but they do not replace normal progression.

## Survival mode

### Identity

An infinite, cyclical campaign, with levels, transitions and hangars.

### Cycle

- First cycle: settings/stages 1–5.
- Second cycle: visually returns to stage 1, but with difficulty equivalent to stages 6–10.
- Third cycle: difficulty equivalent to 11–15.
- Continues until you lose.

Neither progress nor difficulty is reset when returning to the stage 1 setting.

### Variation

- New formations.
- More advanced enemies.
- Different patterns.
- Changed or modified bosses.
- Greater density, simultaneity and pressure.

### Metrics

- Cycle/stage reached.
- Score.
- Duration, if it turns out to be useful.

### Damage model

HP/accumulated attrition was suggested, but it is not settled.

## Endless mode

### Identity

A single continuous session, similar to a level without an end. Enemies, formations and bosses appear indefinitely until the player loses all their lives.

### Progression

- Power-ups and modules obtained during the same run.
- Increasing difficulty.
- Score and duration as the main metrics.

### Hangar

The inclusion of hangars was left open. They could break the continuous rhythm, but they may be necessary for module progression.

### Damage model

A hybrid HP + lives system was suggested, still not confirmed.

## Meta-progression and shop

The permanent shop must not dominate the project. Content considered:

- skins;
- some special ship;
- some special attachment;
- cosmetic or prestige content.

The final currency is open. Using accumulated score is simple, but spending a historical record would be confusing. Alternatives:

- non-spendable historical score + derived credits;
- a separate meta currency;
- rewards for milestones/challenges.

## Codes

Codes may serve for:

- testing;
- internal unlocks;
- easter eggs;
- promotional/special content;
- easing access on another platform.

They must not replace the player's progression.
