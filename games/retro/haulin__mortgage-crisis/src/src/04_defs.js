// Card/game definitions: enums + static data tables (treated as read-only).
MC.Color = {
  Cyan: 0,
  Magenta: 1,
  Orange: 2,
  Black: 3,
};

MC.CardKind = {
  Money: 0,
  Action: 1,
  Property: 2,
  House: 3,
};

MC.ActionKind = {
  Rent: 0,
  SlyDeal: 1,
  JustSayNo: 2,
};

// Rule-note IDs. These are small display-only annotations in Inspect.
MC.RuleNote = {
  SlyDeal_NotFromFullSet: 1,
  House_StationsUtilities: 2,
  JSN_Chain: 3
};

// Rule note display text. These are appended in Inspect when enabled by config.
MC.ruleNoteTextById = [];
MC.ruleNoteTextById[MC.RuleNote.SlyDeal_NotFromFullSet] = "(Cannot be part of a full set)";
MC.ruleNoteTextById[MC.RuleNote.House_StationsUtilities] = "(Except stations & utilities)";
MC.ruleNoteTextById[MC.RuleNote.JSN_Chain] = "(You can say No to a No)";

MC.SET_RULES = [];
MC.SET_RULES[MC.Color.Cyan] = {
  requiredSize: 2,
  rent: [1, 3],
};
MC.SET_RULES[MC.Color.Magenta] = {
  requiredSize: 3,
  rent: [1, 2, 4],
};
MC.SET_RULES[MC.Color.Orange] = {
  requiredSize: 3,
  rent: [2, 3, 5],
};
MC.SET_RULES[MC.Color.Black] = {
  requiredSize: 4,
  rent: [1, 2, 3, 6],
};

MC.HOUSE_RENT_BONUS = 3;

MC.CARD_DEFS = [
  // Money (10)
  {
    id: "money_1",
    name: "Money",
    desc: "Spend to pay debts.\nBank as money.",
    kind: MC.CardKind.Money,
    count: 2,
    bankValue: 1,
  },
  {
    id: "money_2",
    name: "Money",
    desc: "Spend to pay debts.\nBank as money.",
    kind: MC.CardKind.Money,
    count: 2,
    bankValue: 2,
  },
  {
    id: "money_3",
    name: "Money",
    desc: "Spend to pay debts.\nBank as money.",
    kind: MC.CardKind.Money,
    count: 3,
    bankValue: 3,
  },
  {
    id: "money_4",
    name: "Money",
    desc: "Spend to pay debts.\nBank as money.",
    kind: MC.CardKind.Money,
    count: 2,
    bankValue: 4,
  },
  {
    id: "money_5",
    name: "Money",
    desc: "Spend to pay debts.\nBank as money.",
    kind: MC.CardKind.Money,
    count: 1,
    bankValue: 5,
  },

  // Properties (14 fixed + 2 wild = 16)
  {
    id: "prop_cyan",
    name: "Property Cyan",
    desc: "Full set: 2 required.\nRent for 1 property: $1\nRent for 2 properties: $3",
    kind: MC.CardKind.Property,
    count: 2,
    propertyColor: MC.Color.Cyan,
    propertyPayValue: 3,
  },
  {
    id: "prop_magenta",
    name: "Property Magenta",
    desc: "Full set: 3 required.\nRent for 1 property: $1\nRent for 2 properties: $2\nRent for 3 properties: $4",
    kind: MC.CardKind.Property,
    count: 4,
    propertyColor: MC.Color.Magenta,
    propertyPayValue: 2,
  },
  {
    id: "prop_orange",
    name: "Property Orange",
    desc: "Full set: 3 required.\nRent for 1 property: $2\nRent for 2 properties: $3\nRent for 3 properties: $5",
    kind: MC.CardKind.Property,
    count: 3,
    propertyColor: MC.Color.Orange,
    propertyPayValue: 2,
  },
  {
    id: "prop_black",
    name: "Property Black",
    desc: "Full set: 4 required.\nRent for 1 property: $1\nRent for 2 properties: $2\nRent for 3 properties: $3\nRent for 4 properties: $6",
    kind: MC.CardKind.Property,
    count: 5,
    propertyColor: MC.Color.Black,
    propertyPayValue: 1,
  },
  {
    id: "wild_mo",
    name: "Wild Magenta/Orange",
    desc: "Orange rent: $2/$3/$5\nMagenta rent: $1/$2/$4",
    kind: MC.CardKind.Property,
    count: 1,
    wildColors: [MC.Color.Magenta, MC.Color.Orange],
    propertyPayValue: 2,
  },
  {
    id: "wild_cb",
    name: "Wild Cyan/Black",
    desc: "Cyan rent: $1/$3\nBlack rent: $1/$2/$3/$6",
    kind: MC.CardKind.Property,
    count: 1,
    wildColors: [MC.Color.Cyan, MC.Color.Black],
    propertyPayValue: 2,
  },

  // Buildings (3)
  {
    id: "house",
    name: "House",
    desc: "Action card. Add onto any\nfull set you own to add\n$3 to the rent value.",
    kind: MC.CardKind.House,
    count: 3,
    bankValue: 3,
    ruleNotes: [MC.RuleNote.House_StationsUtilities]
  },

  // Actions (13)
  {
    id: "rent_mo",
    name: "Rent Magenta/Orange",
    desc: "Action card. Your opponent\npays you rent for your\nMagenta or Orange sets.\n(Play into center to use)",
    kind: MC.CardKind.Action,
    actionKind: MC.ActionKind.Rent,
    count: 3,
    bankValue: 1,
    rentAllowedColors: [MC.Color.Magenta, MC.Color.Orange],
  },
  {
    id: "rent_cb",
    name: "Rent Cyan/Black",
    desc: "Action card. Your opponent\npays you rent for your\nCyan or Black sets.\n(Play into center to use)",
    kind: MC.CardKind.Action,
    actionKind: MC.ActionKind.Rent,
    count: 3,
    bankValue: 1,
    rentAllowedColors: [MC.Color.Cyan, MC.Color.Black],
  },
  {
    id: "rent_any",
    name: "Rent Any",
    desc: "Action card. Your opponent\npays you rent for one set\nof your choice.\n(Play into center to use)",
    kind: MC.CardKind.Action,
    actionKind: MC.ActionKind.Rent,
    count: 2,
    bankValue: 2,
    rentAllowedColors: null,
  },
  {
    id: "sly_deal",
    name: "Sly Deal",
    desc: "Action card. Steal 1 property\nfrom your opponent.\n(Play into center to use)",
    kind: MC.CardKind.Action,
    actionKind: MC.ActionKind.SlyDeal,
    count: 3,
    bankValue: 3,
    ruleNotes: [MC.RuleNote.SlyDeal_NotFromFullSet]
  },
  {
    id: "just_say_no",
    name: "Just Say No",
    desc: "Action card. Use any time\nwhen an action is played\nagainst you.\n(Play into center to use)",
    kind: MC.CardKind.Action,
    actionKind: MC.ActionKind.JustSayNo,
    count: 2,
    bankValue: 4,
    ruleNotes: [MC.RuleNote.JSN_Chain]
  },
];

MC.DEF_INDEX_BY_ID = {};
(function initDefIndexById() {
  var i;
  for (i = 0; i < MC.CARD_DEFS.length; i++) {
    var id = MC.CARD_DEFS[i].id;
    if (MC.DEF_INDEX_BY_ID[id] != null) {
      throw new Error("duplicate card def id: " + id);
    }
    MC.DEF_INDEX_BY_ID[id] = i;
  }
})();
