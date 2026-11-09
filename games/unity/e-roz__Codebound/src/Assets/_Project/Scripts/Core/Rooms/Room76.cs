using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room76
    {
        public const string Id = "7-6";

        const string Ending =
            "Tala reads the Architect's last note: \"I never wrote the tests. I'm sorry.\"\n" +
            "Bato walks in. \"You fixed it alone, {name}. That was the point.\"\n" +
            "\"You are a Warden now. The Keep will break again tomorrow. That's the job.\"";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Smallest Safe Change",
                "Review: three pull requests fix the master key. Choose the one to ship.",
                "Ship the smallest change that fixes the cause and proves it.",
                new[]
                {
                    "// every vault shares MASTER", "var key = Config.Master;", "foreach (var v in Vaults)",
                    "  v.Lock = key;"
                },
                string.Empty,
                Original(),
                new PredictQuestion(
                    "The loop runs for 3 vaults. How many share the MASTER key afterwards?",
                    new[] { "0", "1", "3", "It depends" },
                    2,
                    "Every pass of the loop sets the same key. All 3 vaults end up with MASTER."),
                new[]
                {
                    new Hypothesis("Rewrite the whole lock system for a cleaner design.", Verdict.Wrong,
                        "Refuted. A huge change is hard to review and brings new bugs of its own."),
                    new Hypothesis("Change only the one vault that was reported.", Verdict.Close,
                        "Partly confirmed. It is small, but it leaves the cause behind."),
                    new Hypothesis("The smallest change that fixes the cause, plus a test that proves it.", Verdict.Correct,
                        "Confirmed. Small to review, safe to ship, and proven by a test.")
                },
                new[]
                {
                    new FixOption("One key per vault, plus a test (2 files)", FixQuality.Best,
                        new[]
                        {
                            "foreach (var v in Vaults)", "  v.Lock = NewKey(v.Id);", "[Test] void KeysAreUnique() {",
                            "  Assert.AreEqual(3, KeyCount());", "}"
                        },
                        Best(),
                        "Test passed: no vault shares a key now, a test proves it, and the change is small enough to review."),
                    new FixOption("Change Vault 1 only (1 file, no test)", FixQuality.SymptomOnly,
                        new[] { "Vault1.Lock = NewKey();", "// the others later" },
                        VaultOneOnly(),
                        "Test failed: quick and small, but two vaults still share MASTER and nothing proves the fix."),
                    new FixOption("Rewrite the lock system (40 files)", FixQuality.Wrong,
                        new[] { "// new LockManager, 40 files", "// new Config, new database", "// old code deleted" },
                        Rewrite(),
                        "Test failed: the change is too big to review and may add new bugs. Small and proven beats big and hopeful.")
                },
                "Assert.AreEqual(3, KeyCount());\n// 2 files changed, 3 tests pass",
                new[]
                {
                    "Tala: how many vaults does each version fix?",
                    "Tala: which version has a test?",
                    "Tala: small, proven, aimed at the cause."
                },
                "Shipping safely means the smallest change that removes the cause, with a test that proves it. Small pull requests get reviewed and merged. At work: this is the habit that matters most in your first week.",
                "Investigate: what does the loop do to each vault?",
                "What should the fix look like?",
                Ending);
        }

        static List<TraceEvent> Original()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(2),
                TraceEvent.TextSet(2, "key", "MASTER"),
                TraceEvent.LineExecuted(4),
                TraceEvent.IntSet(4, "vaults sharing MASTER", 3)
            };
        }

        static List<TraceEvent> Best()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(2),
                TraceEvent.IntSet(2, "vaults sharing MASTER", 0),
                TraceEvent.TextSet(2, "files changed", "2, small to review"),
                TraceEvent.LineExecuted(4),
                TraceEvent.IntSet(4, "unique keys", 3),
                TraceEvent.TextSet(4, "tests", "3 passed")
            };
        }

        static List<TraceEvent> VaultOneOnly()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.IntSet(1, "vaults sharing MASTER", 2),
                TraceEvent.TextSet(1, "tests", "none"),
                TraceEvent.TextSet(2, "cause", "still there")
            };
        }

        static List<TraceEvent> Rewrite()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.TextSet(1, "files changed", "40"),
                TraceEvent.TextSet(2, "review", "nobody can review this"),
                TraceEvent.TextSet(3, "risk", "new bugs everywhere")
            };
        }
    }
}
