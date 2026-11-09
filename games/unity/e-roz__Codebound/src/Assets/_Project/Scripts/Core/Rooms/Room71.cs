using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room71
    {
        public const string Id = "7-1";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Conflict Markers",
                "After a merge, the Keep will not build. Thea and Jean both changed this spot.",
                "The file must build, with both changes kept.",
                new[] { "<<<<<<< HEAD", "Pay(reward);", "=======", "Log(reward);", ">>>>>>> jean-log" },
                string.Empty,
                Original(),
                new PredictQuestion(
                    "What does the build do with this file?",
                    new[] { "Runs Pay only", "Runs Log only", "Fails to build", "Runs both lines" },
                    2,
                    "Git cannot choose between two edits of the same spot, so it writes both and marks them. Those marker lines are not C#, so the compiler stops."),
                new[]
                {
                    new Hypothesis("The compiler is broken.", Verdict.Wrong,
                        "Refuted. The compiler reads exactly what is in the file."),
                    new Hypothesis("Two people changed the same place.", Verdict.Close,
                        "Partly confirmed. That caused the conflict. But why does the build fail?"),
                    new Hypothesis("Git left its conflict markers in the file, and they are not C#.", Verdict.Correct,
                        "Confirmed. A conflict is only solved when you remove every marker.")
                },
                new[]
                {
                    new FixOption("Keep both lines, delete every marker", FixQuality.Best,
                        new[] { "Pay(reward);", "Log(reward);" },
                        Kept(),
                        "Test passed: no markers are left, and both Thea's and Jean's changes are kept."),
                    new FixOption("Keep only my side", FixQuality.SymptomOnly,
                        new[] { "Pay(reward);" },
                        OnlyMine(),
                        "Test failed: it builds, but Jean's change vanished and nobody chose that."),
                    new FixOption("Delete the first marker line only", FixQuality.Wrong,
                        new[] { "Pay(reward);", "=======", "Log(reward);", ">>>>>>> jean-log" },
                        StillBroken(),
                        "Test failed: markers are still in the file. Every marker line must go.")
                },
                "Assert.IsTrue(Build(file).Passed);",
                new[]
                {
                    "Tala: look at the first letters of lines 1, 3 and 5.",
                    "Tala: those three lines come from Git, not from C#.",
                    "Tala: decide what stays, then remove all three."
                },
                "A conflict means two people changed the same place. Git cannot pick, so it marks both and asks you. Read both sides, keep what is needed, remove every marker, then build and test. At work: you will resolve conflicts every week.",
                "Investigate: what does the build report?",
                "Why does the build fail?");
        }

        static List<TraceEvent> Original()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.TextSet(1, "build", "failed at <<<<<<<"),
                TraceEvent.TextSet(1, "Pay(reward)", "never runs")
            };
        }

        static List<TraceEvent> Kept()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.TextSet(1, "build", "passed"),
                TraceEvent.LineExecuted(2),
                TraceEvent.TextSet(2, "both changes", "kept: Pay and Log")
            };
        }

        static List<TraceEvent> OnlyMine()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.TextSet(1, "build", "passed"),
                TraceEvent.TextSet(1, "Jean's Log", "silently lost")
            };
        }

        static List<TraceEvent> StillBroken()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(2),
                TraceEvent.TextSet(2, "build", "failed at =======")
            };
        }
    }
}
