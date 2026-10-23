import { test } from 'node:test';
import assert from 'node:assert/strict';

import { GameState, PlayerAction } from '../public/game/gameState.js';
import { InputController } from '../public/game/inputController.js';
import { fixedFactory, newGame } from './helpers.js';
import { PieceColors } from '../public/game/tetrominoFactory.js';

// Minimal stand ins for the browser globals InputController uses.
function setup(t) {
  t.mock.timers.enable({ apis: ['setTimeout', 'setInterval'] });
  const listeners = {};
  const frames = [];
  const pads = [];
  globalThis.window = { addEventListener: (type, listener) => (listeners[type] ??= []).push(listener) };
  globalThis.requestAnimationFrame = callback => frames.push(callback);
  Object.defineProperty(globalThis, 'navigator', { value: { getGamepads: () => pads }, configurable: true, writable: true });
  t.after(() => {
    delete globalThis.window;
    delete globalThis.requestAnimationFrame;
  });

  const manager = {
    state: GameState.playing,
    isConfirmingNewGame: false,
    actions: [],
    handleAction(action) { this.actions.push(action); },
    togglePause() { this.actions.push('togglePause'); },
    softDrop() { this.actions.push('softDrop'); },
    cancelNewGame() { this.actions.push('cancelNewGame'); }
  };
  // The New Game question's buttons, recording what the controller asks of them.
  const questionButtons = {
    move(step) { manager.actions.push(`move ${step}`); },
    press() { manager.actions.push('press'); }
  };
  const controller = new InputController(manager, questionButtons);
  const fire = (type, event = {}) => (listeners[type] ?? []).forEach(listener => listener(event));
  const key = (code, pressed = true, extra = {}) => {
    const event = { code, repeat: false, metaKey: false, ctrlKey: false, altKey: false, prevented: false, ...extra };
    event.preventDefault = () => { event.prevented = true; };
    fire(pressed ? 'keydown' : 'keyup', event);
    return event;
  };
  const tap = code => { key(code); key(code, false); };
  // Node's mock clock only runs timers that were scheduled before a tick, so
  // advance in small steps to let repeating timers chain like they do live.
  const tick = ms => {
    for (let left = ms; left > 0; left -= 10) t.mock.timers.tick(Math.min(10, left));
  };
  return { manager, controller, fire, key, tap, tick, pads, frames };
}

function gamepad({ pressed = [], x = 0, y = 0 } = {}) {
  const index = { a: 0, b: 1, x: 2, y: 3, lb: 4, rb: 5, view: 8, menu: 9, up: 12, down: 13, left: 14, right: 15 };
  const buttons = Array.from({ length: 16 }, () => ({ pressed: false }));
  for (const name of pressed) buttons[index[name]].pressed = true;
  return { connected: true, buttons, axes: [x, y] };
}

const count = (manager, action) => manager.actions.filter(a => a === action).length;

// Keyboard

test('each action key triggers its action once per press [INP-1]', t => {
  const expected = {
    KeyW: PlayerAction.rotate,
    ArrowUp: PlayerAction.rotate,
    KeyZ: PlayerAction.rotateCounterclockwise,
    Space: PlayerAction.drop,
    KeyH: PlayerAction.hold,
    Enter: PlayerAction.newGame,
    NumpadEnter: PlayerAction.newGame,
    KeyC: PlayerAction.continueGame
  };
  const { manager, tap } = setup(t);
  for (const [code, action] of Object.entries(expected)) {
    manager.actions = [];
    tap(code);
    assert.deepEqual(manager.actions, [action], code);
  }
});

test('P and Escape toggle pause [INP-1]', t => {
  const { manager, tap } = setup(t);
  tap('KeyP');
  tap('Escape');
  assert.deepEqual(manager.actions, ['togglePause', 'togglePause']);
});

test('game keys stop the browser default, other keys do not [INP-3]', t => {
  const { manager, key } = setup(t);
  assert.equal(key('KeyW').prevented, true);
  assert.equal(key('ArrowDown').prevented, true, 'arrow keys must not scroll the page');
  assert.equal(key('Space').prevented, true, 'space must not scroll the page');
  assert.equal(key('Space', false).prevented, true, 'or press an on screen button that has focus');
  assert.equal(key('KeyA').prevented, true);
  assert.equal(key('KeyQ').prevented, false);
  assert.equal(key('Tab').prevented, false);
  assert.equal(count(manager, PlayerAction.rotate), 1);
});

