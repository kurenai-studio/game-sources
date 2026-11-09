using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room11
    {
        public const string Id = "1-1";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Twin Guards",
                "Vault B has a sword nobody put there.",
                "Vault A keeps the Sword. Vault B stays empty.",
                new[]
                {
                    "Chest vaultA = new Chest();",
                    "Chest vaultB = vaultA;",
                    "vaultA.Add(\"Sword\");",
                    "Console.WriteLine(vaultB.Count);"
                },
                "class Chest\n{\n    List<string> items = new List<string>();\n    public void Add(string item) => items.Add(item);\n    public int Count => items.Count;\n}",
                Original(),
                new PredictQuestion(
                    "What does line 4 print?",
                    new[] { "0", "1", "2", "An error" },
                    1,
                    "Line 2 copies the reference, not the chest, so both names point to one chest."),
                new[]
                {
                    new Hypothesis("Line 3 adds the sword to both chests.", Verdict.Wrong,
                        "There is only one chest, so nothing is added \"to both\"."),
                    new Hypothesis("Line 2 makes a second chest.", Verdict.Close,
                        "Right line, wrong idea. Line 2 only copies the reference. No new chest is created."),
                    new Hypothesis("Line 2 copies the reference, so both guards point to one chest.", Verdict.Correct,
                        "Yes. Two names, one chest.")
                },
                new[]
                {
                    new FixOption("Change line 2 to: Chest vaultB = new Chest();", FixQuality.Best,
                        Lines("Chest vaultB = new Chest();"), FixedWithNewChest(),
                        "Test passed: vaultA holds 1 item and vaultB holds 0."),
                    new FixOption("Add after line 4: vaultA.Remove(\"Sword\");", FixQuality.SymptomOnly,
                        new[]
                        {
                            "Chest vaultA = new Chest();", "Chest vaultB = vaultA;", "vaultA.Add(\"Sword\");",
                            "Console.WriteLine(vaultB.Count);", "vaultA.Remove(\"Sword\");"
                        },
                        RemovedAfterwards(),
                        "Test failed: vaultA lost its Sword. Removing it only hides the problem. Both guards still share one chest."),
                    new FixOption("Change line 2 to: Chest vaultB = null;", FixQuality.Wrong,
                        Lines("Chest vaultB = null;"), NullGuard(),
                        "Test failed: line 4 threw a NullReferenceException. Guard B holds nothing.")
                },
                "Assert.AreEqual(1, vaultA.Count);\nAssert.AreEqual(0, vaultB.Count);",
                new[]
                {
                    "How many chests exist after line 2?",
                    "A class variable holds a reference, like a rope to the chest.",
                    "Line 2 creates a second rope, not a second chest."
                },
                "Assigning one object variable to another copies the reference, not the object. At work this is the bug behind shared caches and settings that change behind your back.");
        }

        // The original code with line 2 replaced.
        static string[] Lines(string line2)
        {
            return new[]
            {
                "Chest vaultA = new Chest();", line2, "vaultA.Add(\"Sword\");", "Console.WriteLine(vaultB.Count);"
            };
        }

        static List<TraceEvent> Original()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.VariableDeclared(1, "vaultA"),
                TraceEvent.ObjectCreated(1, 1, "Chest"),
                TraceEvent.ReferenceAssigned(1, "vaultA", 1),
                TraceEvent.LineExecuted(2),
                TraceEvent.VariableDeclared(2, "vaultB"),
                TraceEvent.ReferenceAssigned(2, "vaultB", 1),
                TraceEvent.LineExecuted(3),
                TraceEvent.ObjectMutated(3, 1, "Sword added"),
                TraceEvent.LineExecuted(4),
                TraceEvent.Output(4, "1")
            };
        }

        static List<TraceEvent> FixedWithNewChest()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.VariableDeclared(1, "vaultA"),
                TraceEvent.ObjectCreated(1, 1, "Chest"),
                TraceEvent.ReferenceAssigned(1, "vaultA", 1),
                TraceEvent.LineExecuted(2),
                TraceEvent.VariableDeclared(2, "vaultB"),
                TraceEvent.ObjectCreated(2, 2, "Chest"),
                TraceEvent.ReferenceAssigned(2, "vaultB", 2),
                TraceEvent.LineExecuted(3),
                TraceEvent.ObjectMutated(3, 1, "Sword added"),
                TraceEvent.LineExecuted(4),
                TraceEvent.Output(4, "0")
            };
        }

        static List<TraceEvent> RemovedAfterwards()
        {
            var events = Original();
            events.Add(TraceEvent.LineExecuted(5));
            events.Add(TraceEvent.ObjectMutated(5, 1, "Sword removed"));
            return events;
        }

        static List<TraceEvent> NullGuard()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.VariableDeclared(1, "vaultA"),
                TraceEvent.ObjectCreated(1, 1, "Chest"),
                TraceEvent.ReferenceAssigned(1, "vaultA", 1),
                TraceEvent.LineExecuted(2),
                TraceEvent.VariableDeclared(2, "vaultB"),
                TraceEvent.NullAssigned(2, "vaultB"),
                TraceEvent.LineExecuted(3),
                TraceEvent.ObjectMutated(3, 1, "Sword added"),
                TraceEvent.LineExecuted(4),
                TraceEvent.ExceptionThrown(4, "NullReferenceException")
            };
        }
    }
}
