# Region 1 fun review

Owner: game designer. 2026-10-24, before hard stop B. Build: HEAD d2a2795, 484 tests pass. Read together with the balance rerun (docs/balance/region1-2026-10-24.md) and the QA review (docs/reviews/qa-2026-10-24.md), whose findings are fixed in this build.

How I played: the real app in windows shaped like the Fold5 cover (452 x 1158) and inner screen (906 x 1088), driven by throwaway scripts with a fresh save folder. I played as a first-time player: every card and hint, real taps on spots, sockets and buttons, waves at 1x in real time, the rest fast-forwarded. A headless probe also played the plain mixed recipe at 1x and timed every wave. Sound was off on this machine, so Bart judges sound on the phone. Screenshots are in `%TEMP%\claude\C--Bart-forkline\5e37a376-2998-4ae6-a124-bf563e8b401c\scratchpad\gd_fun\` (shots_cover, shots_inner, burst).

## Verdict

Region 1 is ready for Bart. On the cover screen the loop reads at a glance: a glowing spot, a range ring, the route line, pumpkins in flight and sparkle pops. A gate visibly bends the route line. No number, wave or rule should change before the playtest. One small feedback fix should go in first.

## Issues, most important first

### Before playtest

1. **A creature that gets through leaves no mark on screen.** It vanishes at the home and the heart number drops. Only the sound marks it, and many people play muted. Bart's difficulty notes are the one thing the bots cannot give us, and he needs to see which wave and which creature broke through. Recommendation: on each `leaked` event, a short puff at the home and a heart glyph that floats up from it and fades (no text on the map), plus one pulse of the HUD heart count. Owner: render-engineer (map), ui-engineer (HUD).

### After playtest

2. **Star rules are invisible during play (rerun S2).** Answer: yes, show a third star line as lost once it can no longer be earned. Put it in the Pause menu, which is also where a resumed game opens: the three star lines, each with "Earned", "Not yet" or "Lost". A lost line is struck through and says "Lost", so it never relies on color. The HUD has no room for it on the cover. Also warn before the tap, as the Upgrade button already does: in the build panel for a tower over the limit (a third tower on 1-3), a banned tower or a kind over the limit, and in the gate message for a gate over the limit (1-6: the star is lost when the next wave starts). Owner: ui-engineer. Needs a Battle query for the stars still possible (contract change, through the DM).

3. **The early call button looks like the next step.** From 1-1 on, once a wave has fully arrived the call button turns honey with "+N", the same look as "Start wave". Early calls are taught on 2-1, and a new player can take the bright button for the thing to press, stacking two waves. Recommendation: honey only for "Start wave N" in build phases. The early call keeps the plain look with its "+N" and works the same. Owner: ui-engineer.

4. **"No tower above tier 1." is on 1-1's card before the player has seen a tier.** The tower panel explains tiers on the first tap of a tower, but the card comes first. Recommendation: for `tier_at_most` 1 the sentence becomes "Upgrade no towers." (1-1, 1-2, 1-4). "No tower above tier 2." stays: by 1-5 the player has upgraded on 1-3. Owner: ui-engineer (StarText), the contract 2.7 table (DM), RULES 10.3 (me).

5. **The floating hint covers the fork it teaches.** The hint takes the free map row nearest the glow. On 1-2 that row holds the fork itself, and on 1-3, 1-4 and 1-5 it holds a fork or a join. It closes on a tap or at the first wave, so this is mild. Recommendation: put the hint under the map when it fits there (1-1 to 1-3 leave room on the cover), otherwise on a free row with no fork or join. Owner: ui-engineer, with the contract 7.4 text (DM).

6. **The portrait gate chip has no words.** In portrait the chip shows a gate and the count. The sentences ("Drag one onto a marked road, or tap a marked road.") show only in landscape. On 1-2 the glowing socket plus a tap does the job, so it works today. Recommendation: a tap on the chip shows its sentence in the dock, and 1-2's hint names the tap: "Tap the glowing road to drop your gate there. The line shows their new way." (75 characters). Owners: ui-engineer, level-designer.

7. **The wave preview cannot tell a pack from a trickle.** 1-1's wave 4 shows "Scamp x6" twice: one group spread out, one packed 0.25 s apart. The pack is the Catapult's cue, and the player cannot see it coming. Suggestion for Bart, beyond brief 3.5: mark a group whose gap is 0.4 s or less as "packed" in the preview. Owner: ui-engineer, plus RULES 9.1 (me) and the `wave_preview` rows (contract), only if Bart says yes.

8. **Gold arrives silently.** Kills and the clear bonus only change the gold number. In early waves the clear bonus is about half the income, and nobody sees it paid. Recommendation: a one-line dock message on each clear ("Wave 3 cleared: +35 gold"), and optionally a small coin glint where a creature pops. Owners: ui-engineer, render-engineer.

9. **A loss does not point to Relaxed.** The loss panel is calm and shows progress ("3 of 8 waves cleared."), but a stuck player is never reminded that Relaxed exists. Recommendation: one line on the loss panel, "Stuck? Relaxed gives 40 lives and more gold.", with the numbers from the data. Owner: ui-engineer.

10. **1-3's hint talks about a tower that is not there yet.** "Tap a tower to upgrade it." shows with the glow on an empty spot, and "Spots are few" is not true next to 1-1 (both have 5). Recommendation: "Build on the glow, then tap your tower to upgrade it." Owner: level-designer.

## The questions asked

**First five minutes.** 1-1 teaches building well. Three short cards (Sling Post, Pumpkin Catapult, Scamp) lead to the glow and the hint. A tap on the glow opens the build panel with the Sling Post chosen and its range ring drawn, and Build is one more tap. A new player knows what to do. What confuses: "tier" on the card (4), the honey early call button (3), and that nothing in battle shows the star rules (2). The gate chip works for now (6).

**One idea per level, and the rise.** Each level teaches its idea. 1-1: build, and from wave 4 its packs quietly teach the Catapult (7 would make that visible). 1-2: gates, with the glow on the socket and the line bending to the long road. 1-3: upgrades, through its third star and tough waves; the right socket is a second, hidden lesson (17 against 9 lives). 1-4: splash, against a Pip column that is an obvious target. 1-5: flyers, said three times by the card, the hint and the dotted line. 1-6: tier 3 paths and the boss, two ideas as planned for a boss level. The difficulty is a saw: 1-3 steps up, 1-4 is a breather, 1-5 and 1-6 are the hardest. A breather between the upgrade lesson and the flyers is good pacing, so keep 1-4 as it is.

Change before Bart plays? No. The guided random style places towers and the gate at random, and that is exactly what a thoughtful player does better on 1-5 (spots under the dotted line) and 1-6 (the gate). The plain mixed recipe wins every level at its best gate, and on Relaxed it wins every level with every gate choice. Any change moves the 1-3 margin (14 lives, rerun S1) or a third-star check and costs a full bot pass. The levers are ready if the playtest needs them (rerun S6, S7): 1-4's strength 160 Scamp waves if it is too easy, fewer Pips in the late crowds of 1-5 (waves 7, 9, 10) and 1-6 (waves 6 to 9) if they are too hard.

**Feel.**
- Pacing: most waves last 17 to 30 s at 1x (7 to 41 s in all). The first shot comes 0.1 to 2.5 s into a wave, and no stretch without a shot lasts more than 4 s. Gold comes in small steps, so most build phases hold one purchase. Good.
- Speed at 1x: 5.2 to 6.6 minutes a level. A Scamp walks about 49 dp a second on the cover: calm, right for a cozy first region, with 2x and 3x one tap away.
- Pops: pumpkins arc, pebbles fly, and a sparkle burst lands with the projectile. A Pip crowd turns into a cloud of sparkles. This is the best moment in the build.
- Gold and lives: see 1 and 8.
- Loss: calm, no blame, shows progress. See 9.
- Win: three rows with "New star", "Earned" or "Not earned", then Next level. Clear and quiet. Fine for now.
- The Upgrade warning: "Loses the third star." with an empty star, right above the Upgrade button on the levels that cap the tier, and above the path cards on 1-5. It reads right, and it goes away once the star is already lost. Keep it.

**S2.** Yes, as in 2.

## Watch in Bart's playtest

- **1-1 for a Catapult-first player.** Catapults alone lose 1-1 in wave 4 on Normal (all four Catapult recipes) and win on Relaxed with 30 lives. The build panel opens on the Sling Post, which steers new players right. If Catapult-first players lose 1-1, test more starting gold with the bots first, so a second tower stands before wave 2. Catapult-only builds are 3 lives short of the third star there (best 12 of the 15 needed), so any easing needs the single-tower check again.
- **"Start wave 1" before any tower.** The four Scamps of wave 1 get through: 4 lives. Star 2 survives it with one life to spare.
- **1-6's "Use no gates."** It may lead a first-timer to leave the gate in hand, while the plain mixed recipe needs the gate to beat the boss (with no gate it loses in wave 10). Watch whether first tries die at the boss with no gate placed.
- **Players who never upgrade.** They win 1-6 only 6% of the time even on Relaxed (random play). The 1-3 and 1-6 hints teach upgrades. Watch whether anyone gets stuck there.
- **The gate chip in portrait.** Does Bart find how to move and take back a gate without the landscape sentences?
- **Sound.** Not judged here.
