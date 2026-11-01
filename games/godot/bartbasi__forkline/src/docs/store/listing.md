# Forkline Play Store listing (draft)

Text for the Google Play listing, ready to paste into Play Console. Google's limits are in brackets. Graphics are in docs/store/graphics/. Nothing here has been entered in Play Console yet. Bart reviews and decides everything marked "Bart decides".

The character counts below are checked by `bash tools/store/check_store.sh`, which fails if a count is wrong, a limit is passed, or the text has a character outside plain ASCII (no em dashes, no curly quotes).

## App name (30 characters at most)

```
Forkline: Tower Defense
```

Characters: 23 of 30.

## Short description (80 characters at most)

```
Tower defense where the roads fork. Place gates to steer the creatures.
```

Characters: 71 of 80.

## Full description (4,000 characters at most)

```
Forkline is a tower defense game for Android phones. Night creatures come down the roads of a hillside village toward your home. The roads fork. You build towers beside them, and you place gates that close one branch and send the creatures down another. Solve each map like a puzzle, then watch it play out.

HOW IT PLAYS
Each level has a build phase and then waves of creatures. In the build phase you place and upgrade towers, place gates, and see the route the next wave will take. A line on the map shows it, and a preview shows what is coming. Then you start the wave and watch your defense work. You can pause at any time, play at 2x or 3x, and call the next wave early for a bonus.

SIX TOWERS
Sling Post: quick hits on one target.
Pumpkin Catapult: splash damage on crowds of walkers.
Lullaby Bell: slows walkers in its ring.
Longbow Loft: long range arrows that ignore armor.
Firework Tower: hits flyers.
Bakery: helps the towers around it attack faster.
Towers upgrade, and at the top tier each one picks one of two paths.

NIGHT CREATURES
Scamps, crowds of Pips, fast Skitters, flying Flitters, armored Shellbacks, Bubblers whose bubbles block a hit, Puffballs that split, Menders that heal, and Gatecrashers that break your gates. Each region ends with a boss. When a creature is beaten it puffs into sparkles. There is no blood.

CAMPAIGN
24 levels in four regions: Lantern Hill, Millbrook, Willow Fen and Moonspire Keep. Every level teaches one idea. Each has three stars to earn: win the level, keep 15 lives, and meet a challenge that changes from level to level. Three stars on a level open its Twist, the same map with one rule changed.

ROGUELITE RUNS
One run is 18 waves on a map built from pieces. After each wave you pick a card: new towers, tower perks or risks that pay more. A run takes about 15 to 20 minutes.

DAILY CHALLENGE
One run a day, the same for everyone on the same date. Your best result and your streak stay on your phone.

Roguelite runs and the daily challenge open once you have earned 12 stars in the campaign.

RELAXED DIFFICULTY
Stuck? Pick Relaxed before a level or run for more lives and more starting gold. Nothing else changes. A Relaxed win earns one star, and the daily challenge is always Normal.

MADE FOR PHONES AND FOLDABLES
Forkline plays in portrait. On a foldable's inner screen it switches to a landscape layout on its own. Your game is saved the moment you leave and picks up exactly where you left off.

FREE, PRIVATE AND OFFLINE: free, and it always will be. No ads, no in-app purchases, no accounts and no tracking. Works fully offline, asks for no permissions, collects no data.
Forkline is free software under the GNU GPL version 3. The source code is at github.com/bartbasi/forkline.
```

Characters: 2748 of 4000.

## Category and tags (up to five)

- App or game: Game.
- Category: Strategy.
- Tags: pick from Play Console's own list when the listing is created. Good fits are Tower defense, Strategy, Offline, Casual and Puzzle, if they are on offer. Bart decides.

## Contact details

- Email (shown publicly): bartbasi@gmail.com
- Website: https://github.com/bartbasi/forkline
- Privacy policy URL: https://bartbasi.github.io/forkline/privacy-policy/

The website and privacy policy addresses work only after the repo is public and GitHub Pages is on. Both need Bart's go ahead first (hard stop C, and Pages is ask first).

## What's new (500 characters at most)

```
First release.
```

Characters: 14 of 500.

## Graphics

All made by code. Rerun the tools to change them (see docs/release.md).

