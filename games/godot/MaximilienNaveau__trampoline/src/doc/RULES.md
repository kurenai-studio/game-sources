# Trampoline — Game Rules Reference

"Un jeu pour faire rebondir les mots" ("a game that makes words bounce"),
designed by Michel Cheenne (1999, revised 2015). This document is the
settled, cross-validated reference for anyone (human or agent) implementing
or porting the game — it supersedes the raw legacy files below as the
source to read first.

**Provenance**: extracted from Michel Cheenne's legacy design documents
(kept privately since 2026-11-06, not in this repository: `Trampoline.doc`, `" Trampoline Version 2015.doc"`, `Compter les points
.ods`, the `GRILLE *.xls` puzzle booklet, `Une lettre.xls`, `testtonio.xls`)
and cross-validated against the existing Unity/C# implementation in
`../trampoline-unity/Assets/Scripts/` (`TokenPool.cs`, `BasicToken.cs`,
`TokenDistributor.cs`, `RowLetterHistory.cs`, `TurnManager.cs`), plus
clarifications from Maximilien Naveau (current implementer) where the
sources disagreed or were ambiguous. Where this document and the legacy
files disagree, this document wins.

## Overview

- **Board**: one fixed 13-row x 9-column grid (117 cells). No bonus or
  multiplier squares of any kind.
- **Goal**: fill the whole board by composing 13 horizontal words, one per
  row, normally 9 letters each (see "Shortened words" below for the
  exception). The game ends the instant the 117th cell is filled (or, in
  practice, once every row is either a completed 9-letter word or a
  deliberately shortened word — see below).
- **Players**: 1 to 4, sharing one board and one shared pool of tiles.
  There is no separate "single-player ruleset" — solo play is just the
  1-player case of the same turn-based system (see "Single-player modes"
  below for the three distinct ways solo play can be offered).
- **Tiles**: 117 double-sided tokens. Every tile has a letter on its yellow
  face and (almost always) a different letter on its green face. Flipping a
  tile changes which letter it currently shows.

## The "Trampoline" mechanic

The name refers to two related things:

1. **Words only ever grow.** Once a cell has been filled by any player, it
   must never end up empty again after a subsequent move. Words extend
   (prefix or suffix), get letters swapped out for other letters, or get
   completed by another player — but a filled cell is never vacated.
   During a turn, tiles may move freely; the rule is checked when the turn
   ends (see "Moving and swapping tiles" below).
2. **Tiles physically flip between two faces.** A tile already on the board
   can be flipped in place to reveal its other letter, changing the word
   without removing the tile — this is still "growing," never "emptying."

## Scoring

Formula: **a word of n letters is worth 1 + 2 + … + n, minus 5 per green
letter**, plus bonuses:

| Bonus | Condition |
|---|---|
| +50 | Complete a 9-letter word in a single move, entirely yellow |
| +30 | Complete a 9-letter word in a single move, mixed yellow/green |
| +10 | Complete any line (reach 9 filled cells in a row), any timing |
| +30 | Complete the entire 117-cell board |

The 2015 rules: *"La case 1 vaut 1 point, la case 2 vaut 2, etc.. la case
9 vaut 9. La ligne totale vaut 45 points."* The nth letter of a word is
worth n — whichever side it was added on.

**Each turn earns what it changed the board's worth by. Decided by
Maximilien (2026-11-04):** the board is worth the sum of its valid words
(as above); a turn earns the board's worth when it ends minus its worth
when it began, plus the bonuses won. Nobody owns a letter: placing,
moving, swapping and flipping all count the same way, and breaking a word
costs the player who broke it.

Worked example: Player 1 places a 6-letter word, earning 1+2+3+4+5+6 = 21.
Player 2 later completes it to 9 letters by adding a 3-letter prefix *or*
suffix (either side scores the same): the word is now worth 45, so they
earn 45 − 21 = 24 (and +10 for the line). This is deliberate: it rewards
*completing* a risky short word more than starting it, which is a core
part of the game's tension — do you lay down a short word now (cheap
points, but you're handing the bigger payoff to whoever finishes it), or
hold back for a full 9-letter word yourself?

Only dictionary-valid words count toward score (see "Word validation"
below). Green letters cost 5 points each regardless of position.

