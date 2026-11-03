// All rules are plain TypeScript. No Phaser, DOM, timers or hidden state.
export type RobotId = "pip" | "bolt";
export type Module = "magnet" | "power";
export type Direction = "up" | "down" | "left" | "right";
export type Position = Readonly<{ x: number; y: number }>;
export type Robot = Position & Readonly<{ module: Module; facing: Direction }>;
export type State = Readonly<{
  room: RoomId;
  active: RobotId;
  robots: Readonly<Record<RobotId, Robot>>;
  crate: Position | null;
  connected: RobotId | null;
  actions: number;
}>;
export type Action =
  | { type: "move"; direction: Direction }
  | { type: "switch" }
  | { type: "swap" }
  | { type: "interact" }
  // Held E + direction: reverse pulls with magnet; Bolt's forward direction pushes.
  | { type: "pull"; direction: Direction };
export type Result = { state: State; message: string };

// # wall, . floor, v narrow shaft, S socket, D door, P heavy plate, X exit, O ceramic, ~ pit, B bridge.
export const ROOM = [
  "#################",
  "#################",
  "#################",
  "###S#############",
  "###v#############",
  "#.....#.........#",
  "#.....#.........#",
  "#.....D.P.......#",
  "#.....#.........#",
  "#.....#.......XX#",
  "#################",
  "#################",
  "#################",
] as const;

