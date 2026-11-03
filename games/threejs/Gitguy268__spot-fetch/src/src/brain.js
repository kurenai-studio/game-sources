// Spots hoofd: stats, commando's en gedrag. Puur rekenwerk zonder three-import, zodat Node het kan testen.
// Richting: heading 0 kijkt naar +z, vooruit = (sin h, 0, cos h).

export const COMMANDS = ['zit', 'blijf', 'bring', 'aus'];

const clamp = (x, a, b) => Math.min(b, Math.max(a, x));
const dist = (a, b) => Math.hypot(a.x - b.x, a.z - b.z);
const wrap = (a) => Math.atan2(Math.sin(a), Math.cos(a));

const REN = 7.5, DRAF = 2.8, LOOP = 1.2;
// Energie per seconde per activiteit.
const ENERGIE = { ren: -1.6, zwem: -2, draf: -0.5, loop: -0.15, sta: 0.6, zit: 1.2, lig: 3.5 };
const AFLEIDBAAR = new Set(['wacht', 'zit', 'blijf', 'achtervolg', 'breng', 'speel', 'houvast']);
const BEGRAVEN = new Set(['zand', 'sneeuw']);

export function newDog(cfg = {}, saved) {
  const d = {
    cfg,
    stats: { energie: 85, honger: 25, dorst: 25, vertrouwen: 40 }, // 0–100; honger en dorst: hoger is erger
    mastery: { zit: 0.15, blijf: 0.1, bring: 0.4, aus: 0.25 }, // beheersing 0–1
    pos: { x: 0.9, z: 8.4 }, heading: 0, speed: 0,
    state: 'wacht', t: 0, hasBall: false,
    done: null, doneT: 0, // laatst goed uitgevoerd commando en hoe lang geleden
    worp: 0, cool: 0, aaiCool: 0, zeur: 0,
    events: [], // voor de spellus: pak, val, los, blaf
    // Wat het model moet laten zien.
    pose: 'sta', look: null, headDown: 0, sniff: false, pant: 0, wag: 0.5, alert: 0, swim: false, act: 'sta',
  };
  if (saved) {
    for (const k in d.stats) if (Number.isFinite(saved.stats?.[k])) d.stats[k] = clamp(saved.stats[k], 0, 100);
    for (const k in d.mastery) if (Number.isFinite(saved.mastery?.[k])) d.mastery[k] = clamp(saved.mastery[k], 0, 1);
  }
  return d;
}

export const serialize = (d) => ({ stats: d.stats, mastery: d.mastery });

function bump(d, key, by) {
  d.stats[key] = clamp(d.stats[key] + by, 0, 100);
}

export function tickStats(d, dt, act) {
  const s = d.stats;
  const nood = s.honger > 80 || s.dorst > 80;
  const de = ENERGIE[act] ?? 0;
  bump(d, 'energie', (de > 0 && nood ? de * 0.5 : de) * dt);
  const druk = act === 'ren' || act === 'zwem';
  bump(d, 'honger', (druk ? 0.12 : 0.07) * dt);
  bump(d, 'dorst', (druk ? 0.35 : 0.1) * dt);
  if (nood) bump(d, 'vertrouwen', -0.1 * dt); // verwaarlozing
  const hijg = druk ? 1 : s.energie < 35 ? 0.6 : 0;
  d.pant += (hijg - d.pant) * Math.min(1, dt * (hijg > d.pant ? 0.6 : 0.2));
}

// Tijd dat de speler weg was: Spot krijgt honger en dorst en voelt zich verwaarloosd.
export function applyAway(d, seconds) {
  const h = clamp(seconds, 0, 8 * 3600) / 3600;
  bump(d, 'honger', 9 * h);
  bump(d, 'dorst', 11 * h);
  if (h > 0.5) bump(d, 'vertrouwen', -2 * h);
  if (h > 0.1) d.stats.energie = 100;
}

// Kans dat Spot een commando opvolgt. afleiding 0..1.
export function obeyChance(d, cmd, afleiding = 0) {
  const s = d.stats;
  let p = (0.3 + 0.7 * d.mastery[cmd]) * (0.7 + 0.3 * (s.vertrouwen / 100)) * (1 - 0.6 * afleiding);
  if (s.energie < 15) p *= 0.5;
  if (s.honger > 85 || s.dorst > 85) p *= 0.7;
  return clamp(p, 0, 1);
}

