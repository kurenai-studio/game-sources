using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room45
    {
        public const string Id = "4-5";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "Searching the Whole Shelf",
                "The archive page takes 8 seconds with 100,000 scrolls. A note says: fine for now.",
                "Finding an ID must not read the whole shelf.",
                new[]
                {
                    "// shelf: 1000 ids in a List", "var id = 999;", "var found = shelf.Contains(id);",
                    "Console.WriteLine(found);"
                },
                string.Empty,
                Run(2, 3, 4, 1000),
                new PredictQuestion(
                    "How many items does Contains look at to find 999?",
                    new[] { "1", "10", "Up to 1000", "0" },
                    2,
                    "A List has no shortcut. Contains checks the items one by one, and 999 is near the end."),
                new[]
                {
                    new Hypothesis("The ID 999 is not on the shelf.", Verdict.Wrong,
                        "Refuted. found is true, so the ID is there."),
                    new Hypothesis("The search reads too many items.", Verdict.Close,
                        "Partly confirmed. Which collection forces that?"),
                    new Hypothesis("List.Contains reads items one by one, so the work grows with the shelf.", Verdict.Correct,
                        "Confirmed. 100,000 items can mean 100,000 checks.")
                },
                new[]
                {
                    new FixOption("Keep the ids in a HashSet", FixQuality.Best,
                        new[]
                        {
                            "// shelf: 1000 ids in a HashSet", "var id = 999;", "var found = shelf.Contains(id);",
                            "Console.WriteLine(found);"
                        },
                        Run(2, 3, 4, 1),
                        "Test passed: 1 check instead of 1000, and it stays 1 as the shelf grows."),
                    new FixOption("Use shelf.IndexOf(id) >= 0", FixQuality.SymptomOnly,
                        new[]
                        {
                            "// shelf: 1000 ids in a List", "var id = 999;", "var found = shelf.IndexOf(id) >= 0;",
                            "Console.WriteLine(found);"
                        },
                        Run(2, 3, 4, 1000),
                        "Test failed: it reads differently, but it is still a scan. 1000 checks."),
                    new FixOption("Sort the List before searching", FixQuality.Wrong,
                        new[]
                        {
                            "// shelf: 1000 ids in a List", "var id = 999;", "shelf.Sort();",
                            "var found = shelf.Contains(id);", "Console.WriteLine(found);"
                        },
                        Sorted(),
                        "Test failed: Contains does not use the order, and sorting reads the shelf too. Now 2000 checks.")
                },
                "Assert.IsTrue(checks <= 1);",
                new[]
                {
                    "found is true, so the ID exists. What is the cost?",
                    "How does a List look for an item?",
                    "A HashSet jumps straight to the item."
                },
                "List.Contains reads items one by one, so 100,000 items can mean 100,000 checks. A HashSet or Dictionary finds an item in about one check. At work: this slowness stays hidden until the data grows. The counts here are simulated.",
                "Investigate: how many checks does the search need?",
                "Why is the page slow?");
        }

        static List<TraceEvent> Run(int idLine, int searchLine, int printLine, int checks)
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(idLine),
                TraceEvent.IntSet(idLine, "id", 999),
                TraceEvent.LineExecuted(searchLine),
                TraceEvent.BoolSet(searchLine, "found", true),
                TraceEvent.IntSet(searchLine, "checks", checks),
                TraceEvent.LineExecuted(printLine),
                TraceEvent.OutputAppended(printLine, "True")
            };
        }

        static List<TraceEvent> Sorted()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(2),
                TraceEvent.IntSet(2, "id", 999),
                TraceEvent.LineExecuted(3),
                TraceEvent.IntSet(3, "checks", 1000),
                TraceEvent.LineExecuted(4),
                TraceEvent.BoolSet(4, "found", true),
                TraceEvent.IntSet(4, "checks", 2000),
                TraceEvent.LineExecuted(5),
                TraceEvent.OutputAppended(5, "True")
            };
        }
    }
}