export type RoomId = "bodies" | "modules" | "tech" | "freight" | "routes" | "bridge";
export const ROOM_ORDER: readonly RoomId[] = ["bodies", "modules", "tech", "freight", "routes", "bridge"];
export type Circuit = Readonly<{
  name: string;
  sockets: readonly Position[];
  plates: readonly Position[];
  doors: readonly Position[];
  bridges: readonly Position[];
}>;
type RoomDefinition = Readonly<{
  circuits?: readonly Circuit[];
  title: string;
  objective: string;
  hint: string;
  grid: readonly string[];
  pip: Position;
  bolt: Position;
  crate: Position | null;
}>;
export const ROOMS: Record<RoomId, RoomDefinition> = {
  bodies: {
    title: "01 / Klein & schwer",
    objective: "Bring Pip zum Ausgang und halte mit Bolt die schwere Platte.",
    hint: "Ein schmaler Körper passt durch Gitter. Ein schwerer Körper hält die Tür offen. Shift wechselt deinen Buddy.",
    grid: [
      "#################",
      "#################",
      "#################",
      "#################",
      "#################",
      "#...v.D.X########",
      "#...#############",
      "#....P###########",
      "#...#############",
      "#################",
      "#################",
      "#################",
      "#################",
    ],
    pip: { x: 2, y: 7 }, bolt: { x: 3, y: 7 }, crate: null,
  },
  modules: {
    title: "02 / Energie teilen",
    objective: "Versorge den Anschluss und bring Bolt zum Ausgang.",
    hint: "Magnet zur Kiste ausrichten, E halten und rückwärts fahren. Seitwärts bleibt er stehen. Verankerte Blöcke bleiben fest. Module wechseln mit T nur zwischen Nachbarn; Strom braucht E am Anschluss.",
    grid: [
      "#################",
      "#################",
      "###.....S########",
      "###...###########",
      "###v#############",
      "##O...###########",
      "##....DX#########",
      "##....###########",
      "#################",
      "#################",
      "#################",
      "#################",
      "#################",
    ],
    pip: { x: 3, y: 5 }, bolt: { x: 4, y: 6 }, crate: { x: 6, y: 2 },
  },
  tech: {
    title: "03 / Der Technikraum",
    objective: "Gib Pip die Batterie für den Schacht. Bolt hält drüben die Platte, damit beide den Ausgang erreichen.",
    hint: "Tauscht neben Bolt. Pip versorgt den Anschluss hinter dem Schacht. Bolt fährt durch Tor A auf Platte A. Jetzt kann Pip den Strom lösen und nachkommen.",
    grid: ROOM,
    pip: { x: 3, y: 5 }, bolt: { x: 4, y: 7 }, crate: null,
    circuits: [
      { name: "A", sockets: [{ x: 3, y: 3 }], plates: [{ x: 8, y: 7 }], doors: [{ x: 6, y: 7 }], bridges: [] },
    ],
  },
  freight: {
    title: "04 / Schwere Fracht",
    objective: "Pip versorgt den Schachtanschluss. Bolt schiebt die Fracht in die Plattennische; dann können beide hinaus.",
    hint: "Tauscht zuerst. Pip versorgt A hinter dem Schacht. Bolt fährt oben um die Kiste: nach unten ausrichten, E halten + ↓ schiebt sie in die Sackgasse auf A. Ziehen erreicht diese Nische nicht.",
    grid: [
      "#################", "#################",
      "##....###########",
      "##....###########",
      "##.##P#S#########",
      "##D####v#########",
      "##.......#......#",
      "##.......D......#",
      "##.......#....XX#",
      "#################", "#################", "#################", "#################",
    ],
    pip: { x: 3, y: 7 }, bolt: { x: 4, y: 7 }, crate: { x: 5, y: 3 },
    circuits: [
      { name: "A", sockets: [{ x: 7, y: 4 }], plates: [{ x: 5, y: 4 }], doors: [{ x: 2, y: 5 }, { x: 9, y: 7 }], bridges: [] },
    ],
  },
  routes: {
    title: "05 / Getrennte Wege",
    objective: "Helft euch durch Tor A. Legt die Fracht auf B vor dem letzten Tor, damit beide hinauskommen.",
    hint: "Pip versorgt A, Bolt übernimmt Platte A. Im Mittelraum kann Pip den Magneten zurückbekommen und die Kiste auf B ziehen. Bolt könnte sie auch schieben. Als dauerhafter Wachposten würde er am Ende fehlen.",
    grid: [
      "#################", "#################", "#################",
      "###S#############",
      "###v#############",
      "#.....#....#....#",
      "#.....#....#....#",
      "#.....D.PP.D....#",
      "#.....#....#....#",
      "#.....#....#..XX#",
      "#################", "#################", "#################",
    ],
    pip: { x: 3, y: 5 }, bolt: { x: 4, y: 7 }, crate: { x: 9, y: 6 },
    circuits: [
      { name: "A", sockets: [{ x: 3, y: 3 }], plates: [{ x: 8, y: 7 }], doors: [{ x: 6, y: 7 }], bridges: [] },
      { name: "B", sockets: [], plates: [{ x: 9, y: 7 }], doors: [{ x: 11, y: 7 }], bridges: [] },
    ],
  },
  bridge: {
    title: "06 / Brückendienst",
    objective: "Pip hilft Bolt über die Brücke. Bolt öffnet Pips Partnerweg. Drüben versorgt Pip Bolts Ausgangstor.",
    hint: "Pip übernimmt die Batterie und versorgt die Brücke. Bolt hält drüben A. Pip folgt unten durch Tor A und den Schacht, versorgt Anschluss B und lässt Bolt durch das obere Tor nachkommen. Beide helfen einander vorwärts.",
    grid: [
      "#################", "#################", "#################", "#################",
      "##.....~.......##",
      "##...S.B..P....##",
      "##.....~.......##",
      "##.....~####D####",
      "##.....~.......##",
      "##....Dv..S...X##",
      "########......X##",
      "#################", "#################",
    ],
    pip: { x: 4, y: 7 }, bolt: { x: 5, y: 7 }, crate: null,
    circuits: [
      { name: "C", sockets: [{ x: 5, y: 5 }], plates: [], doors: [], bridges: [{ x: 7, y: 5 }] },
      { name: "A", sockets: [], plates: [{ x: 10, y: 5 }], doors: [{ x: 6, y: 9 }], bridges: [] },
      { name: "B", sockets: [{ x: 10, y: 9 }], plates: [], doors: [{ x: 12, y: 7 }], bridges: [] },
    ],
  },
};

