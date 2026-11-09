using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room64
    {
        public const string Id = "6-4";

        const string TimedOut = "timed out, server got it";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Order That Arrives Twice",
                "Coco ordered once and was charged twice after a slow network.",
                "A retried order must be stored only once.",
                Lines("if (!Send(order))", "    Send(order); // retry"),
                string.Empty,
                Run(2, "server got it again", 2),
                new PredictQuestion(
                    "The first Send times out after it arrived. How many orders does the server hold?",
                    new[] { "1", "2", "0", "3" },
                    1,
                    "The timeout only means no answer came back. The server did get order #7. The retry sends it again, so the server holds 2."),
                new[]
                {
                    new Hypothesis("The server lost the first order.", Verdict.Wrong,
                        "Refuted. The server shows it received the first Send."),
                    new Hypothesis("The retry runs when it should not.", Verdict.Close,
                        "Partly confirmed. But the client cannot know the first Send arrived."),
                    new Hypothesis("A timeout hides that the request arrived, and the retry has no way to say it is the same order.", Verdict.Correct,
                        "Confirmed. Without an id, the server treats the retry as a new order.")
                },
                new[]
                {
                    new FixOption("Send an idempotency key with every try", FixQuality.Best,
                        new[]
                        {
                            "var key = NewKey();", "var order = \"order #7\";", "if (!Send(order, key))",
                            "    Send(order, key); // retry"
                        },
                        Run(2, "same key, ignored", 1),
                        "Test passed: both tries carry the same key, so the server stores the order once."),
                    new FixOption("Never retry", FixQuality.SymptomOnly,
                        new[] { "var order = \"order #7\";", "Send(order); // no retry" },
                        NoRetry(),
                        "Test failed: no duplicate this time, but a request that is really lost now loses the order."),
                    new FixOption("Wait 5 seconds before retrying", FixQuality.Wrong,
                        Lines("if (!Send(order))", "    Wait(5); Send(order);"),
                        Run(2, "server got it again", 2),
                        "Test failed: waiting does not change what the server sees. It still stores two orders.")
                },
                "Assert.AreEqual(1, Server.Orders(after2Tries));",
                new[]
                {
                    "Tala: did the first Send really fail?",
                    "Tala: how can the server tell a retry from a new order?",
                    "Tala: give both tries the same key."
                },
                "Retries are safe only if repeating a request has the same effect as sending it once. That is idempotency. At work: payment APIs ask for an idempotency key for exactly this reason.",
                "Investigate: what does the server see?",
                "Why are there two orders?");
        }

        static string[] Lines(string check, string retry) => new[] { "var order = \"order #7\";", check, retry };

        static List<TraceEvent> Run(int line, string second, int orders)
        {
            var offset = orders == 1 ? 1 : 0;
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(line + offset),
                TraceEvent.TextSet(line + offset, "Send #1", TimedOut),
                TraceEvent.IntSet(line + offset, "server orders", 1),
                TraceEvent.LineExecuted(line + offset + 1),
                TraceEvent.TextSet(line + offset + 1, "Send #2", second),
                TraceEvent.IntSet(line + offset + 1, "server orders", orders)
            };
        }

        static List<TraceEvent> NoRetry()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(2),
                TraceEvent.TextSet(2, "Send #1", TimedOut),
                TraceEvent.IntSet(2, "server orders", 1),
                TraceEvent.TextSet(2, "if the send is lost", "the order never arrives")
            };
        }
    }
}
