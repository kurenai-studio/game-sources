export const createDamageIndicator = (scene, x, y) => {
	const FRAME_W = 80;
	const FRAME_H = 132;
	const LEFT_W = 41; // left quarter width (includes small overlap)
	const RIGHT_W = 40; // right quarter width
	const TOP_H = 67; // top quarter height
	const BOTTOM_H = 66; // bottom quarter height

	const damageIndicatorContainer = scene.add.container(x, y).setDepth(100);

	// Use small RenderTextures for each quarter and blit the appropriate
	// frame into them. This avoids issues with cropping frames in atlases.
	const makeQuarterRT = (x, y, cropX, cropY, cropW, cropH, initialFrame) => {
		const rt = scene.add.renderTexture(x, y, cropW, cropH).setOrigin(0, 0).setDepth(100);
		// drawFrame at negative offsets so the desired crop rectangle appears at 0,0
		rt.drawFrame("OBRYSY.FSF", initialFrame, -cropX, -cropY);
		damageIndicatorContainer.add(rt);
		return rt;
	};

	// top-left (frame 0)
	damageIndicatorContainer.topLeft = makeQuarterRT(0, 0, 0, 0, LEFT_W, TOP_H, 0);
	// top-right (frame 1) positioned to the right of the left piece, with overlap
	damageIndicatorContainer.topRight = makeQuarterRT(LEFT_W - 1, 0, LEFT_W - 1, 0, RIGHT_W, TOP_H, 1);
	// bottom-left (frame 2)
	damageIndicatorContainer.bottomLeft = makeQuarterRT(0, TOP_H - 1, 0, TOP_H - 1, LEFT_W, BOTTOM_H, 2);
	// bottom-right (frame 3)
	damageIndicatorContainer.bottomRight = makeQuarterRT(LEFT_W - 1, TOP_H - 1, LEFT_W - 1, TOP_H - 1, RIGHT_W, BOTTOM_H, 3);

	// damage state stored as frame indices (0..3)
	damageIndicatorContainer.damage = [0, 0, 0, 0]; // topLeft, topRight, bottomLeft, bottomRight
	damageIndicatorContainer.updateDamage = function () {
		// For each quarter RT, clear and redraw the selected frame so the
		// small render texture contains the right part of that frame.
		const quarters = [
			{ rt: this.topLeft, cropX: 0, cropY: 0 },
			{ rt: this.topRight, cropX: LEFT_W - 1, cropY: 0 },
			{ rt: this.bottomLeft, cropX: 0, cropY: TOP_H - 1 },
			{ rt: this.bottomRight, cropX: LEFT_W - 1, cropY: TOP_H - 1 },
		];
		for (let i = 0; i < 4; i++) {
			const q = quarters[i];
			q.rt.clear();
			q.rt.drawFrame("OBRYSY.FSF", this.damage[i], -q.cropX, -q.cropY);
		}
	};
	damageIndicatorContainer.updateDamage();

	scene.events.on("carDamage", (event) => {
		const damageState = event.damageState;
		// damageState expected to be an array of four numbers (percent 0..100) or direct frame indices (0..3)
		if (!damageState || !Array.isArray(damageState)) return;
		for (let i = 0; i < 4; i++) {
			const v = damageState[i] ?? 0;
			let frameIdx = 0;
			if (v >= 0 && v <= 3) {
				// already a frame index
				frameIdx = v;
			} else {
				// map percentage 0..100 to frames 0..3
				frameIdx = Math.min(3, Math.max(0, Math.floor((v / 100) * 3)));
			}
			damageIndicatorContainer.damage[i] = frameIdx;
		}
		damageIndicatorContainer.updateDamage();
	});

	return damageIndicatorContainer;
}