import { textToWholePixels } from "../modules/utils";
import { playSound } from "../modules/audio";
import { createCursor } from "../modules/cursor";
import { parse3DM } from "../modules/3dm";
import { parseIL } from "../modules/il";
import { parseSP1SP2 } from "../modules/sp1sp2";
import { parseLAP } from "../modules/lap";
import { createCar } from "../modules/car";
import { STATIC, b2Body_ApplyLinearImpulse, b2Body_GetLinearVelocity, b2Body_GetMass, b2Body_GetTransform, b2Body_GetWorldCenterOfMass, b2Body_SetTransform, b2Vec2, pxm } from "phaser-box2d/dist/PhaserBox2D.js";
import { assignB2BodyBox, assignB2BodyCircle, createB2World, updateB2worldStepAndCollisions } from "../modules/box2dUtils.js";


const debugging = process.env.DEBUG == "true";

export default class Race extends Phaser.Scene {
	constructor () {
		super({
			key: "race",
			maxLights: 30,
		});
	}

	preload() {
		const scene = this;
		const mapOrder = scene.registry.get("mapOrder");
		const currentMap = mapOrder[scene.registry.get("currentMap")];
		const currentMapFile = currentMap>9 ? `Trat${[currentMap]}.map` : `Trat0${currentMap}.map`;
		const currentMapFileUpper = currentMapFile.toUpperCase();
		console.log("Current map file:", currentMapFile);
		// Parse and make the main tilemap:
		const binaryMapData = scene.cache.binary.get(currentMapFile);
		const mapData = Array.from(binaryMapData.slice(2));
		const mapWidth  = binaryMapData[0]; // in tiles
		const mapHeight = binaryMapData[1]; // in tiles
		const tilemapData = [];
		while (mapData.length > 0) {
			tilemapData.push(mapData.splice(0, mapWidth));
		}

		scene.tileSize = 100;
		scene.tilemap = scene.make.tilemap({ data: tilemapData, tileWidth: scene.tileSize, tileHeight: scene.tileSize });

		// Get 3D model placements:
		const modelPlacementFile = currentMapFileUpper.replace(".MAP", ".3DM");
		const modelPlacementData = parse3DM(scene.cache.binary.get(modelPlacementFile));
		scene.modelPlacements = modelPlacementData;

		// Get AI node positions if they exist:
		const il1File = scene.cache.binary.get(currentMapFile.replace(".map",".il1"));
		const il2File = scene.cache.binary.get(currentMapFile.replace(".map",".il2"));
		if (il1File) scene.aiNodes1 = parseIL(il1File);
		if (il2File) scene.aiNodes2 = parseIL(il2File);

		// Parse SP1+SP2 additional sprite data
		const sp1Parsed = parseSP1SP2(scene, currentMapFile.replace(".map", ".sp1"));
		const sp2Parsed = parseSP1SP2(scene, currentMapFile.replace(".map", ".sp2"));

		// Save parsed entries for placing exact images later in create()
		scene.additionalSprites1Entries = sp1Parsed.entries || [];
		scene.additionalSprites2Entries = sp2Parsed.entries || [];

		// Parse track point data (LAP)
		const lapFile = scene.cache.binary.get(currentMapFile.replace(".map", ".lap"));
		if (lapFile) {
			scene.points = parseLAP(lapFile);
		}

	}

	create() {
		const scene = this;
		scene.events.off();

		createB2World(scene); // create Box2D world

		const toPx = (tileUnits) => tileUnits * scene.tileSize;

		const mapTextures = "POZ.FSF"; // TODO set according to map
		const mapTextures3D = "TEXTURY.PKG"; // TODO set according to map
		const mapTexturesSP1 = "ONIKY.FSF"; // TODO set according to map
		const mapTexturesSP2 = "DIVACI.FSF";
		const tiles = scene.tilemap.addTilesetImage(mapTextures);
		const layer = scene.tilemap.createLayer(0, tiles, 0, 0);

		for (const e of scene.additionalSprites1Entries) {
			const image = scene.add.image(e.x, e.y, mapTexturesSP1, e.frame).setOrigin(0, 0).setDepth(2);
		}

		for (const e of scene.additionalSprites2Entries) {
			const image = scene.add.image(e.x, e.y, mapTexturesSP2, e.frame).setOrigin(0, 0).setDepth(2);
		}

		for (const pointData in scene.points) {
			const point = scene.points[pointData];
			if (debugging) {
				const color = [0xff00ff, 0x00ff00, 0xffff00][["start", "checkpoint", "repairDepo"].indexOf(pointData)];
				const pointRect = scene.add.rectangle(point.x, point.y, 100, point.h, color, 0.5).setOrigin(0, 0);
			}
		}

		scene.cars = [];
		scene.playerCar = createCar(scene, scene.points.start.x, scene.points.start.y, 0, true);
		scene.cars.push(scene.playerCar);

		// scene.add.rectangle(toPx(21), toPx(28), scene.tileSize, scene.tileSize, 0xff0000).setOrigin(0, 0);

		for (const model of scene.modelPlacements) {
			const modelObject = scene.add.model3D(model.x, model.y, model.name, mapTextures3D);
			assignB2BodyBox(modelObject, {type: STATIC});
		}

		const cursor = createCursor(scene);

		if (!scene.scene.isActive("hud")) {
			if (scene.scene.isPaused("hud")) {
				const hudScene = scene.scene.get("hud");
				hudScene.events.emit("showHUD");
			} else {
				scene.scene.launch("hud");
			}
		}
		

		scene.currentLapTime = 0;
		scene.bestLapTime = Infinity;
		scene.totalRaceTime = 0;
		scene.timerRunning = false;
		scene.time.delayedCall(500, () => {
			scene.events.emit("raceStarted");
			scene.timerRunning = true;
		});

		async function loadDebug() {
			if (process.env.DEBUG !== "true") return;
			const DEBUG = await import("../modules/debug.js");
			DEBUG.initToggleBox2dDebug(scene, true); // set true to show debug graphics by default, toggle with B
			scene.debugFPSText = scene.add.text(8, 18, "0 FPS", {
				color: "white",
				fontFamily: "Arial",
				fontSize: 13,
			}).setOrigin(0, 1).setDepth(99999).setAlpha(0);
			scene.input.keyboard.on("keydown-F", (e) => {
				scene.debugFPSText.setAlpha(scene.debugFPSText.alpha === 1 ? 0 : 1);
			});
			
			DEBUG.showAINodes(scene);
			DEBUG.showOffroadOverlay(scene);
			// DEBUG.mouseFreeCam(scene);
			DEBUG.showTileInfo(scene);
			DEBUG.switchMapsWithM(scene);
		}
		loadDebug();
	}

	update(time, delta) {
		const scene = this;
		updateB2worldStepAndCollisions(scene, delta); // update Box2D world and check for collisions
		if (scene.timerRunning) {
			scene.currentLapTime += delta;
			scene.totalRaceTime += delta;
		}
	}
}