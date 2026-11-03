import Phaser from "phaser";
import "./style.css";
import { DriveInput, DIRECTION_KEYS, STEP_MS, driveProgress } from "./game/drive.ts";
import {
  ROOM,
  ROOMS,
  ROOM_ORDER,
  NAMES,
  dispatch,
  newSession,
  isPowered,
  isPlateHeld,
  isWon,
  circuits,
  circuitOn,
  isBridgeOpen,
  isDoorOpen,
  same,
  facingTarget,
  tileAt,
} from "./game/rules.ts";
import type {
  Command,
  RobotId,
  Session,
  State,
  Module,
  RoomId,
} from "./game/rules.ts";

const TILE = 50;
const ANGLES = { up: 0, right: Math.PI / 2, down: Math.PI, left: -Math.PI / 2 };
const COLORS = {
  floor: 0x152638,
  wall: 0x223246,
  line: 0x31465b,
  pip: 0x81e4cf,
  bolt: 0xe6b579,
  magnet: 0xffa0aa,
  power: 0xffe290,
};
const element = <T extends HTMLElement = HTMLElement>(id: string): T =>
  document.getElementById(id) as T;
const gameElement = element("game");
let session: Session = newSession("bodies");
let pullHeld = false;
let muted = true;
let audio: AudioContext | undefined;
const nextRoom = (): RoomId | undefined => ROOM_ORDER[ROOM_ORDER.indexOf(session.state.room) + 1];
const reducedMotion = (): boolean => window.matchMedia("(prefers-reduced-motion: reduce)").matches;
function pullSound(): void {
  if (muted || !audio || audio.state !== "running") return;
  const oscillator = audio.createOscillator();
  const gain = audio.createGain();
  oscillator.type = "sine";
  oscillator.frequency.setValueAtTime(150, audio.currentTime);
  oscillator.frequency.exponentialRampToValueAtTime(85, audio.currentTime + 0.11);
  gain.gain.setValueAtTime(0.035, audio.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, audio.currentTime + 0.13);
  oscillator.connect(gain).connect(audio.destination);
  oscillator.start(); oscillator.stop(audio.currentTime + 0.14);
  oscillator.onended = () => { oscillator.disconnect(); gain.disconnect(); };
}

function updateHud(): void {
  const s = session.state;
  element("feedback").textContent = session.message;
  element("move-count").textContent = `${s.actions} Aktionen`;
  element("door-status").textContent = circuits(s.room).map(c =>
    `${c.name || "TÜR"} ${circuitOn(s, c) ? "OFFEN" : c.bridges.some(b => isBridgeOpen(s, b)) ? "BESETZT · SICHER" : "ZU"}`).join(" · ")
    + ` · ${isPowered(s) ? "Strom verbunden" : isPlateHeld(s) ? tileAt(s.robots.bolt, s.room) === "P" ? "Bolt hält die Platte" : "Kiste hält die Platte" : "Keine Versorgung"}`;
  gameElement.dataset.pulling = String(pullHeld);
  gameElement.dataset.won = String(isWon(s));
  gameElement.dataset.crate = s.crate ? `${s.crate.x},${s.crate.y}` : "";
  const active = s.robots[s.active];
  element("pull-status").textContent = pullHeld
    ? `${active.module === "magnet" ? "∪ E + rückwärts: ziehen · " : ""}${s.active === "bolt" ? "■ E + vorwärts: schieben · " : ""}E loslassen zum Drehen`
    : "∪ Magnet: E + rückwärts zieht · ■ Bolt: E + vorwärts schiebt · ⚡ Batterie: E verbindet / löst";
  element("pull-status").classList.toggle("ready", pullHeld);
  element<HTMLButtonElement>("undo").disabled = session.history.length === 0;
  element("robots").innerHTML = (["pip", "bolt"] as RobotId[])
    .map((id) => {
      const r = s.robots[id];
      return `<section class="robot-card ${s.active === id ? "active" : ""}" data-testid="robot-${id}" data-x="${r.x}" data-y="${r.y}" data-facing="${r.facing}" data-module="${r.module}" data-connected="${s.connected === id}"><div class="robot-top"><span class="robot-name">${id === "pip" ? "●" : "■"} ${NAMES[id]}</span><span class="active-tag">${s.active === id ? "AKTIV · SHIFT ↔" : "BUDDY"}</span></div><p>${id === "pip" ? "Kleiner Körper · passt durch Schächte" : "Schwerer Körper · hält Platten und schiebt"}</p><span class="module ${r.module}">${r.module === "magnet" ? "∪ · Hufeisenmagnet" : "⚡ · Batterie"}${s.connected === id ? " · verbunden" : ""}</span><span class="coords">${({ up: "↑", down: "↓", left: "←", right: "→" })[r.facing]} · Feld ${r.x} / ${r.y}</span></section>`;
    })
    .join("");
  const room = ROOMS[s.room];
  gameElement.dataset.room = s.room;
  element("room-title").textContent = room.title;
  element<HTMLSelectElement>("room-select").value = s.room;
  element("mission-title").textContent = "Deine Aufgabe";
  element("objective").textContent = isWon(s) ? nextRoom() ? "Geschafft! Enter oder Weiter führt zum nächsten Raum." : "Alle sechs Räume geschafft! Danke für euren Werkstattdienst. Raumwahl zum Weiterspielen, R zum Neustart." : room.objective;
  element("room-hint").textContent = room.hint;
  const goals: [boolean, string][] = s.room === "bodies"
    ? [[tileAt(s.robots.pip, s.room) === "X", "Pip am Ausgang"], [isPlateHeld(s), "Bolt hält die schwere Platte"]]
    : s.room === "modules"
      ? [[isPowered(s), "Anschluss versorgt"], [tileAt(s.robots.bolt, s.room) === "X", "Bolt am Ausgang"]]
      : [[tileAt(s.robots.pip, s.room) === "X", "Pip am Ausgang"], [tileAt(s.robots.bolt, s.room) === "X", "Bolt am Ausgang"]];
  element("progress").innerHTML = goals.map(([done, text]) => `<li class="${done ? "done" : ""}">${text}</li>`).join("");
  element<HTMLButtonElement>("next-room").hidden = !isWon(s) || !nextRoom();

}

