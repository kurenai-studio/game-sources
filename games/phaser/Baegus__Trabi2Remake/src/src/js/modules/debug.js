import { b2World_Draw, GetWorldScale, b2AABB, b2Vec2 } from "phaser-box2d/dist/PhaserBox2D.js";

export class PhaserDebugDraw
{
	constructor (graphics, width, height, scale)
	{
		this.scale = scale;
		this.width = width;
		this.height = height;

		this.drawingBounds = new b2AABB();
		this.positionOffset = new b2Vec2();
		this.p0 = new b2Vec2();

		this.useDrawingBounds = false;

		this.drawShapes = true;
		this.drawJoints = false;
		this.drawAABBs = false;
		this.drawMass = false;
		this.drawContacts = false;
		this.drawGraphColors = false;
		this.drawContactNormals = false;
		this.drawContactImpulses = false;
		this.drawFrictionImpulses = false;

		this.context = graphics;

		this.SetPosition(width, 0);
	}

	b2TransformPointOut (t, p, out)
	{
		out.x = (t.q.c * p.x - t.q.s * p.y) + t.p.x;
		out.y = (t.q.s * p.x + t.q.c * p.y) + t.p.y;
	}

	DrawPolygon (xf, vs, ps, col, graphics)
	{
		const p0 = this.p0;
		const scale = this.scale;

		const cX = (this.width >> 1) + this.positionOffset.x;
		const cY = (this.height >> 1) + this.positionOffset.y;

		const points = [];

		for (let i = 0; i < ps; i++)
		{
			this.b2TransformPointOut(xf, vs[i], p0);

			p0.y = -p0.y;

			const x = scale * p0.x + cX;
			const y = scale * p0.y + cY;

			points.push({ x, y });
		}

		graphics.lineStyle(1, col, 1);
		graphics.strokePoints(points, false, true);
	}

	DrawSolidPolygon (xf, vs, ps, rad, col, graphics)
	{
		const p0 = this.p0;
		const scale = this.scale;

		const cX = (this.width >> 1) + this.positionOffset.x;
		const cY = (this.height >> 1) + this.positionOffset.y;

		const points = [];

		for (let i = 0; i < ps; i++)
		{
			this.b2TransformPointOut(xf, vs[i], p0);

			p0.y = -p0.y;

			const x = scale * p0.x + cX;
			const y = scale * p0.y + cY;

			points.push({ x, y });
		}

		graphics.lineStyle(1, col, 1); // Use the radius for line width
		graphics.fillStyle(col, 0.5);

		graphics.fillPoints(points, false, true);
		graphics.strokePoints(points, false, true);
	}

	DrawCircle (center, rad, col, graphics)
	{
		const scale = this.scale;

		const cX = (this.width >> 1) + this.positionOffset.x;
		const cY = (this.height >> 1) + this.positionOffset.y;

		const transformedCenterX = scale * cX + cX;
		const transformedCenterY = -(scale * cY + cY);

		graphics.lineStyle(1, col, 1);
		graphics.strokeCircle(transformedCenterX, transformedCenterY, rad * scale, 0, 2 * Math.PI);
	}

	DrawSolidCircle (xf, rad, col, graphics)
	{
		const scale = this.scale;

		const cX = (this.width >> 1) + this.positionOffset.x;
		const cY = (this.height >> 1) + this.positionOffset.y;

		const transformedCenterX = scale * xf.p.x + cX;
		const transformedCenterY = -(scale * xf.p.y) + cY;

		const scaledRadius = rad * scale;

		graphics.fillStyle(col, 0.5);
		graphics.fillCircle(transformedCenterX, transformedCenterY, scaledRadius, 0, 2 * Math.PI);

		graphics.lineStyle(1, col, 1);
		graphics.strokeCircle(transformedCenterX, transformedCenterY, scaledRadius, 0, 2 * Math.PI);
	}

