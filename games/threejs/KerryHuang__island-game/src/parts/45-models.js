
// ================= 細項模型 archetype（單位空間：底面 ±0.5、高 0–1.5） =================
const WALL = '#f4ebdd', EAVE = '#a34e34', WIN = '#a8c4c2';
const MODELS = {
  house(L) {
    L('rbox', [0, .03, 0], [.96, .06, .96], '#efe4d3');
    L('rbox', [0, .36, 0], [.68, .6, .58], WALL);
    L('box', [0, .68, 0], [.8, .05, .7], EAVE);
    L('hip', [0, .9, 0], [.78, .42, .68], PAL.coral);
    L('box', [.2, 1.02, -.1], [.1, .2, .1], EAVE);
    [-.18, .18].forEach((x) => L('glowbox', [x, .44, .292], [.15, .15, .02], WIN));
    L('box', [0, .2, .292], [.14, .26, .02], PAL.wood);
    L('ico', [.38, .14, .3], .16, PAL.plants[0]);
  },
  hall(L) {
    L('rbox', [0, .04, 0], [1, .08, .9], '#e9ddcb');
    L('rbox', [0, .32, -.05], [.92, .5, .55], PAL.cream);
    for (let i = 0; i < 5; i++) L('cylinder', [-.36 + i * .18, .3, .27], [.06, .44, .06], '#efe6da');
    L('box', [0, .6, .05], [1, .07, .7], PAL.stone);
    L('prism', [0, .7, .27], [.9, .14, .14], PAL.coral, [Math.PI / 2, 0, 0]);
    L('rbox', [0, .88, -.12], [.26, .62, .26], PAL.cream);
    L('cylinder', [0, 1.0, .015], [.19, .02, .19], '#fffdf6', [Math.PI / 2, 0, 0]);
    L('torus', [0, 1.0, .02], [.27, .27, .1], PAL.ink);
    L('box', [0, 1.03, .03], [.012, .07, .01], PAL.ink);
    L('hip', [0, 1.32, -.12], [.32, .26, .32], PAL.coral);
    [-.3, -.1, .1, .3].forEach((x) => L('glowbox', [x, .42, .23], [.1, .14, .02], WIN));
  },
  booth(L) {
    L('rbox', [0, .03, 0], [.9, .06, .8], '#eadfcd');
    L('rbox', [0, .22, .08], [.7, .3, .32], PAL.wood);
    L('box', [0, .38, .08], [.74, .03, .36], PAL.cream);
    [[-.34, .26], [.34, .26], [-.34, -.16], [.34, -.16]].forEach(([x, z]) => L('cylinder', [x, .45, z], [.04, .8, .04], PAL.cream));
    for (let i = 0; i < 6; i++) L('box', [-.31 + i * .124, .86, .05], [.124, .04, .56], i % 2 ? PAL.cream : PAL.coral, [-.18, 0, 0]);
    [-.22, 0, .22].forEach((x, i) => L('sphere', [x, .45, .12], .1, [PAL.yellow, PAL.pastel[0], PAL.plants[1]][i]));
    L('glowsphere', [0, .74, .2], .07, PAL.cream);
  },
  classroom(L) {
    L('rbox', [0, .03, 0], [1, .06, .9], '#e7dccb');
    L('box', [0, .34, -.4], [.94, .6, .06], WALL);
    L('box', [-.45, .3, 0], [.05, .52, .82], WALL);
    L('box', [0, .4, -.36], [.6, .28, .02], '#2f4a3f');
    L('box', [0, .26, -.355], [.6, .02, .03], PAL.wood);
    for (let r = 0; r < 2; r++) for (let c = 0; c < 3; c++) {
      const x = -.26 + c * .26, z = -.06 + r * .26;
      L('box', [x, .17, z], [.18, .03, .12], PAL.wood);
      L('box', [x, .1, z + .1], [.1, .04, .08], PAL.teal);
      L('cylinder', [x, .19, z + .12], [.06, .12, .06], PAL.pastel[(r + c) % 3]);
      L('sphere', [x, .3, z + .12], .09, '#f1cdb2');
      L('dome', [x, .32, z + .12], [.1, .08, .1], PAL.ink);
    }
    L('cylinder', [.3, .26, -.28], [.08, .32, .08], PAL.coral);
    L('sphere', [.3, .48, -.28], .11, '#f1cdb2');
  },
  clinic(L) {
    L('rbox', [0, .03, 0], [.96, .06, .9], '#eae3d8');
    L('rbox', [0, .4, -.05], [.78, .72, .6], '#fbf7f1');
    L('box', [0, .12, .26], [.8, .1, .02], PAL.pastel[1]);
    L('box', [0, .62, .262], [.2, .06, .02], PAL.coral);
    L('box', [0, .62, .262], [.06, .2, .02], PAL.coral);
    L('box', [0, .3, .36], [.4, .03, .22], PAL.teal);
    [-.25, .25].forEach((x) => L('glowbox', [x, .4, .252], [.14, .14, .02], WIN));
    L('box', [0, .8, -.05], [.82, .05, .64], PAL.stone);
  },
  busstop(L) {
    L('rbox', [0, .03, 0], [1, .06, .94], '#ddd3c4');
    L('box', [0, .07, .22], [1, .03, .4], '#8d8a86');
    [-.36, .36].forEach((x) => L('cylinder', [x, .3, -.3], [.035, .52, .035], PAL.ink));
    L('box', [0, .58, -.25], [.84, .04, .3], PAL.coral);
    L('box', [0, .32, -.36], [.74, .4, .02], PAL.glass);
    L('box', [0, .18, -.3], [.5, .04, .1], PAL.wood);
    L('rbox', [0, .3, .2], [.88, .34, .32], PAL.yellow);
    L('box', [0, .36, .362], [.76, .12, .01], PAL.teal);
    for (let i = 0; i < 4; i++) L('glowbox', [-.3 + i * .2, .37, .362], [.14, .1, .012], WIN);
    [-.28, .28].forEach((x) => [.05, .36].forEach((z) => L('cylinder', [x, .12, z], [.12, .05, .12], PAL.ink, [Math.PI / 2, 0, 0])));
  },
  bikes(L) {
    L('rbox', [0, .03, 0], [.96, .06, .8], '#e1d6c6');
    L('box', [0, .12, -.25], [.9, .04, .04], PAL.ink);
    for (let i = 0; i < 4; i++) {
      const x = -.33 + i * .22, c = [PAL.coral, PAL.teal, PAL.yellow, PAL.pastel[2]][i];
      [-.12, .12].forEach((z) => L('torus', [x, .16, z], [.32, .32, .3], PAL.ink, [0, Math.PI / 2, 0]));
      L('box', [x, .22, 0], [.03, .04, .26], c, [.4, 0, 0]);
      L('box', [x, .28, .1], [.12, .02, .02], PAL.ink);
      L('box', [x, .28, -.08], [.04, .03, .08], PAL.ink);
    }
    L('rbox', [.38, .4, .3], [.16, .6, .1], PAL.green);
    L('glowbox', [.38, .55, .352], [.1, .14, .01], WIN);
  },
  court(L) {
    L('rbox', [0, .03, 0], [1, .06, .96], '#7d8f74');
    L('box', [0, .062, 0], [.84, .004, .8], '#91a786');
    L('box', [0, .066, 0], [.84, .004, .015], '#fff8f4');
    L('box', [0, .066, .39], [.84, .004, .015], '#fff8f4');
    L('box', [0, .066, -.39], [.84, .004, .015], '#fff8f4');
    L('torus', [0, .066, 0], [.36, .36, .12], '#fff8f4', [Math.PI / 2, 0, 0]);
    L('cylinder', [0, .4, -.44], [.035, .7, .035], PAL.ink);
    L('box', [0, .72, -.4], [.3, .2, .02], PAL.cream);
    L('torus', [0, .64, -.33], [.22, .22, .2], PAL.coral, [Math.PI / 2, 0, 0]);
    L('sphere', [.18, .1, .12], .09, '#e58a3c');
    L('glowsphere', [.44, .9, .44], .06, PAL.cream);
    L('cylinder', [.44, .45, .44], [.03, .86, .03], PAL.ink);
  },
  farm(L) {
    L('rbox', [0, .03, 0], [.98, .06, .96], '#a07a58');
    for (let r = 0; r < 4; r++) {
      L('box', [0, .07, -.33 + r * .22], [.82, .04, .1], '#8a6446');
      for (let c = 0; c < 5; c++) L(r % 2 ? 'ico' : 'cone', [-.32 + c * .16, .16, -.33 + r * .22], r % 2 ? .13 : [.1, .18, .1], PAL.plants[(r + c) % 3]);
    }
    L('dome', [.34, .06, .34], [.3, .3, .26], '#d6ece6');
    for (let i = 0; i < 6; i++) L('box', [-.48, .12, -.45 + i * .18], [.03, .16, .03], PAL.wood);
    L('cylinder', [-.25, .3, .38], [.03, .44, .03], PAL.wood);
    L('cone', [-.25, .56, .38], [.2, .1, .2], PAL.yellow);
  },
  river(L) {
    L('rbox', [0, .03, 0], [1, .06, .96], '#cfd9b8');
    L('box', [0, .06, 0], [1, .02, .36], PAL.pastel[1]);
    L('box', [0, .072, 0], [1, .004, .2], '#7cc0bf');
    for (let i = 0; i < 7; i++) {
      const x = -.24 + i * .08, y = .1 + Math.sin(i / 6 * Math.PI) * .07;
      L('box', [x, y, 0], [.07, .025, .3], PAL.wood);
    }
    [-.15, .15].forEach((z) => L('box', [0, .2, z], [.5, .02, .02], PAL.cream));
    [[-.4, .3], [-.3, .36], [.38, -.32], [.3, -.38]].forEach(([x, z]) => L('cone', [x, .16, z], [.06, .24, .06], PAL.plants[2]));
    L('ico', [.36, .16, .32], .2, PAL.plants[0]);
  },
  stage(L) {
    L('rbox', [0, .03, 0], [1, .06, .96], '#e8dccb');
    L('rbox', [0, .12, -.08], [.86, .14, .6], PAL.wood);
    L('box', [0, .45, -.36], [.86, .54, .04], PAL.coral);
    L('box', [0, .76, -.08], [.92, .05, .66], PAL.ink);
    [-.42, .42].forEach((x) => L('cylinder', [x, .45, .22], [.04, .62, .04], PAL.ink));
    [-.3, -.1, .1, .3].forEach((x, i) => L('glowsphere', [x, .7, .22], .06, [PAL.yellow, PAL.pastel[0], PAL.yellow, PAL.pastel[1]][i]));
    [-.16, .16].forEach((x, i) => { L('cylinder', [x, .3, -.1], [.1, .16, .1], PAL.pastel[i + 1]); L('sphere', [x, .44, -.1], .12, '#f1cdb2'); });
    for (let i = 0; i < 3; i++) L('sphere', [-.24 + i * .24, .12, .36], .1, PAL.ink);
  },
  book(L) {
    L('rbox', [0, .03, 0], [.96, .06, .9], '#e9dfcf');
    L('box', [-.21, .26, 0], [.44, .05, .64], PAL.coral, [0, 0, .35]);
    L('box', [.21, .26, 0], [.44, .05, .64], PAL.coral, [0, 0, -.35]);
    L('box', [-.2, .31, 0], [.4, .05, .6], PAL.cream, [0, 0, .35]);
    L('box', [.2, .31, 0], [.4, .05, .6], PAL.cream, [0, 0, -.35]);
    L('box', [0, .18, 0], [.06, .2, .64], EAVE);
    for (let i = 0; i < 3; i++) L('box', [-.22, .35 + i * .0, -.15 + i * .14], [.26, .005, .02], PAL.stone, [0, 0, .35]);
    L('box', [.34, .1, .34], [.22, .1, .16], PAL.teal);
    L('box', [.34, .19, .34], [.2, .08, .15], PAL.yellow);
  },
  coin(L) {
    L('rbox', [0, .03, 0], [.92, .06, .9], '#ece2d2');
    for (let i = 0; i < 5; i++) L('cylinder', [-.24, .1 + i * .07, .18], [.32, .06, .32], i % 2 ? '#f5d76e' : PAL.yellow);
    L('cylinder', [.14, .48, -.06], [.72, .1, .72], '#f5d76e', [Math.PI / 2, 0, 0]);
    L('torus', [.14, .48, -.005], [.82, .82, .3], '#e3b94d');
    L('box', [.14, .48, .002], [.06, .26, .02], '#c99a34');
    L('box', [.14, .1, -.06], [.5, .08, .2], PAL.wood);
  },
  clock(L) {
    L('rbox', [0, .03, 0], [.9, .06, .9], '#e8ddcc');
    L('rbox', [0, .5, -.06], [.46, .9, .26], PAL.cream);
    L('cylinder', [0, .74, .08], [.38, .04, .38], '#fffdf6', [Math.PI / 2, 0, 0]);
    L('torus', [0, .74, .1], [.55, .55, .25], PAL.ink);
    L('box', [0, .79, .11], [.025, .12, .01], PAL.ink);
    L('box', [.04, .74, .11], [.09, .02, .01], PAL.coral);
    L('hip', [0, 1.1, -.06], [.5, .26, .3], PAL.teal);
    L('glowbox', [0, .32, .072], [.12, .2, .02], WIN);
  },
  globe(L) {
    L('rbox', [0, .03, 0], [.9, .06, .9], '#e8ddcc');
    L('cylinder', [0, .1, 0], [.36, .08, .36], PAL.wood);
    L('cylinder', [0, .26, 0], [.06, .28, .06], PAL.ink);
    L('sphere', [0, .72, 0], .64, PAL.pastel[1]);
    [[.18, .82, .2], [-.22, .66, .18], [.05, .52, .26], [-.1, .9, -.18], [.24, .6, -.14]].forEach((p) => L('ico', p, .2, PAL.plants[0]));
    L('torus', [0, .72, 0], [1.02, 1.02, .4], PAL.yellow, [0, 0, .4]);
  },
};

