const GOLDEN_RATIO = (1 + Math.sqrt(5)) / 2;

const BASE_VERTICES = [
  [-1, GOLDEN_RATIO, 0],
  [1, GOLDEN_RATIO, 0],
  [-1, -GOLDEN_RATIO, 0],
  [1, -GOLDEN_RATIO, 0],
  [0, -1, GOLDEN_RATIO],
  [0, 1, GOLDEN_RATIO],
  [0, -1, -GOLDEN_RATIO],
  [0, 1, -GOLDEN_RATIO],
  [GOLDEN_RATIO, 0, -1],
  [GOLDEN_RATIO, 0, 1],
  [-GOLDEN_RATIO, 0, -1],
  [-GOLDEN_RATIO, 0, 1],
];

const BASE_FACES = [
  [0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
  [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
  [3, 4, 9], [3, 9, 8], [3, 8, 6], [3, 6, 2], [3, 2, 4],
  [4, 2, 11], [2, 6, 10], [6, 8, 7], [8, 9, 1], [9, 4, 5],
];

function pointKey(point) {
  return point.map((coordinate) => coordinate.toFixed(10)).join(',');
}

function interpolate(a, b, c, i, j, k, subdivision) {
  return [
    (a[0] * i + b[0] * j + c[0] * k) / subdivision,
    (a[1] * i + b[1] * j + c[1] * k) / subdivision,
    (a[2] * i + b[2] * j + c[2] * k) / subdivision,
  ];
}

function addVertex(vertices, vertexIndex, point) {
  const key = pointKey(point);
  let id = vertexIndex.get(key);
  if (id === undefined) {
    id = vertices.length;
    vertexIndex.set(key, id);
    vertices.push({ id, position: point, faces: [] });
  }
  return id;
}

function addFace(faces, vertices, vertexIds) {
  const id = faces.length;
  faces.push({ id, vertices: vertexIds, neighbors: [] });
  for (const vertexId of vertexIds) vertices[vertexId].faces.push(id);
}

function connectNeighbors(faces) {
  const edgeOwners = new Map();
  for (const face of faces) {
    for (let index = 0; index < face.vertices.length; index += 1) {
      const first = face.vertices[index];
      const second = face.vertices[(index + 1) % face.vertices.length];
      const edge = [first, second].sort((a, b) => a - b).join(':');
      const owner = edgeOwners.get(edge);
      if (owner === undefined) {
        edgeOwners.set(edge, face.id);
      } else {
        faces[owner].neighbors.push(face.id);
        face.neighbors.push(owner);
      }
    }
  }
}

function subdivisionPoints(a, b, c, subdivision, getVertexId) {
  const points = new Map();
  for (let row = 0; row <= subdivision; row += 1) {
    for (let column = 0; column <= subdivision - row; column += 1) {
      const point = interpolate(
        a,
        b,
        c,
        subdivision - row - column,
        column,
        row,
        subdivision,
      );
      points.set(`${row}:${column}`, getVertexId(point));
    }
  }
  return points;
}

function makeSubdivisionFaces(points, subdivision, addTriangle) {
  const point = (row, column) => points.get(`${row}:${column}`);
  for (let row = 0; row < subdivision; row += 1) {
    for (let column = 0; column < subdivision - row; column += 1) {
      addTriangle([point(row, column), point(row, column + 1), point(row + 1, column)]);
      if (column < subdivision - row - 1) {
        addTriangle([
          point(row, column + 1),
          point(row + 1, column + 1),
          point(row + 1, column),
        ]);
      }
    }
  }
}

export function createTriangularSphere(subdivision = 1) {
  if (!Number.isInteger(subdivision) || subdivision < 1) {
    throw new RangeError('subdivision must be an integer greater than or equal to 1');
  }

  const vertices = [];
  const faces = [];
  const vertexIndex = new Map();
  const getVertexId = (point) => addVertex(vertices, vertexIndex, point);

  for (const [first, second, third] of BASE_FACES) {
    const points = subdivisionPoints(
      BASE_VERTICES[first],
      BASE_VERTICES[second],
      BASE_VERTICES[third],
      subdivision,
      getVertexId,
    );
    makeSubdivisionFaces(points, subdivision, (vertexIds) => addFace(faces, vertices, vertexIds));
  }

  connectNeighbors(faces);
  return { subdivision, vertices, faces };
}
