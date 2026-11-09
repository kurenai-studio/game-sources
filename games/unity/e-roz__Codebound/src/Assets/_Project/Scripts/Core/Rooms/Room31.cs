using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room31
    {
        public const string Id = "3-1";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Healer Machine",
                "Heal() adds 20, yet the guard's hp does not change.",
                "After healing, hp must be 70.",
                Lines("Heal(hp);", "Console.WriteLine(hp);"),
                string.Empty,
                Run("Heal(hp);"),
                new PredictQuestion(
                    "What does this print?",
                    new[] { "70", "50", "20", "A crash" },
                    1,
                    "Heal returns 70, but line 6 does nothing with it. hp is a separate number, so it is still 50."),
                new[]
                {
                    new Hypothesis("Heal adds the wrong amount.", Verdict.Wrong,
                        "Refuted. Heal(50) returns 70, which is right."),
                    new Hypothesis("Heal does not change hp.", Verdict.Close,
                        "Partly confirmed. True, but why? What does Heal do with its answer?"),
                    new Hypothesis("Heal returns 70, but nothing keeps the result, so hp stays 50.", Verdict.Correct,
                        "Confirmed. A method hands back a value. You must store it.")
                },
                new[]
                {
                    new FixOption("Change line 6 to: hp = Heal(hp);", FixQuality.Best,
                        Lines("hp = Heal(hp);", "Console.WriteLine(hp);"),
                        Keep(),
                        "Test passed: hp is 70."),
                    new FixOption("Change line 7 to: Console.WriteLine(Heal(hp));", FixQuality.SymptomOnly,
                        Lines("Heal(hp);", "Console.WriteLine(Heal(hp));"),
                        PrintOnly(),
                        "Test failed: it prints 70, but hp is still 50 afterwards."),
                    new FixOption("Change line 6 to: Heal(hp + 20);", FixQuality.Wrong,
                        Lines("Heal(hp + 20);", "Console.WriteLine(hp);"),
                        Run("Heal(hp + 20);"),
                        "Test failed: hp is still 50. The result is still thrown away.")
                },
                "Assert.AreEqual(70, hp);",
                new[]
                {
                    "Heal itself is fine. Look at line 6.",
                    "Heal returns a number. Where does that number go?",
                    "Store it: hp = Heal(hp);"
                },
                "A method that returns a value does not change your variable. Store the result. At work: ignoring a return value is a quiet bug when you read code you did not write.",
                "Investigate: what does Heal(hp) hand back?",
                "Why does hp stay 50?");
        }

        static string[] Lines(string line6, string line7) =>
            new[] { "int Heal(int hp)", "{", "    return hp + 20;", "}", "int hp = 50;", line6, line7 };

        // The caller ignores the result, so hp stays 50.
        static List<TraceEvent> Run(string callLine)
        {
            var amount = callLine.Contains("+ 20") ? 70 : 50;
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(5),
                TraceEvent.IntSet(5, "hp", 50),
                TraceEvent.LineExecuted(6),
                TraceEvent.LineExecuted(3),
                TraceEvent.CallReturned(3, $"Heal({amount})", $"{amount + 20}"),
                TraceEvent.LineExecuted(7),
                TraceEvent.OutputAppended(7, "50")
            };
        }

        static List<TraceEvent> Keep()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(5),
                TraceEvent.IntSet(5, "hp", 50),
                TraceEvent.LineExecuted(6),
                TraceEvent.LineExecuted(3),
                TraceEvent.CallReturned(3, "Heal(50)", "70"),
                TraceEvent.IntSet(6, "hp", 70),
                TraceEvent.LineExecuted(7),
                TraceEvent.OutputAppended(7, "70")
            };
        }

        static List<TraceEvent> PrintOnly()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(5),
                TraceEvent.IntSet(5, "hp", 50),
                TraceEvent.LineExecuted(6),
                TraceEvent.LineExecuted(3),
                TraceEvent.CallReturned(3, "Heal(50)", "70"),
                TraceEvent.LineExecuted(7),
                TraceEvent.LineExecuted(3),
                TraceEvent.CallReturned(3, "Heal(50)", "70"),
                TraceEvent.OutputAppended(7, "70")
            };
        }
    }
}