class RoomScene extends Phaser.Scene {
  private graphics!: Phaser.GameObjects.Graphics;
  private labels: Phaser.GameObjects.Text[] = [];
  private preserveLabels = false;
  private motion?: { before: State; progress: number; pull: boolean; started: number; starting: boolean };
  private controls = new DriveInput();
  private nextStepAt = 0;
  private lastFrame = 0;
  private wheelTravel: Record<RobotId, number> = { pip: 0, bolt: 0 };
  private steeringTravel: Record<RobotId, number> = { pip: 0, bolt: 0 };
  private expression?: { id: RobotId; started: number; kind: "start" | "stop" | "bump" };
  private wasRolling = false;
  private effects = new Set<Phaser.GameObjects.Graphics>();

  private settle(): void {
    this.motion = undefined; this.expression = undefined; this.wasRolling = false;
    this.wheelTravel = { pip: 0, bolt: 0 }; this.steeringTravel = { pip: 0, bolt: 0 };
    for (const effect of this.effects) { this.tweens.killTweensOf(effect); effect.destroy(); }
    this.effects.clear();
    gameElement.dataset.animating = "false";
  }
  private resetInput(): void { this.controls.reset(); pullHeld = false; }

  update(): void {
    const now = performance.now();
    // A stalled frame is not a debt to repay. Finish this one legal step and
    // require fresh input after a long suspension, even without a blur event.
    if (this.lastFrame && now - this.lastFrame > 250) {
      this.resetInput(); this.settle(); updateHud(); this.redraw();
    }
    this.lastFrame = now;
    let finished = false;
    if (this.motion) {
      const t = Math.min(1, (now - this.motion.started) / STEP_MS);
      this.motion.progress = driveProgress(t, this.motion.starting);
      if (t === 1) {
        const id = session.state.active;
        const r = session.state.robots[id];
        if (!same(this.motion.before.robots[id], r)) this.wheelTravel[id] += this.motion.pull ? -30 : 30;
        this.steeringTravel[id] += Phaser.Math.Angle.Wrap(ANGLES[r.facing] - ANGLES[this.motion.before.robots[id].facing]) * 8;
        this.motion = undefined; finished = true;
        gameElement.dataset.animating = "false";
      }
    }
    if (!this.motion && now >= this.nextStepAt) {
      const direction = this.controls.take();
      if (direction) this.act({ type: pullHeld ? "pull" : "move", direction }, this.wasRolling);
      else if (this.wasRolling) {
        this.wasRolling = false;
        this.expression = { id: session.state.active, started: now, kind: "stop" };
      }
    }
    if (this.expression && now - this.expression.started > 180) { this.expression = undefined; finished = true; }
    if (this.motion || this.expression || finished) this.redraw(true);
  }

