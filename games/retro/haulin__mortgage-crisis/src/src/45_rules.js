// MC.rules: pure rule computations. MC.engine: deterministic command application + move generation.
MC.rules.evaluateWin = function (state) {
  var p;
  for (p = 0; p < 2; p++) {
    var sets = state.players[p].sets;
    var complete = 0;
    var si;
    for (si = 0; si < sets.length; si++) {
      var set = sets[si];
      if (!set) continue;
      var color = MC.rules.getSetColor(set.props);
      if (color === MC.state.NO_COLOR) continue;
      var req = MC.SET_RULES[color].requiredSize;
      if (set.props.length >= req && req > 0) complete++;
    }
    if (complete >= 3) return p;
  }
  return MC.state.NO_WINNER;
};

MC.engine.assertCanApply = function (state) {
  if (state.winnerP !== MC.state.NO_WINNER) throw new Error("game_over");
};

MC.engine.locEqZone = function (loc, zone) {
  return !!loc && loc.zone === zone;
};

MC.rules.rentAmountForColorCount = function (color, nPropsUncapped, hasHouse) {
  if (color === MC.state.NO_COLOR) return 0;
  var rules = MC.SET_RULES[color];
  if (!rules || !rules.rent || rules.rent.length <= 0) return 0;

  var req = rules.requiredSize;
  var n = nPropsUncapped;
  if (!(n > 0)) return 0;
  if (req > 0 && n > req) n = req;
  if (!(n > 0)) return 0;

  var base = rules.rent[n - 1];
  var bonus = 0;
  if (hasHouse && req > 0 && nPropsUncapped >= req) bonus = MC.HOUSE_RENT_BONUS;
  return base + bonus;
};

MC.rules.rentAmountForSet = function (state, p, setI) {
  var sets = state.players[p].sets;
  if (setI < 0 || setI >= sets.length) return 0;
  var set = sets[setI];
  if (!set || !set.props || set.props.length <= 0) return 0;

  var color = MC.rules.getSetColor(set.props);
  return MC.rules.rentAmountForColorCount(color, set.props.length, !!set.houseUid);
};

MC.rules.replaceWindowEligibleWildLocs = function (state, p, srcSetI, excludeUid) {
  // Replace-window is offered only when we can remove exactly 1 Wild from
  // the just-played-into set while keeping that source set complete.
  if (!(p === 0 || p === 1)) return [];
  var sets = state.players[p] ? state.players[p].sets : null;
  if (!sets || srcSetI < 0 || srcSetI >= sets.length) return [];
  var set = sets[srcSetI];
  if (!set || !set.props || set.props.length <= 0) return [];

  var srcColor = MC.rules.getSetColor(set.props);
  if (srcColor === MC.state.NO_COLOR) return [];
  var req = MC.SET_RULES[srcColor].requiredSize;
  if (!(req > 0)) return [];

  // Need to still be complete after removing exactly 1 property.
  if ((set.props.length - 1) < req) return [];

  var out = [];
  var props = set.props;
  var i;
  for (i = 0; i < props.length; i++) {
    var tup = props[i];
    if (!tup) continue;
    var uid = tup[0];
    if (uid === excludeUid) continue;
    var def = MC.state.defByUid(state, uid);
    if (!MC.rules.isWildDef(def)) continue;
    out.push({ uid: uid, loc: { p: p, zone: "setProps", setI: srcSetI, i: i } });
  }
  return out;
};

MC.rules.replaceWindowDestinations = function (state, p, srcSetI, placedColor) {
  // Destinations: other matching-color sets (in setI order) plus newSet (last).
  if (!(p === 0 || p === 1)) return [{ p: p, newSet: true }];
  var sets = state.players[p] ? state.players[p].sets : null;
  if (!sets) return [{ p: p, newSet: true }];
  var out = [];
  var si;
  for (si = 0; si < sets.length; si++) {
    if (si === srcSetI) continue;
    var set = sets[si];
    var col = MC.rules.getSetColor(set ? set.props : null);
    if (col === MC.state.NO_COLOR) continue;
    if (col !== placedColor) continue;
    out.push({ p: p, setI: si });
  }
  out.push({ p: p, newSet: true });
  return out;
};

