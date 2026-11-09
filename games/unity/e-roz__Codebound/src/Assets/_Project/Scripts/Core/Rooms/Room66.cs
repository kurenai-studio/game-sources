using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room66
    {
        public const string Id = "6-6";

        const string Payload = "x' OR '1'='1";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "Trust No Input",
                "Review: the login search builds SQL from what the player types.",
                "Typed text must never become part of the SQL.",
                new[]
                {
                    "var name = Input();", "var q = \"SELECT * FROM Users\"",
                    "  + \" WHERE Name='\" + name + \"'\";", "Run(q);"
                },
                string.Empty,
                Attack(3, 4, 500, "every user, because OR 1=1 is always true"),
                new PredictQuestion(
                    "A player types x' OR '1'='1 as the name. What does Run return?",
                    new[] { "No rows", "Every user", "One user", "An error" },
                    1,
                    "The typed quote closes the string and OR '1'='1' is always true. The WHERE matches every row."),
                new[]
                {
                    new Hypothesis("Run has a bug.", Verdict.Wrong,
                        "Refuted. Run does exactly what the SQL text says."),
                    new Hypothesis("The player typed something strange.", Verdict.Close,
                        "Partly confirmed. But why did strange text change the query?"),
                    new Hypothesis("The input is glued into the SQL text, so it can add its own SQL.", Verdict.Correct,
                        "Confirmed. That is SQL injection.")
                },
                new[]
                {
                    new FixOption("Use a parameterised query", FixQuality.Best,
                        new[]
                        {
                            "var name = Input();", "var q = \"SELECT * FROM Users\"",
                            "  + \" WHERE Name = @name\";", "Run(q, new { name });"
                        },
                        Safe(),
                        "Test passed: the name travels as data, never as SQL. The attack finds nobody."),
                    new FixOption("Remove quote marks from the input", FixQuality.SymptomOnly,
                        new[]
                        {
                            "var name = Input();", "name = name.Replace(\"'\", \"\");", "var q = \"SELECT * FROM Users\"",
                            "  + \" WHERE Name='\" + name + \"'\";", "Run(q);"
                        },
                        Stripped(),
                        "Test failed: this attack is stopped, but the query is still built from text. Other tricks get through."),
                    new FixOption("Reject names longer than 20", FixQuality.Wrong,
                        new[]
                        {
                            "var name = Input();", "if (name.Length > 20) return;", "var q = \"SELECT * FROM Users\"",
                            "  + \" WHERE Name='\" + name + \"'\";", "Run(q);"
                        },
                        Short(),
                        "Test failed: the attack is only 13 characters. It passes the check and returns every user.")
                },
                "Assert.AreEqual(0, Run(safe, attackText));",
                new[]
                {
                    "Tala: look at the q row after line 3.",
                    "Tala: where does the typed text end up?",
                    "Tala: send values as parameters, not inside the SQL."
                },
                "Never build SQL by joining strings with user input. Use parameters, so the database treats input as data only. At work: SQL injection is one of the most common web attacks.",
                "Investigate: what does q look like?",
                "Why did one name return every user?");
        }

        static List<TraceEvent> Attack(int qLine, int runLine, int rows, string result)
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.TextSet(1, "name", Payload),
                TraceEvent.LineExecuted(qLine),
                TraceEvent.TextSet(qLine, "q", "WHERE Name='x' OR '1'='1'"),
                TraceEvent.LineExecuted(runLine),
                TraceEvent.IntSet(runLine, "rows returned", rows),
                TraceEvent.TextSet(runLine, "result", result)
            };
        }

        static List<TraceEvent> Safe()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.TextSet(1, "name", Payload),
                TraceEvent.TextSet(3, "q", "WHERE Name = @name"),
                TraceEvent.LineExecuted(4),
                TraceEvent.TextSet(4, "name is", "data, never code"),
                TraceEvent.IntSet(4, "rows returned", 0)
            };
        }

        static List<TraceEvent> Stripped()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.TextSet(1, "name", Payload),
                TraceEvent.LineExecuted(2),
                TraceEvent.TextSet(2, "name", "x OR 1=1"),
                TraceEvent.LineExecuted(5),
                TraceEvent.IntSet(5, "rows returned", 0),
                TraceEvent.TextSet(5, "risk", "other tricks still get through")
            };
        }

        static List<TraceEvent> Short()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.TextSet(1, "name", Payload),
                TraceEvent.TextSet(2, "length", "13, passes the check"),
                TraceEvent.LineExecuted(5),
                TraceEvent.IntSet(5, "rows returned", 500),
                TraceEvent.TextSet(5, "result", "every user")
            };
        }
    }
}
