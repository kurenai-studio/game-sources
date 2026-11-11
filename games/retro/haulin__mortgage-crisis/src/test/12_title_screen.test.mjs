import test from "node:test";
import assert from "node:assert/strict";
import { loadSrcIntoVm } from "./helpers/loadSrcIntoVm.mjs";

test("title: draws and selecting New Game enters Render", async () => {
  const printed = [];

  let frame = 0;
  const ctx = await loadSrcIntoVm({
    extraGlobals: {
      // Capture print calls for a basic smoke check.
      print: (s) => {
        printed.push(String(s));
      },
      // Simulate an A tap (press then release).
      btn: (i) => {
        if (i !== 4) return false;
        return frame === 1;
      },
      btnp: (i) => {
        if (i !== 4) return false;
        return frame === 1;
      }
    }
  });

  // Boot should start in Title mode.
  assert.equal(ctx.MC._mainMode, 2);

  // First tick: should draw title (at least some expected strings).
  ctx.MC.mainTick();
  assert.ok(printed.some((s) => s.includes("MORTGAGE")), "expected title to print MORTGAGE");
  assert.ok(printed.some((s) => s.includes("New Game")), "expected title to print New Game");

  // Two-tick A tap: press then release should select New Game and enter Render (mode 1).
  frame = 1;
  ctx.MC.mainTick();
  frame = 2;
  ctx.MC.mainTick();
  assert.equal(ctx.MC._mainMode, 1);
});

test("title: marketing capture mode hides Title chrome", async () => {
  const printed = [];
  const ctx = await loadSrcIntoVm({
    extraGlobals: {
      print: (s) => {
        printed.push(String(s));
      }
    }
  });

  ctx.MC.config.title.marketingCaptureMode = true;

  ctx.MC.mainTick();
  assert.ok(printed.some((s) => s.includes("MORTGAGE")), "expected title to print MORTGAGE");

  // Chrome that should not appear in capture mode.
  assert.ok(!printed.some((s) => s.includes("New Game")), "expected menu to be hidden");
  assert.ok(!printed.some((s) => s.includes("Controls")), "expected controls table to be hidden");
  assert.ok(!printed.some((s) => s.includes(ctx.MC.config.title.subtitleText)), "expected subtitle to be hidden");
  assert.ok(!printed.some((s) => s.includes(ctx.MC.config.meta.version)), "expected version to be hidden");
});

test("title: mouse click outside menu does not activate last-hovered item", async () => {
  let frame = 0;
  let x = 0;
  let y = 0;
  let left = false;

  const ctx = await loadSrcIntoVm({
    extraGlobals: {
      mouse: () => [x, y, left, false, false, 0, 0]
    }
  });

  assert.equal(ctx.MC._mainMode, 2, "expected to boot into Title mode");

  const cfg = ctx.MC.config;
  const tc = cfg.title;
  const menuW = tc.menuW;
  const leftW = cfg.screenW - menuW;
  const xBox = leftW + 2;
  const my0 = tc.menuY;
  const padY = tc.menuItemBoxPadY;
  const hoverX = xBox + 2;
  const hoverY = my0 - padY + 2;

  // Frame 0: draw (mouse outside).
  frame = 0; x = 0; y = 0; left = false; ctx.MC.mainTick();

  // Frame 1: hover New Game.
  frame = 1; x = hoverX; y = hoverY; left = false; ctx.MC.mainTick();

  // Frame 2: move outside (no selection).
  frame = 2; x = 0; y = 0; left = false; ctx.MC.mainTick();

  // Frame 3/4: click outside (press then release) should do nothing.
  frame = 3; x = 0; y = 0; left = true; ctx.MC.mainTick();
  frame = 4; x = 0; y = 0; left = false; ctx.MC.mainTick();

  assert.equal(ctx.MC._mainMode, 2, "expected to remain in Title mode");
});

