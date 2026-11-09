using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room32
    {
        public const string Id = "3-2";

        const string Full = "[Sword, Gem]";
        const string Empty = "[]";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Greedy Counter",
                "The bag holds Sword and Gem. Asking for the total twice gives 2, then 0.",
                "Total() must only count. Asking twice must give 2 both times.",
                new[]
                {
                    "int Total()", "{", "    int n = bag.Count;", "    bag.Clear();", "    return n;", "}",
                    "Console.WriteLine(Total());", "Console.WriteLine(Total());"
                },
                string.Empty,
                Original(),
                new PredictQuestion(
                    "What do the two lines print?",
                    new[] { "2 and 2", "2 and 0", "0 and 0", "A crash" },
                    1,
                    "The first Total() counts 2, then Clear() empties the bag. The second Total() sees an empty bag."),
                new[]
                {
                    new Hypothesis("bag.Count is wrong the second time.", Verdict.Wrong,
                        "Refuted. Count is correct. The bag really was empty."),
                    new Hypothesis("Something empties the bag between the calls.", Verdict.Close,
                        "Partly confirmed. What does line 4 do?"),
                    new Hypothesis("Total() clears the bag as a side effect, so the second call finds it empty.", Verdict.Correct,
                        "Confirmed. A method that should only read must not change anything.")
                },
                new[]
                {
                    new FixOption("Delete the line bag.Clear();", FixQuality.Best,
                        new[]
                        {
                            "int Total()", "{", "    return bag.Count;", "}",
                            "Console.WriteLine(Total());", "Console.WriteLine(Total());"
                        },
                        Fixed(),
                        "Test passed: 2 and 2. The bag still holds Sword and Gem."),
                    new FixOption("Change line 8 to: Console.WriteLine(2);", FixQuality.SymptomOnly,
                        new[]
                        {
                            "int Total()", "{", "    int n = bag.Count;", "    bag.Clear();", "    return n;", "}",
                            "Console.WriteLine(Total());", "Console.WriteLine(2);"
                        },
                        Hardcoded(),
                        "Test failed: it prints 2 and 2, but Total() still empties the bag."),
                    new FixOption("Change line 3 to: int n = bag.Count + 1;", FixQuality.Wrong,
                        new[]
                        {
                            "int Total()", "{", "    int n = bag.Count + 1;", "    bag.Clear();", "    return n;", "}",
                            "Console.WriteLine(Total());", "Console.WriteLine(Total());"
                        },
                        Plus(),
                        "Test failed: it prints 3 and 1. The count is wrong and the bag is still emptied.")
                },
                "Assert.AreEqual(Total(), Total());",
                new[]
                {
                    "Count is fine. Look at what else Total() does.",
                    "Which line changes the bag?",
                    "A method that only counts should not call Clear()."
                },
                "A method that should only read must not change things. Side effects make bugs that depend on the order you call methods. At work: a getter that quietly resets data causes surprises that are hard to trace.",
                "Investigate: what does the bag hold after Total()?",
                "Why is the second answer 0?");
        }

        static List<TraceEvent> Original()
        {
            var events = new List<TraceEvent> { TraceEvent.ArraySet(7, "bag", Full) };
            Call(events, 7, 4, "2", "2");
            Call(events, 8, 4, "0", "0");
            return events;
        }

        // One call of Total(): count, clear, return, print.
        static void Call(List<TraceEvent> events, int printLine, int clearLine, string n, string printed)
        {
            events.Add(TraceEvent.LineExecuted(printLine));
            events.Add(TraceEvent.LineExecuted(3));
            events.Add(TraceEvent.IntSet(3, "n", int.Parse(n)));
            events.Add(TraceEvent.LineExecuted(clearLine));
            events.Add(TraceEvent.ArraySet(clearLine, "bag", Empty));
            events.Add(TraceEvent.LineExecuted(5));
            events.Add(TraceEvent.CallReturned(5, "Total()", n));
            events.Add(TraceEvent.OutputAppended(printLine, printed));
        }

        static List<TraceEvent> Fixed()
        {
            var events = new List<TraceEvent> { TraceEvent.ArraySet(5, "bag", Full) };
            foreach (var printLine in new[] { 5, 6 })
            {
                events.Add(TraceEvent.LineExecuted(printLine));
                events.Add(TraceEvent.LineExecuted(3));
                events.Add(TraceEvent.CallReturned(3, "Total()", "2"));
                events.Add(TraceEvent.OutputAppended(printLine, "2"));
            }
            return events;
        }

        static List<TraceEvent> Hardcoded()
        {
            var events = new List<TraceEvent> { TraceEvent.ArraySet(7, "bag", Full) };
            Call(events, 7, 4, "2", "2");
            events.Add(TraceEvent.LineExecuted(8));
            events.Add(TraceEvent.OutputAppended(8, "2"));
            return events;
        }

        static List<TraceEvent> Plus()
        {
            var events = new List<TraceEvent> { TraceEvent.ArraySet(7, "bag", Full) };
            Call(events, 7, 4, "3", "3");
            Call(events, 8, 4, "1", "1");
            return events;
        }
    }
}