export function distractChance(d, sterkte) {
  const focus = 0.5 * (d.stats.vertrouwen / 100) + 0.25 * (d.mastery.blijf + d.mastery.bring);
  const bezig = d.state === 'achtervolg' || d.state === 'breng' ? 0.5 : 1;
  return clamp(sterkte * (1 - 0.75 * focus) * bezig, 0, 1);
}

// Beloning. Vlak na een goed uitgevoerd commando leert Spot ervan; geeft dan dat commando terug.
export function reward(d) {
  bump(d, 'honger', -1);
  if (d.done && d.doneT < 5) {
    const cmd = d.done;
    d.mastery[cmd] += 0.12 * (1 - d.mastery[cmd]);
    bump(d, 'vertrouwen', 2);
    d.done = null;
    return cmd;
  }
  bump(d, 'vertrouwen', 0.3);
  return null;
}

export function pet(d) {
  if (d.aaiCool > 0) return false;
  d.aaiCool = 4;
  bump(d, 'vertrouwen', 1.5);
  return true;
}

function go(d, state) {
  d.state = state;
  d.t = 0;
}

function brake(d, dt) {
  d.speed = Math.max(0, d.speed - 10 * dt);
  d.pos.x += Math.sin(d.heading) * d.speed * dt;
  d.pos.z += Math.cos(d.heading) * d.speed * dt;
}

function face(d, target, dt) {
  const diff = wrap(Math.atan2(target.x - d.pos.x, target.z - d.pos.z) - d.heading);
  d.heading += clamp(diff, -5 * dt, 5 * dt);
}

// Loop naar een punt; remt af bij aankomst en in scherpe bochten. Geeft de afstand terug.
function move(d, target, vmax, dt, ctx, stop = 0.15) {
  const dx = target.x - d.pos.x, dz = target.z - d.pos.z;
  const dd = Math.hypot(dx, dz);
  vmax = (d.swim ? Math.min(vmax, 1.3) : vmax) * (0.55 + 0.45 * (d.stats.energie / 100));
  let want = 0;
  if (dd > stop) {
    want = Math.min(vmax, Math.sqrt(12 * (dd - stop)) + 0.3);
    const diff = wrap(Math.atan2(dx, dz) - d.heading);
    const rate = 7 - 0.4 * d.speed;
    d.heading += clamp(diff, -rate * dt, rate * dt);
    want *= clamp(1.25 - Math.abs(diff) / 1.4, 0.2, 1);
  }
  d.speed += clamp(want - d.speed, -10 * dt, 7 * dt);
  d.pos.x += Math.sin(d.heading) * d.speed * dt;
  d.pos.z += Math.cos(d.heading) * d.speed * dt;
  for (const o of ctx.obstakels || []) { // om boomstammen heen
    const ox = d.pos.x - o.x, oz = d.pos.z - o.z, od = Math.hypot(ox, oz), min = o.r + 0.4;
    if (od < min && od > 1e-6) { d.pos.x = o.x + (ox / od) * min; d.pos.z = o.z + (oz / od) * min; }
  }
  const g = ctx.grenzen;
  if (g) {
    d.pos.x = clamp(d.pos.x, g.x0 + 0.5, g.x1 - 0.5);
    d.pos.z = clamp(d.pos.z, g.z0 + 0.5, g.z1 - 0.5);
  }
  return dd;
}

const NAAM = { eekhoorn: 'een eekhoorn', hond: 'een andere hond', geluid: 'een geluid' };

function startAfgeleid(d, e, ctx) {
  d.afl = { type: e.type, ref: e.pos, dur: e.type === 'geluid' ? 2.5 : 5 + 4 * ctx.rand() };
  if (d.hasBall && e.type !== 'geluid' && ctx.rand() < 0.5) {
    d.hasBall = false;
    d.events.push({ type: 'val' });
  }
  ctx.say(`${d.cfg.naam || 'Spot'} is afgeleid door ${NAAM[e.type] || 'iets'}`);
  go(d, 'afgeleid');
}

// Na het oppakken of terugroepen: brengt hij de bal, of gaat hij ermee spelen?
function naPak(d, ctx) {
  if (ctx.rand() < obeyChance(d, 'bring')) return go(d, 'breng');
  ctx.say('Spot gaat er met de bal vandoor — roep "bring"');
  d.speelT = 5 + 5 * ctx.rand();
  d.doel = null;
  go(d, 'speel');
}

