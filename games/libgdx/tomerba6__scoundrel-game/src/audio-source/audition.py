"""Builds the listening page: audio-source/build/audition.html (gitignored, never shipped).

    python audio-source/audition.py

Every sound effect is embedded in the page, so it opens straight from disk with
no server. Besides each file on its own, it plays scenes the way the game will:
a card's value picks its weight file and pitch nudge, frequent sounds vary per
play, and no version repeats back to back. Those rules are read out of the Java
source (Scale, SfxChoice, Sound) rather than copied, so the page cannot drift
from what the game does.
"""

import base64
import html
import json
import re
import sys
from pathlib import Path

import check
import music
import recipes
import render
import synth

HERE = Path(__file__).resolve().parent
OUT = HERE / "build" / "audition.html"
AUDIO_JAVA = render.ROOT / "core" / "src" / "main" / "java" / "com" / "tomer" / "scoundrel" / "audio"


def java_rules():
    """The game's weighting and variation constants, read from the Java source."""
    scale = (AUDIO_JAVA / "Scale.java").read_text(encoding="utf-8")
    choice = (AUDIO_JAVA / "SfxChoice.java").read_text(encoding="utf-8")
    sound = (AUDIO_JAVA / "Sound.java").read_text(encoding="utf-8")

    def constant(source, name):
        return float(re.search(rf"static final float {name} = ([0-9.]+)f;", source).group(1))

    def array(source, name):
        body = re.search(rf"static final float\[\] {name} = \{{([^}}]*)\}};", source).group(1)
        return [float(v.strip().rstrip("f")) for v in body.split(",")]

    bands = {m.group(1): [int(v) for v in m.group(2).split(",")]
             for m in re.finditer(r"^\s{4}([A-Z]+)\(([0-9,\s]+)\);?,?$", scale, re.M)}
    sounds = {}
    for m in re.finditer(r"^\s{4}([A-Z]+)\((\d+)(?:,\s*Scale\.([A-Z]+))?\)[,;]", sound, re.M):
        sounds[m.group(1).lower()] = {"versions": int(m.group(2)), "scale": m.group(3)}
    rules = {"nudge": constant(scale, "NUDGE"), "pitchJitter": constant(choice, "PITCH_JITTER"),
             "volumeJitter": constant(choice, "VOLUME_JITTER"), "scales": bands, "sounds": sounds,
             "riffleGain": array(choice, "RIFFLE_GAIN"), "rifflePitch": array(choice, "RIFFLE_PITCH")}
    if len(bands) != 4 or len(sounds) != 10:
        sys.exit(f"could not read the Java rules (found {len(bands)} scales, {len(sounds)} sounds)")
    return rules


def describe(recipe):
    return " ".join((recipe.build.__doc__ or "").split())


CANDIDATE_DIR = OUT.parent / "candidates"


def candidates():
    """Audition-only options: the CANDIDATES recipes, rendered here, plus any reference
    files already saved in build/candidates/ (such as the flips as last heard)."""
    CANDIDATE_DIR.mkdir(parents=True, exist_ok=True)
    for job in recipes.jobs(recipes.CANDIDATES):
        (CANDIDATE_DIR / f"{job.name}.wav").write_bytes(render.wav_bytes(recipes.render(job)))
    return {p.stem: base64.b64encode(p.read_bytes()).decode("ascii") for p in sorted(CANDIDATE_DIR.glob("*.wav"))}


def streams():
    """The music, cues and torch loop, embedded as OGG, keyed by name ("music/run")."""
    return {name: base64.b64encode(render.stream_path(name).read_bytes()).decode("ascii")
            for name in music.STREAMS if render.stream_path(name).exists()}


