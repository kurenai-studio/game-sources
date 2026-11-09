using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room15
    {
        public const string Id = "1-5";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Empty Chest",
                "The machinery crashes when it opens the north vault.",
                "The Gem ends up in a vault, and the program does not crash.",
                new[]
                {
                    "Chest vault = FindChest(\"north\");",
                    "Console.WriteLine(\"Opening vault\");",
                    "vault.Add(\"Gem\");"
                },
                "Chest FindChest(string name)\n{\n    return name == \"east\" ? east : null;\n}",
                Original(),
                new PredictQuestion(
                    "What happens when line 3 runs?",
                    new[]
                    {
                        "The Gem is added to the vault", "The Gem is ignored",
                        "The program crashes with an error", "A new vault is created"
                    },
                    2,
                    "FindChest(\"north\") finds nothing and returns null. Calling Add on null crashes the program."),
                new[]
                {
                    new Hypothesis("Line 2 sets vault to null.", Verdict.Wrong,
                        "Line 2 only prints a message. It does not touch vault."),
                    new Hypothesis("Line 3 is the broken line.", Verdict.Close,
                        "That is where it crashes, but not why. Ask what vault holds when line 3 runs."),
                    new Hypothesis("FindChest returned null, so vault points to nothing when line 3 uses it.",
                        Verdict.Correct,
                        "Yes. vault points to nothing, so Add has nothing to work on.")
                },
                new[]
                {
                    new FixOption("Add after line 1: vault = vault ?? new Chest();", FixQuality.Best,
                        new[]
                        {
                            "Chest vault = FindChest(\"north\");", "vault = vault ?? new Chest();",
                            "Console.WriteLine(\"Opening vault\");", "vault.Add(\"Gem\");"
                        },
                        FixedWithDefaultChest(),
                        "Test passed: vault exists and holds 1 item."),
                    new FixOption("Change line 3 to: if (vault != null) vault.Add(\"Gem\");", FixQuality.SymptomOnly,
                        new[]
                        {
                            "Chest vault = FindChest(\"north\");", "Console.WriteLine(\"Opening vault\");",
                            "if (vault != null) vault.Add(\"Gem\");"
                        },
                        SkippedByNullCheck(),
                        "Test failed: no crash, but vault is still null and the Gem was never stored. The null check only hid the problem."),
                    new FixOption("Change line 1 to: Chest vault = FindChest(\"south\");", FixQuality.Wrong,
                        new[]
                        {
                            "Chest vault = FindChest(\"south\");", "Console.WriteLine(\"Opening vault\");",
                            "vault.Add(\"Gem\");"
                        },
                        Original(),
                        "Test failed: line 3 threw a NullReferenceException. FindChest(\"south\") returns null too.")
                },
                "Assert.IsNotNull(vault);\nAssert.AreEqual(1, vault.Count);",
                new[]
                {
                    "What does vault hold after line 1?",
                    "FindChest returns null when it finds nothing.",
                    "You cannot call Add on null. Decide what should happen instead."
                },
                "Calling a method on null throws NullReferenceException. A null check that just skips the code hides the problem: the Gem is lost silently. Decide what should happen when something is missing: create it, or report it. At work: the most common production error.",
                "Investigate: what does vault point to?",
                "Why does the program crash?");
        }

        static List<TraceEvent> Line1()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.VariableDeclared(1, "vault"),
                TraceEvent.NullAssigned(1, "vault")
            };
        }

        static List<TraceEvent> Original()
        {
            var events = Line1();
            events.Add(TraceEvent.LineExecuted(2));
            events.Add(TraceEvent.Output(2, "Opening vault"));
            events.Add(TraceEvent.LineExecuted(3));
            events.Add(TraceEvent.ExceptionThrown(3, "NullReferenceException"));
            return events;
        }

        static List<TraceEvent> FixedWithDefaultChest()
        {
            var events = Line1();
            events.Add(TraceEvent.LineExecuted(2));
            events.Add(TraceEvent.ObjectCreated(2, 1, "Chest"));
            events.Add(TraceEvent.ReferenceAssigned(2, "vault", 1));
            events.Add(TraceEvent.LineExecuted(3));
            events.Add(TraceEvent.Output(3, "Opening vault"));
            events.Add(TraceEvent.LineExecuted(4));
            events.Add(TraceEvent.ObjectMutated(4, 1, "Gem added"));
            return events;
        }

        static List<TraceEvent> SkippedByNullCheck()
        {
            var events = Line1();
            events.Add(TraceEvent.LineExecuted(2));
            events.Add(TraceEvent.Output(2, "Opening vault"));
            events.Add(TraceEvent.LineExecuted(3));
            return events;
        }
    }
}
