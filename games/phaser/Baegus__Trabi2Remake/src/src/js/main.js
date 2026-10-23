import Phaser from "phaser";
import FGFPlugin from "./formats/fgf";
import PKGPlugin from "./formats/pkg";
import SNDPlugin from "./formats/snd";
import ThreeDPlugin from "./formats/3d";
import SYNPlugin from "./formats/syn";
import Preloader from "./scenes/Preloader";
import MainMenu from "./scenes/Menus/MainMenu"
import OptionsMenu from "./scenes/Menus/OptionsMenu"
import SaveMenu from "./scenes/Menus/SaveMenu"
import CreditsMenu from "./scenes/Menus/CreditsMenu"
import SinglePlayerMenu from "./scenes/Menus/SinglePlayerMenu"
import RaceMenu from "./scenes/Menus/RaceMenu"
import CarSettingsMenu from "./scenes/Menus/CarSettingsMenu"
import OutroMenu from "./scenes/Menus/OutroMenu"
import Race from "./scenes/Race"
import HUD from "./scenes/HUD"

const config = {
	type: Phaser.WEBGL,
	width:  640,
	height: 480,
	// width:  1280,
	// height: 960,
	parent: "trabi2-remake",
	backgroundColor: "#fff",
	roundPixels: true,
	pixelArt: true,
	scale: {
		max: {
			width:  640,
			height: 480,
			// width:  1280,
			// height: 960,
		},
		mode: Phaser.Scale.FIT,
	},
	plugins: {
		global: [
			{ key: "FGFPlugin", plugin: FGFPlugin, start: true },
			{ key: "PKGPlugin", plugin: PKGPlugin, start: true },
			{ key: "SNDPlugin", plugin: SNDPlugin, start: true },
			{ key: "ThreeDPlugin", plugin: ThreeDPlugin, start: true },
			{ key: "SYNPlugin", plugin: SYNPlugin, start: true },
		]
	},
	dom: {
		createContainer: true
	},
	scene: [
		Preloader,
		MainMenu,
		SinglePlayerMenu,
		RaceMenu,
		OptionsMenu,
		CarSettingsMenu,
		CreditsMenu,
		OutroMenu,
		SaveMenu,
		Race,
		HUD,
	],
};

const game = new Phaser.Game(config);
