import { NODES, LINKS } from './data.js';
import { HALF } from './world.js';

const $ = (id) => document.getElementById(id);
const idx = Object.fromEntries(NODES.map((n, i) => [n.id, i]));
const STATE_COLOR = { lit: '#ffb54a', open: '#46e0c8', locked: '#7b5bb0' };
const text = new Map();
const setText = (id, value) => {
  if (text.get(id) === value) return;
  text.set(id, value);
  $(id).textContent = value;
};

export function createHud(mapImage) {
  const mini = $('mini'), mctx = mini.getContext('2d');
  const big = $('bigmap'), bctx = big.getContext('2d');

  function nodeState(v, i) {
    return v.nodes[i].lit ? 'lit' : v.available(i) ? 'open' : 'locked';
  }

  function drawWorld(ctx, v, unit) {
    ctx.drawImage(mapImage, -HALF, -HALF, HALF * 2, HALF * 2);
    ctx.fillStyle = `rgba(8,6,24,${0.45 * (1 - v.dawn)})`;
    ctx.fillRect(-HALF, -HALF, HALF * 2, HALF * 2);
    ctx.globalCompositeOperation = 'lighter';
    NODES.forEach((n, i) => {
      const r = v.uniforms[i].z;
      if (!v.nodes[i].lit || r < 1) return;
      const g = ctx.createRadialGradient(n.pos[0], n.pos[1], 0, n.pos[0], n.pos[1], r);
      g.addColorStop(0, 'rgba(255,170,70,0.28)');
      g.addColorStop(1, 'rgba(255,170,70,0)');
      ctx.fillStyle = g;
      ctx.fillRect(n.pos[0] - r, n.pos[1] - r, r * 2, r * 2);
    });
    ctx.globalCompositeOperation = 'source-over';
    for (const [a, b] of LINKS) {
      const A = NODES[idx[a]].pos, B = NODES[idx[b]].pos, la = v.nodes[idx[a]].lit, lb = v.nodes[idx[b]].lit;
      ctx.strokeStyle = la && lb ? 'rgba(255,181,74,0.9)' : la || lb ? 'rgba(70,224,200,0.75)' : 'rgba(123,91,176,0.45)';
      ctx.lineWidth = 2.2 * unit;
      ctx.setLineDash(la && lb ? [] : [6 * unit, 5 * unit]);
      ctx.beginPath();
      ctx.moveTo(A[0], A[1]);
      ctx.lineTo(B[0], B[1]);
      ctx.stroke();
    }
    ctx.setLineDash([]);
    ctx.fillStyle = '#ffcf7a';
    for (const e of v.embers) {
      if (v.radarAll || Math.hypot(e.x - v.player.x, e.z - v.player.z) < v.radarRange) {
        ctx.globalAlpha = e.value > 1 ? 1 : 0.8;
        ctx.fillRect(e.x - 1.6 * unit * (e.value > 1 ? 2 : 1), e.z - 1.6 * unit * (e.value > 1 ? 2 : 1), 3.2 * unit * (e.value > 1 ? 2 : 1), 3.2 * unit * (e.value > 1 ? 2 : 1));
      }
    }
    ctx.globalAlpha = 1;
    ctx.fillStyle = '#ff3fa4';
    for (const h of v.hollows) {
      if (Math.hypot(h.x - v.player.x, h.z - v.player.z) > 140) continue;
      ctx.beginPath();
      ctx.arc(h.x, h.z, 2.6 * unit, 0, Math.PI * 2);
      ctx.fill();
    }
    NODES.forEach((n, i) => {
      const st = nodeState(v, i);
      ctx.fillStyle = STATE_COLOR[st];
      ctx.strokeStyle = '#0b0a18';
      ctx.lineWidth = 2 * unit;
      ctx.beginPath();
      ctx.arc(n.pos[0], n.pos[1], (v.pin === i ? 9 : 6.5) * unit, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      if (v.pin === i) {
        ctx.strokeStyle = '#ffffff';
        ctx.lineWidth = 1.5 * unit;
        ctx.beginPath();
        ctx.arc(n.pos[0], n.pos[1], (13 + Math.sin(v.t * 5) * 2) * unit, 0, Math.PI * 2);
        ctx.stroke();
      }
    });
    if (!v.inCar) {
      ctx.fillStyle = '#e9d8b4';
      ctx.save();
      ctx.translate(v.car.x, v.car.z);
      ctx.rotate(-v.car.heading);
      ctx.fillRect(-3 * unit, -5 * unit, 6 * unit, 10 * unit);
      ctx.restore();
    }
  }

  function arrow(ctx, size, color) {
    ctx.fillStyle = color;
    ctx.strokeStyle = '#0b0a18';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(0, -size);
    ctx.lineTo(size * 0.7, size * 0.8);
    ctx.lineTo(0, size * 0.35);
    ctx.lineTo(-size * 0.7, size * 0.8);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
  }

  function drawMini(v) {
    const R = mini.width / 2, scale = 0.62;
    mctx.save();
    mctx.clearRect(0, 0, mini.width, mini.height);
    mctx.beginPath();
    mctx.arc(R, R, R - 3, 0, Math.PI * 2);
    mctx.clip();
    mctx.fillStyle = '#0d1426';
    mctx.fillRect(0, 0, mini.width, mini.height);
    mctx.translate(R, R);
    mctx.rotate(Math.PI + v.camYaw);
    mctx.scale(scale, scale);
    mctx.translate(-v.player.x, -v.player.z);
    drawWorld(mctx, v, 1 / scale);
    mctx.restore();

    if (v.pin !== null) {
      const n = NODES[v.pin], dx = n.pos[0] - v.player.x, dz = n.pos[1] - v.player.z;
      const a = Math.PI + v.camYaw, sx = (dx * Math.cos(a) - dz * Math.sin(a)) * scale, sy = (dx * Math.sin(a) + dz * Math.cos(a)) * scale;
      const d = Math.hypot(sx, sy);
      if (d > R - 14) {
        mctx.save();
        mctx.translate(R + (sx / d) * (R - 12), R + (sy / d) * (R - 12));
        mctx.rotate(Math.atan2(sy, sx) + Math.PI / 2);
        arrow(mctx, 7, '#ffffff');
        mctx.restore();
      }
    }
    mctx.save();
    mctx.translate(R, R);
    mctx.rotate(-(v.player.heading - v.camYaw));
    arrow(mctx, 8, v.inCar ? '#e9d8b4' : '#46e0c8');
    mctx.restore();
  }

  let bigScale = 1;
  function drawMap(v) {
    const size = Math.min(innerWidth * 0.62, innerHeight * 0.86);
    if (big.width !== Math.round(size)) big.width = big.height = Math.round(size);
    bigScale = size / (HALF * 2);
    bctx.save();
    bctx.clearRect(0, 0, size, size);
    bctx.scale(bigScale, bigScale);
    bctx.translate(HALF, HALF);
    drawWorld(bctx, v, 1 / bigScale);
    bctx.font = `600 ${13 / bigScale}px Bricolage Grotesque, sans-serif`;
    bctx.textAlign = 'center';
    NODES.forEach((n, i) => {
      const st = nodeState(v, i), node = v.nodes[i];
      bctx.fillStyle = 'rgba(11,10,24,0.75)';
      const label = st === 'lit' ? n.name : `${n.name} · ${Math.floor(node.progress)}/${n.cost}`;
      const w = bctx.measureText(label).width + 12 / bigScale;
      bctx.fillRect(n.pos[0] - w / 2, n.pos[1] + 12 / bigScale, w, 19 / bigScale);
      bctx.fillStyle = STATE_COLOR[st];
      bctx.fillText(label, n.pos[0], n.pos[1] + 26 / bigScale);
    });
    bctx.translate(v.player.x, v.player.z);
    bctx.rotate(Math.PI - v.player.heading);
    bctx.scale(1 / bigScale, 1 / bigScale);
    arrow(bctx, 9, v.inCar ? '#e9d8b4' : '#46e0c8');
    bctx.restore();

    $('mapList').innerHTML = NODES.map((n, i) => {
      const st = nodeState(v, i), node = v.nodes[i];
      const status = st === 'lit' ? 'Restored' : st === 'open' ? `${Math.floor(node.progress)} / ${n.cost} embers` : n.id === 'beacon' ? 'Needs every substation' : 'No live link';
      return `<li data-node="${i}" class="${st}${v.pin === i ? ' pinned' : ''}"><b>${n.name}</b><span>${n.district} · ${status}</span><em>${n.perkText}</em></li>`;
    }).join('');
  }

  function mapHit(ev) {
    const r = big.getBoundingClientRect();
    const x = (ev.clientX - r.left) / bigScale - HALF, z = (ev.clientY - r.top) / bigScale - HALF;
    let best = null, bestD = 22 / bigScale;
    NODES.forEach((n, i) => {
      const d = Math.hypot(n.pos[0] - x, n.pos[1] - z);
      if (d < bestD) { best = i; bestD = d; }
    });
    return best;
  }

  function toast(title, sub = '', kind = '') {
    const el = document.createElement('div');
    el.className = `toast ${kind}`;
    el.innerHTML = `<b>${title}</b>${sub ? `<span>${sub}</span>` : ''}`;
    $('toasts').appendChild(el);
    while ($('toasts').children.length > 4) $('toasts').firstChild.remove();
    setTimeout(() => el.classList.add('out'), 4200);
    setTimeout(() => el.remove(), 5000);
  }

  return { drawMini, drawMap, mapHit, toast, setText };
}
