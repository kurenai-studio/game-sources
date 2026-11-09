using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room43
    {
        public const string Id = "4-3";

        const string Shop = "{Sword: 10, Shield: 20}";
        const string Failure = "throws KeyNotFoundException";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Missing Key",
                "The shop crashes when a player asks for a Potion.",
                "A missing item must not crash the shop.",
                new[]
                {
                    "// shop: Sword=10, Shield=20", "var key = \"Potion\";", "var cost = shop[key];",
                    "Console.WriteLine(cost);"
                },
                string.Empty,
                Original(),
                new PredictQuestion(
                    "What does line 3 do?",
                    new[] { "cost becomes 0", "cost becomes null", "It throws an error", "It adds Potion" },
                    2,
                    "The shop has no Potion. A Dictionary lookup with [ ] throws KeyNotFoundException instead of returning 0."),
                new[]
                {
                    new Hypothesis("The price of Potion is 0.", Verdict.Wrong,
                        "Refuted. There is no entry for Potion at all."),
                    new Hypothesis("The key Potion is not in the shop.", Verdict.Close,
                        "Partly confirmed. What does the lookup do when the key is missing?"),
                    new Hypothesis("shop[key] throws when the key is missing and nothing checks first.", Verdict.Correct,
                        "Confirmed. Ask the dictionary before you read from it.")
                },
                new[]
                {
                    new FixOption("Check shop.ContainsKey(key) first", FixQuality.Best,
                        new[]
                        {
                            "// shop: Sword=10, Shield=20", "var key = \"Potion\";", "if (shop.ContainsKey(key))",
                            "    Console.WriteLine(shop[key]);", "else", "    Console.WriteLine(\"No Potion\");"
                        },
                        Checked(),
                        "Test passed: the shop says No Potion and nothing crashes."),
                    new FixOption("Catch the error and print 0", FixQuality.SymptomOnly,
                        new[]
                        {
                            "// shop: Sword=10, Shield=20", "var key = \"Potion\";", "try", "{",
                            "    Console.WriteLine(shop[key]);", "}", "catch { Console.WriteLine(0); }"
                        },
                        Zero(),
                        "Test failed: no crash, but Potion now looks free. A missing key is not a price of 0."),
                    new FixOption("Check shop.Count > 0 first", FixQuality.Wrong,
                        new[]
                        {
                            "// shop: Sword=10, Shield=20", "var key = \"Potion\";", "if (shop.Count > 0)",
                            "    Console.WriteLine(shop[key]);"
                        },
                        StillCrashes(),
                        "Test failed: the shop is not empty, so the check passes and the lookup still throws.")
                },
                "Assert.DoesNotThrow(() => Lookup(\"Potion\"));",
                new[]
                {
                    "Which keys does the shop hold?",
                    "What does a Dictionary do when a key is missing?",
                    "Ask the dictionary whether the key exists before reading it."
                },
                "A Dictionary throws KeyNotFoundException when a key is missing. Check with ContainsKey, or use TryGetValue to look up only once. At work: lookup tables and config files miss keys all the time.",
                "Investigate: which keys does the shop hold?",
                "Why does line 3 crash?");
        }

        static List<TraceEvent> Start()
        {
            return new List<TraceEvent>
            {
                TraceEvent.ArraySet(1, "shop", Shop),
                TraceEvent.LineExecuted(2),
                TraceEvent.TextSet(2, "key", "Potion")
            };
        }

        static List<TraceEvent> Original()
        {
            var events = Start();
            events.Add(TraceEvent.LineExecuted(3));
            events.Add(TraceEvent.ExceptionThrown(3, "KeyNotFoundException"));
            return events;
        }

        static List<TraceEvent> Checked()
        {
            var events = Start();
            events.Add(TraceEvent.LineExecuted(3));
            events.Add(TraceEvent.LineExecuted(6));
            events.Add(TraceEvent.OutputAppended(6, "No Potion"));
            return events;
        }

        static List<TraceEvent> Zero()
        {
            var events = Start();
            events.Add(TraceEvent.LineExecuted(5));
            events.Add(TraceEvent.TextSet(5, "shop[key]", Failure));
            events.Add(TraceEvent.LineExecuted(7));
            events.Add(TraceEvent.OutputAppended(7, "0"));
            return events;
        }

        static List<TraceEvent> StillCrashes()
        {
            var events = Start();
            events.Add(TraceEvent.LineExecuted(3));
            events.Add(TraceEvent.LineExecuted(4));
            events.Add(TraceEvent.ExceptionThrown(4, "KeyNotFoundException"));
            return events;
        }
    }
}
