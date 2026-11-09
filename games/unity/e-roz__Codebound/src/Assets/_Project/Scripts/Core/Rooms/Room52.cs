using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room52
    {
        public const string Id = "5-2";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Open Chest",
                "A chest shows -50 gold. Nobody can have negative gold.",
                "Gold must never go below 0.",
                new[]
                {
                    "class Chest { public int Gold; }", "var chest = new Chest();", "chest.Gold = 100;",
                    "chest.Gold -= 150;", "Console.WriteLine(chest.Gold);"
                },
                string.Empty,
                Original("-50"),
                new PredictQuestion(
                    "What does this print?",
                    new[] { "100", "-50", "0", "A crash" },
                    1,
                    "Gold is public, so line 4 can take it from 100 down to -50 and nothing stops it."),
                new[]
                {
                    new Hypothesis("Console.WriteLine prints the wrong number.", Verdict.Wrong,
                        "Refuted. The row already shows chest.Gold is -50 before printing."),
                    new Hypothesis("Something set Gold to -50.", Verdict.Close,
                        "Partly confirmed. Who is allowed to change Gold?"),
                    new Hypothesis("Gold is public, so any code can set it to any value.", Verdict.Correct,
                        "Confirmed. Nothing protects the rule.")
                },
                new[]
                {
                    new FixOption("Make gold private and change it with Spend()", FixQuality.Best,
                        new[]
                        {
                            "class Chest {", "    int gold = 100;", "    public int Gold => gold;", "    public void Spend(int n)",
                            "    { if (n <= gold) gold -= n; }", "}", "var chest = new Chest();", "chest.Spend(150);"
                        },
                        Refused(),
                        "Test passed: Spend(150) is refused and Gold stays 100."),
                    new FixOption("Check the amount before line 4", FixQuality.SymptomOnly,
                        new[]
                        {
                            "class Chest { public int Gold; }", "var chest = new Chest();", "chest.Gold = 100;",
                            "if (chest.Gold >= 150)", "    chest.Gold -= 150;", "Console.WriteLine(chest.Gold);"
                        },
                        Guarded(),
                        "Test failed: this one call is safe, but Gold is still public. Other code can still set -50."),
                    new FixOption("Print Math.Max(0, chest.Gold)", FixQuality.Wrong,
                        new[]
                        {
                            "class Chest { public int Gold; }", "var chest = new Chest();", "chest.Gold = 100;",
                            "chest.Gold -= 150;", "var g = Math.Max(0, chest.Gold);", "Console.WriteLine(g);"
                        },
                        Hidden(),
                        "Test failed: it prints 0, but chest.Gold is still -50 inside. Hiding the number fixes nothing.")
                },
                "Assert.AreEqual(100, chest.Gold); // after Spend(150)",
                new[]
                {
                    "Tala: the row shows Gold is -50 before it prints.",
                    "Tala: who may change Gold?",
                    "Tala: make the field private and check the rule in a method."
                },
                "Encapsulation: keep fields private and change them only through methods that check the rule. At work: a public field means every file in the project can break your rule.",
                "Investigate: what is chest.Gold after line 4?",
                "Why can Gold be negative?");
        }

        static List<TraceEvent> Original(string printed)
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(3),
                TraceEvent.IntSet(3, "chest.Gold", 100),
                TraceEvent.LineExecuted(4),
                TraceEvent.IntSet(4, "chest.Gold", -50),
                TraceEvent.LineExecuted(5),
                TraceEvent.OutputAppended(5, printed)
            };
        }

        static List<TraceEvent> Refused()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(7),
                TraceEvent.IntSet(2, "chest.Gold", 100),
                TraceEvent.LineExecuted(8),
                TraceEvent.LineExecuted(5),
                TraceEvent.TextSet(5, "Spend(150)", "refused, not enough Gold")
            };
        }

        static List<TraceEvent> Guarded()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(3),
                TraceEvent.IntSet(3, "chest.Gold", 100),
                TraceEvent.LineExecuted(4),
                TraceEvent.LineExecuted(6),
                TraceEvent.OutputAppended(6, "100")
            };
        }

        static List<TraceEvent> Hidden()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(3),
                TraceEvent.IntSet(3, "chest.Gold", 100),
                TraceEvent.LineExecuted(4),
                TraceEvent.IntSet(4, "chest.Gold", -50),
                TraceEvent.LineExecuted(5),
                TraceEvent.LineExecuted(6),
                TraceEvent.OutputAppended(6, "0")
            };
        }
    }
}
