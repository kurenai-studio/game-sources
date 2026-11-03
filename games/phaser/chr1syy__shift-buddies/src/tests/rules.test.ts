import assert from "node:assert/strict";
import { test } from "node:test";
import {
  dispatch,
  newSession,
  initialState,
  transition,
  isPowered,
  isDoorOpen,
  isPlateHeld,
  isWon,
  isBridgeOpen,
  circuits,
  circuitOn,
  tileAt,
  same,
  ROOMS,
  ROOM_ORDER,
} from "../src/game/rules.ts";
import { DriveInput, driveProgress } from "../src/game/drive.ts";
import type { Action, State, RobotId, Position, RoomId } from "../src/game/rules.ts";
import { solution, fullSolution, bodySolution, moduleSolution, allSolutions, freightSetup } from "./solution.ts";

const play = (state: State, actions: Action[]): State =>
  actions.reduce((s, a) => transition(s, a).state, state);
const up: Action = { type: "move", direction: "up" };
const right: Action = { type: "move", direction: "right" };
const interact: Action = { type: "interact" };
const pull: Action = { type: "pull", direction: "left" };
const powered = (): State => play(initialState(), solution.swapAndPower);
const held = (): State => play(powered(), solution.boltToPlate);
const position = (s: State, id: RobotId, x: number, y: number): State => ({
  ...s,
  robots: { ...s.robots, [id]: { ...s.robots[id], x, y } },
});

test("cooperative tech solution: swap → shaft power → body handoff → both exits", () => {
  let s = powered();
  assert.equal(s.crate, null);
  assert.equal(s.robots.pip.module, "power");
  assert.equal(s.robots.bolt.module, "magnet");
  assert.equal(isPowered(s), true);
  assert.equal(isDoorOpen(s), true);
  s = play(s, solution.boltToPlate);
  assert.equal(isPlateHeld(s), true);
  assert.equal(isPowered(s), true);
  s = play(s, solution.pipToExit);
  assert.equal(isPowered(s), false);
  assert.equal(isDoorOpen(s), true);
  s = play(s, solution.boltToExit);
  assert.equal(isWon(s), true);
  assert.equal(isDoorOpen(s), false);
  assert.equal(
    s.actions,
    fullSolution.length,
    "route contains no rejected or redundant actions",
  );
});

test("undo restores every exact snapshot of the solution, including the winning step", () => {
  let session = newSession();
  const snapshots = [session.state];
  for (const action of fullSolution) {
    session = dispatch(session, action);
    snapshots.push(session.state);
  }
  assert.equal(isWon(session.state), true);
  for (let i = snapshots.length - 2; i >= 0; i--) {
    session = dispatch(session, { type: "undo" });
    assert.deepEqual(session.state, snapshots[i], `snapshot ${i}`);
  }
  assert.deepEqual(session.state, initialState());
  assert.equal(session.history.length, 0);
  assert.deepEqual(dispatch(session, { type: "undo" }).state, initialState());
});

test("restart resets robots, modules, crate, connection, active robot and undo history", () => {
  let session = newSession();
  for (const action of fullSolution) session = dispatch(session, action);
  session = dispatch(session, { type: "restart" });
  assert.deepEqual(session.state, initialState());
  assert.equal(session.history.length, 0);
});

test("power persists across Shift and blocked movement; moving away or E disconnects", () => {
  const s = powered();
  const switched = transition(s, { type: "switch" }).state;
  assert.equal(isPowered(switched), true);
  assert.equal(isPowered(transition(s, right).state), true); // wall at 4/3
  assert.equal(isPowered(transition(s, interact).state), false);
  const moved = transition(s, { type: "move", direction: "down" }).state;
  assert.equal(moved.connected, null);
  assert.equal(isDoorOpen(moved), false);
  assert.deepEqual(
    transition(switched, interact).state,
    switched,
    "Bolt cannot connect remotely",
  );
});

test("body and module are independent: only Pip fits the shaft; only Bolt holds plate", () => {
  for (const module of ["magnet", "power"] as const) {
    let s = position(initialState(), "bolt", 3, 5);
    s = {
      ...s,
      active: "bolt",
      robots: { ...s.robots, bolt: { ...s.robots.bolt, module } },
    };
    assert.deepEqual(transition(s, up).state.robots.bolt, s.robots.bolt);
    s = position(initialState(), "pip", 3, 5);
    assert.equal(transition(s, up).state.robots.pip.y, 4);
  }
  const pipOnPlate = position(initialState(), "pip", 8, 7);
  assert.equal(isPlateHeld(pipOnPlate), false);
  assert.equal(isDoorOpen(pipOnPlate), false);
  assert.equal(isPlateHeld(position(initialState(), "bolt", 8, 7)), true);
});