	DrawSolidCapsule (p1, p2, radius, col, graphics)
	{
		const scale = this.scale;

		const cX = (this.width >> 1) + this.positionOffset.x;
		const cY = (this.height >> 1) + this.positionOffset.y;

		const transformedP1X = (scale * p1.x) + cX;
		const transformedP1Y = (scale * -p1.y) + cY;
		const transformedP2X = (scale * p2.x) + cX;
		const transformedP2Y = (scale * -p2.y) + cY;

		const dx = transformedP2X - transformedP1X;
		const dy = transformedP2Y - transformedP1Y;
		const length = Math.sqrt(dx * dx + dy * dy);
		const angle = Math.atan2(dy, dx);

		graphics.save();
		graphics.translateCanvas(transformedP1X, transformedP1Y);
		graphics.rotateCanvas(angle);

		graphics.fillStyle(col, 0.5);
		graphics.lineStyle(1, col, 1);

		graphics.beginPath();

		graphics.arc(0, 0, radius * scale, Math.PI / 2, -Math.PI / 2);
		graphics.lineTo(length, -radius * scale);
		graphics.arc(length, 0, radius * scale, -Math.PI / 2, Math.PI / 2);
		graphics.lineTo(0, radius * scale);

		graphics.closePath();

		graphics.fill();
		graphics.stroke();

		graphics.restore();
	}

	DrawSegment (p1, p2, col, graphics)
	{
		const scale = this.scale;

		const cX = (this.width >> 1) + this.positionOffset.x;
		const cY = (this.height >> 1) + this.positionOffset.y;

		const v1X = (scale * p1.x) + cX;
		const v1Y = (scale * -p1.y) + cY;
		const v2X = (scale * p2.x) + cX;
		const v2Y = (scale * -p2.y) + cY;

		graphics.lineStyle(1, col, 1);
		graphics.lineBetween(v1X, v1Y, v2X, v2Y);
	}

	DrawPoint (x, y, radius, col, graphics)
	{
		this.DrawSolidCircle({ p: { x, y } }, radius, col, graphics);
	}

	SetPosition (x, y)
	{
		// use half width and height to make the virtual 'camera' look at (x, y)
		this.positionOffset.x = this.width / 2 - x;
		this.positionOffset.y = y - this.height / 2;
	}

	DrawImagePolygon (xf, shape, ctx)
	{
		//  NOOP
	}

	DrawImageCircle (xf, rad, shape, ctx)
	{
		//  NOOP
	}

	DrawImageCapsule (p1, p2, radius, shape, ctx)
	{
		//  NOOP
	}
}

export const initToggleBox2dDebug = (scene, debugVisible = false) => {
	const debugGraphics = scene.add.graphics().setVisible(false).setDepth(99999999);
	scene.debugGraphics = debugGraphics;
	scene.worldDraw = new PhaserDebugDraw(debugGraphics, scene.game.scale.width, scene.game.scale.height, GetWorldScale());

	if (debugVisible) {
		scene.debugGraphics.visible = true;
	}

	scene.input.keyboard.on("keydown-B",(e) => {
		scene.debugGraphics.visible = !scene.debugGraphics.visible;
	});

	scene.events.on("prerender", () => {
		updateBox2dDebug(scene);
	});
}

export const updateBox2dDebug = (scene) => {
	if (scene.debugGraphics.visible) {
		scene.debugGraphics.clear();
		b2World_Draw(scene.world.worldId, scene.worldDraw);
	}
}

export const showTileInfo = (scene) => {
	const cam = scene.cameras.main;

	let lastTileX = null;
	let lastTileY = null;
	scene.input.on("pointermove", function (p) {
		const tileX = scene.tilemap.worldToTileX(p.x + cam.scrollX);
		const tileY = scene.tilemap.worldToTileY(p.y + cam.scrollY);
		if (tileX === lastTileX && tileY === lastTileY) return;
		console.log(`tileX: ${tileX}\ntileY: ${tileY}\ntileIndex: ${scene.tilemap.getTileAt(tileX, tileY)?.index}`);
		lastTileX = tileX;
		lastTileY = tileY;
	});
}

/*
 * Mouse free cam - hold left mouse button and drag to pan, hold shift and scroll to zoom
*/
export const mouseFreeCam = (scene) => {
	const cam = scene.cameras.main;

	cam.scrollX = 2036;
	cam.scrollY = 2913;
	
	scene.input.on("pointermove", function (p) {
		if (!p.isDown) return;
		cam.stopFollow();
		cam.scrollX -= (p.x - p.prevPosition.x) / cam.zoom;
		cam.scrollY -= (p.y - p.prevPosition.y) / cam.zoom;
	});

	scene.input.on("wheel", function (e) {
		if (!e.event.shiftKey) return;
		const amount = (e.deltaY < 0 ? -0.1 : 0.1);
		cam.setZoom(cam.zoom - amount);
	});
}