test('keys held with Cmd, Ctrl or Alt are left to the browser [INP-3]', t => {
  const { manager, key } = setup(t);
  for (const modifier of ['metaKey', 'ctrlKey', 'altKey']) {
    const event = key('KeyW', true, { [modifier]: true });
    assert.equal(event.prevented, false, modifier);
    key('KeyW', false);
  }
  assert.deepEqual(manager.actions, []);
});

test('a key pressed with Cmd, Ctrl or Alt never counts as held, so a lost key release cannot leave it stuck [INP-3]', t => {
  const { manager, key, tick } = setup(t);
  // macOS sends no keyup for a key let go while Cmd is down.
  for (const modifier of ['metaKey', 'ctrlKey', 'altKey']) key('KeyA', true, { [modifier]: true });
  key('KeyD');
  key('KeyD', false);
  tick(1000);
  assert.deepEqual(manager.actions, [PlayerAction.moveRight]);
});

test('key repeat events from holding a key are ignored [INP-3]', t => {
  const { manager, key } = setup(t);
  key('Space');
  const repeat = key('Space', true, { repeat: true });
  assert.equal(repeat.prevented, true);
  assert.deepEqual(manager.actions, [PlayerAction.drop]);
});

test('while the pause screen asks to confirm New Game, keys are left to its dialog, except a held key repeating, Escape, which answers no, and the left and right arrows, which move between its buttons [STA-1] [INP-3]', t => {
  const { manager, key, tap } = setup(t);
  manager.state = GameState.paused;
  manager.isConfirmingNewGame = true;
  for (const code of ['Enter', 'Space', 'KeyP', 'KeyC', 'Tab', 'KeyA', 'KeyD']) {
    assert.equal(key(code).prevented, false, `${code} reaches the dialog's button`);
    key(code, false);
  }
  assert.equal(key('Enter', true, { repeat: true }).prevented, true, 'the Enter that asked, still held, must not answer');
  assert.deepEqual(manager.actions, []);
  assert.equal(key('Escape').prevented, true, 'Escape answers no itself, rather than leaving the dialog to the browser');
  key('Escape', true, { repeat: true });
  key('Escape', false);
  assert.deepEqual(manager.actions, ['cancelNewGame'], 'once per press');
  // The arrows, not A and D, move between the buttons, once per press.
  assert.equal(key('ArrowRight').prevented, true);
  key('ArrowRight', true, { repeat: true });
  key('ArrowRight', false);
  assert.equal(key('ArrowLeft').prevented, true);
  key('ArrowLeft', false);
  assert.deepEqual(manager.actions, ['cancelNewGame', 'move 1', 'move -1']);
  manager.actions = [];
  // A key pressed meanwhile still counts as held once the dialog closes.
  key('KeyD');
  manager.isConfirmingNewGame = false;
  manager.state = GameState.playing;
  tap('KeyA');
  assert.deepEqual(manager.actions, [PlayerAction.moveLeft, PlayerAction.moveRight]);
});

test('holding S or Down soft drops a row at once, then every 50ms until released [INP-1] [INP-2]', t => {
  const { manager, key, tick } = setup(t);
  key('ArrowDown');
  assert.equal(count(manager, 'softDrop'), 1);
  key('ArrowDown', true, { repeat: true });
  tick(49);
  assert.equal(count(manager, 'softDrop'), 1, 'key repeats add nothing');
  tick(1);
  assert.equal(count(manager, 'softDrop'), 2);
  tick(100);
  assert.equal(count(manager, 'softDrop'), 4);
  key('ArrowDown', false);
  tick(500);
  assert.equal(count(manager, 'softDrop'), 4);
  key('KeyS');
  key('KeyS', false);
  tick(500);
  assert.equal(count(manager, 'softDrop'), 5);
  assert.deepEqual(manager.actions.filter(action => action !== 'softDrop'), [], 'a soft drop is never a hard drop');
});

test('the soft drop key stops once the game is no longer playing [INP-2]', t => {
  const { manager, controller, key, tick } = setup(t);
  key('KeyS');
  manager.state = GameState.paused;
  tick(500);
  assert.equal(count(manager, 'softDrop'), 1);
  assert.equal(controller.softDropTimer, undefined);
});

