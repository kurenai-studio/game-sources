import {
  FIELD_HEIGHT,
  FIELD_WIDTH,
  applySling,
  createDailyField,
  formatShareResult,
  gradeFor,
  initialRunState,
  normalizeDateKey,
  plannedTargets,
  projectedEndpoint,
  shanghaiDateKey,
  simulatePlan,
  startRun
} from "./core.js";

const params = new URL(window.location.href).searchParams;
const initialDate = normalizeDateKey(params.get("date") || shanghaiDateKey(new Date()));

const elements = {
  canvas: document.querySelector("#field"),
  dateChip: document.querySelector("#date-chip"),
  dateInput: document.querySelector("#challenge-date"),
  loadDateButton: document.querySelector("#load-date-button"),
  startButton: document.querySelector("#start-button"),
  retryButton: document.querySelector("#retry-button"),
  status: document.querySelector("#status-line"),
  scoreValue: document.querySelector("#score-value"),
  starCount: document.querySelector("#star-count"),
  shotCount: document.querySelector("#shot-count"),
  bestScore: document.querySelector("#best-score"),
  heatMeter: document.querySelector("#heat-meter"),
  gradeValue: document.querySelector("#grade-value"),
  resultPanel: document.querySelector("#result-panel"),
  resultTitle: document.querySelector("#result-title"),
  resultMeta: document.querySelector("#result-meta"),
  copyButton: document.querySelector("#copy-button"),
  copyLinkButton: document.querySelector("#copy-link-button")
};

const ctx = elements.canvas.getContext("2d");
let field = createDailyField(initialDate);
let run = initialRunState(field);
let drag = null;
let animation = null;
let shareText = "";

loadField(field.dateKey, { updateUrl: true });
wireEvents();
resizeCanvas();
window.addEventListener("resize", resizeCanvas);

function wireEvents() {
  elements.startButton.addEventListener("click", () => {
    run = startRun(field);
    shareText = "";
    render();
  });

  elements.retryButton.addEventListener("click", () => {
    stopAnimation();
    run = startRun(field);
    drag = null;
    shareText = "";
    render();
  });

  elements.loadDateButton.addEventListener("click", () => {
    loadField(elements.dateInput.value || shanghaiDateKey(new Date()), { updateUrl: true });
  });

  elements.dateInput.addEventListener("change", () => {
    loadField(elements.dateInput.value || shanghaiDateKey(new Date()), { updateUrl: true });
  });

  elements.copyButton.addEventListener("click", () => {
    copyText(shareText || buildShareText(), elements.copyButton, "Copied");
  });

  elements.copyLinkButton.addEventListener("click", () => {
    copyText(getChallengeLink(), elements.copyLinkButton, "Link copied");
  });

  elements.canvas.addEventListener("pointerdown", (event) => {
    if (!run.active || run.done || animation) return;
    elements.canvas.setPointerCapture(event.pointerId);
    const pointer = canvasPoint(event);
    drag = {
      id: event.pointerId,
      current: pointer
    };
    render();
  });

  elements.canvas.addEventListener("pointermove", (event) => {
    if (!drag || drag.id !== event.pointerId) return;
    drag.current = canvasPoint(event);
    render();
  });

  elements.canvas.addEventListener("pointerup", (event) => {
    if (!drag || drag.id !== event.pointerId) return;
    const pointer = canvasPoint(event);
    const vector = {
      x: pointer.x - run.position.x,
      y: pointer.y - run.position.y
    };
    drag = null;
    fireVector(vector, { animate: true });
  });

  elements.canvas.addEventListener("pointercancel", () => {
    drag = null;
    render();
  });
}

function loadField(dateKey, { updateUrl } = { updateUrl: false }) {
  stopAnimation();
  field = createDailyField(dateKey);
  run = initialRunState(field);
  drag = null;
  shareText = "";
  elements.dateInput.value = field.dateKey;
  if (updateUrl) {
    const nextUrl = new URL(window.location.href);
    nextUrl.searchParams.set("date", field.dateKey);
    window.history.replaceState({}, "", nextUrl);
  }
  render();
}