(The Unity implementation, `RowLetterHistory.cs`, numbered letters by
placement order within a row and credited each to whoever placed it. The
Godot game replaced that with the above once tiles could move freely.)

## Letters and tiles

117 tiles, each with a yellow-face letter and (almost always) a green-face
letter. Distribution, fully cross-validated between the docs' annex table
and the existing Unity `TokenPool.cs` (they match exactly):

| Letter | Yellow | Green | | Letter | Yellow | Green |
|---|---|---|---|---|---|---|
| A | 8 | 7 | | N | 8 | 7 |
| B | 3 | 3 | | O | 6 | 6 |
| C | 4 | 4 | | P | 3 | 3 |
| D | 3 | 3 | | Q | 2 | 2 |
| E | 18 | 12 | | R | 9 | 8 |
| F | 3 | 3 | | S | 9 | 7 |
| G | 2 | 2 | | T | 8 | 7 |
| H | 2 | 2 | | U | 7 | 6 |
| I | 9 | 8 | | V | 2 | 2 |
| J | 1 | 1 | | W | 1 | 0 |
| K | 1 | 0 | | X | 1 | 1 |
| L | 4 | 4 | | Y | 1 | 1 |
| M | 3 | 3 | | Z | 1 | 1 |

Yellow total = 119, Green total = 103 assigned + 12 "shorten" blanks (see
below) = 115. 119 + 115 = 234 = 117 tiles x 2 faces.

Note K and W have zero green letters — those two tiles are yellow on
**both** faces (K/U and W/S respectively), so K and W never incur the
green penalty by design.

The exact front/back pairing for all 117 tiles (which specific yellow
letter is paired with which specific green letter) is not separately
documented here — it's canonically defined in
`../trampoline-unity/Assets/Scripts/TokenPool.cs` (`InitializeTokens()`, all 117
`SetParameters(...)` calls). Treat that file as the source of truth for
pairing; reuse it directly when porting rather than re-deriving a new one.

### Shortened words ("-" tiles)

12 of the 117 tiles have a green face marked "-" (no letter) instead of a
second letter. Flipping a tile to show "-" lets that row's word end early
— shorter than 9 letters — instead of forcing a full 9. This is an
intentional difficulty-easing option, not missing data. A shortened row
simply forfeits the higher-value late position-scores and the 9-letter/
line-completion bonuses for that row.

The 12 are unevenly distributed and look deliberately tuned: 7 in row 2
alone (all `E`-fronted tiles), 1 each in rows 6/7/9/10, none in rows
0/1/3/4/5/8/11/12 — row 2 reads as the designed "easy" row.

## Turns and draws

Draw counts are tuned per player count so the 117 tiles divide evenly:

| Players | Initial draw | Then | Total per player |
|---|---|---|---|
| 2 | 13 | 5 draws of 9 | 58 each (116 total; 117th tile to whoever starts) |
| 3 | 12 | 3 draws of 9 | 39 each (117 total, exact) |
| 4 | 11 | 2 draws of 9 | 29 each (116 total; 117th tile to whoever starts) |

That table is the 2015 rules' schedule. Neither the 2015 nor the 1999
rules text says how many tiles a player may hold, or what happens to the
ones they don't place (the 1999 worked example ends with "lettres non
utilisées à rejeter"). **Clarified by Maximilien (2026-11-02), and what
the implementation does:**

- **The first draw is the hand limit**: 13 tiles for 2 players, 12 for 3,
  11 for 4 (9 in solo). Everyone is dealt a full hand at the start.
- **Each turn starts by refilling** the current player's hand back up to
  that limit from the shared bag, as far as the bag allows — never above
  it. (A tile picked back up off the board can take a hand over the
  limit; that hand then simply draws nothing.)
- **Giving tiles back**: during their turn a player may set tiles aside
  (dragged into the "À rendre" tray beside the hand, in the game; dragged
  back out if they change their mind); when the turn ends those go back
  into the bag at random places, and the next turn's refill replaces
  them — so the next player never sees the new tiles.
- Since tiles return to the bag, the per-player totals in the table
  (58/39/29) no longer apply, nor does the 117th "starter" tile: drawing
  is only limited by what's left in the bag. A player is out of the game
  once their hand and the bag are both empty.

