using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room54
    {
        public const string Id = "5-4";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Identical Twins",
                "The shop lists Coco's coin twice. Two coins of value 5 are not equal.",
                "Two coins with the same value must be equal.",
                Lines("class Coin { public int V; }", "var a = new Coin { V = 5 };", "var b = new Coin { V = 5 };",
                    "Console.WriteLine(a == b);"),
                string.Empty,
                Original(),
                new PredictQuestion(
                    "What does this print?",
                    new[] { "True", "False", "5", "A crash" },
                    1,
                    "== on two class objects asks: are they the same object? a and b are two separate objects, so it is False."),
                new[]
                {
                    new Hypothesis("a.V and b.V are different.", Verdict.Wrong,
                        "Refuted. Both rows show V is 5."),
                    new Hypothesis("a and b look the same but are not equal.", Verdict.Close,
                        "Partly confirmed. What does == compare for a class?"),
                    new Hypothesis("== on classes compares the object itself, not the values inside.", Verdict.Correct,
                        "Confirmed. That is reference equality.")
                },
                new[]
                {
                    new FixOption("Make Coin a record", FixQuality.Best,
                        Lines("record Coin(int V);", "var a = new Coin(5);", "var b = new Coin(5);",
                            "Console.WriteLine(a == b);"),
                        Result(true, "True"),
                        "Test passed: a record compares by value, so equal coins are equal everywhere."),
                    new FixOption("Compare a.V == b.V instead", FixQuality.SymptomOnly,
                        Lines("class Coin { public int V; }", "var a = new Coin { V = 5 };", "var b = new Coin { V = 5 };",
                            "Console.WriteLine(a.V == b.V);"),
                        Result(false, "True"),
                        "Test failed: this one line works, but a == b is still False in lists and dictionaries."),
                    new FixOption("Use Equals(a, b)", FixQuality.Wrong,
                        Lines("class Coin { public int V; }", "var a = new Coin { V = 5 };", "var b = new Coin { V = 5 };",
                            "Console.WriteLine(Equals(a, b));"),
                        Result(false, "False"),
                        "Test failed: Equals is also reference-based for classes. It is still False.")
                },
                "Assert.AreEqual(new Coin(5), new Coin(5));",
                new[]
                {
                    "Tala: both coins hold 5.",
                    "Tala: what does == compare for a class?",
                    "Tala: a record compares the values inside."
                },
                "Classes are compared by reference unless you define equality. A record compares by value. At work: lookups in lists and dictionaries quietly fail when equality is wrong.",
                "Investigate: what do the rows say about a and b?",
                "Why is the answer False?");
        }

        static string[] Lines(string type, string a, string b, string print) => new[] { type, a, b, print };

        static List<TraceEvent> Original() => Result(false, "False");

        static List<TraceEvent> Result(bool equal, string printed)
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(2),
                TraceEvent.TextSet(2, "a", "coin #1"),
                TraceEvent.IntSet(2, "a.V", 5),
                TraceEvent.LineExecuted(3),
                TraceEvent.TextSet(3, "b", "coin #2"),
                TraceEvent.IntSet(3, "b.V", 5),
                TraceEvent.LineExecuted(4),
                TraceEvent.BoolSet(4, "a == b", equal),
                TraceEvent.OutputAppended(4, printed)
            };
        }
    }
}
