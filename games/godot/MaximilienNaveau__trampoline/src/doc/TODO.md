# Trampoline — TODO

**Status (2026-11-05): the game is playable from start to end, on a
computer and on an Android phone** — solo, 2 to 4 players sharing one
device, free play and 10 crosswords; games save on their own and by hand.
What's left is listed first, most useful first; everything done follows.

Each item is meant to be one (or a few) atomic commits; tick it off once
merged. Rules decisions also go into `RULES.md`, visual ones into
`ART_DIRECTION.md`.

## To do

### 1. Sound
Needs research first: open-source (free-licence) sound effects and music,
each source and licence noted in an assets README.
- [ ] Sound effects: pick up a tile, drop it (wooden "tok"), flip it
      (card "flick"), a word scored, a turn refused.
- [ ] Background music, quiet, looping.
- [ ] On/off switches for both in the ☰ menu, remembered between runs.

### 2. Free play and crosswords
- [x] The start card's green buttons (player count, "Jeu libre", the
      crosswords) always start afresh; the orange "Reprendre la partie"
      picks up whatever was played last, and says what ("Jeu libre",
      "Mots croisés n° 3", or the players and their scores).
- [x] Solved crosswords are marked on the start card (cream, framed in
      green).

### 3. Publishing on the Play Store
- [ ] A release signing key, kept out of the repo (GitHub secrets).
- [x] F-Droid: each `v*` release re-signs the APK with the key of the
      Unity builds (the `ANDROID_KEY*` secrets), checks it's the signer
      F-Droid knows, and triggers the magamajo repo, which publishes it.
- [ ] The store listing: description, screenshots, the icon at 512 px,
      a privacy note (the game collects nothing).
- [ ] The version number and code, bumped with each release.

### 4. Checks on more devices
- [ ] A 16:9 phone (the hand reserves 7 tiles a row; up to 10 fit there,
      so a long hand wastes some height), a tablet, and landscape.
