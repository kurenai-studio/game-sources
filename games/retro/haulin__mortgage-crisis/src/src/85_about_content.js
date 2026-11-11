// About screen content.
// Intended workflow: humans edit strings.
(function initAboutContent() {
  var A = MC.about;
  var ver = MC.config.meta.version;

  A.CONTENT = {
    pages: [
      {
        id: "about",
        title: "",
        blocks: [
          { kind: "h", text: "Mortgage Crisis - <c4>" + ver + "</c>" },
          { kind: "p", text: "Collect <c4>3</c> complete property sets to win." },
          { kind: "p", text: "Inspired by Monopoly Deal (Hasbro).\nNot affiliated with Hasbro." },

          { kind: "p", text: "This is a demo. The full version will add:" },
          {
            kind: "bullets",
            items: [
              "over 100 cards (demo has 42)",
              "smarter AI",
              "music",
              "rules variants",
              "more polish"
            ]
          },

          { kind: "h", text: "Play in browser" },
          { kind: "p", text: "TIC-80: <c4>tic80.com/play?cart=4646</c>" },

          { kind: "h", text: "Downloads & feedback" },
          { kind: "p", text:
            "itch.io: <c4>haulin.itch.io/mortgage-crisis</c>\n" +
            "GitHub: <c4>github.com/haulin/mortgage-crisis</c>"
          },

          { kind: "h", text: "Credits" },
          { kind: "p", text:
            "Design & code: <c4>haulin</c>\n" +
            "AI pair programmers: Claude 4.6, GPT-5.2\n" +
            "Built on TIC-80 fantasy console.\n" +
            "MIT License"
          }
        ]
      }
    ]
  };
})();

