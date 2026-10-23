import { playSound } from "../../modules/audio";
import { createCursor } from "../../modules/cursor";
import { createMenuButton } from "../../modules/menu";
import { createTextInput } from "../../modules/textInput";

const debugging = process.env.DEBUG == "true";

export default class RaceMenu extends Phaser.Scene {
	constructor () {
		super({
			key: "raceMenu",
		});
	}

	preload() {
		
	}

	create() {
		const scene = this;
		scene.events.off();

		const currentRaceType = scene.registry.get("currentRaceType");
		const bg = scene.add.image(0,0,"NEW.FGF").setOrigin(0,0);
		const cursor = createCursor(scene);

		const defaultPlayerName = "Novy hrac";
		const defaultTeam = 0;
		const defaultMap = 0;

		// TODO: If game is loaded/in progress, load actual values from registry here:
		let playerName = scene.registry.get("playerName") || defaultPlayerName;
		let team = defaultTeam;
		let map = defaultMap;



		// LEFT COLUMN:

		const teamThumbnails = scene.add.image(148,46,"TYMY.FSF").setOrigin(0,0);
		const totalTeams = scene.registry.get("totalTeams");
		const lastTeam = totalTeams-1;
		const teamsLocked = false; // TODO: set according to current cirmustances
		const setTeam = (offset=1,forceValue=false) => {
			if (teamsLocked && !forceValue) return;
			let selectedTeam = team+offset;
			if (forceValue) selectedTeam = offset
			if (selectedTeam > lastTeam) return;
			if (selectedTeam < 0) return;
			team = selectedTeam;
			const frame = teamsLocked ? selectedTeam+totalTeams : selectedTeam;
			teamThumbnails.setFrame(frame);
		};
		setTeam(team,true);
		const prevTeamButton = createMenuButton(scene,{
			x: 111,
			y: 83,
			texture: "SIPKA1.FSF",
			clickCallback: () => {
				setTeam(-1);
			}
		});
		const nextTeamButton = createMenuButton(scene,{
			x: 321,
			y: 84,
			texture: "SIPKA2.FSF",
			clickCallback: () => {
				setTeam(1);
			}
		});

		const carSettingsButton = createMenuButton(scene,{
			x: 63,
			y: 184,
			texture: "NASVOZ.FSF",
			clickCallback: () => {
				scene.scene.start("carSettingsMenu");
			}
		});

		const playerNameInput = createTextInput(scene,{
			x: 163,
			y: 244,
			text: playerName,
			zoneWidth: 120,
			changeCallback: (value) => {
				playerName = value;
				scene.registry.set("playerName", playerName);
			}
		});


		const easyDiffButton = createMenuButton(scene,{
			x: 118,
			y: 304,
			texture: "SW1.FSF",
			alphaToggle: false,
			clickCallback: () => {
				setDiff(0);
			}
		});
		const mediumDiffButton = createMenuButton(scene,{
			x: 191,
			y: 303,
			texture: "SW2.FSF",
			alphaToggle: false,
			clickCallback: () => {
				setDiff(1);
			}
		});
		const hardDiffButton = createMenuButton(scene,{
			x: 262,
			y: 303,
			texture: "SW3.FSF",
			alphaToggle: false,
			clickCallback: () => {
				setDiff(2);
			}
		});

		const diffButtons = [easyDiffButton, mediumDiffButton, hardDiffButton];
		const setDiff = (val) => {
			scene.registry.set("difficulty", val);
			diffButtons.forEach((btn, i) => {
				btn.setFrame(i === val ? 1 : 0);
				console.log("Difficulty set to", val);
				console.log("frame should be", i === val ? 1 : 0);

			});
		};
		setDiff(scene.registry.get("difficulty") || 0);

		// RIGHT COLUMN:

		const mapThumbnails = scene.add.image(404,91,"TRATE.FSF").setOrigin(0,0);
		const totalMaps = scene.registry.get("totalMaps");
		const lastMap = totalMaps-1;
		const mapsLocked = false; // TODO: set according to current cirmustances
		const setMap = (offset=1,forceValue=false) => {
			if (mapsLocked && !forceValue) return;
			let selectedMap = map+offset;
			if (forceValue) selectedMap = offset
			if (selectedMap > lastMap) return;
			if (selectedMap < 0) return;
			map = selectedMap;
			scene.registry.set("currentMap",map);
			const frame = mapsLocked ? selectedMap+totalMaps : selectedMap;
			mapThumbnails.setFrame(frame);
		};
		setMap(map,true);

		const prevMapButton = createMenuButton(scene,{
			x: 371,
			y: 123,
			texture: "SIPKA3.FSF",
			clickCallback: () => {
				setMap(-1);
			}
		});
		const nextMapButton = createMenuButton(scene,{
			x: 571,
			y: 126,
			texture: "SIPKA4.FSF",
			clickCallback: () => {
				setMap(1);
			}
		});

		const lessLapsButton = createMenuButton(scene,{
			x: 532,
			y: 221,
			texture: "HVEZDA1.FSF",
			clickCallback: () => {
			}
		});
		const lapsText = scene.add.bitmapText(553, 227, "systemFont", "10").setOrigin(0,0);
		const moreLapsButton = createMenuButton(scene,{
			x: 570,
			y: 221,
			texture: "HVEZDA2.FSF",
			clickCallback: () => {
			}
		});
		
		const lessOpponentsButton = createMenuButton(scene,{
			x: 532,
			y: 250,
			texture: "HVEZDA3.FSF",
			clickCallback: () => {
			}
		});
		const opponentsText = scene.add.bitmapText(556, 255, "systemFont", "0").setOrigin(0, 0);
		const moreOpponentsButton = createMenuButton(scene,{
			x: 570,
			y: 250,
			texture: "HVEZDA4.FSF",
			clickCallback: () => {
			}
		});
		// TODO: Display and set text values
		

		const saveButton = createMenuButton(scene,{
			x: 407,
			y: 299,
			texture: "SAVE.FSF",
			clickCallback: () => {
				scene.scene.start("saveMenu");
			}
		});


		// BOTTOM ROW:

		const backButton = createMenuButton(scene,{
			x: 53,
			y: 369,
			texture: "BACK2.FSF",
			clickCallback: () => {
				scene.scene.start("singlePlayerMenu");
			}
		});

		const standingsButton = createMenuButton(scene,{
			x: 202,
			y: 396,
			texture: "KLASIF.FSF",
			clickCallback: () => {
			}
		});

		const startRaceButton = createMenuButton(scene,{
			x: 469,
			y: 367,
			texture: "GAME.FSF",
			clickCallback: () => {
				scene.scene.start("race");
			}
		});


	}
		
}