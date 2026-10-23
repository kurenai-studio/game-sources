import { playSound } from "../../modules/audio";
import { createCursor } from "../../modules/cursor";
import { createMenuButton } from "../../modules/menu";

const debugging = process.env.DEBUG == "true";

export default class CreditsMenu extends Phaser.Scene {
	constructor () {
		super({
			key: "creditsMenu",
		});
	}

	preload() {
		
	}

	create() {
		const scene = this;
		scene.events.off();
		const bg = scene.add.image(0,0,"CREDITS.FGF").setOrigin(0,0);
		const cursor = createCursor(scene);


		const okButton = createMenuButton(scene,{
			x: 511,
			y: 392,
			texture: "OK5.FSF",
			clickCallback: () => {
				scene.scene.start("mainMenu");
			}
		});

		const remakeCredits = scene.add.image(272,406,"remakeCredits").setOrigin(0,0).setDepth(10);
	}
		
}