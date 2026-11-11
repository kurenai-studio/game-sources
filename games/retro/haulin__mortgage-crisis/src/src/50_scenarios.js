// MC.scenarios: deterministic starting-state builders for testing + debug smoke runs.
MC.scenarios.resetForScenario = function (state) {
  state.deck = [];
  state.discard = [];
  state.players[0].hand = [];
  state.players[0].bank = [];
  state.players[0].sets = [];
  state.players[1].hand = [];
  state.players[1].bank = [];
  state.players[1].sets = [];
  state.activeP = 0;
  state.playsLeft = 3;
  MC.state.clearPrompt(state);
  state.winnerP = MC.state.NO_WINNER;
  // Ensure pool exists.
  MC.state.cardPoolInit(state);
};

// Scenario helpers (keep scenario bodies small/readable).
MC.scenarios.pushUids = function (state, out, defIds) {
  var i;
  for (i = 0; i < defIds.length; i++) {
    out.push(MC.state.takeUid(state, defIds[i]));
  }
};

MC.scenarios.takeUids = function (state, defIds) {
  var out = [];
  MC.scenarios.pushUids(state, out, defIds);
  return out;
};

MC.scenarios.setAddFixedProp = function (set, uid, color) {
  set.props.push([uid, color]);
};

MC.scenarios.setAddPropByDefId = function (state, set, defId, forcedColor) {
  var uid = MC.state.takeUid(state, defId);
  var def = MC.state.defByUid(state, uid);
  var color = MC.state.NO_COLOR;
  if (MC.rules.isWildDef(def)) {
    color = forcedColor;
    if (!MC.rules.wildAllowsColor(def, color)) throw new Error("scenario_bad_color:" + defId);
  } else {
    color = def.propertyColor;
  }
  MC.scenarios.setAddFixedProp(set, uid, color);
  return uid;
};

MC.scenarios.fillDeckFromPool = function (state) {
  var deck = [];
  var i;
  for (i = 0; i < MC.CARD_DEFS.length; i++) {
    var defId = MC.CARD_DEFS[i].id;
    var a = state._pool[defId];
    if (!a || a.length === 0) continue;
    var k;
    for (k = 0; k < a.length; k++) deck.push(a[k]);
    state._pool[defId] = [];
  }
  state.deck = deck;
};

MC.scenarios.applyScenario = function (state, scenarioId) {
  MC.scenarios.resetForScenario(state);

  var fn = MC.scenarios._applyById[scenarioId];
  if (!fn) throw new Error("unknown_scenario:" + scenarioId);
  fn(state);

  MC.scenarios.fillDeckFromPool(state);
  // Scenario deck policy: shuffle the remaining deck with the scenario seed so scenarios
  // feel like "real" games while still being reproducible per seed.
  // (Hands/sets/discard are scenario-curated; only the remaining deck is randomized.)
  MC.shuffle.inPlaceWithStateRng(state, state.deck);
  return state;
};

// Scenario registry (single source of truth).
MC.scenarios.IDS = [
  // Replace-window + placement basics
  "replaceWindow",
  "placeBasic",
  "wildBasic",
  "houseBasic",
  "winCheck",
  "bankScrollShuffle",
  // Prompt-driven debt + recipient placement
  "debtHouseFirst",
  "placeReceived",
  // Move generation smoke / AI policy stress
  "moveStress",
  // Screenshot/demo board
  "showcase",
  // Actions + responses
  "slyJSN",
  // Anim edge cases
  "payDebtShuffleDeal"
];

