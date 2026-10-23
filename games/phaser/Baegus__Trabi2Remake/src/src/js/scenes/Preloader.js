const debugging = process.env.DEBUG == "true";

import { loadBitmapFonts } from "../modules/bitmapFonts";

export default class Preloader extends Phaser.Scene {
	constructor() {
		super({
			key: "preloader"
		});

	}

	preload() {
		const scene = this;
		scene.loadingStartTime = performance.now();

		// Load maps:
		const mapCount = 10;
		for (let i = 1; i <= mapCount; i++) {
			const filename = `Trat${i.toString().padStart(2, "0")}.map`;
			const filenameUpper = filename.toUpperCase();
			// 3DM files (model placements):
			const modelPlacementFilename = filenameUpper.replace(".MAP", ".3DM");
			scene.load.binary(filename, `trabi2data/${filename}`, Uint8Array);
			scene.load.binary(modelPlacementFilename, `trabi2data/${modelPlacementFilename}`, Uint8Array);
			// IL1/IL2 files (AI node definitions):
			const il1Filename = filename.replace(".map", ".il1");
			const il2Filename = filename.replace(".map", ".il2");
			scene.load.binary(il1Filename, `trabi2data/${il1Filename}`, Uint8Array);
			scene.load.binary(il2Filename, `trabi2data/${il2Filename}`, Uint8Array);
			// SP1/SP2 files (additional sprite positions, from ONIKY.FSF and DIVACI.FSF):
			const sp1Filename = filename.replace(".map", ".sp1");
			const sp2Filename = filename.replace(".map", ".sp2");
			scene.load.binary(sp1Filename, `trabi2data/${sp1Filename}`, Uint8Array);
			scene.load.binary(sp2Filename, `trabi2data/${sp2Filename}`, Uint8Array);
			 // LAP files (track point definitions):
			const lapFilename = filename.replace(".map", ".lap");
			scene.load.binary(lapFilename, `trabi2data/${lapFilename}`, Uint8Array);
		}

		// Load FGFs and FSFs:
		const originalGraphicsFiles = [
			// MOUSE CURSOR:
			"KURZOR.FSF",



			// MAIN MENU:
			"MAIN.FGF",    // background image
			"POPISKY.FSF", // mouse cursor text tooltips (titles)
			"SINGLE.FSF",  // singleplayer button
			"MULTI.FSF",   // multiplayer button
			"OPTIONS.FSF", // options button
			"CREDITS.FSF", // credits button
			"EXIT.FSF",    // exit button

			// SINGLEPLAYER RACE MODE MENU:
			"SINGLE.FGF",   // background image
			"CHAMPION.FSF", // championship button
			"FREE.FSF",     // free race button
			"GHOST.FSF",    // ghost race button
			"BACK.FSF",     // return back button

			// RACE MENU:
			"NEW.FGF",     // background image
			"SIPKA1.FSF",  // prev arrow button (team selector)
			"SIPKA2.FSF",  // next arrow button (team selector)
			"SIPKA3.FSF",  // prev arrow button (map selector)
			"SIPKA4.FSF",  // next arrow button (map selector)
			"NASVOZ.FSF",  // car settings button
			"SAVE.FSF",    // save button
			"KLASIF.FSF",  // current standings button
			"BACK2.FSF",   // return back button
			"GAME.FSF",    // start race button
			"HVEZDA1.FSF", // star icon - prev (laps selector)
			"HVEZDA2.FSF", // star icon - next (laps selector)
			"HVEZDA3.FSF", // star icon - prev (opponents selector)
			"HVEZDA4.FSF", // star icon - next (opponents selector)
			"SW1.FSF",     // switch - radio button (easy difficulty selector)
			"SW2.FSF",     // switch - radio button (medium difficulty selector)
			"SW3.FSF",     // switch - radio button (hard difficulty selector)
			"TRATE.FSF",   // map selector thumbnails
			"TYMY.FSF",    // team selector thumbnails

			// OPTIONS MENU:
			"OPTIONS.FGF", // background image
			"POSUV3.FSF",  // slider thumb (volume sliders)
			"NOISE.FSF",   // sound switch title
			"SW4.FSF",     // switch - sound on/off
			"DSCREEN.FSF", // dynamic screen switch title
			"SW5.FSF",     // switch - dynamic screen on/off
			"MULTIPL.FSF", // multiplayer COM port switch title
			"SW6.FSF",     // arrow pointing to COM1
			"SW7.FSF",     // arrow pointing to COM2
			"OK2.FSF",     // OK/back button


			// CAR SETTINGS MENU:
			"CAROPT.FGF",  // background image
			"SIPKA5.FSF",  // prev arrow button (tires selector)
			"SIPKA6.FSF",  // next arrow button (tires selector)
			"POSUV1.FSF",  // slider thumb (transmission slider)
			"POSUV2.FSF",  // slider thumb (brakes slider)
			"PNEU.FSF",    // tire selector thumbnails
			"OK.FSF",      // OK/back button


			// CREDITS MENU:
			"CREDITS.FGF",     // background image
			"OK5.FSF",         // OK/back button

			// SAVE MENU:
			"SAVE.FGF",     // background image
			"BACK3.FSF",    // back button

			// MAP TILES:
			"POZ.FSF", // default map tiles
			"POZ2.FSF", // winter map tiles

			// ADDITIONAL OVERLAY MAP TILES:
			"ONIKY.FSF",   // sprites with positions defined in SP1 files
			"ONIKY2.FSF",   // winter sprites with positions defined in SP1 files
			"DIVACI.FSF",  // spectator sprites with positions defined in SP2 files

			// CAR SPRITES:
			"TRABANT.FSF", // all Trabant sprites

			// HUD:
			"FONT.FSF",   // number font (red + gray)
			"TACHO.FSF", // speedometer
			"OBRYSY.FSF", // car damage indicators

			// IN-GAME PAUSE MENU:
			"VNITREK.FSF", // background image, semi-opaque
			"RAMECEK.FSF", // menu frame
			"ICO1.FSF",    // continue option
			"ICO2.FSF",    // exit to menu option
			"ICO3.FSF",    // CD volume bar


			// OUTRO:
			"OUTRO.FGF", // background image

		];
		originalGraphicsFiles.forEach((filename) => {
			scene.load.fsf(filename,`trabi2data/${filename}`);
		});

		// Load texture PKGs:
		const texturePackages = [
			"TEXTURY.PKG",  // default textures
			"TEXTURY2.PKG", // winter textures
		];
		texturePackages.forEach((filename) => {
			scene.load.pkg(filename,`trabi2data/${filename}`);
		});

		// Load 3D models:
		const modelFiles = [
			"BOARD1H.3D",
			"BOARD1V.3D",
			"BOARD2H.3D",
			"BOARD2V.3D",
			"BOARD3H.3D",
			"BOARD3V.3D",
			"DEPO8.3D",
			"MAN1H.3D",
			"MAN1V.3D",
			"MAN2H.3D",
			"MAN2V.3D",
			"SLOUPEK.3D",
			"VEZ.3D",
		];
		modelFiles.forEach((filename) => {
			scene.load.threeD(filename,`trabi2data/${filename}`);
		});

		// Load road curbs bitmask:
		const roadMaskFile = scene.load.syn("POZ.SYN", `trabi2data/POZ.SYN`);

		// Load PAR files (car parameters):
		for (let i = 1; i <= 5; i++) {
			const filename = `PAR${i}.PAR`;
			scene.load.binary(filename, `trabi2data/${filename}`, Uint8Array);
		}

		// Load sounds and music from SNDs:
		const soundFiles = [
			"INTRO.SND",  // intro sounds
			"MENU.SND", // menu sounds
			"HUDBA.SND",  // music tracks
			"TRABANT.SND", // engine sounds
		];
		soundFiles.forEach((filename) => {
			scene.load.snd(filename,`trabi2data/${filename}`);
		});


		// Cheeky addition to the credits menu page:
		scene.load.image("remakeCredits","img/remakeCredits.png");

		// System font for player names and messages:
		scene.load.image("systemFont", "img/systemFont.png");
		
	}

