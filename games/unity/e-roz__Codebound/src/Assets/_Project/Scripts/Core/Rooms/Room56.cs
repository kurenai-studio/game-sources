using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room56
    {
        public const string Id = "5-6";

        const string RealDb = "real Db, created inside Report";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "Depend on the Interface",
                "Review: Report tests are slow and fail whenever the database is down.",
                "Report must be testable without a real database.",
                Lines("    Db db = new Db();", "        => db.Rows;", "var r = new Report();"),
                string.Empty,
                Offline(),
                new PredictQuestion(
                    "The database is offline. What does the test do?",
                    new[] { "Passes", "Fails with an error", "Returns 0", "Is skipped" },
                    1,
                    "Report creates a real Db itself. When the database is offline, Count() throws and the test fails."),
                new[]
                {
                    new Hypothesis("Count() has a typo.", Verdict.Wrong,
                        "Refuted. It works whenever the database is up."),
                    new Hypothesis("The database is offline.", Verdict.Close,
                        "Partly confirmed. But why does a Report test need one at all?"),
                    new Hypothesis("Report creates its own Db with new, so a test cannot swap it.", Verdict.Correct,
                        "Confirmed. The class decides its own dependency.")
                },
                new[]
                {
                    new FixOption("Pass an IDb into the constructor", FixQuality.Best,
                        new[]
                        {
                            "class Report", "{", "    IDb db;", "    public Report(IDb d) => db = d;",
                            "    public int Count() => db.Rows;", "}", "var r = new Report(new FakeDb());",
                            "Console.WriteLine(r.Count());"
                        },
                        Faked(),
                        "Test passed: the test hands in a FakeDb, so no real database is needed."),
                    new FixOption("Return 0 when the database is offline", FixQuality.SymptomOnly,
                        Lines("    Db db = new Db();", "        => db.Online ? db.Rows : 0;", "var r = new Report();"),
                        Zero(),
                        "Test failed: it no longer crashes, but it tests nothing. The real Db is still created inside Report."),
                    new FixOption("Use a global: Db db = Db.Instance;", FixQuality.Wrong,
                        Lines("    Db db = Db.Instance;", "        => db.Rows;", "var r = new Report();"),
                        Offline(),
                        "Test failed: a global is still a real database. The test cannot replace it.")
                },
                "Assert.AreEqual(3, new Report(new FakeDb()).Count());",
                new[]
                {
                    "Tala: why does a Report test need a real Db?",
                    "Tala: who creates the Db? Look at line 3.",
                    "Tala: pass the Db in, and depend on an interface."
                },
                "Pass dependencies in (constructor injection) and depend on an interface. Then a test can give a fake. At work: this is why reviewers say do not use new for services.",
                "Investigate: where does Report get its Db?",
                "Why does the test need a real database?");
        }

        static string[] Lines(string field, string count, string create) => new[]
        {
            "class Report", "{", field, "    public int Count()", count, "}", create, "Console.WriteLine(r.Count());"
        };

        static List<TraceEvent> Offline()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(7),
                TraceEvent.TextSet(3, "db", RealDb),
                TraceEvent.LineExecuted(8),
                TraceEvent.LineExecuted(5),
                TraceEvent.ExceptionThrown(5, "DatabaseOffline")
            };
        }

        static List<TraceEvent> Zero()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(7),
                TraceEvent.TextSet(3, "db", RealDb),
                TraceEvent.LineExecuted(8),
                TraceEvent.LineExecuted(5),
                TraceEvent.CallReturned(5, "Count()", "0"),
                TraceEvent.OutputAppended(8, "0")
            };
        }

        static List<TraceEvent> Faked()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(7),
                TraceEvent.TextSet(7, "db", "FakeDb, a test stand-in"),
                TraceEvent.LineExecuted(8),
                TraceEvent.LineExecuted(5),
                TraceEvent.CallReturned(5, "Count()", "3"),
                TraceEvent.OutputAppended(8, "3")
            };
        }
    }
}