// Optional metadata for debug UI / docs.
MC.scenarios.INFO = {
  replaceWindow: { title: "Replace-window", desc: "Play into an overfill-complete set so the replace-window prompt is offered (move a Wild out of the just-played-into set)." },
  placeBasic: { title: "Place (basic)", desc: "Fixed property placement + Rent play-test (opponent has a small bank payable)." },
  wildBasic: { title: "Wild (basic)", desc: "Wild property placement + discard depth demo." },
  houseBasic: { title: "House (basic)", desc: "Build House on complete set only." },
  winCheck: { title: "Win check", desc: "Already-winning board state (game over)." },
  bankScrollShuffle: { title: "Bank+shuffle stress", desc: "Huge bank + reshuffle-on-draw stress case." },
  debtHouseFirst: { title: "Debt: house-first", desc: "Debt prompt where House must be paid before set properties (includes a JSN in hand to test action-sourced payDebt response gating)." },
  placeReceived: { title: "Place received", desc: "Faux-turn placement buffer (includes Wild color choice)." },
  moveStress: { title: "Move stress", desc: "Many partial sets + 9-card hand (props + wilds + rent-any + house) to maximize legalMoves fanout for smoke testing + AI policy tuning." },
  showcase: { title: "Showcase", desc: "Busy mid-game board for screenshots: full sets, a House bonus, a banked action, stealable vs protected properties, and a mixed hand (Rent/Sly/JSN)." },
  slyJSN: { title: "Sly+JSN+SlySingle", desc: "RespondAction prompt for Sly Deal (Allow vs Just Say No). Also includes a single-target Sly situation in parallel." },
  payDebtShuffleDeal: { title: "PayDebt shuffle deal", desc: "Repro helper: start in a rent-sourced payDebt prompt with empty hand + bank payment, then opponent is forced to endTurn and your next startTurn triggers deck reshuffle + staged deal animation." },
};