function fireVector(vector, { animate } = { animate: true }) {
  if (!run.active || run.done) return run;
  const nextRun = applySling(field, run, vector);
  const shot = nextRun.shots[nextRun.shots.length - 1];
  if (!shot || nextRun === run) {
    run = nextRun;
    render();
    return run;
  }

  run = nextRun;
  if (run.done) finishRound();

  if (!animate) {
    render();
    return run;
  }

  animation = {
    shot,
    startedAt: performance.now(),
    duration: 420
  };
  requestAnimationFrame(tickAnimation);
  return run;
}

function finishRound() {
  const grade = gradeFor(run.score, field.possibleScore);
  shareText = buildShareText(grade);
  saveBest(run.score);
}

function tickAnimation(now) {
  if (!animation) return;
  const progress = Math.min(1, (now - animation.startedAt) / animation.duration);
  render(progress);
  if (progress < 1) {
    requestAnimationFrame(tickAnimation);
  } else {
    animation = null;
    render();
  }
}

function stopAnimation() {
  animation = null;
}

function render(animationProgress = 1) {
  renderStats();
  renderResult();
  drawField(animationProgress);
}

function renderStats() {
  const collectedCount = run.collected.size;
  const grade = run.score > 0 ? gradeFor(run.score, field.possibleScore) : "-";
  elements.dateChip.textContent = field.dateKey;
  elements.scoreValue.textContent = `${run.score}`;
  elements.starCount.textContent = `${collectedCount}/${field.stars.length}`;
  elements.shotCount.textContent = `${run.shots.length}/${field.shotLimit}`;
  elements.bestScore.textContent = `${getBest()}`;
  elements.heatMeter.value = `${run.heat}`;
  elements.gradeValue.textContent = grade;
  elements.status.textContent = run.message;
  elements.startButton.disabled = run.active || Boolean(animation);
  elements.retryButton.disabled = Boolean(animation);
}

function renderResult() {
  if (!run.done) {
    elements.resultPanel.hidden = true;
    elements.copyButton.disabled = true;
    return;
  }

  const grade = gradeFor(run.score, field.possibleScore);
  const collectedCount = run.collected.size;
  elements.resultPanel.hidden = false;
  elements.copyButton.disabled = false;
  elements.resultTitle.textContent = run.docked ? "Docked" : "Round ended";
  elements.resultMeta.textContent =
    `${grade} grade, ${run.score}/${field.possibleScore} pts, ` +
    `${collectedCount}/${field.stars.length} stars, ${run.shots.length} shots.`;
}

function drawField(animationProgress = 1) {
  const dpr = window.devicePixelRatio || 1;
  ctx.save();
  ctx.scale(dpr, dpr);
  ctx.clearRect(0, 0, FIELD_WIDTH, FIELD_HEIGHT);
  drawBackground();
  drawSolutionThread();
  drawHazards();
  drawStars();
  drawDock();
  drawShotTrails();
  drawDragGuide();
  drawCore(animationProgress);
  ctx.restore();
}

function drawBackground() {
  ctx.fillStyle = "#111112";
  ctx.fillRect(0, 0, FIELD_WIDTH, FIELD_HEIGHT);
  ctx.strokeStyle = "rgba(245, 240, 223, 0.08)";
  ctx.lineWidth = 1;
  for (let x = 80; x < FIELD_WIDTH; x += 80) {
    ctx.beginPath();
    ctx.moveTo(x, 34);
    ctx.lineTo(x, FIELD_HEIGHT - 34);
    ctx.stroke();
  }
  for (let y = 80; y < FIELD_HEIGHT; y += 80) {
    ctx.beginPath();
    ctx.moveTo(34, y);
    ctx.lineTo(FIELD_WIDTH - 34, y);
    ctx.stroke();
  }

  ctx.strokeStyle = "rgba(255, 207, 90, 0.55)";
  ctx.lineWidth = 3;
  ctx.strokeRect(46, 46, FIELD_WIDTH - 92, FIELD_HEIGHT - 92);
}

