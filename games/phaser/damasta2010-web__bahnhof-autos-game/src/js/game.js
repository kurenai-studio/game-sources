/* Simple Phaser 3 prototype for "Bahnhof Autos Game" (plain JS)
   - Circle station with 5 slots
   - Two spawn queues that feed colored passenger tokens (red/blue/green)
   - Cars (capacities 8/16/32) draggable to slots; color must match to board
   - Timeout: 8s per car; after that car departs if >=50% filled
   - 3 Levels with increasing spawn rate
*/

const config = {
  type: Phaser.AUTO,
  width: 900,
  height: 640,
  parent: 'game-container',
  backgroundColor: '#1f1f2e',
  scene: {
    preload: preload,
    create: create,
    update: update
  }
};n
const game = new Phaser.Game(config);

function preload() {
  // no external assets for prototype
}

let sceneState = {
  slots: [],
  slotPositions: [],
  passengers: [],
  cars: [],
  nextSpawnLeft: true,
  spawnTimer: 0,
  rotateTimer: 0,
  level: 1,
  transported: 0,
  target: 200,
  spawnInterval: 3000,
  levelTime: 0,
  levelDuration: 60,
  gameOver: false
};

function create() {
  const scene = this;

  // HUD
  this.add.text(16, 16, 'Bahnhof Autos Game', { fontSize: '20px', fill: '#fff' });
  sceneState.levelText = this.add.text(16, 44, 'Level: 1', { fontSize: '16px', fill: '#fff' });
  sceneState.infoText = this.add.text(16, 68, 'Transported: 0', { fontSize: '16px', fill: '#fff' });
  sceneState.timeText = this.add.text(16, 92, 'Time: 0', { fontSize: '16px', fill: '#fff' });

  // Station circle center
  const cx = 450, cy = 240, radius = 140;
  const slotCount = 5;
  for (let i = 0; i < slotCount; i++) {
    const angle = (i / slotCount) * Math.PI * 2 - Math.PI / 2;
    const x = cx + Math.cos(angle) * radius;
    const y = cy + Math.sin(angle) * radius;
    sceneState.slotPositions.push({ x, y });

    const slotG = this.add.container(x, y);
    const bg = this.add.circle(0, 0, 34, 0x333333);
    const ring = this.add.circle(0, 0, 36);
    ring.setStrokeStyle(2, 0x666666);
    slotG.add([bg, ring]);
    slotG.passengers = [];
    scene.add.existing(slotG);
    sceneState.slots.push(slotG);
  }

  // Spawn points (left and right)
  sceneState.spawnLeft = { x: 80, y: 120 };
  sceneState.spawnRight = { x: 820, y: 120 };
  this.add.text(sceneState.spawnLeft.x - 20, sceneState.spawnLeft.y - 40, 'Queue A', { fontSize: '12px', fill: '#fff' });
  this.add.text(sceneState.spawnRight.x - 30, sceneState.spawnRight.y - 40, 'Queue B', { fontSize: '12px', fill: '#fff' });

  // Visual spawn dots
  this.add.circle(sceneState.spawnLeft.x, sceneState.spawnLeft.y, 8, 0x888888);
  this.add.circle(sceneState.spawnRight.x, sceneState.spawnRight.y, 8, 0x888888);

  // Car pool area
  const carY = 520;
  const carXStart = 160;
  const carGap = 200;
  const carConfigs = [ { cap: 8, color: 0xff4d4d }, { cap: 16, color: 0x4da6ff }, { cap: 32, color: 0x66ff66 } ];

  carConfigs.forEach((c, i) => {
    const x = carXStart + i * carGap;
    const car = createCar(scene, x, carY, c.cap, c.color);
    sceneState.cars.push(car);
  });

  // Input drop handling
  this.input.on('dragstart', function (pointer, gameObject) {
    gameObject.setScale(1.05);
  });
  this.input.on('drag', function (pointer, gameObject, dragX, dragY) {
    gameObject.x = dragX;
    gameObject.y = dragY;
  });
  this.input.on('dragend', function (pointer, gameObject) {
    gameObject.setScale(1);
    // check drop on any slot
    const slotIndex = findSlotUnder(scene, gameObject.x, gameObject.y);
    if (slotIndex !== -1) {
      placeCarOnSlot(scene, gameObject, slotIndex);
    } else {
      // return car to home after slight delay if not placed
      returnCarHome(scene, gameObject);
    }
  });

  // Timers
  sceneState.spawnTimer = this.time.addEvent({ delay: sceneState.spawnInterval, callback: spawnPassenger, callbackScope: this, loop: true });
  sceneState.rotateTimer = this.time.addEvent({ delay: 2000, callback: rotatePassengers, callbackScope: this, loop: true });

  sceneState.levelTimer = this.time.addEvent({ delay: 1000, callback: onTick, callbackScope: this, loop: true });

  // Level settings
  applyLevelSettings(this);
}

