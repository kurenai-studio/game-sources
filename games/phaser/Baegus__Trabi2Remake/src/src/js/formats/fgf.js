import { parseGraphics } from "./graphics";

class FGFFile extends Phaser.Loader.FileTypes.BinaryFile {
	constructor(loader, key, url, xhrSettings) {
		super(loader, key, url, xhrSettings);
		this.key = key;
		this.isFGF = url.toLowerCase().endsWith(".fgf");
	}

	processGraphics(data, isFGF = false) {
		const dataView = new DataView(data.buffer, data.byteOffset, data.byteLength);

		const headerSize = isFGF ? 0 : 5;
		const xCount = isFGF ? 1 : 1 + data[2];
		const yCount = isFGF ? 1 : data[0];
		const rowWidth = isFGF ? 640 : dataView.getUint16(1, true);
		const rowHeight = isFGF ? 480 : dataView.getUint16(3, true);

		return parseGraphics(data, {
			headerSize,
			xCount,
			yCount,
			rowWidth,
			rowHeight,
			transparent: !isFGF,
			paddingPerFrame: 4
		});
	}

	async onProcess() {
		const decoded = await this.processGraphics(new Uint8Array(this.xhrLoader.response), this.isFGF);
		this.data = decoded.image;

		if (this.isFGF) {
			await this.loader.textureManager.addImage(this.key, this.data);
		} else {
			await this.loader.textureManager.addSpriteSheet(this.key, decoded.image, {
				frameWidth: decoded.frameWidth,
				frameHeight: decoded.frameHeight
			});
		}

		this.onProcessComplete();
	}
}

export default class FGFPlugin extends Phaser.Plugins.BasePlugin {
	constructor(pluginManager) {
		super(pluginManager);
		pluginManager.registerFileType("fgf", this.fileCallback);
		pluginManager.registerFileType("fsf", this.fileCallback);
	}

	fileCallback(key, url, xhrSettings) {
		this.addFile(new FGFFile(this, key, url, xhrSettings));
		return this;
	}
}