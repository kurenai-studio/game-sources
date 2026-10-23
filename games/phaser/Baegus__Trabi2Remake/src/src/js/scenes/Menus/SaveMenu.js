import { playSound } from "../../modules/audio";
import { createCursor } from "../../modules/cursor";
import { createMenuButton } from "../../modules/menu";
import { createTextInput } from "../../modules/textInput";

const debugging = process.env.DEBUG == "true";

export default class SaveMenu extends Phaser.Scene {
	constructor() {
		super({
			key: "saveMenu",
		});
	}

	preload() {

	}

	create() {
		const scene = this;
		scene.events.off();

		const bg = scene.add.image(0, 0, "SAVE.FGF").setOrigin(0, 0);
		const cursor = createCursor(scene);

		for (let i = 0; i < 12; i++) {
			const y = Math.round(161 + i * 23.168);
			const positionNameInput = createTextInput(scene, {
				x: 226,
				y,
				text: "-volna-", // TODO - if exists, load actual name from registry/localStorage
				zoneWidth: 165,
				maxLength: 8,
				changeCallback: (value) => {
					// TODO: Save everything to registry/localStorage
					scene.scene.start("raceMenu");
				}
			});
			const saveTime = "12:00"; // TODO - if exists, load actual time from registry/localStorage
			scene.add.bitmapText(297, y, "systemFont", saveTime).setOrigin(0, 0);
			const saveDate = "01.01"; // TODO - if exists, load actual date from registry/localStorage
			scene.add.bitmapText(353, y, "systemFont", saveDate).setOrigin(0, 0);
		}

		const backButton = createMenuButton(scene, {
			x: 57,
			y: 369,
			texture: "BACK3.FSF",
			clickCallback: () => {
				scene.scene.start("raceMenu");
			}
		});
	}

}