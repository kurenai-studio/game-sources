export function parseLAP(data) {
	const view = new DataView(data.buffer);
	const filenameLen = view.getUint8(0);

	const dataOffset = 1 + filenameLen + 2;

	const points = [];

	for (let i = dataOffset; i <= data.length - 6; i += 6) {
		points.push({
			x: view.getUint16(i, true),
			y: view.getUint16(i + 2, true),
			h: view.getUint16(i + 4, true)
		});
	}

	console.log("points found", points);

	return {
		start: points[0],
		checkpoint: points[1],
		repairDepo: points[2],
	};
}