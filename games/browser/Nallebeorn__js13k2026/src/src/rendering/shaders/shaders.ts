import { DEBUG } from "../../debug.ts";
import { GL_COMPILE_STATUS, GL_FRAGMENT_SHADER, GL_LINK_STATUS, GL_VERTEX_SHADER } from "../glConstants.ts";
import { gl } from "../glContext.ts";
import objectVertSource from "./object.vert.glsl";
import objectFragSource from "./object.frag.glsl";
import postProcessVertSource from "./postProcess.vert.glsl"
import postProcessFragSource from "./postProcess.frag.glsl"

export const objectShader = createShaderProgram(objectVertSource, objectFragSource);
export const worldToClipUniform = gl.getUniformLocation(objectShader, "w");
export const objectPaletteUniform = gl.getUniformLocation(objectShader, "p");

export const postProcessShader = createShaderProgram(postProcessVertSource, postProcessFragSource);
export const colorTextureUniform = gl.getUniformLocation(postProcessShader, "i");
export const surfaceIndexTextureUniform = gl.getUniformLocation(postProcessShader, "s");
export const depthTextureUniform = gl.getUniformLocation(postProcessShader, "d");
export const postProcessPaletteUniform = gl.getUniformLocation(postProcessShader, "p");
export const transitionUniform = gl.getUniformLocation(postProcessShader, "t");


type ShaderType = typeof GL_VERTEX_SHADER | typeof GL_FRAGMENT_SHADER

export function createShaderProgram(vertexSource: string, fragmentSource: string) {
	const shaderProgram = gl.createProgram();

	const compileAndAttachShader = (type: ShaderType, source: string) => {
		const shader = gl.createShader(type)!;
		gl.shaderSource(shader, source);
		gl.compileShader(shader)

		if (DEBUG) {
			if (!gl.getShaderParameter(shader, GL_COMPILE_STATUS)) {
		    console.error(
		      `An error occurred compiling the shaders: ${gl.getShaderInfoLog(shader)}`,
				);
				console.info("Failing shader source:");
				console.info(source);
				gl.deleteShader(shader);
				return
		  }
		}

		gl.attachShader(shaderProgram, shader);
	}

	compileAndAttachShader(GL_VERTEX_SHADER, vertexSource);
	compileAndAttachShader(GL_FRAGMENT_SHADER, fragmentSource);
	gl.linkProgram(shaderProgram);

	if (DEBUG) {
	 if (!gl.getProgramParameter(shaderProgram, GL_LINK_STATUS)) {
	    console.error(
	      `Unable to initialize the shader program: ${gl.getProgramInfoLog(
	        shaderProgram,
	      )}`,
	    );
	  }
	}

  return shaderProgram;
}
