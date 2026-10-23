class SNDFile extends Phaser.Loader.FileTypes.BinaryFile {
	constructor(loader, key, url, xhrSettings) {
		super(loader, key, url, xhrSettings);
		this.key = key;
		this.audioContext = new AudioContext();
	}

	decodeFileName(bufferView) {
		return new TextDecoder("windows-1250").decode(bufferView).split(/\u0000{1,}/)[0];
	}

	async unpackSND(data) {
		const decodedFiles = [];
		const dataView = new DataView(data.buffer);
		const fileCount = data[0];

		const fileNameLength = 8;
		const offsetInfoLength = 8;
		const fileInfoLength = fileNameLength + offsetInfoLength;

		for (let i = 0; i < fileCount; i++) {
			const fileInfoStart = 2 + (i * fileInfoLength);

			const nameData = data.subarray(fileInfoStart, fileInfoStart + fileNameLength);
			const fileName = this.decodeFileName(nameData);

			const offsetInfoStart = fileInfoStart + fileNameLength;
			const offset = dataView.getUint32(offsetInfoStart, true);
			const length = dataView.getUint32(offsetInfoStart + 4, true);

			const pcmData = new Int8Array(data.buffer, offset, length);

			const audioBuffer = this.audioContext.createBuffer(1, length, 22050);
			const channelData = audioBuffer.getChannelData(0);

			for (let j = 0; j < length; j++) {
				// Convert signed 8-bit (-128 to 127) to AudioBuffer float format (-1.0 to 1.0)
				channelData[j] = pcmData[j] / 128.0;
			}

			decodedFiles.push({ name: fileName, audioBuffer });
		}
		return decodedFiles;
	}

	async onProcess() {
		const unpackedFiles = await this.unpackSND(new Uint8Array(this.xhrLoader.response));
		for (let i = 0; i < unpackedFiles.length; i++) {
			const fileEntry = unpackedFiles[i];
			// Add the generated audioBuffer directly to Phaser's cache
			this.loader.cacheManager.audio.add(`${this.key}-${fileEntry.name}`, fileEntry.audioBuffer);
		}
		this.onProcessComplete();
	}
}

export default class SNDPlugin extends Phaser.Plugins.BasePlugin {

	constructor (pluginManager) {
		super(pluginManager);
		pluginManager.registerFileType('snd', this.fileCallback);
	}

	fileCallback (key, url, xhrSettings) {
		this.addFile(new SNDFile(this, key, url, xhrSettings));
		return this;
	}

}
