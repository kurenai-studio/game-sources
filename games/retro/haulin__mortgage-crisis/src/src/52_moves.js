// MC.moves: shared move helpers (rules + UI). Pure-ish: reads state/move lists, no view mutations.

// Helpers for Place command lists (shared by targeting + menu label tweaks).
MC.moves.defaultWildColorForPlace = function (state, uid, def) {
  if (!def || !MC.rules.isWildDef(def)) return MC.state.NO_COLOR;
  var moves = MC.engine.legalMoves(state);
  var c0 = def.wildColors[0];
  var c1 = def.wildColors[1];
  var has0 = false, has1 = false;
  var i;
  for (i = 0; i < moves.length; i++) {
    var mp = moves[i];
    if (!mp || mp.kind !== "playProp") continue;
    if (!mp.card || mp.card.uid !== uid) continue;
    if (mp.color === c0 && mp.dest && mp.dest.setI != null) has0 = true;
    if (mp.color === c1 && mp.dest && mp.dest.setI != null) has1 = true;
  }
  return has0 ? c0 : (has1 ? c1 : c0);
};

MC.moves.placeCmdsForUid = function (state, uid, def, wildColor) {
  var moves = MC.engine.legalMoves(state);
  var cmds = [];
  var i;
  var isWild = !!(def && MC.rules.isWildDef(def));
  for (i = 0; i < moves.length; i++) {
    var mf = moves[i];
    if (!mf || mf.kind !== "playProp") continue;
    if (!mf.card || mf.card.uid !== uid) continue;
    if (isWild && mf.color !== wildColor) continue;
    cmds.push(mf);
  }

  // Ordering: existing sets first (by setI), then newSet.
  var existing = [];
  var newSet = [];
  for (i = 0; i < cmds.length; i++) {
    var c = cmds[i];
    if (c && c.dest && c.dest.newSet) newSet.push(c);
    else existing.push(c);
  }
  existing.sort(function (a, b) {
    var ai = (a.dest && a.dest.setI != null) ? a.dest.setI : 9999;
    var bi = (b.dest && b.dest.setI != null) ? b.dest.setI : 9999;
    return ai - bi;
  });
  return existing.concat(newSet);
};

MC.moves.defaultWildColorForMoveWild = function (state, uid, def, loc) {
  if (!def || !MC.rules.isWildDef(def)) return MC.state.NO_COLOR;
  if (loc && String(loc.zone || "") === "setProps" && loc.p != null && loc.setI != null && loc.i != null) {
    var sets = state.players[loc.p] ? state.players[loc.p].sets : null;
    var set = sets ? sets[loc.setI] : null;
    var props = set ? set.props : null;
    if (props && props[loc.i] && props[loc.i][0] === uid) return props[loc.i][1];
  }
  // Fallback: same default heuristic as Place (favor a color with existing-set destinations).
  return MC.moves.defaultWildColorForPlace(state, uid, def);
};

MC.moves.moveWildCmdsForUid = function (state, uid, def, wildColor) {
  var moves = MC.engine.legalMoves(state);
  var cmds = [];
  var i;
  var isWild = !!(def && MC.rules.isWildDef(def));
  for (i = 0; i < moves.length; i++) {
    var mv = moves[i];
    if (!mv || mv.kind !== "moveWild") continue;
    if (!mv.card || mv.card.uid !== uid) continue;
    if (isWild && mv.color !== wildColor) continue;
    cmds.push(mv);
  }
  return cmds;
};

MC.moves.buildCmdsForUid = function (state, uid) {
  var moves = MC.engine.legalMoves(state);
  var buildMoves = [];
  var i;
  for (i = 0; i < moves.length; i++) {
    var mv = moves[i];
    if (mv && mv.kind === "playHouse" && mv.card && mv.card.uid === uid) buildMoves.push(mv);
  }
  return buildMoves;
};

MC.moves.rentMovesForUid = function (state, uid) {
  var moves = MC.engine.legalMoves(state);
  var rentMoves = [];
  var i;
  for (i = 0; i < moves.length; i++) {
    var mv = moves[i];
    if (mv && mv.kind === "playRent" && mv.card && mv.card.uid === uid) rentMoves.push(mv);
  }
  return rentMoves;
};

