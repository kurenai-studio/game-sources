/**
 * Post-processing chain.
 *
 *   RenderPass → SSAO → Bokeh(DoF) → Bloom → Cinematic → Output → SMAA/FXAA
 *
 * Ordering rationale: AO must multiply into the beauty pass before bloom reads
 * it, DoF has to happen before bloom or out-of-focus highlights lose their
 * halation, and the Cinematic grade runs on linear HDR so god rays and lens
 * dirt add energy rather than clip. OutputPass does the ACES tonemap + sRGB
 * conversion last, then AA on the LDR result.
 *
 * Everything is individually toggleable at runtime (the HUD chips) and the whole
 * chain rebuilds on a quality change.
 */
import * as THREE from 'three';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { ShaderPass } from 'three/addons/postprocessing/ShaderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
import { SSAOPass } from 'three/addons/postprocessing/SSAOPass.js';
import { BokehPass } from 'three/addons/postprocessing/BokehPass.js';
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
import { SMAAPass } from 'three/addons/postprocessing/SMAAPass.js';
import { FXAAShader } from 'three/addons/shaders/FXAAShader.js';
import { CinematicShader } from './CinematicPass.js';
import { worldToScreen, isInFrontOf, clamp, damp, smoothstep } from '../utils/MathX.js';
import { G } from '../materials/GlobalUniforms.js';

export class PostFX {
  constructor(renderer, scene, camera, settings, materials) {
    this.renderer = renderer;
    this.scene = scene;
    this.camera = camera;
    this.settings = settings;
    this.materials = materials;

    this.enabled = { ...settings.post };
    this._prevSunUv = new THREE.Vector2(0.5, 0.5);
    this._prevCamDir = new THREE.Vector3();
    this._motion = new THREE.Vector2();
    this._focus = 300;

    this._build();
  }

  _build() {
    const { renderer, scene, camera, settings } = this;
    const size = renderer.getSize(new THREE.Vector2());
    const pr = renderer.getPixelRatio();

    this.composer?.dispose?.();
    this.composer = new EffectComposer(renderer, new THREE.WebGLRenderTarget(
      Math.max(1, Math.floor(size.x * pr)),
      Math.max(1, Math.floor(size.y * pr)),
      { type: THREE.HalfFloatType, samples: 0 },
    ));
    this.composer.setPixelRatio(pr);
    this.composer.setSize(size.x, size.y);

    this.renderPass = new RenderPass(scene, camera);
    this.composer.addPass(this.renderPass);

    // ── SSAO ─────────────────────────────────────────────────────────
    this.ssao = new SSAOPass(scene, camera, size.x, size.y);
    this.ssao.kernelRadius = 12;
    this.ssao.minDistance = 0.0008;
    this.ssao.maxDistance = 0.09;
    this.ssao.output = SSAOPass.OUTPUT.Default;
    this.ssao.enabled = !!this.enabled.ssao;
    this.composer.addPass(this.ssao);

    // ── depth of field ───────────────────────────────────────────────
    this.bokeh = new BokehPass(scene, camera, {
      focus: 300, aperture: 0.000012, maxblur: 0.004,
    });
    this.bokeh.enabled = !!this.enabled.dof;
    this.composer.addPass(this.bokeh);

    // ── bloom ────────────────────────────────────────────────────────
    this.bloom = new UnrealBloomPass(new THREE.Vector2(size.x, size.y), 0.62, 0.62, 0.72);
    this.bloom.enabled = !!this.enabled.bloom;
    this.composer.addPass(this.bloom);

    // ── the grade ────────────────────────────────────────────────────
    this.cine = new ShaderPass(CinematicShader);
    this.cine.material.uniforms.tDirt.value = this.materials.T.dirtLens;
    this.cine.material.uniforms.uResolution.value.set(size.x * pr, size.y * pr);
    this.composer.addPass(this.cine);

    // ── output (tonemap + colour space) ──────────────────────────────
    this.output = new OutputPass();
    this.composer.addPass(this.output);

    // ── AA ───────────────────────────────────────────────────────────
    if (settings.post.aa === 'smaa') {
      this.aa = new SMAAPass(size.x * pr, size.y * pr);
    } else {
      this.aa = new ShaderPass(FXAAShader);
      this.aa.material.uniforms.resolution.value.set(1 / (size.x * pr), 1 / (size.y * pr));
    }
    this.composer.addPass(this.aa);

    this.applyToggles();
  }