test('losing window focus stops the soft drop key [INP-2]', t => {
  const { manager, key, fire, tick } = setup(t);
  key('KeyS');
  fire('blur');
  tick(500);
  assert.equal(count(manager, 'softDrop'), 1);
});

test('holding a move key moves once, then repeats after 167ms every 33ms [INP-2]', t => {
  const { manager, key, tick } = setup(t);
  key('KeyA');
  assert.equal(count(manager, PlayerAction.moveLeft), 1);
  tick(166);
  assert.equal(count(manager, PlayerAction.moveLeft), 1);
  tick(1);
  assert.equal(count(manager, PlayerAction.moveLeft), 2);
  tick(33);
  assert.equal(count(manager, PlayerAction.moveLeft), 3);
  for (let i = 0; i < 3; i++) tick(33);
  assert.equal(count(manager, PlayerAction.moveLeft), 6);
  key('KeyA', false);
  tick(1000);
  assert.equal(count(manager, PlayerAction.moveLeft), 6);
});

test('arrow keys move like A and D [INP-1]', t => {
  const { manager, tap } = setup(t);
  tap('ArrowLeft');
  tap('ArrowRight');
  assert.deepEqual(manager.actions, [PlayerAction.moveLeft, PlayerAction.moveRight]);
});

test('the newest direction wins, and releasing it returns to the one still held [INP-2]', t => {
  const { manager, key, tick } = setup(t);
  key('KeyA');
  key('KeyD');
  assert.deepEqual(manager.actions, [PlayerAction.moveLeft, PlayerAction.moveRight]);
  tick(167);
  assert.equal(manager.actions.at(-1), PlayerAction.moveRight);
  key('KeyD', false);
  assert.equal(manager.actions.at(-1), PlayerAction.moveLeft);
  key('KeyA', false);
  const total = manager.actions.length;
  tick(1000);
  assert.equal(manager.actions.length, total);
});

test('auto repeat stops once the game is no longer playing [INP-2]', t => {
  const { manager, key, tick } = setup(t);
  key('KeyD');
  manager.state = GameState.paused;
  tick(1000);
  assert.equal(count(manager, PlayerAction.moveRight), 1);
});

test('losing window focus releases every held key [INP-2]', t => {
  const { manager, key, fire, tick } = setup(t);
  key('KeyA');
  fire('blur');
  tick(1000);
  assert.equal(count(manager, PlayerAction.moveLeft), 1);
  key('KeyD');
  key('KeyD', false);
  assert.equal(count(manager, PlayerAction.moveLeft), 1, 'A is no longer treated as held');
});

// Gamepad

test('gamepad buttons trigger their action on press, not while held [INP-4]', t => {
  const { manager, controller, pads } = setup(t);
  const buttons = [
    ['a', PlayerAction.drop],
    ['up', PlayerAction.drop],
    ['b', PlayerAction.rotate],
    ['rb', PlayerAction.rotate],
    ['lb', PlayerAction.rotateCounterclockwise],
    ['x', PlayerAction.hold],
    ['y', PlayerAction.continueGame],
    ['view', PlayerAction.newGame]
  ];
  for (const [button, action] of buttons) {
    manager.actions = [];
    pads[0] = gamepad({ pressed: [button] });
    controller.pollGamepads();
    controller.pollGamepads();
    assert.deepEqual(manager.actions, [action], `${button} held`);
    pads[0] = gamepad();
    controller.pollGamepads();
    pads[0] = gamepad({ pressed: [button] });
    controller.pollGamepads();
    assert.deepEqual(manager.actions, [action, action], `${button} pressed again`);
    pads[0] = gamepad();
    controller.pollGamepads();
  }
});

test('two buttons for the same action pressed together act once [INP-4]', t => {
  const { manager, controller, pads } = setup(t);
  pads[0] = gamepad({ pressed: ['a', 'up', 'b', 'rb', 'lb'] });
  controller.pollGamepads();
  assert.deepEqual(manager.actions, [PlayerAction.rotate, PlayerAction.rotateCounterclockwise, PlayerAction.drop]);
});

