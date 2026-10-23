(() => {
  "use strict";

  const game = document.getElementById("game");
  const scene = document.getElementById("scene");
  const fx = document.getElementById("fx");
  const uiCanvas = document.getElementById("uiCanvas");

  const bounceCountEl = document.getElementById("bounceCount");
  const stageValueEl = document.getElementById("stageValue");
  const pauseButton = document.getElementById("pauseButton");
  const resetButton = document.getElementById("resetButton");
  const pauseOverlay = document.getElementById("pauseOverlay");
  const resumeButton = document.getElementById("resumeButton");

  const ctx = scene.getContext("2d", { alpha: false, desynchronized: true });
  const fxCtx = fx.getContext("2d", { alpha: true, desynchronized: true });
  const uiCtx = uiCanvas.getContext("2d", { alpha: true });

  const TAU = Math.PI * 2;
  const DPR_CAP = 2;
  const MAX_TRAIL = 1900;
  const MAX_PARTICLES = 320;

  // Visual evolution is driven primarily by time, then reinforced by bounces.
  // This keeps growth smooth and makes later stages feel earned instead of abrupt.
  const GROWTH_DURATION = 76000;
  const MIN_BALL_RADIUS = 7.3;
  const MAX_BALL_RADIUS = 27.5;

  let W = 360;
  let H = 640;
  let dpr = 1;
  let cx = 180;
  let cy = 320;
  let arenaR = 163;
  let paused = false;
  let started = false;
  let previous = performance.now();
  let elapsed = 0;
  let bounceCount = 0;
  let stage = 1;
  let pulse = 0;
  let boost = 0;
  let evolutionFlash = 0;
  let growthTier = 1;

  const trail = [];
  const particles = [];
  const impacts = [];
  const sparkles = [];

  const ball = {
    x: 0,
    y: 0,
    vx: 2.08,
    vy: -1.12,
    r: 7.3,
    spin: 0,
    growthKick: 0
  };

  const camera = {
    swayX: 0,
    swayY: 0,
    roll: 0
  };

  function clamp(v, min, max) {
    return Math.max(min, Math.min(max, v));
  }

  function setCanvasSize(canvas, context) {
    canvas.width = Math.round(W * dpr);
    canvas.height = Math.round(H * dpr);
    canvas.style.width = `${W}px`;
    canvas.style.height = `${H}px`;
    context.setTransform(dpr, 0, 0, dpr, 0, 0);
  }

  function resize() {
    const rect = game.getBoundingClientRect();
    W = rect.width;
    H = rect.height;
    dpr = Math.min(window.devicePixelRatio || 1, DPR_CAP);

    setCanvasSize(scene, ctx);
    setCanvasSize(fx, fxCtx);
    setCanvasSize(uiCanvas, uiCtx);

    cx = W * 0.5;
    cy = H * 0.5;
    arenaR = Math.min(W * 0.455, H * 0.255);

    if (!started) reset(true);
    drawUiFrame();
  }

  function reset(initial = false) {
    paused = false;
    started = true;
    bounceCount = 0;
    stage = 1;
    pulse = 0;
    boost = 0;
    evolutionFlash = 0;
    growthTier = 1;

    trail.length = 0;
    particles.length = 0;
    impacts.length = 0;
    sparkles.length = 0;

    ball.x = cx;
    ball.y = cy - arenaR * 0.75;
    ball.vx = 2.16;
    ball.vy = -1.10;
    ball.r = 7.3;
    ball.spin = 0;
    ball.growthKick = 0;

    camera.swayX = 0;
    camera.swayY = 0;
    camera.roll = 0;

    addTrail(ball.x, cy + arenaR * .98);
    addTrail(ball.x, ball.y);

    for (let i = 0; i < 22; i++) {
      spawnParticle(ball.x, ball.y, 0.5);
    }

    updateHud();
    pauseOverlay.hidden = true;
    pauseButton.textContent = "Ⅱ";
    pauseButton.setAttribute("aria-label", "Pause game");

    if (initial) draw();
  }

  function updateHud() {
    bounceCountEl.textContent = String(bounceCount);
    stageValueEl.textContent = roman(stage);
  }

  function roman(n) {
    const values = [[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]];
    let out = "";
    let value = n;
    for (const [num, char] of values) {
      while (value >= num) {
        out += char;
        value -= num;
      }
    }
    return out;
  }

  function addTrail(x, y) {
    const last = trail[trail.length - 1];
    if (last) {
      const dx = x - last.x;
      const dy = y - last.y;
      if (dx * dx + dy * dy < 0.36) return;
    }

    trail.push({
      x,
      y,
      age: 0,
      phase: Math.random() * TAU
    });

    if (trail.length > MAX_TRAIL) trail.shift();
  }

  function spawnParticle(x, y, power = 1) {
    if (particles.length >= MAX_PARTICLES) particles.splice(0, 10);
    const a = Math.random() * TAU;
    const speed = (0.45 + Math.random() * 2.8) * power;
    particles.push({
      x,
      y,
      vx: Math.cos(a) * speed,
      vy: Math.sin(a) * speed,
      life: .45 + Math.random() * .7,
      size: .45 + Math.random() * 2.2,
      alpha: .35 + Math.random() * .65
    });
  }

  function impactAt(x, y, nx, ny) {
    impacts.push({
      x,
      y,
      nx,
      ny,
      radius: ball.r * .6,
      life: 1
    });

    const base = Math.atan2(ny, nx);
    for (let i = 0; i < 34; i++) {
      const spread = (Math.random() - .5) * Math.PI * .75;
      const angle = base + Math.PI + spread;
      const power = .8 + Math.random() * 2.4;
      particles.push({
        x,
        y,
        vx: Math.cos(angle) * power,
        vy: Math.sin(angle) * power,
        life: .45 + Math.random() * .7,
        size: .6 + Math.random() * 2.3,
        alpha: .45 + Math.random() * .55
      });
    }
  }

  function doBounce(nx, ny) {
    bounceCount += 1;
    const nextStage = Math.min(9, 1 + Math.floor(bounceCount / 10));
    if (nextStage > stage) {
      stage = nextStage;
      growthTier = Math.max(growthTier, stage);
      evolutionFlash = 1;
      for (let i = 0; i < 18; i++) spawnParticle(ball.x, ball.y, 1.15);
    }
    pulse = 1;

    const dot = ball.vx * nx + ball.vy * ny;
    ball.vx -= 2 * dot * nx;
    ball.vy -= 2 * dot * ny;

    const tangent = (Math.random() - .5) * .18;
    ball.vx += -ny * tangent;
    ball.vy += nx * tangent;

    const targetSpeed = clamp(2.64 + bounceCount * .033, 2.66, 4.35);
    const speed = Math.hypot(ball.vx, ball.vy) || 1;
    ball.vx = ball.vx / speed * targetSpeed;
    ball.vy = ball.vy / speed * targetSpeed;

    // Bounce growth provides a subtle secondary lift on top of the time-based evolution.
    const bounceGrowth = Math.min(4.2, bounceCount * 0.055);
    const stageGrowth = Math.min(4.8, (stage - 1) * 0.55);
    ball.growthKick = bounceGrowth + stageGrowth;
    impactAt(ball.x, ball.y, nx, ny);
    updateHud();
  }

  function update(dt) {
    const frame = clamp(dt / 16.6667, .2, 2.5);
    elapsed += dt;

    // Smooth, cinematic growth curve: tiny for the opening seconds,
    // then increasingly visible, reaching the late-game size gradually.
    const timeProgress = clamp(elapsed / GROWTH_DURATION, 0, 1);
    const easedGrowth = timeProgress * timeProgress * (3 - 2 * timeProgress);
    const timeRadius = MIN_BALL_RADIUS + (MAX_BALL_RADIUS - MIN_BALL_RADIUS) * easedGrowth;
    const bounceRadius = Math.min(5.5, ball.growthKick || 0);
    const targetRadius = Math.min(MAX_BALL_RADIUS, timeRadius + bounceRadius);
    ball.r += (targetRadius - ball.r) * (1 - Math.pow(0.84, frame));
    ball.growthKick *= Math.pow(0.987, frame);

    evolutionFlash *= Math.pow(.91, frame);
    pulse *= Math.pow(.91, frame);
    boost *= Math.pow(.88, frame);

    ball.x += ball.vx * frame + boost * ball.vx * .009;
    ball.y += ball.vy * frame + boost * ball.vy * .009;
    ball.vx *= Math.pow(.99965, frame);
    ball.vy *= Math.pow(.99965, frame);
    ball.spin += .018 * frame;

    const dx = ball.x - cx;
    const dy = ball.y - cy;
    const dist = Math.hypot(dx, dy) || 1;
    const limit = arenaR - ball.r - 1.5;

    if (dist >= limit) {
      const nx = dx / dist;
      const ny = dy / dist;
      ball.x = cx + nx * limit;
      ball.y = cy + ny * limit;
      doBounce(nx, ny);
    }

    addTrail(ball.x, ball.y);
    for (const p of trail) p.age += frame;

    for (let i = particles.length - 1; i >= 0; i--) {
      const p = particles[i];
      p.x += p.vx * frame;
      p.y += p.vy * frame;
      p.vx *= Math.pow(.955, frame);
      p.vy *= Math.pow(.955, frame);
      p.life -= .026 * frame;
      if (p.life <= 0) particles.splice(i, 1);
    }

    for (let i = impacts.length - 1; i >= 0; i--) {
      const p = impacts[i];
      p.radius += 2.8 * frame;
      p.life -= .035 * frame;
      if (p.life <= 0) impacts.splice(i, 1);
    }

    for (let i = sparkles.length - 1; i >= 0; i--) {
      const s = sparkles[i];
      s.life -= .025 * frame;
      s.phase += .04 * frame;
      if (s.life <= 0) sparkles.splice(i, 1);
    }

    // Very subtle camera breathing; the gameplay space itself remains stable.
    camera.swayX = Math.sin(elapsed * .00029) * .8;
    camera.swayY = Math.cos(elapsed * .00024) * .55;
    camera.roll = Math.sin(elapsed * .00021) * .00045;

    if (Math.random() < .03 * frame && trail.length > 50) {
      const p = trail[trail.length - 1 - Math.floor(Math.random() * 40)];
      sparkles.push({ x: p.x, y: p.y, life: 1, phase: Math.random() * TAU });
      if (sparkles.length > 80) sparkles.shift();
    }
  }

  function clear(context) {
    context.clearRect(0, 0, W, H);
  }

  function drawBackground() {
    ctx.fillStyle = "#000";
    ctx.fillRect(0, 0, W, H);

    // Sparse dust gives the black field depth while staying almost invisible.
    ctx.save();
    ctx.globalAlpha = .22;
    for (let i = 0; i < 44; i++) {
      const a = (i * 1.61803398875 + elapsed * .000025) % 1;
      const x = (Math.sin(i * 12.9898) * .5 + .5) * W;
      const y = (Math.sin(i * 78.233) * .5 + .5) * H;
      const r = .35 + ((i * 7) % 11) / 24;
      ctx.beginPath();
      ctx.arc(x, y, r, 0, TAU);
      ctx.fillStyle = i % 5 === 0 ? `rgba(120,248,255,${.08 + a * .06})` : `rgba(255,255,255,${.025 + a * .025})`;
      ctx.fill();
    }
    ctx.restore();

    const g = ctx.createRadialGradient(cx, cy, 0, cx, cy, arenaR * 1.45);
    g.addColorStop(0, "rgba(0,244,255,.028)");
    g.addColorStop(.42, "rgba(0,124,255,.014)");
    g.addColorStop(1, "rgba(0,0,0,0)");
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, W, H);

    // Subtle center haze, never affecting gameplay readability.
    ctx.save();
    ctx.translate(camera.swayX, camera.swayY);
    const haze = ctx.createRadialGradient(cx, cy, arenaR * .05, cx, cy, arenaR * .78);
    haze.addColorStop(0, "rgba(255,255,255,.008)");
    haze.addColorStop(1, "rgba(255,255,255,0)");
    ctx.fillStyle = haze;
    ctx.fillRect(cx - arenaR, cy - arenaR, arenaR * 2, arenaR * 2);
    ctx.restore();
  }

  function drawArena() {
    const x = cx + camera.swayX;
    const y = cy + camera.swayY;

    fxCtx.save();
    fxCtx.globalCompositeOperation = "screen";
    fxCtx.shadowColor = "rgba(99,249,255,.9)";
    fxCtx.shadowBlur = 18 + pulse * 10;
    fxCtx.beginPath();
    fxCtx.arc(x, y, arenaR, 0, TAU);
    fxCtx.strokeStyle = "rgba(61,235,255,.18)";
    fxCtx.lineWidth = 2.2;
    fxCtx.stroke();
    fxCtx.restore();

    ctx.save();
    ctx.beginPath();
    ctx.arc(x, y, arenaR, 0, TAU);
    ctx.strokeStyle = "rgba(255,255,255,.93)";
    ctx.lineWidth = 1.35;
    ctx.shadowColor = "rgba(255,255,255,.2)";
    ctx.shadowBlur = 3;
    ctx.stroke();
    ctx.restore();
  }

  function smoothPath(context, points) {
    if (points.length < 2) return;
    context.beginPath();
    context.moveTo(points[0].x, points[0].y);
    for (let i = 1; i < points.length; i++) {
      const p0 = points[i - 1];
      const p1 = points[i];
      const mx = (p0.x + p1.x) * .5;
      const my = (p0.y + p1.y) * .5;
      context.quadraticCurveTo(p0.x, p0.y, mx, my);
    }
    const last = points[points.length - 1];
    context.lineTo(last.x, last.y);
  }

  function drawTrail() {
    if (trail.length < 2) return;

    const start = Math.max(0, trail.length - 1500);
    const pts = trail.slice(start);
    const width = 22 + ball.r * 0.92 + clamp(bounceCount * .045, 0, 4.5);

    // Everything is clipped to the arena, exactly like the reference composition.
    ctx.save();
    ctx.beginPath();
    ctx.arc(cx + camera.swayX, cy + camera.swayY, arenaR - .5, 0, TAU);
    ctx.clip();

    // Small stage flashes add a premium "evolution" moment without interrupting gameplay.
    if (evolutionFlash > 0.002) {
      fxCtx.save();
      fxCtx.globalCompositeOperation = "screen";
      fxCtx.fillStyle = `rgba(205,255,255,${evolutionFlash * .055})`;
      fxCtx.fillRect(cx - arenaR, cy - arenaR, arenaR * 2, arenaR * 2);
      fxCtx.restore();
    }

    // Soft outer aura.
    fxCtx.save();
    fxCtx.globalCompositeOperation = "lighter";
    smoothPath(fxCtx, pts);
    fxCtx.strokeStyle = "rgba(55,226,255,.16)";
    fxCtx.lineWidth = width + 15;
    fxCtx.lineCap = "round";
    fxCtx.lineJoin = "round";
    fxCtx.shadowColor = "rgba(23,235,255,.9)";
    fxCtx.shadowBlur = 16;
    fxCtx.stroke();
    fxCtx.restore();

    // Bright white outer tube.
    smoothPath(ctx, pts);
    ctx.strokeStyle = "rgba(252,255,255,.96)";
    ctx.lineWidth = width;
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    ctx.stroke();

    // Cold blue interior.
    smoothPath(ctx, pts);
    ctx.strokeStyle = "rgba(137,187,245,.92)";
    ctx.lineWidth = Math.max(7, width - 5.4);
    ctx.stroke();

    // Soft pearl center.
    smoothPath(ctx, pts);
    const inner = ctx.createLinearGradient(0, cy - arenaR, 0, cy + arenaR);
    inner.addColorStop(0, "rgba(255,255,255,.96)");
    inner.addColorStop(.46, "rgba(230,247,255,.5)");
    inner.addColorStop(1, "rgba(255,255,255,.91)");
    ctx.strokeStyle = inner;
    ctx.lineWidth = Math.max(2.8, width * .28);
    ctx.stroke();

    // High-frequency ribs for the production tubular look.
    ctx.save();
    ctx.globalAlpha = .64;
    const ribStart = Math.max(1, start + 5);
    const ribGap = 4;
    for (let i = ribStart; i < trail.length - 1; i += ribGap) {
      const p = trail[i];
      const a = trail[i - 1];
      const b = trail[i + 1];
      const tx = b.x - a.x;
      const ty = b.y - a.y;
      const len = Math.hypot(tx, ty) || 1;
      const nx = -ty / len;
      const ny = tx / len;
      const localWidth = Math.max(7.2, width * .39) + clamp(bounceCount * .028, 0, 2.2);
      const wobble = Math.sin(elapsed * .0018 + i * .06 + p.phase) * .55;
      const l = localWidth + wobble;
      ctx.beginPath();
      ctx.moveTo(p.x - nx * l, p.y - ny * l);
      ctx.lineTo(p.x + nx * l, p.y + ny * l);
      ctx.strokeStyle = i > trail.length - 120 ? "rgba(255,255,255,.82)" : "rgba(246,250,255,.56)";
      ctx.lineWidth = .95;
      ctx.stroke();
    }
    ctx.restore();

    // Live seam that follows the ball.
    const recent = trail.slice(Math.max(0, trail.length - 170));
    smoothPath(ctx, recent);
    ctx.strokeStyle = "rgba(255,255,255,.85)";
    ctx.lineWidth = 1.15;
    ctx.stroke();

    ctx.restore();
  }

  function drawImpacts() {
    if (!impacts.length) return;
    fxCtx.save();
    fxCtx.globalCompositeOperation = "lighter";
    for (const i of impacts) {
      fxCtx.beginPath();
      fxCtx.arc(i.x, i.y, i.radius, 0, TAU);
      fxCtx.strokeStyle = `rgba(113,250,255,${i.life * .26})`;
      fxCtx.lineWidth = 1.15;
      fxCtx.stroke();
    }
    fxCtx.restore();
  }

  function drawParticles() {
    fxCtx.save();
    fxCtx.globalCompositeOperation = "lighter";
    for (const p of particles) {
      fxCtx.beginPath();
      fxCtx.arc(p.x, p.y, p.size * (0.7 + p.life), 0, TAU);
      fxCtx.fillStyle = `rgba(117,244,255,${p.life * p.alpha})`;
      fxCtx.shadowColor = "rgba(0,235,255,.85)";
      fxCtx.shadowBlur = 8;
      fxCtx.fill();
    }
    for (const s of sparkles) {
      const a = .35 + .35 * Math.sin(s.phase);
      fxCtx.beginPath();
      fxCtx.arc(s.x, s.y, 1.15, 0, TAU);
      fxCtx.fillStyle = `rgba(255,255,255,${s.life * a})`;
      fxCtx.fill();
    }
    fxCtx.restore();
  }

  function drawBall() {
    const r = ball.r * (1 + pulse * .05);
    const maturity = clamp((ball.r - MIN_BALL_RADIUS) / (MAX_BALL_RADIUS - MIN_BALL_RADIUS), 0, 1);

    fxCtx.save();
    fxCtx.globalCompositeOperation = "lighter";
    const aura = fxCtx.createRadialGradient(ball.x, ball.y, 0, ball.x, ball.y, r * (5.4 + maturity * 1.5));
    aura.addColorStop(0, "rgba(97,255,255,.58)");
    aura.addColorStop(.26, "rgba(21,226,255,.22)");
    aura.addColorStop(1, "rgba(0,145,255,0)");
    fxCtx.fillStyle = aura;
    fxCtx.beginPath();
    fxCtx.arc(ball.x, ball.y, r * (5.4 + maturity * 1.5), 0, TAU);
    fxCtx.fill();
    fxCtx.restore();

    ctx.save();
    ctx.shadowColor = "rgba(0,238,255,.92)";
    ctx.shadowBlur = 13 + pulse * 10 + maturity * 9;

    const sphere = ctx.createRadialGradient(
      ball.x - r * .34,
      ball.y - r * .36,
      r * .03,
      ball.x,
      ball.y,
      r * 1.02
    );
    sphere.addColorStop(0, "#ffffff");
    sphere.addColorStop(.10, "#d8ffff");
    sphere.addColorStop(.28, "#39fbff");
    sphere.addColorStop(.52, "#00b8c1");
    sphere.addColorStop(.76, "#006d77");
    sphere.addColorStop(1, "#00181a");
    ctx.fillStyle = sphere;
    ctx.beginPath();
    ctx.arc(ball.x, ball.y, r, 0, TAU);
    ctx.fill();

    // Secondary reflection band rotates with the ball.
    ctx.save();
    ctx.translate(ball.x, ball.y);
    ctx.rotate(ball.spin);
    const band = ctx.createLinearGradient(-r, -r, r, r);
    band.addColorStop(0, "rgba(255,255,255,0)");
    band.addColorStop(.47, "rgba(255,255,255,.03)");
    band.addColorStop(.55, "rgba(255,255,255,.42)");
    band.addColorStop(.61, "rgba(255,255,255,.02)");
    band.addColorStop(1, "rgba(255,255,255,0)");
    ctx.fillStyle = band;
    ctx.beginPath();
    ctx.arc(0, 0, r, 0, TAU);
    ctx.fill();
    ctx.restore();

    // Specular spot.
    const spec = ctx.createRadialGradient(
      ball.x - r * .34,
      ball.y - r * .36,
      0,
      ball.x - r * .34,
      ball.y - r * .36,
      r * .56
    );
    spec.addColorStop(0, "rgba(255,255,255,.98)");
    spec.addColorStop(.30, "rgba(255,255,255,.34)");
    spec.addColorStop(1, "rgba(255,255,255,0)");
    ctx.fillStyle = spec;
    ctx.beginPath();
    ctx.arc(ball.x, ball.y, r, 0, TAU);
    ctx.fill();

    // Crisp outer rim.
    ctx.beginPath();
    ctx.arc(ball.x, ball.y, r - .55, 0, TAU);
    ctx.strokeStyle = "rgba(178,255,255,.66)";
    ctx.lineWidth = .8;
    ctx.stroke();

    // Thin refractive rim becomes more pronounced as the ball evolves.
    ctx.beginPath();
    ctx.arc(ball.x - r * .05, ball.y - r * .03, r * .86, -2.2, -.18);
    ctx.strokeStyle = `rgba(232,255,255,${.16 + maturity * .34})`;
    ctx.lineWidth = Math.max(.65, r * .045);
    ctx.stroke();

    ctx.restore();
  }

  function draw() {
    clear(ctx);
    clear(fxCtx);
    drawBackground();
    drawArena();
    drawTrail();
    drawImpacts();
    drawParticles();
    drawBall();
    drawUiFrame();
  }

  function drawUiFrame() {
    clear(uiCtx);
    const g = uiCtx.createRadialGradient(cx, cy, arenaR * .36, cx, cy, Math.max(W, H) * .76);
    g.addColorStop(0, "rgba(0,0,0,0)");
    g.addColorStop(.6, "rgba(0,0,0,.015)");
    g.addColorStop(.85, "rgba(0,0,0,.18)");
    g.addColorStop(1, "rgba(0,0,0,.66)");
    uiCtx.fillStyle = g;
    uiCtx.fillRect(0, 0, W, H);

    // Cinematic evolution meter.
    const progress = clamp(elapsed / GROWTH_DURATION, 0, 1);
    const meterW = Math.min(120, W * .28);
    const meterX = (W - meterW) * .5;
    const meterY = H * .081;
    uiCtx.fillStyle = "rgba(255,255,255,.08)";
    uiCtx.fillRect(meterX, meterY, meterW, 1.5);
    uiCtx.fillStyle = `rgba(108,248,255,${.45 + progress * .35})`;
    uiCtx.fillRect(meterX, meterY, meterW * progress, 1.5);

    if (evolutionFlash > .02) {
      const a = evolutionFlash * .16;
      uiCtx.fillStyle = `rgba(170,255,255,${a})`;
      uiCtx.fillRect(0, 0, W, H);
    }
  }

  function togglePause(next = !paused) {
    if (!started) return;
    paused = next;
    pauseOverlay.hidden = !paused;
    pauseButton.textContent = paused ? "▶" : "Ⅱ";
    pauseButton.setAttribute("aria-label", paused ? "Resume game" : "Pause game");

    // Do not reset or alter any world state. Only the simulation clock stops.
    if (!paused) previous = performance.now();
  }

  function boostBall() {
    if (!started || paused) return;
    const speed = Math.hypot(ball.vx, ball.vy) || 1;
    ball.vx += (ball.vx / speed) * .62;
    ball.vy += (ball.vy / speed) * .62;
    boost = 4.5;
    for (let i = 0; i < 10; i++) spawnParticle(ball.x, ball.y, .75);
  }

  function loop(now) {
    const dt = Math.min(40, Math.max(0, now - previous));
    previous = now;

    if (!paused) update(dt);
    draw();
    requestAnimationFrame(loop);
  }

  pauseButton.addEventListener("click", (event) => {
    event.stopPropagation();
    togglePause();
  });

  resumeButton.addEventListener("click", () => togglePause(false));

  resetButton.addEventListener("click", (event) => {
    event.stopPropagation();
    reset();
  });

  game.addEventListener("pointerdown", (event) => {
    if (event.target === pauseButton || event.target === resetButton || event.target === resumeButton) return;
    if (paused) {
      togglePause(false);
      return;
    }
    boostBall();
  }, { passive: true });

  window.addEventListener("keydown", (event) => {
    if (event.code === "Space") {
      event.preventDefault();
      togglePause();
      return;
    }
    if (event.key.toLowerCase() === "r") reset();
  });

  window.addEventListener("resize", resize, { passive: true });
  document.addEventListener("visibilitychange", () => {
    if (document.hidden && !paused) togglePause(true);
  });

  resize();
  previous = performance.now();
  requestAnimationFrame(loop);
})();