  create(): void {
    this.graphics = this.add.graphics();
    this.redraw();
    updateHud();
    // Enter belongs to progression only on the field or its own Next button.
    // Prevent native button activation so one keydown cannot advance twice.
    document.addEventListener("keydown", event => {
      if (event.code !== "Enter" || event.ctrlKey || event.altKey || event.metaKey) return;
      if (![gameElement, document.body, element("next-room")].includes(document.activeElement as HTMLElement)) return;
      event.preventDefault();
      if (!event.repeat && isWon(session.state) && nextRoom()) this.advance();
    }, true);
    // DOM order matters: Phaser queues keydown until the next frame. Handling
    // down/up together here prevents fast E+direction/releases crossing frames.
    window.addEventListener("keydown", (event: KeyboardEvent) => {
      if (event.ctrlKey || event.altKey || event.metaKey) return;
      if (document.activeElement !== gameElement && document.activeElement !== document.body) return;
      if (DIRECTION_KEYS[event.code]) event.preventDefault();
      if (event.repeat) return;
      let command: Command | undefined;
      if (DIRECTION_KEYS[event.code]) {
        event.preventDefault();
        if (isWon(session.state) || !this.controls.press(event.code)) return;
        if (!this.motion) {
          const direction = this.controls.take()!;
          this.act({ type: pullHeld ? "pull" : "move", direction }, this.wasRolling);
        }
        return;
      }
      else if (event.code === "ShiftLeft" || event.code === "ShiftRight") command = { type: "switch" };
      else if (event.code === "KeyE") {
        this.controls.reset();
        pullHeld = (session.state.robots[session.state.active].module === "magnet" || session.state.active === "bolt") && !isWon(session.state);
        command = { type: "interact" };
      }
      else if (event.code === "KeyT") command = { type: "swap" };
      else if (event.code === "KeyZ") command = { type: "undo" };
      else if (event.code === "KeyR") command = { type: "restart" };
      if (command) { event.preventDefault(); this.act(command); }
    });
    const release = (): void => { this.resetInput(); updateHud(); this.redraw(); };
    window.addEventListener("keyup", event => {
      if (DIRECTION_KEYS[event.code]) this.controls.release(event.code);
      if (event.code === "KeyE") release();
    });
    window.addEventListener("blur", () => { this.settle(); release(); });
    gameElement.addEventListener("blur", () => { this.settle(); release(); });
    document.addEventListener("visibilitychange", () => { if (document.hidden) { this.settle(); release(); } });
    window.matchMedia("(prefers-reduced-motion: reduce)").addEventListener("change", () => { this.resetInput(); this.settle(); updateHud(); this.redraw(); });
    element("mute").addEventListener("click", () => {
      muted = !muted;
      element("mute").setAttribute("aria-pressed", String(!muted));
      element("mute").textContent = muted ? "Ton: aus" : "Ton: an";
      if (!muted) {
        audio ??= new AudioContext();
        void audio.resume().catch(() => { muted = true; element("mute").textContent = "Ton: aus"; element("mute").setAttribute("aria-pressed", "false"); });
      }
      gameElement.focus({ preventScroll: true });
    });
    for (const id of ["switch", "interact", "swap", "undo", "restart"] as const) {
      element(id).addEventListener("click", () => {
        this.act({ type: id });
        gameElement.focus({ preventScroll: true });
      });
    }
    element("room-select").addEventListener("change", () => {
      this.act({ type: "room", room: element<HTMLSelectElement>("room-select").value as RoomId });
      gameElement.focus({ preventScroll: true });
    });
    element("next-room").addEventListener("click", () => this.advance());
    gameElement.addEventListener("pointerdown", () =>
      gameElement.focus({ preventScroll: true }),
    );
    gameElement.dataset.ready = "true";
    gameElement.focus({ preventScroll: true });
  }

  private advance(): void {
    const next = nextRoom();
    if (next && isWon(session.state)) this.act({ type: "room", room: next });
    gameElement.focus({ preventScroll: true });
  }

