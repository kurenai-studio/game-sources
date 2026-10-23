export const createSlider = (scene, customConfig) => {
	const config = {
		xStart: 0,
		xEnd: 100,
		y: 0,
		texture: "POSUV1.FSF",
		steps: 15,
		value: 0,
		changeCallback: (value)=>{console.log("Slider value:", value);},
	}
	Object.assign(config, customConfig);

	const slider = scene.add.image(config.xStart, config.y, config.texture).setOrigin(0, 0);
	slider.setInteractive();

	const stepSize = (config.xEnd - config.xStart) / config.steps;

	slider.setValue = (value) => {
		const clampedValue = Phaser.Math.Clamp(Math.round(value), 0, config.steps);
		const newX = config.xStart + clampedValue * stepSize;
		if (slider.x === newX) return;
		slider.x = newX;
		config.changeCallback(clampedValue);
	};
	slider.setValue(config.value || 0);

	scene.input.on("pointermove", (pointer) => {
		if (!pointer.isDown || !slider.dragging) return;
		const localX = pointer.x - config.xStart;
		const newValue = Phaser.Math.Clamp(Math.round(localX / stepSize), 0, config.steps);
		slider.setValue(newValue);
	});

	slider.on("pointerdown", (pointer) => {
		slider.dragging = true;
		const localX = pointer.x - config.xStart;
		const newValue = Phaser.Math.Clamp(Math.round(localX / stepSize), 0, config.steps);
		slider.setValue(newValue);
	});

	scene.input.on("pointerup", () => {
		slider.dragging = false;
	});


	return slider;
}