test("magnet pulls only the facing metal crate with free space behind; no pushing", () => {
  let s = position(initialState("modules"), "pip", 5, 2);
  s = {
    ...s,
    robots: { ...s.robots, pip: { ...s.robots.pip, facing: "right" } },
  };
  assert.deepEqual(
    transition(s, right).state,
    s,
    "walking into crate never pushes it",
  );
  const pulled = transition(s, pull).state;
  assert.deepEqual(pulled.crate, { x: 5, y: 2 });
  assert.equal(pulled.robots.pip.x, 4);
  assert.deepEqual(
    transition(
      {
        ...s,
        robots: { ...s.robots, pip: { ...s.robots.pip, module: "power" } },
      },
      pull,
    ).state.crate,
    s.crate,
  );
  assert.deepEqual(
    transition(
      {
        ...s,
        robots: { ...s.robots, pip: { ...s.robots.pip, facing: "down" } },
      },
      pull,
    ).state.crate,
    s.crate,
  );
  const buddyBehind = position(s, "bolt", 4, 2);
  assert.deepEqual(transition(buddyBehind, pull).state, buddyBehind);
  const wallBehind = { ...position(s, "pip", 3, 2), crate: { x: 4, y: 2 } };
  assert.deepEqual(transition(wallBehind, pull).state, wallBehind);
  const noCrate = initialState();
  assert.deepEqual(transition(noCrate, pull).state, noCrate);
});

test("swap requires orthogonal adjacency, and is exactly undoable", () => {
  const initial = newSession("modules");
  assert.equal(dispatch(initial, { type: "swap" }).history.length, 0);
  const diagonal = initial.state;
  assert.deepEqual(transition(diagonal, { type: "swap" }).state, diagonal);
  const neighbors = dispatch(initial, right);
  const swapped = dispatch(neighbors, { type: "swap" });
  assert.equal(swapped.state.robots.pip.module, "power");
  assert.deepEqual(dispatch(swapped, { type: "undo" }).state, neighbors.state);
});

test("walls, occupied fields and closed door block movement; a facing change is undoable", () => {
  const s = position(initialState(), "pip", 5, 7);
  assert.equal(transition(s, right).state.robots.pip.x, 5);
  const collision = position(initialState(), "pip", 3, 7);
  assert.equal(transition(collision, right).state.robots.pip.x, 3);
  let session = {
    ...newSession(),
    state: position(initialState(), "pip", 1, 5),
  };
  const before = session.state;
  session = dispatch(session, { type: "move", direction: "left" });
  assert.equal(session.state.robots.pip.facing, "left");
  assert.equal(session.state.robots.pip.x, 1);
  assert.deepEqual(dispatch(session, { type: "undo" }).state, before);
});

// Flood fill checks topology independently from transition(), ignoring the other
// robot. Therefore it gives each body MORE freedom than actual play does.
function reachable(
  start: Position,
  id: RobotId,
  crate: Position,
  doorOpen: boolean,
  room: RoomId = "tech",
): Set<string> {
  const seen = new Set<string>();
  const todo = [start];
  while (todo.length) {
    const p = todo.pop()!;
    const key = `${p.x},${p.y}`;
    const tile = tileAt(p, room);
    if (
      seen.has(key) ||
      tile === "#" ||
      tile === "O" ||
      same(p, crate) ||
      (tile === "v" && id === "bolt") ||
      (tile === "D" && !doorOpen)
    )
      continue;
    seen.add(key);
    for (const [dx, dy] of [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
    ])
      todo.push({ x: p.x + dx, y: p.y + dy });
  }
  return seen;
}

