# Slowblue — the editorial checklist, measured

**Status: a self-audit, not a submission.** This is the game checked against what the
App Store's Today tab and Google Play's Editors' Choice actually ask for, one line at a
time, with the number this repo can put behind each one and the name of the thing that
measured it. Slowblue was called TIDE when most of these numbers were taken. It is a
web game now (an installable PWA; see [CLAUDE.md](../CLAUDE.md)), nothing here has been
shown to either store, and no store binary exists.

**Since then:** the settings screen, its COMFORT switches (high contrast, reduced motion,
deep calm) and the sound card on first launch were withdrawn, and the game ships in
English only. Rows that were measured with any of those in the build say so inline and
are marked `unmeasured since`: the number is kept as the record of what was true, and no
row pretends it is a reading of today's build. Browser readings that are not marked were
not re-taken in the last documentation pass either; the file paths, test names and
structural claims were checked against the tree. The e2e specs are the instruments that
re-take the numbers, and [README.md](../README.md) describes what the controls are now.

Two rules for reading it. **A line with no measurement behind it says so** — a
verdict here is either a number, a file, or the word `unmeasured`, and there is no
fourth kind. And **the gaps are at the top of their section rather than the
bottom**, because a checklist whose failures are filed under "notes" is a
marketing document.

The numbers are from headless Chromium on one laptop against the production build.
They are a baseline the next change is compared against, not a phone.

---

## 0. What is not here

**There is no store binary.** The Capacitor/iOS shell that was built in August has been
removed, and TWA packaging was never in scope (see "Decided" in [CLAUDE.md](../CLAUDE.md):
the web is the only target), so nothing below has been through App Store Connect or the
Play Console. This is a checklist of what the build *would carry into* one, measured on
the build that exists.

**There is no monetisation.** No ads, no IAP, no rewarded video, no subscription,
no consent flow, no ad SDK. Both stores ask about all of it; the answer to every
one of those questions is that the code is not there to answer with.

---

## 1. Open — measured, not fixed

| # | what | number | where |
| - | ---- | ------ | ----- |
| 1.1 | **35 of 65 live controls are under Google's 48dp** (counted before the comfort screen and sound card left the walk; `unmeasured since`). All of them clear Apple's 44pt, and all of them clear it by exactly nothing: every control in the shell sizes off one stylesheet variable, `--reach`, and that variable is 44. | 35/65 under 48; smallest live control 44×44 | `[shell reach48]` in `e2e/chrome.spec.ts` |
| 1.2 | ...and what raising it costs, which is the only reason it is still open — but it is no longer the reason it was. The layout objection is gone: the circuit screen's BEGIN is pinned to the bottom of its scrollport now (§4), so 48 does not move it by a pixel. What is left is that the same rule puts four more pixels of the second toggle under that button, and that eight pixels of column have to come from somewhere on a screen that already overflows. | primary 776..824 at both 44 and 48; second toggle 17.3px exposed at 44, 13.3 at 48; column 1031 to 1039 | `[reach]`, measured, not committed |
| 1.3 | **No screen-reader pass.** The shell is real DOM buttons with `aria-*` attributes on them and `documentElement.lang` is set (to English, the only language the game runs in), so it has a chance; nothing has ever put VoiceOver or TalkBack on it. The game itself is a canvas and is not readable by either, which is a property of the genre rather than a defect to fix. | `unmeasured` | — |
| 1.4 | **No app preview video.** The documentation frames in `docs/screens/` exist and regenerate from the build (`npm run screens`); a trailer does not, and cannot be made by this repo. | — | `docs/screens/` |

---

## 2. Getting in — the part an editor actually experiences

