import { makeClickable } from "./utils";

const createMenuButton = (scene,customConfig) => {
	const config = {
		x: customConfig.x || 0,
		y: customConfig.y || 0,
		texture: customConfig.texture || "",
		hoverTextureFrame: customConfig.hoverTextureFrame!==undefined?customConfig.hoverTextureFrame:false,
		tooltipObject: customConfig.tooltipObject || false,
		alphaToggle: customConfig.alphaToggle!==undefined?customConfig.alphaToggle:true,
		tooltipFrame: customConfig.tooltipFrame!==undefined?customConfig.tooltipFrame:false,
		clickCallback:  customConfig.clickCallback!==undefined?customConfig.clickCallback:(() => {}),
	}
	const item = scene.add.image(config.x,config.y,config.texture).setOrigin(0,0);
	const hasTooltip = config.tooltipObject!==false && config.tooltipFrame!==false;
	const hasHover = config.hoverTextureFrame!==false;
	item.name = `menuButton-${config.texture}`;
	item.setDepth(2).setAlpha(0.001);
	makeClickable(item);
	if (config.alphaToggle == false) item.setAlpha(1);
	item.on("pointerover",() => {
		item.setAlpha(1);
		if (hasTooltip) {
			config.tooltipObject.setFrame(config.tooltipFrame);
			config.tooltipObject.setAlpha(1);
		}
		if (hasHover) {
			item.setFrame(config.hoverTextureFrame);
		}
	});
	item.on("pointerout",() => {
		if (config.alphaToggle) item.setAlpha(0.001);
		if (hasTooltip) {
			config.tooltipObject.setAlpha(0);
		}
		if (hasHover) {
			item.setFrame(0);
		}
	});
	item.on("click",() => {
		config.clickCallback();
	});
	return item;
}

export {createMenuButton}