  private act(command: Command, continuing = false): void {
    const driving = command.type === "move" || command.type === "pull";
    if (!driving) {
      this.settle();
      if (["switch", "swap", "undo", "restart", "room"].includes(command.type)) this.resetInput();
    }
    const before = session.state;
    session = dispatch(session, command);
    const after = session.state;
    const id = before.active;
    const moved = !same(before.robots[id], after.robots[id]);
    const turned = before.robots[id].facing !== after.robots[id].facing;
    if (driving) {
      const clockNow = performance.now();
      const now = continuing && clockNow >= this.nextStepAt && clockNow - this.nextStepAt < 100 ? this.nextStepAt : clockNow;
      this.nextStepAt = now + STEP_MS;
      if (!moved) this.controls.obstruct();
      this.wasRolling = moved;
      if (!reducedMotion() && (moved || turned)) {
        this.motion = { before, progress: driveProgress(Math.max(0, (clockNow - now) / STEP_MS), !continuing), started: now, starting: !continuing,
          pull: command.type === "pull" && command.direction !== before.robots[id].facing };
        gameElement.dataset.animating = "true";
      }
      if (!reducedMotion() && (!moved || !continuing))
        this.expression = { id, started: now, kind: moved ? "start" : "bump" };
    }
    if (isWon(after)) this.resetInput();
    if (command.type === "pull" && moved) pullSound();
    updateHud(); this.redraw();
    if (after !== before && !["undo", "restart", "room"].includes(command.type)) this.reaction(before, command);
  }

  private visual(p: { x: number; y: number }, previous?: { x: number; y: number }): { x: number; y: number } {
    const t = this.motion?.progress ?? 1;
    return { x: ((previous?.x ?? p.x) * (1 - t) + p.x * t) * TILE + 25,
      y: ((previous?.y ?? p.y) * (1 - t) + p.y * t) * TILE + 25 };
  }

  private text(
    x: number,
    y: number,
    value: string,
    color = "#b5c9d7",
    size = 12,
  ): void {
    if (this.preserveLabels) return;
    this.labels.push(
      this.add
        .text(x, y, value, {
          fontFamily: "system-ui, sans-serif",
          fontSize: size,
          color,
          fontStyle: "bold",
        })
        .setOrigin(0.5),
    );
  }