def main():
    files, facts = {}, {}
    for job in recipes.jobs():
        path = render.SFX_DIR / f"{job.name}.wav"
        files[job.name] = base64.b64encode(path.read_bytes()).decode("ascii")
        x = check.read_wav(path)[0]
        facts[job.name] = f"{len(x) / synth.SR * 1000:.0f} ms, {synth.loudness_db(x):.1f} dBFS"
    files.update(candidates())
    files.update(streams())

    sections = []
    for recipe in recipes.RECIPES:
        rows = []
        weights = recipe.weights or ("",)
        for weight in weights:
            buttons = []
            for v in range(1, recipe.versions + 1):
                name = f"{recipe.sound}_{weight}_{v}" if weight else f"{recipe.sound}_{v}"
                buttons.append(f'<button data-file="{name}" title="{facts[name]}">'
                               f'{html.escape(weight or "play")}{" " + str(v) if recipe.versions > 1 else ""}</button>')
            rows.append(f'<div class="row">{"".join(buttons)}</div>')
        sections.append(f'<section><h3>{recipe.sound}</h3><p>{html.escape(describe(recipe))}</p>'
                        f'{"".join(rows)}</section>')

    page = TEMPLATE.replace("/*FILES*/{}", json.dumps(files)) \
        .replace("/*RULES*/{}", json.dumps(java_rules())) \
        .replace("<!--SOUNDS-->", "\n".join(sections))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(page, encoding="utf-8")
    print(f"wrote {OUT.relative_to(render.ROOT)} ({OUT.stat().st_size // 1024} KB, {len(files)} sounds)")
    return 0