const STATES = {
  wacht(d, dt, ctx) {
    const { ball, player, bowls } = ctx;
    const s = d.stats;
    d.pose = 'sta';
    d.wag = ball.mode === 'hand' ? 0.8 : 0.5;
    if (s.energie < 12) {
      ctx.say('Spot is moe en gaat liggen');
      return go(d, 'rust');
    }
    if (ball.mode === 'vrij' && d.t > 0.2) {
      d.worp = ctx.worp;
      return go(d, 'achtervolg');
    }
    if (ball.mode === 'hand') {
      if (bowls.water.vol > 0.05 ? s.dorst > 30 : s.dorst > 70) {
        d.doel = bowls.water.vol > 0.05 ? bowls.water : ctx.vijverRand;
        return go(d, 'drink');
      }
      if (bowls.voer.vol > 0.05 && s.honger > 30) return go(d, 'eet');
      d.zeur -= dt;
      if (s.honger > 70 && d.zeur <= 0) {
        d.zeur = 25;
        ctx.say('Spot heeft honger — vul zijn voerbak');
      }
    }
    const plek = { x: player.x + 0.9, z: player.z - 3.6 }; // ook op een smal telefoonscherm in beeld
    if (dist(d.pos, plek) > 1.2 || d.speed > 0.3) move(d, plek, DRAF, dt, ctx, 0.4);
    else { brake(d, dt); face(d, player, dt); }
  },

  zit(d, dt, ctx) {
    brake(d, dt);
    d.pose = 'zit';
    d.wag = 0.4;
    if (ctx.worp !== d.worp && ctx.ball.mode === 'vrij') {
      // "zit" is geen "blijf": een jonge apporteerhond schiet achter de bal aan.
      d.worp = ctx.worp;
      return go(d, 'achtervolg');
    }
    if (d.t > 8 + 40 * d.mastery.zit) go(d, 'wacht');
  },

  blijf(d, dt, ctx) {
    brake(d, dt);
    d.wag = 0.3;
    if (ctx.worp !== d.worp && ctx.ball.mode === 'vrij') {
      d.worp = ctx.worp;
      if (ctx.rand() < obeyChance(d, 'blijf')) {
        d.done = 'blijf'; d.doneT = 0;
        ctx.say('Spot blijft netjes wachten — beloon hem, of zeg "bring"');
      } else {
        ctx.say('Spot kan zich niet inhouden!');
        return go(d, 'achtervolg');
      }
    }
    if (d.t > 3 && !d.bleef) { d.bleef = true; d.done = 'blijf'; d.doneT = 0; }
    if (d.t > 15 + 60 * d.mastery.blijf) go(d, 'wacht');
  },

  achtervolg(d, dt, ctx) {
    const { ball } = ctx;
    if (ball.mode !== 'vrij') return go(d, 'wacht');
    if (d.stats.energie < 5) {
      ctx.say('Spot is uitgeput');
      return go(d, 'rust');
    }
    d.pose = 'sta';
    d.wag = 0.3;
    // In de lucht: naar de voorspelde landing. Daarna naar de bal zelf.
    const doel = ball.p.y > 1 && ctx.land ? ctx.land : ball.p;
    move(d, doel, REN, dt, ctx, 0.2);
    const dd = dist(d.pos, ball.p);
    if (ball.rust && !d.gevonden && dd < 3 && BEGRAVEN.has(ctx.surfaceAt(ball.p.x, ball.p.z))) {
      d.zoekT = 1.5 + 2.5 * ctx.rand();
      ctx.say('Spot zoekt de bal...');
      return go(d, 'zoek');
    }
    if (dd < 0.5 && ball.p.y < 0.8) go(d, 'pak');
  },

  // Snuffelend rondjes draaien tot de neus de bal vindt.
  zoek(d, dt, ctx) {
    const { ball } = ctx;
    if (ball.mode !== 'vrij') return go(d, 'wacht');
    d.sniff = true;
    d.headDown = 1;
    const r = 2 * (1 - d.t / d.zoekT), a = d.t * 2.2;
    move(d, { x: ball.p.x + r * Math.cos(a), z: ball.p.z + r * Math.sin(a) }, LOOP * 1.3, dt, ctx, 0.1);
    if (d.t > d.zoekT) {
      d.gevonden = true;
      go(d, 'achtervolg');
    }
  },

  pak(d, dt, ctx) {
    brake(d, dt);
    d.headDown = 1;
    if (ctx.ball.mode !== 'vrij') return go(d, 'wacht');
    if (d.t < 0.35) return;
    d.gevonden = false;
    d.events.push({ type: 'pak' });
    if (ctx.rand() < 0.3 * (ctx.nat || 0)) {
      d.events.push({ type: 'val' });
      ctx.say('De natte bal glipt uit Spots bek!');
      return go(d, 'wacht');
    }
    d.hasBall = true;
    naPak(d, ctx);
  },

  breng(d, dt, ctx) {
    const { player } = ctx;
    d.pose = 'sta';
    d.wag = 0.7;
    const dd = move(d, { x: player.x, z: player.z - 1.4 }, d.sloom ? DRAF : REN, dt, ctx, 0.3);
    if (dd < 0.45 && d.speed < 0.6) {
      d.sloom = false;
      d.done = 'bring'; d.doneT = 0;
      ctx.say('Spot brengt de bal! Beloon hem en zeg "aus"');
      go(d, 'houvast');
    }
  },

  houvast(d, dt, ctx) {
    brake(d, dt);
    face(d, ctx.player, dt);
    d.wag = 1;
    if (d.t > 10) {
      d.netjes = false;
      go(d, 'los');
    }
  },

  los(d, dt, ctx) {
    brake(d, dt);
    d.headDown = 0.7;
    if (d.t < 0.4) return;
    d.hasBall = false;
    d.events.push({ type: 'los', netjes: !!d.netjes, bijSpeler: dist(d.pos, ctx.player) < 3 });
    if (d.netjes) bump(d, 'vertrouwen', 1.5);
    d.netjes = false;
    d.worp = ctx.worp;
    go(d, 'wacht');
  },

  // Rondrennen met de bal, daarna erop liggen kauwen, en hem uiteindelijk toch brengen.
  speel(d, dt, ctx) {
    d.wag = 1;
    if (!d.doel || dist(d.pos, d.doel) < 1 || d.t > d.doelT) {
      const a = ctx.rand() * Math.PI * 2;
      d.doel = { x: d.pos.x * 0.7 + 7 * Math.cos(a), z: d.pos.z * 0.7 - 2 + 7 * Math.sin(a) };
      d.doelT = d.t + 2;
    }
    move(d, d.doel, 5, dt, ctx, 0.3);
    if (d.t > d.speelT || d.stats.energie < 15) go(d, 'kauw');
  },

  kauw(d, dt) {
    brake(d, dt);
    d.pose = 'lig';
    d.wag = 0.6;
    if (d.t > 6) {
      d.sloom = true;
      go(d, 'breng');
    }
  },

  afgeleid(d, dt, ctx) {
    const a = d.afl;
    d.look = { x: a.ref.x, y: a.type === 'eekhoorn' ? 1.2 : 0.4, z: a.ref.z };
    d.alert = 1;
    d.wag = 0.7;
    d.pose = 'sta';
    if (d.t < 0.7 || a.type === 'geluid') {
      brake(d, dt);
      face(d, a.ref, dt);
    } else if (move(d, a.ref, a.type === 'eekhoorn' ? 6.5 : 3.2, dt, ctx, 2.2) < 3 && d.t > (d.blafT || 0)) {
      d.blafT = d.t + 0.9;
      d.events.push({ type: 'blaf' });
    }
    if (d.t > a.dur) {
      d.blafT = 0;
      if (d.hasBall) naPak(d, ctx);
      else go(d, 'wacht');
    }
  },

  rust(d, dt, ctx) {
    brake(d, dt);
    d.pose = 'lig';
    d.wag = 0.1;
    if (ctx.worp !== d.worp && ctx.ball.mode === 'vrij') {
      d.worp = ctx.worp;
      ctx.say('Spot is te moe om te rennen');
    }
    if (d.stats.energie > 45) go(d, 'wacht');
  },

  drink(d, dt, ctx) {
    if (ctx.ball.mode === 'vrij') return go(d, 'wacht');
    const bak = d.doel === ctx.bowls.water ? d.doel : null;
    if (move(d, d.doel, DRAF, dt, ctx, 0.45) > 0.6) return;
    d.headDown = 1;
    bump(d, 'dorst', -25 * dt);
    if (bak) bak.vol = Math.max(0, bak.vol - dt / 4);
    if (d.stats.dorst < 3 || (bak && bak.vol <= 0)) {
      if (bak) bump(d, 'vertrouwen', 1);
      go(d, 'wacht');
    }
  },

  eet(d, dt, ctx) {
    if (ctx.ball.mode === 'vrij') return go(d, 'wacht');
    const bak = ctx.bowls.voer;
    if (move(d, bak, DRAF, dt, ctx, 0.45) > 0.6) return;
    d.headDown = 1;
    bump(d, 'honger', -20 * dt);
    bak.vol = Math.max(0, bak.vol - dt / 4);
    if (d.stats.honger < 3 || bak.vol <= 0) {
      bump(d, 'vertrouwen', 2);
      go(d, 'wacht');
    }
  },
};

