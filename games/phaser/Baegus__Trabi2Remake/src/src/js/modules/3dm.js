export function parse3DM(data) {
	// Header (3 bytes)
	const N = data[0]; // Number of unique 3D models (filename dictionary)
	const M = data[1] | (data[2] << 8); // Total placed object instances on the map

	let offset = 3;
	const instances = [];

	// Read object definitions (10 bytes each)
	// Format: X (2b), Y (2b), padding/params (6b)
	for (let i = 0; i < M; i++) {
		let x = data[offset] | (data[offset + 1] << 8);
		if (x & 0x8000) x -= 0x10000; // Sign extend if negative
		let y = data[offset + 2] | (data[offset + 3] << 8);
		if (y & 0x8000) y -= 0x10000; // Sign extend if negative

		instances.push({ x, y, modelIndex: 0 });
		offset += 10;
	}

	// Read Map grid indices referencing models (M bytes)
	// This tells each instance which dictionary item it points to
	for (let i = 0; i < M; i++) {
		instances[i].modelIndex = data[offset++];
	}

	// Skip any padding (like 0xFF) before the filename strings
	while (data[offset] === 0xFF && offset < data.length) { offset++; }

	// 3. Read Model Filenames String Table (N items, 13 bytes each Pascal string)
	const models = [];
	for (let i = 0; i < N; i++) {
		const len = data[offset];
		let name = "";
		for (let j = 0; j < len; j++) {
			name += String.fromCharCode(data[offset + 1 + j]);
		}
		models.push(name);
		offset += 13;
	}

	let minX = Infinity, maxX = -Infinity;
	let minY = Infinity, maxY = -Infinity;

	const playableInstances = instances.slice(N);
	if (playableInstances.length === 0) return;

	return playableInstances.map(inst => {
		if (inst.x < minX) minX = inst.x;
		if (inst.x > maxX) maxX = inst.x;
		if (inst.y < minY) minY = inst.y;
		if (inst.y > maxY) maxY = inst.y;
		return {
			x: inst.x,
			y: inst.y,
			name: models[inst.modelIndex-1] || undefined
		}
	});
}