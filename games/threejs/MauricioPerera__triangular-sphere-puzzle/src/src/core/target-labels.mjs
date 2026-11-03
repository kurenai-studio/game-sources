const COLOR_PALETTE = [
  { name: 'rojo', value: '#e63946' },
  { name: 'amarillo', value: '#f1c40f' },
  { name: 'verde', value: '#2a9d8f' },
  { name: 'azul', value: '#3182ce' },
  { name: 'morado', value: '#8e44ad' },
];

function buildFaceConstraints(topology) {
  const constraints = topology.faces.map(() => new Set());
  for (const vertex of topology.vertices) {
    if (vertex.faces.length !== 5) {
      throw new RangeError('Numbered targets require a degree-5 sphere topology');
    }
    for (const first of vertex.faces) {
      for (const second of vertex.faces) {
        if (first !== second) constraints[first].add(second);
      }
    }
  }
  return constraints;
}

function solveFaceAssignment(constraints, reverse = false, forbidden = null, completeCheck = null) {
  const numbers = Array(constraints.length).fill(0);

  function chooseNextFace() {
    let selected = -1;
    let bestAssignedNeighbors = -1;
    for (let faceId = 0; faceId < numbers.length; faceId += 1) {
      if (numbers[faceId] !== 0) continue;
      const assignedNeighbors = [...constraints[faceId]]
        .filter((neighborId) => numbers[neighborId] !== 0).length;
      if (
        assignedNeighbors > bestAssignedNeighbors
        || (assignedNeighbors === bestAssignedNeighbors && (
          selected === -1 || (reverse ? faceId > selected : faceId < selected)
        ))
      ) {
        selected = faceId;
        bestAssignedNeighbors = assignedNeighbors;
      }
    }
    return selected;
  }

  function search(assigned) {
    if (assigned === numbers.length) return completeCheck ? completeCheck(numbers) : true;
    const faceId = chooseNextFace();
    const used = new Set([...constraints[faceId]].map((neighborId) => numbers[neighborId]));
    const candidateNumbers = reverse ? [5, 4, 3, 2, 1] : [1, 2, 3, 4, 5];
    for (const number of candidateNumbers) {
      if (used.has(number) || forbidden?.[faceId] === number) continue;
      numbers[faceId] = number;
      if (search(assigned + 1)) return true;
    }
    numbers[faceId] = 0;
    return false;
  }

  if (!search(0)) throw new Error('Unable to assign values to the sphere faces');
  return numbers;
}

export function createTargetLabels(topology) {
  const constraints = buildFaceConstraints(topology);
  const numbers = solveFaceAssignment(constraints);
  const colors = solveFaceAssignment(constraints, true, numbers, (assignment) => {
    const numbersByColor = Array.from({ length: 5 }, () => new Set());
    assignment.forEach((color, faceId) => numbersByColor[color - 1].add(numbers[faceId]));
    return numbersByColor.every((values) => values.size >= 2);
  });
  return Object.freeze(topology.faces.map((face) => Object.freeze({
    faceId: face.id,
    number: numbers[face.id],
    color: COLOR_PALETTE[colors[face.id] - 1].value,
    colorName: COLOR_PALETTE[colors[face.id] - 1].name,
  })));
}
