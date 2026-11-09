using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room51
    {
        public const string Id = "5-1";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Shared Health",
                "Thea was hit, and Jean lost health too.",
                "Each guard must keep their own Hp.",
                Lines("    public static int Hp = 10;", "var thea = new Guard();", "var jean = new Guard();"),
                string.Empty,
                Run("one copy for all guards", 7),
                new PredictQuestion(
                    "After thea.Hit(), what is Jean's Hp?",
                    new[] { "10", "7", "3", "A crash" },
                    1,
                    "Hp is static, so there is one copy for the whole class. Hit() changes it for every guard."),
                new[]
                {
                    new Hypothesis("Jean was hit as well.", Verdict.Wrong,
                        "Refuted. Only thea.Hit() ran."),
                    new Hypothesis("Thea and Jean share their health.", Verdict.Close,
                        "Partly confirmed. What makes them share it?"),
                    new Hypothesis("Hp is static, so there is only one copy for all guards.", Verdict.Correct,
                        "Confirmed. A static field belongs to the class, not to each object.")
                },
                new[]
                {
                    new FixOption("Make Hp an instance field (remove static)", FixQuality.Best,
                        Lines("    public int Hp = 10;", "var thea = new Guard();", "var jean = new Guard();"),
                        Run("one copy per guard", 10),
                        "Test passed: Thea has 7 and Jean still has 10."),
                    new FixOption("Create jean before thea", FixQuality.SymptomOnly,
                        Lines("    public static int Hp = 10;", "var jean = new Guard();", "var thea = new Guard();"),
                        Run("one copy for all guards", 7),
                        "Test failed: the order does not matter. Hp is still one shared copy."),
                    new FixOption("Add Guard.Hp = 10; after the hit", FixQuality.Wrong,
                        new[]
                        {
                            "class Guard {", "    public static int Hp = 10;", "    public void Hit() { Hp -= 3; }", "}",
                            "var thea = new Guard();", "var jean = new Guard();", "thea.Hit();", "Guard.Hp = 10;"
                        },
                        Reset(),
                        "Test failed: the reset hides the hit on Thea too. Both guards show 10.")
                },
                "Assert.AreEqual(10, jean.Hp);",
                new[]
                {
                    "Tala: only Thea was hit. Look at both rows.",
                    "Tala: how many copies of Hp exist?",
                    "Tala: static means one copy for the whole class."
                },
                "A static field belongs to the class, not to each object. Use an instance field for data each object owns. At work: shared static state causes bugs that depend on what ran earlier.",
                "Investigate: how many copies of Hp exist?",
                "Why did Jean lose Hp?");
        }

        static string[] Lines(string field, string first, string second) => new[]
        {
            "class Guard {", field, "    public void Hit() { Hp -= 3; }", "}", first, second, "thea.Hit();"
        };

        static List<TraceEvent> Run(string copies, int jean)
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(5),
                TraceEvent.LineExecuted(6),
                TraceEvent.TextSet(2, "Hp", copies),
                TraceEvent.LineExecuted(7),
                TraceEvent.LineExecuted(3),
                TraceEvent.IntSet(3, "thea Hp", 7),
                TraceEvent.IntSet(3, "jean Hp", jean)
            };
        }

        static List<TraceEvent> Reset()
        {
            var events = Run("one copy for all guards", 7);
            events.Add(TraceEvent.LineExecuted(8));
            events.Add(TraceEvent.IntSet(8, "thea Hp", 10));
            events.Add(TraceEvent.IntSet(8, "jean Hp", 10));
            return events;
        }
    }
}