test("tech shaft power and remote plate are required before crossing A", () => {
  const s = initialState();
  assert.equal(reachable(s.robots.pip, "pip", { x: -1, y: -1 }, false).has("3,3"), true);
  assert.equal(reachable(s.robots.bolt, "bolt", { x: -1, y: -1 }, true).has("3,3"), false);
  for (const id of ["pip", "bolt"] as const) {
    const closed = reachable(s.robots[id], id, { x: -1, y: -1 }, false);
    assert.equal(closed.has("8,7"), false);
    assert.equal(closed.has("14,9"), false);
    assert.equal(reachable(s.robots[id], id, { x: -1, y: -1 }, true).has("14,9"), true);
  }
  assert.equal(isWon(play(s, fullSolution.filter(a => a.type !== "swap"))), false);
});

test("without the plate, releasing power strands Pip; plate release closes door without latching", () => {
  let s = powered();
  s = position(s, "bolt", 14, 9); // Bolt tries going straight to the exit
  s = transition(s, interact).state;
  assert.equal(isDoorOpen(s), false);
  assert.equal(isWon(s), false);
  assert.equal(
    reachable(s.robots.pip, "pip", { x: -1, y: -1 }, false).has("14,9"),
    false,
  );
  s = held();
  s = transition(s, { type: "switch" }).state;
  s = transition(s, interact).state;
  assert.equal(isDoorOpen(s), true);
  s = transition(s, { type: "switch" }).state;
  s = transition(s, right).state;
  assert.equal(isDoorOpen(s), false);
});

test("one robot at exit does not win; won state accepts only undo or restart", () => {
  const one = play(held(), solution.pipToExit);
  assert.equal(isWon(one), false);
  const won = play(one, solution.boltToExit);
  assert.equal(isWon(won), true);
  for (const action of [
    up,
    interact,
    { type: "switch" },
    { type: "swap" },
  ] as Action[])
    assert.equal(transition(won, action).state, won);
});

for (const [room, route] of Object.entries(allSolutions) as [RoomId, Action[]][]) {
  test(`${room}: valid grid, complete solution, every undo snapshot and local restart`, () => {
    assert.equal(ROOMS[room].grid.length, 13);
    assert.ok(ROOMS[room].grid.every(row => row.length === 17));
    let session = newSession(room);
    const snapshots = [session.state];
    for (const action of route) {
      const before = session.state.actions;
      session = dispatch(session, action);
      assert.equal(session.state.actions, before + 1, JSON.stringify(action));
      snapshots.push(session.state);
    }
    assert.equal(isWon(session.state), true);
    assert.equal(session.state.actions, route.length);
    const restarted = dispatch(session, { type: "restart" });
    assert.deepEqual(restarted.state, initialState(room));
    assert.equal(restarted.history.length, 0);
    for (let i = snapshots.length - 2; i >= 0; i--) {
      session = dispatch(session, { type: "undo" });
      assert.deepEqual(session.state, snapshots[i]);
    }
    assert.equal(session.history.length, 0);
  });
}

test("room selection discards previous undo and restart stays in the chosen room", () => {
  let session = dispatch(newSession("tech"), right);
  for (const room of ROOM_ORDER) {
    session = dispatch(session, { type: "room", room });
    assert.deepEqual(session, newSession(room));
    session = dispatch(session, { type: "switch" });
    session = dispatch(session, { type: "restart" });
    assert.deepEqual(session.state, initialState(room));
    assert.deepEqual(dispatch(session, { type: "undo" }).state, initialState(room));
  }
});

test("body lesson requires Pip's shaft, Bolt's plate, and a switch; no module trick", () => {
  const s = initialState("bodies");
  assert.equal(reachable(s.robots.pip, "pip", { x: -1, y: -1 }, false, "bodies").has("8,5"), false);
  assert.equal(reachable(s.robots.bolt, "bolt", { x: -1, y: -1 }, true, "bodies").has("8,5"), false);
  assert.equal(reachable(s.robots.pip, "pip", { x: -1, y: -1 }, true, "bodies").has("8,5"), true);
  assert.equal(isWon(play(s, bodySolution.filter(a => a.type !== "switch"))), false);
  const atExit = position(s, "pip", 8, 5);
  assert.equal(isWon(atExit), false);
  assert.equal(isWon(position(atExit, "bolt", 5, 7)), true);
});