MC.rules.replaceWindowValidateMove = function (state, prompt, cmdMove, actorP) {
  if (!cmdMove || cmdMove.kind !== "moveWild") return { ok: false, err: "bad_cmd" };
  var card = cmdMove.card;
  var dest = cmdMove.dest;
  if (!card || !card.loc || !dest) return { ok: false, err: "bad_cmd" };
  if (card.loc.p !== actorP) return { ok: false, err: "not_your_card" };
  if (String(card.loc.zone || "") !== "setProps") return { ok: false, err: "bad_loc" };

  var srcSetI = prompt.srcSetI;
  if (card.loc.setI !== srcSetI) return { ok: false, err: "bad_src_set" };
  var uid = card.uid;
  if (uid === prompt.excludeUid) return { ok: false, err: "replace_exclude" };

  var sets = state.players[actorP] ? state.players[actorP].sets : null;
  if (!sets || srcSetI < 0 || srcSetI >= sets.length) return { ok: false, err: "bad_set" };
  var srcSet = sets[srcSetI];
  if (!srcSet || !srcSet.props) return { ok: false, err: "bad_set" };

  var pi = card.loc.i;
  if (!srcSet.props[pi] || srcSet.props[pi][0] !== uid) return { ok: false, err: "bad_loc" };

  var def = MC.state.defByUid(state, uid);
  if (!MC.rules.isWildDef(def)) return { ok: false, err: "not_wild" };

  var placedColor = cmdMove.color;
  if (!MC.rules.wildAllowsColor(def, placedColor)) return { ok: false, err: "wild_color_illegal" };

  // Source must remain complete after removing exactly 1 property.
  var srcColor = MC.rules.getSetColor(srcSet.props);
  if (srcColor === MC.state.NO_COLOR) return { ok: false, err: "empty_set" };
  var req = MC.SET_RULES[srcColor].requiredSize;
  if (!((srcSet.props.length - 1) >= req)) return { ok: false, err: "replace_src_incomplete" };

  // Destination: other set (matching color) or new set.
  var destSetI = -1;
  var isNewSet = !!dest.newSet;
  if (isNewSet) {
    destSetI = sets.length;
  } else {
    destSetI = dest.setI;
    if (destSetI === srcSetI) return { ok: false, err: "replace_same_set" };
    if (destSetI < 0 || destSetI >= sets.length) return { ok: false, err: "bad_set" };
    var setExisting = sets[destSetI];
    var setColor = MC.rules.getSetColor(setExisting ? setExisting.props : null);
    if (setColor === MC.state.NO_COLOR) return { ok: false, err: "empty_set" };
    if (setColor !== placedColor) return { ok: false, err: "set_color_mismatch" };
  }

  return {
    ok: true,
    uid: uid,
    srcSetI: srcSetI,
    srcI: pi,
    destSetI: destSetI,
    isNewSet: isNewSet,
    placedColor: placedColor
  };
};

MC.engine.removeHandAtLoc = function (state, card) {
  var loc = card.loc;
  var p = loc.p;
  var i = loc.i;
  var uid = card.uid;
  var hand = state.players[p].hand;
  if (hand[i] !== uid) throw new Error("bad_loc");
  hand.splice(i, 1);
};