Each turn has a 3-minute soft/hard time limit to place a word (treat as a
real constraint to respect, not just a suggestion).

**A turn is confined to a single row.** From the 2015 revised legacy design
("Trampoline Version 2015.doc"): *"Jouer c'est placer une ou plusieurs
lettres sur une seule ligne horizontale vide ou partiellement occupée"*
("playing means placing one or more letters on a single horizontal line,
empty or partially occupied") — a player picks ONE row (empty or already
started) each turn and only extends/edits that one, never touching a
second row in the same turn, and never splitting that one row's own
letters into more than one disconnected group either. This was missing
from an earlier version of this document and from the Godot implementation
until 2026-08-05; see `TurnValidity` in
`scripts/turn_validity.gd` for the current enforcement.

**Every word starts in the first column. Decided by Maximilien
(2026-11-05):** a row's word is read from its leftmost cell, and grows to
the right. Letters standing anywhere else in a row — a second word, or
one word shifted right — aren't a word: they're worth nothing (see
`Scoring.board_value`), they're framed in red, and the turn can't end
while they're there ("Les mots commencent à la première colonne.", see
`WordChallenge.find_invalid_words`). A blank ("-") tile still ends a
row's word early.

**Simplified for the current implementation** (confirmed by Maximilien,
same spirit as "Word validation" below): the legacy text also frames each
placement as extending the row's existing word from one of its two ends
("chercher à allonger un mot déjà placé"), never dropping a letter
elsewhere in an already-started row. The Godot implementation deliberately
doesn't enforce that adjacency — any empty cell in the turn's chosen row is
fair game, and `TurnValidity` only objects once the result is actually
disconnected. A placement is never refused outright either way: like an
invalid dictionary word, a broken turn is flagged live (the offending
tiles are highlighted) and blocks ending the turn, rather than being
silently rejected the moment it happens.

### Moving and swapping tiles

The 2015 rules let a player rework what is already on the board before
placing: *"il est permis, avant de poser, d'échanger des lettres entre
tirage et lettres posées"*, *"du simple échange de lettres, au
remplacement total ou partiel de mots déjà en place"* — with one strict
condition: *"aucune case occupée avant une intervention ne doit être
vidée de son contenu"*. **Decided by Maximilien (2026-11-04), and what the
game does:**

- **Any tile on the board may be moved during a turn**, whoever placed it
  and whenever: dragged alone, or several together (a drag across empty
  cells draws a dotted box; the tiles under it move as one block, keeping
  their shape).
- **Swapping**: a tile dropped on another takes its place; the one it
  landed on goes into the player's hand (*"échanger des lettres entre
  tirage et lettres posées"*), to play from there like any other. A board
  tile can also be dragged back into the hand.
- **The turn can't end while a cell that held a letter when the turn
  began is empty** (framed in red). A blank ("-") tile's cell is the
  exception: taking it off shortens a word on purpose.
- The single-row rule above applies to the letters put down from the
  hand, not to tiles only moved on the board.
- Since every word starts in the first column, moved tiles must end up
  in the row's one word: TOUT slid right by three, then P, A, R put
  before it, gives PARTOUT (28) against 10 before: that turn earns +18.

## End of the game

The 2015 rules' only end condition is the board itself: « La partie se
termine avec la pose de la 117ème lettre. » They also say a word must be
placed every turn (« au terme [des 3 minutes] un mot doit être placé »),
and never say who wins. The 1999 text adds « Une partie dure au maximum
1 heure ! ». **Clarified by Maximilien (2026-11-03), and what the
implementation does** (turn-based games only, solo included; free play
and crossword have no time limit):

- **Passing is allowed, as often as a player likes**, with or without
  giving tiles back: another player's word can unblock them later. A pass
  simply scores nothing. Nobody is ever eliminated.
- **The game lasts one hour of actual play.** The clock only runs while
  someone is playing a turn — not on the screen between two players'
  turns, in menus or dialogs, or while the app is in the background — and
  is saved with the game. The header shows the time left, discreetly, then
  in orange during the last 5 minutes.
