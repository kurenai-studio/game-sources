class SYNFile extends Phaser.Loader.FileTypes.BinaryFile {
	constructor(loader, key, url, xhrSettings) {
		super(loader, key, url, xhrSettings);
		this.key = key;
		this.isSYN = url.toLowerCase().endsWith(".syn");
	}

	processGraphics(data) {
		// data: Uint8Array
		return new Promise((resolve) => {
			// SYN files in this project appear to contain multiple 100x100 monochrome
			// tiles packed as 1 bit per pixel (100x100 = 10000 bits = 1250 bytes).
			// Some files contain a repeating header sequence: 0x64 0x00 0x64 0x00
			// We'll scan for that header and extract blocks of 1250 bytes. If none
			// found, fall back to splitting the file into 1250-byte chunks.

			const TILE_W = 100;
			const TILE_H = 100;
			const BYTES_PER_TILE = Math.ceil((TILE_W * TILE_H) / 8); // 1250

			const tiles = [];
			const header = [0x64, 0x00, 0x64, 0x00];
			let i = 0;
			let foundHeader = false;
			while (i <= data.length - 4) {
				if (data[i] === header[0] && data[i+1] === header[1] && data[i+2] === header[2] && data[i+3] === header[3]) {
					// try to slice next BYTES_PER_TILE bytes
					if (i + 4 + BYTES_PER_TILE <= data.length) {
						tiles.push(data.slice(i + 4, i + 4 + BYTES_PER_TILE));
						foundHeader = true;
						i += 4 + BYTES_PER_TILE;
						continue;
					} else {
						break;
					}
				}
				i++;
			}

			if (!foundHeader) {
				// fallback: split into consecutive tiles if the file length is a multiple
				// (or nearly multiple) of BYTES_PER_TILE
				if (data.length >= BYTES_PER_TILE) {
					const possibleCount = Math.floor(data.length / BYTES_PER_TILE);
					for (let t = 0; t < possibleCount; t++) {
						const start = t * BYTES_PER_TILE;
						tiles.push(data.slice(start, start + BYTES_PER_TILE));
					}
				}
			}

			// Build a canvas sprite sheet from tiles
			const tileCount = tiles.length;
			const cols = Math.max(1, Math.min(16, Math.ceil(Math.sqrt(tileCount))));
			const rows = Math.ceil(tileCount / cols);
			const canvas = document.createElement('canvas');
			canvas.width = cols * TILE_W;
			canvas.height = rows * TILE_H;
			const ctx = canvas.getContext('2d');
			const imgData = ctx.createImageData(canvas.width, canvas.height);

			// convert each tile's bitstream into pixels (neon-orange for 1, dark for 0)
			for (let t = 0; t < tileCount; t++) {
				const block = tiles[t];
				const offsetX = (t % cols) * TILE_W;
				const offsetY = Math.floor(t / cols) * TILE_H;
				for (let y = 0; y < TILE_H; y++) {
					for (let x = 0; x < TILE_W; x++) {
						const bitIndex = y * TILE_W + x;
						const byteIdx = Math.floor(bitIndex / 8)	;
						const bitOffset = bitIndex % 8;
						const byte = block[byteIdx];
						// MSB-first as typical in these assets
						const bit = (byte >> (7 - bitOffset)) & 1;
						const globalX = offsetX + x;
						const globalY = offsetY + y;
						const pxIdx = (globalY * canvas.width + globalX) * 4;
						if (bit) {
							imgData.data[pxIdx + 0] = 255; // R
							imgData.data[pxIdx + 1] = 170; // G
							imgData.data[pxIdx + 2] = 0;   // B
							imgData.data[pxIdx + 3] = 255; // A
						} else {
							imgData.data[pxIdx + 0] = 20;
							imgData.data[pxIdx + 1] = 20;
							imgData.data[pxIdx + 2] = 20;
							imgData.data[pxIdx + 3] = 255;
						}
					}
				}
			}

			ctx.putImageData(imgData, 0, 0);

			// Store parsed tiles for debug drawing into a global registry so other
			// code (or the console) can toggle overlays. Keep the raw bit blocks too.
			if (!window.SYNParsed) window.SYNParsed = {};
			window.SYNParsed[this.key] = {
				image: canvas,
				frameWidth: TILE_W,
				frameHeight: TILE_H,
				cols: cols,
				rows: rows,
				tileCount: tileCount,
				rawTiles: tiles
			};

			resolve({
				image: canvas,
				frameWidth: TILE_W,
				frameHeight: TILE_H
			});
		});
	}

	async onProcess() {
		const decoded = await this.processGraphics(new Uint8Array(this.xhrLoader.response));
		this.data = decoded.image;

		await this.loader.textureManager.addSpriteSheet(this.key, decoded.image, {
			frameWidth: decoded.frameWidth,
			frameHeight: decoded.frameHeight
		});

		this.onProcessComplete();
	}
}

