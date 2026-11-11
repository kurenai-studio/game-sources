import test from "node:test";
import assert from "node:assert/strict";
import { loadSrcIntoVm } from "./helpers/loadSrcIntoVm.mjs";

test("about: enter from Title and back with B", async () => {
  const printed = [];
  let frame = 0;

  function isDown(i) {
    // Down pulses to select About: frames 1, 3, 5 (New Game -> Continue -> How to Play -> About).
    if (i === 1) return frame === 1 || frame === 3 || frame === 5;
    // A press to enter About: frame 7.
    if (i === 4) return frame === 7;
    return false;
  }

  function isPressed(i) {
    // D-pad pulses.
    if (i === 1 && (frame === 1 || frame === 3 || frame === 5)) return true;
    // A press pulse.
    if (i === 4 && frame === 7) return true;
    // B press pulse to exit About: frame 11.
    if (i === 5 && frame === 11) return true;
    return false;
  }

  const ctx = await loadSrcIntoVm({
    extraGlobals: {
      print: (s) => {
        printed.push(String(s));
      },
      btn: (i) => isDown(i),
      btnp: (i) => isPressed(i),
    }
  });

  assert.equal(ctx.MC._mainMode, 2, "expected to boot into Title mode");

  // Frame 0: draw title.
  frame = 0; ctx.MC.mainTick();

  // Select About (Down, Down, Down) then A tap to enter.
  frame = 1; ctx.MC.mainTick();
  frame = 2; ctx.MC.mainTick();
  frame = 3; ctx.MC.mainTick();
  frame = 4; ctx.MC.mainTick();
  frame = 5; ctx.MC.mainTick();
  frame = 6; ctx.MC.mainTick();

  frame = 7; ctx.MC.mainTick(); // A press
  frame = 8; ctx.MC.mainTick(); // A release => mode switch
  assert.equal(ctx.MC._mainMode, 4, "expected About mode after selecting About");

  // First About draw should print the header label.
  printed.length = 0;
  frame = 9; ctx.MC.mainTick();
  assert.ok(printed.some((s) => s.includes("About")), "expected About header to print");

  // Exit About with B.
  frame = 10; ctx.MC.mainTick();
  frame = 11; ctx.MC.mainTick();
  assert.equal(ctx.MC._mainMode, 2, "expected back to Title after B");
});

