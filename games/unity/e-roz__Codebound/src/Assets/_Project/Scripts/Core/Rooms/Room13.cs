using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room13
    {
        public const string Id = "1-3";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Shared Inventory",
                "The hero's inventory shows a Dagger he never picked up.",
                "Hero keeps only the Potion. Rogue keeps only the Dagger.",
                Lines("var rogue = hero;", "Console.WriteLine(hero.Count);"),
                string.Empty,
                Original(),
                new PredictQuestion(
                    "What does line 5 print?",
                    new[] { "0", "1", "2", "An error" },
                    2,
                    "Line 2 copies the reference, so both names use one list. The Potion and the Dagger both go into it."),
                new[]
                {
                    new Hypothesis("Line 3 adds the Potion to both lists.", Verdict.Wrong,
                        "There is only one list, so nothing is added \"to both\"."),
                    new Hypothesis("Line 2 makes a second list.", Verdict.Close,
                        "Right line, wrong idea. Line 2 only copies the reference. No new list is created."),
                    new Hypothesis("Line 2 gives rogue the same list, so both names use one list.", Verdict.Correct,
                        "Yes. Two names, one list.")
                },
                new[]
                {
                    new FixOption("Change line 2 to: var rogue = new List<string>(hero);", FixQuality.Best,
                        Lines("var rogue = new List<string>(hero);", "Console.WriteLine(hero.Count);"),
                        FixedWithCopy(),
                        "Test passed: hero holds 1 item and rogue holds 1 item."),
                    new FixOption("Change line 5 to: Console.WriteLine(1);", FixQuality.SymptomOnly,
                        Lines("var rogue = hero;", "Console.WriteLine(1);"),
                        PrintsOne(),
                        "Test failed: it prints 1, but the Dagger is still in the hero's list. You only hid the problem."),
                    new FixOption("Change line 5 to: Console.WriteLine(rogue.Count);", FixQuality.Wrong,
                        Lines("var rogue = hero;", "Console.WriteLine(rogue.Count);"),
                        PrintsRogueCount(),
                        "Test failed: rogue also holds 2 items. Nothing is separate yet.")
                },
                "Assert.AreEqual(1, hero.Count);\nAssert.AreEqual(1, rogue.Count);",
                new[]
                {
                    "How many lists exist after line 2?",
                    "A list variable holds a reference, like the chest in room 1.1.",
                    "new List<string>(x) builds a separate list with the same items."
                },
                "A List is an object, so b = a shares it. To get an independent list, copy it: new List<string>(a). At work: the bug behind \"my cart shows another user's items\".",
                "Investigate: which list does each name use?",
                "Why does the hero hold a Dagger?");
        }

        static string[] Lines(string line2, string line5)
        {
            return new[]
            {
                "var hero = new List<string>();", line2, "hero.Add(\"Potion\");", "rogue.Add(\"Dagger\");", line5
            };
        }

        static List<TraceEvent> Start(bool copy)
        {
            var events = new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.VariableDeclared(1, "hero"),
                TraceEvent.ObjectCreated(1, 1, "List"),
                TraceEvent.ReferenceAssigned(1, "hero", 1),
                TraceEvent.LineExecuted(2),
                TraceEvent.VariableDeclared(2, "rogue")
            };
            if (copy)
            {
                events.Add(TraceEvent.ObjectCreated(2, 2, "List"));
                events.Add(TraceEvent.ReferenceAssigned(2, "rogue", 2));
            }
            else
            {
                events.Add(TraceEvent.ReferenceAssigned(2, "rogue", 1));
            }
            events.Add(TraceEvent.LineExecuted(3));
            events.Add(TraceEvent.ObjectMutated(3, 1, "Potion added"));
            events.Add(TraceEvent.LineExecuted(4));
            events.Add(TraceEvent.ObjectMutated(4, copy ? 2 : 1, "Dagger added"));
            events.Add(TraceEvent.LineExecuted(5));
            return events;
        }

        static List<TraceEvent> Original()
        {
            var events = Start(false);
            events.Add(TraceEvent.Output(5, "2"));
            return events;
        }

        static List<TraceEvent> FixedWithCopy()
        {
            var events = Start(true);
            events.Add(TraceEvent.Output(5, "1"));
            return events;
        }

        static List<TraceEvent> PrintsOne()
        {
            var events = Start(false);
            events.Add(TraceEvent.Output(5, "1"));
            return events;
        }

        static List<TraceEvent> PrintsRogueCount()
        {
            var events = Start(false);
            events.Add(TraceEvent.Output(5, "2"));
            return events;
        }
    }
}
