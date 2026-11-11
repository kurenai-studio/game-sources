import test from "node:test";
import assert from "node:assert/strict";
import { loadSrcIntoVm } from "./helpers/loadSrcIntoVm.mjs";

test("howto: enter from Title, page, scroll, back, and remember state", async () => {
  const printed = [];
  let frame = 0;

  function isDown(i) {
    // Down to select How to Play: frames 1 and 3.
    if (i === 1) return frame === 1 || frame === 3 || frame === 12;
    // A taps: enter howto at frame 5, re-enter at frame 16.
    if (i === 4) return frame === 5 || frame === 16;
    // Right: go Quick Start -> Controls -> Details (frames 8 and 10).
    if (i === 3) return frame === 8 || frame === 10;
    return false;
  }

  function isPressed(i) {
    // D-pad pulses (Down/Right).
    if (i === 1 && (frame === 1 || frame === 3 || frame === 12)) return true;
    if (i === 3 && (frame === 8 || frame === 10)) return true;
    // A press pulses.
    if (i === 4 && (frame === 5 || frame === 16)) return true;
    // B: exit howto on frame 14.
    if (i === 5 && frame === 14) return true;
    return false;
  }

  const ctx = await loadSrcIntoVm({
    extraGlobals: {
      print: (...args) => {
        printed.push(String(args[0]));
      },
      btn: (i) => isDown(i),
      btnp: (i) => isPressed(i),
    }
  });

  assert.equal(ctx.MC._mainMode, 2, "expected to boot into Title mode");

  // Frame 0: draw title.
  frame = 0; ctx.MC.mainTick();

  // Enter How to Play (Down, Down, A tap).
  frame = 1; ctx.MC.mainTick();
  frame = 2; ctx.MC.mainTick();
  frame = 3; ctx.MC.mainTick();
  frame = 4; ctx.MC.mainTick();
  frame = 5; ctx.MC.mainTick(); // A press
  frame = 6; ctx.MC.mainTick(); // A release => mode switch
  assert.equal(ctx.MC._mainMode, 3, "expected HowTo mode after selecting How to Play");

  // First HowTo draw.
  printed.length = 0;
  frame = 7; ctx.MC.mainTick();
  assert.ok(printed.some((s) => s.includes("How to Play")), "expected howto header to print");
  assert.ok(printed.some((s) => s.includes("Quick Start")), "expected Quick Start page title");

  // Page right -> Controls.
  printed.length = 0;
  frame = 8; ctx.MC.mainTick();
  frame = 9; ctx.MC.mainTick();
  assert.ok(printed.some((s) => s.includes("Controls")), "expected Controls page title after paging right");

  // Page right -> Details.
  printed.length = 0;
  frame = 10; ctx.MC.mainTick();
  frame = 11; ctx.MC.mainTick();
  assert.ok(printed.some((s) => s.includes("Details")), "expected Details page title after paging right again");

  // Scroll down on Details (must have scroll room).
  const hc = ctx.MC.config.howto;
  const viewH = ctx.MC.config.screenH - hc.headerH - hc.footerH - 2 * hc.padY;
  const layout = ctx.MC.howto.st.layoutByPage[2];
  assert.ok(layout && layout.contentH > viewH, "expected Details page to be scrollable");

  const prevScroll = ctx.MC.howto.st.scrollByPage[2] || 0;
  frame = 12; ctx.MC.mainTick();
  frame = 13; ctx.MC.mainTick();
  const nextScroll = ctx.MC.howto.st.scrollByPage[2] || 0;
  assert.ok(nextScroll > prevScroll, "expected scroll to increase after Down");

  // Exit HowTo with B.
  frame = 14; ctx.MC.mainTick();
  assert.equal(ctx.MC._mainMode, 2, "expected back to Title after B");

  // Re-enter HowTo (Title selection should still be on How to Play).
  frame = 15; ctx.MC.mainTick();
  frame = 16; ctx.MC.mainTick(); // A press
  frame = 17; ctx.MC.mainTick(); // A release => mode switch
  assert.equal(ctx.MC._mainMode, 3, "expected HowTo mode again");

  // Verify remembered page + scroll.
  assert.equal(ctx.MC.howto.st.pageI, 2, "expected to remember last page (Details)");
  assert.equal(ctx.MC.howto.st.scrollByPage[2] || 0, nextScroll, "expected to remember scroll position for Details");
});