function drawSolutionThread() {
  const points = [field.launcher, ...field.stars, field.dock];
  ctx.beginPath();
  points.forEach((point, index) => {
    if (index === 0) ctx.moveTo(point.x, point.y);
    else ctx.lineTo(point.x, point.y);
  });
  ctx.strokeStyle = "rgba(25, 194, 160, 0.22)";
  ctx.lineWidth = 4;
  ctx.setLineDash([8, 14]);
  ctx.stroke();
  ctx.setLineDash([]);
}

function drawHazards() {
  for (const hazard of field.hazards) {
    ctx.beginPath();
    ctx.arc(hazard.x, hazard.y, hazard.radius, 0, Math.PI * 2);
    ctx.fillStyle = "rgba(255, 107, 95, 0.24)";
    ctx.fill();
    ctx.strokeStyle = "#ff6b5f";
    ctx.lineWidth = 3;
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(hazard.x - hazard.radius * 0.55, hazard.y - hazard.radius * 0.55);
    ctx.lineTo(hazard.x + hazard.radius * 0.55, hazard.y + hazard.radius * 0.55);
    ctx.moveTo(hazard.x + hazard.radius * 0.55, hazard.y - hazard.radius * 0.55);
    ctx.lineTo(hazard.x - hazard.radius * 0.55, hazard.y + hazard.radius * 0.55);
    ctx.strokeStyle = "rgba(255, 245, 230, 0.6)";
    ctx.lineWidth = 2;
    ctx.stroke();
  }
}

function drawStars() {
  for (const star of field.stars) {
    const collected = run.collected.has(star.id);
    ctx.save();
    ctx.globalAlpha = collected ? 0.36 : 1;
    drawStarShape(star.x, star.y, star.radius + 8, star.radius * 0.55);
    ctx.fillStyle = collected ? "#7d8185" : "#ffcf5a";
    ctx.fill();
    ctx.strokeStyle = collected ? "rgba(245, 240, 223, 0.25)" : "#fff0a5";
    ctx.lineWidth = 3;
    ctx.stroke();
    ctx.restore();
  }
}

function drawDock() {
  ctx.beginPath();
  ctx.arc(field.dock.x, field.dock.y, field.dock.radius + 10, 0, Math.PI * 2);
  ctx.strokeStyle = run.collected.size === field.stars.length ? "#19c2a0" : "rgba(245, 240, 223, 0.35)";
  ctx.lineWidth = 5;
  ctx.stroke();

  ctx.beginPath();
  ctx.arc(field.dock.x, field.dock.y, field.dock.radius - 4, 0, Math.PI * 2);
  ctx.fillStyle = "rgba(25, 194, 160, 0.16)";
  ctx.fill();
}

function drawShotTrails() {
  for (const shot of run.shots) {
    ctx.beginPath();
    ctx.moveTo(shot.start.x, shot.start.y);
    ctx.lineTo(shot.end.x, shot.end.y);
    ctx.strokeStyle = shot.hazardHits.length > 0 ? "rgba(255, 107, 95, 0.72)" : "rgba(245, 240, 223, 0.55)";
    ctx.lineWidth = 3;
    ctx.stroke();
  }
}

function drawDragGuide() {
  if (!drag || !run.active) return;
  const end = projectedEndpoint(run.position, {
    x: drag.current.x - run.position.x,
    y: drag.current.y - run.position.y
  });

  ctx.beginPath();
  ctx.moveTo(run.position.x, run.position.y);
  ctx.lineTo(end.x, end.y);
  ctx.strokeStyle = "#19c2a0";
  ctx.lineWidth = 5;
  ctx.stroke();

  ctx.beginPath();
  ctx.arc(end.x, end.y, 13, 0, Math.PI * 2);
  ctx.fillStyle = "#19c2a0";
  ctx.fill();
}

