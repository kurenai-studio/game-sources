

export const loadBitmapFonts = async (scene) => {
	const numbers = "0123456789";
	const systemFontConfig = {
		image: "systemFont",
		width: 8,
		height: 8,
		charsPerRow: 67,
		chars: `ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz${numbers} -_:.`,
	};
	// Create two HUD bitmap fonts (red and gray) from a single image that has
	// one character per row: red characters first, then gray ones.
	const charsRed = `${numbers}:.`;
	const charsGray = `${numbers}/`;
	const charW = 9;
	const charH = 16;
	const redCount = charsRed.length;
	const grayCount = charsGray.length;

	const srcTexture = scene.textures.get("FONT.FSF");
	const srcImage = srcTexture.getSourceImage();

	// Helper to create a texture from a slice of the source image
	const makeFontFromSlice = async (key, srcY, count, chars) => {
		const canvas = document.createElement("canvas");
		canvas.width = charW;
		canvas.height = charH * count;
		const ctx = canvas.getContext("2d");
		// sx, sy, sWidth, sHeight, dx, dy, dWidth, dHeight
		ctx.drawImage(srcImage, 0, srcY, charW, charH * count, 0, 0, charW, charH * count);

		// Special-case: for the red HUD font, shift ':' and '.' 1px to the left
		if (key === "HUDFontRed") {
			const shiftChars = [":", "."];
			// find indices within the provided chars string
			const indices = shiftChars
				.map(c => chars.indexOf(c))
				.filter(i => i >= 0);

			indices.forEach((index) => {
				const rowY = index * charH;
				// copy source row (except the last column) to a temp canvas
				const tmp = document.createElement("canvas");
				tmp.width = Math.max(0, charW - 1);
				tmp.height = charH;
				const tctx = tmp.getContext("2d");
				// copy left (charW - 1) pixels of the row
				if (tmp.width > 0) tctx.drawImage(canvas, 0, rowY, tmp.width, charH, 0, 0, tmp.width, charH);
				// clear original row
				ctx.clearRect(0, rowY, charW, charH);
				if (tmp.width > 0) ctx.drawImage(tmp, 0, 0, tmp.width, charH, -1, rowY, tmp.width, charH);
			});
		}

		// add the canvas as a texture key and parse as RetroFont
		const textureKey = `fontSlice_${key}`;
		scene.textures.addImage(textureKey, canvas);
		const cfg = {
			image: textureKey,
			width: charW,
			height: charH,
			charsPerRow: 1,
			chars: chars
		};
		scene.cache.bitmapFont.add(key, Phaser.GameObjects.RetroFont.Parse(scene, cfg));
	};

	scene.cache.bitmapFont.add("systemFont", Phaser.GameObjects.RetroFont.Parse(scene, systemFontConfig));
	makeFontFromSlice("HUDFontRed", 0, redCount, charsRed);
	makeFontFromSlice("HUDFontGray", charH * redCount, grayCount, charsGray);
}