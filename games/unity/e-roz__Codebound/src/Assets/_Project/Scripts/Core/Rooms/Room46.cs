using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room46
    {
        public const string Id = "4-6";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Right Container",
                "Review: orders are served first come, first served, using a List.",
                "Pick the container that fits the job.",
                new[]
                {
                    "// orders arrive: A, B, C", "var orders = new List<string>();", "var next = orders[0];",
                    "orders.RemoveAt(0);", "Console.WriteLine(next);"
                },
                string.Empty,
                Original(),
                new PredictQuestion(
                    "A is served. What happens to B and C?",
                    new[] { "They stay where they are", "They shift one place left", "They are deleted", "They swap places" },
                    1,
                    "RemoveAt(0) closes the gap. A List moves every later item one place left."),
                new[]
                {
                    new Hypothesis("RemoveAt(0) deletes every item.", Verdict.Wrong,
                        "Refuted. B and C are still in the list."),
                    new Hypothesis("RemoveAt(0) does extra work.", Verdict.Close,
                        "Partly confirmed. What exactly does it move?"),
                    new Hypothesis("A List shifts every item left, but a Queue is built for first in, first out.", Verdict.Correct,
                        "Confirmed. The job is a queue, so use a Queue.")
                },
                new[]
                {
                    new FixOption("Use a Queue and call Dequeue()", FixQuality.Best,
                        new[]
                        {
                            "// orders arrive: A, B, C", "var orders = new Queue<string>();",
                            "var next = orders.Dequeue();", "Console.WriteLine(next);"
                        },
                        Queued(),
                        "Test passed: A is served first and nothing is shifted."),
                    new FixOption("Replace line 4 with orders.Remove(next);", FixQuality.SymptomOnly,
                        new[]
                        {
                            "// orders arrive: A, B, C", "var orders = new List<string>();", "var next = orders[0];",
                            "orders.Remove(next);", "Console.WriteLine(next);"
                        },
                        Original(),
                        "Test failed: it reads cleaner, but Remove still shifts every item and searches the list first."),
                    new FixOption("Use a Stack and call Pop()", FixQuality.Wrong,
                        new[]
                        {
                            "// orders arrive: A, B, C", "var orders = new Stack<string>();",
                            "var next = orders.Pop();", "Console.WriteLine(next);"
                        },
                        Stacked(),
                        "Test failed: a Stack serves the newest order first. It served C, but A came first.")
                },
                "Assert.AreEqual(\"A\", orders.Dequeue());",
                new[]
                {
                    "Look at the rows before and after line 4.",
                    "Which collection serves the oldest item first?",
                    "Queue: first in, first out."
                },
                "Pick the container for the job: Queue for first in, first out; Stack for last in, first out; HashSet for unique values; Dictionary for lookups by key. At work: interviews ask which collection you would use, and why.",
                "Investigate: what do the rows show after line 4?",
                "Why is a List a poor fit here?");
        }

        static List<TraceEvent> Original()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(3),
                TraceEvent.ArraySet(3, "orders", "[A, B, C]"),
                TraceEvent.TextSet(3, "next", "A"),
                TraceEvent.LineExecuted(4),
                TraceEvent.ArraySet(4, "orders", "[B, C]"),
                TraceEvent.IntSet(4, "moves", 2),
                TraceEvent.LineExecuted(5),
                TraceEvent.OutputAppended(5, "A")
            };
        }

        static List<TraceEvent> Queued()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(3),
                TraceEvent.TextSet(3, "next", "A"),
                TraceEvent.ArraySet(3, "orders", "[B, C]"),
                TraceEvent.IntSet(3, "moves", 0),
                TraceEvent.LineExecuted(4),
                TraceEvent.OutputAppended(4, "A")
            };
        }

        static List<TraceEvent> Stacked()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(3),
                TraceEvent.TextSet(3, "next", "C"),
                TraceEvent.ArraySet(3, "orders", "[A, B]"),
                TraceEvent.IntSet(3, "moves", 0),
                TraceEvent.LineExecuted(4),
                TraceEvent.OutputAppended(4, "C")
            };
        }
    }
}
