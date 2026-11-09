using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room26
    {
        public const string Id = "2-6";

        const string Input = "\"abc\"";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Visitor Form",
                "A visitor typed abc as their age. The form crashes.",
                "Read the age safely. Bad input must not crash.",
                new[] { "string t = \"abc\";", "int age = int.Parse(t);", "Console.WriteLine(age);" },
                string.Empty,
                Crash(),
                new PredictQuestion(
                    "What happens when this runs?",
                    new[] { "It prints 0", "It prints abc", "It crashes with an error", "It prints nothing" },
                    2,
                    "int.Parse expects a number. abc is not one, so it throws a FormatException."),
                new[]
                {
                    new Hypothesis("age is too small.", Verdict.Wrong,
                        "The crash happens before age gets any value."),
                    new Hypothesis("The text is not a number.", Verdict.Close,
                        "Yes, but what should the code do about it?"),
                    new Hypothesis("int.Parse throws on bad input and nothing checks first.", Verdict.Correct,
                        "Yes. User input can be anything. Check it before you trust it.")
                },
                new[]
                {
                    new FixOption("Check with TryParse and print Bad age", FixQuality.Best,
                        new[]
                        {
                            "string t = \"abc\";", "if (!int.TryParse(t, out int age))",
                            "    Console.WriteLine(\"Bad age\");", "else Console.WriteLine(age);"
                        },
                        TryParseFails(),
                        "Test passed: abc prints Bad age. 21 would print 21."),
                    new FixOption("Change line 2 to: int.TryParse(t, out int age);", FixQuality.SymptomOnly,
                        new[] { "string t = \"abc\";", "int.TryParse(t, out int age);", "Console.WriteLine(age);" },
                        ZeroAge(),
                        "Test failed: it does not crash, but abc silently becomes age 0 and nobody is told."),
                    new FixOption("Change line 2 to: int age = Convert.ToInt32(t);", FixQuality.Wrong,
                        new[] { "string t = \"abc\";", "int age = Convert.ToInt32(t);", "Console.WriteLine(age);" },
                        Crash(),
                        "Test failed: Convert.ToInt32 also throws a FormatException on abc.")
                },
                "Assert.AreEqual(\"Bad age\", output); // for \"abc\"",
                new[]
                {
                    "What does int.Parse do with text that is not a number?",
                    "It throws. Is there a way to ask first, without throwing?",
                    "int.TryParse returns true or false. Check it, then decide."
                },
                "User input is hostile. int.Parse throws on bad text. int.TryParse returns false and lets you decide, but ignoring that false hides the problem. At work: forms, APIs and files send you values you did not expect.",
                "Investigate: what does int.Parse get?",
                "Why does the form crash?");
        }

        static List<TraceEvent> Start()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.TextSet(1, "t", Input),
                TraceEvent.LineExecuted(2)
            };
        }

        static List<TraceEvent> Crash()
        {
            var events = Start();
            events.Add(TraceEvent.ExceptionThrown(2, "FormatException"));
            return events;
        }

        static List<TraceEvent> TryParseFails()
        {
            var events = Start();
            events.Add(TraceEvent.Evaluated(2, "TryParse(abc)", false));
            events.Add(TraceEvent.LineExecuted(3));
            events.Add(TraceEvent.OutputAppended(3, "Bad age"));
            return events;
        }

        static List<TraceEvent> ZeroAge()
        {
            var events = Start();
            events.Add(TraceEvent.IntSet(2, "age", 0));
            events.Add(TraceEvent.LineExecuted(3));
            events.Add(TraceEvent.OutputAppended(3, "0"));
            return events;
        }
    }
}
