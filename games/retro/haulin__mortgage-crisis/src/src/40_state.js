// MC.state: game state constructors + uid bookkeeping + prompt helpers (no UI/render).
MC.state.NO_COLOR = -1;
MC.state.NO_WINNER = -1;
MC.state.HAND_MAX = 7;

MC.state.clearPrompt = function (state) {
  state.prompt = null;
};

MC.state.setPrompt = function (state, prompt) {
  if (prompt == null) {
    state.prompt = null;
    return;
  }
  var k = String(prompt.kind);
  var p = prompt.p;

  if (k === "discardDown") {
    var nDiscarded = (prompt.nDiscarded != null) ? prompt.nDiscarded : 0;
    state.prompt = {
      kind: k,
      p: p,
      nDiscarded: nDiscarded
    };
    return;
  }

  if (k === "payDebt") {
    var src = prompt.srcAction;
    var srcAction = src ? { kind: String(src.kind || ""), fromP: src.fromP, actionUid: Math.floor(src.actionUid) } : null;
    state.prompt = {
      kind: k,
      p: p,
      toP: prompt.toP,
      rem: Math.floor(prompt.rem),
      buf: prompt.buf.slice(),
      srcAction: srcAction
    };
    return;
  }

  if (k === "respondAction") {
    // Generic response window prompt.
    var src2 = prompt.srcAction;
    var srcAction2 = src2 ? { kind: String(src2.kind || ""), fromP: src2.fromP, actionUid: Math.floor(src2.actionUid) } : null;
    var tgt = prompt.target;
    var loc = tgt && tgt.loc ? tgt.loc : null;
    state.prompt = {
      kind: k,
      p: p,
      srcAction: srcAction2,
      target: { uid: tgt ? tgt.uid : 0, loc: { p: loc ? loc.p : 0, zone: loc ? loc.zone : "", setI: loc ? loc.setI : 0, i: loc ? loc.i : 0 } }
    };
    return;
  }

  if (k === "placeReceived") {
    state.prompt = {
      kind: k,
      p: p,
      uids: prompt.uids.slice()
    };
    return;
  }

  if (k === "replaceWindow") {
    // Wild replace-window (optional reposition after property placement).
    var resume = prompt.resume;
    var resumeObj = null;
    if (resume && String(resume.kind || "") === "placeReceived") {
      resumeObj = { kind: "placeReceived", uids: resume.uids.slice() };
    }
    state.prompt = {
      kind: k,
      p: p,
      srcSetI: Math.floor(prompt.srcSetI),
      excludeUid: Math.floor(prompt.excludeUid),
      resume: resumeObj
    };
    return;
  }

  throw new Error("unknown_prompt_kind:" + k);
};

MC.state.hasAnyPayables = function (state, p) {
  var pl = state.players[p];
  if (pl.bank.length) return true;
  var sets = pl.sets;
  var si;
  for (si = 0; si < sets.length; si++) {
    var set = sets[si];
    if (set.houseUid) return true;
    if (set.props.length) return true;
  }
  return false;
};

MC.state.beginDebt = function (state, fromP, toP, amount, srcAction) {
  if (!(amount > 0)) return;
  if (!MC.state.hasAnyPayables(state, fromP)) return;
  MC.state.setPrompt(state, { kind: "payDebt", p: fromP, toP: toP, rem: amount, buf: [], srcAction: srcAction || null });
};

MC.rules.otherPlayer = function (p) {
  return (p ^ 1) & 1;
};

MC.rules.getSetColor = function (props) {
  if (!props || props.length === 0) return MC.state.NO_COLOR;
  return props[0][1];
};

MC.rules.isBankableDef = function (def) {
  if (!def) return false;
  return def.kind === MC.CardKind.Money || def.kind === MC.CardKind.Action || def.kind === MC.CardKind.House;
};

MC.rules.isWildDef = function (def) {
  return !!(def && def.kind === MC.CardKind.Property && def.wildColors && def.wildColors.length);
};

MC.rules.handHasActionKind = function (state, p, actionKind) {
  var hand = state && state.players && state.players[p] ? state.players[p].hand : null;
  if (!hand || hand.length === 0) return false;
  var i;
  for (i = 0; i < hand.length; i++) {
    var uid = hand[i];
    var def = MC.state.defByUid(state, uid);
    if (def && def.kind === MC.CardKind.Action && def.actionKind === actionKind) return true;
  }
  return false;
};

MC.rules.wildAllowsColor = function (def, color) {
  if (!MC.rules.isWildDef(def)) return false;
  return def.wildColors[0] === color || def.wildColors[1] === color;
};

