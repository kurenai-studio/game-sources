class ThreeDFile extends Phaser.Loader.FileTypes.BinaryFile {
	constructor(loader, key, url, xhrSettings) {
		super(loader, key, url, xhrSettings);
		this.key = key;
	}

	async processModel(data) {
		const view = new DataView(data.buffer);
		let offset = 0;

		const numBlocks = view.getUint8(offset++);
		const allTriangles = [];

		for (let i = 0; i < numBlocks; i++) {
			const vertices = [];
			for (let v = 0; v < 8; v++) {
				const x = view.getInt16(offset, true); offset += 2;
				const y = -view.getInt16(offset, true); offset += 2;
				const z = view.getInt16(offset, true); offset += 2;
				offset += 4;

				vertices.push({ x: x, y: y, z: z });
			}

			const faceTex = [
				view.getUint8(offset++),
				view.getUint8(offset++),
				view.getUint8(offset++),
				view.getUint8(offset++),
				view.getUint8(offset++)
			];

			const faces = [
				{ name: "Top", indices: [4, 5, 7, 6], texId: faceTex[0], flipX: false },
				{ name: "Front", indices: [0, 1, 5, 4], texId: faceTex[1], flipX: false },
				{ name: "Right", indices: [1, 3, 7, 5], texId: faceTex[2] !== 0 ? faceTex[2] : faceTex[3], flipX: true },
				{ name: "Left", indices: [2, 0, 4, 6], texId: faceTex[4] !== 0 ? faceTex[4] : faceTex[2], flipX: false },
				{ name: "Back", indices: [3, 2, 6, 7], texId: faceTex[3] !== 0 ? faceTex[3] : faceTex[1], flipX: true },
			];

			faces.forEach((face) => {
				if (face.texId === 0) return;

				const v0 = vertices[face.indices[0]];
				const v1 = vertices[face.indices[1]];
				const v2 = vertices[face.indices[2]];
				const v3 = vertices[face.indices[3]];

				const u0x = face.flipX ? 1 : 0;
				const u1x = face.flipX ? 0 : 1;
				const u2x = face.flipX ? 0 : 1;
				const u3x = face.flipX ? 1 : 0;

				// Calculate average Z for sorting
				const avgZ = (v0.z + v1.z + v2.z + v3.z) / 4;
				const avgY = (v0.y + v1.y + v2.y + v3.y) / 4;

				// Subdivide walls to fix affine texture mapping distortion (classic PS1 wobble / crease effect).
				// Top faces don't suffer from this because they are parallel to the projection plane.
				const slices = face.name === "Top" ? 1 : 6;

				for (let s = 0; s < slices; s++) {
					const t0 = s / slices;
					const t1 = (s + 1) / slices;

					// Interpolate vertex positions
					const p0 = {
						x: v0.x + (v1.x - v0.x) * t0,
						y: v0.y + (v1.y - v0.y) * t0,
						z: v0.z + (v1.z - v0.z) * t0
					};
					const p1 = {
						x: v0.x + (v1.x - v0.x) * t1,
						y: v0.y + (v1.y - v0.y) * t1,
						z: v0.z + (v1.z - v0.z) * t1
					};
					const p2 = {
						x: v3.x + (v2.x - v3.x) * t1,
						y: v3.y + (v2.y - v3.y) * t1,
						z: v3.z + (v2.z - v3.z) * t1
					};
					const p3 = {
						x: v3.x + (v2.x - v3.x) * t0,
						y: v3.y + (v2.y - v3.y) * t0,
						z: v3.z + (v2.z - v3.z) * t0
					};

					// Interpolate horizontal UV mapping bounds
					const su0x = u0x + (u1x - u0x) * t0;
					const su1x = u0x + (u1x - u0x) * t1;
					const su2x = u3x + (u2x - u3x) * t1;
					const su3x = u3x + (u2x - u3x) * t0;

					allTriangles.push({
						texId: face.texId,
						p0: p0, p1: p1, p2: p2,
						u0x: su0x, u0y: 1, u1x: su1x, u1y: 1, u2x: su2x, u2y: 0,
						avgZ, avgY
					});

					allTriangles.push({
						texId: face.texId,
						p0: p0, p1: p2, p2: p3,
						u0x: su0x, u0y: 1, u1x: su2x, u1y: 0, u2x: su3x, u2y: 0,
						avgZ, avgY
					});
				}
			});
		}

		// Sort triangles by average Z (Painter's algorithm: lowest Z drawn first)
		// If Z is equal, sort by Y
		allTriangles.sort((a, b) => {
			if (Math.abs(a.avgZ - b.avgZ) > 0.1) {
				return a.avgZ - b.avgZ;
			}
			return b.avgY - a.avgY;
		});

		const meshBatches = [];
		let currentBatch = null;

		for (const tri of allTriangles) {
			if (!currentBatch || currentBatch.texId !== tri.texId) {
				currentBatch = { texId: tri.texId, positions: [], uvs: [] };
				meshBatches.push(currentBatch);
			}
			currentBatch.positions.push(tri.p0.x, tri.p0.y, tri.p0.z, tri.p1.x, tri.p1.y, tri.p1.z, tri.p2.x, tri.p2.y, tri.p2.z);
			currentBatch.uvs.push(tri.u0x, tri.u0y, tri.u1x, tri.u1y, tri.u2x, tri.u2y);
		}

		return meshBatches;
	};

	async onProcess() {
		const data = new Uint8Array(this.xhrLoader.response);
		this.data = await this.processModel(data);
		this.onProcessComplete();
	}
}

