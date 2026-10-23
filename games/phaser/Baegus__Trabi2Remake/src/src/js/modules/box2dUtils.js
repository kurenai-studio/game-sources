import { b2Body_GetUserData, RemoveSpriteFromWorld, b2Body_IsValid, b2Shape_GetBody, b2World_GetContactEvents, UpdateWorldSprites, WorldStep, b2DefaultBodyDef, b2DefaultWorldDef, CreateWorld, CreateBoxPolygon, STATIC, pxmVec2, b2Vec2, pxm, b2Body_SetUserData, DYNAMIC, SpriteToCircle, SpriteToBox, AddSpriteToWorld, b2DestroyBody } from "phaser-box2d/dist/PhaserBox2D.js";

/**
 * Creates a Box2D world. The world will be accessible in the scene object.
 * @param {*} scene current scene
 * @param {Object} options options for world creation
 */
export function createB2World(scene, options) {
	const defaultOptions = {
		gravity: { x: 0, y: 0 },
		...options
	};
	const worldDef = b2DefaultWorldDef();
	Object.assign(worldDef, defaultOptions);
	scene.world = CreateWorld({ worldDef });
	scene.box2DObjectsScheduledForRemoval = new Set();
}

/**
 * Updates Box2D world and sprites in the scene. Also checks for collisions.
 * @param {*} scene current scene
 * @param {Number} delta time since last update
 */
export function updateB2worldStepAndCollisions(scene, delta) {
	const worldId = scene.world.worldId;
	WorldStep({ worldId, deltaTime: delta * 0.001 });
	UpdateWorldSprites(worldId);
	checkB2CollisionBeginEvents(scene);
	checkB2CollisionEndEvents(scene);
}

/**
 * Creates a wall boundary around the canvas
 * @param {*} scene current scene
 * @param {Boolean} top boolean to create top wall
 * @param {Boolean} right boolean to create right wall
 * @param {Boolean} bottom boolean to create bottom wall
 * @param {Boolean} left boolean to create left wall
 */
export function createB2WallBoundaries(scene, top = true, right = true, bottom = true, left = true) {
	const canvasWidth = scene.game.scale.width;
	const canvasHeight = scene.game.scale.height;
	const boundWallThickness = 100;
	const groundBodyDef = b2DefaultBodyDef();
	const worldId = scene.world.worldId;
	if (top) {
		// top
		const wallTop = CreateBoxPolygon({ worldId, type: STATIC, bodyDef: groundBodyDef, position: pxmVec2(canvasWidth / 2, 0 + (boundWallThickness/2)), size: new b2Vec2(pxm(canvasWidth / 2 + boundWallThickness), pxm(boundWallThickness / 2)), density: 1.0, friction: 0.6, restitution: 0.1});
		b2Body_SetUserData(wallTop.bodyId, {type: 'wallTop'});
	}

	if (right) {
		// right
		const wallRight = CreateBoxPolygon({ worldId, type: STATIC, bodyDef: groundBodyDef, position: pxmVec2(canvasWidth + (boundWallThickness / 2), -canvasHeight / 2), size: new b2Vec2(pxm(boundWallThickness / 2), pxm(canvasHeight / 2 + boundWallThickness)), density: 1.0, friction: 0.6, restitution: 0.1 });
		b2Body_SetUserData(wallRight.bodyId, { type: 'wallRight' });
	}

	if (bottom) {
		// bottom
		const wallBottom = CreateBoxPolygon({ worldId, type: STATIC, bodyDef: groundBodyDef, position: pxmVec2(canvasWidth / 2, -canvasHeight - (boundWallThickness/2)), size: new b2Vec2(pxm(canvasWidth / 2 + boundWallThickness), pxm(boundWallThickness / 2)), density: 1.0, friction: 0.6, restitution: 0.1});
		b2Body_SetUserData(wallBottom.bodyId, {type: 'wallBottom'});
	}

	if (left) {
		// left
		const wallLeft = CreateBoxPolygon({ worldId, type: STATIC, bodyDef: groundBodyDef, position: pxmVec2(-(boundWallThickness/2), -canvasWidth / 2),	size: new b2Vec2(pxm(boundWallThickness / 2), pxm(canvasHeight / 2 + boundWallThickness)), density: 1.0, friction: 0.6, restitution: 0.1});
		b2Body_SetUserData(wallLeft.bodyId, {type: 'wallLeft'});
	}
}

/**
 * checks if there are any collision begin events and updates the collidingWith property of the userData of the bodies
 * @param {*} scene current scene
 */
