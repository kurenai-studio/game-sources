using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room53
    {
        public const string Id = "5-3";

        const string Typed = "a Dog, typed as Guard";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Gentle Dog",
                "Toffee the guard dog bites for 9, but the game only deals 1.",
                "g.Hit() must run the Dog's version.",
                Lines("{ public int Hit() => 1; }", "{ public int Hit() => 9; }", "Console.WriteLine(g.Hit());"),
                string.Empty,
                Run("g.Hit()", "1"),
                new PredictQuestion(
                    "What does this print?",
                    new[] { "9", "1", "10", "A crash" },
                    1,
                    "g is typed as Guard. Without virtual and override, the call uses the type of the variable, so Guard.Hit runs."),
                new[]
                {
                    new Hypothesis("Dog has no Hit method.", Verdict.Wrong,
                        "Refuted. Line 4 gives Dog its own Hit."),
                    new Hypothesis("The Guard version runs instead of the Dog version.", Verdict.Close,
                        "Partly confirmed. Why does the compiler choose Guard's?"),
                    new Hypothesis("Hit is not virtual, so a call on a Guard variable uses Guard.Hit.", Verdict.Correct,
                        "Confirmed. Polymorphism needs virtual and override.")
                },
                new[]
                {
                    new FixOption("Use virtual in Guard and override in Dog", FixQuality.Best,
                        Lines("{ public virtual int Hit() => 1; }", "{ public override int Hit() => 9; }",
                            "Console.WriteLine(g.Hit());"),
                        Run("g.Hit()", "9"),
                        "Test passed: g.Hit() runs the Dog's version and prints 9."),
                    new FixOption("Cast to Dog: ((Dog)g).Hit()", FixQuality.SymptomOnly,
                        Lines("{ public int Hit() => 1; }", "{ public int Hit() => 9; }",
                            "Console.WriteLine(((Dog)g).Hit());"),
                        Run("((Dog)g).Hit()", "9"),
                        "Test failed: it prints 9 here, but any code that calls g.Hit() still gets 1."),
                    new FixOption("Add new to Dog's Hit", FixQuality.Wrong,
                        Lines("{ public int Hit() => 1; }", "{ public new int Hit() => 9; }",
                            "Console.WriteLine(g.Hit());"),
                        Run("g.Hit()", "1"),
                        "Test failed: new hides the method, but a Guard variable still runs Guard.Hit. It prints 1.")
                },
                "Assert.AreEqual(9, g.Hit());",
                new[]
                {
                    "Tala: which Hit() runs when g is typed Guard?",
                    "Tala: the compiler picks the method unless it is virtual.",
                    "Tala: virtual in the parent, override in the child."
                },
                "Polymorphism needs virtual in the base class and override in the child. Without them the call uses the variable's type. At work: plugin and handler systems rely on this.",
                "Investigate: what does the call on g return?",
                "Why does the dog deal only 1?");
        }

        static string[] Lines(string guardHit, string dogHit, string print) => new[]
        {
            "class Guard", guardHit, "class Dog : Guard", dogHit, "Guard g = new Dog();", print
        };

        static List<TraceEvent> Run(string call, string result)
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(5),
                TraceEvent.TextSet(5, "g", Typed),
                TraceEvent.LineExecuted(6),
                TraceEvent.CallReturned(6, call, result),
                TraceEvent.OutputAppended(6, result)
            };
        }
    }
}