// ctx: { ball: {mode: 'hand'|'vrij'|'bek', p, rust}, land, worp, player, hand, bowls: {voer, water},
//        vijverRand, surfaceAt, nat, grenzen, obstakels, events: [{type, pos, sterkte}], rand, say }
export function update(d, dt, ctx) {
  d.t += dt;
  d.doneT += dt;
  d.cool -= dt;
  d.aaiCool -= dt;
  d.swim = ctx.surfaceAt(d.pos.x, d.pos.z) === 'water';
  d.sniff = false;
  d.headDown = 0;
  d.alert = Math.max(0, d.alert - dt);
  const b = ctx.ball;
  d.look = b.mode === 'hand' ? ctx.hand : b.mode === 'vrij' ? b.p : { x: ctx.player.x, y: 1.5, z: ctx.player.z };

  if (AFLEIDBAAR.has(d.state)) {
    const e = ctx.events.find((e) => ctx.rand() < distractChance(d, e.sterkte));
    if (e) startAfgeleid(d, e, ctx);
  }
  STATES[d.state](d, dt, ctx);

  d.act = d.swim ? 'zwem' : d.speed > 4 ? 'ren' : d.speed > 1.6 ? 'draf' : d.speed > 0.2 ? 'loop' : d.pose;
  tickStats(d, dt, d.act);
}