/*
 * Switch maps with the M key - shows a simple HTML overlay with a list of maps to choose from
*/
export const switchMapsWithM = (scene) => {
	scene.input.keyboard.on("keydown-M", (e) => {
		if (scene._mapPickerOpen) return;
		scene._mapPickerOpen = true;

		const totalMaps = scene.registry.get("totalMaps") || 0;
		const mapOrder = scene.registry.get("mapOrder") || Array.from({length: totalMaps}, (_,i) => i+1);

		const overlay = document.createElement("div");
		Object.assign(overlay.style, {
			position: "fixed", left: 0, top: 0, width: "100%", height: "100%",
			background: "rgba(0,0,0,0.6)", zIndex: 9999999999,
			display: "flex", alignItems: "center", justifyContent: "center"
		});

		const panel = document.createElement("div");
		Object.assign(panel.style, {
			background: "#222", padding: "12px", borderRadius: "8px",
			minWidth: "260px", maxWidth: "90%", boxShadow: "0 6px 20px rgba(0,0,0,0.6)",
			color: "#fff"
		});

		const list = document.createElement("div");
		Object.assign(list.style, { maxHeight: "50vh", overflow: "auto", marginBottom: "12px" });

		const buttons = [];
		for (let i = 0; i < totalMaps; i++) {
			const displayNum = mapOrder[i] ?? (i + 1);
			const btn = document.createElement("button");
			btn.textContent = `${i + 1}. Track ${displayNum}`;
			Object.assign(btn.style, {
				display: "block",
				width: "100%",
				margin: "6px 0",
				padding: "8px 10px",
				fontSize: "14px",
				cursor: "pointer",
				borderRadius: "4px",
				border: "none",
				background: "#444",
				color: "#fff",
				textAlign: "left"
			});
			btn.dataset.index = String(i);

			btn.addEventListener("click", () => {
				scene.registry.set("currentMap", i);
				cleanupAndRestart();
			});

			list.appendChild(btn);
			buttons.push(btn);
		}

		panel.appendChild(list);

		const cancelBtn = document.createElement("button");
		cancelBtn.textContent = "Cancel";
		Object.assign(cancelBtn.style, {
			padding: "8px 12px",
			fontSize: "14px",
			cursor: "pointer",
			border: "none",
			borderRadius: "4px"
		});

		cancelBtn.addEventListener("click", () => {
			cleanupAndClose();
		});

		panel.appendChild(cancelBtn);
		overlay.appendChild(panel);
		document.body.appendChild(overlay);

		// allow ESC to close
		const onEsc = (ev) => {
			if (ev.key === "Escape") cleanupAndClose();
		};

		window.addEventListener("keydown", onEsc);

		function cleanupAndClose() {
			window.removeEventListener("keydown", onEsc);
			buttons.forEach((b) => b.remove());
			cancelBtn.remove();
			list.remove();
			panel.remove();
			overlay.remove();
			scene._mapPickerOpen = false;
		}

		function cleanupAndRestart() {
			cleanupAndClose();
			scene.scene.restart();
		}
	});
}

export const showAINodes = (scene) => {
	const aiNodesGraphics = scene.add.graphics().setAlpha(0.5);
	if (scene.aiNodes1) {
		aiNodesGraphics.lineStyle(2, 0x00ff00);
		aiNodesGraphics.fillStyle(0x00ff00);
		aiNodesGraphics.beginPath();
		scene.aiNodes1.forEach(node => {
			aiNodesGraphics.lineTo(node.x, node.y);
			aiNodesGraphics.fillRect(node.x - 3, node.y - 3, 6, 6);
		});
		aiNodesGraphics.closePath();
		aiNodesGraphics.strokePath();
	}
	if (scene.aiNodes2) {
		aiNodesGraphics.lineStyle(2, 0x0000ff);
		aiNodesGraphics.fillStyle(0x0000ff);
		aiNodesGraphics.beginPath();
		scene.aiNodes2.forEach(node => {
			aiNodesGraphics.lineTo(node.x, node.y);
			aiNodesGraphics.fillRect(node.x - 3, node.y - 3, 6, 6);
		});
		aiNodesGraphics.closePath();
		aiNodesGraphics.strokePath();
	}
}

