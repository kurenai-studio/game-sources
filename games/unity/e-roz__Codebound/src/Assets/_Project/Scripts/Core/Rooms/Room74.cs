using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room74
    {
        public const string Id = "7-4";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Flaky Guard Test",
                "The night-shift test passes all day and fails when run at 23:59.",
                "The test must give the same result at any time.",
                new[]
                {
                    "bool NightShift() {", "  var h = DateTime.Now.Hour;", "  return h >= 22 || h < 6;", "}",
                    "// test:", "Assert.IsFalse(NightShift());"
                },
                string.Empty,
                Original(),
                new PredictQuestion(
                    "The test runs at 23:59. What happens?",
                    new[] { "Passes", "Fails", "Crashes", "Is skipped" },
                    1,
                    "At 23:59 the hour is 23, so NightShift returns true. The test expects false, so it fails. At 09:00 it would pass."),
                new[]
                {
                    new Hypothesis("NightShift has a typo.", Verdict.Wrong,
                        "Refuted. The rule is right: night is from 22:00 to 06:00."),
                    new Hypothesis("The test is too strict.", Verdict.Close,
                        "Partly confirmed. But strict is not the problem. Why does the answer change?"),
                    new Hypothesis("The test reads the real clock, so its result depends on when it runs.", Verdict.Correct,
                        "Confirmed. The clock is a hidden input the test cannot control.")
                },
                new[]
                {
                    new FixOption("Pass the hour in, test fixed hours", FixQuality.Best,
                        new[]
                        {
                            "bool NightShift(int h) {", "  return h >= 22 || h < 6;", "}", "// tests:",
                            "Assert.IsFalse(NightShift(12));", "Assert.IsTrue(NightShift(23));"
                        },
                        Fixed(),
                        "Test passed: the test chooses the hour, so it gives the same result at any time."),
                    new FixOption("Run the tests only in the daytime", FixQuality.SymptomOnly,
                        new[] { "// CI runs tests 06:00 to 22:00", "Assert.IsFalse(NightShift());" },
                        DaytimeOnly(),
                        "Test failed: it hides the problem. Anyone who runs the test at night still sees it fail."),
                    new FixOption("Retry the test three times", FixQuality.Wrong,
                        new[] { "Retry(3, () =>", "  Assert.IsFalse(NightShift()));" },
                        Retry(),
                        "Test failed: retrying does not change the clock. It just fails three times instead of once.")
                },
                "Assert.IsTrue(NightShift(23));\n// the same at any run time",
                new[]
                {
                    "Tala: what changes between 9am and 11pm?",
                    "Tala: the code asks the clock. Who controls the clock in a test?",
                    "Tala: give the hour to the method as a parameter."
                },
                "A flaky test passes or fails for reasons outside the code: the clock, random numbers, test order. Take the hidden input out and pass it in, so the test controls it. At work: flaky tests teach teams to ignore red builds.",
                "Investigate: what does the code read?",
                "Why does it fail only at night?");
        }

        static List<TraceEvent> Original()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(2),
                TraceEvent.TextSet(2, "now", "23:59"),
                TraceEvent.IntSet(2, "h", 23),
                TraceEvent.LineExecuted(3),
                TraceEvent.TextSet(3, "NightShift()", "true"),
                TraceEvent.LineExecuted(6),
                TraceEvent.TextSet(6, "test", "failed"),
                TraceEvent.TextSet(6, "rerun at 09:00", "passed")
            };
        }

        static List<TraceEvent> Fixed()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(5),
                TraceEvent.IntSet(5, "h", 12),
                TraceEvent.TextSet(5, "NightShift(12)", "false"),
                TraceEvent.LineExecuted(6),
                TraceEvent.IntSet(6, "h", 23),
                TraceEvent.TextSet(6, "NightShift(23)", "true"),
                TraceEvent.TextSet(6, "test", "passed at any time")
            };
        }

        static List<TraceEvent> DaytimeOnly()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(2),
                TraceEvent.TextSet(2, "test", "passed in the day"),
                TraceEvent.TextSet(2, "at night", "still fails if someone runs it")
            };
        }

        static List<TraceEvent> Retry()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.TextSet(1, "try 1", "failed"),
                TraceEvent.TextSet(1, "try 2", "failed"),
                TraceEvent.LineExecuted(2),
                TraceEvent.TextSet(2, "try 3", "failed"),
                TraceEvent.TextSet(2, "test", "still fails at night")
            };
        }
    }
}
