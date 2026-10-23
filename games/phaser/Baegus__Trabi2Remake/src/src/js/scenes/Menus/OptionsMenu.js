import { playSound, setMusicVolume } from "../../modules/audio";
import { createCursor } from "../../modules/cursor";
import { createMenuButton } from "../../modules/menu";
import { createSlider } from "../../modules/sliders";

const debugging = process.env.DEBUG == "true";

export default class OptionsMenu extends Phaser.Scene {
	constructor() {
		super({
			key: "optionsMenu",
		});
	}

	preload() {

	}

	create() {
		const scene = this;
		scene.events.off();
		const bg = scene.add.image(0, 0, "OPTIONS.FGF").setOrigin(0, 0);
		const cursor = createCursor(scene);

		const soundSwitch = createMenuButton(scene, {
			x: 566,
			y: 61,
			texture: "SW4.FSF",
			hoverTextureFrame: false,
		});
		soundSwitch.setAlpha(1);
		let soundEnabled = scene.registry.get("soundEnabled");
		if (!soundEnabled) soundSwitch.setFrame(1);
		const soundTitle = createMenuButton(scene, {
			x: 417,
			y: 45,
			texture: "NOISE.FSF",
			clickCallback: () => {
				soundSwitch.setFrame(soundSwitch.frame.name === 0 ? 1 : 0);
				soundEnabled = !soundEnabled;
				scene.registry.set("soundEnabled", soundEnabled);
			}
		});

		const dynamicScreenSwitch = createMenuButton(scene, {
			x: 565,
			y: 295,
			texture: "SW5.FSF",
			hoverTextureFrame: false,
		});
		dynamicScreenSwitch.setAlpha(1);
		const dynamicScreenTitle = createMenuButton(scene, {
			x: 283,
			y: 285,
			texture: "DSCREEN.FSF",
			clickCallback: () => {
				dynamicScreenSwitch.setFrame(dynamicScreenSwitch.frame.name === 0 ? 1 : 0);
			}
		});
		
		const multiplayerCOM1Arrow = scene.add.image(138, 338, "SW6.FSF", 0).setOrigin(0, 0);
		const multiplayerCOM2Arrow = scene.add.image(139, 401, "SW7.FSF", 0).setOrigin(0, 0);
		let multiplayerCOMPort = scene.registry.get("multiplayerCOMPort");
		multiplayerCOM1Arrow.setAlpha(multiplayerCOMPort === 1 ? 1 : 0);
		multiplayerCOM2Arrow.setAlpha(multiplayerCOMPort === 2 ? 1 : 0);
		const multiplayerTitle = createMenuButton(scene, {
			x: 179,
			y: 364,
			texture: "MULTIPL.FSF",
			clickCallback: () => {
				multiplayerCOMPort = multiplayerCOMPort === 1 ? 2 : 1;
				multiplayerCOM1Arrow.setAlpha(multiplayerCOMPort === 1 ? 1 : 0);
				multiplayerCOM2Arrow.setAlpha(multiplayerCOMPort === 2 ? 1 : 0);
				scene.registry.set("multiplayerCOMPort", multiplayerCOMPort);
			}
		});

		const musicVolumeSlider = createSlider(scene, {
			xStart: 244,
			xEnd: 424,
			y: 150,
			texture: "POSUV3.FSF",
			steps: 15,
			value: scene.registry.get("musicVolume"),
			changeCallback: (value) => {
				setMusicVolume(scene, value);
			},
		});

		const CDVolumeSlider = createSlider(scene, {
			xStart: 244,
			xEnd: 424,
			y: 232,
			texture: "POSUV3.FSF",
			steps: 15,
			value: scene.registry.get("CDVolume"),
			changeCallback: (value) => {
				scene.registry.set("CDVolume", value);
			},
		});

		const okButton = createMenuButton(scene, {
			x: 473,
			y: 369,
			texture: "OK2.FSF",
			clickCallback: () => {
				scene.scene.start("mainMenu");
			}
		});

	}

}