import { OPPOSITE_DIRECTION, type Direction, type DungeonLayout, type RoomNode } from '@/game/types';
import { SeededRng } from '@/game/systems/rng';

const STEPS: ReadonlyArray<{ direction: Direction; dx: number; dy: number }> = [
  { direction: 'north', dx: 0, dy: -1 },
  { direction: 'east', dx: 1, dy: 0 },
  { direction: 'south', dx: 0, dy: 1 },
  { direction: 'west', dx: -1, dy: 0 },
];

function key(x: number, y: number): string {
  return `${x},${y}`;
}

function connectRooms(left: RoomNode, right: RoomNode, direction: Direction): void {
  left.neighbors[direction] = right.id;
  right.neighbors[OPPOSITE_DIRECTION[direction]] = left.id;
}

function calculateDistances(rooms: RoomNode[], startId: string): void {
  const roomById = new Map(rooms.map((room) => [room.id, room]));
  const queue: Array<{ id: string; distance: number }> = [{ id: startId, distance: 0 }];
  const visited = new Set<string>();

  while (queue.length > 0) {
    const entry = queue.shift();
    if (!entry || visited.has(entry.id)) continue;
    visited.add(entry.id);
    const room = roomById.get(entry.id);
    if (!room) continue;
    room.distance = entry.distance;
    for (const target of Object.values(room.neighbors)) {
      if (target && !visited.has(target)) queue.push({ id: target, distance: entry.distance + 1 });
    }
  }
}

export function generateDungeon(seed: string, roomCount?: number): DungeonLayout {
  const rng = new SeededRng(`${seed}::dungeon`);
  const targetCount = roomCount ?? rng.int(5, 8);
  if (targetCount < 5 || targetCount > 8) throw new RangeError('Dungeon room count must be between 5 and 8');

  const rooms: RoomNode[] = [
    {
      id: 'room-0',
      index: 0,
      x: 0,
      y: 0,
      kind: 'start',
      distance: 0,
      neighbors: {},
      visited: false,
      cleared: true,
      rewardClaimed: true,
    },
  ];
  const occupied = new Map<string, RoomNode>([[key(0, 0), rooms[0] as RoomNode]]);

  let cursor = rooms[0] as RoomNode;
  let previousDirection: Direction | undefined;
  for (let pathIndex = 0; pathIndex < 3; pathIndex += 1) {
    const candidates = rng
      .shuffle(STEPS)
      .filter((step) => step.direction !== OPPOSITE_DIRECTION[previousDirection ?? step.direction])
      .filter((step) => !occupied.has(key(cursor.x + step.dx, cursor.y + step.dy)));
    const step = candidates[0] ?? rng.pick(STEPS);
    const next: RoomNode = {
      id: `room-${rooms.length}`,
      index: rooms.length,
      x: cursor.x + step.dx,
      y: cursor.y + step.dy,
      kind: 'combat',
      distance: 0,
      neighbors: {},
      visited: false,
      cleared: false,
      rewardClaimed: false,
    };
    rooms.push(next);
    occupied.set(key(next.x, next.y), next);
    connectRooms(cursor, next, step.direction);
    cursor = next;
    previousDirection = step.direction;
  }

  let attempts = 0;
  while (rooms.length < targetCount && attempts < 500) {
    attempts += 1;
    const origin = rng.pick(rooms);
    const step = rng.pick(STEPS);
    const destinationKey = key(origin.x + step.dx, origin.y + step.dy);
    if (occupied.has(destinationKey)) continue;
    const next: RoomNode = {
      id: `room-${rooms.length}`,
      index: rooms.length,
      x: origin.x + step.dx,
      y: origin.y + step.dy,
      kind: 'combat',
      distance: 0,
      neighbors: {},
      visited: false,
      cleared: false,
      rewardClaimed: false,
    };
    rooms.push(next);
    occupied.set(destinationKey, next);
    connectRooms(origin, next, step.direction);
  }

  if (rooms.length !== targetCount) throw new Error('Unable to generate a complete dungeon layout');
  calculateDistances(rooms, 'room-0');

  const leaves = rooms.filter((room) => room.id !== 'room-0' && Object.keys(room.neighbors).length === 1);
  const boss = [...(leaves.length > 0 ? leaves : rooms.slice(1))].sort(
    (left, right) => right.distance - left.distance || right.index - left.index,
  )[0];
  if (!boss) throw new Error('Dungeon did not produce a boss room candidate');
  boss.kind = 'boss';

  const treasureCandidates = rooms
    .filter((room) => room.id !== 'room-0' && room.id !== boss.id)
    .sort((left, right) => right.distance - left.distance || left.index - right.index);
  const treasure =
    treasureCandidates.find((room) => Object.keys(room.neighbors).length === 1) ?? treasureCandidates[0];
  if (!treasure) throw new Error('Dungeon did not produce a treasure room candidate');
  treasure.kind = 'treasure';

  const layout: DungeonLayout = {
    seed,
    rooms,
    startId: 'room-0',
    treasureId: treasure.id,
    bossId: boss.id,
  };
  const errors = validateDungeon(layout);
  if (errors.length > 0) throw new Error(`Invalid dungeon: ${errors.join('; ')}`);
  return layout;
}

export function validateDungeon(layout: DungeonLayout): string[] {
  const errors: string[] = [];
  if (layout.rooms.length < 5 || layout.rooms.length > 8) errors.push('room count must be 5–8');
  const roomById = new Map(layout.rooms.map((room) => [room.id, room]));
  const coordinates = new Set<string>();
  const visited = new Set<string>();
  const queue = [layout.startId];

  for (const room of layout.rooms) {
    const coordinate = key(room.x, room.y);
    if (coordinates.has(coordinate)) errors.push(`duplicate coordinate ${coordinate}`);
    coordinates.add(coordinate);
    for (const [direction, targetId] of Object.entries(room.neighbors) as Array<[Direction, string]>) {
      const target = roomById.get(targetId);
      if (!target) {
        errors.push(`${room.id} has a dangling ${direction} door`);
        continue;
      }
      if (target.neighbors[OPPOSITE_DIRECTION[direction]] !== room.id) {
        errors.push(`${room.id} ${direction} door is not bidirectional`);
      }
    }
  }

  while (queue.length > 0) {
    const id = queue.shift();
    if (!id || visited.has(id)) continue;
    visited.add(id);
    const room = roomById.get(id);
    if (room) queue.push(...Object.values(room.neighbors).filter((value): value is string => Boolean(value)));
  }
  if (visited.size !== layout.rooms.length) errors.push('not all rooms are reachable');
  if (layout.rooms.filter((room) => room.kind === 'boss').length !== 1)
    errors.push('must have exactly one boss room');
  if (layout.rooms.filter((room) => room.kind === 'treasure').length !== 1)
    errors.push('must have exactly one treasure room');
  if (layout.bossId === layout.treasureId || layout.bossId === layout.startId)
    errors.push('special rooms overlap');
  const boss = roomById.get(layout.bossId);
  if (!boss || boss.distance < 3) errors.push('boss must be at least three doors from start');
  return errors;
}
