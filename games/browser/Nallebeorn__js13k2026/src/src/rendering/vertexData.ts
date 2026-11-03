import { createRibbon, createPill } from "./shapes.ts";

export interface MeshInfo {
	offset: number,
	size: number,
}

export function addVertexData(vertices: number[]): MeshInfo {
	return {
		size: vertices.length,
		offset: vertexData.push(...vertices) - vertices.length,
	}
};

export const vertexData: number[] = [];

export const rainbowMesh = addVertexData(createRibbon());
export const unitSphere = addVertexData(createPill(1, 1, 0));