test('Menu and View act alone: other buttons pressed at the same moment do nothing, and Menu wins over View [INP-4]', t => {
  const { manager, controller, pads } = setup(t);
  const press = (state, buttons) => {
    manager.state = state;
    manager.actions = [];
    pads[0] = gamepad({ pressed: buttons });
    controller.pollGamepads();
    pads[0] = gamepad();
    controller.pollGamepads();
    controller.stopMoving();
    return manager.actions;
  };
  const others = ['a', 'b', 'x', 'y', 'lb', 'rb', 'up'];
  assert.deepEqual(press(GameState.gameOver, ['menu', ...others]), [PlayerAction.newGame], 'A cannot hard drop the new game\'s first piece');
  assert.deepEqual(press(GameState.playing, ['menu', ...others]), ['togglePause']);
  assert.deepEqual(press(GameState.paused, ['view', ...others]), [PlayerAction.newGame], 'nothing cancels the question just asked');
  assert.deepEqual(press(GameState.paused, ['menu', 'view']), ['togglePause']);
  assert.deepEqual(press(GameState.gameOver, ['menu', 'view']), [PlayerAction.newGame], 'one new game, not two');
  // Moving carries on as held.
  assert.deepEqual(press(GameState.gameOver, ['menu', 'left']), [PlayerAction.newGame, PlayerAction.moveLeft]);
});

test('View and A pressed together on the pause screen leave the New Game question open [INP-4] [STA-1]', t => {
  const { pads } = setup(t);
  const { game } = newGame({ factory: fixedFactory(PieceColors.cyan) });
  const controller = new InputController(game, { move() {}, press() {} });
  game.togglePause();
  pads[0] = gamepad({ pressed: ['view', 'a'] });
  controller.pollGamepads();
  assert.equal(game.state, GameState.paused);
  assert.equal(game.isConfirmingNewGame, true);
});

test('the menu button pauses during play and starts a new game at game over [INP-4]', t => {
  const { manager, controller, pads } = setup(t);
  pads[0] = gamepad({ pressed: ['menu'] });
  controller.pollGamepads();
  assert.deepEqual(manager.actions, ['togglePause']);
  pads[0] = gamepad();
  controller.pollGamepads();
  manager.state = GameState.gameOver;
  pads[0] = gamepad({ pressed: ['menu'] });
  controller.pollGamepads();
  assert.deepEqual(manager.actions, ['togglePause', PlayerAction.newGame]);
});

test('while the pause screen asks to confirm New Game, left and right move between its buttons, A presses the selected one, B cancels, and nothing else on the gamepad acts [STA-1] [INP-4]', t => {
  const { manager, controller, pads, tick } = setup(t);
  manager.state = GameState.paused;
  manager.isConfirmingNewGame = true;
  const poll = state => {
    pads[0] = gamepad(state);
    controller.pollGamepads();
  };
  for (const button of ['x', 'y', 'view', 'menu', 'lb', 'rb', 'up', 'down']) {
    poll({ pressed: [button] });
    poll();
  }
  poll({ y: -1 });
  tick(500);
  poll();
  assert.deepEqual(manager.actions, [], 'nothing else acts');
  // Once per push, on the directional pad or the stick, however long it is held.
  poll({ pressed: ['right'] });
  poll({ pressed: ['right'] });
  tick(500);
  poll({ pressed: ['right'] });
  poll();
  poll({ x: -1 });
  poll({ x: -0.9 });
  poll();
  assert.deepEqual(manager.actions, ['move 1', 'move -1']);
  manager.actions = [];
  poll({ pressed: ['a'] });
  assert.deepEqual(manager.actions, ['press'], 'A presses the selected button');
  poll({ pressed: ['a', 'b'] });
  assert.deepEqual(manager.actions, ['press', 'cancelNewGame'], 'B cancels, and A held from before does not press again');
  poll();
  // A push still held as the question closes does not then move a piece.
  poll({ pressed: ['right'] });
  manager.isConfirmingNewGame = false;
  manager.state = GameState.playing;
  manager.actions = [];
  poll({ pressed: ['right'] });
  assert.deepEqual(manager.actions, []);
  poll();
  poll({ pressed: ['right'] });
  assert.deepEqual(manager.actions, [PlayerAction.moveRight], 'a new push moves it');
});

