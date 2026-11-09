using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room35
    {
        public const string Id = "3-5";

        const string Test = "Add(2, 3) is 5";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "Red, Then Green",
                "Add(2, 3) gives -1, but the team wants proof before any fix.",
                "Show the bug with a failing test first. Then fix it.",
                Lines("    return a - b;"),
                string.Empty,
                Run("-1"),
                new PredictQuestion(
                    "What does this print?",
                    new[] { "5", "-1", "1", "A crash" },
                    1,
                    "Add subtracts. 2 - 3 is -1."),
                new[]
                {
                    new Hypothesis("Add is never called.", Verdict.Wrong,
                        "Refuted. The row shows Add(2, 3) returns -1."),
                    new Hypothesis("Add gives a wrong number.", Verdict.Close,
                        "Partly confirmed. Which line makes it wrong?"),
                    new Hypothesis("Line 3 subtracts instead of adding.", Verdict.Correct,
                        "Confirmed. a - b should be a + b.")
                },
                new[]
                {
                    new FixOption("Write a test that fails now, then change to a + b", FixQuality.Best,
                        Lines("    return a + b;"),
                        RedThenGreen(),
                        "Test passed: it was red before the fix and green after. Now you have proof."),
                    new FixOption("Change to a + b, then write the test", FixQuality.SymptomOnly,
                        Lines("    return a + b;"),
                        GreenOnly(),
                        "Test failed: it is green, but you never saw it red. A test that never failed proves nothing."),
                    new FixOption("Write a test for Add(0, 0) is 0", FixQuality.Wrong,
                        Lines("    return a - b;"),
                        WrongTest(),
                        "Test failed: Add(0, 0) is green even with the bug. This test cannot catch it.")
                },
                "Assert.AreEqual(5, Add(2, 3));",
                new[]
                {
                    "What would you check to see the bug?",
                    "Pick numbers where adding and subtracting differ.",
                    "A test must fail before the fix. That is the proof."
                },
                "Write the test first and watch it fail (red). Then fix, and watch it pass (green). At work: a test that was never red does not prove the bug is fixed.",
                "Investigate: which inputs show the bug?",
                "Why is the answer -1?");
        }

        static string[] Lines(string line3) =>
            new[] { "int Add(int a, int b)", "{", line3, "}", "Console.WriteLine(Add(2, 3));" };

        static List<TraceEvent> Run(string result)
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(5),
                TraceEvent.LineExecuted(3),
                TraceEvent.CallReturned(3, "Add(2, 3)", result),
                TraceEvent.OutputAppended(5, result)
            };
        }

        static List<TraceEvent> RedThenGreen()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(5),
                TraceEvent.TestRan(5, $"{Test} (before fix)", false),
                TraceEvent.LineExecuted(3),
                TraceEvent.CallReturned(3, "Add(2, 3)", "5"),
                TraceEvent.TestRan(5, Test, true),
                TraceEvent.OutputAppended(5, "5")
            };
        }

        static List<TraceEvent> GreenOnly()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(5),
                TraceEvent.LineExecuted(3),
                TraceEvent.CallReturned(3, "Add(2, 3)", "5"),
                TraceEvent.TestRan(5, Test, true),
                TraceEvent.OutputAppended(5, "5")
            };
        }

        static List<TraceEvent> WrongTest()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(5),
                TraceEvent.TestRan(5, "Add(0, 0) is 0", true),
                TraceEvent.LineExecuted(3),
                TraceEvent.CallReturned(3, "Add(2, 3)", "-1"),
                TraceEvent.OutputAppended(5, "-1")
            };
        }
    }
}
