using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room41
    {
        public const string Id = "4-1";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Duplicate Scrolls",
                "The report counts 2 scrolls, but only scroll A1 exists.",
                "Each scroll ID must be counted once.",
                new[]
                {
                    "var ids = new List<string>();", "ids.Add(\"A1\");", "ids.Add(\"A1\");",
                    "Console.WriteLine(ids.Count);"
                },
                string.Empty,
                Original("2"),
                new PredictQuestion(
                    "How many IDs does the archive count?",
                    new[] { "1", "2", "0", "A crash" },
                    1,
                    "A List keeps every Add, even the same ID twice. So the count is 2."),
                new[]
                {
                    new Hypothesis("Count adds one extra.", Verdict.Wrong,
                        "Refuted. Count is right: the list really holds two items."),
                    new Hypothesis("The same ID was added twice.", Verdict.Close,
                        "Partly confirmed. Why does the list accept it?"),
                    new Hypothesis("A List keeps every Add, so a repeated ID is stored twice.", Verdict.Correct,
                        "Confirmed. When IDs must be unique, a List is the wrong container.")
                },
                new[]
                {
                    new FixOption("Use a HashSet instead of a List", FixQuality.Best,
                        new[]
                        {
                            "var ids = new HashSet<string>();", "ids.Add(\"A1\");", "ids.Add(\"A1\");",
                            "Console.WriteLine(ids.Count);"
                        },
                        Unique(),
                        "Test passed: the second Add is ignored and the count is 1."),
                    new FixOption("Change line 4 to: Console.WriteLine(1);", FixQuality.SymptomOnly,
                        new[]
                        {
                            "var ids = new List<string>();", "ids.Add(\"A1\");", "ids.Add(\"A1\");",
                            "Console.WriteLine(1);"
                        },
                        Original("1", false),
                        "Test failed: it prints 1, but the list still holds A1 twice."),
                    new FixOption("Sort the list before counting", FixQuality.Wrong,
                        new[]
                        {
                            "var ids = new List<string>();", "ids.Add(\"A1\");", "ids.Add(\"A1\");",
                            "ids.Sort();", "Console.WriteLine(ids.Count);"
                        },
                        Sorted(),
                        "Test failed: sorting keeps both copies, so it still prints 2.")
                },
                "Assert.AreEqual(1, ids.Count);",
                new[]
                {
                    "Is Count wrong, or are there really two items?",
                    "What does Add do when the ID is already there?",
                    "Use a collection that keeps each value only once."
                },
                "A List keeps every item you add, even repeats. A HashSet keeps each value once. At work: duplicate customer and order records usually come from a List used where a set was needed.",
                "Investigate: what does the list hold after line 3?",
                "Why is the count 2?");
        }

        static List<TraceEvent> Original(string printed, bool showCount = true)
        {
            var events = new List<TraceEvent>
            {
                TraceEvent.LineExecuted(2),
                TraceEvent.ArraySet(2, "ids", "[A1]"),
                TraceEvent.LineExecuted(3),
                TraceEvent.ArraySet(3, "ids", "[A1, A1]"),
                TraceEvent.LineExecuted(4)
            };
            if (showCount) events.Add(TraceEvent.IntSet(4, "Count", 2));
            events.Add(TraceEvent.OutputAppended(4, printed));
            return events;
        }

        static List<TraceEvent> Unique()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(2),
                TraceEvent.ArraySet(2, "ids", "[A1]"),
                TraceEvent.LineExecuted(3),
                TraceEvent.ArraySet(3, "ids", "[A1]"),
                TraceEvent.LineExecuted(4),
                TraceEvent.IntSet(4, "Count", 1),
                TraceEvent.OutputAppended(4, "1")
            };
        }

        static List<TraceEvent> Sorted()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(2),
                TraceEvent.ArraySet(2, "ids", "[A1]"),
                TraceEvent.LineExecuted(3),
                TraceEvent.ArraySet(3, "ids", "[A1, A1]"),
                TraceEvent.LineExecuted(4),
                TraceEvent.LineExecuted(5),
                TraceEvent.IntSet(5, "Count", 2),
                TraceEvent.OutputAppended(5, "2")
            };
        }
    }
}