test('the stick moves left and right with the same auto repeat as the keyboard [INP-4]', t => {
  const { manager, controller, pads, tick } = setup(t);
  pads[0] = gamepad({ x: -1 });
  controller.pollGamepads();
  assert.equal(count(manager, PlayerAction.moveLeft), 1);
  controller.pollGamepads(); // still held: no extra move
  tick(167);
  assert.equal(count(manager, PlayerAction.moveLeft), 2);
  pads[0] = gamepad({ x: 0.2 }); // inside the dead zone
  controller.pollGamepads();
  tick(1000);
  assert.equal(count(manager, PlayerAction.moveLeft), 2);
  pads[0] = gamepad({ x: 0.9 });
  controller.pollGamepads();
  assert.equal(count(manager, PlayerAction.moveRight), 1);
});

test('the directional pad moves left and right with the same auto repeat as the stick [INP-4]', t => {
  const { manager, controller, pads, tick } = setup(t);
  pads[0] = gamepad({ pressed: ['left'] });
  controller.pollGamepads();
  assert.equal(count(manager, PlayerAction.moveLeft), 1);
  controller.pollGamepads(); // still held: no extra move
  tick(167);
  assert.equal(count(manager, PlayerAction.moveLeft), 2);
  pads[0] = gamepad({ pressed: ['right'] });
  controller.pollGamepads();
  assert.equal(count(manager, PlayerAction.moveRight), 1);
  pads[0] = gamepad();
  controller.pollGamepads();
  tick(500);
  assert.deepEqual(manager.actions, [PlayerAction.moveLeft, PlayerAction.moveLeft, PlayerAction.moveRight]);
});

test('letting go of the directional pad goes back to a move key still held [INP-2] [INP-4]', t => {
  const { manager, controller, key, pads } = setup(t);
  key('KeyA');
  pads[0] = gamepad({ pressed: ['right'] });
  controller.pollGamepads();
  pads[0] = gamepad();
  controller.pollGamepads();
  assert.deepEqual(manager.actions, [PlayerAction.moveLeft, PlayerAction.moveRight, PlayerAction.moveLeft]);
});

test('holding down on the directional pad soft drops every 50ms [INP-4]', t => {
  const { manager, controller, pads, tick } = setup(t);
  pads[0] = gamepad({ pressed: ['down'] });
  controller.pollGamepads();
  tick(50);
  assert.equal(count(manager, 'softDrop'), 1);
  tick(100);
  assert.equal(count(manager, 'softDrop'), 3);
  pads[0] = gamepad();
  controller.pollGamepads();
  tick(500);
  assert.equal(count(manager, 'softDrop'), 3);
  assert.deepEqual(manager.actions.filter(action => action !== 'softDrop'), [], 'down on the pad does nothing else');
});

test('pushing the stick down soft drops every 50ms, up does nothing [INP-4]', t => {
  const { manager, controller, pads, tick } = setup(t);
  pads[0] = gamepad({ y: -1 }); // browser axes: up is negative
  controller.pollGamepads();
  tick(500);
  assert.equal(count(manager, 'softDrop'), 0);
  pads[0] = gamepad({ y: 1 });
  controller.pollGamepads();
  tick(50);
  assert.equal(count(manager, 'softDrop'), 1);
  tick(100);
  assert.equal(count(manager, 'softDrop'), 3);
  pads[0] = gamepad();
  controller.pollGamepads();
  tick(500);
  assert.equal(count(manager, 'softDrop'), 3);
});

test('soft drop stops once the game is no longer playing [INP-4]', t => {
  const { manager, controller, pads, tick } = setup(t);
  pads[0] = gamepad({ y: 1 });
  controller.pollGamepads();
  tick(50);
  manager.state = GameState.paused;
  tick(500);
  assert.equal(count(manager, 'softDrop'), 1);
  assert.equal(controller.softDropTimer, undefined, 'the timer itself is stopped, not left ticking');
});

test('a resting stick does not cancel keyboard movement [INP-4]', t => {
  const { manager, controller, key, pads, tick } = setup(t);
  pads[0] = gamepad();
  key('KeyA');
  for (let i = 0; i < 10; i++) controller.pollGamepads();
  tick(200);
  assert.equal(count(manager, PlayerAction.moveLeft), 2);
});

test('a resting stick does not cancel the soft drop key, and the stick keeps it going after the key is let go [INP-2] [INP-4]', t => {
  const { manager, controller, key, pads, tick } = setup(t);
  pads[0] = gamepad();
  key('KeyS');
  for (let i = 0; i < 5; i++) controller.pollGamepads();
  tick(100);
  assert.equal(count(manager, 'softDrop'), 3);
  pads[0] = gamepad({ y: 1 });
  controller.pollGamepads();
  key('KeyS', false);
  tick(100);
  assert.equal(count(manager, 'softDrop'), 5);
  pads[0] = gamepad();
  controller.pollGamepads();
  tick(500);
  assert.equal(count(manager, 'softDrop'), 5);
});