function drawCore(animationProgress) {
  let position = run.position;
  if (animation) {
    const eased = 1 - Math.pow(1 - animationProgress, 3);
    const shot = animation.shot;
    position = {
      x: shot.start.x + (shot.end.x - shot.start.x) * eased,
      y: shot.start.y + (shot.end.y - shot.start.y) * eased
    };
  }

  ctx.beginPath();
  ctx.arc(position.x, position.y, 20, 0, Math.PI * 2);
  ctx.fillStyle = run.done && !run.docked ? "#f5f0df" : "#19c2a0";
  ctx.fill();
  ctx.strokeStyle = "#f5f0df";
  ctx.lineWidth = 4;
  ctx.stroke();

  ctx.beginPath();
  ctx.arc(position.x - 5, position.y - 6, 5, 0, Math.PI * 2);
  ctx.fillStyle = "rgba(255, 255, 255, 0.65)";
  ctx.fill();
}

function drawStarShape(x, y, outer, inner) {
  ctx.beginPath();
  for (let index = 0; index < 10; index += 1) {
    const angle = -Math.PI / 2 + (index * Math.PI) / 5;
    const radius = index % 2 === 0 ? outer : inner;
    const px = x + Math.cos(angle) * radius;
    const py = y + Math.sin(angle) * radius;
    if (index === 0) ctx.moveTo(px, py);
    else ctx.lineTo(px, py);
  }
  ctx.closePath();
}

function resizeCanvas() {
  const dpr = window.devicePixelRatio || 1;
  elements.canvas.width = FIELD_WIDTH * dpr;
  elements.canvas.height = FIELD_HEIGHT * dpr;
  elements.canvas.style.aspectRatio = `${FIELD_WIDTH} / ${FIELD_HEIGHT}`;
  render();
}

function canvasPoint(event) {
  const rect = elements.canvas.getBoundingClientRect();
  return {
    x: ((event.clientX - rect.left) / rect.width) * FIELD_WIDTH,
    y: ((event.clientY - rect.top) / rect.height) * FIELD_HEIGHT
  };
}

function buildShareText(grade = gradeFor(run.score, field.possibleScore)) {
  return formatShareResult({
    dateKey: field.dateKey,
    score: run.score,
    possibleScore: field.possibleScore,
    grade,
    docked: run.docked,
    collectedCount: run.collected.size,
    totalStars: field.stars.length,
    shotsUsed: run.shots.length
  });
}

function getChallengeLink() {
  const url = new URL(window.location.href);
  url.searchParams.set("date", field.dateKey);
  return url.href;
}

async function copyText(text, button, label) {
  try {
    await navigator.clipboard.writeText(text);
  } catch {
    const area = document.createElement("textarea");
    area.value = text;
    document.body.append(area);
    area.select();
    document.execCommand("copy");
    area.remove();
  }
  const previous = button.textContent;
  button.textContent = label;
  window.setTimeout(() => {
    button.textContent = previous;
  }, 1100);
}

function bestKey() {
  return `star-sling:${field.dateKey}:best`;
}

function getBest() {
  return Number(window.localStorage.getItem(bestKey()) || 0);
}

function saveBest(score) {
  if (score > getBest()) {
    window.localStorage.setItem(bestKey(), `${score}`);
  }
}

function serializableState() {
  return {
    field: {
      dateKey: field.dateKey,
      name: field.name,
      stars: field.stars,
      hazards: field.hazards,
      possibleScore: field.possibleScore,
      par: field.par
    },
    run: {
      active: run.active,
      done: run.done,
      docked: run.docked,
      position: run.position,
      score: run.score,
      heat: run.heat,
      shots: run.shots,
      collectedCount: run.collected.size,
      collected: Array.from(run.collected),
      message: run.message
    },
    shareText: shareText || buildShareText(),
    resultOpen: !elements.resultPanel.hidden,
    challengeLink: getChallengeLink()
  };
}

window.StarSling = {
  getState: serializableState,
  start() {
    run = startRun(field);
    render();
    return serializableState();
  },
  slingTo(x, y) {
    if (!run.active) run = startRun(field);
    fireVector({ x: x - run.position.x, y: y - run.position.y }, { animate: false });
    return serializableState();
  },
  solveToday() {
    run = simulatePlan(field, plannedTargets(field));
    finishRound();
    render();
    return serializableState();
  },
  getShareText() {
    return shareText || buildShareText();
  },
  getChallengeLink
};