  applyToggles() {
    const e = this.enabled;
    this.ssao.enabled = !!e.ssao;
    this.bokeh.enabled = !!e.dof;
    this.bloom.enabled = !!e.bloom;
    const u = this.cine.material.uniforms;
    u.uGodRays.value = e.godrays ? 0.16 : 0;
    u.uGrain.value = e.grain ? 0.24 : 0;
    u.uChroma.value = e.ca ? 0.24 : 0;
    u.uMotionAmount.value = e.mblur ? 0.30 : 0;
    u.uDirt.value = e.dirt === false ? 0 : 0.045;
  }

  set(key, on) {
    this.enabled[key] = on;
    this.applyToggles();
  }

  setSize(w, h) {
    const pr = this.renderer.getPixelRatio();
    this.composer.setPixelRatio(pr);
    this.composer.setSize(w, h);
    this.ssao.setSize(w, h);
    this.bloom.setSize(w, h);
    this.cine.material.uniforms.uResolution.value.set(w * pr, h * pr);
    if (this.aa.material?.uniforms?.resolution) {
      this.aa.material.uniforms.resolution.value.set(1 / (w * pr), 1 / (h * pr));
    } else {
      this.aa.setSize?.(w * pr, h * pr);
    }
  }

  applyQuality(settings) {
    this.settings = settings;
    this.enabled = { ...settings.post };
    this._build();
  }

