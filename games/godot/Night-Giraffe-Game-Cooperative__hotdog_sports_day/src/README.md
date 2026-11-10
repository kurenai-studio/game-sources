# HotDog Sports Day

_Sports day for hot dogs: sixteen events, summer and winter. They have
no arms and no legs: they bounce. Tap RUN, RUN to go faster, JUMP at the
line, hold it and let go in the green, the way Track & Field did it; and
where the music is the game (diving, trampoline, breaking, skateboarding),
tap on the beat._

Lineage: Konami's Track & Field and International Track & Field (side-on
stadium, one event after another, qualifying marks, a run button and a jump
button), turned from a button-mashing game into a rhythm game. A Night Giraffe
Game Cooperative game; the quality bar is the studio's Heartwood: one
consistent look made by scripts in the repo, deep but readable systems, tests.

This file is the design source of truth: what the game is and how it's
built. The decisions behind it are in `DECISIONS.md`.

### Playing it

`godot` in this folder, or the Android build in `build/`. One player: the left
half of the screen (or Space, Z, A, Left) is BOUNCE, the right half (or Enter,
X, S, Right) is JUMP. Up to four share a tablet: two have a half each,
BOUNCE on its outer quarter and JUMP on its inner one (keys A/S and K/L);
three or four have a strip each along the bottom. New players start with
LEARN TO PLAY (three short lessons with a coach). Up to four also play
together over the home Wi-Fi: another tablet joins this one's game
(PLAY TOGETHER, then JOIN A GAME ON ANOTHER TABLET on the other) and shows it
with its own buttons, or a phone scans the QR code and becomes a player's
buttons (section 4).

- Tests, headless: `godot --headless --path . --script res://tests/run_tests.gd`
  (a cold checkout needs one `godot --headless --path . --import` first)
- The bot plays every event through the real screens:
  `godot --headless --path . -- --play --fast` (`--event=hurdles` for one or
  `--event=dive,swim` for a few, `--champ` for a whole championship,
  `--players=4` with two pretend phones)
- Phones by hand on this computer: `godot --path . -- --event=sprint
  --wait-phones=1 --loopback --remote-log`, then open http://127.0.0.1:8642/
  in a browser (the log prints each press and how old it was on arrival)