TEMPLATE = r"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Scoundrel audition</title>
<style>
  :root { --bg:#17120e; --panel:#241d16; --line:#4a3524; --text:#e8ddc7; --dim:#a8987c; --torch:#d9a441; }
  * { box-sizing: border-box; }
  body { margin:0; background:var(--bg); color:var(--text); font:15px/1.5 ui-monospace, Consolas, monospace; }
  main { max-width: 980px; margin: 0 auto; padding: 24px 16px 64px; }
  h1 { color: var(--torch); font-size: 22px; margin: 0 0 4px; letter-spacing: .08em; }
  h2 { color: var(--torch); font-size: 16px; margin: 32px 0 8px; letter-spacing: .08em; text-transform: uppercase; }
  h3 { margin: 0 0 4px; font-size: 15px; text-transform: uppercase; letter-spacing: .06em; }
  p { margin: 0 0 8px; color: var(--dim); }
  .bar { position: sticky; top: 0; background: var(--bg); padding: 10px 0; border-bottom: 2px solid var(--line);
         display: flex; flex-wrap: wrap; gap: 16px; align-items: center; z-index: 1; }
  section { background: var(--panel); border: 2px solid var(--line); padding: 12px 14px; margin: 10px 0; }
  .row { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 6px; }
  button { background: #33291f; color: var(--text); border: 2px solid var(--line); padding: 5px 10px;
           font: inherit; cursor: pointer; }
  button:hover { border-color: var(--torch); }
  button:active { background: var(--line); }
  .scene button { border-color: var(--torch); }
  label { color: var(--dim); }
  ol { color: var(--dim); margin: 0 0 8px; padding-left: 20px; }
  .value { min-width: 38px; }
</style></head>
<body><main>
<h1>SCOUNDREL — AUDITION</h1>
<p>The 29 synthesized placeholder sound effects, on their own and in scenes that behave the way the game
will. Claude built them without hearing them — you are the ear. Signed off in listening round 1
(2026-09-24); what to listen for:</p>
<ol>
  <li>Does each sound fit <b>crunchy lo-fi</b> in a torchlit dungeon, and is it the thing its description says?</li>
  <li>Can you tell <b>light / medium / heavy</b> apart?</li>
  <li>Does anything <b>grate on repeat</b> (the scenes with eight in a row)?</li>
  <li>Is the <b>loudness even</b> — nothing jumping out, nothing lost?</li>
</ol>
<div class="bar">
  <label>volume <input id="volume" type="range" min="0" max="1" step="0.01" value="0.8"></label>
  <label><input id="vary" type="checkbox" checked> game variation (versions, ±pitch, quieter)</label>
  <button id="stop">stop</button>
</div>

<h2>Music, cues and the torch (listening round 3)</h2>
<section class="scene"><h3>The tracks</h3>
  <p>Placeholders, composed without being heard: D minor, 64 BPM, 60-second loops. The run track is a
  drone, the theme plucked sparsely, and a heartbeat on each chord's root; the menu is the same theme
  stripped back. These play looped. Judge the mood first; this page decodes with the browser, so the
  seam that counts is the one in the game.</p>
  <div class="row"><button data-music="music/menu" data-loop="1">menu track</button>
  <button data-music="music/run" data-loop="1">run track</button>
  <button data-music="music/menu" data-loop="1" data-seam="6">menu: 6 s before the seam</button>
  <button data-music="music/run" data-loop="1" data-seam="6">run: 6 s before the seam</button>
  <button data-crossfade="1">menu → run crossfade (1 s, as the game does)</button></div></section>
<section class="scene"><h3>The ends of a run</h3>
  <p>The win cue resolves the theme onto D major; the death cue tolls and sinks. In the game the death cue
  plays after the music has died with the torch and a beat of silence; the chime follows either cue.</p>
  <div class="row"><button data-music="music/win">win cue</button><button data-music="music/death">death cue</button>
  <button data-file="chime_1">chime</button></div></section>
<section class="scene"><h3>The torch</h3>
  <p>On every screen, quietly under the music, at the SOUND level; it gutters out with the torch when you die.
  A 20-second loop.</p>
  <div class="row"><button data-music="ambience/torch" data-loop="1">torch loop</button>
  <button data-music="ambience/torch" data-loop="1" data-seam="4">torch: 4 s before the seam</button>
  <button data-together="1">run track with the torch under it</button></div></section>

<h2>Scenes, as the game will play them</h2>
<section class="scene"><h3>Dealing</h3>
  <p>A flip per card as it lands, a frame (83 ms) apart, shaped as one riffle: each flip overlaps the
  next, and each card is a little quieter and lower than the one before (chosen in round 1 over one
  sound per deal and over the first card alone).</p>
  <div class="row"><button data-scene="deal">deal a room</button><button data-scene="deals">4 deals</button></div></section>
<section class="scene"><h3>A weapon kill: clean, then costly</h3>
  <p>The blade alone when the weapon takes it all; a thud under it when damage gets through (1–4 light, 5+ heavy).</p>
  <div class="row"><button data-scene="clean">clean kill (weapon 6)</button>
  <button data-scene="costly-light">costly: 3 got through</button>
  <button data-scene="costly-heavy">costly: 8 got through</button></div></section>
<section class="scene"><h3>Repetition</h3>
  <p>The same moment eight times in a row, the way a run repeats it. Listen for a machine gun.</p>
  <div class="row"><button data-scene="kills">8 weapon kills</button><button data-scene="fists">8 bare-handed fights</button>
  <button data-scene="clicks">menu clicks</button></div></section>
<section class="scene"><h3>A fast room</h3>
  <p>A quick run through one room: deal, take a heavy weapon, kill with it (some damage through), drink,
  a second potion wasted, avoid the next room, deal.</p>
  <div class="row"><button data-scene="room">play the room</button></div></section>
<section class="scene"><h3>Every value</h3>
  <p>Each card value picks its weight file and a small pitch nudge within it, as the game does.</p>
  <div class="row" id="values"></div></section>
<section class="scene"><h3>Trophies</h3>
  <div class="row"><button data-file="chime_1">chime</button></div></section>

<h2>Every file</h2>
<p>Hover a button for its length and loudness (the loudest 50 ms). These play the file exactly, no variation.</p>
<!--SOUNDS-->
</main>
<script>
const FILES = /*FILES*/{};
const RULES = /*RULES*/{};
const FRAME = 1 / 12;
const ctx = new (window.AudioContext || window.webkitAudioContext)();
const master = ctx.createGain();
master.connect(ctx.destination);
const buffers = {};
const live = new Set();

const ready = Promise.all(Object.entries(FILES).map(async ([name, b64]) => {
  const bytes = Uint8Array.from(atob(b64), c => c.charCodeAt(0));
  buffers[name] = await ctx.decodeAudioData(bytes.buffer);
}));

function play(name, when = 0, pitch = 1, volume = 1) {
  const src = ctx.createBufferSource();
  src.buffer = buffers[name];
  src.playbackRate.value = pitch;
  const gain = ctx.createGain();
  gain.gain.value = volume;
  src.connect(gain).connect(master);
  src.start(ctx.currentTime + 0.03 + when);
  live.add(src);
  src.onended = () => live.delete(src);
}

// --- the game's rules, read from the Java source ---------------------------
function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }
function weightOf(scale, value) {
  const [min, lightMax, mediumMax, max] = RULES.scales[scale];
  const v = clamp(value, min, max);
  return v <= lightMax ? "light" : v <= mediumMax ? "medium" : "heavy";
}
function pitchWithin(v, lo, hi) {
  if (hi <= lo) return 1;
  return 1 + RULES.nudge * ((lo + hi) / 2 - v) / ((hi - lo) / 2);
}
function pitchOf(scale, value) {
  const [min, lightMax, mediumMax, max] = RULES.scales[scale];
  const v = clamp(value, min, max);
  const w = weightOf(scale, v);
  return w === "light" ? pitchWithin(v, min, lightMax)
       : w === "medium" ? pitchWithin(v, lightMax + 1, mediumMax) : pitchWithin(v, mediumMax + 1, max);
}
const lastVersion = {};
function pickVersion(stem, versions) {
  if (versions === 1 || !document.getElementById("vary").checked) return 1;
  const prev = lastVersion[stem];
  let v;
  if (prev === undefined) v = 1 + Math.floor(Math.random() * versions);
  else { const d = 1 + Math.floor(Math.random() * (versions - 1)); v = d >= prev ? d + 1 : d; }
  lastVersion[stem] = v;
  return v;
}
// A sound the game's way: its weight file and value nudge, a version that does not repeat,
// and - for sounds with several versions - the per-play variation. `stem` may name a
// candidate's files instead (e.g. "flip_now"), with `versions` given.
function sfx(sound, value, when = 0, gain = 1, pitchStep = 1, stem = null, versions = null) {
  const rule = RULES.sounds[sound] || { versions: versions, scale: null };
  let base = stem || sound, pitch = pitchStep, volume = gain;
  if (rule.scale) { base += "_" + weightOf(rule.scale, value); pitch *= pitchOf(rule.scale, value); }
  const n = versions || rule.versions;
  const version = pickVersion(base, n);
  if (n > 1 && document.getElementById("vary").checked) {
    pitch *= 1 + RULES.pitchJitter * (2 * Math.random() - 1);
    volume *= 1 - RULES.volumeJitter * Math.random();
  }
  play(base + "_" + version, when, pitch, volume);
}
// Each card of a deal lands three frames after it sets off, one frame after the card before it.
function landing(i) { return (i + 3) * FRAME; }
// The deal's riffle (SfxChoice.RIFFLE_*): each card a little quieter and lower than the one before.
function deal(at, cards = 4) {
  for (let i = 0; i < cards; i++) {
    const step = Math.min(i, RULES.riffleGain.length - 1);
    sfx("flip", 0, at + landing(i), RULES.riffleGain[step], RULES.rifflePitch[step]);
  }
}
function weaponKill(weapon, damage, at) {
  sfx("blade", weapon, at);
  if (damage > 0) sfx("thud", damage, at);
}