export const showOffroadOverlay = (scene) => {
	const SYNDebug = {};

	SYNDebug.drawOverlay = function(key, scene, tilemap, options = {}) {
		const record = window.SYNParsed && window.SYNParsed[key];
		if (!record) {
			console.warn("SYN overlay: no parsed record for", key);
			return null;
		}
		const opts = Object.assign({ alpha: 0.85, invert: true }, options);

		const TILE_W = record.frameWidth;
		const TILE_H = record.frameHeight;

		const mapPixelWidth = tilemap.width * tilemap.tileWidth;
		const mapPixelHeight = tilemap.height * tilemap.tileHeight;

		const canvas = document.createElement("canvas");
		canvas.width = mapPixelWidth;
		canvas.height = mapPixelHeight;
		const ctx = canvas.getContext("2d");
		const imgData = ctx.createImageData(canvas.width, canvas.height);

		const tileIndexToSynIndex = window.SYNTileIndexToSynIndex || {};

		for (let ty = 0; ty < tilemap.height; ty++) {
			for (let tx = 0; tx < tilemap.width; tx++) {
				const tile = tilemap.getTileAt(tx, ty);
				if (!tile) continue;
				const tileId = tile.index;

				const destX = tx * tilemap.tileWidth;
				const destY = ty * tilemap.tileHeight;
				const alphaByte = Math.floor(255 * opts.alpha);

				if ([0, 2, 31, 44, 54, 57].includes(tileId) || (tileId >= 87 && tileId <= 98) || tileId >= 115) {
					for (let y = 0; y < TILE_H; y++) {
						for (let x = 0; x < TILE_W; x++) {
							const globalX = destX + x;
							const globalY = destY + y;
							if (globalX < 0 || globalX >= canvas.width || globalY < 0 || globalY >= canvas.height) continue;
							const pxIdx = (globalY * canvas.width + globalX) * 4;
							imgData.data[pxIdx + 0] = 255;
							imgData.data[pxIdx + 1] = 170;
							imgData.data[pxIdx + 2] = 0;
							imgData.data[pxIdx + 3] = alphaByte;
						}
					}
					continue;
				}

				const baseSynIndex = tileIndexToSynIndex[tileId];
				if (baseSynIndex === undefined) continue;

				const synIndex = (baseSynIndex + record.tileCount) % record.tileCount;
				if (synIndex < 0 || synIndex >= record.tileCount) continue;

				const block = record.rawTiles[synIndex];

				for (let y = 0; y < TILE_H; y++) {
					for (let x = 0; x < TILE_W; x++) {
						let bitIndex = (y * TILE_W + x);
						const byteIdx = Math.floor(bitIndex / 8);
						const bitOffset = bitIndex % 8;
						const byte = block[byteIdx];
						let bit = ((byte >> (7 - bitOffset)) & 1);

						if (opts.invert) bit = bit ? 0 : 1;
						if (!bit) continue;

						const globalX = destX + x;
						const globalY = destY + y;
						if (globalX < 0 || globalX >= canvas.width || globalY < 0 || globalY >= canvas.height) continue;
						const pxIdx = (globalY * canvas.width + globalX) * 4;
						imgData.data[pxIdx + 0] = 255;
						imgData.data[pxIdx + 1] = 170;
						imgData.data[pxIdx + 2] = 0;
						imgData.data[pxIdx + 3] = alphaByte;
					}
				}
			}
		}

		ctx.putImageData(imgData, 0, 0);

		const texKey = `__SYN_DBG__${key}`;
		const gm = scene.textures;
		if (gm.exists(texKey)) gm.remove(texKey);
		gm.addImage(texKey, canvas);

		const layerX = (tilemap.layers && tilemap.layers[0] && tilemap.layers[0].x) || 0;
		const layerY = (tilemap.layers && tilemap.layers[0] && tilemap.layers[0].y) || 0;

		const img = scene.add.image(layerX, layerY, texKey).setOrigin(0, 0).setDepth(9999);
		img.setScrollFactor(1);

		return img;
	};

	SYNDebug.createInteractiveOverlay = function(key, scene, tilemap, options = {}) {
		const record = window.SYNParsed && window.SYNParsed[key];
		if (!record) {
			console.warn("SYN overlay: no parsed record for", key);
			return null;
		}
		const state = {
			key,
			scene,
			tilemap,
			opts: Object.assign({ alpha: 0.85, invert: true }, options),
			img: null
		};

		function draw() {
			if (state.img && state.img.destroy) {
				state.img.destroy();
			}
			state.img = SYNDebug.drawOverlay(state.key, state.scene, state.tilemap, state.opts);
		}

		const cleanup = () => {
			try {
				if (state.img && state.img.destroy) state.img.destroy();
			} catch (e) {}
		};

		state.scene.events.on("shutdown", cleanup);
		state.scene.events.on("destroy", cleanup);

		draw();

		return {
			destroy: cleanup,
			state
		};
	};
	scene.offroadOverlay = SYNDebug.createInteractiveOverlay("POZ.SYN", scene, scene.tilemap);
}