MC.engine.applyCommand = function (state, cmd) {
  MC.engine.assertCanApply(state);
  if (!cmd || !cmd.kind) throw new Error("bad_cmd");

  var events = [];
  var prompt = state.prompt;
  var p = prompt ? prompt.p : state.activeP;
  var handP = state.players[p].hand;

  function decPlays() {
    state.playsLeft -= 1;
    events.push({ kind: "plays", p: p, playsLeft: state.playsLeft });
  }

  function applyEndTurn() {
    state.activeP = MC.rules.otherPlayer(state.activeP);
    events.push({ kind: "turn", activeP: state.activeP });
    MC.state.startTurn(state, events);
  }

  function applyDiscard(cmdDiscard) {
    var card = cmdDiscard.card;
    if (!card || !card.loc) throw new Error("bad_cmd");
    if (!MC.engine.locEqZone(card.loc, "hand")) throw new Error("bad_loc");
    if (card.loc.p !== p) throw new Error("not_your_card");

    var uid = card.uid;
    MC.engine.removeHandAtLoc(state, card);
    state.discard.push(uid);

    events.push({
      kind: "move",
      uid: uid,
      from: card.loc,
      to: { zone: "discard", i: state.discard.length - 1 }
    });

    if (state.prompt && state.prompt.kind === "discardDown") {
      state.prompt.nDiscarded += 1;
    }

    // End-turn discard-down prompt: once <= HAND_MAX, finish ending the turn.
    if (handP.length <= MC.state.HAND_MAX) {
      MC.state.clearPrompt(state);
      applyEndTurn();
    }
  }

  function cleanupEmptySetsForPlayer(pp) {
    var sets = state.players[pp].sets;
    var i;
    for (i = sets.length - 1; i >= 0; i--) {
      var set = sets[i];
      var nProps = set.props.length;
      var hasHouse = !!set.houseUid;
      if (nProps === 0 && !hasHouse) sets.splice(i, 1);
    }
  }

  function tryBeginReplaceWindow(actorP, srcSetI, excludeUid, resume) {
    // After placing a property into a set, optionally allow moving one Wild
    // out of that same set (excluding the just-played card), but only if the source
    // set remains complete after removal.
    if (state.winnerP !== MC.state.NO_WINNER) return false;
    var elig = MC.rules.replaceWindowEligibleWildLocs(state, actorP, srcSetI, excludeUid);
    if (!elig || elig.length === 0) return false;
    MC.state.setPrompt(state, {
      kind: "replaceWindow",
      p: actorP,
      srcSetI: srcSetI,
      excludeUid: excludeUid,
      resume: resume || null
    });
    return true;
  }

  function applySlySteal(fromP, target) {
    if (!(fromP === 0 || fromP === 1)) throw new Error("bad_fromP");
    if (!target || !target.loc) throw new Error("bad_target");
    var loc = target.loc;
    if (!MC.engine.locEqZone(loc, "setProps")) throw new Error("bad_loc");

    var defP = loc.p;
    var setI = loc.setI;
    var pi = loc.i;
    if (!(defP === 0 || defP === 1)) throw new Error("bad_loc");
    var setsD = state.players[defP].sets;
    if (!setsD || setI < 0 || setI >= setsD.length) throw new Error("bad_set");
    var setD = setsD[setI];
    if (!setD || !setD.props) throw new Error("bad_set");

    var props = setD.props;
    if (!props[pi] || props[pi][0] !== target.uid) throw new Error("bad_loc");

    // Sly rule: cannot steal from a complete set (including overfilled).
    var color = MC.rules.getSetColor(props);
    if (color === MC.state.NO_COLOR) throw new Error("empty_set");
    var req = MC.SET_RULES[color].requiredSize;
    if (props.length >= req) throw new Error("sly_full_set");

    // Remove from defender set.
    props.splice(pi, 1);
    cleanupEmptySetsForPlayer(defP);

    // Attacker receives the property and must place it.
    MC.state.setPrompt(state, { kind: "placeReceived", p: fromP, uids: [target.uid] });
    events.push({
      kind: "move",
      uid: target.uid,
      selectedByP: fromP,
      from: { p: defP, zone: "setProps", setI: setI, i: pi },
      to: { p: fromP, zone: "recvProps", i: 0 }
    });
    // Direction: stolen from defender -> attacker.
    events.push({ kind: "slySteal", fromP: defP, toP: fromP, uid: target.uid });
  }

  // Prompt gating: only allow prompt-appropriate commands.
  if (prompt) {
    if (prompt.kind === "discardDown") {
      if (cmd.kind === "discard") {
        applyDiscard(cmd);
        return { events: events };
      }
      if (cmd.kind === "cancelPrompt") {
        if (prompt.nDiscarded > 0) throw new Error("prompt_forced");
        MC.state.clearPrompt(state);
        return { events: events };
      }
      throw new Error("prompt_active");
    }

    function payValueForUid(uid) {
      var def = MC.state.defByUid(state, uid);
      if (def.kind === MC.CardKind.Property) return def.propertyPayValue != null ? def.propertyPayValue : 0;
      return def.bankValue != null ? def.bankValue : 0;
    }

    function applyPayDebt(cmdPay) {
      var card = cmdPay.card;
      if (!card || !card.loc) throw new Error("bad_cmd");
      var loc = card.loc;
      if (loc.p !== p) throw new Error("not_your_card");

      var uid = card.uid;
      var buf = prompt.buf;

      if (loc.zone === "bank") {
        var bi = loc.i;
        var bank = state.players[p].bank;
        if (!bank || bank[bi] !== uid) throw new Error("bad_loc");
        bank.splice(bi, 1);
      } else if (loc.zone === "setHouse") {
        var hsI = loc.setI;
        var setsH = state.players[p].sets;
        if (hsI < 0 || hsI >= setsH.length) throw new Error("bad_set");
        var setH = setsH[hsI];
        if (!setH || setH.houseUid !== uid) throw new Error("bad_loc");
        setH.houseUid = 0;
      } else if (loc.zone === "setProps") {
        var psI = loc.setI;
        var pi = loc.i;
        var setsP = state.players[p].sets;
        if (psI < 0 || psI >= setsP.length) throw new Error("bad_set");
        var setP = setsP[psI];
        if (!setP || !setP.props) throw new Error("bad_loc");
        if (setP.houseUid) throw new Error("house_pay_first");
        if (!setP.props[pi] || setP.props[pi][0] !== uid) throw new Error("bad_loc");
        setP.props.splice(pi, 1);
      } else {
        throw new Error("bad_loc");
      }

      var bufI = buf.length;
      events.push({
        kind: "move",
        uid: uid,
        selectedByP: p,
        from: card.loc,
        to: { p: p, zone: "promptBuf", i: bufI }
      });
      buf.push(uid);
      prompt.rem = prompt.rem - payValueForUid(uid);

      events.push({ kind: "payDebt", p: p, uid: uid, rem: prompt.rem, toP: prompt.toP });

      cleanupEmptySetsForPlayer(p);

      // Auto-finalize when covered or out of payables.
      if (prompt.rem > 0 && MC.state.hasAnyPayables(state, p)) return;

      var toP = prompt.toP;
      var recv = [];
      var i;
      for (i = 0; i < buf.length; i++) {
        var uidT = buf[i];
        var defT = MC.state.defByUid(state, uidT);
        if (defT && defT.kind === MC.CardKind.Property) {
          var ri = recv.length;
          recv.push(uidT);
          events.push({
            kind: "move",
            uid: uidT,
            from: { p: p, zone: "promptBuf", i: i },
            to: { p: toP, zone: "recvProps", i: ri }
          });
        } else {
          state.players[toP].bank.push(uidT);
          events.push({
            kind: "move",
            uid: uidT,
            from: { p: p, zone: "promptBuf", i: i },
            to: { p: toP, zone: "bank", i: state.players[toP].bank.length - 1 }
          });
        }
      }

      if (recv.length > 0) {
        MC.state.setPrompt(state, { kind: "placeReceived", p: toP, uids: recv });
      } else {
        MC.state.clearPrompt(state);
      }
    }

    function applyPlayJustSayNo(cmdJsn) {
      var card = cmdJsn.card;
      if (!card || !card.loc) throw new Error("bad_cmd");
      if (!MC.engine.locEqZone(card.loc, "hand")) throw new Error("bad_loc");
      if (card.loc.p !== p) throw new Error("not_your_card");

      var uid = card.uid;
      var def = MC.state.defByUid(state, uid);
      if (!def || def.kind !== MC.CardKind.Action || def.actionKind !== MC.ActionKind.JustSayNo) throw new Error("not_jsn");

      MC.engine.removeHandAtLoc(state, card);
      state.discard.push(uid);
      events.push({
        kind: "move",
        uid: uid,
        from: card.loc,
        to: { zone: "discard", i: state.discard.length - 1 }
      });

      // Cancel the active prompt and report the response (single-layer only).
      var src = prompt && prompt.srcAction ? prompt.srcAction : null;
      MC.state.clearPrompt(state);
      events.push({ kind: "jsn", p: p, srcAction: src });
    }

    function applyRespondPass() {
      if (!prompt || prompt.kind !== "respondAction") throw new Error("prompt_active");
      if (!prompt.srcAction) throw new Error("bad_srcAction");
      if (String(prompt.srcAction.kind || "") !== "slyDeal") throw new Error("bad_srcAction");
      var fromP = prompt.srcAction.fromP;
      var target = prompt.target;
      MC.state.clearPrompt(state);
      applySlySteal(fromP, target);
    }

    function applyPlaceReceived(cmdProp) {
      var card = cmdProp.card;
      var dest = cmdProp.dest;
      if (!card || !card.loc || !dest) throw new Error("bad_cmd");
      if (card.loc.p !== p) throw new Error("not_your_card");
      if (!MC.engine.locEqZone(card.loc, "recvProps")) throw new Error("bad_loc");

      var ri = card.loc.i;
      var uids = prompt.uids;
      var uid = card.uid;
      if (!uids[ri] || uids[ri] !== uid) throw new Error("bad_loc");

      var def = MC.state.defByUid(state, uid);
      if (!def || def.kind !== MC.CardKind.Property) throw new Error("not_property");

      var placedColor = MC.state.NO_COLOR;
      if (MC.rules.isWildDef(def)) {
        placedColor = cmdProp.color;
        if (!MC.rules.wildAllowsColor(def, placedColor)) throw new Error("wild_color_illegal");
      } else {
        placedColor = def.propertyColor;
      }

      // Remove from received buffer.
      uids.splice(ri, 1);

      var sets = state.players[p].sets;
      var setI;
      if (dest.newSet) {
        var newSet = MC.state.newEmptySet();
        setI = sets.length;
        sets.push(newSet);
        events.push({ kind: "createSet", p: p, setI: setI, color: placedColor });
      } else {
        setI = dest.setI;
        if (setI < 0 || setI >= sets.length) throw new Error("bad_set");
        var setExisting = sets[setI];
        var setColor = MC.rules.getSetColor(setExisting.props);
        if (setColor === MC.state.NO_COLOR) throw new Error("empty_set");
        if (setColor !== placedColor) throw new Error("set_color_mismatch");
      }

      var setT = sets[setI];
      setT.props.push([uid, placedColor]);

      events.push({
        kind: "move",
        uid: uid,
        from: card.loc,
        to: { p: p, zone: "setProps", setI: setI, i: setT.props.length - 1 }
      });

      var winner = MC.rules.evaluateWin(state);
      if (winner !== MC.state.NO_WINNER) {
        state.winnerP = winner;
        events.push({ kind: "win", winnerP: winner });
        // Winner: skip replace-window and let UI suppress prompts.
        if (prompt.uids.length === 0) MC.state.clearPrompt(state);
        return;
      }

      // Offer replace-window after each received placement (then resume).
      var resume = (prompt.uids.length > 0) ? { kind: "placeReceived", uids: prompt.uids.slice() } : null;
      var started = tryBeginReplaceWindow(p, setI, uid, resume);
      if (started) return;

      if (prompt.uids.length === 0) MC.state.clearPrompt(state);
    }

    if (prompt.kind === "payDebt") {
      if (cmd.kind === "payDebt") { applyPayDebt(cmd); return { events: events }; }
      if (cmd.kind === "playJustSayNo") {
        if (!prompt.srcAction) throw new Error("no_response_window");
        if (prompt.buf && prompt.buf.length > 0) throw new Error("response_too_late");
        applyPlayJustSayNo(cmd);
        return { events: events };
      }
      throw new Error("prompt_active");
    }
    if (prompt.kind === "respondAction") {
      if (cmd.kind === "respondPass") { applyRespondPass(); return { events: events }; }
      if (cmd.kind === "playJustSayNo") { applyPlayJustSayNo(cmd); return { events: events }; }
      throw new Error("prompt_active");
    }
    if (prompt.kind === "placeReceived") {
      if (cmd.kind === "playProp") { applyPlaceReceived(cmd); return { events: events }; }
      throw new Error("prompt_active");
    }
    if (prompt.kind === "replaceWindow") {
      function resumeOrClearReplaceWindow() {
        if (prompt.resume && String(prompt.resume.kind || "") === "placeReceived") {
          MC.state.setPrompt(state, { kind: "placeReceived", p: p, uids: prompt.resume.uids.slice() });
        } else {
          MC.state.clearPrompt(state);
        }
      }

      function applySkipReplaceWindow() {
        resumeOrClearReplaceWindow();
        events.push({ kind: "replaceSkip", p: p });
      }

      function applyMoveWild(cmdMove) {
        var v = MC.rules.replaceWindowValidateMove(state, prompt, cmdMove, p);
        if (!v.ok) throw new Error(v.err);

        var uid = v.uid;
        var srcSetI = v.srcSetI;
        var pi = v.srcI;
        var destSetI = v.destSetI;
        var isNewSet = v.isNewSet;
        var placedColor = v.placedColor;

        var sets = state.players[p].sets;
        var srcSet = sets[srcSetI];

        // Apply the move (mutating state) now that validation has passed.
        srcSet.props.splice(pi, 1);
        if (isNewSet) {
          var newSet = MC.state.newEmptySet();
          sets.push(newSet);
          events.push({ kind: "createSet", p: p, setI: destSetI, color: placedColor });
        }

        var destSet = sets[destSetI];
        destSet.props.push([uid, placedColor]);
        events.push({
          kind: "moveWild",
          p: p,
          uid: uid,
          from: { p: p, zone: "setProps", setI: srcSetI, i: pi },
          to: { p: p, zone: "setProps", setI: destSetI, i: destSet.props.length - 1 },
          color: placedColor
        });

        var winner = MC.rules.evaluateWin(state);
        if (winner !== MC.state.NO_WINNER) {
          state.winnerP = winner;
          events.push({ kind: "win", winnerP: winner });
          MC.state.clearPrompt(state);
          return;
        }

        resumeOrClearReplaceWindow();
      }

      if (cmd.kind === "skipReplaceWindow") { applySkipReplaceWindow(); return { events: events }; }
      if (cmd.kind === "moveWild") { applyMoveWild(cmd); return { events: events }; }
      throw new Error("prompt_active");
    }
    throw new Error("prompt_active");
  }

  function applyBank(cmdBank) {
    var card = cmdBank.card;
    if (!card || !card.loc) throw new Error("bad_cmd");
    if (!MC.engine.locEqZone(card.loc, "hand")) throw new Error("bad_loc");
    if (card.loc.p !== p) throw new Error("not_your_card");

    var uid = card.uid;
    var def = MC.state.defByUid(state, uid);
    if (!MC.rules.isBankableDef(def)) throw new Error("not_bankable");

    MC.engine.removeHandAtLoc(state, card);
    state.players[p].bank.push(uid);

    events.push({
      kind: "move",
      uid: uid,
      from: card.loc,
      to: { p: p, zone: "bank", i: state.players[p].bank.length - 1 }
    });
    decPlays();
  }

  function applyPlayProp(cmdProp) {
    var card = cmdProp.card;
    var dest = cmdProp.dest;
    if (!card || !card.loc || !dest) throw new Error("bad_cmd");
    if (!MC.engine.locEqZone(card.loc, "hand")) throw new Error("bad_loc");
    if (card.loc.p !== p) throw new Error("not_your_card");

    var uid = card.uid;
    var def = MC.state.defByUid(state, uid);
    if (!def || def.kind !== MC.CardKind.Property) throw new Error("not_property");

    var placedColor = MC.state.NO_COLOR;
    if (MC.rules.isWildDef(def)) {
      placedColor = cmdProp.color;
      if (!MC.rules.wildAllowsColor(def, placedColor)) throw new Error("wild_color_illegal");
    } else {
      placedColor = def.propertyColor;
    }

    var sets = state.players[p].sets;
    var setI;
    if (dest.newSet) {
      var newSet = MC.state.newEmptySet();
      setI = sets.length;
      sets.push(newSet);
      events.push({ kind: "createSet", p: p, setI: setI, color: placedColor });
    } else {
      setI = dest.setI;
      if (setI < 0 || setI >= sets.length) throw new Error("bad_set");
      var setExisting = sets[setI];
      var setColor = MC.rules.getSetColor(setExisting.props);
      if (setColor === MC.state.NO_COLOR) throw new Error("empty_set");
      if (setColor !== placedColor) throw new Error("set_color_mismatch");
    }

    MC.engine.removeHandAtLoc(state, card);
    var setT = sets[setI];
    setT.props.push([uid, placedColor]);

    events.push({
      kind: "move",
      uid: uid,
      from: card.loc,
      to: { p: p, zone: "setProps", setI: setI, i: setT.props.length - 1 }
    });
    decPlays();

    var winner = MC.rules.evaluateWin(state);
    if (winner !== MC.state.NO_WINNER) {
      state.winnerP = winner;
      events.push({ kind: "win", winnerP: winner });
      return;
    }

    // Offer replace-window after each property play into a set.
    tryBeginReplaceWindow(p, setI, uid, null);
  }

  function applyPlayHouse(cmdHouse) {
    var card = cmdHouse.card;
    var dest = cmdHouse.dest;
    if (!card || !card.loc || !dest) throw new Error("bad_cmd");
    if (!MC.engine.locEqZone(card.loc, "hand")) throw new Error("bad_loc");
    if (card.loc.p !== p) throw new Error("not_your_card");

    var uid = card.uid;
    var def = MC.state.defByUid(state, uid);
    if (!def || def.kind !== MC.CardKind.House) throw new Error("not_house");

    var sets = state.players[p].sets;
    var setI = dest.setI;
    if (setI < 0 || setI >= sets.length) throw new Error("bad_set");
    var set = sets[setI];
    if (set.houseUid !== 0) throw new Error("house_already");

    var color = MC.rules.getSetColor(set.props);
    if (color === MC.state.NO_COLOR) throw new Error("empty_set");
    var req = MC.SET_RULES[color].requiredSize;
    if (set.props.length < req) throw new Error("set_not_complete");

    MC.engine.removeHandAtLoc(state, card);
    set.houseUid = uid;

    events.push({
      kind: "move",
      uid: uid,
      from: card.loc,
      to: { p: p, zone: "setHouse", setI: setI }
    });
    decPlays();
  }

  function applyPlayRent(cmdRent) {
    var card = cmdRent.card;
    if (!card || !card.loc) throw new Error("bad_cmd");
    if (!MC.engine.locEqZone(card.loc, "hand")) throw new Error("bad_loc");
    if (card.loc.p !== p) throw new Error("not_your_card");

    var uid = card.uid;
    var def = MC.state.defByUid(state, uid);
    if (!def || def.kind !== MC.CardKind.Action || def.actionKind !== MC.ActionKind.Rent) throw new Error("not_rent");

    var setI = cmdRent.setI;
    var sets = state.players[p].sets;
    if (!sets || setI < 0 || setI >= sets.length) throw new Error("bad_set");
    var set = sets[setI];
    if (!set || !set.props || set.props.length <= 0) throw new Error("empty_set");

    var color = MC.rules.getSetColor(set.props);
    if (color === MC.state.NO_COLOR) throw new Error("empty_set");

    var allowed = def.rentAllowedColors;
    if (allowed && allowed.length) {
      var ok = false;
      var ai;
      for (ai = 0; ai < allowed.length; ai++) if (allowed[ai] === color) ok = true;
      if (!ok) throw new Error("rent_color_illegal");
    }

    var amount = MC.rules.rentAmountForSet(state, p, setI);
    if (amount <= 0) throw new Error("rent_zero");

    // Discard the rent card.
    MC.engine.removeHandAtLoc(state, card);
    state.discard.push(uid);
    events.push({
      kind: "move",
      uid: uid,
      from: card.loc,
      to: { zone: "discard", i: state.discard.length - 1 }
    });
    decPlays();

    // Trigger debt prompt for the opponent (if they have payables).
    var payer = MC.rules.otherPlayer(p);
    MC.state.beginDebt(state, payer, p, amount, { kind: "rent", fromP: p, actionUid: uid });
    events.push({ kind: "rent", p: p, setI: setI, color: color, amount: amount });
  }

  function applyPlaySlyDeal(cmdSly) {
    var card = cmdSly.card;
    var target = cmdSly.target;
    if (!card || !card.loc || !target || !target.loc) throw new Error("bad_cmd");
    if (!MC.engine.locEqZone(card.loc, "hand")) throw new Error("bad_loc");
    if (card.loc.p !== p) throw new Error("not_your_card");

    var uid = card.uid;
    var def = MC.state.defByUid(state, uid);
    if (!def || def.kind !== MC.CardKind.Action || def.actionKind !== MC.ActionKind.SlyDeal) throw new Error("not_sly");

    // Validate target is opponent property.
    var otherP = MC.rules.otherPlayer(p);
    var tLoc = target.loc;
    if (!MC.engine.locEqZone(tLoc, "setProps")) throw new Error("bad_loc");
    if (tLoc.p !== otherP) throw new Error("bad_target");

    // Validate not from full set.
    var setsO = state.players[otherP].sets;
    if (!setsO || tLoc.setI < 0 || tLoc.setI >= setsO.length) throw new Error("bad_set");
    var setO = setsO[tLoc.setI];
    if (!setO || !setO.props) throw new Error("bad_set");
    var color = MC.rules.getSetColor(setO.props);
    if (color === MC.state.NO_COLOR) throw new Error("empty_set");
    var req = MC.SET_RULES[color].requiredSize;
    if (setO.props.length >= req) throw new Error("sly_full_set");
    if (!setO.props[tLoc.i] || setO.props[tLoc.i][0] !== target.uid) throw new Error("bad_loc");

    // Discard the action card.
    MC.engine.removeHandAtLoc(state, card);
    state.discard.push(uid);
    events.push({
      kind: "move",
      uid: uid,
      from: card.loc,
      to: { zone: "discard", i: state.discard.length - 1 }
    });
    decPlays();

    // If defender has JSN, open a response prompt; otherwise resolve immediately.
    var hasJsn = MC.rules.handHasActionKind(state, otherP, MC.ActionKind.JustSayNo);

    if (hasJsn) {
      MC.state.setPrompt(state, {
        kind: "respondAction",
        p: otherP,
        srcAction: { kind: "slyDeal", fromP: p, actionUid: uid },
        target: { uid: target.uid, loc: { p: tLoc.p, zone: tLoc.zone, setI: tLoc.setI, i: tLoc.i } }
      });
      events.push({ kind: "respondOffered", p: otherP, srcAction: { kind: "slyDeal", fromP: p, actionUid: uid } });
      return;
    }

    events.push({ kind: "respondSkipped", p: otherP, reason: "no_jsn", srcAction: { kind: "slyDeal", fromP: p, actionUid: uid } });
    applySlySteal(p, { uid: target.uid, loc: tLoc });
  }

  if (cmd.kind === "endTurn") {
    if (handP.length > MC.state.HAND_MAX) {
      MC.state.setPrompt(state, { kind: "discardDown", p: p });
      if (state.prompt) state.prompt.nDiscarded = 0;
      return { events: events };
    }
    applyEndTurn();
    return { events: events };
  }

  if (state.playsLeft <= 0) throw new Error("no_plays_left");

  if (cmd.kind === "bank") applyBank(cmd);
  else if (cmd.kind === "playProp") applyPlayProp(cmd);
  else if (cmd.kind === "playHouse") applyPlayHouse(cmd);
  else if (cmd.kind === "playRent") applyPlayRent(cmd);
  else if (cmd.kind === "playSlyDeal") applyPlaySlyDeal(cmd);
  else throw new Error("unknown_cmd:" + cmd.kind);

  return { events: events };
};