| what is asked | verdict | number | where |
| ------------- | ------- | ------ | ----- |
| Playable in seconds, no download gate | **ok** | cold 34 ms to a title screen and 328 ms to moving fish; warm 20 ms and 277 ms, against a 3 s budget. The pressing of the button is 36 ms of that cold and 16 warm — the rest is a person reading a screen. | `e2e/measure.spec.ts` `startup` |
| ...and what is in front of that, stated rather than hidden | **by decision** | the studio ident is outside the budget on purpose and one tap from over; the spec asserts it plays out its 7.1 s. The 11 089 ms recorded here once included the sound card, which has since been withdrawn, so today's figure is `unmeasured since` | `startup first launch` in `e2e/measure.spec.ts` |
| No account, no sign-in, no email | **ok** | there is no network code in `src/` at all: zero `fetch`, zero `XMLHttpRequest`, zero `sendBeacon`, zero `WebSocket` | grep (re-run for this audit: no matches in `src/`), and `e2e/measure.spec.ts` `offline` |
| No tutorial, no forced walkthrough | **ok** | the ask is on the glass at 0.3 s, the first ring goes in at 8.3-10.9 s, the first section is cleared at 9.9-12.3 s, and the first station hands over at 65.5-70.5 s | `tools/onboarding.sweep.ts`, guarded by `tests/onboarding.test.ts` |
| ...and a player who has not worked out the control yet is still taught | **ok** | touching nothing: a ring absorbed at 13.6 s, a section cleared at 15.6 s, the multiplier moved, and the run lasts 33 s before the medium leaves them behind | same |
| One idle hint, then never again | **ok** | raised after 2 s of no input, dropped on the first touch, latched off for the session | `e2e/runtime.spec.ts` |
| Works with no signal | **ok** | a cold install with the network off launches and flies; the worker precaches the build's own asset list | `e2e/measure.spec.ts` `offline` |
| Installable | **ok** | web manifest, fullscreen, portrait, maskable icon, offline worker | `public/manifest.webmanifest`, `public/sw.js`, `e2e/smoke.spec.ts` |

## 3. Craft — the part they film

| what is asked | verdict | number | where |
| ------------- | ------- | ------- | ----- |
| Holds a frame rate | **ok** | measured with hunters and standing currents up, not on an opening frame | `e2e/runtime.spec.ts` |
| Simulation independent of the display | **ok** | fixed timestep with an accumulator, checked at 30-144 Hz: never more than one step of drift, the catch-up cap never engages | `tests/promotion.test.ts` |
| No stutter from collection | **ok** | 37 B/frame on an opening frame, 109 on the heaviest, ~6 KB/s at worst — about one minor GC a minute; held by a 400 B/frame ceiling in e2e and a unit test | `e2e/measure.spec.ts` `allocation`, `tests/allocation.test.ts` |
| Sharp on retina | **ok** | `clamp(dpr, 1, 2)` against a measured frame budget; native 3× would be 31.6 ms/frame | `e2e/measure.spec.ts` `pixels` |
| Sound that is built rather than bolted on | **ok** | decoded buffers and ramped `AudioParam`s throughout; the one looping buffer's seam measures 0.84× a normal sample-to-sample step, and every tuned voice over half a second is on the scale (0.2 cents mean, from 31) | `tests/loops.test.ts`, `tests/audioengine.test.ts` |
| Audio unlocks on first touch, and comes back after an interruption | **ok** | voices reaching the mixer are counted from outside: silent cold, loud after a tap, back when the player is | `e2e/unlock.spec.ts` |
| Every event answers on both channels | **ok** | picture and sound measured per event against a 0.82× null reading | `e2e/response.spec.ts` |
| The picture is looked at, not assumed | **ok** | all 42 stations shot at their opening and late images, and all 7 endings per movement. (There used to be a high-contrast pass as well; the setting it exercised is gone.) | `e2e/acts.spec.ts`, which writes the frames to `docs/screens/acts/` (git-ignored) |

## 4. Interface — the part they screenshot