test("module lesson requires two metal pulls, Pip's body, exchange and power", () => {
  const s = initialState("modules");
  for (const x of [6, 5])
    assert.equal(reachable(s.robots.pip, "pip", { x, y: 2 }, true, "modules").has("8,2"), false);
  assert.equal(reachable(s.robots.pip, "pip", { x: 4, y: 2 }, true, "modules").has("8,2"), true);
  assert.equal(reachable(s.robots.bolt, "bolt", { x: 4, y: 2 }, true, "modules").has("8,2"), false);
  assert.equal(reachable(s.robots.bolt, "bolt", { x: 4, y: 2 }, false, "modules").has("7,6"), false);
  for (const type of ["interact", "swap", "switch"])
    assert.equal(isWon(play(s, moduleSolution.filter(a => a.type !== type))), false);
  const solved = play(s, moduleSolution);
  assert.equal(isPowered(solved), true);
  assert.equal(isWon({ ...solved, connected: null }), false);
});

test("anchored ceramic blocks movement and magnet E gives an explicit immutable rejection", () => {
  let s = initialState("modules");
  s = transition(s, { type: "move", direction: "left" }).state;
  assert.equal(s.robots.pip.x, 3);
  const result = transition(s, interact);
  assert.equal(result.state, s);
  assert.match(result.message, /verankert und nicht magnetisch/);
  assert.deepEqual(result.state.crate, { x: 6, y: 2 });
  assert.equal(tileAt({ x: 2, y: 5 }, s.room), "O");
  const session = { ...newSession("modules"), state: s };
  assert.equal(dispatch(session, interact).history.length, 0);
});


test("E alone, lateral/forward pull and wrong module never move or turn the bot", () => {
  let s = position(initialState("modules"), "pip", 5, 2);
  s = { ...s, robots: { ...s.robots, pip: { ...s.robots.pip, facing: "right" } } };
  for (const action of [interact, { type: "pull", direction: "up" }, { type: "pull", direction: "right" }] as Action[])
    assert.equal(transition(s, action).state, s);
  const result = transition(s, pull).state;
  assert.equal(result.robots.pip.facing, "right");
  assert.deepEqual(result.crate, { x: 5, y: 2 });
  const powerBot = { ...s, robots: { ...s.robots, pip: { ...s.robots.pip, module: "power" as const } } };
  assert.equal(transition(powerBot, pull).state, powerBot);
});

test("crate holds a plate, Pip does not; undo restores crate, plate and door", () => {
  let before = newSession("freight");
  for (const action of freightSetup) before = dispatch(before, action);
  const after = dispatch(before, { type: "pull", direction: "down" });
  assert.equal(isPlateHeld(after.state), true);
  assert.deepEqual(after.state.crate, { x: 5, y: 4 });
  const disconnected = transition({ ...after.state, active: "pip" }, interact).state;
  assert.equal(isDoorOpen(disconnected), true);
  assert.equal(isDoorOpen({ ...disconnected, crate: null }), false);
  assert.deepEqual(dispatch(after, { type: "undo" }).state, before.state);
});

test("separate circuits never power the other door; module swap disconnects", () => {
  let s = position(initialState("routes"), "pip", 3, 3);
  s = { ...s, connected: "pip", robots: { ...s.robots, pip: { ...s.robots.pip, module: "power" } } };
  assert.equal(isDoorOpen(s, { x: 6, y: 7 }), true);
  assert.equal(isDoorOpen(s, { x: 11, y: 7 }), false);
  s = { ...position(s, "pip", 9, 8), crate: { x: 9, y: 7 } };
  assert.equal(isDoorOpen(s, { x: 6, y: 7 }), false);
  assert.equal(isDoorOpen(s, { x: 11, y: 7 }), true);
  s = position(s, "bolt", 8, 8);
  const swapped = transition(s, { type: "swap" }).state;
  assert.equal(swapped.connected, null);
  assert.equal(isDoorOpen(swapped, { x: 6, y: 7 }), false);
  assert.equal(isDoorOpen(swapped, { x: 11, y: 7 }), true);
  // A valid adjacent supplier, with power actually on before the exchange.
  const supplied: State = { ...initialState("bridge"), connected: "pip", robots: {
    pip: { x: 5, y: 5, facing: "right", module: "power" },
    bolt: { x: 6, y: 5, facing: "left", module: "magnet" },
  } };
  assert.equal(isPowered(supplied), true);
  const exchanged = transition(supplied, { type: "swap" }).state;
  assert.equal(exchanged.connected, null);
  assert.equal(isBridgeOpen(exchanged, { x: 7, y: 5 }), false);
});

