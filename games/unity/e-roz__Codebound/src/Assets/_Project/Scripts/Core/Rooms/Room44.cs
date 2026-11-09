using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room44
    {
        public const string Id = "4-4";

        const string Users = "{Thea: 1, Jean: 2}";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Case-Sensitive Index",
                "Thea cannot log in. She types thea, but the archive says she does not exist.",
                "Lookups must ignore upper and lower case.",
                new[]
                {
                    "// users: Thea=1, Jean=2", "var name = \"thea\";", "var ok = users.ContainsKey(name);",
                    "Console.WriteLine(ok);"
                },
                string.Empty,
                Run(2, 3, 4, false),
                new PredictQuestion(
                    "What does this print?",
                    new[] { "True", "False", "A crash", "1" },
                    1,
                    "The stored key is Thea. The search text is thea. A Dictionary compares keys letter by letter, including the case."),
                new[]
                {
                    new Hypothesis("Thea was never added to users.", Verdict.Wrong,
                        "Refuted. The row shows Thea in users."),
                    new Hypothesis("The search text differs from the stored key.", Verdict.Close,
                        "Partly confirmed. How exactly do they differ?"),
                    new Hypothesis("Dictionary keys are case-sensitive, so thea is not Thea.", Verdict.Correct,
                        "Confirmed. Two spellings are two different keys.")
                },
                new[]
                {
                    new FixOption("Create users with StringComparer.OrdinalIgnoreCase", FixQuality.Best,
                        new[]
                        {
                            "// users: Thea=1, Jean=2", "// comparer: OrdinalIgnoreCase", "var name = \"thea\";",
                            "var ok = users.ContainsKey(name);", "Console.WriteLine(ok);"
                        },
                        Run(3, 4, 5, true),
                        "Test passed: thea finds Thea. The dictionary now ignores case for every key."),
                    new FixOption("Change line 2 to: var name = \"Thea\";", FixQuality.SymptomOnly,
                        new[]
                        {
                            "// users: Thea=1, Jean=2", "var name = \"Thea\";", "var ok = users.ContainsKey(name);",
                            "Console.WriteLine(ok);"
                        },
                        Run(2, 3, 4, true, "Thea"),
                        "Test failed: it works for Thea only. A player typing jean still fails."),
                    new FixOption("Change line 2 to: var name = \"thea\".ToLower();", FixQuality.Wrong,
                        new[]
                        {
                            "// users: Thea=1, Jean=2", "var name = \"thea\".ToLower();",
                            "var ok = users.ContainsKey(name);", "Console.WriteLine(ok);"
                        },
                        Run(2, 3, 4, false),
                        "Test failed: thea was already lowercase. The stored key is still Thea, so it prints False.")
                },
                "Assert.IsTrue(users.ContainsKey(\"thea\"));",
                new[]
                {
                    "Is Thea in the dictionary? Look at the row.",
                    "Compare the stored key and the search text letter by letter.",
                    "Tell the dictionary to ignore case when it is created."
                },
                "Dictionary keys are case-sensitive unless you pass a comparer. Decide the rule once, where the dictionary is created. At work: logins by email fail when people type a different case.",
                "Investigate: which keys does users hold?",
                "Why is the answer False?");
        }

        // Shared run: users row, the typed name, the lookup result, the printed word.
        static List<TraceEvent> Run(int nameLine, int lookupLine, int printLine, bool found, string name = "thea")
        {
            return new List<TraceEvent>
            {
                TraceEvent.ArraySet(1, "users", Users),
                TraceEvent.LineExecuted(nameLine),
                TraceEvent.TextSet(nameLine, "name", name),
                TraceEvent.LineExecuted(lookupLine),
                TraceEvent.BoolSet(lookupLine, "ok", found),
                TraceEvent.LineExecuted(printLine),
                TraceEvent.OutputAppended(printLine, found ? "True" : "False")
            };
        }
    }
}
