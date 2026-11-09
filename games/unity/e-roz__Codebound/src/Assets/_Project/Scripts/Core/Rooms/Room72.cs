using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room72
    {
        public const string Id = "7-2";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Commit That Broke It",
                "The door worked at commit #1. It is broken at #8. One commit in between did it.",
                "Find the first bad commit with as few checks as possible.",
                new[]
                {
                    "#1 add door", "#2 add lock", "#3 add alarm", "#4 rename keys", "#5 faster doors",
                    "#6 new greeting", "#7 tidy code", "#8 add torch"
                },
                string.Empty,
                Linear(),
                new PredictQuestion(
                    "First bad commit is #7. How many checks, one by one from #2?",
                    new[] { "3", "6", "7", "8" },
                    1,
                    "You check #2, #3, #4, #5, #6 and #7. That is 6 checks, and each one means building and running the Keep."),
                new[]
                {
                    new Hypothesis("Read every file in the Keep.", Verdict.Wrong,
                        "Refuted. That takes days and does not tell you when it broke."),
                    new Hypothesis("Check every commit, one by one.", Verdict.Close,
                        "Partly confirmed. It works, but it is slow. Is there a faster way?"),
                    new Hypothesis("The history is in order, so check the middle and halve the range.", Verdict.Correct,
                        "Confirmed. Good at #1 and bad at #8 means the change is in between. Halve the range each time.")
                },
                new[]
                {
                    new FixOption("Check the middle, then half again", FixQuality.Best,
                        new[]
                        {
                            "#1 add door (good)", "#4 rename keys", "#6 new greeting", "#7 tidy code",
                            "#8 add torch (bad)"
                        },
                        Bisect(),
                        "Test passed: 3 checks found it. Each check cuts the search in half. Git does this for you as bisect."),
                    new FixOption("Undo the last 3 commits", FixQuality.SymptomOnly,
                        new[] { "#8 add torch", "git revert #8 #7 #6" },
                        Revert(),
                        "Test failed: the door works, but good work in #6 and #8 is lost and nobody knows why #7 broke it."),
                    new FixOption("Ask who wrote the newest commit", FixQuality.Wrong,
                        new[] { "#8 add torch (bad)", "git blame #8 -> Coco" },
                        Blame(),
                        "Test failed: the newest commit is not always guilty. #8 only sits on top of the real cause.")
                },
                "Assert.AreEqual(7, FirstBad(history));\nAssert.LessOrEqual(checks, 3);",
                new[]
                {
                    "Tala: count the checks in the watch list.",
                    "Tala: what if you start in the middle?",
                    "Tala: halve the range every time."
                },
                "Bisect: when #1 is good and #8 is bad, check the middle, then the middle of the part that still hides the culprit. 3 checks beat 6, and with 1000 commits it needs only about 10. At work: git bisect does this for you. Here Git is shown as simple text.",
                "Investigate: how many checks did we need?",
                "What is the smartest way to find the bad commit?");
        }

        static List<TraceEvent> Linear()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(2), TraceEvent.TextSet(2, "last check", "#2 good"), TraceEvent.IntSet(2, "checks", 1),
                TraceEvent.LineExecuted(3), TraceEvent.TextSet(3, "last check", "#3 good"), TraceEvent.IntSet(3, "checks", 2),
                TraceEvent.LineExecuted(4), TraceEvent.TextSet(4, "last check", "#4 good"), TraceEvent.IntSet(4, "checks", 3),
                TraceEvent.LineExecuted(5), TraceEvent.TextSet(5, "last check", "#5 good"), TraceEvent.IntSet(5, "checks", 4),
                TraceEvent.LineExecuted(6), TraceEvent.TextSet(6, "last check", "#6 good"), TraceEvent.IntSet(6, "checks", 5),
                TraceEvent.LineExecuted(7), TraceEvent.TextSet(7, "last check", "#7 bad"), TraceEvent.IntSet(7, "checks", 6),
                TraceEvent.TextSet(7, "first bad", "#7 tidy code")
            };
        }

        static List<TraceEvent> Bisect()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(2), TraceEvent.TextSet(2, "last check", "#4 good"), TraceEvent.IntSet(2, "checks", 1),
                TraceEvent.LineExecuted(3), TraceEvent.TextSet(3, "last check", "#6 good"), TraceEvent.IntSet(3, "checks", 2),
                TraceEvent.LineExecuted(4), TraceEvent.TextSet(4, "last check", "#7 bad"), TraceEvent.IntSet(4, "checks", 3),
                TraceEvent.TextSet(4, "first bad", "#7 tidy code")
            };
        }

        static List<TraceEvent> Revert()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(2),
                TraceEvent.TextSet(2, "door", "works again"),
                TraceEvent.TextSet(2, "lost work", "#6 greeting and #8 torch"),
                TraceEvent.TextSet(2, "cause", "still unknown")
            };
        }

        static List<TraceEvent> Blame()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(2),
                TraceEvent.TextSet(2, "blame", "Coco wrote #8"),
                TraceEvent.TextSet(2, "cause", "#8 is not the culprit")
            };
        }
    }
}
