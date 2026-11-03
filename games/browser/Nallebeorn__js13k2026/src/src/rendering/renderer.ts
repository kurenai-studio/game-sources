import { gl } from "./glContext.ts";
import { GL_ARRAY_BUFFER, GL_BACK, GL_CLAMP_TO_EDGE, GL_COLOR, GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1, GL_COLOR_BUFFER_BIT, GL_CULL_FACE, GL_DEPTH_ATTACHMENT, GL_DEPTH_BUFFER_BIT, GL_DEPTH_COMPONENT, GL_DEPTH_COMPONENT32F, GL_DEPTH_TEST, GL_DYNAMIC_DRAW, GL_FLOAT, GL_FRAMEBUFFER, GL_FRAMEBUFFER_COMPLETE, GL_FRONT, GL_HALF_FLOAT, GL_NEAREST, GL_RG, GL_RG16F, GL_RG16UI, GL_RG32F, GL_RG32UI, GL_RG_INTEGER, GL_RGBA, GL_STATIC_DRAW, GL_TEXTURE0, GL_TEXTURE1, GL_TEXTURE2, GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_TEXTURE_MIN_FILTER, GL_TEXTURE_WRAP_S, GL_TEXTURE_WRAP_T, GL_TRIANGLES, GL_UNSIGNED_BYTE, GL_UNSIGNED_INT, GL_UNSIGNED_SHORT } from "./glConstants.ts";
import { createMatrix, IDENTITY, projectPerspective, type Transform } from "../core/math.ts";
import { DEBUG, debugWatch } from "../debug.ts";
import { colorTextureUniform, depthTextureUniform, objectPaletteUniform, objectShader, postProcessPaletteUniform, postProcessShader, surfaceIndexTextureUniform, transitionUniform, worldToClipUniform } from "./shaders/shaders.ts";
import { colors as colorsData, type Color } from "../gamedata/colors.ts";
import type { RenderObjectHandle } from "../gamedata/objects.gen.ts";
import { staticColliders } from "../physics/objectColliders.ts";
import { transformCollider } from "../physics/collision.ts";
import { vertexData, type MeshInfo } from "./vertexData.ts";
import { objectsBank } from "../gamedata/gamedata.ts";
import { transitionColor, transitionProgress } from "./screenTransition.ts";

export const ROOT_SLOT = "_";

if (DEBUG && !gl) {
	console.error("No WebGL context!");
}

// * Set up render targets
const CANVAS_WIDTH = 640;
const CANVAS_HEIGHT = 480;

const framebuffer = gl.createFramebuffer();
gl.bindFramebuffer(GL_FRAMEBUFFER, framebuffer);

const createRenderTexture = (attachment: GLenum, internalFormat: GLenum, format: GLenum, type: GLenum) => {
	const texture = gl.createTexture();
	gl.bindTexture(GL_TEXTURE_2D, texture);
	gl.texImage2D(GL_TEXTURE_2D, 0, internalFormat, CANVAS_WIDTH, CANVAS_HEIGHT, 0, format, type, null);
	gl.texParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	gl.texParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	gl.texParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	gl.texParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	gl.framebufferTexture2D(GL_FRAMEBUFFER, attachment, GL_TEXTURE_2D, texture, 0);
	return texture;
}

const colorTexture = createRenderTexture(GL_COLOR_ATTACHMENT0, GL_RGBA, GL_RGBA, GL_UNSIGNED_BYTE);
const surfaceIndexTexture = createRenderTexture(GL_COLOR_ATTACHMENT1, GL_RG16UI, GL_RG_INTEGER, GL_UNSIGNED_SHORT);
const depthTexture = createRenderTexture(GL_DEPTH_ATTACHMENT, GL_DEPTH_COMPONENT32F, GL_DEPTH_COMPONENT, GL_FLOAT);
gl.drawBuffers([GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1]);