MC.scenarios._applyById = {
  replaceWindow: function (state) {
    // Source set (Orange, complete=3) includes a Wild not being played this turn.
    // Playing one more Orange into this set makes it overfilled (4), enabling replace-window:
    // moving exactly 1 Wild out still leaves the source set complete (3).
    var setSrc = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setSrc, "prop_orange", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setSrc, "prop_orange", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setSrc, "wild_mo", MC.Color.Orange);
    state.players[0].sets.push(setSrc);

    // Destination set (Magenta, 2/3) so moving the Wild as Magenta can complete it.
    var setM = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setM, "prop_magenta", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setM, "prop_magenta", MC.state.NO_COLOR);
    state.players[0].sets.push(setM);

    // Hand: play Orange into the source set to trigger replace-window.
    MC.scenarios.pushUids(state, state.players[0].hand, ["prop_orange", "money_1"]);
  },

  placeBasic: function (state) {
    // P0 has 2 orange properties + $1. P0 also has an existing Orange set with 1 property.
    var setO = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setO, "prop_orange", MC.state.NO_COLOR);
    state.players[0].sets.push(setO);

    // Hand: 2 orange properties + $1 + rent card (Magenta/Orange rent).
    MC.scenarios.pushUids(state, state.players[0].hand, ["prop_orange", "prop_orange", "money_1", "rent_mo"]);

    // Ensure opponent has something payable so Rent triggers payDebt.
    state.players[1].bank.push(MC.state.takeUid(state, "money_2"));
  },

  wildBasic: function (state) {
    // P0 has Wild(M/O) and $1.
    MC.scenarios.pushUids(state, state.players[0].hand, ["wild_mo", "money_1"]);

    // Discard demo (depth=3): top card is last.
    MC.scenarios.pushUids(state, state.discard, ["money_2", "money_1", "rent_cb"]);
  },

  houseBasic: function (state) {
    // P0 has two Houses in hand.
    MC.scenarios.pushUids(state, state.players[0].hand, ["house", "house"]);

    // One complete Cyan set (2).
    var setC = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setC, "prop_cyan", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setC, "prop_cyan", MC.state.NO_COLOR);
    state.players[0].sets.push(setC);

    // One incomplete Black set (3/4).
    var setB = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setB, "prop_black", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setB, "prop_black", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setB, "prop_black", MC.state.NO_COLOR);
    state.players[0].sets.push(setB);

    // Discard demo (depth=1).
    state.discard.push(MC.state.takeUid(state, "money_5"));
  },

  winCheck: function (state) {
    // P0 has 3 complete sets: Cyan(2), Magenta(3), Orange(3).
    var setC2 = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setC2, "prop_cyan", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setC2, "prop_cyan", MC.state.NO_COLOR);
    state.players[0].sets.push(setC2);

    var setM3 = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setM3, "prop_magenta", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setM3, "prop_magenta", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setM3, "prop_magenta", MC.state.NO_COLOR);
    state.players[0].sets.push(setM3);

    var setO3 = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setO3, "prop_orange", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setO3, "prop_orange", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setO3, "prop_orange", MC.state.NO_COLOR);
    state.players[0].sets.push(setO3);

    state.playsLeft = 0;
    state.winnerP = MC.rules.evaluateWin(state);
  },

  bankScrollShuffle: function (state) {
    // Dev scenario:
    // - P0 bank contains *all* bankable cards (money/action/house) to stress bank stack/scrolling.
    // - Most remaining cards are in discard (to stress reshuffle).
    // - Leave exactly 1 card in deck so the next draw forces a reshuffle.
    // - Ensure P1 hand is non-empty so endTurn draws 2 (not 5).

    // Seed P1 hand with 1 property so startTurn draws 2.
    state.players[1].hand.push(MC.state.takeUid(state, "prop_cyan"));

    // Drain pool: bankables -> P0 bank; non-bankables -> discard.
    var di;
    for (di = 0; di < MC.CARD_DEFS.length; di++) {
      var def = MC.CARD_DEFS[di];
      if (!def || !def.id) continue;
      var defId = def.id;
      var a = state._pool[defId];
      if (!a || a.length === 0) continue;

      // NOTE: scenario pool contains only uids, so we inspect the def kind here.
      var bankable = MC.rules.isBankableDef(def);
      while (a.length > 0) {
        var uid = a.pop();
        if (bankable) state.players[0].bank.push(uid);
        else state.discard.push(uid);
      }
    }

    // Put back one card into the pool so it becomes the (1-card) deck.
    // Prefer taking from discard so the discard->deck reshuffle still has plenty of cards.
    if (state.discard.length > 0) {
      var keepUid = state.discard.pop();
      var keepDef = MC.state.defByUid(state, keepUid);
      var keepId = String(keepDef.id);
      state._pool[keepId].push(keepUid);
    }

    // Keep hand small and end-turn legal.
    state.players[0].hand = [];
    state.activeP = 0;
    state.playsLeft = 0;
    state.winnerP = MC.state.NO_WINNER;
  },

  // Goal: exercise prompt actor separation + house-first redirect + overpay allowed.
  debtHouseFirst: function (state) {
    // P0: complete Cyan set with a House.
    var setC = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setC, "prop_cyan", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setC, "prop_cyan", MC.state.NO_COLOR);
    setC.houseUid = MC.state.takeUid(state, "house");
    state.players[0].sets.push(setC);

    // Keep bank empty so the only payable is the House (forces the rule).
    state.players[0].bank = [];

    // Add a little hand so the UI isn't empty.
    MC.scenarios.pushUids(state, state.players[0].hand, ["rent_cb", "just_say_no"]);

    // Pay a small debt to P1; paying the House overpays and resolves immediately.
    var rentUid = MC.state.takeUid(state, "rent_any");
    state.discard.push(rentUid);
    MC.state.setPrompt(state, { kind: "payDebt", p: 0, toP: 1, rem: 1, buf: [], srcAction: { kind: "rent", fromP: 1, actionUid: rentUid } });
  },

  placeReceived: function (state) {
    // P0 has an existing Orange set to allow placing into existing sets.
    var setO = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setO, "prop_orange", MC.state.NO_COLOR);
    state.players[0].sets.push(setO);

    // Prompt buffer: one fixed property + one Wild to place (wild assignment chosen during placement).
    var recv = MC.scenarios.takeUids(state, ["prop_orange", "wild_mo"]);
    MC.state.setPrompt(state, { kind: "placeReceived", p: 0, uids: recv });

    // Keep normal hand visible for the “faux-hand + real hand” row layout.
    MC.scenarios.pushUids(state, state.players[0].hand, ["money_1", "rent_mo"]);
  },

  moveStress: function (state) {
    // Board: P0 has many partial sets so properties/wilds have multiple existing destinations.
    // Hand: 9 cards including wilds + rent-any + house, so move list gets large.
    //
    // Note: hand > HAND_MAX is intentional; endTurn will enter discardDown prompt.

    // 1 complete Cyan set (2) so House has at least one legal build target.
    var setC = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setC, "prop_cyan", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setC, "prop_cyan", MC.state.NO_COLOR);
    state.players[0].sets.push(setC);

    // Opponent has at least one stealable property so Sly Deal has targets.
    // Prefer an Orange-ish pair (incomplete set) so Sly targeting can cycle more than one option.
    // (Orange set requires 3, so 2 cards stays stealable.)
    var setOp = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setOp, "wild_mo", MC.Color.Orange);
    MC.scenarios.setAddPropByDefId(state, setOp, "prop_orange", MC.state.NO_COLOR);
    state.players[1].sets.push(setOp);

    // 2 Magenta sets (each 1 prop) so Magenta + wild_mo can target multiple existing sets.
    var setM0 = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setM0, "prop_magenta", MC.state.NO_COLOR);
    state.players[0].sets.push(setM0);
    var setM1 = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setM1, "prop_magenta", MC.state.NO_COLOR);
    state.players[0].sets.push(setM1);

    // 2 Orange sets (each 1 prop) so Orange + wild_mo can target multiple existing sets.
    var setO0 = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setO0, "prop_orange", MC.state.NO_COLOR);
    state.players[0].sets.push(setO0);
    var setO1 = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setO1, "prop_orange", MC.state.NO_COLOR);
    state.players[0].sets.push(setO1);

    // 3 Black sets (each 1 prop) so Black + wild_cb can target multiple existing sets.
    var setB0 = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setB0, "prop_black", MC.state.NO_COLOR);
    state.players[0].sets.push(setB0);
    var setB1 = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setB1, "prop_black", MC.state.NO_COLOR);
    state.players[0].sets.push(setB1);
    var setB2 = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setB2, "prop_black", MC.state.NO_COLOR);
    state.players[0].sets.push(setB2);

    // Hand: one of each base property (remaining), one wild, plus rent-any + house + $1 + one action.
    // Keep Orange out of hand here so we can use it for opponent Sly targets above.
    MC.scenarios.pushUids(state, state.players[0].hand, [
      "prop_magenta",
      "money_2",
      "prop_black",
      "wild_cb",
      "house",
      "rent_any",
      "money_1",
      "sly_deal"
    ]);
  },

  showcase: function (state) {
    // Player board:
    // - Cyan full (2)
    // - Magenta full (3) + House
    // - Orange partial (2/3)
    // - Black partial (2/4) using wild_cb as Black
    var p0 = state.players[0];
    var p1 = state.players[1];

    var setC = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setC, "prop_cyan", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setC, "prop_cyan", MC.state.NO_COLOR);
    p0.sets.push(setC);

    var setM = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setM, "prop_magenta", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setM, "prop_magenta", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setM, "prop_magenta", MC.state.NO_COLOR);
    setM.houseUid = MC.state.takeUid(state, "house");
    p0.sets.push(setM);

    var setO = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setO, "prop_orange", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setO, "prop_orange", MC.state.NO_COLOR);
    p0.sets.push(setO);

    var setB = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setB, "prop_black", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setB, "wild_cb", MC.Color.Black);
    p0.sets.push(setB);

    // Opponent board:
    // - Black full (protected from Sly)
    // - Magenta 1/3 (stealable)
    var setB1 = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setB1, "prop_black", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setB1, "prop_black", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setB1, "prop_black", MC.state.NO_COLOR);
    MC.scenarios.setAddPropByDefId(state, setB1, "prop_black", MC.state.NO_COLOR);
    p1.sets.push(setB1);

    var setM1 = MC.state.newEmptySet();
    MC.scenarios.setAddPropByDefId(state, setM1, "prop_magenta", MC.state.NO_COLOR);
    p1.sets.push(setM1);

    // Bank: include at least one banked action.
    MC.scenarios.pushUids(state, p0.bank, ["rent_cb", "money_2", "money_4"]);
    MC.scenarios.pushUids(state, p1.bank, ["money_1", "rent_mo", "money_3"]);

    // Hand (7), with Rent Any at index 2 for nicer screenshots.
    MC.scenarios.pushUids(state, p0.hand, ["sly_deal", "just_say_no", "rent_any", "wild_mo", "prop_orange", "money_5", "house"]);

    // Opponent hand: keep it non-empty / busy.
    MC.scenarios.pushUids(state, p1.hand, ["money_4", "sly_deal", "rent_cb", "money_2"]);

    // Discard demo (depth=4): top card is last.
    MC.scenarios.pushUids(state, state.discard, ["money_1", "rent_mo", "money_3", "sly_deal"]);
  },

  slyJSN: function (state) {
    // P0 has a stealable (incomplete) set with a single property.
    var setO = MC.state.newEmptySet();
    var uidT = MC.state.takeUid(state, "prop_orange");
    MC.scenarios.setAddFixedProp(setO, uidT, MC.Color.Orange);
    state.players[0].sets.push(setO);

    // P0 has JSN in hand to respond with.
    MC.scenarios.pushUids(state, state.players[0].hand, ["just_say_no", "money_1"]);

    // Opponent played Sly Deal; the action card is already discarded.
    var slyUid = MC.state.takeUid(state, "sly_deal");
    state.discard.push(slyUid);

    // Also include a single-target Sly situation in parallel (for debugging menu behavior after the prompt):
    // P0 has a Sly Deal in hand, and P1 has exactly one eligible property on the table.
    state.players[0].hand.push(MC.state.takeUid(state, "sly_deal"));
    var setM = MC.state.newEmptySet();
    var uidM = MC.state.takeUid(state, "prop_magenta");
    MC.scenarios.setAddFixedProp(setM, uidM, MC.Color.Magenta);
    state.players[1].sets.push(setM);

    MC.state.setPrompt(state, {
      kind: "respondAction",
      p: 0,
      srcAction: { kind: "slyDeal", fromP: 1, actionUid: slyUid },
      target: { uid: uidT, loc: { p: 0, zone: "setProps", setI: 0, i: 0 } }
    });

    state.activeP = 1;
    state.playsLeft = 3;
  },

  payDebtShuffleDeal: function (state) {
    // Start in a payDebt prompt (rent-sourced). After payment, opponent has playsLeft=0
    // so the AI will immediately endTurn; the next startTurn draws with reshuffle+deal.
    state.activeP = 1;
    state.playsLeft = 0;

    // P0 has an empty hand and a single payable bank card to cover the debt.
    var payUid = MC.state.takeUid(state, "money_1");
    state.players[0].bank.push(payUid);

    // Put enough cards into discard so startTurn draw(5) must reshuffle from discard.
    // Include a rent card uid so srcAction can reference a real uid in discard.
    var rentUid = MC.state.takeUid(state, "rent_mo");
    state.discard.push(rentUid);
    state.discard.push(MC.state.takeUid(state, "money_2"));
    state.discard.push(MC.state.takeUid(state, "money_3"));
    state.discard.push(MC.state.takeUid(state, "prop_orange"));
    state.discard.push(MC.state.takeUid(state, "prop_magenta"));
    state.discard.push(MC.state.takeUid(state, "wild_mo"));

    // Open the debt prompt for P0 (payer). activeP remains the opponent (rent actor),
    // matching real gameplay: the prompt actor is prompt.p.
    MC.state.setPrompt(state, {
      kind: "payDebt",
      p: 0,
      toP: 1,
      rem: 1,
      buf: [],
      srcAction: { kind: "rent", fromP: 1, actionUid: rentUid }
    });

    // Ensure no additional pool cards get moved into deck by the scenario framework.
    // (We want deck empty so reshuffle is guaranteed.)
    var defId;
    for (defId in state._pool) state._pool[defId] = [];
  }
};

