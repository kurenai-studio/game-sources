import assert from 'node:assert/strict';
import test from 'node:test';
import { createTriangularSphere } from '../src/core/triangular-sphere.mjs';
import { applyMove, createPuzzleState, isSolved, shufflePuzzle } from '../src/core/puzzle-state.mjs';

const topology = createTriangularSphere(1);

test('crea un tablero resuelto con una sola cara vacía', () => {
  const state = createPuzzleState(topology, 0);

  assert.equal(state.emptyFaceId, 0);
  assert.equal(state.moves, 0);
  assert.equal(state.ballsByFace.filter((ball) => ball === null).length, 1);
  assert.equal(state.ballsByFace[0], null);
  assert.ok(isSolved(state));
});

test('mueve una esfera hacia el hueco vecino sin mutar el estado anterior', () => {
  const state = createPuzzleState(topology, 0);
  const sourceFaceId = topology.faces[0].neighbors[0];
  const next = applyMove(state, sourceFaceId);

  assert.notEqual(next, state);
  assert.equal(next.emptyFaceId, sourceFaceId);
  assert.equal(next.ballsByFace[0], sourceFaceId);
  assert.equal(next.ballsByFace[sourceFaceId], null);
  assert.equal(next.moves, 1);
  assert.equal(state.emptyFaceId, 0);
  assert.equal(state.ballsByFace[0], null);
  assert.equal(state.moves, 0);
  assert.equal(isSolved(next), false);
});

test('rechaza una cara no vecina sin cambiar el estado', () => {
  const state = createPuzzleState(topology, 0);
  const neighborIds = new Set(topology.faces[0].neighbors);
  const nonNeighbor = topology.faces.find((face) => face.id !== 0 && !neighborIds.has(face.id));
  const next = applyMove(state, nonNeighbor.id);

  assert.equal(next, state);
  assert.equal(next.moves, 0);
  assert.ok(isSolved(next));
});

test('un movimiento legal puede deshacerse', () => {
  const state = createPuzzleState(topology, 0);
  const sourceFaceId = topology.faces[0].neighbors[0];
  const moved = applyMove(state, sourceFaceId);
  const restored = applyMove(moved, 0);

  assert.deepEqual(restored.ballsByFace, state.ballsByFace);
  assert.equal(restored.emptyFaceId, state.emptyFaceId);
  assert.equal(restored.moves, 2);
  assert.ok(isSolved(restored));
});

test('rechaza identificadores inexistentes', () => {
  const state = createPuzzleState(topology, 0);

  assert.throws(() => applyMove(state, -1), RangeError);
  assert.throws(() => applyMove(state, topology.faces.length), RangeError);
});

test('desordena mediante movimientos legales sin mutar el estado resuelto', () => {
  const topology = createTriangularSphere(1);
  const solved = createPuzzleState(topology, 19);
  const shuffled = shufflePuzzle(solved, 12, () => 0.25);

  assert.equal(isSolved(solved), true);
  assert.equal(isSolved(shuffled), false);
  assert.equal(shuffled.moves, 0);
  assert.equal(shuffled.ballsByFace.filter((ballId) => ballId === null).length, 1);
  assert.deepEqual(solved.ballsByFace, topology.faces.map((face) => face.id === 19 ? null : face.id));
});