if (DEBUG) {
	const status = gl.checkFramebufferStatus(GL_FRAMEBUFFER);

	if (status !== GL_FRAMEBUFFER_COMPLETE) {
    console.error("Framebuffer incomplete:", "0x" + status.toString(16));
	}
}

// * Set up postprocess shader
gl.useProgram(postProcessShader);

gl.uniform1i(colorTextureUniform, 0);
gl.uniform1i(surfaceIndexTextureUniform, 1);
gl.uniform1i(depthTextureUniform, 2);

gl.activeTexture(GL_TEXTURE0);
gl.bindTexture(GL_TEXTURE_2D, colorTexture);
gl.activeTexture(GL_TEXTURE1)
gl.bindTexture(GL_TEXTURE_2D, surfaceIndexTexture);
gl.activeTexture(GL_TEXTURE2);
gl.bindTexture(GL_TEXTURE_2D, depthTexture);

// * Set up configuration
gl.enable(GL_DEPTH_TEST);

const fov = 2.4; // ≈ TAU/8 radians = 45°
const aspect = CANVAS_WIDTH / CANVAS_HEIGHT;

// * Set up vertex array buffer
const arrayBuffer = gl.createBuffer();

// Must be called after vertexData has initialized
export function initializeVertexArrayBuffer() {
	gl.bindBuffer(GL_ARRAY_BUFFER, arrayBuffer);

	gl.bufferData(
			GL_ARRAY_BUFFER,
			new Float32Array(vertexData),
			GL_STATIC_DRAW
		);
	gl.vertexAttribPointer(5, 4, GL_FLOAT, false, 0, 0);
	gl.enableVertexAttribArray(5);
}

// * Instance buffer
const instanceBuffer = gl.createBuffer();
const instanceRenderList = new Map<MeshInfo, number[]>();
const staticInstanceRenderList = new Map<MeshInfo, number[]>;

const SIZEOF_FLOAT = 4;
const NUM_FLOATS_PER_INSTANCE = 5 * 4;
const INSTANCE_DATA_BYTES_STRIDE = SIZEOF_FLOAT * NUM_FLOATS_PER_INSTANCE;

// * Render API
export function drawMesh(
	mesh: MeshInfo,
	color: Color,
	transform: DOMMatrix,
	length: number,
	bend: number,
	isStatic?: boolean,
) {
	let instanceData = (isStatic ? staticInstanceRenderList : instanceRenderList).get(mesh);
	if (!instanceData) {
		(isStatic ? staticInstanceRenderList : instanceRenderList).set(mesh, instanceData = []);
	}

	instanceData.push(
		transform.m11,
		transform.m12,
		transform.m13,
		transform.m14,
		transform.m21,
		transform.m22,
		transform.m23,
		transform.m24,
		transform.m31,
		transform.m32,
		transform.m33,
		transform.m34,
		transform.m41,
		transform.m42,
		transform.m43,
		transform.m44,
		color,
		objectIndex,
		length,
		bend,
	);
}

export type SlotTransforms = Record<number | "_", Transform>;

function mul(a: DOMMatrix, b: DOMMatrix) {
	return b == IDENTITY ? a : a.multiply(b);
}

export function drawObject(
	object: RenderObjectHandle,
	slotTransforms?: SlotTransforms,
	color_override?: Color,
	isStatic?: boolean
) {
	objectIndex++;

	transformStack.push(mul(transformStack.at(-1)!, createMatrix(slotTransforms?.[ROOT_SLOT])));
	let transformSlotIndex = 0;
	objectsBank[object]!.map(command => {
		color = command.colour ?? color;
		if (command.incrementSurfaceIndex) {
			objectIndex++;
		}

		/* if (command.pushTransform) {
			transformStack.push(
				transformStack.at(-1)!
					.multiply(createMatrix(command.pushTransform))
					.multiply(createMatrix(slotTransforms?.[transformSlotIndex++]))
			);
		} */
		if (command.pushTransform) {
			transformStack.push(
				mul(
					mul(transformStack.at(-1)!, createMatrix(command.pushTransform)),
					createMatrix(slotTransforms?.[transformSlotIndex++])
				)
			);
		}


		if (command.drawShape) {
			drawMesh(
				command.drawShape,
				color_override ?? color,
				transformStack.at(-1)!,
				1,
				0,
				isStatic
			)
		}

		if (command.collider && isStatic) {
			staticColliders.push(
				transformCollider(
					command.collider,
					transformStack.at(-1)!
				),
			);
		}

		if (command.popTransform) {
		 transformStack.pop();
		}
	});
	transformStack.pop();
}

