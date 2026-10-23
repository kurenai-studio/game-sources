import { createDamageIndicator } from "../modules/damageIndicator.js";
import { createSpeedometer } from "../modules/speedometer.js";
import { createPauseMenu } from "../modules/pauseMenu.js";
import { createTimers } from "../modules/timers.js";

const debugging = process.env.DEBUG == "true";

export default class HUD extends Phaser.Scene {
	constructor() {
		super({
			key: "hud",
		});
	}

	create() {
		const scene = this;
		scene.events.off();
		const damageIndicator = createDamageIndicator(scene, 560, 347);
		const speedometer = createSpeedometer(scene, 0, 341);

		const timers = createTimers(scene, 10, 10);

		const trainingText = scene.add.bitmapText(200, 460, "systemFont", "Trenink muzete kdykoliv ukoncit klavesou ESC.").setOrigin(0, 0).setDepth(100);

		const pauseMenu = createPauseMenu(scene);

		scene.events.on("hideHUD", () => {
			scene.scene.setVisible(false);
			scene.scene.pause();
		});

		scene.events.on("showHUD", () => {
			scene.scene.resume();
			scene.scene.setVisible(true);
		});
	}
}