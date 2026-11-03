/**
 * Asset pipeline.
 *
 * The realm ships *fully procedural* — no binary payload, so first paint is
 * instant and there's nothing to 404. This loader exists so that dropping a
 * compressed glTF into /assets is a one-line change: add it to the manifest
 * and it streams in with DRACO geometry + KTX2/Basis textures already wired,
 * decoders lazily instantiated only if something actually needs them.
 */
import * as THREE from 'three';
import { GLTFLoader }  from 'three/addons/loaders/GLTFLoader.js';
import { DRACOLoader } from 'three/addons/loaders/DRACOLoader.js';
import { KTX2Loader }  from 'three/addons/loaders/KTX2Loader.js';
import { RGBELoader }  from 'three/addons/loaders/RGBELoader.js';

const CDN = 'https://unpkg.com/three@0.169.0/examples/jsm/libs';

export class AssetLoader {
  constructor(renderer) {
    this.renderer = renderer;
    this.manager = new THREE.LoadingManager();
    this.cache = new Map();
    this._gltf = null;
    this._rgbe = null;
    this.onProgress = null;
  }

  get gltf() {
    if (!this._gltf) {
      const draco = new DRACOLoader(this.manager).setDecoderPath(`${CDN}/draco/gltf/`);
      const ktx2  = new KTX2Loader(this.manager)
        .setTranscoderPath(`${CDN}/basis/`)
        .detectSupport(this.renderer);

      this._gltf = new GLTFLoader(this.manager)
        .setDRACOLoader(draco)
        .setKTX2Loader(ktx2);
      this._gltf.setMeshoptDecoder?.(null);
      this._draco = draco;
      this._ktx2 = ktx2;
    }
    return this._gltf;
  }

  get rgbe() {
    if (!this._rgbe) this._rgbe = new RGBELoader(this.manager);
    return this._rgbe;
  }

  /** Load an optional model; resolves to null (with a warning) if absent. */
  async model(url) {
    if (this.cache.has(url)) return this.cache.get(url);
    try {
      const gltf = await this.gltf.loadAsync(url);
      this.cache.set(url, gltf);
      return gltf;
    } catch (e) {
      console.warn(`[assets] optional model missing: ${url}`, e.message);
      return null;
    }
  }

  /** Load an .hdr equirect and return a PMREM-ready texture, or null. */
  async hdri(url) {
    try {
      const tex = await this.rgbe.loadAsync(url);
      tex.mapping = THREE.EquirectangularReflectionMapping;
      return tex;
    } catch (e) {
      console.warn(`[assets] optional HDRI missing: ${url} — using procedural sky env`);
      return null;
    }
  }

  /** Manifest sweep. Empty by default; procedural build steps report progress instead. */
  async loadManifest(manifest = []) {
    const out = {};
    let done = 0;
    for (const item of manifest) {
      out[item.id] = item.type === 'hdri' ? await this.hdri(item.url) : await this.model(item.url);
      this.onProgress?.(++done / manifest.length, item.id);
    }
    return out;
  }

  dispose() {
    this._draco?.dispose?.();
    this._ktx2?.dispose?.();
    this.cache.clear();
  }
}
