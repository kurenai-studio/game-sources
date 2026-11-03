export function createBox(a1: number, b1: number, h: number, a2: number, b2: number) {
	const corners = [
		[-a1, 0, -b1],
		[-a1, 0, b1],
		[-a2, h, -b2],
		[-a2, h, b2],
		[a1, 0, -b1],
		[a1, 0, b1],
		[a2, h, -b2],
		[a2, h, b2],
	];

	// With correct winding order (if backface culling is on)
	const vertices = [
		0, 1, 2, 2, 1, 3, // -X
		0, 4, 1, 1, 4, 5, // -Y
		0, 2, 4, 4, 2, 6, // -Z
		1, 5, 3, 3, 5, 7, // +Z
		2, 3, 6, 6, 3, 7, // +Y
		4, 6, 5, 5, 6, 7, // +X
	];

	return vertices.flatMap((v, i) => [...corners[v]!, i / 6 | 0]);
}

export function createRibbon() {
	const vertices: number[] = [];

	for (let i = 0; i < 1; i += 1/64) {
		vertices.push(...[
			-.5, 0, i, -1,
			-.5, 0, i + 1/32, -1,
			.5, 0, i, 0,
			.5, 0, i, 0,
			-.5, 0, i + 1/32, -1,
			.5, 0, i + 1/32, 0
		]);
	}

	return vertices;
}

export function createPill(
	bottomRadius: number,
	topRadius: number,
	height: number
) {
	const segments = 24;
	const capSegments = 6;

	const vertices: number[] = [];
	const slope = (topRadius - bottomRadius) / height;
	const tangentAngle = Math.acos(slope || 0);

	function addVertex(r: number, y: number, segment: number) {
		vertices.push(
			r * Math.cos(segment * Math.PI * 2 / segments),
			y,
			r * Math.sin(segment * Math.PI * 2 / segments),
			Math.cos(segment * Math.PI * 2 / segments)*.38-.5,
		);
	}

	function getRing(index: number): [number, number] {
		let angle = tangentAngle * index / capSegments;
		let radius = bottomRadius;
		let h = 0;

		if (index > capSegments) {
			angle = tangentAngle +
				(Math.PI - tangentAngle) *
				(index - capSegments - 1) / capSegments;
			radius = topRadius;
			h = height;
		}

		return [
			radius * Math.sin(angle),
			h - radius * Math.cos(angle)
		];
	}

	for (let ring = 0; ring < capSegments * 2 + 1; ring++) {
		const bottom = getRing(ring);
		const top = getRing(ring + 1);

		for (let segment = 0; segment < segments; segment++) {
			addVertex(...bottom, segment);
			addVertex(...top, segment);
			addVertex(...top, segment + 1);

			addVertex(...bottom, segment);
			addVertex(...top, segment + 1);
			addVertex(...bottom, segment + 1);
		}
	}

	return vertices;
}
