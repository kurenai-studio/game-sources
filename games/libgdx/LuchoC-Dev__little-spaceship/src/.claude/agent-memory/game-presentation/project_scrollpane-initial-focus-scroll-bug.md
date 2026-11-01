---
name: scrollpane-initial-focus-scroll-bug
description: Wrapping MenuEntries/MenuNavigator's entry list in a ScrollPane needs a validate() before the navigator's constructor and an explicit setScrollY(0f) after, or the screen opens scrolled to the bottom
metadata:
  type: project
---

Fixed for #276 (TESTS submenu, nine entries overflowing 480x270). `MenuNavigator`'s constructor
calls `entries.get(0).setFocused(true)` immediately, before the stage has ever run a layout pass. If
gaining focus is wired to also call `scrollPane.scrollTo(button.getX(), button.getY(), w, h)` (the
natural way to keep keyboard navigation visible inside a scrolled list), that first call runs
against a button whose `getX()`/`getY()` are still `(0, 0)` — no layout has happened yet to give it
real coordinates.

The failure is not a no-op, which is the tempting assumption. `scrollTo` treats `(0, 0)` as a real
rectangle to bring into view, and in this coordinate system y grows upward, so `y = 0` is the
*bottom* of the entries table (the last row, here BACK), not "no scroll". The screen opens scrolled
to the last few entries instead of the first — confirmed on a real desktop launch, screenshotted
before and after the fix (see the status fragment for #276 for both screenshots' content).

Fix, both parts required:
1. `content.validate()` (or the equivalent for whatever `Table` holds the `ScrollPane`) right before
   constructing `MenuNavigator`, so the first focus-triggered `scrollTo` call runs against real,
   laid-out coordinates.
2. `scrollPane.setScrollY(0f)` immediately after constructing `MenuNavigator`, as a second,
   independent guarantee. `validate()` alone was not quite enough in practice — the very first
   screenshot after adding just `validate()` still showed the first entry one row above the fold,
   likely `scrollTo`'s own "minimum distance to make the rectangle visible" logic not landing
   exactly at the top edge. Setting `scrollY` directly for the one-time "screen just opened" case
   sidesteps that rounding entirely.

Both `scrollTo` calls made afterwards (real keyboard navigation, once the render loop has run at
least one frame) work correctly with no extra care — by the time a keypress can reach
`MenuNavigator`, the stage has already drawn once and every button has real coordinates. The bug is
specific to the *very first* `setFocused(true)` call, which happens synchronously inside the
navigator's own constructor, before any frame has ever rendered.