test("title: selecting disabled Continue shows an error toast", async () => {
  let frame = 0;
  const ctx = await loadSrcIntoVm({
    extraGlobals: {
      btn: (i) => {
        // Hold Down on frame 1.
        if (i === 1) return frame === 1;
        // Hold A only on frame 3.
        if (i === 4) return frame === 3;
        return false;
      },
      btnp: (i) => {
        // Frame 1: press Down to select Continue.
        if (frame === 1 && i === 1) return true;
        // Frame 3: A press pulse (tap completes on release at frame 4).
        if (frame === 3 && i === 4) return true;
        return false;
      }
    }
  });

  // Boot should start in Title mode.
  assert.equal(ctx.MC._mainMode, 2);

  // Frame 0: draw.
  frame = 0;
  ctx.MC.mainTick();

  // Frame 1: Down (select Continue).
  frame = 1;
  ctx.MC.mainTick();

  // Frame 2: idle.
  frame = 2;
  ctx.MC.mainTick();

  // Frame 3: press A.
  frame = 3;
  ctx.MC.mainTick();

  // Frame 4: release A (tap resolves here).
  frame = 4;
  ctx.MC.mainTick();

  const tv = ctx.MC.title.toastView;
  assert.ok(tv && Array.isArray(tv.toasts), "expected title.toastView.toasts");
  assert.ok(tv.toasts.length >= 1, "expected at least one toast");
  assert.equal(tv.toasts[0].kind, "error");
  assert.ok(String(tv.toasts[0].text || "").includes("No game to continue"));
  assert.equal(tv.toasts[0].frames, ctx.MC.config.ui.toast.errorFrames);
});

test("title: toasts stack by message text (dedupe identical)", async () => {
  let frame = 0;
  const ctx = await loadSrcIntoVm({
    extraGlobals: {
      btn: (i) => {
        // Down on frames 1, 5, 7, 9.
        if (i === 1) return frame === 1 || frame === 5 || frame === 7 || frame === 9;
        // Up on frames 13, 15, 17.
        if (i === 0) return frame === 13 || frame === 15 || frame === 17;
        // A press on frames 3, 11, 19 (release happens on the following frames).
        if (i === 4) return frame === 3 || frame === 11 || frame === 19;
        return false;
      },
      btnp: (i) => {
        // Press pulses for Down/Up.
        if (i === 1 && (frame === 1 || frame === 5 || frame === 7 || frame === 9)) return true;
        if (i === 0 && (frame === 13 || frame === 15 || frame === 17)) return true;
        // A press pulse.
        if (i === 4 && (frame === 3 || frame === 11 || frame === 19)) return true;
        return false;
      }
    }
  });

  assert.equal(ctx.MC._mainMode, 2);
  ctx.MC.config.debug.enabled = true;

  // Frame 0: draw.
  frame = 0; ctx.MC.mainTick();
  // Frame 1: Down -> Continue.
  frame = 1; ctx.MC.mainTick();
  // Frame 2: idle.
  frame = 2; ctx.MC.mainTick();
  // Frame 3/4: A tap on disabled Continue -> toast "No game to continue".
  frame = 3; ctx.MC.mainTick();
  frame = 4; ctx.MC.mainTick();

  // Frame 5: Down -> How to Play.
  frame = 5; ctx.MC.mainTick();
  // Frame 6: idle.
  frame = 6; ctx.MC.mainTick();
  // Frame 7: Down -> About.
  frame = 7; ctx.MC.mainTick();
  // Frame 8: idle.
  frame = 8; ctx.MC.mainTick();
  // Frame 9: Down -> Dev toggle.
  frame = 9; ctx.MC.mainTick();
  // Frame 10: idle.
  frame = 10; ctx.MC.mainTick();
  // Frame 11/12: A tap on Dev toggle -> toast "Dev tools enabled" (info).
  frame = 11; ctx.MC.mainTick();
  frame = 12; ctx.MC.mainTick();

  const tv = ctx.MC.title.toastView;
  assert.ok(tv && Array.isArray(tv.toasts), "expected title.toastView.toasts");
  assert.equal(tv.toasts.length, 2, "expected two stacked toasts");
  assert.ok(tv.toasts.some((t) => String(t.text || "").includes("No game to continue")));
  assert.ok(tv.toasts.some((t) => String(t.text || "").includes("Dev tools enabled")));

  // Repeat the Continue error: should dedupe by message text id (not add a third toast).
  // Frame 13: Up -> About.
  frame = 13; ctx.MC.mainTick();
  // Frame 14: idle.
  frame = 14; ctx.MC.mainTick();
  // Frame 15: Up -> How to Play.
  frame = 15; ctx.MC.mainTick();
  // Frame 16: idle.
  frame = 16; ctx.MC.mainTick();
  // Frame 17: Up -> Continue.
  frame = 17; ctx.MC.mainTick();
  // Frame 18: idle.
  frame = 18; ctx.MC.mainTick();
  // Frame 19/20: A tap on disabled Continue again.
  frame = 19; ctx.MC.mainTick();
  frame = 20; ctx.MC.mainTick();

  assert.equal(tv.toasts.length, 2, "expected identical toast to dedupe (still 2)");
});

