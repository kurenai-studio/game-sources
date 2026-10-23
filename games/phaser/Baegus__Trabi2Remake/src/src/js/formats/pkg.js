import { parseGraphics } from "./graphics";

class PKGFile extends Phaser.Loader.FileTypes.BinaryFile {
	constructor(loader, key, url, xhrSettings) {
		super(loader, key, url, xhrSettings);
		this.key = key;
	}

	decodeFileName(arrayBuffer) {
		return new TextDecoder("windows-1250").decode(arrayBuffer);
	}

	processGraphics(data) {
		const dataView = new DataView(data.buffer, data.byteOffset, data.byteLength);
		const imgWidth = dataView.getUint16(0, true);
		const imgHeight = dataView.getUint16(2, true);

		return parseGraphics(data, {
			headerSize: 4,
			rowWidth: imgWidth,
			rowHeight: imgHeight,
			paddingPerFrame: 0,
			transparent: false
		});
	}

	async unPKG(data) {
		const decodedFiles = [];
		const fileCount = data[0];
		const fileNameLength = 12;

		let curByte = 2; // fileCountHeaderLength

		for (let i = 0; i < fileCount; i++) {
			const nameData = data.subarray(curByte, curByte + fileNameLength);
			const fileName = this.decodeFileName(nameData);
			curByte += fileNameLength;

			const imageWidth = data[curByte];
			curByte += 2;
			const imageHeight = data[curByte];
			curByte += 3;

			const fileLength = (imageWidth * imageHeight) * 2;
			// Subarray guarantees lightweight view over the original buffer
			const fileData = data.subarray(curByte - 5, curByte + fileLength);
			curByte += fileLength;

			decodedFiles.push({ name: fileName, data: fileData });
		}
		return decodedFiles;
	}

	async onProcess() {
		const unpackedFiles = await this.unPKG(new Uint8Array(this.xhrLoader.response));

		for (let i = 0; i < unpackedFiles.length; i++) {
			const fileEntry = unpackedFiles[i];
			const decoded = await this.processGraphics(fileEntry.data);

			this.data = decoded.image;
			await this.loader.textureManager.addImage(`${this.key}-${i}`, this.data);
		}

		this.onProcessComplete();
	}

}

export default class PKGPlugin extends Phaser.Plugins.BasePlugin {
	constructor(pluginManager) {
		super(pluginManager);
		pluginManager.registerFileType('pkg', this.fileCallback);
	}

	fileCallback(key, url, xhrSettings) {
		this.addFile(new PKGFile(this, key, url, xhrSettings));
		return this;
	}

}