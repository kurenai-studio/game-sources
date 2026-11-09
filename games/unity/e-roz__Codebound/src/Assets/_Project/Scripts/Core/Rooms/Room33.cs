using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room33
    {
        public const string Id = "3-3";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Stack of Clues",
                "The crash points at line 5, but line 5 looks fine.",
                "Load a file path and print its length. No crash.",
                Lines("Load(null);", "  => Parse(path);", "  => Console.WriteLine(s.Length);"),
                string.Empty,
                Run("null", false),
                new PredictQuestion(
                    "Which line does the crash report point to?",
                    new[] { "Line 1", "Line 3", "Line 5", "No crash" },
                    2,
                    "s is null when line 5 reads s.Length, so the crash is reported there, on the last call."),
                new[]
                {
                    new Hypothesis("Parse is broken.", Verdict.Wrong,
                        "Refuted. Parse works for any real string. It was given null."),
                    new Hypothesis("s is null inside Parse.", Verdict.Close,
                        "Partly confirmed. True, but who gave it null? Follow the stack up."),
                    new Hypothesis("Line 1 passes null, and it travels down until Parse crashes.", Verdict.Correct,
                        "Confirmed. The crash shows where it blew up, not where it started.")
                },
                new[]
                {
                    new FixOption("Change line 1 to: Load(\"save.txt\");", FixQuality.Best,
                        Lines("Load(\"save.txt\");", "  => Parse(path);", "  => Console.WriteLine(s.Length);"),
                        Run("\"save.txt\"", true),
                        "Test passed: it prints 8, the length of save.txt."),
                    new FixOption("Change line 5 to: => Console.WriteLine(s?.Length);", FixQuality.SymptomOnly,
                        Lines("Load(null);", "  => Parse(path);", "  => Console.WriteLine(s?.Length);"),
                        Hidden(),
                        "Test failed: no crash, but it prints a blank line. The bad path is hidden, not fixed."),
                    new FixOption("Change line 3 to: => Parse(\"\");", FixQuality.Wrong,
                        Lines("Load(null);", "  => Parse(\"\");", "  => Console.WriteLine(s.Length);"),
                        Empty(),
                        "Test failed: it prints 0. Load now ignores its path.")
                },
                "Assert.AreEqual(\"8\", output); // for \"save.txt\"",
                new[]
                {
                    "The last line of the stack is where it crashed, not why.",
                    "Read the stack from the bottom up. Who first had the null?",
                    "The first call, line 1, passes null. Fix it there."
                },
                "A stack trace shows where the program crashed, not where the mistake started. Follow the calls up to the first one that gave a bad value. At work: reading a stack trace is the most useful skill on day one.",
                "Investigate: who first had the null?",
                "Where does the null come from?");
        }

        static string[] Lines(string line1, string line3, string line5) =>
            new[] { line1, "void Load(string path)", line3, "void Parse(string s)", line5 };

        // Main calls Load, which calls Parse. A null path travels all the way down.
        static List<TraceEvent> Run(string path, bool works)
        {
            var events = new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.TextSet(1, "stack", "Main > Load"),
                TraceEvent.TextSet(1, "path", path),
                TraceEvent.LineExecuted(3),
                TraceEvent.TextSet(3, "stack", "Main > Load > Parse"),
                TraceEvent.TextSet(3, "s", path),
                TraceEvent.LineExecuted(5)
            };

            if (works) events.Add(TraceEvent.OutputAppended(5, "8"));
            else events.Add(TraceEvent.ExceptionThrown(5, "NullReferenceException"));
            return events;
        }

        static List<TraceEvent> Hidden()
        {
            var events = Run("null", true);
            events.RemoveAt(events.Count - 1);
            events.Add(TraceEvent.OutputAppended(5, "(blank line)"));
            return events;
        }

        static List<TraceEvent> Empty()
        {
            var events = Run("null", true);
            events.RemoveAt(events.Count - 1);
            events[5] = TraceEvent.TextSet(3, "s", "\"\"");
            events.Add(TraceEvent.OutputAppended(5, "0"));
            return events;
        }
    }
}
