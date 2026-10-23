export const createCursor = (scene) => {
	const {x,y} = scene.input;
	const cursor = scene.add.image(x,y,"KURZOR.FSF").setDepth(9999).setOrigin(0,0);
	cursor.scrollFactorX = 0;
	cursor.scrollFactorY = 0;

	scene.input.setDefaultCursor("none"); // disable system cursor
	scene.input.on("pointermove",(p) => {
		cursor.x = p.x;
		cursor.y = p.y;
	});

	return cursor;
}