const SCENES = {
  "deal": () => deal(0),
  "deals": () => { for (let i = 0; i < 4; i++) deal(i * 0.9); },
  "clean": () => weaponKill(6, 0, 0),
  "costly-light": () => weaponKill(6, 3, 0),
  "costly-heavy": () => weaponKill(6, 8, 0),
  "kills": () => { for (let i = 0; i < 8; i++) weaponKill(7, i % 3 === 0 ? 2 : 0, i * 0.45); },
  "fists": () => { for (let i = 0; i < 8; i++) sfx("fist", 8, i * 0.5); },
  "clicks": () => { for (let i = 0; i < 6; i++) sfx("click", 0, i * 0.35); },
  "room": () => {
    let t = 0;
    deal(t); t += 1.0;
    sfx("equip", 9, t + 3 * FRAME); t += 0.9;                     // lands on the rail 250 ms in
    weaponKill(9, 3, t + 2 * FRAME); t += 0.8;                    // the blade lands 167 ms in
    sfx("drink", 6, t + 5 * FRAME); t += 1.0;                     // pours 417 ms in
    sfx("spill", 0, t + 3 * FRAME); t += 0.9;                     // spills 250 ms in
    sfx("sweep", 0, t); deal(t + 3 * FRAME, 4);                   // the room goes, the next comes
  },
};