function createCar(scene, x, y, capacity, color) {
  const container = scene.add.container(x, y);
  const rect = scene.add.rectangle(0, 0, 140, 60, color).setStrokeStyle(2, 0x222222);
  const text = scene.add.text(-60, -10, `${capacity} Plätze`, { fontSize: '12px', fill: '#111' });
  container.add([rect, text]);
  container.setSize(140, 60);
  container.capacity = capacity;
  container.color = color;
  container.boarded = 0;
  container.homeX = x; container.homeY = y;
  container.placedAtSlot = -1;
  container.available = true;

  container.setInteractive(new Phaser.Geom.Rectangle(-70, -30, 140, 60), Phaser.Geom.Rectangle.Contains);
  scene.input.setDraggable(container);

  return container;
}

function findSlotUnder(scene, x, y) {
  for (let i = 0; i < sceneState.slots.length; i++) {
    const s = sceneState.slots[i];
    const dx = x - s.x;
    const dy = y - s.y;
    if (Math.sqrt(dx * dx + dy * dy) <= 50) return i;
  }
  return -1;
}

function placeCarOnSlot(scene, car, slotIndex) {
  if (!car.available) return;
  const slot = sceneState.slots[slotIndex];
  // snap to slot edge
  scene.tweens.add({ targets: car, x: slot.x + 0, y: slot.y + 90, duration: 300 });
  car.available = false;
  car.placedAtSlot = slotIndex;
  car.boarded = 0;

  // start timeout timer (8s)
  car.timeoutEvent = scene.time.delayedCall(8000, () => {
    const minNeeded = Math.ceil(car.capacity * 0.5);
    if (car.boarded >= minNeeded) {
      departCar(scene, car);
    } else {
      // not enough -> return home empty
      returnCarHome(scene, car);
    }
  });

  // start boarding loop
  car.boardingLoop = scene.time.addEvent({ delay: 400, callback: () => {
    tryBoardFromSlot(scene, car, slotIndex);
  }, loop: true });
}

function tryBoardFromSlot(scene, car, slotIndex) {
  const slot = sceneState.slots[slotIndex];
  // find passenger of matching color
  if (!slot || slot.passengers.length === 0) return;
  let foundIndex = -1;
  for (let i = 0; i < slot.passengers.length; i++) {
    if (slot.passengers[i].color === car.color) { foundIndex = i; break; }
  }
  if (foundIndex === -1) return;
  if (car.boarded >= car.capacity) return;

  // board one passenger
  const p = slot.passengers.splice(foundIndex, 1)[0];
  scene.tweens.add({ targets: p.sprite, x: car.x - 30 + (car.boarded % 6) * 10, y: car.y - 10, duration: 400, onComplete: () => {
    p.sprite.destroy();
  }});
  car.boarded += 1;

  if (car.boarded >= car.capacity) {
    // full -> depart immediately
    if (car.timeoutEvent) car.timeoutEvent.remove(false);
    departCar(scene, car);
  }
}

function departCar(scene, car) {
  // stop boarding
  if (car.boardingLoop) car.boardingLoop.remove(false);
  // animate depart upwards
  scene.tweens.add({ targets: car, y: -120, duration: 700, ease: 'Power2', onComplete: () => {
    sceneState.transported += car.boarded;
    sceneState.infoText.setText('Transported: ' + sceneState.transported);
    // remove car and respawn after delay
    car.destroy();
    scene.time.delayedCall(1200, () => {
      const newCar = createCar(scene, car.homeX, car.homeY, car.capacity, car.color);
      sceneState.cars.push(newCar);
    });
  }});
}

function returnCarHome(scene, car) {
  // stop boarding and timeout
  if (car.boardingLoop) car.boardingLoop.remove(false);
  if (car.timeoutEvent) car.timeoutEvent.remove(false);
  car.available = true;
  car.placedAtSlot = -1;
  scene.tweens.add({ targets: car, x: car.homeX, y: car.homeY, duration: 500 });
}

