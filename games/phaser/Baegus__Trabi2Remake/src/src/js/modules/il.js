export function parseIL(data) {
		const view = new DataView(data.buffer);

		// Ensure file is at least big enough for the header
		if (data.byteLength < 2) {
			console.error("Error: File is too small to be valid.");
			return;
		}

		// 1. Read the number of points (UInt16, Little Endian)
		const numPoints = view.getUint16(0, true);

		const expectedBytes = 2 + (numPoints * 4);
		if (data.byteLength < expectedBytes) {
			console.warn(`Warning: File indicates ${numPoints} points, but only has enough data for ${Math.floor((data.byteLength - 2) / 4)} points.`);
		}

		const points = [];
		let minX = Infinity, maxX = -Infinity;
		let minY = Infinity, maxY = -Infinity;

		// 2. Parse Points (X, Y -> UInt16, Little Endian)
		const pointCountToRead = Math.min(numPoints, Math.floor((data.byteLength - 2) / 4));

		for (let i = 0; i < pointCountToRead; i++) {
			const x = view.getUint16(2 + (i * 4), true) + 320;
			const y = view.getUint16(4 + (i * 4), true) + 240;
			points.push({ x, y });

			if (x < minX) minX = x;
			if (x > maxX) maxX = x;
			if (y < minY) minY = y;
			if (y > maxY) maxY = y;
		}

		return points;
}