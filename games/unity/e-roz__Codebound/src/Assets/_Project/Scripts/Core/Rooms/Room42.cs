using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room42
    {
        public const string Id = "4-2";

        const string Start = "[1, 1, 2]";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Shelf That Shrinks",
                "Clearing old entries from the shelf crashes the archive.",
                "Remove every 1 from the list without a crash. The count should be 1.",
                new[]
                {
                    "var ids = new List<int> {1, 1, 2};", "foreach (var id in ids)", "{",
                    "    if (id == 1) ids.Remove(id);", "}", "Console.WriteLine(ids.Count);"
                },
                string.Empty,
                Original(),
                new PredictQuestion(
                    "What happens when this runs?",
                    new[] { "Prints 1", "Prints 2", "Throws an error", "Prints 3" },
                    2,
                    "Remove changes the list while foreach is reading it. The next turn of the loop throws InvalidOperationException."),
                new[]
                {
                    new Hypothesis("Remove cannot take an item out of a List.", Verdict.Wrong,
                        "Refuted. The row shows the list shrink before the error."),
                    new Hypothesis("The error comes from the loop, not from Remove.", Verdict.Close,
                        "Partly confirmed. What does the loop need from the list while it runs?"),
                    new Hypothesis("Remove changes the list while foreach reads it, so the loop throws.", Verdict.Correct,
                        "Confirmed. A foreach needs the collection to stay the same.")
                },
                new[]
                {
                    new FixOption("Replace the loop with ids.RemoveAll(...)", FixQuality.Best,
                        new[]
                        {
                            "var ids = new List<int> {1, 1, 2};", "ids.RemoveAll(id => id == 1);",
                            "Console.WriteLine(ids.Count);"
                        },
                        RemovedAll(),
                        "Test passed: both 1s are gone and the count is 1. There is no loop to break."),
                    new FixOption("Catch the error with try and catch", FixQuality.SymptomOnly,
                        new[]
                        {
                            "var ids = new List<int> {1, 1, 2};", "try", "{", "    foreach (var n in ids)",
                            "        if (n == 1) ids.Remove(n);", "}", "catch (Exception) { }",
                            "Console.WriteLine(ids.Count);"
                        },
                        Caught(),
                        "Test failed: no crash, but the loop quit early. One 1 is still in the list."),
                    new FixOption("Call ids.Remove(1); once, before the loop", FixQuality.Wrong,
                        new[]
                        {
                            "var ids = new List<int> {1, 1, 2};", "ids.Remove(1);", "Console.WriteLine(ids.Count);"
                        },
                        RemovedOnce(),
                        "Test failed: Remove deletes only the first 1. One 1 is left, so it prints 2.")
                },
                "Assert.AreEqual(1, ids.Count);",
                new[]
                {
                    "The list shrinks, then the error appears. Which line runs next?",
                    "What does foreach need from the list while it loops?",
                    "Remove every match in one call instead of looping."
                },
                "Never add or remove items from a collection while a foreach reads it. Use RemoveAll, or loop over a copy. At work: this crash only shows on data that has a match, so it passes small tests and fails in production.",
                "Investigate: what does the list look like when the error happens?",
                "Why does the loop crash?");
        }

        static List<TraceEvent> Original()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.ArraySet(1, "ids", Start),
                TraceEvent.LineExecuted(2),
                TraceEvent.LineExecuted(4),
                TraceEvent.ArraySet(4, "ids", "[1, 2]"),
                TraceEvent.LineExecuted(2),
                TraceEvent.ExceptionThrown(2, "InvalidOperationException")
            };
        }

        static List<TraceEvent> RemovedAll()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.ArraySet(1, "ids", Start),
                TraceEvent.LineExecuted(2),
                TraceEvent.ArraySet(2, "ids", "[2]"),
                TraceEvent.LineExecuted(3),
                TraceEvent.IntSet(3, "Count", 1),
                TraceEvent.OutputAppended(3, "1")
            };
        }

        static List<TraceEvent> Caught()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.ArraySet(1, "ids", Start),
                TraceEvent.LineExecuted(4),
                TraceEvent.LineExecuted(5),
                TraceEvent.ArraySet(5, "ids", "[1, 2]"),
                TraceEvent.LineExecuted(7),
                TraceEvent.LineExecuted(8),
                TraceEvent.IntSet(8, "Count", 2),
                TraceEvent.OutputAppended(8, "2")
            };
        }

        static List<TraceEvent> RemovedOnce()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.ArraySet(1, "ids", Start),
                TraceEvent.LineExecuted(2),
                TraceEvent.ArraySet(2, "ids", "[1, 2]"),
                TraceEvent.LineExecuted(3),
                TraceEvent.IntSet(3, "Count", 2),
                TraceEvent.OutputAppended(3, "2")
            };
        }
    }
}