export const checkB2CollisionBeginEvents = (scene) => {
	const contactEvents = b2World_GetContactEvents(scene.world.worldId);
	if (contactEvents.beginCount > 0) {
		for (let i = 0; i < contactEvents.beginEvents.length; i++) {
			const event = contactEvents.beginEvents[i];
			if (!event) continue;

			const shapeIdA = event.shapeIdA;
			const shapeIdB = event.shapeIdB;
			const bodyIdA = b2Shape_GetBody(shapeIdA);
			const bodyIdB = b2Shape_GetBody(shapeIdB);

			if (!b2Body_IsValid(bodyIdA) || !b2Body_IsValid(bodyIdB)) return;

			const userDataA = b2Body_GetUserData(bodyIdA);
			const userDataB = b2Body_GetUserData(bodyIdB);
			userDataA.collidingWith = userDataB?.type;
			userDataB.collidingWith = userDataA?.type;

			b2Body_SetUserData(bodyIdA, userDataA);
			b2Body_SetUserData(bodyIdB, userDataB);

			// console.log("Collision begins between", userDataA?.type, userDataB?.type);
		}
	}
}

/**
 * checks if there are any collision end events and updates the collidingWith property of the userData of the bodies
 * @param {*} scene current scene
 */
export const checkB2CollisionEndEvents = (scene) => {
	const contactEvents = b2World_GetContactEvents(scene.world.worldId);
	if (contactEvents.endCount > 0) {
		for (let i = 0; i < contactEvents.endEvents.length; i++) {
			const event = contactEvents.endEvents[i];
			if (!event) continue;

			const shapeIdA = event.shapeIdA;
			const shapeIdB = event.shapeIdB;
			const bodyIdA = b2Shape_GetBody(shapeIdA);
			const bodyIdB = b2Shape_GetBody(shapeIdB);

			if (!b2Body_IsValid(bodyIdA) || !b2Body_IsValid(bodyIdB)) return;

			const userDataA = b2Body_GetUserData(bodyIdA);
			const userDataB = b2Body_GetUserData(bodyIdB);
			userDataA.collidingWith = null;
			userDataB.collidingWith = null;

			b2Body_SetUserData(bodyIdA, userDataA);
			b2Body_SetUserData(bodyIdB, userDataB);

			// console.log("Collision ends between", userDataA?.type, userDataB?.type);
		}
	}
}

/**
 * Function to assign Box2D body to a sprite. Creates circle body.
 * @param {*} gameObject gameObject to assign body to
 * @param {Object} bodyOptions options for body creation
 * @returns gameObject with body assigned
 */
export function assignB2BodyCircle(gameObject, bodyOptions) {
	const bodyOptionsDefault = {
		type: DYNAMIC,
		restitution: 0.7,
		friction: 0.1
	};
	const options = { ...bodyOptionsDefault, ...bodyOptions };

	const circleBody = SpriteToCircle(gameObject.scene.world.worldId, gameObject, {
		...options,
		radius: pxm(gameObject.width / 2 * gameObject.scale) // will be probably fixed in library
	});
	b2Body_SetUserData(circleBody.bodyId, {
		collidingWith: null,
		sprite: gameObject,
		type: gameObject.name ? gameObject.name : gameObject.texture.key
	});
	AddSpriteToWorld(gameObject.scene.world.worldId, gameObject, circleBody);

	gameObject.body = circleBody;
	gameObject.body.destroy = () => {
		RemoveSpriteFromWorld(gameObject.scene.world.worldId, gameObject, true);
	}
	return gameObject;
}

/**
 * Function to assign Box2D body to a sprite. Creates box body.
 * @param {*} gameObject gameObject to assign body to
 * @param {*} bodyOptions options for body creation
 * @returns gameObject with body assigned
 */
export function assignB2BodyBox(gameObject, bodyOptions) {
	const bodyOptionsDefault = {
		type: DYNAMIC,
		restitution: 0.7,
		friction: 0.1
	};
	const options = { ...bodyOptionsDefault, ...bodyOptions };

	const boxBody = SpriteToBox(gameObject.scene.world.worldId, gameObject, {
		...options,
	});
	b2Body_SetUserData(boxBody.bodyId, {
		collidingWith: null,
		sprite: gameObject,
		type: gameObject.name ? gameObject.name : gameObject.texture.key
	});
	AddSpriteToWorld(gameObject.scene.world.worldId, gameObject, boxBody);

	gameObject.body = boxBody;
	gameObject.body.destroy = () => {
		RemoveSpriteFromWorld(gameObject.scene.world.worldId, gameObject, true);
	}
	return gameObject;
}