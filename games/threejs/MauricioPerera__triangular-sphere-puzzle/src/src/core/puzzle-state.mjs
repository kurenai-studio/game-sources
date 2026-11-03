function assertFaceId(topology, faceId) {
  if (!Number.isInteger(faceId) || faceId < 0 || faceId >= topology.faces.length) {
    throw new RangeError(`face id out of range: ${faceId}`);
  }
}

function freezeState(topology, emptyFaceId, ballsByFace, moves, lastMove = null) {
  return Object.freeze({
    topology,
    emptyFaceId,
    ballsByFace: Object.freeze(ballsByFace),
    moves,
    lastMove,
  });
}

export function createPuzzleState(topology, emptyFaceId = 0) {
  assertFaceId(topology, emptyFaceId);
  const ballsByFace = topology.faces.map((face) => (face.id === emptyFaceId ? null : face.id));
  return freezeState(topology, emptyFaceId, ballsByFace, 0);
}

export function applyMove(state, fromFaceId) {
  assertFaceId(state.topology, fromFaceId);
  const emptyFaceId = state.emptyFaceId;
  const emptyFace = state.topology.faces[emptyFaceId];
  if (!emptyFace.neighbors.includes(fromFaceId) || state.ballsByFace[fromFaceId] === null) {
    return state;
  }

  const ballsByFace = [...state.ballsByFace];
  ballsByFace[emptyFaceId] = ballsByFace[fromFaceId];
  ballsByFace[fromFaceId] = null;
  return freezeState(
    state.topology,
    fromFaceId,
    ballsByFace,
    state.moves + 1,
    { fromFaceId, toFaceId: emptyFaceId },
  );
}

export function isSolved(state) {
  return state.ballsByFace.every((ballId, faceId) => (
    faceId === state.emptyFaceId ? ballId === null : ballId === faceId
  ));
}

export function shufflePuzzle(state, steps = 30, random = Math.random) {
  if (!Number.isInteger(steps) || steps < 1) {
    throw new RangeError('steps must be an integer greater than or equal to one');
  }
  if (typeof random !== 'function') throw new TypeError('random must be a function');

  let shuffled = state;
  for (let step = 0; step < steps; step += 1) {
    const previousEmptyFaceId = shuffled.lastMove?.toFaceId;
    const candidates = shuffled.topology.faces[shuffled.emptyFaceId].neighbors
      .filter((faceId) => faceId !== previousEmptyFaceId);
    const choice = Math.min(candidates.length - 1, Math.floor(random() * candidates.length));
    shuffled = applyMove(shuffled, candidates[Math.max(0, choice)]);
  }

  if (isSolved(shuffled)) {
    const fallback = shuffled.topology.faces[shuffled.emptyFaceId].neighbors[0];
    shuffled = applyMove(shuffled, fallback);
  }

  return freezeState(
    shuffled.topology,
    shuffled.emptyFaceId,
    [...shuffled.ballsByFace],
    0,
    null,
  );
}