test("bridge occupancy interlock on power loss: E, departure, swap, crate and undo", () => {
  const span = { x: 7, y: 5 };
  let s = initialState("bridge");
  s = position(s, "bolt", 5, 5);
  s = position(s, "pip", 6, 5);
  s = { ...s, active: "pip", connected: "bolt" };
  assert.equal(isBridgeOpen(s, span), true);
  const onboard = transition(s, right).state;
  assert.equal(onboard.robots.pip.x, 7);
  const lostPower = { ...onboard, active: "bolt" as const };
  for (const action of [interact, { type: "move", direction: "down" }] as Action[]) {
    const off = transition(lostPower, action).state;
    assert.equal(isPowered(off), false);
    assert.equal(isBridgeOpen(off, span), true);
    const departed: State = transition({ ...off, active: "pip" }, right).state;
    assert.equal(departed.robots.pip.x, 8);
    assert.equal(isBridgeOpen(departed, span), false);
    const session = dispatch({ state: off, history: [], message: "" }, { type: "switch" });
    const moved = dispatch(session, right);
    assert.deepEqual(dispatch(moved, { type: "undo" }).state, session.state);
  }
  const adjacentSupplier = position(lostPower, "bolt", 6, 5);
  assert.equal(isBridgeOpen(transition(adjacentSupplier, { type: "swap" }).state, span), true);
  assert.equal(isBridgeOpen({ ...initialState("bridge"), crate: span }, span), true);
  assert.equal(isBridgeOpen(initialState("bridge"), span), false);
});

// Independent topology check for each new gate. With MORE freedom than actual
// play (no partner collisions), a walker still cannot bypass its closed output.
test("new rooms have no trivial walking bypass of freight, A/B or bridge/return", () => {
  function flood(room: RoomId, start: Position, allowed: Set<string>): Set<string> {
    const seen = new Set<string>(), todo = [start];
    while (todo.length) {
      const p = todo.pop()!, key = `${p.x},${p.y}`, tile = tileAt(p, room);
      if (seen.has(key) || "#O~".includes(tile) || ((tile === "D" || tile === "B") && !allowed.has(key))) continue;
      seen.add(key);
      for (const [dx, dy] of [[1,0],[-1,0],[0,1],[0,-1]]) todo.push({ x: p.x+dx, y: p.y+dy });
    }
    return seen;
  }
  assert.equal(flood("freight", ROOMS.freight.pip, new Set()).has("12,7"), false);
  assert.equal(flood("routes", ROOMS.routes.pip, new Set()).has("8,7"), false);
  assert.equal(flood("routes", { x: 8, y: 7 }, new Set(["6,7"])).has("14,9"), false);
  assert.equal(flood("bridge", ROOMS.bridge.pip, new Set()).has("14,9"), false);
  assert.equal(flood("bridge", ROOMS.bridge.pip, new Set(["7,5"])).has("14,9"), false);
  const bridgeCircuits = circuits("bridge");
  const held = position(initialState("bridge"), "bolt", 10, 5);
  assert.equal(circuitOn(held, bridgeCircuits[0]), false);
  assert.equal(circuitOn(held, bridgeCircuits[1]), true);
});

test("Bolt's body pushes with either module; obstacles reject without turning or losing power", () => {
  for (const module of ["magnet", "power"] as const) {
    let s: State = play(initialState("freight"), freightSetup);
    s = { ...s, robots: { ...s.robots, bolt: { ...s.robots.bolt, module } } };
    const push: Action = { type: "pull", direction: "down" };
    const rejectedActions: Action[] = [interact, { type: "move", direction: "down" },
      { type: "pull", direction: "right" }];
    for (const action of rejectedActions) {
      assert.equal(transition(s, action).state, s);
    }
    const pushed: State = transition(s, push).state;
    assert.deepEqual(pushed.crate, { x: 5, y: 4 });
    assert.equal(pushed.robots.bolt.y, 3);
    assert.equal(pushed.robots.bolt.facing, "down");
    assert.equal(pushed.robots.bolt.module, module);
    assert.equal(pushed.connected, "pip", "partner's supply persists");
    assert.equal(transition(pushed, push).state, pushed, "wall behind the crate");
    assert.equal(transition(position(s, "pip", 5, 4), push).state.robots.bolt.y, 2,
      "partner behind the crate blocks a push");
    const pip = { ...s, active: "pip" as const, robots: { ...s.robots,
      pip: { ...s.robots.pip, module, x: 5, y: 2, facing: "down" as const },
      bolt: { ...s.robots.bolt, x: 4, y: 2 } } };
    assert.equal(transition(pip, push).state, pip, "Pip cannot push with either module");
  }
});