const BEZIG = 'Spot is daar nu te druk voor';

// De speler geeft een commando. Geeft true terug als Spot gehoorzaamt.
export function command(d, cmd, ctx) {
  if (d.cool > 0) return false;
  d.cool = 1.2;
  const st = d.state, vrij = ctx.ball.mode === 'vrij';
  const rustig = st === 'wacht' || st === 'zit' || st === 'blijf' || st === 'afgeleid' || st === 'rust';
  const kan = {
    zit: rustig && !d.hasBall,
    blijf: rustig && !d.hasBall,
    bring: (vrij && rustig) || (d.hasBall && (st === 'speel' || st === 'kauw' || st === 'afgeleid')),
    aus: d.hasBall && st !== 'los',
  }[cmd];
  if (!kan) {
    ctx.say(cmd === 'aus' ? 'Spot heeft de bal niet' : cmd === 'bring' ? 'Er valt nu niets te brengen' : BEZIG);
    return false;
  }
  const p = obeyChance(d, cmd, st === 'afgeleid' ? 0.5 : 0) * (st === 'rust' ? 0.3 : 1);
  if (ctx.rand() >= p) {
    d.alert = 0.6;
    ctx.say(`Spot negeert "${cmd}"`);
    return false;
  }
  if (st === 'afgeleid') ctx.say('Spot luistert weer');
  if (cmd === 'zit') {
    d.done = 'zit'; d.doneT = 0;
    go(d, 'zit');
  } else if (cmd === 'blijf') {
    d.bleef = false;
    d.pose = 'zit';
    d.worp = ctx.worp;
    go(d, 'blijf');
  } else if (cmd === 'bring') {
    d.worp = ctx.worp;
    go(d, d.hasBall ? 'breng' : 'achtervolg');
  } else {
    d.netjes = true;
    d.done = 'aus'; d.doneT = 0;
    go(d, 'los');
  }
  return true;
}