- **When the hour is up, the current round is finished** ("Dernier
  tour"), so that every player has had the same number of turns, then the
  game ends. (Solo, a round is one turn.)
- The game also ends as soon as the board is complete, as in the rules.
- **The best score wins.** On equal scores, whoever has the fewest tiles
  left in hand wins; if that's equal too, they all win.

## Word validation

Any word in a standard dictionary is legal, including proper nouns,
compound words, and all grammatical forms (plural, gender, conjugations).
Proper nouns (first names, places) and the acronyms the word list holds
stay playable — confirmed by Maximilien, 2026-11-05.

The original design is a reactive **challenge**: a turn can end with a bad
word on the board, and another player can challenge it afterward; if
proven wrong, it's removed from the board and the offending player loses
their turn. **Simplified for the current implementation** (confirmed by
Maximilien): rather than building the full challenge/penalty flow now, a
player simply cannot end their turn while any word on the board is
invalid (`WordChallenge.can_end_turn`, in `scripts/`) —
every turn must leave only valid words behind, no challenging needed. The
fuller challenge/penalty mechanic — including several open questions
(where removed tiles go, what the penalty actually is, who can challenge
and until when, whether a failed challenge penalizes the challenger) — is
documented in that same file for whenever it's worth revisiting.

## Single-player modes

Solo play (1 player) can be offered three distinct ways, all sharing the
same core board/tile-pool/word-validation primitives but differing in
their turn/scoring layer:

1. **Turn-based** — identical ruleset to multiplayer (draws, turn timer,
   scoring, bonuses), just with 1 player. This is the N=1 case of the same
   turn engine used for multiplayer — no separate implementation needed.
2. **Free play** — access to all 117 tokens at once, no turns, no draw
   restrictions, build the board freely. No competitive scoring pressure;
   more of a sandbox/practice/creative mode.
3. **Crossword reconstruction** — load one of the pre-authored example
   grids (the `GRILLE *.xls` puzzle booklet — see below) as a target, show
   its clues, and challenge the player to use the 117 tokens to recreate
   the exact target grid.

**Current Unity implementation status** (as of 2026-07-25, for anyone
porting/continuing this work): what's live today under "solo mode" is
actually mode 2 (free play) — `GameController` + `Board` + `Store`, no
turns, all tokens visible at once. The full turn-based engine for mode 1
(`GameControllerMultiplayer`, `BoardMultiplayer`, `TurnManager`,
`TokenDistributor`, `StoreMultiplayer`, `PlayerManager`) already exists and
looks complete, but `GameSceneController.LoadScene()` doesn't route to it
yet — the multiplayer scene-load branch is a `/// @todo` with the actual
`SceneManager.LoadScene` call commented out, so neither true turn-based
solo nor real multiplayer is reachable from the game's menu today, only
free play is. Mode 3 doesn't exist in any form yet; it needs the puzzle
content below plus new goal-checking logic.

Mode 3 could plausibly be extended to multiplayer later (e.g. a race to
solve the same target grid), but that needs real design work on
synchronization and is explicitly deferred — a "race on separate boards,
compare results at the end" version would be far simpler than a shared
live board, if/when this gets revisited.

## The example puzzles ("GRILLE" files)

The 11 `GRILLE nn&mmr.xls` files (Michel Cheenne's, kept privately) are **not board variants**
— all 11 use the identical 13x9 board and letter set. They're a
crossword-style example-puzzle booklet: each sheet has 13 clues (one per
row) for puzzle N with no letters given, plus the answer key (13 clues +
their 9-letter solutions) for the *previous* puzzle N-1, printed on the
same sheet as a practical print convention. Grid 11 has no answer key (a
hypothetical "file 12" was never produced). These are good source content
for the "crossword reconstruction" single-player mode above, and/or as
built-in tutorial content.

## Deferred / out of scope for now

- **"Trampoline Version jaune plus.ods"** — best-evidenced reading is a
  doubled-size variant (26 word-lines / 234 cells instead of 13/117, i.e.
  literally double the base game). Confirmed out of scope for the initial
  rewrite.
- **Networked multiplayer** — the turn-based engine described above is
  designed be inherently multi-player (shared board/tile-pool/turn model),
  but only *local* multi-player (same device, players taking turns) is in
  scope right now. Remote/networked play is a later concern.