	async create() {
		const scene = this;
		const endTime = performance.now();
		console.log(`All files loaded in ${(endTime - scene.loadingStartTime).toFixed(2)} ms`);
		scene.registry.set("currentMap",3); // DEBUG
		scene.registry.set("totalTeams",6);
		scene.registry.set("totalMaps",10);
		 // For whatever reason, tracks are out of order:
		scene.registry.set("mapOrder",[7,8,1,5,6,9,4,3,10,2]);

		scene.registry.set("soundEnabled", true);
		scene.registry.set("dynamicScreenEnabled", true);
		scene.registry.set("musicVolume", 3);
		scene.registry.set("CDVolume", 0);
		
		scene.registry.set("multiplayerCOMPort", 1);

		scene.registry.set("difficulty", 1); // 0 = easy, 1 = medium, 2 = hard
		scene.registry.set("transmissionVal", 0);
		scene.registry.set("brakesVal", 0);
		scene.registry.set("totalTires", 3);
		scene.registry.set("tiresVal", 0);

		loadBitmapFonts(scene);

		// scene.scene.start("mainMenu"); // DEBUG MAIN MENU
		// scene.scene.start("singlePlayer"); // DEBUG SINGLEPLAYER MENU
		// scene.scene.start("optionsMenu"); // DEBUG OPTIONS MENU
		scene.scene.start("saveMenu"); // DEBUG SAVE MENU
		// scene.scene.start("carSettingsMenu"); // DEBUG CAR SETTINGS MENU
		// scene.scene.start("raceMenu"); // DEBUG RACE MENU
		// scene.scene.start("race"); // DEBUG RACE
	}
}