const DELTA: Record<Direction, Position> = {
  up: { x: 0, y: -1 },
  down: { x: 0, y: 1 },
  left: { x: -1, y: 0 },
  right: { x: 1, y: 0 },
};
export const facingTarget = (robot: Robot): Position => ({
  x: robot.x + DELTA[robot.facing].x, y: robot.y + DELTA[robot.facing].y,
});
export const NAMES: Record<RobotId, string> = { pip: "Pip", bolt: "Bolt" };
export const same = (a: Position, b: Position): boolean =>
  a.x === b.x && a.y === b.y;
export const tileAt = (p: Position, room: RoomId = "tech"): string =>
  ROOMS[room].grid[p.y]?.[p.x] ?? "#";
export const otherRobot = (id: RobotId): RobotId =>
  id === "pip" ? "bolt" : "pip";
export const adjacent = (a: Position, b: Position): boolean =>
  Math.abs(a.x - b.x) + Math.abs(a.y - b.y) === 1;

export function initialState(room: RoomId = "tech"): State {
  return {
    room,
    active: "pip",
    robots: {
      pip: { ...ROOMS[room].pip, module: "magnet", facing: "up" },
      bolt: { ...ROOMS[room].bolt, module: "power", facing: "up" },
    },
    crate: ROOMS[room].crate,
    connected: null,
    actions: 0,
  };
}

// Older one-circuit rooms use the same model as the explicitly wired new rooms.
export function circuits(room: RoomId): readonly Circuit[] {
  if (ROOMS[room].circuits) return ROOMS[room].circuits;
  const find = (symbol: string): Position[] => ROOMS[room].grid.flatMap((row, y) =>
    [...row].flatMap((tile, x) => tile === symbol ? [{ x, y }] : []));
  return [{ name: "", sockets: find("S"), plates: find("P"), doors: find("D"), bridges: [] }];
}
export function isPowered(s: State, socket?: Position): boolean {
  if (!s.connected) return false;
  const robot = s.robots[s.connected];
  return robot.module === "power" && tileAt(robot, s.room) === "S" && (!socket || same(robot, socket));
}
export const isPlateHeld = (s: State, plate?: Position): boolean =>
  [s.robots.bolt, s.crate].some(p => p && tileAt(p, s.room) === "P" && (!plate || same(p, plate)));
export const circuitOn = (s: State, circuit: Circuit): boolean =>
  circuit.sockets.some(p => isPowered(s, p)) || circuit.plates.some(p => isPlateHeld(s, p));
export function isDoorOpen(s: State, door?: Position): boolean {
  return circuits(s.room).some(c => (!door || c.doors.some(p => same(p, door))) && c.doors.length > 0 && circuitOn(s, c));
}
export function isBridgeOpen(s: State, bridge: Position): boolean {
  const circuit = circuits(s.room).find(c => c.bridges.some(p => same(p, bridge)));
  if (!circuit) return false;
  // Occupancy interlock covers the entire span, including crates. No crushing,
  // falling, or retracting under a passenger when power/supplier changes.
  return circuitOn(s, circuit) || [...Object.values(s.robots), s.crate].some(
    p => p && circuit.bridges.some(b => same(p, b)));
}
export const isWon = (s: State): boolean =>
  s.room === "bodies"
    ? tileAt(s.robots.pip, s.room) === "X" && isPlateHeld(s)
    : s.room === "modules"
      ? isPowered(s) && tileAt(s.robots.bolt, s.room) === "X"
      : Object.values(s.robots).every((r) => tileAt(r, s.room) === "X");

