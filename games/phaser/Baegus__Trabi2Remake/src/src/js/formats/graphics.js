// Pre-compute the RGB565 look-up tables
const redTable = new Uint32Array(32);
for (let i = 0; i < 32; i++) { redTable[i] = (i * 255) / 31; }

const greenTable = new Uint32Array(64);
for (let i = 0; i < 64; i++) { greenTable[i] = (i * 255) / 63; }

const blueTable = redTable;
const alphaMask = (255 << 24);

/**
 * Parses binary RGB565 data into a standardized canvas element
 */
export function parseGraphics(data, config) {
	return new Promise((resolve) => {
		const {
			headerSize = 0,
			xCount = 1,
			yCount = 1,
			rowWidth,
			rowHeight,
			transparent = false,
			paddingPerFrame = 0
		} = config;

		const canvas = document.createElement("canvas");
		const ctx = canvas.getContext("2d");

		// Stacking all grids linearly into a vertical spritesheet
		canvas.width = rowWidth;
		canvas.height = rowHeight * yCount * xCount;

		const imageData = ctx.createImageData(canvas.width, canvas.height);
		const buf32 = new Uint32Array(imageData.data.buffer);

		let dataIndex = 0;
		let pixelIndex = headerSize;

		for (let yRow = 0; yRow < yCount; yRow++) {
			for (let xRow = 0; xRow < xCount; xRow++) {
				for (let y = 0; y < rowHeight; y++) {
					for (let x = 0; x < rowWidth; x++) {
						const value = data[pixelIndex] | (data[pixelIndex + 1] << 8);

						const redIdx = (value >> 11) & 0x1F;
						const greenIdx = (value >> 5) & 0x3F;
						const blueIdx = value & 0x1F;

						const redValue = redTable[redIdx];
						const greenValue = greenTable[greenIdx];
						const blueValue = blueTable[blueIdx];

						const isTransparent = transparent && (redValue + greenValue + blueValue) === 0;

						// JS uses little-endian TypedArrays so format is ABGR locally
						buf32[dataIndex++] = isTransparent ? 0 :
							(alphaMask | (blueValue << 16) | (greenValue << 8) | redValue);

						pixelIndex += 2;
					}
				}
				pixelIndex += paddingPerFrame;
			}
		}

		ctx.putImageData(imageData, 0, 0);

		resolve({
			image: canvas,
			frameWidth: rowWidth,
			frameHeight: rowHeight,
		});
	});
}