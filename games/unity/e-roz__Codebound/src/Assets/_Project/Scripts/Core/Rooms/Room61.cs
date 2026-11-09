using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room61
    {
        public const string Id = "6-1";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Lost Customers",
                "The report lists 2 customers. The shop has 3. Mokky is missing.",
                "Every customer must appear, even one with no orders.",
                Lines("INNER JOIN Orders o"),
                string.Empty,
                Result("INNER", "2 rows", "dropped, no order"),
                new PredictQuestion(
                    "Mokky has no orders. How many customers does this query return?",
                    new[] { "3", "2", "1", "0" },
                    1,
                    "INNER JOIN keeps only rows that match on both sides. Mokky matches no order, so Mokky is dropped."),
                new[]
                {
                    new Hypothesis("The Customers table lost a row.", Verdict.Wrong,
                        "Refuted. Customers still shows 3 rows."),
                    new Hypothesis("Mokky has no matching order.", Verdict.Close,
                        "Partly confirmed. But why does that remove Mokky from the result?"),
                    new Hypothesis("INNER JOIN drops customers that have no matching order.", Verdict.Correct,
                        "Confirmed. A customer without an order has nothing to join with.")
                },
                new[]
                {
                    new FixOption("Use LEFT JOIN", FixQuality.Best,
                        Lines("LEFT JOIN Orders o"),
                        Result("LEFT", "3 rows", "kept, Total is NULL"),
                        "Test passed: LEFT JOIN keeps every customer. Mokky shows with an empty Total."),
                    new FixOption("Add a dummy order for Mokky", FixQuality.SymptomOnly,
                        new[]
                        {
                            "INSERT INTO Orders", "VALUES (3, 0); -- Mokky", "SELECT c.Name, o.Total",
                            "FROM Customers c", "INNER JOIN Orders o", "  ON o.CustomerId = c.Id;"
                        },
                        Dummy(),
                        "Test failed: Mokky shows up, but with a fake order. The next customer without orders will vanish again."),
                    new FixOption("Use RIGHT JOIN", FixQuality.Wrong,
                        Lines("RIGHT JOIN Orders o"),
                        Result("RIGHT", "2 rows", "still dropped"),
                        "Test failed: RIGHT JOIN keeps every order, not every customer. Mokky is still missing.")
                },
                "Assert.AreEqual(3, Rows(leftJoin));",
                new[]
                {
                    "Tala: count the rows in Customers and in the result.",
                    "Tala: which side of the join keeps its unmatched rows?",
                    "Tala: LEFT keeps everything from the table on the left."
                },
                "INNER JOIN keeps only matches. LEFT JOIN keeps every row on the left, with NULL where nothing matches. At work: reports that silently lose rows are a classic SQL bug.",
                "Investigate: compare the row counts.",
                "Why is Mokky missing?");
        }

        static string[] Lines(string join) => new[]
        {
            "SELECT c.Name, o.Total", "FROM Customers c", join, "  ON o.CustomerId = c.Id;"
        };

        static List<TraceEvent> Result(string join, string joined, string mokky)
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(2),
                TraceEvent.TextSet(2, "customers", "3 rows"),
                TraceEvent.LineExecuted(3),
                TraceEvent.TextSet(3, "orders", "2 rows"),
                TraceEvent.TextSet(3, "join", join),
                TraceEvent.TextSet(4, "joined", joined),
                TraceEvent.TextSet(4, "Mokky", mokky)
            };
        }

        static List<TraceEvent> Dummy()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(2),
                TraceEvent.TextSet(2, "orders", "3 rows, one is fake"),
                TraceEvent.LineExecuted(5),
                TraceEvent.TextSet(5, "join", "INNER"),
                TraceEvent.TextSet(6, "joined", "3 rows"),
                TraceEvent.TextSet(6, "Mokky", "shown with a fake order")
            };
        }
    }
}
