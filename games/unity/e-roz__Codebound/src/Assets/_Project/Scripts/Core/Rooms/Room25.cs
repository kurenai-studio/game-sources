using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room25
    {
        public const string Id = "2-5";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Split Treasure",
                "7 coins split between 2 guards. Each guard gets 3, and one coin vanishes.",
                "Share 7 coins between 2 guards. No coin may vanish.",
                Lines("int coins = 7;", "var share = coins / guards;"),
                string.Empty,
                Split("3"),
                new PredictQuestion(
                    "What does this print?",
                    new[] { "3.5", "3", "4", "A crash" },
                    1,
                    "coins and guards are both int. int divided by int gives an int, so 7 / 2 is 3. The .5 is dropped."),
                new[]
                {
                    new Hypothesis("7 is odd, so the program breaks.", Verdict.Wrong,
                        "It did not break. It ran and printed 3."),
                    new Hypothesis("The answer gets rounded.", Verdict.Close,
                        "Yes, but why? Look at the types on lines 1 and 2."),
                    new Hypothesis("int divided by int has no decimals, so the .5 is dropped.", Verdict.Correct,
                        "Yes. Whole-number division throws the remainder away.")
                },
                new[]
                {
                    new FixOption("Change line 1 to: decimal coins = 7;", FixQuality.Best,
                        Lines("decimal coins = 7;", "var share = coins / guards;"),
                        Split("3.5"),
                        "Test passed: each guard gets 3.5."),
                    new FixOption("Change line 1 to: double coins = 7;", FixQuality.SymptomOnly,
                        Lines("double coins = 7;", "var share = coins / guards;"),
                        Split("3.5"),
                        "Test failed: 3.5 is right here, but double drifts on money (0.1 + 0.2 is not 0.3). Use decimal."),
                    new FixOption("Change line 3 to: var share = coins / guards + 1;", FixQuality.Wrong,
                        Lines("int coins = 7;", "var share = coins / guards + 1;"),
                        Split("4"),
                        "Test failed: 4 is too many. Two guards would get 8 coins.")
                },
                "Assert.AreEqual(3.5m, share);",
                new[]
                {
                    "What type is coins? What type is guards?",
                    "int divided by int gives an int. 7 / 2 is 3.",
                    "Make coins a decimal so the division keeps the .5."
                },
                "int / int drops the decimals. For money use decimal, not double. Also check that guards is not 0 first: dividing an int by 0 crashes. At work: e-wallet and payroll rounding errors.",
                "Investigate: what type is coins / guards?",
                "Why does a coin vanish?");
        }

        static string[] Lines(string line1, string line3) =>
            new[] { line1, "int guards = 2;", line3, "Console.WriteLine(share);" };

        static List<TraceEvent> Split(string share)
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.TextSet(1, "coins", "7"),
                TraceEvent.LineExecuted(2),
                TraceEvent.TextSet(2, "guards", "2"),
                TraceEvent.LineExecuted(3),
                TraceEvent.TextSet(3, "share", share),
                TraceEvent.LineExecuted(4),
                TraceEvent.OutputAppended(4, share)
            };
        }
    }
}
