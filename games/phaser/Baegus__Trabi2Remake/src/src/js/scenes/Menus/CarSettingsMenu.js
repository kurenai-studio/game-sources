import { playSound } from "../../modules/audio";
import { createCursor } from "../../modules/cursor";
import { createMenuButton } from "../../modules/menu";
import { createSlider } from "../../modules/sliders";
import { getTransmissionStats, getParKeyForDifficulty } from "../../modules/carParams";

const debugging = process.env.DEBUG == "true";

export default class CarSettingsMenu extends Phaser.Scene {
	constructor () {
		super({
			key: "carSettingsMenu",
		});
	}

	preload() {
		
	}

	create() {
		const scene = this;
		scene.events.off();
		const bg = scene.add.image(0,0,"CAROPT.FGF").setOrigin(0,0);
		const cursor = createCursor(scene);

		let tires = scene.registry.get("tiresVal");
		let transmission = scene.registry.get("transmissionVal");
		let brakes = scene.registry.get("brakesVal");
		const difficulty = scene.registry.get("difficulty");
		const parData = scene.cache.binary.get(getParKeyForDifficulty(difficulty));

		const maxSpeedText = scene.add.bitmapText(132, 216, "systemFont").setOrigin(0, 0);
		const zeroTo60Text = scene.add.bitmapText(132, 245, "systemFont").setOrigin(0, 0);
		const zeroTo120Text = scene.add.bitmapText(133, 275, "systemFont").setOrigin(0, 0);

		function updateTransmissionStats() {
			const stats = getTransmissionStats(parData, difficulty, transmission);
			maxSpeedText.setText(stats.maxSpeed);
			zeroTo60Text.setText(stats.zeroTo60);
			zeroTo120Text.setText(stats.zeroTo120);
		}
		updateTransmissionStats();


		const transmissionSlider = createSlider(scene, {
			xStart: 67,
			xEnd: 277,
			y: 118,
			texture: "POSUV1.FSF",
			steps: 21,
			value: scene.registry.get("transmissionVal"),
			changeCallback: (value) => {
				transmission = value;
				scene.registry.set("transmissionVal", transmission);
				updateTransmissionStats();
			},
		});

		const brakesSlider = createSlider(scene, {
			xStart: 380,
			xEnd: 590,
			y: 118,
			texture: "POSUV2.FSF",
			steps: 21,
			value: scene.registry.get("brakesVal"),
			changeCallback: (value) => {
				brakes = value;
				scene.registry.set("brakesVal", brakes);
			},
		});


		// TIRES SELECTOR:

		const tireThumbnails = scene.add.image(366,355,"PNEU.FSF").setOrigin(0,0);
		const totalTires = scene.registry.get("totalTires");
		const lastTires = totalTires-1;
		const setTires = (offset=1,forceValue=false) => {
			let selectedTires = tires+offset;
			if (forceValue) selectedTires = offset
			if (selectedTires > lastTires) return;
			if (selectedTires < 0) return;
			tires = selectedTires;
			scene.registry.set("tiresVal",tires);
			tireThumbnails.setFrame(selectedTires);
		};
		setTires(tires,true);

		const prevTiresButton = createMenuButton(scene,{
			x: 332,
			y: 362,
			texture: "SIPKA5.FSF",
			clickCallback: () => {
				setTires(-1);
			}
		});
		const nextTiresButton = createMenuButton(scene,{
			x: 420,
			y: 364,
			texture: "SIPKA6.FSF",
			clickCallback: () => {
				setTires(1);
			}
		});



		const okButton = createMenuButton(scene,{
			x: 468,
			y: 363,
			texture: "OK.FSF",
			clickCallback: () => {
				scene.scene.start("raceMenu");
			}
		});



	}
		
}