  private redraw(preserveLabels = false): void {
    this.preserveLabels = preserveLabels;
    this.graphics.clear();
    if (!preserveLabels) {
      this.labels.forEach((label) => label.destroy());
      this.labels = [];
    }
    const g = this.graphics;
    const s = session.state;
    ROOMS[s.room].grid.forEach((row, y) =>
      [...row].forEach((tile, x) => {
        const px = x * TILE;
        const py = y * TILE;
        g.fillStyle(tile === "#" ? COLORS.wall : (x + y) % 2 ? COLORS.floor : 0x1b2e3b).fillRect(
          px,
          py,
          TILE,
          TILE,
        );
        g.lineStyle(1, tile === "#" ? 0x26384c : 0x1f364b).strokeRect(
          px + 1,
          py + 1,
          TILE - 2,
          TILE - 2,
        );
        if (tile === "#") {
          g.fillStyle((x + y) % 3 === 0 ? 0x354250 : 0x2b3a49).fillRoundedRect(px + 4, py + 4, 42, 40, 5);
          g.fillStyle(0x667079, 0.4).fillCircle(px + 10, py + 10, 2).fillCircle(px + 40, py + 38, 2);
          return;
        }
      }),
    );
    // Recessed wiring lies beneath every fixture, crate and robot. Matching
    // circuit badges carry the relationship; wires are only a quiet floor cue.
    for (const c of circuits(s.room)) {
      const on = circuitOn(s, c);
      for (const source of [...c.sockets, ...c.plates]) for (const target of [...c.doors, ...c.bridges]) {
        const sx = source.x * TILE + 7, sy = source.y * TILE + 43;
        const tx = target.x * TILE + 7, ty = target.y * TILE + 43;
        g.lineStyle(1, on ? COLORS.power : 0xa4a58b, on ? 0.32 : 0.16)
          .lineBetween(sx, sy, sx, ty).lineBetween(sx, ty, tx, ty);
      }
    }
    ROOMS[s.room].grid.forEach((row, y) =>
      [...row].forEach((tile, x) => {
        const px = x * TILE, py = y * TILE;
        if (tile === "v") {
          // 26 px opening: Pip's 22 px wheels fit, Bolt's 44 px tracks don't.
          const horizontal = ["#", "~"].includes(tileAt({ x, y: y - 1 }, s.room))
            && ["#", "~"].includes(tileAt({ x, y: y + 1 }, s.room));
          g.fillStyle(0x637c80);
          if (horizontal) g.fillRect(px, py + 1, TILE, 11).fillRect(px, py + 38, TILE, 11);
          else g.fillRect(px + 1, py, 11, TILE).fillRect(px + 38, py, 11, TILE);
          g.lineStyle(2, 0xa3c3bd);
          for (let i = 5; i < TILE; i += 9)
            if (horizontal) g.lineBetween(px + i, py + 13, px + i, py + 37);
            else g.lineBetween(px + 13, py + i, px + 37, py + i);
          // Field-local label: never a hard-coded arrow pointing at a neighbour.
          g.fillStyle(0x102532).fillRect(px + 13, py + 38, 24, 11);
          this.text(px + 25, py + 44, "PIP", "#c1eee3", 8);
        }
        if (tile === "~" || tile === "B") {
          g.fillStyle(0x080f17).fillRect(px, py, TILE, TILE);
          g.lineStyle(2, 0x465462).lineBetween(px + 3, py, px + 3, py + 50).lineBetween(px + 47, py, px + 47, py + 50);
          if (tile === "B") {
            const open = isBridgeOpen(s, { x, y });
            g.fillStyle(open ? 0x637f7c : 0x38424c).fillRect(px + 3, py + 3, open ? 44 : 8, 44);
            g.lineStyle(2, open ? COLORS.pip : 0xa88b5b);
            for (let i = 8; i < 48; i += 10) g.lineBetween(px + 4, py + i, px + (open ? 46 : 11), py + i);
          }
        }
        if (tile === "S") {
          g.lineStyle(3, COLORS.power).strokeCircle(px + 25, py + 25, 17);
          g.fillStyle(isPowered(s, { x, y }) ? COLORS.power : 0x6e684e).fillCircle(
            px + 25,
            py + 25,
            7,
          );
          this.drawModule(px + 25, py + 25, "power");
        }
        if (tile === "D") {
          const color = isDoorOpen(s, { x, y }) ? 0x81e4cf : 0xfa9b88;
          g.fillStyle(color, 0.18).fillRect(px, py, TILE, TILE);
          g.lineStyle(4, color)
            .lineBetween(px + 2, py + 2, px + 48, py + 2)
            .lineBetween(px + 2, py + 48, px + 48, py + 48);
          if (!isDoorOpen(s, { x, y }))
            for (let i = 11; i < 49; i += 12)
              g.lineBetween(px + i, py + 5, px + i, py + 45);
        }
        if (tile === "P") {
          g.fillStyle(isPlateHeld(s, { x, y }) ? 0x32685e : 0x605444).fillRoundedRect(
            px + 5,
            py + (isPlateHeld(s, { x, y }) ? 13 : 8),
            40,
            isPlateHeld(s, { x, y }) ? 28 : 35,
            4,
          );
          g.lineStyle(
            2,
            isPlateHeld(s, { x, y }) ? COLORS.pip : COLORS.bolt,
          ).strokeRoundedRect(px + 5, py + 8, 40, 35, 4);
          // Twin track imprints match Bolt's broad undercarriage.
          g.fillStyle(COLORS.bolt).fillRoundedRect(px + 8, py + 12, 9, 27, 3).fillRoundedRect(px + 33, py + 12, 9, 27, 3);
          g.lineStyle(2, 0x221f25).lineBetween(px + 12, py + 18, px + 12, py + 33).lineBetween(px + 38, py + 18, px + 38, py + 33);
        }
        if (tile === "O") {
          // Chamfered ceramic, crack, and four anchors; never the metal crate silhouette.
          g.fillStyle(0x9b8b78).fillPoints([
            new Phaser.Geom.Point(px + 13, py + 6), new Phaser.Geom.Point(px + 37, py + 6),
            new Phaser.Geom.Point(px + 44, py + 16), new Phaser.Geom.Point(px + 44, py + 35),
            new Phaser.Geom.Point(px + 35, py + 44), new Phaser.Geom.Point(px + 13, py + 44),
            new Phaser.Geom.Point(px + 6, py + 34), new Phaser.Geom.Point(px + 6, py + 16),
          ], true);
          g.lineStyle(2, 0x574c45).lineBetween(px + 17, py + 13, px + 27, py + 24).lineBetween(px + 27, py + 24, px + 21, py + 34).lineBetween(px + 27, py + 24, px + 36, py + 20);
          for (const dx of [7, 43]) for (const dy of [7, 43]) {
            g.fillStyle(0x111e2c).fillRect(px + dx - 3, py + dy - 3, 6, 6);
            g.lineStyle(1, 0xb5a68f).lineBetween(px + dx - 4, py + dy, px + dx + 4, py + dy);
          }
        }
        if (tile === "X") {
          g.fillStyle(0x295b50).fillRect(px + 2, py + 2, 46, 46);
          g.lineStyle(2, COLORS.pip).strokeRect(px + 5, py + 5, 40, 40);
          this.text(px + 25, py + 25, "→", "#81e4cf", 26);
        }
      }),
    );
    this.text(425, 43, ROOMS[s.room].title.toUpperCase(), "#d9e7ef", 18);
    this.text(425, 70, "WERKSTATTDIENST · Gemeinsam findet ihr einen Weg.", "#a3b8c9", 12);
    if (s.room === "bodies") {
      this.text(510, 275, "← AUSGANG", "#81e4cf", 11);
    } else if (s.room === "modules") {
      this.text(65, 275, "FEST →", "#c5b69e", 10);
      this.text(384, 375, "AUSGANG ↑", "#81e4cf", 11);
    }
    // A few warm service lamps soften the steel workshop without hiding tiles.
    ROOMS[s.room].grid.forEach((row, y) => [...row].forEach((tile, x) => {
      if (tile === "#" && tileAt({ x, y: y + 1 }, s.room) === "." && x % 4 === 2) {
        const px = x * TILE + 25, py = (y + 1) * TILE;
        g.fillStyle(0xffd79b, 0.035).fillCircle(px, py + 24, 43);
        g.fillStyle(0x665746).fillRoundedRect(px - 13, py - 9, 26, 7, 2);
        g.fillStyle(0xffd79b).fillRect(px - 9, py - 6, 18, 3);
      }
    }));
    // Corner badges stay readable even while a source is occupied. Hollow /
    // filled dots encode state as well as colour; A/B/C match every endpoint.
    for (const c of circuits(s.room)) {
      for (const p of [...c.sockets, ...c.plates, ...c.doors, ...c.bridges]) {
        const tile = tileAt(p, s.room);
        const on = tile === "S" ? isPowered(s, p) : tile === "P" ? isPlateHeld(s, p)
          : tile === "D" ? isDoorOpen(s, p) : isBridgeOpen(s, p);
        this.text(p.x * TILE + 12, p.y * TILE + 6, `${on ? "●" : "○"}${c.name || "A"}`, on ? "#b7ffe5" : "#e5d4ae", 9);
      }
    }
    if (!s.crate) delete gameElement.dataset.visualCrate;
    if (s.crate) {
      const { x: cx, y: cy } = this.visual(s.crate, this.motion?.before.crate ?? undefined);
      gameElement.dataset.visualCrate = JSON.stringify({ x: cx, y: cy });
      g.fillStyle(0x050a10, 0.35).fillEllipse(cx + 2, cy + 18, 43, 15);
      g.fillStyle(0x6f899a).fillRoundedRect(cx - 20, cy - 20, 40, 40, 3);
      g.lineStyle(2, 0xd3e0e7).strokeRoundedRect(cx - 20, cy - 20, 40, 40, 3);
      g.lineStyle(2, 0x344a5b).lineBetween(cx - 17, cy - 12, cx + 17, cy - 12).lineBetween(cx - 17, cy + 13, cx + 17, cy + 13);
      for (const dx of [-15, 15]) for (const dy of [-15, 15])
        g.fillStyle(0xe1ebef).fillCircle(cx + dx, cy + dy, 2);
      this.drawModule(cx, cy, "magnet");
    }
    const active = s.robots[s.active];
    const from = this.motion?.before.robots[s.active];
    if ((pullHeld || this.motion?.pull) && active.module === "magnet" && s.crate && same(facingTarget(active), s.crate)) {
      const bot = this.visual(active, from), crate = this.visual(s.crate, this.motion?.before.crate ?? undefined);
      if (Math.abs(bot.x - crate.x) + Math.abs(bot.y - crate.y) < 60) {
        g.lineStyle(10, COLORS.magnet, 0.13).lineBetween(bot.x, bot.y, crate.x, crate.y);
        g.lineStyle(2, COLORS.magnet, 0.9).lineBetween(bot.x, bot.y, crate.x, crate.y);
      }
    }
    for (const id of ["pip", "bolt"] as RobotId[]) this.drawRobot(s, id);
    if (isWon(s)) {
      // Phaser text objects render above Graphics; hide floor annotations
      // before adding the victory text so they cannot cross the dialog.
      if (!preserveLabels) this.labels.forEach((label) => label.setVisible(false));
      g.fillStyle(0x0b1c29, 0.96).fillRoundedRect(150, 240, 550, 150, 18);
      g.lineStyle(2, COLORS.pip).strokeRoundedRect(150, 240, 550, 150, 18);
      this.text(425, 280, "ZUSAMMEN GESCHAFFT!", "#81e4cf", 27);
      this.text(
        425,
        321,
        `${ROOMS[s.room].title} ist gelöst.`,
        "#eaf0f5",
        17,
      );
      this.text(
        425,
        357,
        nextRoom() ? "ENTER  Nächster Raum     ·     R  Neustart     ·     Z  Zurück" : "Alle sechs Räume geschafft!  ·  Danke, Buddies!  ·  R / Z",
        "#a5b9c9",
        13,
      );
    }
  }