MC.engine._pushPlayPropMoves = function (outMoves, state, p, uid, loc, sets) {
  var def = MC.state.defByUid(state, uid);
  if (!def || def.kind !== MC.CardKind.Property) return;
  var cardRef = { uid: uid, loc: loc };

  if (MC.rules.isWildDef(def)) {
    // New set for each allowed color.
    outMoves.push({ kind: "playProp", card: cardRef, dest: { p: p, newSet: true }, color: def.wildColors[0] });
    outMoves.push({ kind: "playProp", card: cardRef, dest: { p: p, newSet: true }, color: def.wildColors[1] });
    // Existing sets that match allowed colors.
    var si;
    for (si = 0; si < sets.length; si++) {
      var set = sets[si];
      var setColor = MC.rules.getSetColor(set.props);
      if (setColor === MC.state.NO_COLOR) continue;
      if (MC.rules.wildAllowsColor(def, setColor)) {
        outMoves.push({ kind: "playProp", card: cardRef, dest: { p: p, setI: si }, color: setColor });
      }
    }
    return;
  }

  var c = def.propertyColor;
  outMoves.push({ kind: "playProp", card: cardRef, dest: { p: p, newSet: true } });
  var sj;
  for (sj = 0; sj < sets.length; sj++) {
    var setJ = sets[sj];
    var setColorJ = MC.rules.getSetColor(setJ.props);
    if (setColorJ === MC.state.NO_COLOR) continue;
    if (setColorJ === c) {
      outMoves.push({ kind: "playProp", card: cardRef, dest: { p: p, setI: sj } });
    }
  }
};

