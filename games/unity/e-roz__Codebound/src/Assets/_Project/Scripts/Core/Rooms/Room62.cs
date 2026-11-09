using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room62
    {
        public const string Id = "6-2";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Missing WHERE",
                "Support asked to reset Thea's gold. Now all 500 players have 0 gold.",
                "Only Thea's row may change.",
                Lines("SET Gold = 0;"),
                string.Empty,
                Result(500, "reset for every player"),
                new PredictQuestion(
                    "How many rows does this UPDATE change?",
                    new[] { "1", "500", "0", "An error" },
                    1,
                    "UPDATE with no WHERE touches every row in the table. There are 500 players."),
                new[]
                {
                    new Hypothesis("The Gold column is wrong.", Verdict.Wrong,
                        "Refuted. Gold is the right column."),
                    new Hypothesis("The query changed more rows than Thea's.", Verdict.Close,
                        "Partly confirmed. What decides which rows change?"),
                    new Hypothesis("There is no WHERE, so UPDATE hits every row.", Verdict.Correct,
                        "Confirmed. Without WHERE, the whole table is the target.")
                },
                new[]
                {
                    new FixOption("Add WHERE Id = 7", FixQuality.Best,
                        Lines("SET Gold = 0", "WHERE Id = 7;"),
                        Result(1, "reset for Thea only"),
                        "Test passed: one row changed. Thea's. Run a SELECT with the same WHERE first to check."),
                    new FixOption("Add LIMIT 1", FixQuality.SymptomOnly,
                        Lines("SET Gold = 0", "LIMIT 1;"),
                        Result(1, "any one row, maybe not Thea"),
                        "Test failed: one row changed, but which one? LIMIT does not pick Thea."),
                    new FixOption("Add WHERE Gold > 0", FixQuality.Wrong,
                        Lines("SET Gold = 0", "WHERE Gold > 0;"),
                        Result(499, "reset for everyone with gold"),
                        "Test failed: almost every player still has gold, so 499 rows change.")
                },
                "Assert.AreEqual(1, Update(withWhere));",
                new[]
                {
                    "Tala: read the rows changed number.",
                    "Tala: what tells UPDATE which row to change?",
                    "Tala: add a WHERE that names Thea."
                },
                "UPDATE and DELETE without WHERE hit every row. At work: write the WHERE first, run it as a SELECT, then change it to UPDATE. Many teams also wrap changes in a transaction.",
                "Investigate: how many rows changed?",
                "Why did every player lose gold?");
        }

        static string[] Lines(string set, string last = null) => last == null
            ? new[] { "-- reset Thea's gold", "UPDATE Players", set }
            : new[] { "-- reset Thea's gold", "UPDATE Players", set, last };

        static List<TraceEvent> Result(int rows, string note)
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(2),
                TraceEvent.LineExecuted(3),
                TraceEvent.IntSet(3, "rows changed", rows),
                TraceEvent.TextSet(3, "result", note)
            };
        }
    }
}
