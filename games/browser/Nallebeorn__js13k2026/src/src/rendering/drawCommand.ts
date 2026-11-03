import type { Transform } from "../core/math.ts";
import type { Color } from "../gamedata/colors.ts";
import type { Collider } from "../physics/collision.ts";
import type { MeshInfo } from "./vertexData.ts";

export interface DrawCommand {
	pushTransform?: Transform;
	popTransform?: 1;

	drawShape?: 0 | MeshInfo;
	colour?: Color;
	incrementSurfaceIndex?: 0 | number;
	collider?: 0 | Collider;
}