- Two copies side by side: the host as above, then `godot --path . --
  --join=127.0.0.1 --loopback --remote-log --auto-tap --snap=guest` (it taps
  on the beat by itself, logs pictures a second and how far its music is
  from the host's, and saves its screen to `shots/guest.png` every 2s)
- Screenshots of every screen into `shots/`: `godot --path . -- --shots`
  (opens a window for about two minutes; `--only=dive` for one event). The
  screenshots, the bot and `--auto-tap` play silently; add `--sound` to hear
  them.
- All the art: `python tools/gen_art.py` (or name parts: dogs, wardrobe,
  face, flags, crowd, stadium, icon); the fonts: `python tools/font.py`
- The sounds: `python tools/gen_audio.py` (needs the sample library:
  `python tools/fetch_recordings.py`)
- The music: `python tools/fetch_music.py`, then `python tools/make_music.py`
  (converts, levels and measures each track's beat into `data/music.json`;
  needs numpy, scipy and ffmpeg). The public repository doesn't hold the
  music files: Pixabay's licence lets them ship inside the game, not on
  their own. Until they're fetched the game plays without music, to a
  steady beat.
- Android: `godot --headless --path . --export-debug "Android" build/hotdog_sports_day.apk`,
  signed with Godot's debug keystore, package `com.nightgiraffe.hotdogolympics`
  (the game's first name, kept so an update keeps everyone's progress)

---

## 1. Pillars

1. **Track & Field controls, and the beat where it's the game.** Running,
   jumping and throwing work the arcade way: RUN, RUN for speed, the action
   button timed to the line and held for the angle (0.10.0; the game began
   as rhythm over speed, and the young players it's for found that too
   hard). The beat rules the dive, the trampoline, breaking, the skateboard
   and the ski jump, and the hot dogs always bounce to the music.
2. **Hot dogs, properly.** Eighteen nations, each its own country's hot dog,
   with cartoon faces and 80s sweatbands. No arms, no legs, all bounce.
3. **Arcade-simple, deep to master.** Two buttons. Anyone can finish; a
   perfect run needs perfect time.
4. **One pen draws everything.** Every sprite comes from `tools/pix.py`, one
   palette (`tools/palette.py`), one light from the upper left.
5. **Play together.** Up to four in every event: two on a tablet, side by
   side, and the rest on a second tablet or their own phones. In the Games
   they are one team.

## 2. The bounce

A hot dog bounces two or three times a second, on the beat: the game picks
how many bounces a beat (`Beat.sub`) so the bounce rate is near 2.9 a second
whatever the track's tempo. Every landing is on a bounce slot.

A tap is judged against the nearest landing: within 50 ms (70 on Junior) is
**perfect**, 90 (115) **good**, 130 (160) **ok**. A landing with no tap is a
**miss**; a tap with no landing near it, or a second tap on the same landing,
is a **wobble**. Each judged landing pulls the hot dog's **spring** part of
the way toward what its grade earns (perfect 1.0, good 0.74, ok 0.45, miss
0.12, wobble 0.05), so spring always says how the last few bounces went.
Speed is spring to the power 1.4, so the last of the speed is for perfect
taps. Eight perfects in a row and the hot dog is **sizzling**: 5% faster,
starry-eyed, the crowd on its feet.

The JUMP button does what the event needs: in hurdles it turns the next
bounce into a big one (two slots long) that clears a hurdle; in the jumps it
plants the hot dog on its landing, squashed, while the aim rises 45° a beat,
so holding from one beat to the next is the classic 45°. Letting go launches.

The helpers (on by default) draw a ring on the ground that closes as the hot
dog comes down to land, and turn it blue on the landing to jump from.

## 3. The events

| Event | What you do | Marks (junior / pro qualify, record) |
| --- | --- | --- |
| 100m Bounce | Tap every landing on the beat. | 16.0s / 12.4s, 10.80s |
| Long Jump | Bounce up the runway, hold JUMP on the last landing before the board, let go on the beat. Measured from take-off. Three tries. | 5.00 / 7.00m, 8.60m |
| 110m Hurdles | Tap JUMP on the landing before each hurdle for a big bounce over it. Clipping one costs spring. | 19.5s / 14.6s, 12.90s |
| Hop, Skip & Jump | JUMP by the board to hop, JUMP on landing to skip, then hold and let go. | 11.0 / 14.6m, 17.90m |
| High Jump | Seven bounces in, hold JUMP on the last and let go (the aim rises from 40°), then JUMP at the top to arch over the bar. Three tries a height; countback breaks ties. | 1.70 / 2.10m, 2.40m |
| High Dive | Bounce on the springboard on the beat, JUMP to take off; in the air BOUNCE on the beat is a somersault, JUMP a twist. Be straight by the water. Five judges. Three dives, total. Sixteen bounces without taking off is a balk: nothing. | 60 / 150 pts, 240 pts |
| 4×50m Relay | Four of your hot dogs. JUMP on a landing inside the yellow box to tag the next; a tag on the beat hands over all the spring, running through the box fumbles it. | 30.0 / 23.0s, 20.20s |
| Steeplechase | 200m, six barriers that don't fall (clip one and clamber over, slowly) and a water jump. | 32.0 / 24.0s, 21.40s |
| Meatball Put | No arms: a header. Bounce on the spot to build spring, hold JUMP on a landing, let go as the aim comes up past 40°. Sixteen bounces without a put is a foul. | 11.0 / 18.5m, 22.90m |
| Springboard Vault | The high jump with a springboard: nine bounces in, hold and let go on the board, arch at the top. The camera rises with you. | 4.00 / 5.25m, 6.00m |
| 50m Bun Paddle | The stadium becomes a pool. Stroke on the beat; JUMP on the fourth beat of every bar to breathe, or gulp. | 17.0 / 12.4s, 10.20s |
| Trampoline | Two beats a bounce: BOUNCE as you land, a trick on the beat at the top (BOUNCE somersault, JUMP twist), eight skills, JUMP to stick it. Difficulty, execution, flight. | 22 / 40 pts, 52 pts |
| Breaking | A dance battle: the MC dances a two-bar pattern, you dance it back (BOUNCE toprock, JUMP head-spin), three rounds, busier each time; a note highway shows the moves. Same patterns for everyone. | 90 / 170 pts, 218 pts |
| Skateboarding | The board rolls in time with the music, so every obstacle arrives on a beat: push on every beat for flow, JUMP to ollie a cone, grind a rail (hold, let go on its last beat) or launch off a ramp (trick at the top, land on the beat). A JUMP with nothing to jump costs flow. | 600 / 1700 pts, 2500 pts |
| Ski Jump | Tuck on every beat down the in-run, JUMP on the downbeat at the edge, BOUNCE on every beat in the air to hold the V, JUMP as you touch down for a telemark (the first reach counts; more wobble). Distance and style points. | 70 / 120 pts, 148 pts |
| Bun Bobsleigh | The bun is the sled. Push for a bar, JUMP on the downbeat to hop in, then lean with every bend on its beat (JUMP high, BOUNCE low). | 28.0 / 21.5s, 19.40s |

Records live in `data/events.json` until a player beats one; then the
player's record is kept in the profile and shown with their name.

## 4. The Games

A set series of events (`data/series.json`), four in each event: the players
and the nations that shine at it (`best` and `also` in `data/nations.json`).
The series: Track & Field, The Classic Six, Water & Air, Street Games, Winter
Games, and the Full Sports Day (every event, summer then winter); or the
players' own pick, kept in the profile. One set of rules for every player
(EASY: wider beats, a forgiving spring, lower marks to qualify, a lower
first bar, and the hold-and-let-go events let go at the best angle by
themselves, and arch by themselves). What changes is the computer: the age
band button (AGES 5-7, 8-10, 11-13, 14+; inside, the rivals gentle, keen,
fierce, legendary) sets how steady and how quick the computer's athletes
are. A new game starts at AGES 5-7.

The races (100m, hurdles, steeplechase, relay, swim) are run the
old-fashioned way at every age: two RUN buttons close together, tapped one
after the other as fast as you can (the same one twice doesn't count), and
JUMP as ever for hurdles, barriers, water and tags. The hot dog still
bounces to the music; only its speed comes from the tapping
(`Bouncer.bash`): four taps a second is flat out, three is most of the way.
No false starts when bashing. The computer gets quicker with the age band
(a boost to its top speed at 11-13 and 14+).

**The Track & Field way.** Like Konami's game: RUN, RUN for speed or power,
and one action button where timing and the angle decide the result
(`game/aim.gd`).
- Speed and power come from RUN, RUN: the races, the run-ups of the long and
  triple jump, the high jump and the vault, the put's spin-up and the
  bobsleigh's push. Taps while waiting for the go count, so a run-up starts
  with speed in it.
- Take-offs are timed to the line, not the beat: JUMP (or HOP) takes off the
  moment it's pressed, as close to the board (or the high jump's spot) as you
  can. The long and triple jump are measured from the board, so early loses
  distance; past the board is a foul. A circle closes on the hot dog as it
  reaches the line.
- Angles are the player's: holding the action button, a dial beside the hot
  dog shows a needle climbing with the degrees and a green zone round the
  best angle; let go in the green. The needle climbs faster and the green is
  narrower with each age band (45 degrees a second and 10 either side at
  5-7; 105 and 4 at 14+).
- Ages 5-7 get a hand: no fouls (past the board it's measured from the
  take-off), it takes off by itself if the board goes by, it lets go at the
  best angle if they hold on, and it throws the put before time runs out.
- Elsewhere BOUNCE on the beat builds the spring (the dive's board, the ski
  jump's in-run) or is the game (the trampoline, breaking, the skateboard).
  The computer's athletes bounce on the beat everywhere, and take off by
  their own spot near the line.

**The buttons say what they do.** Each button's word changes with what it
does at that moment (`ui/controls.gd`): HOP, SKIP and JUMP in the triple
jump; ARCH over the high jump's bar; THROW in the put; FLIP and TWIST off the
dive board and the trampoline, and STICK to finish; LOW and HIGH for the
bobsleigh's bends (after the push it has two buttons, not three); TUCK,
STEADY and LAND on the ski jump; ROCK and SPIN in breaking; PUSH, OLLIE,
GRIND, FLIP, SPIN and LAND on the skateboard; TAG in the relay and AIR in the
swim. And the button to press next lights up with a pulsing ring: JUMP as the
circle closes, the RUN buttons while a runner is slow, BOUNCE as a landing
comes, the bend's lean, breaking's next move. Phones and a joined tablet get
the same words and lights.

Whenever there's a JUMP to time, a circle shrinks onto the player's hot dog
and meets the dotted ring round it at the moment to press JUMP; where JUMP
is then held (the long jump, triple jump, high jump, vault, the put), a
ring fills while it's held, and the hot dog lets go when it's full.

**LEARN TO PLAY** has a lesson for each thing you do: RUN (the 100m), JUMP
(the hurdles) and JUMP & HOLD (the long jump), each a real event against one
gentle rival with the coach talking all the way (a box under the
scoreboard: GET READY TO TAP RUN!, TAP RUN, RUN, RUN!, WAIT... JUMP WHEN THE
CIRCLE IS SMALL, JUMP NOW!, KEEP HOLDING JUMP!). Doing all three unlocks
the wizard hat and big specs. **LEARN MODE** (on by default, switched on
the same screen) keeps the coach in every event.

Every tablet lags: its speaker plays a little behind the music's clock and
its screen feels a finger a little late. On Android that can be a sixth of
a second, which turns every tap into a miss. The game starts from a guess
(0.12s on Android when the sound system doesn't say) and learns the real
lag from the players' own taps as they play (`game/timing.gd`): each tap's
place on the bounce grid, a circular mean once sixteen of them agree, half
the way there each time. The timing check in Settings still sets it by
hand.

The Games open with a ceremony: every nation's athlete bounces round with its
flag stuck in its bun (no arms to carry it), the players' team last, and the
Mustard Flame is lit. Miss an event's qualifying mark and you lose a bun (♥);
try the event again. Lose all three buns and the Games end. Every event's
scoreboard has its top three on a little podium; medals go on the nations'
table as they're won; at the end, the podium, at dusk, under the floodlights,
with confetti.

Any event can be paused at any point, on its card, mid-go or on its
scoreboard (the II button, Escape, or a phone's back button): the music and
its clock stop where they are and pick up from there, or you leave the event.

### Playing together: a second tablet

PLAY TOGETHER makes this tablet the host. On the other tablet, PLAY
TOGETHER then JOIN A GAME ON ANOTHER TABLET lists the games on the Wi-Fi
(each host sends a beacon every second) and how many play on it (one or
two). If the host isn't listed, there are two more ways in that need no
scanner app: SCAN ITS CODE, which reads the QR code on the host's PLAY
TOGETHER screen with this tablet's camera (`ui/qr_scanner.gd`, with Reggie's
Neon Adventure's reader, `ui/qr_reader.gd`), or type the host's TABLET CODE,
the last number of its address (shown under the QR code: "23" for
192.168.1.23; a whole address works too). It then shows the host's game (`ui/mirror.gd`):

- **The picture**: the game is drawn into a stage (Main's SubViewport) with
  the players' buttons over it, outside, so the host can send the stage
  without them. Each picture (480x270) is packed on a worker thread with
  zstd (about 25KB; pixel art squeezes well) and sent over the WebSocket,
  about 28 a second; a host that's slow to grab them sends fewer, and a
  tablet that falls behind is skipped rather than queued.
- **The music** plays on the joined tablet too, from its own copy of the
  track, at the place the host's is heard (the host says every half second;
  it's nudged back if it drifts more than 45ms). Every sound effect is sent
  along as it plays.
- **Its buttons** come up in events, for its one or two players, drawn over
  the picture; presses go back stamped on the host's clock, like a phone's,
  with the tablet's own timing calibration. Between events (and while
  paused) a tap on the picture is a tap on the host's screen, so either
  tablet works the menus. Back on the joined tablet pauses an event for
  everyone; between events it leaves.

### Playing together, from phones

PLAY TOGETHER (on the title) opens the doors: the game serves a page on the
home Wi-Fi (`ui/remote.gd`, the page is `web/controller.html`) and shows its
address as a QR code (`ui/qr.gd`). A phone that opens it gets two big
buttons, BOUNCE and JUMP, and its own hot dog (the dressing room's, then the
spares: Chilli Dog and Corny Joe), which it can change from the join screen.
The tablet's own buttons can be for 0, 1 or 2 players; phones fill the places
after them, up to four in all.

The phone's header says what's on and whose go it is (it buzzes for yours),
its hot dog bounces on the music's beat, and a grade (PERFECT!, WOBBLE!)
flashes after each press. A phone that drops off the Wi-Fi mid-event keeps
its place and picks up where it was when it comes back.

Rhythm over Wi-Fi: each phone pings the game and keeps the offset from the
quickest round trip, so it knows the game's clock to a few milliseconds.
Every press goes with the moment the finger landed on that clock, and the
game judges it at that moment, however late the message arrives (a stamp
more than 0.35s old means a bad clock and counts as fresh). A phone player's
beats also wait 0.12s longer before counting as missed, so a press still on
its way isn't marked a miss first.

## 5. The nations

`data/nations.json`: USA (Chicago Dog), Germany (Bratwurst in a Brötchen),
Denmark (Rød Pølse), South Korea (Corn Dog, on a stick), Japan (Octopus
Wiener), Great Britain (Banger in a Bap), Australia (Sausage Sizzle in a slice
of bread), Mexico (bacon-wrapped Sonoran Dog), Brazil (Cachorro-Quente with a
crown of potato sticks), France (Le Parisien, in a baguette), Chile (Completo,
avocado hairdo), Czechia (Párek v Rohlíku, popping out of its roll) and
Jamaica (a jerk dog in shades), and the home nations, where the studio is
from: England (a Cumberland in a floury bap), Wales (a Glamorgan sausage,
cheese and leek, with a leek for a plume), Scotland (a square Lorne sausage
in a floury roll), Northern Ireland (an Ulster fry in a soda farl) and
Ireland (a breakfast roll with a fried egg). Every athlete has a silly
sausage name: Frankie Furter, Brat Pitt, Hans Christian Pølsen, Kernel Kim,
Tako Bell, Bangers McMash, Snag Dundee, Bacon Banderas, Hotdoginho, Napoleon
Bunaparte, Guaca Molly, Párek Parker, Usain Bun, Benedict Cumberland,
Glamorgan Freeman, Neeps McTatties, Rory McFry and Saoirse O'Sizzle; a line;
and the events it's best at. The players'
own team is the Night Giraffe Game Cooperative's, unless they pick a nation.

## 6. The dressing room

Front and centre: the title has the players' own hot dogs, big, in the
middle of the stadium, with a DRESS UP! button under them (it says how many
NEW things there are). Tap a hot dog to dress that one.

The dressing room has the hot dog big on the left and, on the right, a tab
for each kind of thing (HATS, OUTFITS, SPECS, FACE, TRAILS, NATION,
SAUSAGE, BUN, TOPPINGS, BAND, STRIPE) with a tile for every choice showing
the hot dog wearing it. Each player (P1 to P4) has their own.

Every part of a hot dog is a separate sprite sheet (sausage, the bun behind,
the bun in front, each topping, the sweatband), so any sausage goes in any bun
with any three toppings. Sweatbands are painted in key colours and swapped for
the team's at run time (`ui/swap.gdshader`). Faces are hand-drawn stamps
(eyes, mouths, brows, shades, moustaches, 80s hair) put on at anchors saved
for every frame. Hats and outfits (`tools/wardrobe.py`) are sheets of their
own, painted on the same 38 frames so they squash, lean and spin with the
hot dog, on a bigger cell (88×104) for tall hats and wide brims; an outfit
can have a part behind the hot dog (a cape, wings, the far side of a tutu).
Trails (sparkles, hearts, stars, bubbles, flames, a rainbow) are left on the
ground behind it as it moves.

**Unlocks.** About seventy silly things (22 hats, 12 outfits, 8 specs, 4
hairdos, 2 moustaches, 6 sausages, 5 buns, 8 colours, 6 trails) are
unlocked by playing (`data/wardrobe.json`, `game/wardrobe.gd`): events
played, medals, golds, perfect bounces, red-hot sizzling runs, Games
finished, world records, playing with a friend, and LEARN TO PLAY. Unlocks
are for everyone on the tablet, not one player. Something unlocks after
nearly every event at first (the first event: heart specs and pigtails), the
scoreboard says NEW TO WEAR!, and new things say NEW in the dressing room
until they've been seen. A locked tile says what unlocks it and how far
along you are (WIN 3 GOLD MEDALS 1/3).

## 7. How it looks and sounds

- **Pixels.** The game draws at 480×270 and scales up by whole numbers
  (`stretch/mode=viewport`, `scale_mode=integer`, `aspect=expand`), so a
  phone or tablet sees a little more, never a blurred pixel. The Night Giraffe
  splash alone is drawn sharp at full resolution.
- **Frames.** Each hot dog sheet holds 38 frames: seven squashes and stretches
  upright, the same leaning into speed, and 24 turns of a full spin, all
  painted fresh by `tools/pix.py` (never a rotated bitmap).
- **Lettering.** One hand-drawn pixel alphabet (`tools/font.py`) in three
  faces: small, big (doubled) and the scoreboard's LED dots.
- **Pictograms.** Every event has one (`tools/icons.py`): a white hot dog
  with eyes and a sweatband, in its bun, doing the sport on a coloured tile.
- **The stadium** tiles sideways for parallax: clouds, the city, the far
  stand's roof and seats with hot-dog fans who bounce on the beat, the ad
  boards, the tartan, the grass. Far lanes sit a little to the right of near
  ones (an oblique view), and so does everything that stands across them.
- **Venues.** The stadium (and its pool version for the swim), the diving
  hall, the gym, a night-time breaking stage, a sunset street, the ski jump
  at night and the bobsleigh run; all drawn in the same palette.
- **Sound.** Taps are music: a perfect bounce is a kalimba note over a
  woodblock (Versilian Community Sample Library, CC0); in breaking and the
  bobsleigh, the two buttons have two different notes, so you can hear the
  pattern. Music is lofi from Pixabay (16 tracks, `tools/fetch_music.py`):
  title, menus, events and ceremony, each a shuffled playlist. Each event
  track's beat is measured from the audio by `tools/make_music.py` (tempo by
  autocorrelation then a fine grid search, phase, the downbeat from the kick
  drum, a drift check, and where the drums come in); an event has one
  track for all its goes, each go starting a bar before a downbeat.

## 8. How it's built

- `game/` the rules, no drawing: `beat.gd` (the grid), `bouncer.gd` (one hot
  dog's bouncing), `rival.gd` (the computer's thumbs), the events (`race.gd`
  for the sprint, hurdles, steeplechase, relay and swim; `jump.gd`, `high.gd`
  (and the vault), `throw.gd`, `dive.gd`, `tramp.gd`, `battle.gd`, `skate.gd`,
  `skijump.gd`, `bob.gd`), `meet.gd` (an event's competition),
  `championship.gd` (the Games), `looks.gd` (the dressing room's choices),
  `catalog.gd` (data), `profile.gd` (autoload: settings, athletes, records).
- `ui/` the screens: `main.gd` (running order, bot, shots), `event_screen.gd`
  (plays any event), the venues (`stadium_view.gd`, `pool_view.gd`,
  `gym_view.gd`, `stage_view.gd`, `street_view.gd`, `snow_view.gd`,
  `sled_view.gd`), `games.gd` (picking a series), `athlete_view.gd`,
  `pad.gd` (buttons and keys), `fx.gd`, `kit.gd` (fonts, buttons, panels),
  `sound.gd` (autoload: music, effects, the song clock), `remote.gd`
  (autoload: the phones' web server and WebSocket, and the host's side of a
  second tablet), `mirror.gd` (the joined tablet's side), `join.gd` (finding
  a game on the Wi-Fi), `qr.gd`, `portrait.gd` (a hot dog's picture for its
  phone), `together.gd` (the join screen), and the menus.
- `web/controller.html` the phones' buttons page (shipped in the APK).
- `tools/` the art, font, sound and music scripts.
- `tests/run_tests.gd` the rules' checks.

The song clock (`Sound.song_time`) follows the playing track's position
(smoothed), so bounces line up with what's heard; each tap is stamped with
the clock the moment it arrives, less the player's calibration (Settings,
timing check).

## 9. Licence

HotDog Sports Day is free software under the GNU General Public License,
version 3: see [LICENSE](LICENSE). You can play it, change it and share it;
if you share a changed copy, share its source too. That covers the code and
everything the scripts in `tools/` make: the art, the lettering and the
sound effects. The sound effects are made from the Versilian Community
Sample Library (CC0). The music is by the artists credited in
`data/music.json`, under the Pixabay Content License, and isn't part of
this repository.