// ================= 島內配置 =================
const inHex = (x, z, a) => Math.abs(x) <= a && Math.abs(x) * .5 + Math.abs(z) * SQ3 / 2 <= a;
function layoutIsland(isl) {
  const items = isl.data.items, rest = items.length - 1, main = { x: 0, z: -.58, size: 1.15 };
  let cell = .62, cand = [];
  for (; cell >= .46; cell -= .02) {
    cand = [];
    for (let row = -4; row <= 4; row++) for (let col = -4; col <= 4; col++) {
      const x = (col + (row % 2 ? .5 : 0)) * cell, z = row * cell * .9;
      if (!inHex(x, z, 1.36 - cell * .5)) continue;
      if (Math.abs(x - main.x) < (main.size + cell) / 2 - .02 && Math.abs(z - main.z) < (main.size + cell) / 2 - .02) continue;
      cand.push({ x, z });
    }
    if (cand.length >= rest) break;
  }
  cell = Math.max(cell, .46);
  cand.sort((a, b) => (b.z - a.z) * .6 + (Math.abs(a.x) - Math.abs(b.x)) * .4); // 前排優先
  const spots = [main, ...cand.slice(0, rest).map((c) => ({ ...c, size: cell * .92 }))];
  items.forEach((it, i) => {
    const sp = spots[i];
    const frame = { origin: new THREE.Vector3(isl.cx + sp.x, TOP, isl.cz + sp.z), yaw: rr(-.18, .18), size: sp.size };
    const rec = { data: it, island: isl, frame, num: i + 1, top: new THREE.Vector3(frame.origin.x, TOP + sp.size * 1.15, frame.origin.z) };
    isl.items.push(rec); S.itemById[it.id] = rec;
    kit.owner = rec;
    const fn = MODELS[it.model] || MODELS.house;
    fn((kind, p, s, c, rot) => kit.local(frame, kind, p, s, c, rot));
    if (it.heat === 3) { // 熱度旗：只標全城最熱的議題，插在右後角，旗頂夜晚發光
      const h = .95;
      kit.local(frame, 'cylinder', [.44, h / 2, -.44], [.03, h, .03], PAL.stone);
      kit.local(frame, 'box', [.55, h - .07, -.44], [.2, .13, .02], isl.data.band);
      kit.local(frame, 'glowsphere', [.44, h + .02, -.44], .04, PAL.cream);
    }
    kit.owner = null;
  });
}