| what is asked | verdict | number | where |
| ------------- | ------- | ------- | ----- |
| Text that can be read | **ok** | 120 text runs on the glass across ten shell states, 0 below WCAG AA (`unmeasured since` the comfort screen and sound card left the walk; the gate is still 0 below AA) | `e2e/chrome.spec.ts` |
| ...with the exception stated | **by decision** | one tier, `--unlit` at 2.13:1: an act nobody has reached is drawn as an absence on purpose, and is printed every run rather than exempted quietly | same |
| Controls a thumb can find | **ok on Apple, open on Google** | 65 live controls, 0 below 44; 35 below 48 (`unmeasured since`; the 44 floor is still a gate). See §1.1 | same |
| The thing to press is where the player can see it | **ok** | 32 primaries — 8 screens on 4 glasses, from a 375×667 to a landscape 844×390 — 0 past the fold, tightest 20px to spare. The comfort screen has been withdrawn since, so the spec now walks 7 screens (at least 28 primaries) and the 32 is `unmeasured since`; the 0-past-the-fold gate stands. It was 23.7px past on the map at 390×844 and 123.4px past at 375×667 before the map's primary was pinned to its scrollport | `e2e/chrome.spec.ts` `[shell fold]` |
| ...and what pinning it costs, stated | **by decision** | one control overlapped at rest: the second mode toggle, 17.3px of 44 still exposed, whole again after 30px of scroll; 0 controls covered completely, and 7 text runs behind the button printed rather than counted as unreadable | `[shell under-pin]`, `[shell covered]` |
| Nothing under the notch | **ok** | five window geometries (a Dynamic Island, two notches, an Android navigation bar, and none), both the shell and the run | `e2e/safearea.spec.ts` |
| The page never scrolls or bounces under the game | **ok** | `touch-action` on the canvas rather than the body — deliberately, because on the ancestor chain it killed scrolling in the shell | `e2e/smoke.spec.ts` |
| Layers that do not collide | **ok** | the canvas readout column starts below the corner buttons standing over it, checked as rectangles rather than pixels | `e2e/chrome.spec.ts`, `HUD_COLUMN_TOP` |
| A hierarchy rather than a palette | **ok** | 7 ink tiers and 11 type sizes across the whole shell, from 36 and 15 (`unmeasured since`; the gates are at most 8 and 12) | `e2e/chrome.spec.ts` |
| Localised | **no** | English only at runtime: there is no language picker, and `resolveLang` returns English whatever is stored. So the row is a no, not an ok | `src/i18n/strings.ts` |

## 5. Mindful gaming — Apple's own section, and the one this game is for

| what is asked | verdict | evidence |
| ------------- | ------- | -------- |
| Nothing manipulative in the loop | **ok** | no ads, no IAP, no energy, no daily reward, no streak that costs anything outside the run |
| No notifications | **ok** | there is no notification code, because there is no network code |
| Nothing is uploaded | **ok** | telemetry exists and is local: the export writes JSON into the page and nowhere else |
| The player can stop | **ok** | pause from any run, one tap; the water is held while the mixer drawer is open, deliberately, so setting a level costs nothing (`e2e/smoke.spec.ts`, "the in-game mixer holds the water") |
| A quieter way to play, that is not a difficulty | **withdrawn** | there was a comfort screen with reduced motion, high contrast and deep calm, and it was removed along with the settings screen it sat on (README, "Where the controls are"). Nothing replaces it: the game now has no accessibility switches, which is a gap an editor would find, and it belongs in §1 if it is ever to be fixed |
| Sound the player owns | **ok** | per-bus faders and a mute that is one tap from every screen |
| Failure that does not end the journey | **by design** | in every act a lost station begins again, for time and score, and once an act attempt has spent its restarts (two in act I and three in each of the other six, from `restartsForMinutes` in `src/sim/Failure.ts`) the next failure ends that attempt and begins the act again; it never ends the campaign, and the last three stations of act VII cannot be lost at all. The earlier rule here, that acts I and II were harsher and act IV could not fail, was superseded by that one |
| Something to arrive at | **ok** | 42 hand-built stations in a closed circuit that returns to the frame it opened on |

## 6. Content and originality

| what is asked | verdict | evidence |
| ------------- | ------- | -------- |
| A sentence a stranger can repeat | **ok** | *you do not control the fish, you control the ocean* — one gesture, seven media, from the first frame to the last |
| Not a reskin of a known loop | **ok** | the whole simulation is `acc += (mediumVelocity - velocity) * coupling`, and every act is that one line with a different medium in it |
| Enough of it | **ok** | 7 acts, 42 stations, 432 sections and 144 authored minutes ([DESIGN-LENGTH.md](DESIGN-LENGTH.md) §11), and an obstacle alphabet of its own per act (`SectionArchetype` in `src/sim/ObstacleSystem.ts`) |
| Made rather than generated | **ok** | every level is a hand-written list of sections, and a flood fill proves each one has a route through it |

---

## What to measure next

Nothing in §2-§6 was ever left unmeasured, but several readings predate the comfort and
sound-card removals and say `unmeasured since`: one `SLOWBLUE_E2E_PORT=4271 npm run e2e`
re-takes the shell numbers. After that, the next number this file wants is one of §1's.

**1.1 and 1.2 together**, and they are cheaper than they were: the layout decision
that blocked them — that 48 takes the map's primary off the fold — was measured
again after §4's pinning rule and it is no longer true. One variable, eight pixels
of column to find on one screen, and the shell clears both stores rather than one.