test('after disconnecting with the stick down, the soft drop key works on its own [INP-4]', t => {
  const { manager, controller, fire, key, pads, tick } = setup(t);
  pads[0] = gamepad({ y: 1 });
  controller.pollGamepads();
  fire('gamepaddisconnected');
  key('KeyS');
  key('KeyS', false);
  tick(500);
  assert.equal(count(manager, 'softDrop'), 1);
});

test('disconnecting the gamepad releases the stick [INP-4]', t => {
  const { manager, controller, fire, pads, tick } = setup(t);
  pads[0] = gamepad({ y: 1 });
  controller.pollGamepads();
  fire('gamepaddisconnected');
  tick(500);
  assert.equal(count(manager, 'softDrop'), 0);
});

test('polling with no gamepad, or an empty slot, does nothing [INP-4]', t => {
  const { manager, controller, pads } = setup(t);
  controller.pollGamepads();
  pads[0] = null;
  pads[1] = { ...gamepad({ pressed: ['a'] }), connected: false };
  controller.pollGamepads();
  assert.deepEqual(manager.actions, []);
});

test('gamepads are polled on every animation frame [INP-4]', t => {
  const { manager, frames, pads } = setup(t);
  assert.equal(frames.length, 1, 'polling starts right away');
  pads[0] = gamepad({ pressed: ['b'] });
  frames.shift()();
  assert.deepEqual(manager.actions, [PlayerAction.rotate]);
  assert.equal(frames.length, 1, 'and schedules the next poll');
});

test('polling stops while no gamepad is connected and starts again when one connects [INP-4] [DSP-3]', t => {
  const { manager, fire, frames, pads } = setup(t);
  frames.shift()();
  assert.equal(frames.length, 0, 'no gamepad: no more polls');
  fire('gamepadconnected');
  fire('gamepadconnected');
  assert.equal(frames.length, 1, 'one polling loop however many connect');
  pads[0] = gamepad({ pressed: ['b'] });
  frames.shift()();
  assert.deepEqual(manager.actions, [PlayerAction.rotate]);
  assert.equal(frames.length, 1, 'keeps polling while connected');
  pads[0] = { ...gamepad(), connected: false };
  frames.shift()();
  assert.equal(frames.length, 0, 'stops after the last one disconnects');
  fire('gamepadconnected');
  assert.equal(frames.length, 1, 'and can start again');
});

test('an error while reading the gamepad never stops polling [SAF-5]', t => {
  const { manager, frames, pads } = setup(t);
  const logged = t.mock.method(console, 'error', () => {});
  Object.defineProperty(globalThis, 'navigator', { value: { getGamepads: () => { throw new Error('gamepad failure'); } }, configurable: true, writable: true });
  frames.shift()();
  assert.equal(logged.mock.callCount(), 1);
  assert.equal(logged.mock.calls[0].arguments[0], 'Tetris gamepad error:');
  assert.equal(logged.mock.calls[0].arguments[1].message, 'gamepad failure');
  assert.equal(frames.length, 1, 'the next poll is still scheduled');
  Object.defineProperty(globalThis, 'navigator', { value: { getGamepads: () => pads }, configurable: true, writable: true });
  pads[0] = gamepad({ pressed: ['a'] });
  frames.shift()();
  assert.deepEqual(manager.actions, [PlayerAction.drop]);
});

test('releasing left while right is still held moves right again [INP-2]', t => {
  const { manager, key } = setup(t);
  key('KeyD');
  key('KeyA');
  key('KeyA', false);
  assert.deepEqual(manager.actions, [PlayerAction.moveRight, PlayerAction.moveLeft, PlayerAction.moveRight]);
});

test('pressing a direction that is already moving does not add an extra move [INP-2] [INP-4]', t => {
  const { manager, controller, key, pads } = setup(t);
  pads[0] = gamepad({ x: -1 });
  controller.pollGamepads();
  key('KeyA');
  assert.deepEqual(manager.actions, [PlayerAction.moveLeft]);
});