MC.moves.slyDealMovesForUid = function (state, uid) {
  var moves = MC.engine.legalMoves(state);
  var out = [];
  var i;
  for (i = 0; i < moves.length; i++) {
    var mv = moves[i];
    if (mv && mv.kind === "playSlyDeal" && mv.card && mv.card.uid === uid) out.push(mv);
  }
  return out;
};

MC.moves.locAllowsSource = function (loc) {
  if (!loc || !loc.zone) return false;
  var z = String(loc.zone);
  return (z === "hand") || (z === "recvProps");
};

MC.moves.cmdsWithoutSource = function (cmds) {
  if (!cmds || cmds.length === 0) return [];
  var out = [];
  var i;
  for (i = 0; i < cmds.length; i++) {
    var c = cmds[i];
    if (!c || !c.kind) continue;
    if (c.kind === "source") continue;
    out.push(c);
  }
  return out;
};

// Build the list of cmds for a targeting mode.
// Returns { cmds, wildColor } or null (unknown kind).
MC.moves.cmdsForTargeting = function (state, kind, uid, loc) {
  kind = String(kind || "");
  var out = { cmds: [], wildColor: MC.state.NO_COLOR };

  // Cmd profiles: the single source of truth for targeting-mode cmd lists.
  var prof = MC.cmd.getProfile(kind);
  if (!prof) return null;

  var def = MC.state.defByUid(state, uid);
  var isWild = !!(def && MC.rules.isWildDef(def));
  if (isWild && prof.defaultWildColor) out.wildColor = prof.defaultWildColor(state, uid, def, loc);
  else out.wildColor = MC.state.NO_COLOR;

  if (prof.cmdsForUid) out.cmds = prof.cmdsForUid(state, uid, loc);
  else if (prof.cmdsForWildColor) out.cmds = prof.cmdsForWildColor(state, uid, def, out.wildColor, loc);
  else out.cmds = [];

  if (prof.includeSource && prof.includeSource(loc)) out.cmds.push({ kind: "source" });
  return out;
};

// Command semantics: interpret a cmd's destination in board-space terms.
// Returns one of:
// - {kind:"newSet", p}
// - {kind:"setEnd", p, setI}
// - {kind:"setTop", p, setI}
// - {kind:"bankEnd", p}
// - {kind:"source"}
// - null
MC.moves.destForCmd = function (cmd) {
  if (!cmd || !cmd.kind) return null;
  if (cmd.kind === "playProp") {
    if (cmd.dest && cmd.dest.newSet) return { kind: "newSet", p: cmd.dest.p };
    if (cmd.dest && cmd.dest.setI != null) return { kind: "setEnd", p: cmd.dest.p, setI: cmd.dest.setI };
    return null;
  }
  if (cmd.kind === "moveWild") {
    if (cmd.dest && cmd.dest.newSet) return { kind: "newSet", p: cmd.dest.p };
    if (cmd.dest && cmd.dest.setI != null) return { kind: "setEnd", p: cmd.dest.p, setI: cmd.dest.setI };
    return null;
  }
  if (cmd.kind === "playHouse") {
    if (cmd.dest && cmd.dest.setI != null) return { kind: "setEnd", p: cmd.dest.p, setI: cmd.dest.setI };
    return null;
  }
  if (cmd.kind === "bank") return { kind: "bankEnd", p: cmd.card && cmd.card.loc ? cmd.card.loc.p : 0 };
  if (cmd.kind === "playRent") return { kind: "setTop", p: cmd.card && cmd.card.loc ? cmd.card.loc.p : 0, setI: cmd.setI };
  if (cmd.kind === "source") return { kind: "source" };
  return null;
};

MC.moves.bankCmdsForUid = function (state, uid) {
  var moves = MC.engine.legalMoves(state);
  var cmds = [];
  var i;
  for (i = 0; i < moves.length; i++) {
    var mv = moves[i];
    if (!mv || mv.kind !== "bank") continue;
    if (!mv.card || mv.card.uid !== uid) continue;
    cmds.push(mv);
  }
  return cmds;
};

