using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room12
    {
        public const string Id = "1-2";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "Copy That",
                "Guard A's pouch should hold 8 coins after the bonus, but it still holds 5.",
                "Guard A ends with 8 coins.",
                Lines("int coinsB = coinsA;", "coinsB = coinsB + 3;", "Console.WriteLine(coinsA);"),
                string.Empty,
                Original(),
                new PredictQuestion(
                    "What does line 4 print?",
                    new[] { "3", "5", "8", "An error" },
                    1,
                    "Line 2 copies the number, so coinsB is its own pouch. Line 3 only changes coinsB."),
                new[]
                {
                    new Hypothesis("Line 3 changes both pouches.", Verdict.Wrong,
                        "Line 3 only uses the name coinsB, so only coinsB changes."),
                    new Hypothesis("Line 2 makes both guards share one pouch, like the chests.", Verdict.Close,
                        "Right line, wrong idea. Objects share. A number is copied whole, so each guard has its own."),
                    new Hypothesis("Line 2 copies the number, so line 3 only changes coinsB.", Verdict.Correct,
                        "Yes. Two names, two separate pouches.")
                },
                new[]
                {
                    new FixOption("Change line 3 to: coinsA = coinsA + 3;", FixQuality.Best,
                        Lines("int coinsB = coinsA;", "coinsA = coinsA + 3;", "Console.WriteLine(coinsA);"),
                        FixedOnA(),
                        "Test passed: coinsA is 8."),
                    new FixOption("Change line 4 to: Console.WriteLine(8);", FixQuality.SymptomOnly,
                        Lines("int coinsB = coinsA;", "coinsB = coinsB + 3;", "Console.WriteLine(8);"),
                        PrintsEight(),
                        "Test failed: it prints 8, but coinsA is still 5. You only hid the problem."),
                    new FixOption("Change line 3 to: coinsB = 3;", FixQuality.Wrong,
                        Lines("int coinsB = coinsA;", "coinsB = 3;", "Console.WriteLine(coinsA);"),
                        SetsB(),
                        "Test failed: coinsA is still 5, and coinsB lost its coins.")
                },
                "Assert.AreEqual(8, coinsA);",
                new[]
                {
                    "Which variable does line 3 change?",
                    "A number is copied as a whole. It is not shared.",
                    "After line 2, coinsA and coinsB are separate."
                },
                "A number variable holds the value itself, so int b = a; makes an independent copy. Objects (room 1.1) hold a reference, so their copies share. Know which one you have before you change a copy. At work: changing a copy of a price or a count never changes the original.",
                "Investigate: what does each guard hold?",
                "Why does Guard A still have 5?");
        }

        static string[] Lines(string line2, string line3, string line4)
        {
            return new[] { "int coinsA = 5;", line2, line3, line4 };
        }

        static List<TraceEvent> Start()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.VariableDeclared(1, "coinsA"),
                TraceEvent.ValueSet(1, "coinsA", 5),
                TraceEvent.LineExecuted(2),
                TraceEvent.VariableDeclared(2, "coinsB"),
                TraceEvent.ValueSet(2, "coinsB", 5),
                TraceEvent.LineExecuted(3)
            };
        }

        static List<TraceEvent> Original()
        {
            var events = Start();
            events.Add(TraceEvent.ValueSet(3, "coinsB", 8));
            events.Add(TraceEvent.LineExecuted(4));
            events.Add(TraceEvent.Output(4, "5"));
            return events;
        }

        static List<TraceEvent> FixedOnA()
        {
            var events = Start();
            events.Add(TraceEvent.ValueSet(3, "coinsA", 8));
            events.Add(TraceEvent.LineExecuted(4));
            events.Add(TraceEvent.Output(4, "8"));
            return events;
        }

        static List<TraceEvent> PrintsEight()
        {
            var events = Original();
            events[events.Count - 1] = TraceEvent.Output(4, "8");
            return events;
        }

        static List<TraceEvent> SetsB()
        {
            var events = Start();
            events.Add(TraceEvent.ValueSet(3, "coinsB", 3));
            events.Add(TraceEvent.LineExecuted(4));
            events.Add(TraceEvent.Output(4, "5"));
            return events;
        }
    }
}