function blocked(s: State, id: RobotId | "crate", target: Position): string | null {
  const tile = tileAt(target, s.room);
  if (tile === "O") return "Der Keramikblock ist verankert und nicht magnetisch. Er bleibt fest.";
  if (tile === "~") return "Hier ist die Wartungsgrube. Nur eine ausgefahrene Brücke trägt dich.";
  if (tile === "B" && !isBridgeOpen(s, target)) return "Die Brücke braucht ihren Stromanschluss. Besetzt bleibt sie sicher ausgefahren.";
  if (tile === "#") return "Hier ist eine Wand.";
  if (tile === "v" && id !== "pip")
    return "Nur Pip passt durch den Schacht. Bolt und die Fracht sind zu breit.";
  if (tile === "D" && !isDoorOpen(s, target))
    return "Diese Tür braucht ihren zugeordneten Anschluss oder eine schwere Last auf ihrer Platte.";
  if (id !== "crate" && s.crate && same(target, s.crate))
    return "Metallkiste: Magnet + E rückwärts zieht. Bolt + E vorwärts schiebt, mit jedem Modul. Erst zur Kiste ausrichten.";
  if ((["pip", "bolt"] as const).some(bot => bot !== id && same(target, s.robots[bot])))
    return "Hier steht dein Buddy. Shift wechselt, T tauscht benachbarte Module.";
  return null;
}

