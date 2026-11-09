using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room23
    {
        public const string Id = "2-3";

        const string TimedOut = "Timed out (loop never ends)";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Gate That Never Closes",
                "The gate knocks forever. The program never stops.",
                "Knock 3 times, then stop.",
                new[] { "int tries = 3;", "while (tries > 0) {", "    Console.WriteLine(\"Knock\");", "}" },
                string.Empty,
                Spin(">"),
                new PredictQuestion(
                    "What happens when this runs?",
                    new[] { "Knocks 3 times, then stops", "Knocks once", "Knocks forever", "Nothing" },
                    2,
                    "tries starts at 3 and nothing inside the loop changes it. tries > 0 stays true, so the loop never ends."),
                new[]
                {
                    new Hypothesis("The condition is wrong. It should be tries < 0.", Verdict.Wrong,
                        "tries < 0 is false from the start, so the gate would never knock at all."),
                    new Hypothesis("The loop never ends.", Verdict.Close,
                        "Yes, but why? What decides when the loop ends?"),
                    new Hypothesis("tries never changes inside the loop, so tries > 0 stays true.", Verdict.Correct,
                        "Yes. Nothing moves tries toward 0, so the check is true every round.")
                },
                new[]
                {
                    new FixOption("Add tries--; inside the loop", FixQuality.Best,
                        new[]
                        {
                            "int tries = 3;", "while (tries > 0) {", "    Console.WriteLine(\"Knock\");",
                            "    tries--;", "}"
                        },
                        Countdown(),
                        "Test passed: Knock, Knock, Knock. It stops."),
                    new FixOption("Add break; after the print", FixQuality.SymptomOnly,
                        new[]
                        {
                            "int tries = 3;", "while (tries > 0) {", "    Console.WriteLine(\"Knock\");",
                            "    break;", "}"
                        },
                        BreakAfterOne(),
                        "Test failed: it stops, but it only knocks once."),
                    new FixOption("Change line 2 to: while (tries >= 0) {", FixQuality.Wrong,
                        new[] { "int tries = 3;", "while (tries >= 0) {", "    Console.WriteLine(\"Knock\");", "}" },
                        Spin(">="),
                        "Test failed: tries still never changes. It still never stops.")
                },
                "Assert.AreEqual(\"Knock, Knock, Knock\", output);",
                new[]
                {
                    "Which line changes tries?",
                    "No line changes it, so tries > 0 is true every round.",
                    "Add tries--; inside the loop."
                },
                "A while loop needs something inside it that moves the condition toward false. Here, tries-- does that. At work: a loop that never ends freezes a service or burns CPU until a timeout kills it.",
                "Investigate: which line changes tries?",
                "Why does it never stop?");
        }

        // The loop as written: tries stays 3. Three rounds are shown, then the program is stopped.
        static List<TraceEvent> Spin(string op)
        {
            var events = Start();
            for (var round = 0; round < 3; round++)
            {
                events.Add(TraceEvent.LineExecuted(2));
                events.Add(TraceEvent.Evaluated(2, $"3 {op} 0", true));
                events.Add(TraceEvent.LineExecuted(3));
                events.Add(TraceEvent.OutputAppended(3, "Knock"));
            }
            events.Add(TraceEvent.ExceptionThrown(2, TimedOut));
            return events;
        }

        // With tries--; the number counts 3, 2, 1, 0 and the fourth check is false.
        static List<TraceEvent> Countdown()
        {
            var events = Start();
            for (var tries = 3; tries >= 1; tries--)
            {
                events.Add(TraceEvent.LineExecuted(2));
                events.Add(TraceEvent.Evaluated(2, $"{tries} > 0", true));
                events.Add(TraceEvent.LineExecuted(3));
                events.Add(TraceEvent.OutputAppended(3, "Knock"));
                events.Add(TraceEvent.LineExecuted(4));
                events.Add(TraceEvent.IntSet(4, "tries", tries - 1));
            }
            events.Add(TraceEvent.LineExecuted(2));
            events.Add(TraceEvent.Evaluated(2, "0 > 0", false));
            return events;
        }

        static List<TraceEvent> BreakAfterOne()
        {
            var events = Start();
            events.Add(TraceEvent.LineExecuted(2));
            events.Add(TraceEvent.Evaluated(2, "3 > 0", true));
            events.Add(TraceEvent.LineExecuted(3));
            events.Add(TraceEvent.OutputAppended(3, "Knock"));
            events.Add(TraceEvent.LineExecuted(4));
            return events;
        }

        static List<TraceEvent> Start()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.IntSet(1, "tries", 3)
            };
        }
    }
}