  /**
   * Grade + effect parameters, updated per frame from the world state.
   * @param ctx { sunWorld, fireStrength, fireWorld, ventWorld, ventStrength,
   *              focusTarget, mood, dt }
   */
  update(dt, ctx) {
    const u = this.cine.material.uniforms;
    u.uTime.value = G.uTime.value;

    // ── sun screen position & visibility (for god rays / dirt) ───────
    if (ctx.sunWorld) {
      const inFront = isInFrontOf(ctx.sunWorld, this.camera);
      const uv = worldToScreen(ctx.sunWorld, this.camera, new THREE.Vector2());
      if (inFront) u.uSunScreen.value.copy(uv);
      const off = Math.max(
        Math.max(0, -uv.x), Math.max(0, uv.x - 1),
        Math.max(0, -uv.y), Math.max(0, uv.y - 1),
      );
      const target = inFront ? (1 - smoothstep(0, 0.55, off)) * (ctx.mood?.godRays ?? 1) : 0;
      u.uSunVisible.value = damp(u.uSunVisible.value, target, 0.0001, dt);
    }

    // ── heat distortion follows the fire and the vent ────────────────
    if (ctx.fireWorld && ctx.fireStrength > 0.001) {
      const uv = worldToScreen(ctx.fireWorld, this.camera, new THREE.Vector2());
      u.uHeatCenter.value.copy(uv);
      const dist = this.camera.position.distanceTo(ctx.fireWorld);
      u.uHeatRadius.value = clamp(9000 / Math.max(dist, 60) * 0.06, 0.12, 0.7);
      u.uHeatStrength.value = damp(u.uHeatStrength.value, ctx.fireStrength * 1.35, 0.0001, dt);
    } else {
      u.uHeatStrength.value = damp(u.uHeatStrength.value, 0, 0.0001, dt);
    }
    if (ctx.ventWorld) {
      const uv = worldToScreen(ctx.ventWorld, this.camera, new THREE.Vector2());
      u.uHeat2Center.value.copy(uv);
      const inFront = isInFrontOf(ctx.ventWorld, this.camera);
      u.uHeat2Strength.value = damp(
        u.uHeat2Strength.value,
        inFront ? (ctx.ventStrength ?? 0.25) : 0,
        0.0002, dt,
      );
    }

    // ── pressure waves (eruption blast, dragon roar) ─────────────────
    {
      let best = null, bestS = 0;
      for (const w of ctx.waves ?? []) {
        if (!w || w.radius <= 0 || w.strength <= 0.001) continue;
        if (!isInFrontOf(w.origin, this.camera)) continue;
        if (w.strength > bestS) { best = w; bestS = w.strength; }
      }
      const R = u.uRipple.value;
      if (best) {
        const uv = worldToScreen(best.origin, this.camera, new THREE.Vector2());
        const dist = Math.max(30, this.camera.position.distanceTo(best.origin));
        const halfH = Math.tan(THREE.MathUtils.degToRad(this.camera.fov * 0.5));
        R.set(uv.x, uv.y, best.radius / (2 * dist * halfH), best.strength);
      } else {
        R.w = 0;
      }
    }

    // ── motion blur from camera angular + lateral velocity ───────────
    const dir = new THREE.Vector3();
    this.camera.getWorldDirection(dir);
    const delta = dir.clone().sub(this._prevCamDir);
    // Project the change into screen axes.
    const right = new THREE.Vector3().crossVectors(dir, new THREE.Vector3(0, 1, 0)).normalize();
    const upV = new THREE.Vector3().crossVectors(right, dir).normalize();
    this._motion.set(delta.dot(right), delta.dot(upV)).multiplyScalar(1 / Math.max(dt, 1e-3));
    u.uMotion.value.lerp(this._motion, 0.35);
    this._prevCamDir.copy(dir);

    // ── autofocus ────────────────────────────────────────────────────
    if (this.bokeh.enabled && ctx.focusTarget) {
      const d = this.camera.position.distanceTo(ctx.focusTarget);
      this._focus = damp(this._focus, d, 0.002, dt);
      this.bokeh.materialBokeh.uniforms.focus.value = this._focus;
      // Wider aperture (shallower depth) when close — like a real lens.
      this.bokeh.materialBokeh.uniforms.aperture.value =
        clamp(0.000022 * (120 / Math.max(this._focus, 40)), 0.000002, 0.00004);
      this.bokeh.materialBokeh.uniforms.maxblur.value = ctx.mood?.dofBlur ?? 0.007;
    }

    // ── mood grade ───────────────────────────────────────────────────
    const m = ctx.mood;
    if (m) {
      u.uExposure.value = damp(u.uExposure.value, m.exposure ?? 1, 0.0005, dt);
      u.uContrast.value = damp(u.uContrast.value, m.contrast ?? 1.06, 0.0005, dt);
      u.uSaturation.value = damp(u.uSaturation.value, m.saturation ?? 1.08, 0.0005, dt);
      u.uVignette.value = damp(u.uVignette.value, m.vignette ?? 0.9, 0.0005, dt);
      if (m.lift) u.uLift.value.lerp(new THREE.Color(m.lift), dt * 1.6);
      if (m.shadowTint) u.uShadowTint.value.lerp(new THREE.Color(m.shadowTint), dt * 1.6);
      if (m.highlightTint) u.uHighlightTint.value.lerp(new THREE.Color(m.highlightTint), dt * 1.6);
      if (this.bloom.enabled) {
        this.bloom.strength = damp(this.bloom.strength, m.bloom ?? 0.62, 0.0005, dt);
        this.bloom.radius = damp(this.bloom.radius, m.bloomRadius ?? 0.62, 0.0005, dt);
        this.bloom.threshold = damp(this.bloom.threshold, m.bloomThreshold ?? 0.72, 0.0005, dt);
      }
    }
  }

  render(dt) { this.composer.render(dt); }

  dispose() { this.composer?.dispose?.(); }
}
