const setTimeText = (textObj, ms) => {
	const minutes = Math.floor(ms / 60000);
	const seconds = Math.floor(ms / 1000) % 60;
	const hundredths = Math.floor((ms % 1000) / 10);
	const formatted = `${minutes.toString().padStart(2, "0")}:${seconds.toString().padStart(2, "0")}.${hundredths.toString().padStart(2, "0")}`;
	textObj.setText(formatted);
}

const flash = (scene, textObj, ms, flashes = 5, halfDuration = 500) => {
	if (textObj._flashTimer) {
		textObj._flashTimer.remove(false);
		textObj._flashTimer = null;
	}

	// Show the final lap time for the entire flash duration and freeze updates
	setTimeText(textObj, ms);
	textObj.setVisible(true);
	textObj.alpha = 1;
	textObj._isFrozen = true;

	const ticks = flashes * 2;
	let count = 0;

	textObj._flashTimer = scene.time.addEvent({
		delay: halfDuration,
		repeat: ticks - 1,
		callback: () => {
			textObj.alpha = textObj.alpha === 0 ? 1 : 0;
			count++;

			if (count < ticks) return;
			textObj.alpha = 1;
			textObj._isFrozen = false;
			textObj._flashTimer = null;
		}
	});
}

export const createTimers = (scene, x, y) => {
	const lapTimeText = scene.add.bitmapText(x, y, "HUDFontRed", "00:00.00").setOrigin(0, 0).setDepth(100).setLetterSpacing(1);
	const bestLapText = scene.add.bitmapText(x, y + 20, "HUDFontRed", "00:00.00").setOrigin(0, 0).setDepth(100).setLetterSpacing(1);
	setTimeText(lapTimeText, 0);
	setTimeText(bestLapText, 0);
	let bestLapTime = Infinity;

	scene.events.on("lapCompleted", (event) => {
		const lapTime = event.lapTime;
		flash(scene, lapTimeText, lapTime);

		if (lapTime < bestLapTime) {
			bestLapTime = lapTime;
			setTimeText(bestLapText, bestLapTime);
		}
	});

	const raceScene = scene.scene.get("race");
	raceScene.events.on("raceStarted", () => {
		raceScene.time.addEvent({
			delay: 10,
			loop: true,
			callback: () => {
				if (lapTimeText._isFrozen) return;
				setTimeText(lapTimeText, raceScene.currentLapTime);
			}
		});
	});

	/*
	// Example lapCompleted trigger:
	scene.time.delayedCall(100, () => {
		scene.events.emit("lapCompleted", { lapTime: 57180 });
	});
	*/
}
