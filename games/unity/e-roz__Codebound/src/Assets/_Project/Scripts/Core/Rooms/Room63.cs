using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room63
    {
        public const string Id = "6-3";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Empty Name",
                "The API sends Mokky's profile, but the app shows no name.",
                "The name from the JSON must reach the User object.",
                Lines("class User { public string Name; }", "var shown = u.Name;"),
                string.Empty,
                Result("null"),
                new PredictQuestion(
                    "What does u.Name hold?",
                    new[] { "Mokky", "null", "An empty string", "A crash" },
                    1,
                    "The JSON key is \"name\" but the property is Name. The parser is case-sensitive, so nothing matches and Name stays null."),
                new[]
                {
                    new Hypothesis("The JSON text is empty.", Verdict.Wrong,
                        "Refuted. The text holds a name key."),
                    new Hypothesis("The name never reaches the object.", Verdict.Close,
                        "Partly confirmed. Why does the match fail?"),
                    new Hypothesis("The key name and the property Name differ in case, so Name stays null.", Verdict.Correct,
                        "Confirmed. Parsers match keys by exact spelling unless told otherwise.")
                },
                new[]
                {
                    new FixOption("Map the key with JsonPropertyName", FixQuality.Best,
                        new[]
                        {
                            "// text: {\"name\": \"Mokky\"}", "class User {", "  [JsonPropertyName(\"name\")]",
                            "  public string Name; }", "var u = Parse<User>(text);", "var shown = u.Name;"
                        },
                        Mapped(),
                        "Test passed: the attribute links the key name to the property Name. Mokky arrives."),
                    new FixOption("Show Guest when Name is null", FixQuality.SymptomOnly,
                        Lines("class User { public string Name; }", "var shown = u.Name ?? \"Guest\";"),
                        Result("Guest"),
                        "Test failed: the screen looks fine, but Mokky's real name is still lost."),
                    new FixOption("Trim the text before parsing", FixQuality.Wrong,
                        new[]
                        {
                            "// text: {\"name\": \"Mokky\"}", "class User { public string Name; }",
                            "var u = Parse<User>(text.Trim());", "var shown = u.Name;"
                        },
                        Result("null"),
                        "Test failed: spaces were never the problem. The key still does not match.")
                },
                "Assert.AreEqual(\"Mokky\", Parse<User>(text).Name);",
                new[]
                {
                    "Tala: compare the key in the text with the property.",
                    "Tala: look at the first letter of each.",
                    "Tala: tell the parser which key belongs to Name."
                },
                "JSON keys must match your properties, or you must map them. At work: APIs use their own naming style, so mapping attributes or naming policies keep your C# names clean.",
                "Investigate: what does u hold after Parse?",
                "Why is the name empty?");
        }

        static string[] Lines(string type, string last) => new[]
        {
            "// text: {\"name\": \"Mokky\"}", type, "var u = Parse<User>(text);", last
        };

        static List<TraceEvent> Result(string name)
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(3),
                TraceEvent.TextSet(3, "u", "a User"),
                TraceEvent.TextSet(3, "u.Name", "null"),
                TraceEvent.LineExecuted(4),
                TraceEvent.TextSet(4, "shown", name)
            };
        }

        static List<TraceEvent> Mapped()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(5),
                TraceEvent.TextSet(5, "u", "a User"),
                TraceEvent.TextSet(5, "u.Name", "Mokky"),
                TraceEvent.LineExecuted(6),
                TraceEvent.TextSet(6, "shown", "Mokky")
            };
        }
    }
}