MC.engine.legalMoves = function (state) {
  if (state.winnerP !== MC.state.NO_WINNER) return [];
  if (state.prompt) {
    var pr = state.prompt;
    if (pr.kind === "discardDown") {
      var pp = pr.p;
      if (state.activeP !== pp) return [];
      var movesP = [];
      var nDiscarded = pr.nDiscarded;
      if (nDiscarded <= 0) movesP.push({ kind: "cancelPrompt" });
      var handP = state.players[pp].hand;
      var iP;
      for (iP = 0; iP < handP.length; iP++) {
        var uidP = handP[iP];
        movesP.push({ kind: "discard", card: { uid: uidP, loc: { p: pp, zone: "hand", i: iP } } });
      }
      return movesP;
    }
    if (pr.kind === "payDebt") {
      var pPay = pr.p;
      var out = [];
      var bank = state.players[pPay].bank;
      var i;
      for (i = 0; i < bank.length; i++) {
        out.push({ kind: "payDebt", card: { uid: bank[i], loc: { p: pPay, zone: "bank", i: i } } });
      }
      var sets = state.players[pPay].sets;
      var si;
      for (si = 0; si < sets.length; si++) {
        var set = sets[si];
        if (set.houseUid) out.push({ kind: "payDebt", card: { uid: set.houseUid, loc: { p: pPay, zone: "setHouse", setI: si } } });
        if (set.houseUid) continue;
        var props = set.props;
        var pi;
        for (pi = 0; pi < props.length; pi++) {
          out.push({ kind: "payDebt", card: { uid: props[pi][0], loc: { p: pPay, zone: "setProps", setI: si, i: pi } } });
        }
      }
      if (pr.srcAction && pr.buf && pr.buf.length === 0) {
        // Allow JSN response before any payment.
        var handJ = state.players[pPay].hand;
        var hj;
        for (hj = 0; hj < handJ.length; hj++) {
          var uidJ = handJ[hj];
          var defJ = MC.state.defByUid(state, uidJ);
          if (defJ && defJ.kind === MC.CardKind.Action && defJ.actionKind === MC.ActionKind.JustSayNo) {
            out.push({ kind: "playJustSayNo", card: { uid: uidJ, loc: { p: pPay, zone: "hand", i: hj } } });
          }
        }
      }
      return out;
    }
    if (pr.kind === "respondAction") {
      var pR = pr.p;
      var outR = [{ kind: "respondPass" }];
      var handR = state.players[pR].hand;
      var hr;
      for (hr = 0; hr < handR.length; hr++) {
        var uidR = handR[hr];
        var defR = MC.state.defByUid(state, uidR);
        if (defR && defR.kind === MC.CardKind.Action && defR.actionKind === MC.ActionKind.JustSayNo) {
          outR.push({ kind: "playJustSayNo", card: { uid: uidR, loc: { p: pR, zone: "hand", i: hr } } });
        }
      }
      return outR;
    }
    if (pr.kind === "placeReceived") {
      var pR = pr.p;
      var uids = pr.uids;
      var setsR = state.players[pR].sets;
      var outR = [];

      var iR;
      for (iR = 0; iR < uids.length; iR++) {
        var uidR = uids[iR];
        MC.engine._pushPlayPropMoves(outR, state, pR, uidR, { p: pR, zone: "recvProps", i: iR }, setsR);
      }
      return outR;
    }
    if (pr.kind === "replaceWindow") {
      var pW = pr.p;
      var outW = [{ kind: "skipReplaceWindow" }];
      var srcSetI = pr.srcSetI;
      var excludeUid = pr.excludeUid;
      var elig = MC.rules.replaceWindowEligibleWildLocs(state, pW, srcSetI, excludeUid);
      var iW;
      for (iW = 0; iW < elig.length; iW++) {
        var e = elig[iW];
        if (!e || !e.loc) continue;
        var uidW = e.uid;
        var defW = MC.state.defByUid(state, uidW);
        if (!MC.rules.isWildDef(defW)) continue;

        var c0 = defW.wildColors[0];
        var c1 = defW.wildColors[1];
        var cardRef = { uid: uidW, loc: e.loc };

        function pushMovesForColor(col) {
          var dests = MC.rules.replaceWindowDestinations(state, pW, srcSetI, col);
          var di;
          for (di = 0; di < dests.length; di++) {
            outW.push({ kind: "moveWild", card: cardRef, dest: dests[di], color: col });
          }
        }

        pushMovesForColor(c0);
        pushMovesForColor(c1);
      }
      return outW;
    }
    return [];
  }

  var moves = [];
  var p = state.activeP;
  var hand = state.players[p].hand;

  // End turn is always available; if hand > HAND_MAX it enters a discard-down prompt.
  moves.push({ kind: "endTurn" });

  if (state.playsLeft <= 0) return moves;

  var sets = state.players[p].sets;

  var i;
  for (i = 0; i < hand.length; i++) {
    var uid = hand[i];
    var def = MC.state.defByUid(state, uid);
    var cardRef = { uid: uid, loc: { p: p, zone: "hand", i: i } };

    if (MC.rules.isBankableDef(def)) {
      moves.push({ kind: "bank", card: cardRef });
    }

    if (def.kind === MC.CardKind.Property) {
      MC.engine._pushPlayPropMoves(moves, state, p, uid, cardRef.loc, sets);
    } else if (def.kind === MC.CardKind.House) {
      var sh;
      for (sh = 0; sh < sets.length; sh++) {
        var setH = sets[sh];
        if (setH.houseUid !== 0) continue;
        var col = MC.rules.getSetColor(setH.props);
        if (col === MC.state.NO_COLOR) continue;
        var req = MC.SET_RULES[col].requiredSize;
        if (setH.props.length >= req) {
          moves.push({ kind: "playHouse", card: cardRef, dest: { p: p, setI: sh } });
        }
      }
    } else if (def.kind === MC.CardKind.Action && def.actionKind === MC.ActionKind.Rent) {
      // Rent: one move per eligible set.
      var allowed = def.rentAllowedColors;
      var siR;
      for (siR = 0; siR < sets.length; siR++) {
        var setR = sets[siR];
        if (!setR || !setR.props || setR.props.length <= 0) continue;
        var colR = MC.rules.getSetColor(setR.props);
        if (colR === MC.state.NO_COLOR) continue;
        if (allowed && allowed.length) {
          var ok = false;
          var ai;
          for (ai = 0; ai < allowed.length; ai++) if (allowed[ai] === colR) ok = true;
          if (!ok) continue;
        }
        var amt = MC.rules.rentAmountForSet(state, p, siR);
        if (amt <= 0) continue;
        moves.push({ kind: "playRent", card: cardRef, setI: siR });
      }
    } else if (def.kind === MC.CardKind.Action && def.actionKind === MC.ActionKind.SlyDeal) {
      // Sly Deal: one move per eligible opponent property (not from complete set).
      var op = MC.rules.otherPlayer(p);
      var setsOp = state.players[op].sets;
      var siS;
      for (siS = 0; siS < setsOp.length; siS++) {
        var setS = setsOp[siS];
        if (!setS || !setS.props || setS.props.length <= 0) continue;
        var colS = MC.rules.getSetColor(setS.props);
        if (colS === MC.state.NO_COLOR) continue;
        var reqS = MC.SET_RULES[colS].requiredSize;
        if (setS.props.length >= reqS) continue;
        var piS;
        for (piS = 0; piS < setS.props.length; piS++) {
          moves.push({
            kind: "playSlyDeal",
            card: cardRef,
            target: { uid: setS.props[piS][0], loc: { p: op, zone: "setProps", setI: siS, i: piS } }
          });
        }
      }
    }
  }

  return moves;
};

