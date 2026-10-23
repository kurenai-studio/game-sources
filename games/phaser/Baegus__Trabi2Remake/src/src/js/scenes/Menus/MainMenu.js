import { playSound, playMusicTrack, setMusicVolume } from "../../modules/audio";
import { createCursor } from "../../modules/cursor";
import { createMenuButton } from "../../modules/menu";

const debugging = process.env.DEBUG == "true";

export default class MainMenu extends Phaser.Scene {
	constructor () {
		super({
			key: "mainMenu",
		});
	}

	preload() {
		
	}

	create() {
		const scene = this;
		scene.events.off();
		const bg = scene.add.image(0,0,"MAIN.FGF").setOrigin(0,0);

		const cursor = createCursor(scene);

		const cursorTooltip = scene.add.image(cursor.x,cursor.y,"POPISKY.FSF",0);
		cursorTooltip.setAlpha(0).setDepth(cursor.depth);

		scene.input.on("pointermove",(p) => {
			cursorTooltip.x = p.x+53;
			cursorTooltip.y = p.y+12;
		});

		const singlePlayerButton = createMenuButton(scene,{
			x: 259,
			y: 154,
			texture: "SINGLE.FSF",
			tooltipObject: cursorTooltip,
			tooltipFrame: 0,
			clickCallback: () => {
				scene.scene.start("singlePlayerMenu");
			}
		});
		const multiPlayerButton = createMenuButton(scene,{
			x:371,
			y:149,
			texture: "MULTI.FSF",
			tooltipObject: cursorTooltip,
			tooltipFrame:1,
			clickCallback: () => {
				alert("Multiplayer mode is not implemented (yet?)");
			}
		});
		const optionsButton = createMenuButton(scene,{
			x:487,
			y:147,
			texture: "OPTIONS.FSF",
			tooltipObject: cursorTooltip,
			tooltipFrame:2,
			clickCallback: () => {
				scene.scene.start("optionsMenu");
			}
		});
		const creditsButton = createMenuButton(scene,{
			x:302,
			y:253,
			texture: "CREDITS.FSF",
			tooltipObject: cursorTooltip,
			tooltipFrame:3,
			clickCallback: () => {
				scene.scene.start("creditsMenu");
			}
		});
		const exitButton = createMenuButton(scene,{
			x:420,
			y:256,
			texture: "EXIT.FSF",
			tooltipObject: cursorTooltip,
			tooltipFrame:4,
			clickCallback: () => {
				scene.scene.start("outroMenu");
			}
		});

		if (scene.registry.get("menuMusicPlaying") !== true) {
			playMusicTrack(scene,2);
			scene.registry.set("menuMusicPlaying", true);
			setMusicVolume(scene, scene.registry.get("musicVolume"));
		}
	}
		
}