function spawnPassenger() {
  const scene = this; // callbackScope
  if (sceneState.gameOver) return;
  // choose color randomly with some weighting by level
  const colors = [0xff4d4d, 0x4da6ff, 0x66ff66];
  const color = Phaser.Utils.Array.GetRandom(colors);
  // spawn from left/right alternately
  const spawn = sceneState.nextSpawnLeft ? sceneState.spawnLeft : sceneState.spawnRight;
  sceneState.nextSpawnLeft = !sceneState.nextSpawnLeft;

  const circle = scene.add.circle(spawn.x, spawn.y, 12, color).setDepth(2);
  const passenger = { color, sprite: circle };

  // find first available slot (by index order) to move into; if all full => game over
  let targetIndex = -1;
  for (let i = 0; i < sceneState.slots.length; i++) {
    if (sceneState.slots[i].passengers.length < 6) { targetIndex = i; break; }
  }
  if (targetIndex === -1) {
    // station full -> game over
    sceneState.gameOver = true;
    scene.add.text(320, 300, 'Game Over - Station Overrun', { fontSize: '28px', fill: '#ffaaaa' });
    return;
  }

  const tx = sceneState.slotPositions[targetIndex].x + Phaser.Math.Between(-10,10);
  const ty = sceneState.slotPositions[targetIndex].y + Phaser.Math.Between(-10,10);
  scene.tweens.add({ targets: circle, x: tx, y: ty, duration: 600, onComplete: () => {
    sceneState.slots[targetIndex].passengers.push(passenger);
  }});
}

function rotatePassengers() {
  if (sceneState.gameOver) return;
  // rotate passenger arrays across slots (visualize by tweening all passenger sprites to next slot)
  const nextPositions = [];
  for (let i = 0; i < sceneState.slots.length; i++) {
    nextPositions.push(sceneState.slots[(i + 1) % sceneState.slots.length].getAt(0));
  }
  // move all passenger sprites to next slot positions
  for (let si = 0; si < sceneState.slots.length; si++) {
    const slot = sceneState.slots[si];
    for (let pi = 0; pi < slot.passengers.length; pi++) {
      const p = slot.passengers[pi];
      const nextIndex = (si + 1) % sceneState.slots.length;
      const tx = sceneState.slotPositions[nextIndex].x + Phaser.Math.Between(-10,10);
      const ty = sceneState.slotPositions[nextIndex].y + Phaser.Math.Between(-10,10);
      scene.tweens.add({ targets: p.sprite, x: tx, y: ty, duration: 600, onComplete: () => {
        // transfer data structure: move passenger to next slot at the end of rotation
      }});
    }
  }

  // after a small delay, shift arrays
  this.time.delayedCall(650, () => {
    const lastPassengers = sceneState.slots[sceneState.slots.length - 1].passengers.slice();
    for (let i = sceneState.slots.length - 1; i > 0; i--) {
      sceneState.slots[i].passengers = sceneState.slots[i-1].passengers;
    }
    sceneState.slots[0].passengers = lastPassengers;
  });
}

function onTick() {
  if (sceneState.gameOver) return;
  sceneState.levelTime += 1;
  sceneState.timeText.setText('Time: ' + sceneState.levelTime + 's');
  // level progression simple: every 30s increase level (max 3)
  if (sceneState.levelTime === 30 && sceneState.level < 2) {
    sceneState.level = 2; applyLevelSettings(this.scene ? this.scene : this); sceneState.levelText.setText('Level: ' + sceneState.level);
  }
  if (sceneState.levelTime === 60 && sceneState.level < 3) {
    sceneState.level = 3; applyLevelSettings(this.scene ? this.scene : this); sceneState.levelText.setText('Level: ' + sceneState.level);
  }
}

function applyLevelSettings(scene) {
  // adjust spawnInterval by level
  if (sceneState.spawnTimer) sceneState.spawnTimer.remove(false);
  if (sceneState.level === 1) sceneState.spawnInterval = 3000;
  else if (sceneState.level === 2) sceneState.spawnInterval = 2000;
  else sceneState.spawnInterval = 1200;

  sceneState.spawnTimer = scene.time.addEvent({ delay: sceneState.spawnInterval, callback: spawnPassenger, callbackScope: scene, loop: true });
}

function update() {
  // nothing heavy here for now
}
