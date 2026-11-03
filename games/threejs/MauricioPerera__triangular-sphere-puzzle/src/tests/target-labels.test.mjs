import test from 'node:test';
import assert from 'node:assert/strict';
import { createTriangularSphere } from '../src/core/triangular-sphere.mjs';
import { createTargetLabels } from '../src/core/target-labels.mjs';

test('crea una etiqueta numerada para cada cara del icosaedro', () => {
  const topology = createTriangularSphere(1);
  const labels = createTargetLabels(topology);

  assert.equal(labels.length, 20);
  assert.deepEqual([...new Set(labels.map((label) => label.number))].sort(), [1, 2, 3, 4, 5]);
  assert.equal(new Set(labels.map((label) => label.color)).size, 5);
  assert.deepEqual([...new Set(labels.map((label) => label.colorName))].sort(), [
    'amarillo', 'azul', 'morado', 'rojo', 'verde',
  ]);
  for (const vertex of topology.vertices) {
    assert.equal(new Set(vertex.faces.map((faceId) => labels[faceId].color)).size, 5);
  }
  assert.equal(new Set(labels.map((label) => `${label.number}|${label.color}`)).size, 20);
  for (const vertex of topology.vertices) {
    assert.deepEqual(
      vertex.faces.map((faceId) => labels[faceId].number).sort(),
      [1, 2, 3, 4, 5],
    );
  }
});

test('rechaza topologías subdivididas con vértices de grado 6', () => {
  const topology = createTriangularSphere(2);

  assert.throws(() => createTargetLabels(topology), RangeError);
});
