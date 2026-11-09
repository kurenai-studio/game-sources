using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room36
    {
        public const string Id = "3-6";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Forty-Line Monster",
                "Checkout is 40 lines long. Nobody dares to change it.",
                "Split Checkout so each method has one clear job.",
                new[]
                {
                    "void Checkout(Order o)", "{", "    // 1 validate the order", "    // 2 work out the price",
                    "    // 3 save to the database", "    // 4 send the receipt", "    // ...34 more lines", "}"
                },
                string.Empty,
                Jobs(),
                new PredictQuestion(
                    "How many different jobs does Checkout do?",
                    new[] { "1", "2", "4", "40" },
                    2,
                    "Validate, price, save and send the receipt: four jobs in one method."),
                new[]
                {
                    new Hypothesis("The comments make it clear enough.", Verdict.Wrong,
                        "Refuted. Comments do not stop a change to one job from breaking another."),
                    new Hypothesis("The method is too long to read.", Verdict.Close,
                        "Partly confirmed. But length is a symptom. What is the real problem?"),
                    new Hypothesis("Four jobs share one method, so a change to one can break the others.", Verdict.Correct,
                        "Confirmed. One method, one job.")
                },
                new[]
                {
                    new FixOption("Split into Validate, Price, Save, SendReceipt", FixQuality.Best,
                        Split("Validate(o);", "Price(o);", "Save(o);", "SendReceipt(o);"),
                        Calls("Validate(o)", "Price(o)", "Save(o)", "SendReceipt(o)"),
                        "Test passed: every method has one job and a name that says it."),
                    new FixOption("Split into Part1, Part2", FixQuality.SymptomOnly,
                        Split("Part1(o);", "Part2(o);", null, null),
                        Calls("Part1(o)", "Part2(o)", null, null),
                        "Test failed: shorter, but the names say nothing and each part still mixes jobs."),
                    new FixOption("Move all the lines into DoEverything", FixQuality.Wrong,
                        Split("DoEverything(o);", null, null, null),
                        Calls("DoEverything(o)", null, null, null),
                        "Test failed: you only moved the monster. It still does four jobs.")
                },
                "// review: one job per method, names that say what they do",
                new[]
                {
                    "Count the verbs in the comments.",
                    "Each verb is a job. A method should have one.",
                    "Make one method per job and name it after that job."
                },
                "One method, one job, and a name that says it. Short methods are easier to test, review and change. At work: code review comments about this are the most common ones.",
                "Investigate: how many jobs do the comments name?",
                "What is wrong with Checkout?");
        }

        static string[] Split(string a, string b, string c, string d)
        {
            var lines = new List<string> { "void Checkout(Order o)", "{" };
            foreach (var call in new[] { a, b, c, d })
                if (call != null) lines.Add("    " + call);
            lines.Add("}");
            return lines.ToArray();
        }

        // The four jobs shown as rows, one per comment line.
        static List<TraceEvent> Jobs()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(3),
                TraceEvent.TextSet(3, "job 1", "validate the order"),
                TraceEvent.LineExecuted(4),
                TraceEvent.TextSet(4, "job 2", "work out the price"),
                TraceEvent.LineExecuted(5),
                TraceEvent.TextSet(5, "job 3", "save to the database"),
                TraceEvent.LineExecuted(6),
                TraceEvent.TextSet(6, "job 4", "send the receipt"),
                TraceEvent.OutputAppended(6, "4")
            };
        }

        // Checkout now only calls the smaller methods. Each call line is 3, 4, ... (line 3 is the first call).
        static List<TraceEvent> Calls(params string[] calls)
        {
            var events = new List<TraceEvent>();
            var line = 3;
            foreach (var call in calls)
            {
                if (call == null) continue;
                events.Add(TraceEvent.LineExecuted(line));
                events.Add(TraceEvent.CallReturned(line, call, "done"));
                line++;
            }
            return events;
        }
    }
}
