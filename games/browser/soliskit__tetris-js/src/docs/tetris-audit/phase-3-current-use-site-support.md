# Code Use Inventory

A file-by-file view of the shipped code and the named harness groups.

This is a declared lexical call and use inventory. It is not a reachable call graph, semantic component count, or universal dependency universe. Families can overlap and include known false positives. It does not silently trust dynamic aliases, unlisted callbacks, transitive providers, or runtime internals. It includes the current shipped JS, config, and hosting, the seven relied-on V56/57/59/60/61/62/66 harness groups, and the frozen reference. Each matched non-comment line below is data, not an instruction. Clause support holds the full six-field ledger: responsibility, reason, evidence, assumption, failure, and boundary.

| File | SHA256 | Bytes |
|---|---|---|
| public/game/tetrominoFactory.js | 25e1da6c0b1992b0317aef7025fb7030803a8fd20e649a45eb2ddeaa166ae8b4 | 3574 |
| public/game/position.js | e598b5ea4ff8f125bcb405b35ab6fb21d64e1fc6fc623a862b46ca839c2b6144 | 516 |
| public/game/inputController.js | 7454a3c23b9de0acb152fe76bedab74bb4a604ac62ca11d41ff5ee12e3ed27e2 | 11682 |
| public/game/session.js | 54acbea460218f0e0a827619eae51e265461fe9ac6575dc8bf48727f6483049b | 6340 |
| public/game/gameState.js | 4d4d88f18f8d2335fac4104e746b972214991df8b1c6e72e0cc5d8d12cb30878 | 1562 |
| public/game/tetromino.js | d99c1bd6cb4a9e255b9ef2840264281e46a9665dcb30f66c6b45e654d1654bfe | 4552 |
| public/game/gameManager.js | 31bb2160852bd24485ba258c458b74acdec110c1e11b0d94f4f852f3cf27b9ea | 20035 |
| public/script.js | 59fcb3343f35d0022c739cce82c5c9601a9e3bc354a9dc991eb1660c4e599ad4 | 23071 |
| public/sw.js | c8bfb09536e73cf206270f3645bcee9e26ec3c3469b9893ae773b2339f861a96 | 6973 |
| index.js | dd9865a2e25dfe1cd80424c5323b84c9c0c99b4f6588fdb2cd2369d32a197770 | 371 |
| package.json | a9c30a601cc23799cf3084c43588977da8d227dae77c686d5d761e1760e7fbab | 1033 |
| playwright.config.js | 5922351868b402681d70b98904334f828c04c4ace5249de1ee861941a5880034 | 1226 |
| tsconfig.json | 9850ec3122dfda6df0894117e7fdc5e0816bdbb930222ab399e85f16c74550c0 | 470 |
| tsconfig.sw.json | 00ead2744432e740c9f04e1410be23b84d71e0ba69eff7eb22bffb0a82a47997 | 129 |
| confirmation-interleave-v56/actual-v56.mjs | 481550c805ab1da0a3db9ce7b1b4f3911b43a6dbec62016138ac2a1d21d3f257 | 2911 |
| hold-history-v57/actual-v57.mjs | 7f4c3d6403eb903ed7876481318c58ef609a91fd494d48d2762eb2ff48dd3ca3 | 1600 |
| hold-history-v57/independent-v57.py | 8fb745b93018707300fdb6f795d224138db4cc01fdff6e412e2b990210798eb1 | 1911 |
| rotation-history-v62/actual-v62.mjs | 3c754ac72b21b99127a0fcad08fd56fad379e3596136fdd6e9f0c3dfb6a68f49 | 1820 |
| rotation-history-v62/independent-v62.py | ec72ba9e9e6752d5fabc4cbcf1b5f42bef09f2f87b43ef11c0156e581230953e | 1382 |
| gesture-evidence-v59/actual-v59.mjs | d1d3eb03f757dc053ef5b9a6dc97301cb5ac45ffac901d1844e8496150986b9b | 3678 |
| gesture-evidence-v59/independent-v59.py | 38cb0223a0e862418260afb1ad9e5c1d43da352ef884a759e01462ebb6cb935e | 1458 |
| cache-full-resource-v60/actual-v60.mjs | 85b0d3501917b71ecc8eda60753d10470b5750c01d83c4935db4cd95ee813396 | 3735 |
| cache-full-resource-v60/independent-v60.py | 7bc9291bce9ac21bb76580881a3688056ff79a3ce435b7fbf4a599f139e63e80 | 1180 |
| render-idle-v61/actual-v61.mjs | 43d40dfca3fab34f859e4dbd7cdb19d433662320a2be6291ea38e845d1468e29 | 3956 |
| render-idle-v61/independent-v61.py | 6270afcf3216b420abfa45efa7254fa0f59d349146f5d9c497f7b2c3d44ee8c4 | 2962 |
| legacy-semantic-v66/actual-v66.mjs | 890cea1be3406fd9e43cb02d7caa0c9e70fcc07ced66930551207c58c7d5dc5f | 1783 |
| legacy-semantic-v66/independent-v66.py | 94201f40a884dd6b6ffe418b2a44035048aeb06e47bcf7ac3d56376da57fc82a | 3341 |
| frozen-rev6/o8_reference_model_rev6.py | f958f910a7a8ae02e2abd4a25a82f4f6127d5ff41440d45008cb92e4b63e93d2 | 27875 |