export default class SYNPlugin extends Phaser.Plugins.BasePlugin {
	constructor(pluginManager) {
		super(pluginManager);
		pluginManager.registerFileType('syn', this.fileCallback);
	}

	fileCallback(key, url, xhrSettings) {
		this.addFile(new SYNFile(this, key, url, xhrSettings));
		return this;
	}
}

// mapSequence defines which tiles map to SYN indices.
const mapSequence = [
	{ type: 0, count: 7  },
	{ type: 1, count: 11 },
	{ type: 0, count: 1 },
	{ type: 1, count: 1 },
	{ type: 0, count: 1 },
	{ type: 1, count: 2 },
	{ type: 0, count: 1 },
	{ type: 1, count: 5 },
	{ type: 0, count: 1 },
	{ type: 1, count: 1 },
	{ type: 0, count: 1 },
	{ type: 1, count: 3 },
	{ type: 0, count: 1 },
	{ type: 1, count: 1 },
	{ type: 0, count: 1 },
	{ type: 1, count: 2 },
	{ type: 0, count: 1 },
	{ type: 1, count: 2 },
	{ type: 0, count: 2 },
	{ type: 1, count: 3 },
	{ type: 0, count: 1 },
	{ type: 1, count: 1 },
	{ type: 0, count: 1 },
	{ type: 1, count: 3 },
	{ type: 0, count: 1 },
	{ type: 1, count: 2 },
	{ type: 0, count: 2 },
	{ type: 1, count: 2 },
	{ type: 0, count: 1 },
	{ type: 1, count: 1 },
	{ type: 0, count: 37 },
	{ type: 1, count: 2 },
	{ type: 0, count: 2 },
	{ type: 1, count: 2 },
	{ type: 0, count: 2 },
	{ type: 1, count: 2 },
	{ type: 0, count: 2 },
	{ type: 1, count: 2 },
	{ type: 0, count: 14 }
];

const tileIndexToSynIndex = {};
let seqTileIndex = 0;
let seqSynIndex = 0;

for (const seq of mapSequence) {
	for (let i = 0; i < seq.count; i++) {
		if (seq.type === 1) {
			tileIndexToSynIndex[seqTileIndex] = seqSynIndex;
			seqSynIndex++;
		}
		seqTileIndex++;
	}
}
// expose the mapping for optional debug tooling (debug module will consume this)
if (typeof window !== 'undefined') window.SYNTileIndexToSynIndex = tileIndexToSynIndex;

window.SYNQuery = {
	isOffroad: function(key, tilemap, x, y, options = {}) {
		const record = window.SYNParsed && window.SYNParsed[key];
		if (!record) return false;
		
		const opts = Object.assign({ invert: true }, options);
		
		const TILE_W = record.frameWidth;
		const TILE_H = record.frameHeight;
		
		const tx = Math.floor(x / tilemap.tileWidth);
		const ty = Math.floor(y / tilemap.tileHeight);
		const tile = tilemap.getTileAt(tx, ty);
		
		if (!tile) return true; // Treat outer bounds as offroad
		const tileId = tile.index;

		if ([0, 2, 31, 44, 54, 57].includes(tileId) || (tileId >= 87 && tileId <= 98) || tileId >= 115) {
			return true;
		}
		
		const baseSynIndex = tileIndexToSynIndex[tileId];
		if (baseSynIndex === undefined) return false;
		
		const synIndex = (baseSynIndex + record.tileCount) % record.tileCount;
		if (synIndex < 0 || synIndex >= record.tileCount) return false;
		
		const block = record.rawTiles[synIndex];
		
		const localX = Math.floor(x) % tilemap.tileWidth;
		const localY = Math.floor(y) % tilemap.tileHeight;
		
		const synX = Math.floor((localX / tilemap.tileWidth) * TILE_W);
		const synY = Math.floor((localY / tilemap.tileHeight) * TILE_H);
		
		if (synX < 0 || synX >= TILE_W || synY < 0 || synY >= TILE_H) return false;
		
		const bitIndex = (synY * TILE_W + synX);
		const byteIdx = Math.floor(bitIndex / 8);
		const bitOffset = bitIndex % 8;
		const byte = block[byteIdx];
		let bit = ((byte >> (7 - bitOffset)) & 1);
		
		if (opts.invert) bit = bit ? 0 : 1;
		
		return bit === 1;
	}
};