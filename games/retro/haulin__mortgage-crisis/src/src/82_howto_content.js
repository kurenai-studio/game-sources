// How-to-Play content.
// Intended workflow: humans edit strings; small demo draw() blocks are optional.
(function initHowtoContent() {
  var H = MC.howto;

  function demoTwoCards(idA, idB, dx) {
    dx = dx || 20;
    return function (ctx) {
      H.drawMiniCardById(idA, ctx.x, ctx.y);
      H.drawMiniCardById(idB, ctx.x + dx, ctx.y);
    };
  }

  function shadowBarAt(xFace, yFace) {
    var L = MC.config.render.layout;
    var S = MC.config.render.style;
    rect(xFace + L.shadowBarDx, yFace, 1, L.faceH, S.colShadow);
  }

  H.CONTENT = {
    pages: [
      {
        id: "quickStart",
        title: "Quick Start",
        blocks: [
          { kind: "h", text: "Goal" },
          {
            kind: "p",
            text:
              "Be the first player to complete <c4>3</c> property <c4>sets</c>. A set is complete when it has the required number of properties (2, 3, or 4 depending on the color).",
            demo: { layout: "left", w: 30, h: 25, draw: function(ctx) {
              var L = MC.config.render.layout;
              var dx = L.stackStrideX;
              demoTwoCards("wild_cb", "prop_cyan", dx)(ctx);
              shadowBarAt(ctx.x + dx, ctx.y);
            }}
          },

          { kind: "h", text: "On your turn" },
          {
            kind: "bullets",
            items: [
              "<c4>Draw 2</c> cards (or <c4>5</c> if you start the turn with an empty hand).",
              "<c4>Play</c> up to <c4>3</c> cards.",
              "End your turn. If you have more than <c4>7</c> cards, you must <c4>discard</c> down."
            ]
          },

          { kind: "h", text: "Quick tips" },
          {
            kind: "bullets",
            items: [
              "<c4>Tap A</c> on a hand card to see what it can do right now.",
              "<c4>Hold X</c> to Inspect the selected card to learn about its properties and effects.",
              "If you owe money, you choose what to pay with (from your <c4>Bank</c> and your <c4>Properties</c>).",
              "The value of every card is shown in the top left corner."
            ]
          }
        ]
      },

      {
        id: "controls",
        title: "Controls",
        blocks: [
          { kind: "h", text: "Basics" },
          {
            kind: "bullets",
            items: [
              "<c4>D-pad</c>: move selection (cursor).",
              "<c4>A (tap)</c>: open a card menu / confirm a choice.",
              "<c4>A (hold)</c>: enter quick play (use D-pad to cycle options, release A confirms).",
              "<c4>B</c>: back / cancel (when allowed).",
              "<c4>X (hold)</c>: Inspect cards, buttons, deck for more information.",
              "Similarly with <c12>keyboard</c>, use <c4>arrow keys</c> for navigation, <c4>Z</c4> for action/confirm, <c4>X</c4> for back/cancel, and <c4>A</c4> for inspect."
            ],
            demo: { layout: "left", w: 37, h: 37, draw: function (ctx) {
              // Tiny button legend mock.
              rectb(ctx.x + 13, ctx.y, 11, 11, MC.Pal.Grey);
              print("Y", ctx.x + 16, ctx.y + 3, MC.Pal.LightGrey);

              rectb(ctx.x, ctx.y + 13, 11, 11, MC.Pal.Grey);
              print("X", ctx.x + 3, ctx.y + 16, MC.Pal.Cyan);

              rectb(ctx.x + 26, ctx.y + 13, 11, 11, MC.Pal.Grey);
              print("B", ctx.x + 29, ctx.y + 16, MC.Pal.Red);

              rectb(ctx.x + 13, ctx.y + 26, 11, 11, MC.Pal.Grey);
              print("A", ctx.x + 16, ctx.y + 29, MC.Pal.Yellow);
            } }
          },

          { kind: "h", text: "Mouse" },
          {
            kind: "bullets",
            items: [
              "<c4>Hover</c>: move selection (cursor).",
              "<c4>Left click</c>: open a card menu / confirm a choice.",
              "<c4>Left drag</c>: drag a card to a destination (drop confirms).",
              "<c4>Right click</c>: back / cancel (when allowed).",
              "<c4>Middle click (hold)</c>: Inspect.",
              "<c4>Wheel</c>: move selection up/down."
            ]
          },

          { kind: "h", text: "Menus and targeting" },
          {
            kind: "p",
            text:
              "Most actions start from the card menu (tap <c4>A</c> on a hand card).\n" +
              "If an action needs a destination/target, you enter targeting and cycle options with <c4>L/R</c>."
          }
        ]
      },

      {
        id: "details",
        title: "Details",
        blocks: [
          { kind: "h", text: "Cards (what they do)" },
          {
            kind: "bullets",
            items: [
              "<c12>1</c> - <c4>Money</c>: bank it as cash, or spend it to pay debts.",
              "<c12>2</c> - <c4>Properties</c>: place into sets on your table. (Not bankable.)",
              "<c12>3</c> - <c4>Wild</c>: a property that can be used as either color.",
              "<c12>4</c> - <c4>Rent</c>: charge rent for one of your sets that matches the color bars (opponent must pay).",
              "<c12>5</c> - <c4>Sly Deal</c>: steal one opponent property (not from a complete set).",
              "<c12>6</c> - <c4>Just Say No</c>: cancel an action played against you.",
              "<c4>Banking action cards</c>: action cards can be banked for money. Once banked, they count as money only for the rest of the game (you can't play them as actions)."
            ],
            demo: { layout: "above", w: 150, h: 25, draw: function (ctx) {
              var dx = 0
              print("1", ctx.x + dx,  ctx.y + 0, MC.Pal.White, true, 1, true);
              H.drawMiniCardById("money_1", ctx.x + dx + 6, ctx.y);
              dx += 26;
              print("2", ctx.x + dx, ctx.y + 0, MC.Pal.White, true, 1, true);
              H.drawMiniCardById("prop_orange", ctx.x + dx + 6, ctx.y);
              dx += 26;
              print("3", ctx.x + dx, ctx.y + 0, MC.Pal.White, true, 1, true);
              H.drawMiniCardById("wild_mo", ctx.x + dx + 6, ctx.y);
              dx += 26;
              print("4", ctx.x + dx, ctx.y + 0, MC.Pal.White, true, 1, true);
              H.drawMiniCardById("rent_mo", ctx.x + dx + 6, ctx.y);
              dx += 26;
              print("5", ctx.x + dx, ctx.y + 0, MC.Pal.White, true, 1, true);
              H.drawMiniCardById("sly_deal", ctx.x + dx + 6, ctx.y);
              dx += 26;
              print("6", ctx.x + dx,ctx.y + 0, MC.Pal.White, true, 1, true);
              H.drawMiniCardById("just_say_no", ctx.x + dx + 6, ctx.y);
            } }  
          },
          { kind: "h", text: "Paying a debt" },
          {
            kind: "p",
            text:
              "When you owe money (for example, Rent), you must pay until the debt is covered.\n" +
              "Navigate to a payable card and press <c4>A</c> to pay it.",
            demo: { layout: "left", w: 40, h: 25, draw: demoTwoCards("money_2", "prop_black", 20) }
          },
          {
            kind: "bullets",
            items: [
              "You can pay using cards from your <c4>Bank</c> and <c4>Properties</c> (not from hand).",
              "If you pay with a <c4>Property</c>, the opponent receives it and must place it.",
              "If a set has a <c4>House</c>, that House must be paid first before properties from that set.",
              "Overpay is allowed. <c4>No change</c> is returned.",
              "<c4>Rent</c> is capped once a set is complete - extra properties don't raise it."
            ]
          },

          { kind: "h", text: "Placing received properties" },
          {
            kind: "p",
            text:
              "When you receive properties as payment, you place them one-by-one into your sets.\n" +
              "Wild properties let you pick which color they count as while placing.",
          },

          { kind: "h", text: "Wild move (optional prompt)" },
          {
            kind: "p",
            text:
              "After some property placements, the game may offer a one-time option to move a Wild.\n" +
              "Press <c4>A</c> to move it, or <c4>B</c> to skip.",
          },

          { kind: "h", text: "Just Say No windows" },
          {
            kind: "p",
            text:
              "If you have a Just Say No in hand, you can use it when an action targets you.\n" +
              "Important: for action-sourced debts, JSN is only allowed before any payment is made."
          }
        ]
      }
    ]
  };
})();