- [ ] Performance on an older phone (animations, the felt's grain).

### 5. Later
- [ ] Colour-blind players: the yellow and green faces differ mostly by
      hue (the corner square helps). A pattern, or a lightness gap between
      the two, would make them tell apart without colour.
- [ ] Maybe: a short animated intro (the tiles actually bouncing) before
      the box lid — the loading image itself can't move.
- [ ] Code: `scripts/main.gd` is at ~900 of the 1000 lines lint allows;
      before adding much more to it, move out the end-turn message and the
      turn timer (as the start card was, see `scripts/start_card.gd`).

## Done

### Playable

#### 1. Passing and the end of the game
Decided (recorded in `RULES.md`, "End of the game"): unlimited passing,
nobody eliminated; one hour of actual play, the round in progress is
finished when it runs out; best score wins, then fewest tiles left in
hand, then a shared win.

- [x] `GameSession`: play time, the last round, ending by time, winners
      with the tie-break (tested, saved with the game).
- [x] Header clock: time left, orange in the last 5 minutes, "Dernier
      tour"; only runs while a turn is being played.
- [x] The screen between turns no longer assumes a phone: "Au tour de
      Alice" / "C'est moi !".
- [x] That screen recaps the scores: every player's score, what the
      last turn changed (in orange), and the time left.
- Won't do (decided 2026-11-05): ending early when every player passes
  two rounds in a row.

#### 2. Score feedback during the turn
- [x] A live "+N" next to the current player's score while they build
      their turn (positive or negative: green letters cost −5), updated on
      every placement, move, flip or take-back, with any bonus it would
      win ("bonus +50").
- [x] When the turn ends, the "+N" floats into the score, and bonuses
      (+10 line, +30/+50 full word, +30 board) pop up separately.
- [x] `GameSession`: a way to ask "what would this turn score right now"
      without ending it (tested).
- [x] Nothing can be changed from "Fin du tour" until the next player
      presses "C'est moi !" (clicks, touches and keys are blocked while
      the points are counted).
- [x] Fixed on the way: a bonus was lost again at the next turn (scores
      were recomputed from the words alone).

#### 3. Android build
- [x] Android export preset (portrait, icon, package name), committed;
      fixed so it actually exports (no Gradle build, ETC2/ASTC textures,
      the dictionary included — it was missing from every export).
- [x] A reproducible APK build: `nix build .#android` from the repository root
      (Godot export templates + Android SDK from nixpkgs, in the Nix
      sandbox), also used by the release workflow on tags. Signed with a
      committed debug key (`keys/`).
- [x] Tested on a real phone (2026-11-05): drag and drop, flipping,
      swapping, arranging the hand, the selection box, the screen fitting.
      Fixed on the way: the layout sat against the top of a tall screen.
- [x] Automatic save at the start of every turn (names included), and a
      "Reprendre la partie" button on the start card; the file dialogs are
      gone.
- [x] Saving by hand: "Sauvegarder la partie" in the ☰ menu keeps a copy
      of the game; "Charger une partie" on the start card lists them (up
      to 8, newest first, with "×" to delete) — to put a solo game aside
      for a game with friends.
- [x] Free play and each crossword save on every change, each to its own
      file, and pick up where they were left when chosen again.
- [x] The dictionary loads in ~50 ms instead of ~3 s: the word list ships
      pre-normalized and sorted (`data/dictionaries/fr-words.txt`, rebuilt
      by `tools/build_word_list.gd`, checked up to date by the tests).
- [x] Thinner page margins and board rim, for bigger tiles on a phone;
      room left at the top (status bar, camera cutout) and the spare room
      at the bottom (Android's back/home buttons).
- [x] While loading: TRAMPOLINE's tiles bouncing off a trampoline, with
      "Fait avec Godot" in the corner, instead of Godot's logo; the app
      icon is an M/C tile.

#### 4. To think about further
- [x] Moving tiles (2015 rules, see `RULES.md` "Moving and swapping
      tiles"): any tile moves during a turn, alone or in a block picked
      with a dotted selection box; dropping a tile on another swaps it into
      the hand; the turn can't end with a cell emptied that held a letter;
      each turn earns the board's change in worth.
- [x] "Comment jouer" cards for swapping, the selection box,
      "Recommencer", and arranging the hand.
- [x] "Recommencer" in the header: the board and hand back as they were
      when the turn began.
- [x] Under the hand: "Trier" (A to Z), "Tout jaune", "Tout vert"; a hand
      tile can be dragged to another place in the hand.
- [x] A hand over 14 tiles gets a third row (or more): the board makes
      room for as many rows as the hand needs, at 7 tiles a row.
- [x] `tests/test_save_game.gd` failed now and then: it looked for given
      letters only in the undrawn pile, which the deal had sometimes
      emptied of them. It now looks in the hands too.

### Polish

#### 5. The hand on a play mat
- [x] The hand (and the "À rendre" tray) sits on the background, drawn as
      a **play mat** (felt, like the real game's desk mat), not on
      the plain dark page.
- [x] Hand, tray and dragged tiles drawn as 2.5D blocks with their cork
      sides (like the tiles off the board in the "Comment jouer" cards),
      matching the board.
- [x] The whole game screen on the desk felt, and the screens over it
      (between turns, end, "Comment jouer") too; the "À rendre" tray a
      dark felt pocket instead of a green box.

#### 6. In-game motion
From `ART_DIRECTION.md` → "Motion" (never blocking input):
- [x] Tile dropped on a cell: squash-and-bounce.
- [x] Tile flipped: the turn-over animation (narrow, swap face, widen),
      as in the "Comment jouer" cards.
- [x] Drag: the tile lifts (slightly bigger, soft shadow; the tilt was
      dropped, it blurred the letters).
- [x] Valid word scored: letters hop left to right, `+N` floats up.
- [x] Broken turn: offending tiles shake (keep the red border).
- [x] Board complete: rows hop top to bottom, before the end screen (the
      ribbon bow left out).

#### 7. Header
- [x] Buttons and text in Jost (Baloo 2 removed), per the art direction.
- [x] "☰" replaced by a small drawn icon.
- [x] Scores easier to read at a glance: one rounded chip per player,
      the name small and the score big; the current player's framed in
      orange.

#### 8. End of game
- [x] A proper end screen instead of the text banner: final scores
      ranked (tiles left in hand break ties), the winners in orange.
- [x] "Rejouer" (same players) and "Menu" buttons; going back to the
      menu closes the lid over the box.
- [x] Solo: a finished board with no green face at all ("Grille
      parfaite !") rains yellow tiles and pulses the score; otherwise the
      screen counts the green faces left, the next game's target.
