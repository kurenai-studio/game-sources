using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room16
    {
        public const string Id = "1-6";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "Who Changed My Guard?",
                "Interview: Reset should empty the vault, but it still holds the Gem. Explain why.",
                "After line 3, the vault is empty.",
                Lines("Reset(vault);", "Console.WriteLine(vault.Count);"),
                "void Fill(Chest c)\n{\n    c.Add(\"Gem\");\n}\nvoid Reset(Chest c)\n{\n    c = new Chest();\n}",
                Original("1"),
                new PredictQuestion(
                    "What does line 4 print?",
                    new[] { "0", "1", "2", "An error" },
                    1,
                    "Fill changes the chest that vault points to. Reset only changes its own copy of the reference, so vault still points to the full chest."),
                new[]
                {
                    new Hypothesis("Reset never runs.", Verdict.Wrong,
                        "Reset does run on line 3. Watch the helper guard c appear."),
                    new Hypothesis("Reset makes a new chest, but the old chest is still full.", Verdict.Close,
                        "True, but that is not the whole reason. Why does vault not use the new chest?"),
                    new Hypothesis("Reset only changes its own copy of the reference (c), so vault still points to the old chest.",
                        Verdict.Correct,
                        "Yes. c is a copy of the reference. Changing c does not change vault.")
                },
                new[]
                {
                    new FixOption("Change line 3 to: vault = new Chest();", FixQuality.Best,
                        Lines("vault = new Chest();", "Console.WriteLine(vault.Count);"),
                        FixedByReassigning(),
                        "Test passed: vault holds 0 items."),
                    new FixOption("Change line 4 to: Console.WriteLine(0);", FixQuality.SymptomOnly,
                        Lines("Reset(vault);", "Console.WriteLine(0);"),
                        Original("0"),
                        "Test failed: it prints 0, but vault still holds the Gem. You only hid the problem."),
                    new FixOption("Change line 3 to: Fill(vault);", FixQuality.Wrong,
                        Lines("Fill(vault);", "Console.WriteLine(vault.Count);"),
                        FilledAgain(),
                        "Test failed: vault holds 2 items. Calling Fill again made it worse.")
                },
                "Assert.AreEqual(0, vault.Count);",
                new[]
                {
                    "Does Reset change the chest, or only what c points to?",
                    "c is a copy of the reference. Reassigning c does not change vault.",
                    "To change vault, assign to vault itself."
                },
                "A method receives a copy of the reference. c.Add(...) changes the caller's object. c = new Chest() only changes the copy. To replace the caller's object, assign it where the variable lives. At work: a favourite interview question.",
                "Investigate: which chest does vault point to?",
                "Why is the vault not empty?");
        }

        static string[] Lines(string line3, string line4)
        {
            return new[] { "Chest vault = new Chest();", "Fill(vault);", line3, line4 };
        }

        // Lines 1 and 2: vault points to chest #1, and Fill adds the Gem through its helper guard c.
        static List<TraceEvent> Start()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.VariableDeclared(1, "vault"),
                TraceEvent.ObjectCreated(1, 1, "Chest"),
                TraceEvent.ReferenceAssigned(1, "vault", 1),
                TraceEvent.LineExecuted(2),
                TraceEvent.VariableDeclared(2, "c"),
                TraceEvent.ReferenceAssigned(2, "c", 1),
                TraceEvent.ObjectMutated(2, 1, "Gem added"),
                TraceEvent.ScopeEnded(2, "c")
            };
        }

        static List<TraceEvent> Original(string printed)
        {
            var events = Start();
            events.Add(TraceEvent.LineExecuted(3));
            events.Add(TraceEvent.VariableDeclared(3, "c"));
            events.Add(TraceEvent.ReferenceAssigned(3, "c", 1));
            events.Add(TraceEvent.ObjectCreated(3, 2, "Chest"));
            events.Add(TraceEvent.ReferenceAssigned(3, "c", 2));
            events.Add(TraceEvent.ScopeEnded(3, "c"));
            events.Add(TraceEvent.LineExecuted(4));
            events.Add(TraceEvent.Output(4, printed));
            return events;
        }

        static List<TraceEvent> FixedByReassigning()
        {
            var events = Start();
            events.Add(TraceEvent.LineExecuted(3));
            events.Add(TraceEvent.ObjectCreated(3, 2, "Chest"));
            events.Add(TraceEvent.ReferenceAssigned(3, "vault", 2));
            events.Add(TraceEvent.LineExecuted(4));
            events.Add(TraceEvent.Output(4, "0"));
            return events;
        }

        static List<TraceEvent> FilledAgain()
        {
            var events = Start();
            events.Add(TraceEvent.LineExecuted(3));
            events.Add(TraceEvent.VariableDeclared(3, "c"));
            events.Add(TraceEvent.ReferenceAssigned(3, "c", 1));
            events.Add(TraceEvent.ObjectMutated(3, 1, "Gem added"));
            events.Add(TraceEvent.ScopeEnded(3, "c"));
            events.Add(TraceEvent.LineExecuted(4));
            events.Add(TraceEvent.Output(4, "2"));
            return events;
        }
    }
}
