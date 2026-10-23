const createEl = (type,attributes = {}) => { 
	const el = document.createElement(type);
	for (let attr in attributes) {
		el.setAttribute(attr,attributes[attr]);
	}
	return el;
}
const addCl = (el,cls) => {
	if (Array.isArray(cls)) {
		for(let i = cls.length-1; i>=0; i--) {
			el.classList.add(cls[i]);
		}
	} else {
		el.classList.add(cls);
	}
}
const remCl = (el,cls) => {
	if (Array.isArray(cls)) {
		for(let i = cls.length-1; i>=0; i--) {
			el.classList.remove(cls[i]);
		}
	} else {
		el.classList.remove(cls);
	}
}

const smallestAngleDiff = (currentAngle,targetAngle) => {
	let diff = targetAngle-currentAngle;
	if (diff < -Math.PI) {
		diff += Math.PI * 2;
	} else if (diff > Math.PI) {
		diff -= Math.PI * 2;
	}
	return diff;
}

const textToWholePixels = (textObject) => {
	const textOriginXRounded = Math.floor(textObject.displayOriginX);
	const textOriginYRounded = Math.floor(textObject.displayOriginY);
	const diffX = textObject.displayOriginX - textOriginXRounded;
	const diffY = textObject.displayOriginY - textOriginYRounded;
	textObject.x += diffX;
	textObject.y += diffY;
}

const makeClickable = (gameObject) => {
	gameObject.setInteractive();

	gameObject.on("pointerdown", function (pointer) {
		this.setData("clickStart_" + pointer.id, pointer.downTime);
	});

	gameObject.on("pointerup", function (pointer) {
		const pressTime = this.getData("clickStart_" + pointer.id);

		if (pressTime === pointer.downTime && pointer.getDistance() < 15) {
			gameObject.emit("click", pointer);
		}
	});

	return gameObject;
}


export { createEl, addCl, remCl, smallestAngleDiff, textToWholePixels, makeClickable };