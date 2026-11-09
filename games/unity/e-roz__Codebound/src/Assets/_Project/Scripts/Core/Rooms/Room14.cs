using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room14
    {
        public const string Id = "1-4";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "Copy of a Copy",
                "The rogue upgraded his sword to 9 damage, and the hero's sword changed too.",
                "Hero's sword stays at 5. Rogue's sword becomes 9.",
                Lines("var rogue = new List<Sword>(hero);", "rogue[0].Damage = 9;", "Console.WriteLine(hero[0].Damage);"),
                "class Sword\n{\n    public int Damage;\n    public Sword(int damage) => Damage = damage;\n}",
                Original("9"),
                new PredictQuestion(
                    "What does line 5 print?",
                    new[] { "5", "9", "14", "An error" },
                    1,
                    "Line 3 copies the list, not the Sword inside it. Both lists hold the same Sword, so line 4 changes it for both."),
                new[]
                {
                    new Hypothesis("Line 3 makes both names use one list, like in room 1.3.", Verdict.Wrong,
                        "There are two lists now (#1 and #3). Look at what is inside them."),
                    new Hypothesis("Line 4 changes the hero's list.", Verdict.Close,
                        "Right line, wrong target. Line 4 does not change a list. It changes the Sword inside."),
                    new Hypothesis("The lists are separate, but both hold the same Sword, and line 4 changes that Sword.",
                        Verdict.Correct,
                        "Yes. Two lists, one Sword.")
                },
                new[]
                {
                    new FixOption("Change line 4 to: rogue[0] = new Sword(9);", FixQuality.Best,
                        Lines("var rogue = new List<Sword>(hero);", "rogue[0] = new Sword(9);",
                            "Console.WriteLine(hero[0].Damage);"),
                        FixedWithNewSword(),
                        "Test passed: hero's sword is 5 and rogue's sword is 9."),
                    new FixOption("Change line 5 to: Console.WriteLine(5);", FixQuality.SymptomOnly,
                        Lines("var rogue = new List<Sword>(hero);", "rogue[0].Damage = 9;", "Console.WriteLine(5);"),
                        Original("5"),
                        "Test failed: it prints 5, but both lists still share one Sword. You only hid the problem."),
                    new FixOption("Change line 3 to: var rogue = new List<Sword>();", FixQuality.Wrong,
                        Lines("var rogue = new List<Sword>();", "rogue[0].Damage = 9;", "Console.WriteLine(hero[0].Damage);"),
                        EmptyRogueList(),
                        "Test failed: line 4 threw ArgumentOutOfRangeException. The rogue's list is empty.")
                },
                "Assert.AreEqual(5, hero[0].Damage);\nAssert.AreEqual(9, rogue[0].Damage);",
                new[]
                {
                    "How many Sword objects exist after line 3?",
                    "new List<Sword>(hero) copies the list, not the swords.",
                    "Both lists hold a reference to the same Sword."
                },
                "Copying a list copies the list, not the objects inside. Both lists still point to the same Sword. This is a shallow copy. To change one without the other, give the copy its own new object. At work: a copied config that still shares inner objects.",
                "Investigate: what does each list hold?",
                "Why did the hero's sword change?");
        }

        static string[] Lines(string line3, string line4, string line5)
        {
            return new[] { "var hero = new List<Sword>();", "hero.Add(new Sword(5));", line3, line4, line5 };
        }

        // Lines 1 to 3 of the original code: hero's list #1, Sword #2, and the rogue's copy #3.
        static List<TraceEvent> Start()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.VariableDeclared(1, "hero"),
                TraceEvent.ObjectCreated(1, 1, "List"),
                TraceEvent.ReferenceAssigned(1, "hero", 1),
                TraceEvent.LineExecuted(2),
                TraceEvent.ItemObjectCreated(2, 2, "Sword", "Damage", 5),
                TraceEvent.ItemAdded(2, 1, 2),
                TraceEvent.LineExecuted(3),
                TraceEvent.VariableDeclared(3, "rogue"),
                TraceEvent.ListCopied(3, 3, 1, "List"),
                TraceEvent.ReferenceAssigned(3, "rogue", 3)
            };
        }

        static List<TraceEvent> Original(string printed)
        {
            var events = Start();
            events.Add(TraceEvent.LineExecuted(4));
            events.Add(TraceEvent.FieldSet(4, 2, "Damage", 9));
            events.Add(TraceEvent.LineExecuted(5));
            events.Add(TraceEvent.Output(5, printed));
            return events;
        }

        static List<TraceEvent> FixedWithNewSword()
        {
            var events = Start();
            events.Add(TraceEvent.LineExecuted(4));
            events.Add(TraceEvent.ItemObjectCreated(4, 4, "Sword", "Damage", 9));
            events.Add(TraceEvent.ItemReplaced(4, 3, 0, 4));
            events.Add(TraceEvent.LineExecuted(5));
            events.Add(TraceEvent.Output(5, "5"));
            return events;
        }

        static List<TraceEvent> EmptyRogueList()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.VariableDeclared(1, "hero"),
                TraceEvent.ObjectCreated(1, 1, "List"),
                TraceEvent.ReferenceAssigned(1, "hero", 1),
                TraceEvent.LineExecuted(2),
                TraceEvent.ItemObjectCreated(2, 2, "Sword", "Damage", 5),
                TraceEvent.ItemAdded(2, 1, 2),
                TraceEvent.LineExecuted(3),
                TraceEvent.VariableDeclared(3, "rogue"),
                TraceEvent.ObjectCreated(3, 3, "List"),
                TraceEvent.ReferenceAssigned(3, "rogue", 3),
                TraceEvent.LineExecuted(4),
                TraceEvent.ExceptionThrown(4, "ArgumentOutOfRangeException")
            };
        }
    }
}
