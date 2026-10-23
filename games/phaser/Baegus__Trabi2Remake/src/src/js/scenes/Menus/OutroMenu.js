import { playSound, setMusicVolume } from "../../modules/audio";
import { createCursor } from "../../modules/cursor";

const debugging = process.env.DEBUG == "true";

export default class OutroMenu extends Phaser.Scene {
	constructor() {
		super({
			key: "outroMenu",
		});
	}

	preload() {

	}

	create() {
		const scene = this;
		scene.events.off();
		const bg = scene.add.image(0, 0, "OUTRO.FGF").setOrigin(0, 0);
		const cursor = createCursor(scene);

		setMusicVolume(scene, 0);
	}

}