  // The same physical module shapes are used on bots and on magnetic metal.
  private drawModule(x: number, y: number, module: Module): void {
    const g = this.graphics;
    if (module === "magnet") {
      g.lineStyle(5, 0xd8e5ec).beginPath().moveTo(x - 6, y - 6)
        .lineTo(x - 6, y + 2).arc(x, y + 2, 6, Math.PI, 0, true)
        .lineTo(x + 6, y - 6).strokePath();
      g.fillStyle(0xff818e).fillRect(x - 9, y - 9, 6, 6);
      g.fillStyle(0x89caff).fillRect(x + 3, y - 9, 6, 6);
      // One striped pole also distinguishes poles without relying on color.
      g.lineStyle(1, 0xffffff).lineBetween(x + 4, y - 7, x + 8, y - 7);
    } else {
      g.fillStyle(0x131e2a).fillRoundedRect(x - 8, y - 9, 16, 20, 2);
      g.lineStyle(2, COLORS.power).strokeRoundedRect(x - 8, y - 9, 16, 20, 2);
      g.fillStyle(0xe7edf0).fillRect(x - 4, y - 12, 8, 3);
      g.fillStyle(COLORS.power).fillPoints([
        new Phaser.Geom.Point(x + 2, y - 7), new Phaser.Geom.Point(x - 5, y + 2),
        new Phaser.Geom.Point(x, y + 2), new Phaser.Geom.Point(x - 2, y + 8),
        new Phaser.Geom.Point(x + 5, y - 1), new Phaser.Geom.Point(x, y - 1),
      ], true);
    }
  }