const values = document.getElementById("values");
for (const [label, sound, lo, hi] of [["equip", "equip", 2, 10], ["blade", "blade", 2, 10],
                                      ["fist", "fist", 2, 14], ["drink", "drink", 2, 10], ["thud", "thud", 1, 12]]) {
  const row = document.createElement("div");
  row.className = "row";
  row.innerHTML = `<span class="value">${label}</span>`;
  for (let v = lo; v <= hi; v++) {
    const b = document.createElement("button");
    b.textContent = v;
    b.onclick = async () => { await start(); sfx(sound, v); };
    row.appendChild(b);
  }
  values.appendChild(row);
}

// Streams: looped from a chosen offset, with a gain that can be faded (equal power, as the game).
function stream(name, { loop = false, offset = 0, gain = 1 } = {}) {
  const src = ctx.createBufferSource();
  src.buffer = buffers[name];
  src.loop = loop;
  const g = ctx.createGain();
  g.gain.value = gain;
  src.connect(g).connect(master);
  src.start(ctx.currentTime + 0.03, Math.max(0, offset));
  live.add(src);
  src.onended = () => live.delete(src);
  return g;
}
function equalPowerFade(g, from, to, seconds) {
  const steps = 32, curve = new Float32Array(steps);
  for (let i = 0; i < steps; i++) {
    const level = from + (to - from) * (i / (steps - 1));
    curve[i] = Math.sin(level * Math.PI / 2);
  }
  g.gain.setValueCurveAtTime(curve, ctx.currentTime + 0.03, seconds);
}

async function start() { await ctx.resume(); await ready; }
document.addEventListener("click", async (e) => {
  const button = e.target.closest("button");
  if (!button) return;
  if (button.dataset.file) { await start(); play(button.dataset.file); }
  if (button.dataset.scene) { await start(); SCENES[button.dataset.scene](); }
  if (button.dataset.music) {
    await start();
    const name = button.dataset.music;
    const seam = button.dataset.seam ? buffers[name].duration - Number(button.dataset.seam) : 0;
    stream(name, { loop: !!button.dataset.loop, offset: seam });
  }
  if (button.dataset.crossfade) {
    await start();
    const menu = stream("music/menu", { loop: true });
    setTimeout(() => {
      const run = stream("music/run", { loop: true, gain: 0 });
      equalPowerFade(menu, 1, 0, 1.0);
      equalPowerFade(run, 0, 1, 1.0);
    }, 4000);
  }
  if (button.dataset.together) {
    await start();
    stream("music/run", { loop: true, gain: 0.5 });     // the game's default music level (-6 dB)
    stream("ambience/torch", { loop: true, gain: 1 });  // and sound at full
  }
});
document.getElementById("stop").onclick = () => { for (const s of live) s.stop(); live.clear(); };
document.getElementById("volume").oninput = (e) => { master.gain.value = e.target.value; };
master.gain.value = 0.8;
</script>
</body></html>
"""

if __name__ == "__main__":
    sys.exit(main())
