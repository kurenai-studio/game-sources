import { playSound } from "../../modules/audio";
import { createCursor } from "../../modules/cursor";
import { createMenuButton } from "../../modules/menu";

const debugging = process.env.DEBUG == "true";

export default class SinglePlayerMenu extends Phaser.Scene {
	constructor () {
		super({
			key: "singlePlayerMenu",
		});
	}

	preload() {
		
	}

	create() {
		const scene = this;
		scene.events.off();
		const bg = scene.add.image(0,0,"SINGLE.FGF").setOrigin(0,0);
		const cursor = createCursor(scene);


		const backButton = createMenuButton(scene,{
			x: 60,
			y: 405,
			texture: "BACK.FSF",
			hoverTextureFrame: 1,
			clickCallback: () => {
				scene.scene.start("mainMenu");
			}
		});

		const selectRaceType = (type) => {
			scene.registry.set("currentRaceType",type);
			scene.scene.start("raceMenu");
		}
		const championshipButton = createMenuButton(scene,{
			x: 53,
			y: 146,
			texture: "CHAMPION.FSF",
			clickCallback: () => {
				selectRaceType("championship");
			}
		});
		const freeRaceButton = createMenuButton(scene,{
			x: 53,
			y: 228,
			texture: "FREE.FSF",
			clickCallback: () => {
				selectRaceType("freeRace");
			}
		});
		const ghostRaceButton = createMenuButton(scene,{
			x: 56,
			y: 310,
			texture: "GHOST.FSF",
			clickCallback: () => {
				selectRaceType("ghostRace");
			}
		});



	}
		
}