| Play Console slot | File | Size |
|---|---|---|
| App icon | docs/store/graphics/icon_512.png | 512 x 512 |
| Feature graphic | docs/store/graphics/feature_1024x500.png | 1024 x 500 |
| Phone screenshot 1 | docs/store/graphics/screen_4_build_phase.png | 1080 x 2160 |
| Phone screenshot 2 | docs/store/graphics/screen_5_wave.png | 1080 x 2160 |
| Phone screenshot 3 | docs/store/graphics/screen_3_levels.png | 1080 x 2160 |
| Phone screenshot 4 | docs/store/graphics/screen_2_modes.png | 1080 x 2160 |
| Phone screenshot 5 | docs/store/graphics/screen_1_front_door.png | 1080 x 2160 |

The order puts the fork and the gate first, because that is what is new: the build phase with its route line (steer them with gates), the wave (watch it play out), the campaign (24 levels, three stars each), the mode screen (campaign, roguelite and daily), and the front door.

The screenshots are the real app, run in a window at phone size with its real data and the sound off. The gold on the build and wave screens was topped up so the picture shows a full defense. Screenshot 5 shows the Buy me a coffee row on the front door. Bart decided on 2026-10-27 to keep it there (see the known risk below). The build picture (slot 1) is level 1-2, The Fork, before wave 5. The wave picture (slot 2) is level 3-2, Puffball Pond, in wave 6, with five tower kinds built. It is the best frame of the wave, picked by the tool: creatures spread along the road, a Pumpkin Catapult shot with its dashed splash ring, at least two other kinds of shot in the air, and sparkles from beaten creatures.

Phone screenshots are 1080 x 2160, the tallest shape Play accepts (twice as tall as wide). The app has no separate tablet layout beyond its landscape layout, so no tablet screenshots are listed. If Play Console asks for large screen screenshots, take them on the Fold5's inner screen (see docs/release.md).

## Play Console answers

- Data safety: collects or shares no data. Encryption in transit and deletion requests: not applicable. The coffee, source and feedback buttons only hand an address to another app, so this stays "No data collected".
- Ads: no. App access: everything is available without a login. In-app purchases: none.
- Users can talk to each other: no. Location: none. Permissions: none. The APK requests no permissions at all (checked by scripts/check_apk.sh).
- Target audience: 13 and over. This keeps Google's Families policy and its payment link rules out.
- Government, financial, health, news: no.
- Content rating: answer the questionnaire as written in the notes below. Bart decided on 2026-10-27: mild fantasy violence.

### Content rating notes

Bart decided on 2026-10-27 to answer with mild fantasy violence. The answer must match what the game shows, and this does.

- The violence question: yes, mild fantasy violence. Cartoon creatures are hit by towers (arrows, pebbles, pumpkins, fireworks) and puff into sparkles. There is no blood, no gore, no injury, no dead bodies, no realistic people and no violence against people or animals that look real.
- Everything else: no. No sexual content, no nudity, no strong language, no drugs, alcohol or tobacco, no gambling or simulated gambling, no real money, no horror, no user generated content, no way for players to talk to each other, no sharing of location.
- Digital purchases: none. The app has no ads and no in-app purchases.
- Expected result: a low rating that allows a 13 and over audience. Most likely Everyone 10+ in the ESRB, PEGI 7, USK 6 and IARC Generic 7+. Everyone and PEGI 3 are possible if the questionnaire treats the creatures as too mild to count, but do not count on it. Whatever Play Console shows is what stands. Record the actual result here after the questionnaire is done.
- If the result is higher than expected (for example Teen), stop and ask Bart before accepting it. Check that each answer matches the list above first.

## Known risk: the Buy me a coffee button

Google Play's payments policy only allows in-app donation links to tax exempt charities outside the US. Bart accepted that risk for every Play, Inc. app on 2026-10-17. The full description above does not mention the button. If review rejects the app for it, pull the button quickly. It lives in:

- src/ui/links.gd: the address constant `COFFEE_URL` and `open_coffee()`.
- src/ui/coffee_button.gd: the button itself.
- src/ui/front_door.gd: the row at the bottom of the front door.
- src/ui/about_screen.gd: the "Supporting Forkline" section.
- src/ui/pause_panel.gd: the quiet row in Pause.
- README.md: the Support section.
- docs/store/privacy-policy.md: the Buy me a coffee line.
- Screenshot 5 (screen_1_front_door.png) shows the front door's row, so retake the screenshots with `tools/store/make_screenshots.gd` after the button is gone.

Those files belong to other agents, so the DM makes the change.

## Not in the listing

No other app's or game's name. The listing describes Forkline in its own words.