// A rejected move may turn the robot to face an object. That turn is undoable too.
export function transition(s: State, action: Action): Result {
  if (isWon(s))
    return {
      state: s,
      message:
        "Geschafft! Raumziel erreicht. Enter oder Weiter führt zum nächsten Raum; am Ende hilft die Raumwahl. R startet neu, Z geht zurück.",
    };
  const id = s.active;
  const robot = s.robots[id];
  const buddyId = otherRobot(id);
  const buddy = s.robots[buddyId];
  const accept = (patch: Partial<State>, message: string): Result => ({
    state: { ...s, ...patch, actions: s.actions + 1 },
    message,
  });
  const reject = (message: string): Result => ({ state: s, message });
  if (action.type === "switch") {
    return accept(
      { active: buddyId },
      `${NAMES[buddyId]} ist aktiv.${isPowered(s) ? " Der Anschluss bleibt versorgt." : ""}`,
    );
  }
  if (action.type === "swap") {
    if (!adjacent(robot, buddy))
      return reject(
        "Zum Tauschen direkt nebeneinander stehen — diagonal reicht nicht.",
      );
    return accept(
      {
        robots: {
          ...s.robots,
          [id]: { ...robot, module: buddy.module },
          [buddyId]: { ...buddy, module: robot.module },
        },
        connected: null,
      },
      "Module getauscht. Pip und Bolt tragen jetzt das jeweils andere Modul.",
    );
  }
  if (action.type === "interact" && robot.module === "magnet") {
    const front = facingTarget(robot);
    return reject(tileAt(front, s.room) === "O"
      ? "Keine Magnetwirkung: Dieser Keramikblock ist verankert und nicht magnetisch."
      : `Magnet bereit: E + rückwärts zieht.${id === "bolt" ? " Bolt schiebt mit E + vorwärts." : " Nur Bolt kann vorwärts schieben."} E loslassen zum Drehen.`);
  }
  if (action.type === "pull" && id === "bolt" && action.direction === robot.facing) {
    const front = facingTarget(robot);
    if (!s.crate || !same(front, s.crate)) return reject("Keine Metallkiste direkt vor Bolt. E loslassen und zur Kiste ausrichten.");
    const delta = DELTA[robot.facing];
    const target = { x: front.x + delta.x, y: front.y + delta.y };
    const reason = blocked(s, "crate", target);
    if (reason) return reject(`Kein Platz für die Fracht. ${reason}`);
    return accept({ crate: target, robots: { ...s.robots, bolt: { ...robot, ...front } }, connected: s.connected === id ? null : s.connected },
      "Bolt schiebt mit Körperkraft. Beide fahren ein Feld vorwärts; jedes Modul bleibt nutzbar.");
  }
  if (action.type === "pull") {
    if (robot.module !== "magnet") return reject("Zum Ziehen brauchst du das Magnetmodul.");
    const delta = DELTA[robot.facing];
    const movement = DELTA[action.direction];
    if (movement.x !== -delta.x || movement.y !== -delta.y)
      return reject("Beim Ziehen nur rückwärts von der Kiste wegfahren. E loslassen, um dich neu auszurichten.");
    const front = facingTarget(robot);
    if (tileAt(front, s.room) === "O") return reject("Der Keramikblock ist verankert und nicht magnetisch.");
    if (!s.crate || !same(front, s.crate))
      return reject("Kein Metall direkt vor dem Magneten. E loslassen und zur benachbarten Kiste schauen.");
    if (tileAt(robot, s.room) === "v") return reject("Die Fracht passt nicht in den Schacht. Ziehen braucht auch für die Kiste Platz.");
    const back = { x: robot.x + movement.x, y: robot.y + movement.y };
    if (blocked(s, id, back)) return reject("Kein Platz zum Zurückziehen. Hinter dir muss ein freies, begehbares Feld sein.");
    return accept({ crate: { x: robot.x, y: robot.y }, robots: { ...s.robots, [id]: { ...robot, ...back } } },
      "Magnet zieht: Du fährst rückwärts, die Metallkiste folgt. Der Blick bleibt zur Kiste.");
  }
  if (action.type === "move") {
    const delta = DELTA[action.direction];
    const target = { x: robot.x + delta.x, y: robot.y + delta.y };
    const reason = blocked(s, id, target);
    if (reason && robot.facing === action.direction) return reject(reason);
    const nextRobot = {
      ...robot,
      ...(reason ? {} : target),
      facing: action.direction,
    };
    const nextConnected = !reason && s.connected === id ? null : s.connected;
    let message = reason ?? `${NAMES[id]} geht ein Feld.`;
    if (!reason && s.connected === id)
      message =
        `${NAMES[id]} hat den Anschluss verlassen. Die Stromverbindung ist gelöst.`;
    if (!reason && tileAt(target, s.room) === "P")
      message =
        id === "bolt"
          ? "Bolt drückt die schwere Platte ein. Die zugeordnete Tür bleibt offen."
          : "Pip ist zu leicht. Bolt oder eine Metallkiste halten diese Platte.";
    if (!reason && tileAt(target, s.room) === "S")
      message = "Anschluss erreicht. Mit Strommodul und E verbinden.";
    const result = accept(
      { robots: { ...s.robots, [id]: nextRobot }, connected: nextConnected },
      message,
    );
    if (isWon(result.state))
      result.message =
        `Geschafft! ${ROOMS[s.room].title} ist gelöst. R: noch einmal · Z: zurück.`;
    return result;
  }
  if (robot.module === "power") {
    if (tileAt(robot, s.room) !== "S")
      return reject(
        `Batterie: Auf dem Ringfeld mit E verbinden.${id === "bolt" ? " Zum Schieben E halten + vorwärts zur Kiste." : ""}`,
      );
    const connected = s.connected === id ? null : id;
    return accept(
      { connected },
      connected
        ? "Strom verbunden. Der zugeordnete Weg ist offen. Shift wechselt den Buddy und lässt den Strom an."
        : "Strom gelöst. Bolt oder eine Kiste können eine zugeordnete Platte halten. Besetzte Brücken bleiben sicher ausgefahren.",
    );
  }
  return reject("E halten und rückwärts fahren.");
}

export type Session = Readonly<{
  state: State;
  history: readonly State[];
  message: string;
}>;
export type Command = Action | { type: "undo" } | { type: "restart" } | { type: "room"; room: RoomId };
export function newSession(room: RoomId = "tech"): Session {
  return {
    state: initialState(room),
    history: [],
    message:
      ROOMS[room].objective,
  };
}
export function dispatch(session: Session, command: Command): Session {
  if (command.type === "room") return newSession(command.room);
  if (command.type === "restart")
    return {
      ...newSession(session.state.room),
      message: "Raum neu gestartet. Pip trägt Magnet, Bolt trägt Strom.",
    };
  if (command.type === "undo") {
    const previous = session.history.at(-1);
    return previous
      ? {
          state: previous,
          history: session.history.slice(0, -1),
          message:
            "Letzte Aktion zurückgenommen — inklusive Blickrichtung und Verbindung.",
        }
      : { ...session, message: "Noch keine Aktion zum Zurücknehmen." };
  }
  const result = transition(session.state, command);
  return {
    state: result.state,
    history:
      result.state === session.state
        ? session.history
        : [...session.history, session.state],
    message: result.message,
  };
}
