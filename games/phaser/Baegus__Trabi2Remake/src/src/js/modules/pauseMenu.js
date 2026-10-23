export const createPauseMenu = (scene) => {
	const menuContainer = scene.add.container(210, 188).setVisible(false);
	const bg = scene.add.image(8, 7, "VNITREK.FSF").setOrigin(0, 0).setAlpha(0.5);
	menuContainer.add(bg);
	const frame = scene.add.image(0, 0, "RAMECEK.FSF").setOrigin(0, 0);
	menuContainer.add(frame);

	const toggleMenu = () => {
		if (menuContainer.visible) {
			menuContainer.setVisible(false);
			scene.scene.resume("race");
		} else {
			activate(0);
			menuContainer.setVisible(true);
			scene.scene.pause("race");
		}
	};

	let activeItem = 0;
	const menuItems = [];

	const resumeButton = scene.add.image(55, 17, "ICO1.FSF").setOrigin(0, 0);
	menuContainer.add(resumeButton);
	resumeButton.action = () => {
		toggleMenu();
	};

	menuItems.push(resumeButton);

	const exitToMenuButton = scene.add.image(42, 40, "ICO2.FSF").setOrigin(0, 0);
	exitToMenuButton.setFrame(1);
	menuContainer.add(exitToMenuButton);
	exitToMenuButton.action = () => {
		const raceScene = scene.scene.get("race");
		raceScene.scene.start("raceMenu");
		toggleMenu();
		scene.events.emit("hideHUD");
	};

	menuItems.push(exitToMenuButton);

	const cdVolumeOption = scene.add.image(22, 69, "ICO3.FSF").setOrigin(0, 0);
	cdVolumeOption.setFrame(1);
	menuContainer.add(cdVolumeOption);
	menuItems.push(cdVolumeOption);

	
	const activate = (menuItemIndex) => {
		if (menuItemIndex === activeItem) return;
		menuItems[activeItem].setFrame(1);
		activeItem = menuItemIndex;
		menuItems[activeItem].setFrame(0);
	}

	const select = (offset) => {
		let newIndex = Phaser.Math.Clamp(activeItem + offset, 0, menuItems.length - 1);
		activate(newIndex);
	}

	scene.input.keyboard.on("keydown-ESC", () => {
		toggleMenu();
	});

	scene.input.keyboard.on("keydown-ENTER", () => {
		if (!menuContainer.visible) return;
		menuItems[activeItem].action();
	});

	scene.input.keyboard.on("keydown-DOWN", () => {
		if (!menuContainer.visible) return;
		select(1);
	});
	scene.input.keyboard.on("keydown-UP", () => {
		if (!menuContainer.visible) return;
		select(-1);
	});

	return menuContainer;
}