  private drawRobot(s: State, id: RobotId): void {
    const r = s.robots[id];
    const g = this.graphics;
    const { x, y } = this.visual(r, this.motion?.before.robots[id]);
    const target = ANGLES[r.facing];
    const start = ANGLES[this.motion?.before.robots[id].facing ?? r.facing];
    const difference = Phaser.Math.Angle.Wrap(target - start);
    const turnTime = this.motion ? Math.min(1, (performance.now() - this.motion.started) / (id === "pip" ? 100 : 140)) : 1;
    const angle = start + difference * turnTime * turnTime * (3 - 2 * turnTime);
    const pip = id === "pip";
    const rolling = this.motion && !same(this.motion.before.robots[id], r);
    const travel = this.wheelTravel[id] + (rolling ? this.motion!.progress * (this.motion!.pull ? -30 : 30) : 0);
    const steering = this.steeringTravel[id] + (angle - start) * 8;
    const leftPhase = (((travel - steering) % 6) + 6) % 6;
    const rightPhase = (((travel + steering) % 6) + 6) % 6;
    // Pip springs lightly; Bolt braces with a shorter, heavier chassis response.
    const expression = !reducedMotion() && this.expression?.id === id ? this.expression : undefined;
    const pulse = expression ? Math.sin(Math.min(1, (performance.now() - expression.started) / 180) * Math.PI) : 0;
    const brace = expression?.kind === "bump" ? -1 : expression?.kind === "stop" ? 1 : -0.6;
    gameElement.dataset[`visual${id === "pip" ? "Pip" : "Bolt"}`] = JSON.stringify({ x, y, angle, leftPhase, rightPhase });
    g.fillStyle(0x040a10, 0.4).fillEllipse(x + 2, y + 17, pip ? 31 : 49, 16);
    if (s.connected === id) g.lineStyle(3, COLORS.power).strokeCircle(x, y, 24);
    if (s.active === id) {
      g.lineStyle(2, 0xffffff).strokeRoundedRect(x - 24, y - 24, 48, 48, 5);
      g.fillStyle(0xffffff).fillTriangle(x - 22, y - 22, x - 14, y - 22, x - 22, y - 14);
    }
    // The face and drive rotate with the chassis. The module stays upright
    // at its rotating rear mount, leaving the face clear in every direction.
    g.save().translateCanvas(x, y).rotateCanvas(angle).translateCanvas(0, pulse * brace * (pip ? 2 : 1));
    // A nose arrow supplements the face and the direction on the robot card.
    g.fillStyle(0xf0fcff).fillTriangle(0, -25, -4, -20, 4, -20);
    g.fillStyle(0x08111b);
    if (pip) {
      g.fillRoundedRect(-13, -7, 6, 20, 3).fillRoundedRect(7, -7, 6, 20, 3);
      g.lineStyle(2, 0x849da0).lineBetween(-10, -4 + leftPhase, -10, 2 + leftPhase).lineBetween(10, -4 + rightPhase, 10, 2 + rightPhase);
    } else {
      g.fillRoundedRect(-22, -18, 11, 38, 5).fillRoundedRect(11, -18, 11, 38, 5);
      g.lineStyle(2, 0xa08b6c);
      for (let dy = -20; dy < 18; dy += 6) {
        if (dy + leftPhase >= -16 && dy + leftPhase <= 18)
          g.lineBetween(-21, dy + leftPhase, -12, dy + leftPhase);
        if (dy + rightPhase >= -16 && dy + rightPhase <= 18)
          g.lineBetween(12, dy + rightPhase, 21, dy + rightPhase);
      }
    }
    g.fillStyle(COLORS[id]).fillRoundedRect(pip ? -8 : -16, pip ? -15 : -18, pip ? 16 : 32, pip ? 31 : 36, pip ? 7 : 4);
    g.lineStyle(2, pip ? 0xb3f3e3 : 0xf2d0a2).lineBetween(pip ? -5 : -12, 12, pip ? 5 : 12, 12);
    g.fillStyle(0x102532).fillRoundedRect(pip ? -7 : -13, -14, pip ? 14 : 26, 9, 3);
    g.fillStyle(0xe7fcff).fillCircle(-3.5, -10, pip ? 2.2 : 2).fillCircle(3.5, -10, pip ? 2.2 : 2);
    if (pip) {
      g.lineStyle(2, 0xa1c8c0).lineBetween(0, -15, 4, -21);
      g.fillStyle(COLORS.pip).fillCircle(4, -21, 2);
    } else {
      g.fillStyle(0x8b7358).fillRect(-13, 9, 26, 5);
    }
    g.restore();
    const mx = x - Math.sin(angle) * 9;
    const my = y + Math.cos(angle) * 9;
    g.fillStyle(COLORS[r.module], 0.14).fillCircle(mx, my - 1, 15);
    g.fillStyle(0x263b48).fillRoundedRect(mx - 10, my - 9, 20, 23, 4);
    this.drawModule(mx, my, r.module);
    g.fillStyle(COLORS[r.module]).fillCircle(mx - 10, my + 3, 2).fillCircle(mx + 10, my + 3, 2);
  }

