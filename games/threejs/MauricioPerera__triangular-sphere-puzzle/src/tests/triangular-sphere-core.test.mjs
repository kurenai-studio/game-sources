import assert from 'node:assert/strict';
import test from 'node:test';
import { createTriangularSphere } from '../src/core/triangular-sphere.mjs';

function degreeHistogram(topology) {
  const degrees = topology.vertices.map((vertex) => vertex.faces.length);
  return degrees.reduce((histogram, degree) => {
    histogram[degree] = (histogram[degree] ?? 0) + 1;
    return histogram;
  }, {});
}

test('frecuencia 1 produce el icosaedro base', () => {
  const topology = createTriangularSphere(1);

  assert.equal(topology.subdivision, 1);
  assert.equal(topology.faces.length, 20);
  assert.equal(topology.vertices.length, 12);
  assert.deepEqual(degreeHistogram(topology), { 5: 12 });
});

test('frecuencia 2 produce 80 caras y grados 5/6', () => {
  const topology = createTriangularSphere(2);

  assert.equal(topology.faces.length, 80);
  assert.equal(topology.vertices.length, 42);
  assert.deepEqual(degreeHistogram(topology), { 5: 12, 6: 30 });
});

test('cada cara tiene tres vecinos recíprocos distintos', () => {
  const topology = createTriangularSphere(2);
  const faceIds = new Set(topology.faces.map((face) => face.id));

  for (const face of topology.faces) {
    assert.equal(face.vertices.length, 3);
    assert.equal(face.neighbors.length, 3);
    assert.equal(new Set(face.neighbors).size, 3);
    assert.ok(!face.neighbors.includes(face.id));

    for (const neighborId of face.neighbors) {
      assert.ok(faceIds.has(neighborId));
      const neighbor = topology.faces[neighborId];
      assert.ok(neighbor.neighbors.includes(face.id));
    }
  }
});

test('la salida es determinista', () => {
  assert.deepEqual(createTriangularSphere(2), createTriangularSphere(2));
});

test('rechaza frecuencias no enteras menores que uno', () => {
  for (const subdivision of [0, -1, 1.5, '2']) {
    assert.throws(() => createTriangularSphere(subdivision), RangeError);
  }
});
