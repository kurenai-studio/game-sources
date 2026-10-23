const debugging = process.env.DEBUG == "true";

export const createSpeedometer = (scene, x, y) => {
	const speedometer = scene.add.image(x, y, "TACHO.FSF", 0).setOrigin(0, 0).setDepth(60);
	if (debugging) {
		window.speedDebugText = scene.add.bitmapText(10, y + 60, "systemFont", "0 km/h").setDepth(100);
	}

	const angleOffset = -128;
	const needle = scene.add.rectangle(x + 122, y + 74.5, 1, 51, 0x485048).setOrigin(0.5, 0.68).setDepth(101).setRotation(Phaser.Math.DegToRad(angleOffset));
	const maxSpeedKPH = 146; // in km/h
	const angleRange = 320;

	const lapText = scene.add.bitmapText(x + 22, y + 27, "HUDFontGray", "1/5").setDepth(100);
	const positionText = scene.add.bitmapText(x + 33, y + 109, "HUDFontGray", "1").setDepth(100);

	scene.events.on("playerCarUpdate", (event) => {
		const speedKPH = event.speedKPH;
		if (debugging) {
			window.speedDebugText.setText(`${speedKPH} km/h`);
		}

		const rawAngle = (speedKPH / maxSpeedKPH) * angleRange + angleOffset;
		const needleAngle = Phaser.Math.Clamp(rawAngle, angleOffset, angleOffset + angleRange);
		needle.setRotation(Phaser.Math.DegToRad(needleAngle));
	});

	return speedometer;
}