  private reaction(before: State, command: Command): void {
    if (reducedMotion()) return;
    const after = session.state;
    const activated = circuits(after.room).flatMap(c => {
      const sources = [...c.sockets.filter(p => !isPowered(before, p) && isPowered(after, p)),
        ...c.plates.filter(p => !isPlateHeld(before, p) && isPlateHeld(after, p))];
      return sources.length ? [...sources, ...c.doors, ...c.bridges] : [];
    });
    const robots: readonly RobotId[] = command.type === "swap" ? ["pip", "bolt"] : command.type === "interact" ? [before.active] : [];
    if (!activated.length && !robots.length) return;
    const effect = this.add.graphics().setDepth(10);
    this.effects.add(effect);
    for (const p of activated) effect.lineStyle(3, 0xc9ffe9, 0.9)
      .strokeRoundedRect(p.x * TILE + 2, p.y * TILE + 2, 46, 46, 4);
    for (const id of robots) {
      const r = session.state.robots[id];
      effect.lineStyle(3, command.type === "swap" ? 0xffffff : COLORS[before.robots[id].module], 0.85)
        .strokeCircle(r.x * TILE + 25, r.y * TILE + 25, 22);
    }
    this.tweens.add({ targets: effect, alpha: 0, duration: 450, onComplete: () => { effect.destroy(); this.effects.delete(effect); } });
  }

}

new Phaser.Game({
  // This room uses vector Graphics only. Canvas avoids software-WebGL overhead
  // on browsers without a GPU and keeps the small workshop inexpensive to draw.
  type: Phaser.CANVAS,
  parent: "game",
  width: ROOM[0].length * TILE,
  height: ROOM.length * TILE,
  backgroundColor: "#101c2b",
  scene: RoomScene,
  render: { antialias: true },
  scale: { mode: Phaser.Scale.FIT, autoCenter: Phaser.Scale.CENTER_BOTH },
  input: { keyboard: false },
});
