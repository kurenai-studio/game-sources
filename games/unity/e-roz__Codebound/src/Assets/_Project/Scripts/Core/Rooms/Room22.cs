using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room22
    {
        public const string Id = "2-2";

        static readonly string[] Guards = { "Thea", "Jean", "Coco" };

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Last Guard",
                "The roll call calls all three guards, then crashes.",
                "Call every guard once. Never go past the last one.",
                Lines("int n = g.Length;", "for (int i = 0; i <= n; i++)"),
                string.Empty,
                Roll(3, 0, true),
                new PredictQuestion(
                    "What happens when this runs?",
                    new[] { "It prints 3 names", "3 names, then a crash", "A crash, no names", "Nothing" },
                    1,
                    "The names print fine for i = 0, 1, 2. Then i becomes 3, and slot 3 does not exist."),
                new[]
                {
                    new Hypothesis("g is empty.", Verdict.Wrong,
                        "g holds three guards. It printed them."),
                    new Hypothesis("The loop runs one time too many.", Verdict.Close,
                        "Yes, but why? Look at the condition on line 3."),
                    new Hypothesis("i <= n lets i reach 3, but the last slot is 2.", Verdict.Correct,
                        "Yes. Slots are 0, 1, 2. Slot 3 does not exist.")
                },
                new[]
                {
                    new FixOption("Change line 3 to: for (int i = 0; i < n; i++)", FixQuality.Best,
                        Lines("int n = g.Length;", "for (int i = 0; i < n; i++)"),
                        Roll(3, 0, false),
                        "Test passed: Thea, Jean, Coco. No crash."),
                    new FixOption("Change line 2 to: int n = 2;", FixQuality.SymptomOnly,
                        Lines("int n = 2;", "for (int i = 0; i <= n; i++)"),
                        Roll(2, 0, true),
                        "Test failed: it works for 3 guards, but with 4 guards the last guard would be skipped."),
                    new FixOption("Change line 3 to: for (int i = 1; i <= n; i++)", FixQuality.Wrong,
                        Lines("int n = g.Length;", "for (int i = 1; i <= n; i++)"),
                        Roll(3, 1, true),
                        "Test failed: Thea is skipped and it still crashes.")
                },
                "Assert.AreEqual(\"Thea, Jean, Coco\", output); // and again with 4 guards",
                new[]
                {
                    "What is the last slot number of g?",
                    "g has 3 guards, so its slots are 0, 1, 2.",
                    "<= lets i reach 3. Use < instead."
                },
                "Slots are counted from 0, so the last slot is Length - 1. Use i < Length. At work: off-by-one is why batch jobs skip or crash on the last record.",
                "Investigate: what is the last slot of g?",
                "Why does it crash after Coco?");
        }

        static string[] Lines(string line2, string line3)
        {
            return new[] { "string[] g={\"Thea\",\"Jean\",\"Coco\"};", line2, line3, "    Console.WriteLine(g[i]);" };
        }

        // Plays the roll call. n is the loop limit, inclusive picks <= instead of <.
        // The loop stops when its condition is false, or crashes when it reads a slot that does not exist.
        static List<TraceEvent> Roll(int n, int start, bool inclusive)
        {
            var events = new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.ArraySet(1, "g", "[Thea, Jean, Coco] (slots 0 to 2)"),
                TraceEvent.LineExecuted(2),
                TraceEvent.IntSet(2, "n", n)
            };

            for (var i = start; ; i++)
            {
                events.Add(TraceEvent.LineExecuted(3));
                events.Add(TraceEvent.IntSet(3, "i", i));

                var keepGoing = inclusive ? i <= n : i < n;
                if (!keepGoing)
                {
                    events.Add(TraceEvent.Evaluated(3, $"{i} {(inclusive ? "<=" : "<")} {n}", false));
                    return events;
                }

                if (i >= Guards.Length)
                {
                    events.Add(TraceEvent.Evaluated(3, $"{i} {(inclusive ? "<=" : "<")} {n}", true));
                    events.Add(TraceEvent.LineExecuted(4));
                    events.Add(TraceEvent.ExceptionThrown(4, "IndexOutOfRangeException"));
                    return events;
                }

                events.Add(TraceEvent.LineExecuted(4));
                events.Add(TraceEvent.OutputAppended(4, Guards[i]));
            }
        }
    }
}
