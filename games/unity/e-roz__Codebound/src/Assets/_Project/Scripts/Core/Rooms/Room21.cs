using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room21
    {
        public const string Id = "2-1";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Gate Rules",
                "A member with no pass walked into the vault.",
                "Everyone needs a pass. Members and guests both get in with one.",
                Lines("bool ok = member || guest && pass;", "bool member = true;"),
                string.Empty,
                Original(true),
                new PredictQuestion(
                    "What does line 5 print?",
                    new[] { "True", "False", "An error", "Nothing" },
                    0,
                    "&& runs before ||. guest && pass is false, then member || false is true."),
                new[]
                {
                    new Hypothesis("pass is true.", Verdict.Wrong,
                        "Check line 3. pass is false."),
                    new Hypothesis("|| lets a member in.", Verdict.Close,
                        "Partly. But why is the pass never checked for a member? Look at which part runs first."),
                    new Hypothesis("&& runs before ||, so the pass only applies to the guest, not the member.",
                        Verdict.Correct,
                        "Yes. && goes first, so member || (guest && pass).")
                },
                new[]
                {
                    new FixOption("Change line 4 to: bool ok = (member || guest) && pass;", FixQuality.Best,
                        Lines("bool ok = (member || guest) && pass;", "bool member = true;"),
                        FixedWithParentheses(),
                        "Test passed: ok is false. A member with no pass stays out."),
                    new FixOption("Change line 1 to: bool member = false;", FixQuality.SymptomOnly,
                        Lines("bool ok = member || guest && pass;", "bool member = false;"),
                        Original(false),
                        "Test failed: you changed the visitor, not the rule. A member with no pass would still get in."),
                    new FixOption("Change line 4 to: bool ok = member || guest || pass;", FixQuality.Wrong,
                        Lines("bool ok = member || guest || pass;", "bool member = true;"),
                        AnyoneGetsIn(),
                        "Test failed: ok is true. Now the pass is not required at all.")
                },
                "Assert.IsFalse(ok);",
                new[]
                {
                    "Which part of line 4 runs first?",
                    "&& binds tighter than ||.",
                    "Parentheses decide the order."
                },
                "&& is evaluated before ||. Use parentheses to say what you mean: (member || guest) && pass. At work: a missing pair of parentheses is a classic permission bug.",
                "Investigate: which part of line 4 runs first?",
                "Why did the member get in?");
        }

        static string[] Lines(string line4, string line1)
        {
            return new[] { line1, "bool guest = false;", "bool pass = false;", line4, "Console.WriteLine(ok);" };
        }

        static string Word(bool value) => value ? "True" : "False";

        static List<TraceEvent> Inputs(bool member)
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.BoolSet(1, "member", member),
                TraceEvent.LineExecuted(2),
                TraceEvent.BoolSet(2, "guest", false),
                TraceEvent.LineExecuted(3),
                TraceEvent.BoolSet(3, "pass", false),
                TraceEvent.LineExecuted(4)
            };
        }

        // member || guest && pass: && goes first (guest and pass are both false, so guest && pass is false).
        static List<TraceEvent> Original(bool member)
        {
            var events = Inputs(member);
            events.Add(TraceEvent.Evaluated(4, "guest && pass", false));
            events.Add(TraceEvent.Evaluated(4, "member || false", member));
            events.Add(TraceEvent.BoolSet(4, "ok", member));
            events.Add(TraceEvent.LineExecuted(5));
            events.Add(TraceEvent.Output(5, Word(member)));
            return events;
        }

        static List<TraceEvent> FixedWithParentheses()
        {
            var events = Inputs(true);
            events.Add(TraceEvent.Evaluated(4, "member || guest", true));
            events.Add(TraceEvent.Evaluated(4, "true && pass", false));
            events.Add(TraceEvent.BoolSet(4, "ok", false));
            events.Add(TraceEvent.LineExecuted(5));
            events.Add(TraceEvent.Output(5, "False"));
            return events;
        }

        static List<TraceEvent> AnyoneGetsIn()
        {
            var events = Inputs(true);
            events.Add(TraceEvent.Evaluated(4, "member || guest", true));
            events.Add(TraceEvent.Evaluated(4, "true || pass", true));
            events.Add(TraceEvent.BoolSet(4, "ok", true));
            events.Add(TraceEvent.LineExecuted(5));
            events.Add(TraceEvent.Output(5, "True"));
            return events;
        }
    }
}
