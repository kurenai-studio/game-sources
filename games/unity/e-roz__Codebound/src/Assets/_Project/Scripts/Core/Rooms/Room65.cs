using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room65
    {
        public const string Id = "6-5";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Hidden 404",
                "Players see \"Not found\" as their profile. The app never reported an error.",
                "A failed request must be reported, not saved as data.",
                new[] { "var r = Get(\"/profile/9\");", "var data = r.Body;", "Save(data);" },
                string.Empty,
                Original(),
                new PredictQuestion(
                    "The server answers 404. What does Save() store?",
                    new[] { "The profile", "Not found", "Nothing", "A crash" },
                    1,
                    "The code never looks at the status. A 404 still has a body, the text Not found, so that text gets saved as if it were the profile."),
                new[]
                {
                    new Hypothesis("The server sent the wrong profile.", Verdict.Wrong,
                        "Refuted. The server sent no profile at all."),
                    new Hypothesis("The request failed.", Verdict.Close,
                        "Partly confirmed. But why did the code carry on?"),
                    new Hypothesis("The code ignores the status 404 and saves the error body as data.", Verdict.Correct,
                        "Confirmed. Always check the status before you use the body.")
                },
                new[]
                {
                    new FixOption("Check the status, retry only on 5xx", FixQuality.Best,
                        new[]
                        {
                            "var r = Get(\"/profile/9\");", "if (r.Status >= 500) Retry();",
                            "else if (r.Status != 200)", "    return Fail(r.Status);", "Save(r.Body);"
                        },
                        Reported(),
                        "Test passed: a 404 is reported and never saved. A 5xx is retried, because the server may recover."),
                    new FixOption("Skip short bodies", FixQuality.SymptomOnly,
                        new[] { "var r = Get(\"/profile/9\");", "if (r.Body.Length < 10) return;", "Save(r.Body);" },
                        Skipped(),
                        "Test failed: nothing bad is saved now, but nobody is told about the 404. A longer error text would still get through."),
                    new FixOption("Retry until it works", FixQuality.Wrong,
                        new[]
                        {
                            "var r = Get(\"/profile/9\");", "while (r.Status != 200)",
                            "    r = Get(\"/profile/9\");", "Save(r.Body);"
                        },
                        Forever(),
                        "Test failed: a 404 will not change by asking again. The loop never ends.")
                },
                "Assert.IsFalse(Saved(\"Not found\"));",
                new[]
                {
                    "Tala: what number did the server send back?",
                    "Tala: which line reads that number?",
                    "Tala: 4xx means your request is wrong. 5xx means the server failed."
                },
                "Status codes tell you if a call worked. 2xx is success, 4xx is your mistake, 5xx is the server's. Retry only on 5xx. At work: silent failures are the hardest bugs to find.",
                "Investigate: what is the status?",
                "Why was an error saved as a profile?");
        }

        static List<TraceEvent> Original()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.IntSet(1, "status", 404),
                TraceEvent.LineExecuted(2),
                TraceEvent.TextSet(2, "data", "Not found"),
                TraceEvent.LineExecuted(3),
                TraceEvent.TextSet(3, "saved", "Not found")
            };
        }

        static List<TraceEvent> Reported()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.IntSet(1, "status", 404),
                TraceEvent.LineExecuted(3),
                TraceEvent.LineExecuted(4),
                TraceEvent.TextSet(4, "result", "Fail(404), nothing saved")
            };
        }

        static List<TraceEvent> Skipped()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.IntSet(1, "status", 404),
                TraceEvent.LineExecuted(2),
                TraceEvent.TextSet(2, "saved", "nothing"),
                TraceEvent.TextSet(2, "caller", "never told about the 404")
            };
        }

        static List<TraceEvent> Forever()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.IntSet(1, "status", 404),
                TraceEvent.LineExecuted(2),
                TraceEvent.LineExecuted(3),
                TraceEvent.IntSet(3, "status", 404),
                TraceEvent.TextSet(3, "loop", "retries forever on 404")
            };
        }
    }
}
