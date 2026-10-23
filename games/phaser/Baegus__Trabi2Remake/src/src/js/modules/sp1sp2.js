export const parseSP1SP2 = (scene, filename) => {
	const data = scene.cache.binary.get(filename);
	if (!data || data.length === 0) return { grid: [[-1]], entries: [], tileSize: 25 };

	const lower = filename ? filename.toLowerCase() : "";
	const tileSize = lower.endsWith(".sp1") ? 88 : lower.endsWith(".sp2") ? 25 : 25;

	const entries = [];
	let offset = 0;
	while (offset + 5 <= data.length) {
		let x = data[offset] | (data[offset + 1] << 8);
		if (x & 0x8000) x -= 0x10000; // sign-extend
		let y = data[offset + 2] | (data[offset + 3] << 8);
		if (y & 0x8000) y -= 0x10000; // sign-extend

		const frame = data[offset + 4];
		offset += 5;

		if (x === 0 && y === 0 && frame === 0) continue;

		const col = Math.floor(x / tileSize);
		const row = Math.floor(y / tileSize);
		if (col < 0 || row < 0) continue;


		entries.push({
			x,
			y,
			frame,
		});
	}

	return { entries, tileSize };
}