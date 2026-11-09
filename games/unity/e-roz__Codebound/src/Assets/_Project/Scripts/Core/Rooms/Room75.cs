using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room75
    {
        public const string Id = "7-5";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Master Key",
                "Every wing broke in a different way. Tala found one name in every log: MASTER.",
                "A key must open only its own vault.",
                new[]
                {
                    "var key = \"MASTER\";", "Vault1.Lock = key;", "Vault2.Lock = key;", "Vault3.Lock = key;",
                    "Vault3.Open(Vault1.Key);"
                },
                string.Empty,
                Original(),
                new PredictQuestion(
                    "Vault 1's key is MASTER. Does it open Vault 3?",
                    new[] { "No", "Yes", "Only at night", "It crashes" },
                    1,
                    "All three locks were set from the same value. A key is only a copy of that value, so any vault's key fits every vault."),
                new[]
                {
                    new Hypothesis("Vault 3 is broken.", Verdict.Wrong,
                        "Refuted. Vault 3 does exactly what its lock says."),
                    new Hypothesis("Someone lost a key.", Verdict.Close,
                        "Partly confirmed. But a lost key should open only one vault. Why does it open all?"),
                    new Hypothesis("All vaults share one lock value, so any key opens every vault.", Verdict.Correct,
                        "Confirmed. This is the root cause behind the whole Keep: one shortcut, marked temporary.")
                },
                new[]
                {
                    new FixOption("Give each vault its own key", FixQuality.Best,
                        new[]
                        {
                            "// test first: it must go red", "Vault1.Lock = NewKey();", "Vault2.Lock = NewKey();",
                            "Vault3.Lock = NewKey();", "Assert.IsFalse(Vault3.Open(k1));"
                        },
                        OwnKeys(),
                        "Test passed: each vault has its own key, and a test proves Vault 1's key cannot open Vault 3."),
                    new FixOption("Change the lock on Vault 3 only", FixQuality.SymptomOnly,
                        new[]
                        {
                            "var key = \"MASTER\";", "Vault1.Lock = key;", "Vault2.Lock = key;",
                            "Vault3.Lock = \"OTHER\";", "Vault3.Open(Vault1.Key);"
                        },
                        OneVault(),
                        "Test failed: Vault 3 is safe now, but Vault 2 still opens with Vault 1's key. The cause is still there."),
                    new FixOption("Rename key to secretKey", FixQuality.Wrong,
                        new[]
                        {
                            "var secretKey = \"MASTER\";", "Vault1.Lock = secretKey;", "Vault2.Lock = secretKey;",
                            "Vault3.Lock = secretKey;", "Vault3.Open(Vault1.Key);"
                        },
                        Renamed(),
                        "Test failed: a new name changes nothing. The same value still opens every vault.")
                },
                "Assert.IsFalse(Vault3.Open(key1));",
                new[]
                {
                    "Tala: compare the lock value of each vault.",
                    "Tala: how many different keys exist?",
                    "Tala: one key per vault, and a test that proves it."
                },
                "Root cause: one shared master key, a shortcut marked temporary. Fix the cause, not just the one place you noticed, and prove it with a test. At work: temporary shortcuts have a way of becoming permanent.",
                "Investigate: what is each lock set to?",
                "Why does one key open every vault?");
        }

        static List<TraceEvent> Original()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.TextSet(1, "key", "MASTER"),
                TraceEvent.LineExecuted(2),
                TraceEvent.TextSet(2, "Vault 1 lock", "MASTER"),
                TraceEvent.LineExecuted(3),
                TraceEvent.TextSet(3, "Vault 2 lock", "MASTER"),
                TraceEvent.LineExecuted(4),
                TraceEvent.TextSet(4, "Vault 3 lock", "MASTER"),
                TraceEvent.LineExecuted(5),
                TraceEvent.TextSet(5, "Vault 3", "opened by Vault 1's key")
            };
        }

        static List<TraceEvent> OwnKeys()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(2),
                TraceEvent.TextSet(2, "Vault 1 lock", "key A"),
                TraceEvent.LineExecuted(3),
                TraceEvent.TextSet(3, "Vault 2 lock", "key B"),
                TraceEvent.LineExecuted(4),
                TraceEvent.TextSet(4, "Vault 3 lock", "key C"),
                TraceEvent.LineExecuted(5),
                TraceEvent.TextSet(5, "Vault 3", "stays locked"),
                TraceEvent.TextSet(5, "test", "passed")
            };
        }

        static List<TraceEvent> OneVault()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(4),
                TraceEvent.TextSet(4, "Vault 3 lock", "OTHER"),
                TraceEvent.LineExecuted(5),
                TraceEvent.TextSet(5, "Vault 3", "stays locked"),
                TraceEvent.TextSet(5, "Vault 2", "still opens with any key")
            };
        }

        static List<TraceEvent> Renamed()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.TextSet(1, "secretKey", "MASTER"),
                TraceEvent.LineExecuted(5),
                TraceEvent.TextSet(5, "Vault 3", "still opened by Vault 1's key")
            };
        }
    }
}