MC.state.buildAllUids = function (state) {
  var uidToDefI = [0];
  var uid = 1;
  var di;
  for (di = 0; di < MC.CARD_DEFS.length; di++) {
    var def = MC.CARD_DEFS[di];
    var c = def.count;
    var k;
    for (k = 0; k < c; k++) {
      uidToDefI[uid] = di;
      uid++;
    }
  }
  state.uidToDefI = uidToDefI;
  state.totalUids = uidToDefI.length - 1;
};

MC.state.defByUid = function (state, uid) {
  var di = state.uidToDefI[uid];
  return MC.CARD_DEFS[di];
};

MC.state.newEmptySet = function () {
  return {
    // Properties are tuples: [uid, color]
    props: [],
    // House card uid (0/undefined means none).
    houseUid: 0
  };
};

MC.state.drawToHand = function (state, p, n, events) {
  if (n <= 0) return;

  var uids = [];
  while (n > 0) {
    var nAvail = state.deck.length;
    if (nAvail <= 0) {
      var nDisc = state.discard.length;
      if (nDisc <= 0) break;
      // Reshuffle discard into deck (deterministic).
      var i;
      for (i = 0; i < nDisc; i++) state.deck.push(state.discard[i]);
      state.discard = [];
      MC.shuffle.inPlaceWithStateRng(state, state.deck);
      if (events) events.push({ kind: "reshuffle", from: "discard", to: "deck", n: nDisc });
      nAvail = state.deck.length;
      if (nAvail <= 0) break;
    }

    var take = nAvail;
    if (take > n) take = n;
    var k;
    for (k = 0; k < take; k++) {
      var uid = state.deck.pop();
      state.players[p].hand.push(uid);
      uids.push(uid);
    }
    n -= take;
  }

  if (events && uids.length > 0) events.push({ kind: "draw", p: p, uids: uids });
};

MC.state.startTurn = function (state, events) {
  state.playsLeft = 3;
  MC.state.clearPrompt(state);
  var p = state.activeP;
  var nDraw = 2;
  if (state.players[p].hand.length === 0) nDraw = 5;
  MC.state.drawToHand(state, p, nDraw, events);
  if (events) events.push({ kind: "plays", p: state.activeP, playsLeft: state.playsLeft });
};

MC.state.newGame = function (opts) {
  var seedU32 = (opts.seedU32 == null) ? MC.seed.computeSeedU32() : MC.rng.u32NonZero(opts.seedU32);

  var state = {
    rngS: seedU32,
    uidToDefI: null,
    totalUids: 0,

    deck: [],
    discard: [],

    players: [
      { hand: [], bank: [], sets: [] },
      { hand: [], bank: [], sets: [] }
    ],

    activeP: 0,
    playsLeft: 0,
    prompt: null,
    winnerP: MC.state.NO_WINNER
  };

  MC.state.buildAllUids(state);

  if (opts.scenarioId) {
    MC.scenarios.applyScenario(state, String(opts.scenarioId));
    return state;
  }

  // Default game start: shuffle full deck, deal 5 each, choose first player randomly,
  // then start their turn (draw 2, playsLeft=3).
  var uid;
  for (uid = 1; uid <= state.totalUids; uid++) state.deck.push(uid);
  MC.shuffle.inPlaceWithStateRng(state, state.deck);

  MC.state.drawToHand(state, 0, 5, null);
  MC.state.drawToHand(state, 1, 5, null);

  state.activeP = MC.rng.nextIntInState(state, 2);
  var events = [];
  events.push({ kind: "turn", activeP: state.activeP });
  MC.state.startTurn(state, events);
  // Default newGame doesn't expose events, but tests may call startTurn/endTurn directly.

  return state;
};

// Scenario/test helpers (defId-first).
MC.state.cardPoolInit = function (state) {
  var pool = {};
  var uid;
  for (uid = 1; uid <= state.totalUids; uid++) {
    var di = state.uidToDefI[uid];
    var defId = MC.CARD_DEFS[di].id;
    var a = pool[defId];
    if (!a) {
      a = [];
      pool[defId] = a;
    }
    a.push(uid);
  }
  state._pool = pool;
  return pool;
};

MC.state.takeUid = function (state, defId) {
  if (!state._pool) MC.state.cardPoolInit(state);
  var a = state._pool[defId];
  if (!a || a.length === 0) throw new Error("pool_exhausted:" + defId);
  return a.pop();
};