export default class ThreeDPlugin extends Phaser.Plugins.BasePlugin {

	constructor(pluginManager) {
		super(pluginManager);
		pluginManager.registerFileType("threeD", this.fileCallback);

		pluginManager.registerGameObject("model3D", function (x, y, modelKey, texturePackage = "TEXTURY.PKG") {
			const meshData = this.scene.cache.binary.get(modelKey);
			if (!meshData) {
				console.error(`3D Model ${modelKey} not found in cache. Did you load it?`);
				return null;
			}

			const wallContainer = new Phaser.GameObjects.Container(this.scene, x, y);
			wallContainer.name = modelKey;
			this.displayList.add(wallContainer);

			const fov = 45; // Phaser's default Mesh FOV
			const gameHeight = this.scene.scale.height;
			const perfectPanZ = ((gameHeight / 2) / Math.tan(Phaser.Math.DegToRad(fov / 2))) * 2;

			const meshes = [];
			const zScale = fov * 0.1;

			let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
			for (const batch of meshData) {
				const raw = batch.positions;
				for (let i = 0; i < raw.length; i += 3) {
					if (raw[i] < minX) minX = raw[i];
					if (raw[i] > maxX) maxX = raw[i];
					if (raw[i + 1] < minY) minY = raw[i + 1];
					if (raw[i + 1] > maxY) maxY = raw[i + 1];
				}
			}

			const width = maxX - minX;
			const height = maxY - minY;

			// Set the container size to match the footprint
			wallContainer.setSize(width, height);

			// 2. Create meshes with normalized vertices (0 to width, 0 to height)
			for (const batch of meshData) {
				const textureKey = `${texturePackage}-${batch.texId - 1}`;
				const raw = batch.positions;
				const scaled = new Array(raw.length);

				for (let i = 0; i < raw.length; i += 3) {
					// Subtract minX/minY to align vertices with the Container's 0,0 (Top-Left)
					scaled[i] = raw[i] - minX;
					scaled[i + 1] = raw[i + 1] - minY;
					scaled[i + 2] = raw[i + 2] * zScale;
				}

				const mesh = new Phaser.GameObjects.Mesh(this.scene, 0, 0, textureKey);
				mesh.addVertices(scaled, batch.uvs, undefined, true);
				mesh.panZ(perfectPanZ);

				wallContainer.add(mesh);
				meshes.push(mesh);
			}


			// Offset for perspective calculation (center of the footprint)
			const centerX = width / 2;
			const centerY = height / 2;


			wallContainer.x += centerX;
			wallContainer.y -= centerY;

			const updatePerspective = () => {
				if (!wallContainer.scene) return;

				const camera = wallContainer.scene.cameras.main;

				// The world position of the container's center
				const worldCenterX = wallContainer.x + (centerX * wallContainer.scaleX);
				const worldCenterY = wallContainer.y + (centerY * wallContainer.scaleY);

				const dx = wallContainer.x - camera.midPoint.x;
				const dy = wallContainer.y - camera.midPoint.y;

				const distDx = worldCenterX - camera.midPoint.x;
				const distDy = worldCenterY - camera.midPoint.y;

				// Depth sorting
				wallContainer.depth = 2000 + (100000 - Math.sqrt(distDx * distDx + distDy * distDy)) * 0.01 + (wallContainer.y * 0.001);

				for (const mesh of meshes) {
					mesh.x = -dx
					mesh.y = -dy
					mesh.modelPosition.x = dx - centerX;
					mesh.modelPosition.y = -dy - centerY;
				}
			};

			updatePerspective();

			this.scene.events.on("preupdate", updatePerspective);

			wallContainer.on("destroy", () => {
				this.scene.events.off("preupdate", updatePerspective);
			});

			return wallContainer;
		});
	}

	fileCallback(key, url, xhrSettings) {
		this.addFile(new ThreeDFile(this, key, url, xhrSettings));
		return this;
	}
}