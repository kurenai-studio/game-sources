using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room73
    {
        public const string Id = "7-3";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Test That Cannot Fail",
                "Every test is green, yet Mokky walked through a locked door.",
                "The test must go red when the door is wrong.",
                Lines("  Console.Write(r);"),
                string.Empty,
                Original(),
                new PredictQuestion(
                    "The door lets everyone in. Does LockedDoor fail?",
                    new[] { "Yes, it fails", "No, it passes", "It crashes", "It never runs" },
                    1,
                    "A test fails only when something inside it throws. This one prints r and checks nothing, so it passes whatever the door does."),
                new[]
                {
                    new Hypothesis("The test runner is broken.", Verdict.Wrong,
                        "Refuted. The runner ran the test and reported what it saw."),
                    new Hypothesis("The door code has a bug.", Verdict.Close,
                        "Partly confirmed. It does. But a good test would have caught it."),
                    new Hypothesis("The test never checks the result, so nothing can fail.", Verdict.Correct,
                        "Confirmed. A test with no check is always green.")
                },
                new[]
                {
                    new FixOption("Assert that the door stays locked", FixQuality.Best,
                        Lines("  Assert.IsFalse(r);"),
                        Red(),
                        "Test passed: your test now goes red on the broken door. A test that can fail can protect you."),
                    new FixOption("Fix the door only", FixQuality.SymptomOnly,
                        FixedDoor(),
                        DoorOnly(),
                        "Test failed: the door is fixed, but the test still checks nothing. The next break goes unnoticed."),
                    new FixOption("Assert the result is not null", FixQuality.Wrong,
                        Lines("  Assert.IsNotNull(r);"),
                        NotNull(),
                        "Test failed: a bool is never null, so this check always passes. A check that cannot fail checks nothing.")
                },
                "Assert.IsFalse(Open(mokky));\n// it must go red on the bug",
                new[]
                {
                    "Tala: look for the word Assert in the test.",
                    "Tala: the test printed r. Did it judge r?",
                    "Tala: make the test fail when Mokky gets in."
                },
                "A green test proves nothing if it cannot fail. Write the check first, watch it go red, then make it green. At work: reviewers ask \"what does this test check?\" before they read anything else.",
                "Investigate: what did the test check?",
                "Why is the test green?");
        }

        static string[] Lines(string check) => new[]
        {
            "bool Open(User u) => true;", "[Test] void LockedDoor() {", "  var r = Open(mokky);", check, "}"
        };

        static string[] FixedDoor() => new[]
        {
            "bool Open(User u) => u.IsStaff;", "[Test] void LockedDoor() {", "  var r = Open(mokky);",
            "  Console.Write(r);", "}"
        };

        static List<TraceEvent> Original()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(3),
                TraceEvent.TextSet(3, "Open(mokky)", "true"),
                TraceEvent.LineExecuted(4),
                TraceEvent.IntSet(4, "checks made", 0),
                TraceEvent.LineExecuted(5),
                TraceEvent.TextSet(5, "test", "passed")
            };
        }

        static List<TraceEvent> Red()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(3),
                TraceEvent.TextSet(3, "Open(mokky)", "true"),
                TraceEvent.LineExecuted(4),
                TraceEvent.IntSet(4, "checks made", 1),
                TraceEvent.TextSet(4, "test", "FAILED, the door bug is caught")
            };
        }

        static List<TraceEvent> DoorOnly()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(3),
                TraceEvent.TextSet(3, "Open(mokky)", "false"),
                TraceEvent.IntSet(4, "checks made", 0),
                TraceEvent.TextSet(5, "test", "passed"),
                TraceEvent.TextSet(5, "next bug", "would pass the test too")
            };
        }

        static List<TraceEvent> NotNull()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(3),
                TraceEvent.TextSet(3, "Open(mokky)", "true"),
                TraceEvent.LineExecuted(4),
                TraceEvent.IntSet(4, "checks made", 1),
                TraceEvent.TextSet(4, "test", "passed, a bool is never null")
            };
        }
    }
}