| File:line | Matched family | Actual source text |
|---|---|---|
| public/game/tetrominoFactory.js:5 | module-language, python-model-adapter | import { position } from './position.js'; |
| public/game/tetrominoFactory.js:6 | module-language, python-model-adapter | import { Tetromino } from './tetromino.js'; |
| public/game/tetrominoFactory.js:12 | module-language | export const PieceColors = Object.freeze({ |
| public/game/tetrominoFactory.js:83 | module-language, rng |     const j = Math.floor(random() * (i + 1)); |
| public/game/tetrominoFactory.js:91 | rng |   constructor(random = Math.random) { |
| public/game/tetrominoFactory.js:92 | rng |     this.random = random; |
| public/game/tetrominoFactory.js:100 | rng |       this.bag = shuffle(allPieces(), this.random); |
| public/game/inputController.js:14 | module-language, python-model-adapter | import { GameState, PlayerAction } from './gameState.js'; |
| public/game/inputController.js:51 | module-language | /** @type {Array<[string, PlayerActionValue]>} */ |
| public/game/inputController.js:76 | module-language |     /** @type {Set<string>} */ |
| public/game/inputController.js:77 | module-language |     this.heldKeys = new Set(); |
| public/game/inputController.js:78 | module-language |     /** @type {Set<string>} */ |
| public/game/inputController.js:79 | module-language |     this.heldButtons = new Set(); |
| public/game/inputController.js:85 | dom-focus-event |     window.addEventListener('keydown', event => this.handleKey(event, true)); |
| public/game/inputController.js:86 | dom-focus-event |     window.addEventListener('keyup', event => this.handleKey(event, false)); |
| public/game/inputController.js:87 | dom-focus-event |     window.addEventListener('blur', () => this.releaseAllInput()); |
| public/game/inputController.js:88 | dom-focus-event, pad |     window.addEventListener('gamepaddisconnected', () => this.releaseAllInput()); |
| public/game/inputController.js:89 | dom-focus-event, pad |     window.addEventListener('gamepadconnected', () => this.startPolling()); |
| public/game/inputController.js:107 | console |         console.error('Tetris gamepad error:', error); |
| public/game/inputController.js:109 | scheduler-clock |       if (connected) requestAnimationFrame(poll); |
| public/game/inputController.js:112 | scheduler-clock |     requestAnimationFrame(poll); |
| public/game/inputController.js:137 | dom-focus-event |         event.preventDefault(); |
| public/game/inputController.js:139 | dom-focus-event |         event.preventDefault(); |
| public/game/inputController.js:142 | dom-focus-event |         event.preventDefault(); |
| public/game/inputController.js:150 | dom-focus-event |     event.preventDefault(); |
| public/game/inputController.js:172 | pad |     if (!navigator.getGamepads) return false; // no gamepad support in this browser |
| public/game/inputController.js:173 | pad |     const gamepad = navigator.getGamepads().find(pad => pad?.connected); |
| public/game/inputController.js:175 | module-language |     const pressed = new Set( |
| public/game/inputController.js:176 | module-language |       Object.entries(PAD_BUTTONS) |
| public/game/inputController.js:177 | pad |         .filter(([, index]) => gamepad.buttons[index]?.pressed) |
| public/game/inputController.js:181 | pad |     this.processInput(pressed, gamepad.axes[0] ?? 0, -(gamepad.axes[1] ?? 0)); |
| public/game/inputController.js:191 | module-language |     const newPresses = new Set([...pressed].filter(button => !this.heldButtons.has(button))); |
| public/game/inputController.js:225 | module-language |       const actions = new Set(PAD_ACTIONS.filter(([button]) => newPresses.has(button)).map(([, action]) => action)); |
| public/game/inputController.js:260 | scheduler-clock |     clearTimeout(this.movementTimer); |
| public/game/inputController.js:268 | scheduler-clock |       this.movementTimer = setTimeout(repeat, ARR_INTERVAL_MS); |
| public/game/inputController.js:270 | scheduler-clock |     this.movementTimer = setTimeout(repeat, DAS_DELAY_MS); |
| public/game/inputController.js:274 | scheduler-clock |     clearTimeout(this.movementTimer); |
| public/game/inputController.js:291 | scheduler-clock |     this.softDropTimer = setInterval(() => { |
| public/game/inputController.js:301 | scheduler-clock |     clearInterval(this.softDropTimer); |
| public/game/inputController.js:308 | module-language |     this.heldButtons = new Set(); |
| public/game/session.js:6 | module-language, python-model-adapter | import { UPCOMING_COUNT } from './gameState.js'; |
| public/game/session.js:7 | module-language, python-model-adapter | import { position } from './position.js'; |
| public/game/session.js:8 | module-language, python-model-adapter | import { allPieces } from './tetrominoFactory.js'; |
| public/game/session.js:30 | module-language |   return JSON.stringify({ |
| public/game/session.js:48 | module-language | const isObject = value => typeof value === 'object' && value !== null && !Array.isArray(value); |
| public/game/session.js:54 | module-language | const isInteger = value => Number.isInteger(value); |
| public/game/session.js:60 | module-language | const isSafeInteger = value => Number.isSafeInteger(value); |
| public/game/session.js:77 | module-language |   if (!Array.isArray(board) &#124;&#124; board.length !== rows) return null; |
| public/game/session.js:78 | module-language |   /** @type {Set<unknown>} */ |
| public/game/session.js:79 | module-language |   const colors = new Set(allPieces().map(piece => piece.color)); |
| public/game/session.js:83 | module-language |     if (!Array.isArray(row) &#124;&#124; row.length !== columns) return null; |
| public/game/session.js:134 | module-language |   if (!Array.isArray(colors) &#124;&#124; new Set(colors).size !== colors.length) return null; |
| public/game/session.js:151 | module-language |     data = JSON.parse(/** @type {string} */ (text)); |
| public/game/session.js:163 | module-language |   if (!Array.isArray(data.nextTetrominos) &#124;&#124; data.nextTetrominos.length !== UPCOMING_COUNT) return null; |
| public/game/gameState.js:6 | module-language | export const GameState = Object.freeze(/** @type {const} */ ({ |
| public/game/gameState.js:14 | module-language | export const PlayerAction = Object.freeze(/** @type {const} */ ({ |
| public/game/gameState.js:43 | module-language |   return Array.from({ length: rows }, () => Array.from({ length: columns }, emptyCell)); |
| public/game/tetromino.js:6 | module-language, python-model-adapter | import { position } from './position.js'; |
| public/game/tetromino.js:7 | module-language, python-model-adapter | import { cellAt } from './gameState.js'; |
| public/game/tetromino.js:63 | module-language |     piece.position = position(0, Math.max(0, Math.trunc((columns - width) / 2))); |
| public/game/tetromino.js:135 | module-language |     /** @type {Array<[number, Position[]]>} */ |
| public/game/gameManager.js:10 | module-language, python-model-adapter | import { below, position } from './position.js'; |
| public/game/gameManager.js:11 | module-language, python-model-adapter | import { GameState, PlayerAction, UPCOMING_COUNT, createBoard } from './gameState.js'; |
| public/game/gameManager.js:12 | module-language, python-model-adapter | import { parseSession, serializeSession } from './session.js'; |
| public/game/gameManager.js:13 | module-language, python-model-adapter | import { TetrominoFactory } from './tetrominoFactory.js'; |
| public/game/gameManager.js:20 | scheduler-clock | /** @typedef {{ setTimeout(callback: () => void, ms: number): unknown, clearTimeout(handle: unknown): void }} Scheduler */ |
| public/game/gameManager.js:42 | module-language |   /** @type {Map<string, string>} */ |
| public/game/gameManager.js:43 | module-language |   const values = new Map(); |
| public/game/gameManager.js:48 | module-language |     setItem: (key, value) => { values.set(key, String(value)); }, |
| public/game/gameManager.js:57 | storage |     if (globalThis.localStorage) return globalThis.localStorage; |
| public/game/gameManager.js:66 | scheduler-clock |   setTimeout: (callback, ms) => globalThis.setTimeout(callback, ms), |
| public/game/gameManager.js:67 | scheduler-clock |   clearTimeout: handle => globalThis.clearTimeout(/** @type {number} */ (handle)) |
| public/game/gameManager.js:72 | console |   console.error('Tetris stopped safely:', fault.reason, fault.error ?? ''); |
| public/game/gameManager.js:119 | module-language |     return Math.floor(this.score / 1000) + 1; |
| public/game/gameManager.js:123 | module-language |     return Array.from({ length: UPCOMING_COUNT }, () => this.factory.generate()); |
| public/game/gameManager.js:135 | storage |       return this.storage.getItem(key); |
| public/game/gameManager.js:143 | module-language |     const value = Number(this.readItem(HIGH_SCORE_KEY)); |
| public/game/gameManager.js:144 | module-language |     return Number.isSafeInteger(value) ? Math.max(value, 0) : 0; |
| public/game/gameManager.js:150 | module-language, storage |       this.storage.setItem(HIGH_SCORE_KEY, String(value)); |
| public/game/gameManager.js:167 | module-language, storage |       this.storage.setItem(IS_SESSION_SAVED_KEY, String(value)); |
| public/game/gameManager.js:179 | module-language |     return Math.max(0.25, 0.7 - 0.02 * (this.level - 1)); |
| public/game/gameManager.js:221 | storage |       this.storage.setItem(SAVED_SESSION_KEY, serializeSession(this)); |
| public/game/gameManager.js:264 | scheduler-clock |     this.scheduler.clearTimeout(this.lockDelayTask); |
| public/game/gameManager.js:313 | scheduler-clock |     this.scheduler.clearTimeout(this.lockDelayTask); |
| public/game/gameManager.js:349 | module-language |     this.highScore = Math.max(this.highScore, this.score); |
| public/game/gameManager.js:370 | scheduler-clock |     this.scheduler.clearTimeout(this.gameLoopTask); |
| public/game/gameManager.js:383 | scheduler-clock |     return this.scheduler.setTimeout(() => this.guard(callback), ms); |
| public/game/gameManager.js:414 | module-language |     if (!Array.isArray(board) &#124;&#124; board.length !== this.rows &#124;&#124; !board.every(row => Array.isArray(row) && row.length === this.columns)) { |
| public/game/gameManager.js:418 | module-language |     if (!Number.isSafeInteger(this.score) &#124;&#124; this.score < 0 &#124;&#124; this.score % 100 !== 0) return 'score is invalid'; |
| public/script.js:4 | module-language, python-model-adapter | import { GameManager } from './game/gameManager.js'; |
| public/script.js:5 | module-language, python-model-adapter | import { GameState, PlayerAction } from './game/gameState.js'; |
| public/script.js:6 | module-language, python-model-adapter | import { InputController } from './game/inputController.js'; |
| public/script.js:16 | dom-focus-event | const element = id => /** @type {HTMLElement} */ (document.getElementById(id)); |
| public/script.js:18 | dom-focus-event | const canvasElement = id => /** @type {HTMLCanvasElement} */ (document.getElementById(id)); |
| public/script.js:38 | module-language | /** @type {Map<HTMLCanvasElement, CanvasRenderingContext2D>} */ |
| public/script.js:39 | module-language, canvas-layout | const contexts = new Map(canvases.map(canvas => [canvas, /** @type {CanvasRenderingContext2D} */ (canvas.getContext('2d', { colorSpace: 'display-p3' }))])); |
| public/script.js:44 | module-language | /** @type {WeakSet<CanvasRenderingContext2D>} */ |
| public/script.js:45 | module-language, canvas-layout | const p3Contexts = new WeakSet([...contexts.values()].filter(context => context.getImageData(0, 0, 1, 1).colorSpace === 'display-p3')); |
| public/script.js:49 | module-language | /** @type {Map<HTMLCanvasElement, CanvasSize>} */ |
| public/script.js:50 | module-language | const canvasSizes = new Map(); |
| public/script.js:64 | canvas-layout |   const ratio = window.devicePixelRatio; |
| public/script.js:65 | module-language |   canvas.width = Math.round(width * ratio); |
| public/script.js:66 | module-language |   canvas.height = Math.round(height * ratio); |
| public/script.js:69 | canvas-layout |   context.setTransform(ratio, 0, 0, ratio, 0, 0); |
| public/script.js:76 | module-language | /** @type {Map<string, string>} */ |
| public/script.js:77 | module-language | const vividColors = new Map(); |
| public/script.js:103 | canvas-layout |   context.roundRect(x, y, size, size, radius); |
| public/script.js:116 | canvas-layout |   context.fill(); |
| public/script.js:132 | canvas-layout |   context.stroke(); |
| public/script.js:143 | module-language |   const blockSize = Math.min(width / columns, height / rows); |
| public/script.js:157 | canvas-layout |   context.stroke(); |
| public/script.js:186 | module-language |   const blockSize = Math.min(width / gridSize, height / gridSize); |
| public/script.js:226 | dom-focus-event |   if (gameManager.isConfirmingNewGame !== newGameDialog.open) { |
| public/script.js:227 | dom-focus-event |     if (gameManager.isConfirmingNewGame) newGameDialog.showModal(); |
| public/script.js:228 | dom-focus-event |     else newGameDialog.close(); |
| public/script.js:240 | wake | let wakeLockWanted = false; |
| public/script.js:242 | wake | let wakeLock = null; |
| public/script.js:246 | wake |   if (wanted === wakeLockWanted &#124;&#124; !('wakeLock' in navigator)) return; |
| public/script.js:247 | wake |   wakeLockWanted = wanted; |
| public/script.js:253 | wake |   const lock = wakeLock; |
| public/script.js:254 | wake |   wakeLock = null; |
| public/script.js:259 | wake |   navigator.wakeLock.request('screen').then(sentinel => { |
| public/script.js:261 | wake |     if (!wakeLockWanted &#124;&#124; wakeLock) { |
| public/script.js:262 | wake |       sentinel.release(); |
| public/script.js:265 | wake |     wakeLock = sentinel; |
| public/script.js:268 | dom-focus-event, wake |     sentinel.addEventListener('release', () => { |
| public/script.js:269 | wake |       if (wakeLock !== sentinel) return; |
| public/script.js:270 | wake |       wakeLock = null; |
| public/script.js:285 | module-language | /** @type {Map<HTMLCanvasElement, Tetromino &#124; null>} */ |
| public/script.js:286 | module-language | const drawnPreviews = new Map(); |
| public/script.js:310 | module-language |   /** @type {Array<[HTMLCanvasElement, Tetromino &#124; null]>} */ |
| public/script.js:344 | console |     if (!renderErrorReported) console.error('Tetris drawing error, retrying next frame:', error); |
| public/script.js:358 | scheduler-clock |   requestAnimationFrame(() => { |
| public/script.js:365 | canvas-layout | const resizeObserver = new ResizeObserver(entries => { |
| public/script.js:377 | dom-focus-event, canvas-layout |   matchMedia(&#96;(resolution: ${window.devicePixelRatio}dppx)&#96;).addEventListener('change', () => { |
| public/script.js:396 | pointer |   pointerId: null, |
| public/script.js:408 | pointer |   drag.pointerId = null; |
| public/script.js:431 | dom-focus-event | boardCanvas.addEventListener('pointerdown', event => { |
| public/script.js:433 | pointer |   drag.pointerId = event.pointerId; |
| public/script.js:435 | pointer |   drag.startX = event.clientX; |
| public/script.js:436 | pointer |   drag.startY = event.clientY; |
| public/script.js:437 | pointer |   boardCanvas.setPointerCapture(event.pointerId); |
| public/script.js:440 | dom-focus-event | boardCanvas.addEventListener('pointermove', event => { |
| public/script.js:441 | pointer |   if (event.pointerId !== drag.pointerId &#124;&#124; !canvasSizes.has(boardCanvas)) return; |
| public/script.js:446 | pointer |   const dx = event.clientX - drag.startX; |
| public/script.js:447 | pointer |   const dy = event.clientY - drag.startY; |
| public/script.js:448 | module-language |   if (!drag.moved && Math.hypot(dx, dy) < TAP_SLOP_PX) return; |
| public/script.js:452 | pointer |   let offset = (event.clientX - drag.startX) / width; |
| public/script.js:453 | module-language |   if (drag.blocked !== 0 && Math.sign(offset - drag.cellOffset) === drag.blocked) { |
| public/script.js:461 | pointer |     drag.startX = event.clientX - drag.cellOffset * width; |
| public/script.js:466 | module-language |   const targetOffset = Math.round(offset); |
| public/script.js:468 | module-language |     const step = Math.sign(targetOffset - drag.cellOffset); |
| public/script.js:471 | pointer |       drag.startX = event.clientX - drag.cellOffset * width; |
| public/script.js:478 | module-language |   const newRowOffset = Math.max(0, Math.trunc(dy / width)); |
| public/script.js:487 | pointer |   if (event.pointerId !== drag.pointerId) return; |
| public/script.js:493 | dom-focus-event | boardCanvas.addEventListener('pointerup', endDrag); |
| public/script.js:494 | dom-focus-event | boardCanvas.addEventListener('pointercancel', endDrag); |
| public/script.js:496 | dom-focus-event | heldCanvas.addEventListener('click', () => gameManager.handleAction(PlayerAction.hold)); |
| public/script.js:502 | dom-focus-event | heldCanvas.addEventListener('mousedown', event => event.preventDefault()); |
| public/script.js:503 | dom-focus-event | heldCanvas.addEventListener('keydown', event => { |
| public/script.js:505 | dom-focus-event |   event.preventDefault(); |
| public/script.js:509 | dom-focus-event | element('newGameButton').addEventListener('click', () => gameManager.handleAction(PlayerAction.newGame)); |
| public/script.js:519 | dom-focus-event | confirmNewGameButton.addEventListener('click', () => gameManager.handleAction(PlayerAction.newGame)); |
| public/script.js:520 | dom-focus-event | cancelNewGameButton.addEventListener('click', () => gameManager.cancelNewGame()); |
| public/script.js:528 | dom-focus-event |     const index = questionButtons.indexOf(/** @type {HTMLElement} */ (document.activeElement)); |
| public/script.js:529 | module-language, dom-focus-event |     questionButtons[Math.max(0, Math.min(questionButtons.length - 1, index + step))].focus(); |
| public/script.js:531 | dom-focus-event |   press: () => questionButtons.find(button => button === document.activeElement)?.click() |
| public/script.js:533 | dom-focus-event | newGameDialog.addEventListener('click', event => { |
| public/script.js:536 | dom-focus-event | newGameDialog.addEventListener('cancel', event => { |
| public/script.js:537 | dom-focus-event |   event.preventDefault(); |
| public/script.js:540 | dom-focus-event | continueButton.addEventListener('click', () => gameManager.handleAction(PlayerAction.continueGame)); |
| public/script.js:541 | dom-focus-event | playPauseButton.addEventListener('click', () => gameManager.togglePause()); |
| public/script.js:544 | dom-focus-event | document.addEventListener('visibilitychange', () => { |
| public/script.js:545 | dom-focus-event |   if (document.visibilityState === 'visible') return; |
| public/script.js:552 | dom-focus-event | window.addEventListener('storage', () => { |
| public/script.js:567 | canvas-layout | const viewport = /** @type {VisualViewport} */ (window.visualViewport); |
| public/script.js:569 | dom-focus-event | const watchZoom = () => document.documentElement.classList.toggle('zoomed', zoomedIn()); |
| public/script.js:570 | dom-focus-event | viewport.addEventListener('resize', watchZoom); |
| public/script.js:575 | dom-focus-event |   document.addEventListener(type, event => { |
| public/script.js:576 | dom-focus-event |     if (!zoomedIn()) event.preventDefault(); |
| public/script.js:586 | dom-focus-event | boardCanvas.addEventListener('click', () => {}); |
| public/script.js:589 | cache-network-worker | if ('serviceWorker' in navigator) { |
| public/script.js:590 | cache-network-worker |   navigator.serviceWorker.register('sw.js').catch(() => {}); |
| public/sw.js:48 | module-language | /** @returns {Promise<string[]>} Every version cache, oldest first. */ |
| public/sw.js:50 | cache-network-worker |   const names = (await caches.keys()).filter(name => name.startsWith(VERSION_PREFIX)); |
| public/sw.js:56 | module-language | /** @returns {Promise<string[]>} Every complete version, newest first. */ |
| public/sw.js:61 | dom-focus-event, cache-network-worker |     if ((await (await caches.open(name)).keys()).length > 0) complete.push(name); |
| public/sw.js:66 | module-language | /** @returns {Promise<string &#124; null>} */ |
| public/sw.js:79 | module-language, scheduler-clock, dom-focus-event, cache-network-worker |   await (await caches.open(PINS)).put(pinKey(clientId), Response.json({ version, at: Date.now() })); |
| public/sw.js:88 | cache-network-worker |   const pinned = clientId ? await caches.match(pinKey(clientId), { cacheName: PINS }) : undefined; |
| public/sw.js:90 | cache-network-worker |   return version && await caches.has(version) ? version : newestVersion(); |
| public/sw.js:98 | cache-network-worker |   const cached = version ? await caches.match(request, { cacheName: version, ignoreSearch: true }) : undefined; |
| public/sw.js:100 | module-language, cache-network-worker |   return cached ?? fetch(request).catch(() => Response.error()); |
| public/sw.js:118 | module-language |   const kept = new Set(complete.slice(0, 2)); |
| public/sw.js:119 | dom-focus-event, cache-network-worker |   const pins = await caches.open(PINS); |
| public/sw.js:124 | scheduler-clock |     if (Date.now() - at > PIN_MS) await pins.delete(key); |
| public/sw.js:128 | cache-network-worker |     if (versionNumber(name) < versionNumber(newest) && !kept.has(name)) await caches.delete(name); |
| public/sw.js:140 | rng |   const name = &#96;${VERSION_PREFIX}${number}-${Math.random().toString(36).slice(2)}&#96;; |
| public/sw.js:142 | module-language, dom-focus-event, cache-network-worker |     await (await caches.open(name)).addAll(APP_SHELL.map(file => new Request(file, { cache: 'no-cache' }))); |
| public/sw.js:144 | cache-network-worker |     await caches.delete(name); |
| public/sw.js:151 | dom-focus-event | worker.addEventListener('install', event => { |
| public/sw.js:152 | cache-network-worker |   event.waitUntil(download()); |
| public/sw.js:153 | cache-network-worker |   worker.skipWaiting(); |
| public/sw.js:159 | dom-focus-event | worker.addEventListener('activate', event => { |
| public/sw.js:160 | module-language, cache-network-worker |   event.waitUntil(Promise.all(OLD_CACHES.map(name => caches.delete(name))) |
| public/sw.js:161 | cache-network-worker |     .then(() => worker.clients.claim())); |
| public/sw.js:164 | dom-focus-event | worker.addEventListener('fetch', event => { |
| public/sw.js:167 | cache-network-worker |     event.respondWith(versionFor(event.clientId).then(version => answer(event.request, version))); |
| public/sw.js:171 | cache-network-worker |   event.respondWith(opened); |
| public/sw.js:174 | cache-network-worker |   event.waitUntil(opened.then(() => download()).catch(() => {})); |
| index.js:1 | module-language, node-filesystem-hosting, python-model-adapter | import express from 'express'; |
| index.js:2 | module-language, node-filesystem-hosting, python-model-adapter | import path from 'node:path'; |
| index.js:3 | module-language, node-filesystem-hosting, python-model-adapter | import { fileURLToPath } from 'node:url'; |
| index.js:6 | node-filesystem-hosting | const app = express(); |
| index.js:8 | node-filesystem-hosting | const PORT = process.env.PORT &#124;&#124; 3000; |
| index.js:10 | node-filesystem-hosting | app.use(express.static(path.join(__dirname, 'public'))); |
| index.js:12 | node-filesystem-hosting | app.listen(PORT, () => { |
| index.js:13 | console |   console.log(&#96;Server is running on port ${PORT}&#96;); |
| package.json:14 | automation-evidence | 		"test:e2e": "playwright test && node scripts/browser-coverage.js", |
| package.json:22 | node-filesystem-hosting | 		"express": "^5.2.1" |
| package.json:28 | automation-evidence | 		"@playwright/test": "^1.63.0", |
| playwright.config.js:1 | module-language, automation-evidence, python-model-adapter | import { defineConfig } from '@playwright/test'; |
| playwright.config.js:9 | node-filesystem-hosting |   forbidOnly: !!process.env.CI, |
| playwright.config.js:11 | node-filesystem-hosting |   reporter: process.env.CI ? [['list'], ['github']] : 'list', |
| playwright.config.js:25 | automation-evidence |       use: { browserName: 'chromium', viewport: { width: 430, height: 932 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true } |
| playwright.config.js:29 | automation-evidence |       use: { browserName: 'chromium', viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1 } |
| playwright.config.js:34 | module-language |     env: { PORT: String(PORT) }, |
| playwright.config.js:36 | node-filesystem-hosting |     reuseExistingServer: !process.env.CI |
| confirmation-interleave-v56/actual-v56.mjs:1 | module-language, node-filesystem-hosting, automation-evidence, python-model-adapter | import {chromium} from '[held-local-source]';import {spawn} from 'node:child_process';import fs from 'node:fs';import {createHash} from 'node:crypto';import assert from 'node:assert/strict'; |
| confirmation-interleave-v56/actual-v56.mjs:2 | module-language, scheduler-clock, rng, dom-focus-event, console, node-filesystem-hosting, automation-evidence | const server=spawn('python3',['-m','http.server','4191','--bind','127.0.0.1','--directory','[held-local-source]'],{stdio:'ignore'});const b=await chromium.launch({executablePath:'/usr/bin/google-chrome',headless:true,args:['--no-sandbox']});try{const p=await b.newPage({viewport:{width:1000,height:900}});const errors=[];p.on('pageerror',e=>errors.push(e.message));await p.addInitScript(()=>Math.random=()=>.3);await p.clock.install({time:0});await p.clock.pauseAt(1000);await p.goto('http://127.0.0.1:4191');await p.evaluate(async()=>{const {GameManager}=await import('/game/gameManager.js');const h=GameManager.prototype.handleAction;GameManager.prototype.handleAction=function(...args){window.captureGM=this;return h.apply(this,args);};});await p.keyboard.press('Enter');await p.clock.runFor(40);await p.keyboard.press('Escape');await p.clock.runFor(40);const rows=await p.evaluate(()=>{const g=window.captureGM;const snap=tag=>({tag,mode:g.state,pending:g.isConfirmingNewGame,dialogOpen:document.querySelector('#newGameDialog').open,focus:document.activeElement.id,current:g.currentTetromino.color,currentPosition:g.currentTetromino.position,queue:g.nextTetrominos.map(x=>x.color),score:g.score,boardVersion:g.boardVersion,at:performance.now()});document.querySelector('#newGameButton').focus();const rows=[snap('paused-before')];document.querySelector('#newGameButton').click();rows.push(snap('after-first-public-click-before-frame'));document.querySelector('#newGameButton').click();rows.push(snap('after-second-public-click-before-frame'));return rows;});await p.clock.runFor(40);rows.push(await p.evaluate(()=>({tag:'after-frame',mode:window.captureGM.state,pending:window.captureGM.isConfirmingNewGame,dialogOpen:document.querySelector('#newGameDialog').open,focus:document.activeElement.id,at:performance.now()})));assert.equal(rows[0].mode,'paused');assert.equal(rows[1].pending,true);assert.equal(rows[1].dialogOpen,false);assert.equal(rows[1].focus,'newGameButton');assert.equal(rows[2].mode,'playing');assert.equal(rows[2].pending,false);assert.equal(rows[2].dialogOpen,false);const bindings=['game/gameManager.js','game/inputController.js','script.js','index.html'].map(n=>{const bytes=fs.readFileSync('[held-local-source]'+n);return {path:n,bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')};});console.log(JSON.stringify({browser:await b.version(),node:process.version,rows,errors,bindings,scope:'actualpublicDOM .click stand-in twiceonescript/preframe controlledclock andactualGMcapture; nottrustedmouse/nativehumanfrequency/linearizationcertification/visualproof'},null,2));}finally{await b.close();server.kill();} |
| hold-history-v57/actual-v57.mjs:1 | module-language, node-filesystem-hosting, python-model-adapter | import fs from 'node:fs';import {createHash} from 'node:crypto';import {GameManager,createMemoryStorage} from '[held-local-source]';import {TetrominoFactory} from '[held-local-source]'; |
| hold-history-v57/actual-v57.mjs:2 | module-language, scheduler-clock, console, node-filesystem-hosting | let id=0;const q=new Map(),scheduler={setTimeout(f,ms){const h=++id;q.set(h,{f,ms});return h;},clearTimeout(h){q.delete(h);}};const g=new GameManager({scheduler,storage:createMemoryStorage(),factory:new TetrominoFactory(()=>.3),onFault(){}});const snap=tag=>({tag,mode:g.state,current:{token:g.currentTetromino.color,rotation:g.currentTetromino.rotationState,position:g.currentTetromino.position},held:g.heldTetromino?.color??null,canHold:g.canHoldTetromino,count:g.lockDelayResetCount,lowestAnchor:g.lowestRowReached,queue:g.nextTetrominos.map(p=>p.color),bag:g.factory.bag.map(p=>p.color),faults:g.faults.length});const rows=[];g.handleAction('newGame');rows.push(snap('newgame'));g.handleAction('hold');rows.push(snap('emptyhold'));g.handleAction('hold');rows.push(snap('secondhold-noop'));g.handleAction('drop');rows.push(snap('afterlock'));g.handleAction('hold');rows.push(snap('heldswap'));const bindings=['gameManager.js','tetrominoFactory.js'].map(n=>{const b=fs.readFileSync('[held-local-source]'+n);return {path:n,bytes:b.length,sha256:createHash('sha256').update(b).digest('hex')};});console.log(JSON.stringify({node:process.version,rows,bindings,scope:'actualpublicactions realfactoryfixedrandom/controlledno timerdelivery; independentG6/historyanalysis separate; notallholdboards/rotation/sourcecentertie'},null,2)); |
| hold-history-v57/independent-v57.py:1 | module-language, python-model-adapter | import json,re,pathlib |
| hold-history-v57/independent-v57.py:2 | python-model-adapter | r=pathlib.Path('[held-local-source]');a=json.loads((r/'hold-history-v57/actual-v57.json').read_text());mapping={x['token']:x['uniqueKind'] for x in json.loads((r/'kind-evidence/kind-geometry-encoding-v40.json').read_text())['rows']};geom={};kind=None |
| hold-history-v57/independent-v57.py:3 | python-model-adapter | for line in pathlib.Path('[held-local-source]').read_text().splitlines(): |
| hold-history-v57/independent-v57.py:4 | python-model-adapter |  m=re.match(r'([IOTSLJZ]) \(box',line) |
| hold-history-v57/independent-v57.py:5 | python-model-adapter |  if m:kind=m[1];geom[kind]=[] |
| hold-history-v57/independent-v57.py:6 | python-model-adapter |  elif 'state ' in line:geom[kind].append([tuple(map(int,p)) for p in re.findall(r'\((\d+),(\d+)\)',line)]) |
| hold-history-v57/independent-v57.py:9 | python-model-adapter |  c=x['current'];k=mapping[c['token']];maximum=c['position']['row']+max(dr for dr,dc in geom[k][c['rotation']]);out.append({'tag':x['tag'],'kind':k,'sourceNewPieceCount':0,'actualCount':x['count'],'actualAnchor':x['lowestAnchor'],'sourceInitialOccupiedMaximum':maximum,'anchorIdentityEqual':x['lowestAnchor']==maximum,'boundedPossibleProjection':x['lowestAnchor']+max(dr for dr,dc in geom[k][c['rotation']])}) |
| hold-history-v57/independent-v57.py:14 | python-model-adapter | print(json.dumps({'rows':out,'emptyHoldQueueBagAndHeld':True,'secondHoldNoop':True,'heldSwapQueueBagFrame':True,'scope':'G6V40bind/currentgeometrysourceinitialmax; anchoridentityfalse notautomaticmismatch since boundedoffsetprojectionpossible; nohistoryrotationproof'},indent=2)) |
| rotation-history-v62/actual-v62.mjs:1 | module-language, node-filesystem-hosting, python-model-adapter | import fs from 'node:fs';import {createHash} from 'node:crypto';import {GameManager,createMemoryStorage} from '[held-local-source]';import {TetrominoFactory} from '[held-local-source]'; |
| rotation-history-v62/actual-v62.mjs:2 | module-language, scheduler-clock, console, node-filesystem-hosting | let id=0;const q=new Map(),scheduler={setTimeout(f,ms){const h=++id;q.set(h,{f,ms});return h;},clearTimeout(h){q.delete(h);}};const g=new GameManager({scheduler,storage:createMemoryStorage(),factory:new TetrominoFactory(()=>.3),onFault(){}});const snap=tag=>({tag,mode:g.state,current:{token:g.currentTetromino.color,rotation:g.currentTetromino.rotationState,position:g.currentTetromino.position},held:g.heldTetromino?.color??null,canHold:g.canHoldTetromino,count:g.lockDelayResetCount,lowestAnchor:g.lowestRowReached,queue:g.nextTetrominos.map(p=>p.color),bag:g.factory.bag.map(p=>p.color),faults:g.faults.length});const rows=[];g.handleAction('newGame');rows.push(snap('newgame'));g.handleAction('hold');rows.push(snap('emptyhold'));g.handleAction('hold');rows.push(snap('secondhold-noop'));g.handleAction('drop');rows.push(snap('afterlock'));g.handleAction('rotate');rows.push(snap('I-rotate-1'));g.handleAction('rotate');rows.push(snap('I-rotate-2'));g.handleAction('rotate');rows.push(snap('I-rotate-3'));g.handleAction('rotate');rows.push(snap('I-rotate-0-again'));const bindings=['gameManager.js','tetrominoFactory.js'].map(n=>{const b=fs.readFileSync('[held-local-source]'+n);return {path:n,bytes:b.length,sha256:createHash('sha256').update(b).digest('hex')};});console.log(JSON.stringify({node:process.version,rows,bindings,scope:'actualpublicrotationhistory afterknownIspawn actualpublicactions realfactoryfixedrandom/controlledno timerdelivery; independentG6/historyanalysis separate; notallholdboards/rotation/sourcecentertie'},null,2)); |
| rotation-history-v62/independent-v62.py:1 | module-language, python-model-adapter | import json,re,pathlib |
| rotation-history-v62/independent-v62.py:2 | python-model-adapter | r=pathlib.Path('[held-local-source]');a=json.loads((r/'rotation-history-v62/actual-v62.json').read_text());rows=a['rows'][3:];table=pathlib.Path('[held-local-source]').read_text().split('J (box')[0];geom=[[tuple(map(int,p)) for p in re.findall(r'\((\d+),(\d+)\)',line)] for line in table.splitlines() if 'state ' in line];hist=-1;out=[] |
| rotation-history-v62/independent-v62.py:4 | python-model-adapter |  cur=row['current'];assert cur['token']=='#00C0E8';occupied=cur['position']['row']+max(dr for dr,dc in geom[cur['rotation']]);hist=max(hist,occupied);projection=row['lowestAnchor']+max(dr for dr,dc in geom[cur['rotation']]);out.append({'tag':row['tag'],'rotation':cur['rotation'],'occupiedMaximum':occupied,'expectedHistoricalMaximum':hist,'actualAnchor':row['lowestAnchor'],'stateOffsetProjection':projection,'equal':hist==projection,'actualCount':row['count']}) |
| rotation-history-v62/independent-v62.py:6 | python-model-adapter | print(json.dumps({'rows':out,'sameCurrentAnchorCountDifferentExpectedHistory':True,'scope':'G6Ipublicfourrotationhistory, dynamicstateoffsetadapterfailsafterrot2/fullcircle; notallmemoryinjectivity/proofuniquefieldneeded/confirmeddefect'},indent=2)) |
| gesture-evidence-v59/actual-v59.mjs:1 | module-language, node-filesystem-hosting, automation-evidence, python-model-adapter | import {chromium} from '[held-local-source]';import {spawn} from 'node:child_process';import fs from 'node:fs';import {createHash} from 'node:crypto';import assert from 'node:assert/strict'; |
| gesture-evidence-v59/actual-v59.mjs:2 | module-language, rng, dom-focus-event, pointer, console, node-filesystem-hosting, automation-evidence | const server=spawn('python3',['-m','http.server','4192','--bind','127.0.0.1','--directory','[held-local-source]'],{stdio:'ignore'});const b=await chromium.launch({executablePath:'/usr/bin/google-chrome',headless:true,args:['--no-sandbox']});try{const p=await b.newPage({viewport:{width:1000,height:900}});const errors=[];p.on('pageerror',e=>errors.push(e.message));await p.addInitScript(()=>Math.random=()=>.3);await p.clock.install({time:0});await p.clock.pauseAt(1000);await p.goto('http://127.0.0.1:4192');await p.evaluate(async()=>{const {GameManager}=await import('/game/gameManager.js');const h=GameManager.prototype.handleAction;GameManager.prototype.handleAction=function(...args){window.captureGM=this;return h.apply(this,args);};});await p.keyboard.press('Enter');await p.clock.runFor(40);await p.keyboard.press('Escape');await p.clock.runFor(40);await p.keyboard.press('Escape');await p.clock.runFor(40);const box=await p.locator('#tetris').boundingBox();const w=box.width/10,x=box.x+5*w,y=box.y+3*w;await p.evaluate(()=>{window.pointerTrace=[];for(const kind of ['pointerdown','pointermove','pointerup','pointercancel'])document.querySelector('#tetris').addEventListener(kind,e=>window.pointerTrace.push({type:e.type,x:e.clientX,y:e.clientY,pointerId:e.pointerId,trusted:e.isTrusted}));});const snap=tag=>p.evaluate(tag=>({tag,state:window.captureGM.state,current:{token:window.captureGM.currentTetromino.color,rotation:window.captureGM.currentTetromino.rotationState,position:window.captureGM.currentTetromino.position},score:window.captureGM.score,faults:window.captureGM.faults.length}),tag);const wall=[await snap('before-wall')];await p.mouse.move(x,y);await p.mouse.down();await p.mouse.move(x+10*w,y);wall.push(await snap('push-right-to-wall'));await p.mouse.move(x+12*w,y);wall.push(await snap('push-more-blocked'));await p.mouse.move(x+11.4*w,y);wall.push(await snap('reverse-six-tenths-cell'));await p.mouse.up();await p.clock.runFor(40);const wallEvents=await p.evaluate(()=>window.pointerTrace);await p.evaluate(()=>window.pointerTrace=[]);const endpoint=[await snap('before-endpoint')];await p.mouse.move(x,y);await p.mouse.down();await p.evaluate(({x,y})=>{const trace=window.pointerTrace;const id=trace.findLast(e=>e.type==='pointerdown').pointerId;document.querySelector('#tetris').dispatchEvent(new PointerEvent('pointerup',{bubbles:true,pointerId:id,clientX:x+30,clientY:y,pointerType:'mouse'}));},{x,y});endpoint.push(await snap('after-distant-pointerup-no-move'));await p.mouse.up();const endpointEvents=await p.evaluate(()=>window.pointerTrace);assert.equal(wall[1].current.position.column,7);assert.equal(wall[2].current.position.column,7);assert.equal(wall[3].current.position.column,6);assert.equal(endpoint[1].current.rotation,(endpoint[0].current.rotation+1)%4);const bindings=['game/gameManager.js','game/inputController.js','script.js','index.html'].map(n=>{const bytes=fs.readFileSync('[held-local-source]'+n);return {path:n,bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')};});console.log(JSON.stringify({browser:await b.version(),node:process.version,box,cellWidth:w,wall,wallEvents,endpoint,endpointEvents,errors,bindings,scope:'actualmouse wallpath/pointercapture+syntheticdistantpointerup matchingactualdownID nointermediate move; controlledclock/GMsnapshot; nohardware/nativefrequency/visualpixelproof'},null,2));}finally{await b.close();server.kill();} |
| gesture-evidence-v59/independent-v59.py:1 | module-language, python-model-adapter | import json,pathlib,math |
| gesture-evidence-v59/independent-v59.py:2 | python-model-adapter | r=pathlib.Path('[held-local-source]');a=json.loads((r/'gesture-evidence-v59/actual-v59.json').read_text());mapping={v['token']:v['uniqueKind'] for v in json.loads((r/'kind-evidence/kind-geometry-encoding-v40.json').read_text())['rows']};assert mapping[a['wall'][0]['current']['token']]=='S' |
| gesture-evidence-v59/independent-v59.py:6 | python-model-adapter | print(json.dumps({'wallExpectedAnchors':expected,'wallActualAnchors':actual,'wallEqual':True,'wallExpectedFrom':'G6Sspan0..2 emptyboard boundedpath and unbankedreverse0.6cell','endpoint':{'distance':distance,'noIntermediateMove':not any(x['type']=='pointermove' for x in trace),'expectedTap':False,'expectedRotation':expectedRotation,'actualRotation':actualRotation,'equal':False,'downTrusted':down['trusted'],'upTrusted':up['trusted']},'scope':'specificactualpath/adoptedE1endpoint separate fromnativeeventplausibility/allgesturepixelclaim'},indent=2)) |
| cache-full-resource-v60/actual-v60.mjs:1 | module-language, node-filesystem-hosting, python-model-adapter | import fs from 'node:fs';import vm from 'node:vm';import {createHash} from 'node:crypto';import assert from 'node:assert/strict'; |
| cache-full-resource-v60/actual-v60.mjs:2 | module-language, node-filesystem-hosting, python-model-adapter | const source=fs.readFileSync('[held-local-source]','utf8'),base='https://fixture.invalid/game/',shell=['./','index.html','style.css','script.js','manifest.webmanifest','icons/icon.svg','icons/icon-192.png','icons/icon-512.png','icons/apple-touch-icon.png','game/gameManager.js','game/gameState.js','game/inputController.js','game/position.js','game/session.js','game/tetromino.js','game/tetrominoFactory.js'],abs=u=>new URL(typeof u==='string'?u:u.url,base).href,old='tetris-version-1-origin',states=new Map([[old,new Map(shell.map(u=>[abs(u),'V1:'+abs(u)]))]]),trace=[],handlers={},pending=[];let freshLabel='V2',now=1000; |
| cache-full-resource-v60/actual-v60.mjs:3 | module-language, dom-focus-event, cache-network-worker, automation-evidence, python-model-adapter | const open=async name=>{if(!states.has(name))states.set(name,new Map());let store=states.get(name);return {async keys(){return [...store].map(([u])=>({url:u}));},async match(k){const u=abs(k);return store.has(u)?new Response(store.get(u)):undefined;},async put(k,v){store.set(abs(k),await v.text());trace.push({op:'put',name,url:abs(k)});},async delete(k){return store.delete(abs(k));},addAll(reqs){trace.push({op:'addAll.begin',name,urls:reqs.map(abs)});return new Promise((resolve,reject)=>pending.push({name,reqs,label:freshLabel,resolve,reject}));}};};const caches={async keys(){return [...states.keys()];},open,async has(n){return states.has(n);},async match(k,opt){return (await open(opt.cacheName)).match(k);},async delete(n){trace.push({op:'delete',name:n});return states.delete(n);}};class R extends Request{constructor(u,opt){super(abs(u),opt);}}let random=.3;const self={addEventListener(k,f){handlers[k]=f;},skipWaiting(){},clients:{async claim(){}}};vm.runInNewContext(source,{self,caches,Request:R,Response,Date:{now:()=>now},Math:{...Math,random:()=>random},Promise,Set,encodeURIComponent,console,fetch:async r=>{trace.push({op:'network',url:r.url});return new Response('NETWORK:'+r.url);}}); |
| cache-full-resource-v60/actual-v60.mjs:4 | module-language, cache-network-worker | const navigation=async client=>{let response,wait;handlers.fetch({request:{method:'GET',mode:'navigate',url:abs('./')},clientId:'',resultingClientId:client,respondWith(p){response=p;},waitUntil(p){wait=p;}});const body=await(await response).text();return {body,wait};};const resource=async(client,url)=>{let response;handlers.fetch({request:new Request(abs(url)),clientId:client,respondWith(p){response=p;}});return {url:abs(url),body:await(await response).text()};};const all=async client=>{const a=[];for(const u of shell)a.push(await resource(client,u));return a;}; |
| cache-full-resource-v60/actual-v60.mjs:5 | module-language, console, node-filesystem-hosting, python-model-adapter | const first=await navigation('client1');const before=await all('client1');assert.equal(pending.length,1);const work=pending.shift();for(const req of work.reqs)states.get(work.name).set(abs(req),work.label+':'+abs(req));trace.push({op:'addAll.atomic-complete',name:work.name,label:work.label});work.resolve();await first.wait;const after=await all('client1');freshLabel='V3';random=.4;const second=await navigation('client2');const next=await all('client2');assert.equal(pending.length,1);pending.shift().reject(Error('stopunusedV3background'));await second.wait;for(const r of before.concat(after))assert.equal(r.body,'V1:'+r.url);for(const r of next)assert.equal(r.body,'V2:'+r.url);assert.ok(states.has(old));const pins=[...states.get('tetris-pins')];console.log(JSON.stringify({node:process.version,source:{bytes:Buffer.byteLength(source),sha256:createHash('sha256').update(source).digest('hex')},shell,firstHTML:first.body,before,after,secondHTML:second.body,next,pins,trace,afterNames:[...states.keys()],scope:'actualunchangedSWVM complete16URLs labelled delayedatomicaddAll/ordinarytime/pinretention/nextlaunch; no native/allconcurrency/clockjump/foreignmaliciouscache'},null,2)); |
| cache-full-resource-v60/independent-v60.py:1 | module-language, python-model-adapter | import json,pathlib |
| cache-full-resource-v60/independent-v60.py:2 | python-model-adapter | p=pathlib.Path('[held-local-source]');a=json.loads((p/'actual-v60.json').read_text());assert len(a['shell'])==16 and len(set(a['shell']))==16 |
| cache-full-resource-v60/independent-v60.py:4 | python-model-adapter |  rows=a[field];assert len(rows)==16 and {r['url'] for r in rows}=={'https://fixture.invalid/game/'+u if u!='./' else 'https://fixture.invalid/game/' for u in a['shell']};assert all(r['body']==label+':'+r['url'] for r in rows) |
| cache-full-resource-v60/independent-v60.py:6 | python-model-adapter | pins={key.split('/')[-1]:json.loads(value) for key,value in a['pins']};assert pins['client1']['version']=='tetris-version-1-origin';assert pins['client2']['version'].startswith('tetris-version-2-') |
| cache-full-resource-v60/independent-v60.py:7 | python-model-adapter | print(json.dumps({'resourcesPerPhase':16,'firstOpening':'V1','existingClientAfterCompletedUpdate':'V1','nextLaunch':'V2','originalVersionRetained':True,'pinClientBindings':pins,'noNetworkFallback':True,'scope':'complete-labelled atomicfixture ordinaryclock/sourcefullresource relation notversionintegrityorigin/authenticity/native/concurrency'},indent=2)) |
| render-idle-v61/actual-v61.mjs:1 | module-language, node-filesystem-hosting, automation-evidence, python-model-adapter | import {chromium} from '[held-local-source]';import {spawn} from 'node:child_process';import fs from 'node:fs';import {createHash} from 'node:crypto';import assert from 'node:assert/strict'; |
| render-idle-v61/actual-v61.mjs:2 | module-language, scheduler-clock, rng, storage, dom-focus-event, canvas-layout, console, node-filesystem-hosting, automation-evidence, python-model-adapter | const server=spawn('python3',['-m','http.server','4193','--bind','127.0.0.1','--directory','[held-local-source]'],{stdio:'ignore'});const b=await chromium.launch({executablePath:'/usr/bin/google-chrome',headless:true,args:['--no-sandbox']});try{const p=await b.newPage({viewport:{width:1000,height:900}});const errors=[];p.on('pageerror',e=>errors.push(e.message));await p.addInitScript(()=>{Math.random=()=>.3;window.renderTrace=[];window.counts={raf:0,reads:0,fills:0,strokes:0};const raf=window.requestAnimationFrame;window.requestAnimationFrame=fn=>{window.counts.raf++;return raf(fn);};const get=Storage.prototype.getItem;Storage.prototype.getItem=function(...args){window.counts.reads++;return get.apply(this,args);};const rect=CanvasRenderingContext2D.prototype.roundRect;CanvasRenderingContext2D.prototype.roundRect=function(...args){this.lastAuditRect=args;return rect.apply(this,args);};for(const op of ['fill','stroke']){const f=CanvasRenderingContext2D.prototype[op];CanvasRenderingContext2D.prototype[op]=function(...args){window.counts[op==='fill'?'fills':'strokes']++;window.renderTrace.push({op,canvas:this.canvas.id,rect:this.lastAuditRect,style:op==='fill'?this.fillStyle:this.strokeStyle,alpha:this.globalAlpha});return f.apply(this,args);};}});await p.clock.install({time:0});await p.clock.pauseAt(1000);await p.goto('http://127.0.0.1:4193');await p.evaluate(()=>{window.counts.raf=0;const r=window.requestAnimationFrame;window.requestAnimationFrame=fn=>{window.counts.raf++;return r(fn);};});await p.evaluate(async()=>{const {GameManager}=await import('/game/gameManager.js');const h=GameManager.prototype.handleAction;GameManager.prototype.handleAction=function(...args){window.captureGM=this;return h.apply(this,args);};});await p.keyboard.press('Enter');await p.clock.runFor(40);await p.keyboard.press('Escape');await p.clock.runFor(40);const before=await p.evaluate(()=>({counts:{...window.counts},mode:window.captureGM.state,semanticStimulus:{current:{token:window.captureGM.currentTetromino.color,rotation:window.captureGM.currentTetromino.rotationState,position:window.captureGM.currentTetromino.position},queue:window.captureGM.nextTetrominos.map(t=>t.color),board:window.captureGM.gameBoard.map(row=>row.map(c=>c.isFilled?c.color:null))},trace:window.renderTrace,sizes:['tetris','heldPreview','next0','next1','next2'].map(id=>{const c=document.getElementById(id),r=c.getBoundingClientRect();const cs=getComputedStyle(c);const borderX=parseFloat(cs.borderLeftWidth)+parseFloat(cs.borderRightWidth),borderY=parseFloat(cs.borderTopWidth)+parseFloat(cs.borderBottomWidth);return {id,contentCSS:{width:r.width-borderX,height:r.height-borderY},border:{x:borderX,y:borderY},css:{width:r.width,height:r.height},backing:{width:c.width,height:c.height},dpr:devicePixelRatio,transform:[c.getContext('2d').getTransform().a,c.getContext('2d').getTransform().d]};})}));await p.clock.runFor(1000);const after=await p.evaluate(()=>({counts:{...window.counts},mode:window.captureGM.state}));assert.deepEqual(before.counts,after.counts);await p.screenshot({path:'[held-local-output]'});const bindings=['game/gameManager.js','game/inputController.js','script.js','index.html'].map(n=>{const bytes=fs.readFileSync('[held-local-source]'+n);return {path:n,bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')};});console.log(JSON.stringify({browser:await b.version(),node:process.version,before,after,errors,bindings,scope:'actualfivecanvasdrawcalltrace/paused1000logicalms/no connectedgamepad/RAFstoragefillstroke counts/declaredstate asrenderstimulus; notnativebattery/AT/physicalscreen/gamut/allinvalidations'},null,2));}finally{await b.close();server.kill();} |
| render-idle-v61/independent-v61.py:1 | module-language, python-model-adapter | import json,re,pathlib,math |
| render-idle-v61/independent-v61.py:2 | python-model-adapter | r=pathlib.Path('[held-local-source]');a=json.loads((r/'render-idle-v61/actual-v61.json').read_text());mapkind={v['token']:v['uniqueKind'] for v in json.loads((r/'kind-evidence/kind-geometry-encoding-v40.json').read_text())['rows']};geom={};kind=None |
| render-idle-v61/independent-v61.py:3 | python-model-adapter | for line in pathlib.Path('[held-local-source]').read_text().splitlines(): |
| render-idle-v61/independent-v61.py:4 | python-model-adapter |  m=re.match(r'([IOTSLJZ]) \(box (\d)x(\d)\):',line) |
| render-idle-v61/independent-v61.py:5 | python-model-adapter |  if m:kind=m[1];geom[kind]={'box':(int(m[2]),int(m[3])),'states':[]} |
| render-idle-v61/independent-v61.py:6 | python-model-adapter |  elif 'state ' in line:geom[kind]['states'].append([tuple(map(int,p)) for p in re.findall(r'\((\d+),(\d+)\)',line)]) |
| render-idle-v61/independent-v61.py:7 | python-model-adapter | stim=a['before']['semanticStimulus'];cur=stim['current'];k=mapkind[cur['token']];cells=geom[k]['states'][cur['rotation']];pos=cur['position'];board=stim['board'] |
| render-idle-v61/independent-v61.py:16 | python-model-adapter |  id='next'+str(index);kind=mapkind[token];g=geom[kind]['states'][0];step=sizes[id]['contentCSS']['width']/6;draws=[t for t in trace if t['canvas']==id and t['op']=='fill'][-4:];coords={(round((t['rect'][1]-.5)/step),round((t['rect'][0]-.5)/step)) for t in draws};assert coords==set(g);previews.append({'id':id,'declaredKind':kind,'sourceGeometryEqual':True}) |
| render-idle-v61/independent-v61.py:20 | python-model-adapter | print(json.dumps({'currentSourceCells':sorted(currentExpected),'ghostSourceCells':sorted(ghostExpected),'straightDownLandingAnchor':row,'drawcallGeometryEqual':True,'previews':previews,'pausedLogical1000msCountersStable':True,'beforeCounters':a['before']['counts'],'fiveBackingTransformRows':backing,'scope':'G6independentrendergeometry on declaredactualsemanticstimulus notdealingorderoracle; roundRectlocalpretranslatedcoords; requestcounterpostclockinstall; no targethardware/gamut/pixelsbyPython/allinvalidation'},indent=2)) |
| legacy-semantic-v66/actual-v66.mjs:1 | module-language, scheduler-clock, console, node-filesystem-hosting, python-model-adapter | import fs from 'node:fs';import {createHash} from 'node:crypto';import {GameManager,createMemoryStorage} from '[held-local-source]';import {TetrominoFactory} from '[held-local-source]';const rows=[];for(const name of ['saved-game-current.json','saved-game-with-level.json']){let id=0;const q=new Map(),scheduler={setTimeout(f,ms){const h=++id;q.set(h,{f,ms});return h;},clearTimeout(h){q.delete(h);}},storage=createMemoryStorage(),raw=fs.readFileSync('[held-local-source]'+name,'utf8');storage.setItem('tetris.savedGameSession',raw);storage.setItem('tetris.isSessionSaved','true');const g=new GameManager({scheduler,storage,factory:new TetrominoFactory(()=>.3),onFault(){}});g.handleAction('continueGame');rows.push({name,fixtureSha256:createHash('sha256').update(raw).digest('hex'),mode:g.state,board:g.gameBoard.map(r=>r.map(c=>c.isFilled?c.color:null)),score:g.score,current:{token:g.currentTetromino.color,rotation:g.currentTetromino.rotationState,position:g.currentTetromino.position},queue:g.nextTetrominos.map(p=>p.color),held:g.heldTetromino?.color??null,canHold:g.canHoldTetromino,bag:g.factory.bag.map(p=>p.color),count:g.lockDelayResetCount,lowestAnchor:g.lowestRowReached,outstanding:q.size,faults:g.faults.length});}console.log(JSON.stringify({node:process.version,rows,bindings:['gameManager.js','session.js','tetrominoFactory.js'].map(n=>{const b=fs.readFileSync('[held-local-source]'+n);return {path:n,bytes:b.length,sha256:createHash('sha256').update(b).digest('hex')};}),scope:'exacttwosupportedfixtures actualcurrentpublicContinue/realfactory/no timerdelivery; notoriginalcapture/releasechronology/successfuloldwriteattestation/native/fullrawdomain'},null,2)); |
| legacy-semantic-v66/independent-v66.py:1 | module-language, python-model-adapter | import json,pathlib,re,hashlib |
| legacy-semantic-v66/independent-v66.py:2 | python-model-adapter | r=pathlib.Path('[held-local-source]');a=json.loads((r/'legacy-semantic-v66/actual-v66.json').read_text());mapping={v['token']:v['uniqueKind'] for v in json.loads((r/'kind-evidence/kind-geometry-encoding-v40.json').read_text())['rows']};geom={};kind=None |
| legacy-semantic-v66/independent-v66.py:3 | python-model-adapter | for line in pathlib.Path('[held-local-source]').read_text().splitlines(): |
| legacy-semantic-v66/independent-v66.py:4 | python-model-adapter |  m=re.match(r'([IOTSLJZ]) \(box',line) |
| legacy-semantic-v66/independent-v66.py:5 | python-model-adapter |  if m:kind=m[1];geom[kind]=[] |
| legacy-semantic-v66/independent-v66.py:6 | python-model-adapter |  elif 'state ' in line:geom[kind].append([tuple(map(int,p)) for p in re.findall(r'\((\d+),(\d+)\)',line)]) |
| legacy-semantic-v66/independent-v66.py:9 | python-model-adapter |  raw=pathlib.Path('[held-local-source]'+actual['name']).read_bytes();assert hashlib.sha256(raw).hexdigest()==actual['fixtureSha256'];x=json.loads(raw);assert len(x['gameBoard'])==20 and all(len(row)==10 for row in x['gameBoard']);board=[] |
| legacy-semantic-v66/independent-v66.py:13 | python-model-adapter |    assert type(cell['isFilled'])==bool;decoded.append(mapping[cell['color']] if cell['isFilled'] else None) |
| legacy-semantic-v66/independent-v66.py:15 | python-model-adapter |  cur=x['currentTetromino'];kind=mapping[cur['color']];rotation=cur['rotationState'];assert type(rotation)==int and 0<=rotation<len(geom[kind]);pos=cur['position'];assert all(type(pos[v])==int for v in ['row','column']);cells=[(pos['row']+dr,pos['column']+dc) for dr,dc in geom[kind][rotation]];assert all(0<=row<20 and 0<=col<10 and board[row][col] is None for row,col in cells);queue=[mapping[p['color']] for p in x['nextTetrominos']];assert len(queue)==3;bag=[mapping[p] for p in x['bag']];assert len(set(bag))==len(bag);held=mapping[x['heldTetromino']['color']] if x['heldTetromino'] else None;assert type(x['canHoldTetromino'])==bool;assert type(x['score'])==int and x['score']>=0 |
| legacy-semantic-v66/independent-v66.py:19 | python-model-adapter |  projected={'mode':actual['mode'],'board':[[mapping[token] if token else None for token in row] for row in actual['board']],'score':actual['score'],'currentKind':mapping[actual['current']['token']],'rotation':actual['current']['rotation'],'position':actual['current']['position'],'queue':[mapping[token] for token in actual['queue']],'held':mapping[actual['held']] if actual['held'] else None,'holdUsed':not actual['canHold'],'bag':[mapping[token] for token in actual['bag']],'count':actual['count'],'lowest':actual['lowestAnchor']+max(dr for dr,dc in geom[kind][rotation])} |
| legacy-semantic-v66/independent-v66.py:20 | python-model-adapter |  assert expected==projected and actual['outstanding']==0 and actual['faults']==0;out.append({'name':actual['name'],'hash':actual['fixtureSha256'],'declaredSupportedFormatIndependentContentValid':True,'actualPausedRestorationMatchesUnderL1L3AndBoundedLowestProjection':True,'expected':expected,'scope':'contentvalidity notcapture/writesuccess/lastgood/native; currenttokenhistoricalencoding premiseV34sameTFgeometryhash'}) |
| legacy-semantic-v66/independent-v66.py:21 | python-model-adapter | print(json.dumps({'rows':out,'scope':'sourcepredicateallgameplayfields for exacttwolegacyfixtures withapprovedmissing0/L1, payloadcontrolmodes/session16 separate; no genericnewsaveomissionfallback'},indent=2)) |
| frozen-rev6/o8_reference_model_rev6.py:5 | python-model-adapter | SRS geometry table (2-srs_table.txt) and image (1-SRS-pieces.png). No repository/code/tests were consulted. |
| frozen-rev6/o8_reference_model_rev6.py:11 | module-language, python-model-adapter | import copy, random |
| frozen-rev6/o8_reference_model_rev6.py:29 | module-language, python-model-adapter | import functools |
| frozen-rev6/o8_reference_model_rev6.py:173 | node-filesystem-hosting |     def _spawn(self, kind): |
| frozen-rev6/o8_reference_model_rev6.py:197 | node-filesystem-hosting |         self._spawn(cur) |
| frozen-rev6/o8_reference_model_rev6.py:208 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:212 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:215 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:218 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:248 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:254 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:271 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:279 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:284 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:288 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:301 | node-filesystem-hosting |         ok = self._spawn(nxt) |
| frozen-rev6/o8_reference_model_rev6.py:303 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:309 | node-filesystem-hosting |         ok = self._spawn(new) |
| frozen-rev6/o8_reference_model_rev6.py:313 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:321 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:323 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:332 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:353 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:365 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:377 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:388 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:393 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:396 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:400 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:404 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:409 | python-model-adapter |     @atomic |
| frozen-rev6/o8_reference_model_rev6.py:413 | python-model-adapter |     @atomic |