test("title: New Game prompts overwrite confirm when session exists (B cancels)", async () => {
  let frame = 0;
  const ctx = await loadSrcIntoVm({
    extraGlobals: {
      btn: (i) => {
        // A down only on frame 1 (release at frame 2 triggers tap).
        if (i === 4) return frame === 1;
        return false;
      },
      btnp: (i) => {
        // A press pulse on frame 1.
        if (i === 4 && frame === 1) return true;
        // B press cancels on frame 3.
        if (i === 5 && frame === 3) return true;
        return false;
      }
    }
  });

  // Create an in-memory session without leaving Title mode.
  ctx.MC.debug.startNewGame();
  const prevState = ctx.MC.debug.state;
  assert.ok(prevState, "expected debug.state session");

  // Frame 0: draw.
  frame = 0; ctx.MC.mainTick();
  // Frame 1/2: A tap on New Game should enter confirm (not start immediately).
  frame = 1; ctx.MC.mainTick();
  frame = 2; ctx.MC.mainTick();

  assert.equal(ctx.MC._mainMode, 2, "expected to remain in Title mode");
  assert.equal(ctx.MC.debug.state, prevState, "expected session to remain until confirmed");
  const tv = ctx.MC.title.toastView;
  assert.ok(tv && Array.isArray(tv.toasts), "expected title.toastView.toasts");
  assert.ok(tv.toasts.length >= 1, "expected confirm toast");
  assert.ok(tv.toasts.some((t) => t && t.persistent), "expected persistent confirm toast");
  assert.ok(tv.toasts.some((t) => String(t.text || "").includes("Overwrite current game?")));

  // Frame 3: B cancels and returns to the menu (toast cleared).
  frame = 3; ctx.MC.mainTick();
  assert.equal(ctx.MC._mainMode, 2, "expected to remain in Title mode after cancel");
  assert.equal(ctx.MC.debug.state, prevState, "expected session to remain after cancel");
  assert.equal(tv.toasts.length, 0, "expected confirm toast cleared on cancel");
});

test("title: New Game overwrite confirm starts new game on A", async () => {
  let frame = 0;
  const ctx = await loadSrcIntoVm({
    extraGlobals: {
      btn: (i) => {
        // Two A taps: press on frames 1 and 3, release on 2 and 4.
        if (i === 4) return frame === 1 || frame === 3;
        return false;
      },
      btnp: (i) => {
        // A press pulses.
        if (i === 4 && (frame === 1 || frame === 3)) return true;
        return false;
      }
    }
  });

  ctx.MC.debug.startNewGame();
  const prevState = ctx.MC.debug.state;
  assert.ok(prevState, "expected debug.state session");

  // Frame 0: draw.
  frame = 0; ctx.MC.mainTick();
  // Frame 1/2: enter confirm.
  frame = 1; ctx.MC.mainTick();
  frame = 2; ctx.MC.mainTick();
  assert.equal(ctx.MC._mainMode, 2);
  assert.equal(ctx.MC.debug.state, prevState);

  // Frame 3/4: confirm overwrite (A tap) should start a new game and enter Render.
  frame = 3; ctx.MC.mainTick();
  frame = 4; ctx.MC.mainTick();
  assert.equal(ctx.MC._mainMode, 1, "expected to enter Render after confirming");
  assert.notEqual(ctx.MC.debug.state, prevState, "expected session to be replaced after confirming");
});