export function incrementObjectIndex() {
	objectIndex++;
}

let startingObjectIndex = 0;

export function setupFrame() {
	gl.useProgram(objectShader)
	gl.bindFramebuffer(GL_FRAMEBUFFER, framebuffer);

	gl.uniformMatrix4fv(
  	worldToClipUniform,
  	false,
		projectPerspective(fov, aspect, 0.5)
			.multiply(cameraTransform.inverse())
			.toFloat32Array(),
	);
	gl.uniform4fv(objectPaletteUniform, colorsData);
	gl.clearBufferfv(GL_COLOR, 0, [0, 0, 0, 0]);
	gl.clearBufferuiv(GL_COLOR, 1, [0, 0, 0, 0]);
	gl.clear(GL_DEPTH_BUFFER_BIT);

	transformStack = [IDENTITY];
	if (!startingObjectIndex) startingObjectIndex = objectIndex;
	objectIndex = startingObjectIndex;
	color = 0;
	instanceRenderList.clear();
}

let instanceBufferData = new Float32Array(0);

export function finishFrame() {
	const t0 = performance.now();

	// * Draw instances
	gl.bindBuffer(GL_ARRAY_BUFFER, instanceBuffer);

	debugWatch("meshes", instanceRenderList.size);

	const combinedRenderList = [
		...staticInstanceRenderList.entries(),
		...instanceRenderList.entries()
	];

	let dataSize = 0;
	for (const [, data] of combinedRenderList) {
		dataSize += data.length
	}

	if (dataSize > instanceBufferData.length) {
		instanceBufferData = new Float32Array(dataSize);
	}

	let cursor = 0;
	for (const [,data] of combinedRenderList) {
		instanceBufferData.set(data, cursor);
		cursor += data.length;
	}

	gl.bufferData(
			GL_ARRAY_BUFFER,
			instanceBufferData.subarray(0, dataSize),
			GL_DYNAMIC_DRAW
		)
	let instanceDataOffset = 0;
	for (const [mesh, data] of combinedRenderList) {
		for (let i = 0; i < 5; i++) {
			gl.vertexAttribPointer(i, 4, GL_FLOAT, false, INSTANCE_DATA_BYTES_STRIDE, instanceDataOffset + i * 4 * SIZEOF_FLOAT);
			gl.vertexAttribDivisor(i, 1);
			gl.enableVertexAttribArray(i);
		}

		instanceDataOffset += data.length * SIZEOF_FLOAT;

		gl.drawArraysInstanced(GL_TRIANGLES, mesh.offset / 4, mesh.size / 4, data.length / NUM_FLOATS_PER_INSTANCE)
	}

	debugWatch("render instances", performance.now() - t0);

	// * Draw post processing (and blit to canvas)
	const t1 = performance.now();
	gl.bindFramebuffer(GL_FRAMEBUFFER, null);
	gl.useProgram(postProcessShader);
	gl.uniform2f(transitionUniform, transitionProgress, transitionColor);
	gl.uniform4fv(postProcessPaletteUniform, colorsData);
	gl.drawArrays(GL_TRIANGLES, 0, 3);
	debugWatch("post", performance.now() - t1);
}

// * Frame state
export let cameraTransform = IDENTITY;
export function updateCameraTransform(newCameraTransform: DOMMatrix) {
	cameraTransform = newCameraTransform;
}
let objectIndex = 1;
let color!: Color;
let transformStack = [IDENTITY];
