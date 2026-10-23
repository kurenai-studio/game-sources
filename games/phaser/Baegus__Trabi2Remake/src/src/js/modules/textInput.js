export const createTextInput = (scene, customConfig) => {
	const config = {
		x: 0,
		y: 0,
		zoneWidth: 120,
		text: "",
		allowedChars: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789- ",
		maxLength: 16,
		changeCallback: (value) => { console.log("Text input value:", value); },
	}
	Object.assign(config, customConfig);

	const textInput = scene.add.bitmapText(config.x, config.y, "systemFont", config.text).setOrigin(0, 0);
	const inputZone = scene.add.zone(textInput.x, textInput.y, config.zoneWidth, 17).setOrigin(0, 0);

	let inputActive = false;
	let inputWasActive = false;
	scene.input.on("pointerdown", (pointer) => {
		if (!inputZone.getBounds().contains(pointer.x, pointer.y)) {
			if (inputWasActive) {
				inputActive = false;
				textInput.setText(config.text);
				config.changeCallback(config.text);
			}
			inputWasActive = false;
			return;
		}
		config.text = "";
		textInput.setText("_");
		inputActive = true;
		inputWasActive = true;
	});
	scene.input.keyboard.on("keydown", (event) => {
		if (!inputActive) return;
		if (event.key === "Backspace") {
			config.text = config.text.slice(0, -1);
		} else if (config.allowedChars.includes(event.key) && config.text.length < config.maxLength) {
			config.text += event.key;
		}
		textInput.setText(config.text + "_");
	});

	return textInput;
}