test('holding the stick down keeps one steady soft drop [INP-4]', t => {
  const { manager, controller, pads, tick } = setup(t);
  pads[0] = gamepad({ y: 1 });
  for (let i = 0; i < 5; i++) controller.pollGamepads();
  tick(100);
  assert.equal(count(manager, 'softDrop'), 2);
});

test('a browser without gamepad support, or a gamepad without a stick, does nothing [INP-4]', t => {
  const { manager, controller, pads } = setup(t);
  pads[0] = { ...gamepad(), axes: [] };
  assert.equal(controller.pollGamepads(), true);
  Object.defineProperty(globalThis, 'navigator', { value: {}, configurable: true, writable: true });
  assert.equal(controller.pollGamepads(), false);
  assert.deepEqual(manager.actions, []);
});

test('the first connected gamepad is used, skipping empty and disconnected slots [INP-4]', t => {
  const { manager, controller, pads } = setup(t);
  pads[0] = null;
  pads[1] = { ...gamepad({ pressed: ['a'] }), connected: false };
  pads[2] = gamepad({ pressed: ['b'] });
  controller.pollGamepads();
  assert.deepEqual(manager.actions, [PlayerAction.rotate]);
});

test('a gamepad with fewer buttons than the standard layout still works [INP-4]', t => {
  const { manager, controller, pads } = setup(t);
  pads[0] = { connected: true, buttons: [{ pressed: true }, { pressed: false }], axes: [0, 0] };
  controller.pollGamepads();
  assert.deepEqual(manager.actions, [PlayerAction.drop]);
});

test('the stick does nothing until pushed past halfway [INP-4]', t => {
  const { manager, controller, pads, tick } = setup(t);
  for (const [x, y] of [[-0.5, 0], [0.5, 0], [0, 0.5]]) {
    pads[0] = gamepad({ x, y });
    controller.pollGamepads();
  }
  tick(500);
  assert.deepEqual(manager.actions, []);
});

test('letting the stick return to the middle stops moving without any other action [INP-4]', t => {
  const { manager, controller, pads, tick } = setup(t);
  pads[0] = gamepad({ x: 1 });
  controller.pollGamepads();
  pads[0] = gamepad();
  controller.pollGamepads();
  tick(500);
  assert.deepEqual(manager.actions, [PlayerAction.moveRight]);
});

test('letting the stick return to the middle goes back to a move key still held [INP-2] [INP-4]', t => {
  const { manager, controller, key, pads, tick } = setup(t);
  key('KeyA');
  pads[0] = gamepad({ x: 1 });
  controller.pollGamepads();
  pads[0] = gamepad();
  controller.pollGamepads();
  assert.deepEqual(manager.actions, [PlayerAction.moveLeft, PlayerAction.moveRight, PlayerAction.moveLeft]);
  tick(167);
  assert.equal(count(manager, PlayerAction.moveLeft), 3, 'still repeating left');
});

test('polling a resting stick never starts a move on its own, even with a key still held [INP-2] [INP-4]', t => {
  const { manager, controller, key, pads, tick } = setup(t);
  pads[0] = gamepad();
  key('KeyA');
  manager.state = GameState.paused;
  tick(200); // the repeat notices the pause and stops
  manager.state = GameState.playing;
  for (let i = 0; i < 10; i++) controller.pollGamepads();
  tick(200);
  assert.equal(count(manager, PlayerAction.moveLeft), 1);
});

test('releasing a move key goes back to the stick while it is still pushed [INP-2] [INP-4]', t => {
  const { manager, controller, key, pads, tick } = setup(t);
  pads[0] = gamepad({ x: -1 });
  controller.pollGamepads();
  key('KeyD');
  key('KeyD', false);
  assert.deepEqual(manager.actions, [PlayerAction.moveLeft, PlayerAction.moveRight, PlayerAction.moveLeft]);
  tick(167);
  assert.equal(count(manager, PlayerAction.moveLeft), 3, 'still repeating left');
});

test('after a pause stops a held key repeating, the stick can move the piece again [INP-2] [INP-4]', t => {
  const { manager, controller, key, pads, tick } = setup(t);
  key('KeyD');
  manager.state = GameState.paused;
  tick(200); // the repeat notices the pause and stops
  manager.state = GameState.playing;
  pads[0] = gamepad({ x: 1 });
  controller.pollGamepads();
  assert.deepEqual(manager.actions, [PlayerAction.moveRight, PlayerAction.moveRight]);
});