test("both bodies can pull with magnet, battery cannot; freight never enters a shaft", () => {
  for (const id of ["pip", "bolt"] as const) {
    const other = id === "pip" ? "bolt" : "pip";
    let s = initialState("modules");
    s = { ...s, active: id, robots: { ...s.robots,
      [id]: { x: 5, y: 2, module: "magnet", facing: "right" },
      [other]: { ...s.robots[other], x: 3, y: 5 } } };
    assert.deepEqual(transition(s, pull).state.crate, { x: 5, y: 2 });
    const power = { ...s, robots: { ...s.robots, [id]: { ...s.robots[id], module: "power" as const } } };
    assert.equal(transition(power, pull).state, power);
  }
  const s = initialState("modules");
  const inShaft: State = { ...s, crate: { x: 3, y: 3 }, robots: { ...s.robots,
    pip: { ...s.robots.pip, x: 3, y: 4, facing: "up" } } };
  assert.equal(transition(inShaft, { type: "pull", direction: "down" }).state, inShaft);
  const bolt: State = { ...s, active: "bolt", crate: { x: 3, y: 3 }, robots: { ...s.robots,
    bolt: { ...s.robots.bolt, x: 3, y: 2, facing: "down" } } };
  assert.equal(transition(bolt, { type: "pull", direction: "down" }).state, bolt);
});

test("cooperation routes fail without their required handoff, freight or partner supply", () => {
  for (const room of ["tech", "freight", "routes", "bridge"] as const) {
    assert.equal(isWon(play(initialState(room), allSolutions[room].filter(a => a.type !== "swap"))), false, room);
  }
  for (const room of ["freight", "routes"] as const) {
    assert.equal(isWon(play(initialState(room), allSolutions[room].filter(a => a.type !== "pull"))), false, room);
  }
  const bridge = initialState("bridge");
  const lightPlate = position(bridge, "pip", 10, 5);
  assert.equal(isDoorOpen(lightPlate, { x: 6, y: 9 }), false);
  const heavyPlate = position(bridge, "bolt", 10, 5);
  assert.equal(isDoorOpen(heavyPlate, { x: 6, y: 9 }), true);
  assert.equal(isDoorOpen(heavyPlate, { x: 12, y: 7 }), false, "B still needs Pip's separate supply");
});

// Physical key ownership stays outside the puzzle state and its undo history.

test("held input: newest physical key wins, aliases and releases are deterministic", () => {
  const input = new DriveInput();
  assert.equal(input.press("KeyD"), true);
  assert.equal(input.take(), "right");
  assert.equal(input.press("KeyD"), false);
  assert.equal(input.press("ArrowRight"), true);
  input.take(); input.release("KeyD");
  assert.equal(input.take(), "right");
  input.press("KeyW");
  assert.equal(input.take(), "up");
  input.release("KeyW");
  assert.equal(input.take(), "right");
  input.release("ArrowRight");
  assert.equal(input.take(), undefined);
});

test("tap has one pending step; obstacles latch, fresh input and resets clear safely", () => {
  const input = new DriveInput();
  input.press("KeyA"); input.release("KeyA");
  assert.equal(input.take(), "left");
  assert.equal(input.take(), undefined);
  input.press("KeyD"); input.take(); input.obstruct();
  for (let n = 0; n < 100; n++) assert.equal(input.take(), undefined);
  assert.equal(input.press("KeyD"), false);
  input.release("KeyD"); input.press("KeyD");
  assert.equal(input.take(), "right");
  input.press("KeyW"); input.reset();
  assert.equal(input.continuing, false);
  assert.equal(input.take(), undefined);
});

test("departure joins linear travel with unit velocity; no interior per-tile easing", () => {
  const h = 0.00001;
  assert.equal(driveProgress(0, true), 0);
  assert.equal(driveProgress(1, true), 1);
  assert.ok(Math.abs((driveProgress(h, true) - driveProgress(0, true)) / h) < 0.001);
  assert.ok(Math.abs((driveProgress(1, true) - driveProgress(1-h, true)) / h - 1) < 0.001);
  for (const t of [0, 0.1, 0.5, 0.9, 1]) assert.equal(driveProgress(t, false), t);
});
