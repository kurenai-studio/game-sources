using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room24
    {
        public const string Id = "2-4";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Toll Boundary",
                "A total of exactly 100 gets no discount. 99 and 101 act as expected.",
                "A total of 100 or more gets the discount.",
                Lines("bool discount = total > 100;"),
                string.Empty,
                Check(">", false),
                new PredictQuestion(
                    "What does this print?",
                    new[] { "True", "False", "100", "A crash" },
                    1,
                    "total > 100 asks for MORE than 100. Exactly 100 is not more, so the answer is False."),
                new[]
                {
                    new Hypothesis("total is the wrong number.", Verdict.Wrong,
                        "total is 100, just as the ticket says."),
                    new Hypothesis("The check is too strict.", Verdict.Close,
                        "Yes, but how? Compare the sign on line 2 with the goal."),
                    new Hypothesis("> leaves out exactly 100. The rule says 100 or more.", Verdict.Correct,
                        "Yes. > means more than. >= means more than or equal.")
                },
                new[]
                {
                    new FixOption("Change line 2 to: bool discount = total >= 100;", FixQuality.Best,
                        Lines("bool discount = total >= 100;"),
                        Check(">=", true),
                        "Test passed: 99 is False, 100 is True, 101 is True."),
                    new FixOption("Change line 2 to: bool discount = true;", FixQuality.SymptomOnly,
                        Lines("bool discount = true;"),
                        AlwaysTrue(),
                        "Test failed: 100 gets the discount, but 99 would get it too."),
                    new FixOption("Change line 2 to: bool discount = total < 100;", FixQuality.Wrong,
                        Lines("bool discount = total < 100;"),
                        Check("<", false),
                        "Test failed: 100 still gets no discount, and 99 now does.")
                },
                "Assert.AreEqual(\"True\", output); // also test 99 and 101",
                new[]
                {
                    "Does the rule include exactly 100?",
                    "\"100 or more\" includes 100. total > 100 does not.",
                    "Use >= so that 100 counts."
                },
                "Always test the three numbers around a limit: 99, 100 and 101. > leaves the limit out, >= keeps it. At work: fare and discount rules (student, PWD, senior) break exactly at the boundary.",
                "Investigate: is 100 more than 100?",
                "Why does 100 get no discount?");
        }

        static string[] Lines(string line2) =>
            new[] { "int total = 100;", line2, "Console.WriteLine(discount);" };

        static List<TraceEvent> Check(string op, bool result)
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.IntSet(1, "total", 100),
                TraceEvent.LineExecuted(2),
                TraceEvent.Evaluated(2, $"100 {op} 100", result),
                TraceEvent.BoolSet(2, "discount", result),
                TraceEvent.LineExecuted(3),
                TraceEvent.OutputAppended(3, result ? "True" : "False")
            };
        }

        static List<TraceEvent> AlwaysTrue()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.IntSet(1, "total", 100),
                TraceEvent.LineExecuted(2),
                TraceEvent.BoolSet(2, "discount", true),
                TraceEvent.LineExecuted(3),
                TraceEvent.OutputAppended(3, "True")
            };
        }
    }
}
