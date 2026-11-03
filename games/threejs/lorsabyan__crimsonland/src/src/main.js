// Crimsonland. URL flags: ?debug tuning GUI, ?webgl force WebGL2, ?quality=high|medium|low,
// ?autoplay bot plays a real run (=human for reaction lag and aim error; with
// ?mode=survival|rush and ?biome=dust|moss|ash|frost), ?mute.
import '@fontsource/teko/500.css';
import '@fontsource/teko/600.css';
import '@fontsource/teko/700.css';
import '@fontsource/jetbrains-mono/400.css';
import '@fontsource/jetbrains-mono/500.css';
import './ui/style.css';
import * as THREE from 'three/webgpu';
import { FLAGS, pickTier } from './config.js';
import { clamp } from './core/util.js';
import { Input } from './core/input.js';
import { Audio } from './core/audio.js';
import { loadProfile } from './core/save.js';
import { Stage } from './gfx/stage.js';
import { Decals } from './gfx/decals.js';
import { World } from './gfx/world.js';
import { FX } from './gfx/fx.js';
import { HeroView } from './gfx/hero.js';
import { CrowdLayer } from './gfx/crowd.js';
import { CREATURES } from './gfx/creatures.js';
import { makeStampAtlas, makeSpriteAtlas } from './gfx/textures.js';
import { ENEMY_IDS } from './data/enemies.js';
import { BONUS_LIST } from './data/bonuses.js';
import { Game } from './game/game.js';
import { UI } from './ui/ui.js';

window.__threeReady = false;

const loader = document.getElementById('loader');
const showError = (msg) => {
  loader.classList.add('done');
  const el = document.getElementById('error');
  el.hidden = false;
  el.textContent = msg;
};

async function main() {
  await document.fonts.load('600 40px Teko').catch(() => {});
  const profile = loadProfile();
  const tier = pickTier(profile.quality);
  const stage = new Stage(document.getElementById('app'), tier);
  stage.onLost = () => showError('The graphics device was lost. Reload the page to continue.');
  await stage.init();

  const decals = new Decals(stage, makeStampAtlas(), tier.decal);
  const world = new World(stage, decals, tier);
  const fx = new FX(stage, decals, makeSpriteAtlas(BONUS_LIST.map((b) => b.icon)), tier);
  const layers = ENEMY_IDS.map((id) => {
    const c = CREATURES[id];
    return new CrowdLayer(stage, decals, c.build(), c.cap, c);
  });
  const hero = new HeroView(stage);
  const input = new Input();
  const audio = new Audio();
  audio.volume = profile.volume; audio.music = profile.music;
  stage.shakeScale = profile.shake ? 1 : 0;
  const ui = new UI({ input, audio, profile, stage });
  const game = new Game({ stage, decals, world, fx, hero, layers, input, audio, ui, profile });
  ui.bindGame(game);

  game.autoplay = FLAGS.autoplay;
  game.bot.human = FLAGS.human;
  const biome = FLAGS.biome ?? profile.biome;
  game.start({ mode: FLAGS.autoplay ? (FLAGS.mode ?? 'survival') : 'survival', biome, attract: !FLAGS.autoplay });

  // Warm up: compile every material before the loader goes away, so the first kill does not hitch.
  for (const l of layers) { l.begin(); l.push(0, -30, 0, 0, 0, 1, 0, 0, 1, 1, 1, 0); l.end(); l.baker?.add(0, 0, 0, 0.001, 0, 0, 0); }
  fx.glow.draw(0, -30, 0, 1, 0, 0, 0, 1, 1, 1, 1, 0); fx.soft.draw(0, -30, 0, 1, 0, 0, 0, 1, 1, 1, 1, 0);
  fx.commit();
  decals.stamp(0, 0, 0, 0.01, 0.01, 0, 0, 0, 0, 0);
  decals.flush();
  stage.snapCamera(0, 0);
  stage.render();
  decals.clear();

  // Adaptive resolution: drop pixel ratio when frames run long, then retry after a calm spell.
  // Each drop doubles the wait, so a machine on the edge settles instead of flickering.
  const targetPR = Math.min(devicePixelRatio, tier.dpr);
  let acc = 0, frames = 0, calm = 0, wait = 10;
  const adapt = (dt) => {
    acc += dt; frames++;
    if (acc < 2) return;
    const avg = acc / frames; acc = 0; frames = 0;
    if (document.hidden) return;
    if (avg > 1 / 45) {
      stage.setPixelRatio(Math.max(0.75, stage.pixelRatio - 0.25));
      calm = 0; wait = Math.min(wait * 2, 160);
    } else if (avg < 1 / 54 && stage.pixelRatio < targetPR && (calm += 2) >= wait) {
      stage.setPixelRatio(Math.min(targetPR, stage.pixelRatio + 0.25));
      calm = 0;
    }
  };

  const timer = new THREE.Timer();
  timer.connect(document);
  stage.renderer.setAnimationLoop((t) => {
    timer.update(t);
    const dt = clamp(timer.getDelta(), 0, 1 / 20);
    game.update(dt);
    stage.render();
    adapt(dt);
  });

  // Never let the horde eat someone who alt-tabbed.
  const autoPause = () => { if (game.phase === 'play' && !game.attract && !game.autoplay) game.togglePause(); };
  addEventListener('blur', autoPause);
  document.addEventListener('visibilitychange', () => { if (document.hidden) autoPause(); });

  if (FLAGS.autoplay) { ui.setPlaying(true); } else ui.showMenu();
  loader.classList.add('done');
  window.__threeReady = true;
  if (FLAGS.autoplay || FLAGS.debug || FLAGS.selftest) window.__game = game;
  if (import.meta.env.DEV && FLAGS.selftest) import('./dev/selftest.js').then((m) => m.run(game));

  if (FLAGS.debug) {
    const { default: GUI } = await import('lil-gui');
    const gui = new GUI({ title: 'Look' });
    const s = stage;
    gui.add(s.renderer, 'toneMappingExposure', 0.3, 2, 0.01).name('exposure');
    gui.add(s.sun, 'intensity', 0, 8, 0.05).name('sun');
    gui.add(s.hemi, 'intensity', 0, 3, 0.01).name('fill');
    gui.add(s.scene, 'environmentIntensity', 0, 2, 0.01).name('env');
    gui.add(s, 'lanternPower', 0, 120, 1).name('lantern');
    gui.add(s.bloomPass.strength, 'value', 0, 2, 0.01).name('bloom');
    gui.add(s.bloomPass.threshold, 'value', 0, 2, 0.01).name('bloom threshold');
    gui.add(s.u.vignette, 'value', 0, 1, 0.01).name('vignette');
    gui.add({ biome }, 'biome', ['dust', 'moss', 'ash', 'frost']).onChange((b) => game.start({ mode: 'survival', biome: b, attract: game.attract }));
    console.info('backend:', s.renderer.backend.isWebGPUBackend ? 'WebGPU' : 'WebGL2', '| tier:', tier.name);
  }
}

main().catch((err) => {
  console.error(err);
  showError(`Could not start the game: ${err?.message || err}`);
});
