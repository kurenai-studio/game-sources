using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room55
    {
        public const string Id = "5-5";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Flightless Bird",
                "The flock takes off, but the Penguin crashes the whole game.",
                "Only birds that can fly may be asked to Fly().",
                new[]
                {
                    "class Bird", "{ public virtual void Fly() { } }", "class Penguin : Bird",
                    "{ public override void Fly()", "    => throw new Exception(); }", "new Penguin().Fly();"
                },
                string.Empty,
                Original(),
                new PredictQuestion(
                    "What happens on line 6?",
                    new[] { "Nothing", "The penguin flies", "It throws an error", "It swims" },
                    2,
                    "Penguin overrides Fly() and throws, because a penguin cannot fly. Calling it crashes."),
                new[]
                {
                    new Hypothesis("Penguin has no Fly method.", Verdict.Wrong,
                        "Refuted. Penguin inherits Fly() and overrides it."),
                    new Hypothesis("Penguin cannot do what Bird promises.", Verdict.Close,
                        "Partly confirmed. Where does that promise come from?"),
                    new Hypothesis("Penguin inherits Fly() from Bird even though it cannot fly, so the promise is broken.", Verdict.Correct,
                        "Confirmed. Inheritance means is-a, and a Penguin is not a flyer.")
                },
                new[]
                {
                    new FixOption("Move Fly() into an ICanFly interface", FixQuality.Best,
                        new[]
                        {
                            "class Bird { }", "interface ICanFly { void Fly(); }", "class Eagle : Bird, ICanFly { }",
                            "class Penguin : Bird { }", "new Eagle().Fly();", "// Penguin.Fly() won't compile"
                        },
                        Interfaced(),
                        "Test passed: only flyers can Fly(). Calling it on a Penguin is now a compile error."),
                    new FixOption("Catch the error with try and catch", FixQuality.SymptomOnly,
                        new[]
                        {
                            "class Bird", "{ public virtual void Fly() { } }", "class Penguin : Bird",
                            "{ public override void Fly()", "    => throw new Exception(); }",
                            "try { new Penguin().Fly(); }", "catch { }"
                        },
                        Caught(),
                        "Test failed: the crash is hidden, but Bird still promises Fly() to every bird."),
                    new FixOption("Make Penguin.Fly() do nothing", FixQuality.Wrong,
                        new[]
                        {
                            "class Bird", "{ public virtual void Fly() { } }", "class Penguin : Bird",
                            "{ public override void Fly() { } }", "new Penguin().Fly();"
                        },
                        Pretends(),
                        "Test failed: no crash, but the penguin now pretends to fly. The wrong promise is still in Bird.")
                },
                "Assert.IsFalse(new Penguin() is ICanFly);",
                new[]
                {
                    "Tala: a penguin cannot fly. Who said it can?",
                    "Tala: Bird promises Fly() to every child.",
                    "Tala: give Fly() only to the birds that can."
                },
                "Inheritance means is-a. If a child cannot keep the parent's promise, the design is wrong. Split abilities into interfaces, or use composition. At work: deep inheritance trees are hard to change safely.",
                "Investigate: what does Penguin.Fly() do?",
                "Why does the penguin crash?");
        }

        static List<TraceEvent> Original()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(6),
                TraceEvent.TextSet(6, "Penguin", "a Bird"),
                TraceEvent.LineExecuted(5),
                TraceEvent.ExceptionThrown(5, "Exception")
            };
        }

        static List<TraceEvent> Interfaced()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(5),
                TraceEvent.TextSet(5, "Eagle.Fly()", "ok, an Eagle can fly"),
                TraceEvent.LineExecuted(6),
                TraceEvent.TextSet(6, "Penguin.Fly()", "not allowed, no ICanFly")
            };
        }

        static List<TraceEvent> Caught()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(6),
                TraceEvent.TextSet(6, "Penguin", "a Bird"),
                TraceEvent.TextSet(6, "Penguin.Fly()", "throws, error hidden"),
                TraceEvent.LineExecuted(7)
            };
        }

        static List<TraceEvent> Pretends()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(5),
                TraceEvent.TextSet(5, "Penguin", "a Bird"),
                TraceEvent.TextSet(5, "Penguin.Fly()", "does nothing, pretends to fly")
            };
        }
    }
}
