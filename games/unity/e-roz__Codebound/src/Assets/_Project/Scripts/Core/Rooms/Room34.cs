using System.Collections.Generic;

namespace Codebound.Core
{
    public static class Room34
    {
        public const string Id = "3-4";

        const string Failure = "throws FileNotFoundException";

        public static RoomDefinition Create()
        {
            return new RoomDefinition(
                Id,
                "The Silent Failure",
                "Players say their progress is lost, but the game never shows an error.",
                "A failed load must be handled and written to the log.",
                new[]
                {
                    "try", "{", "    LoadSave(\"save.dat\");", "}", "catch (Exception) { }",
                    "Console.WriteLine(\"Done\");"
                },
                string.Empty,
                Original(),
                new PredictQuestion(
                    "What does this print?",
                    new[] { "Done", "An error message", "Nothing", "A crash" },
                    0,
                    "LoadSave fails, but the empty catch swallows the error. The program carries on and prints Done."),
                new[]
                {
                    new Hypothesis("LoadSave works fine.", Verdict.Wrong,
                        "Refuted. The row shows LoadSave throws FileNotFoundException."),
                    new Hypothesis("The error is not shown anywhere.", Verdict.Close,
                        "Partly confirmed. Why not? Look at line 5."),
                    new Hypothesis("catch (Exception) { } swallows the error, so nothing is handled or logged.", Verdict.Correct,
                        "Confirmed. An empty catch hides failures until a customer complains.")
                },
                new[]
                {
                    new FixOption("Catch FileNotFoundException and log e.Message", FixQuality.Best,
                        new[]
                        {
                            "try", "{", "    LoadSave(\"save.dat\");", "}", "catch (FileNotFoundException e)",
                            "    Log(e.Message);", "Console.WriteLine(\"Done\");"
                        },
                        Logged("ERROR FileNotFoundException: save.dat", 6, 7),
                        "Test passed: the log says which file was missing."),
                    new FixOption("Change line 5 to: catch { Log(\"error\"); }", FixQuality.SymptomOnly,
                        new[]
                        {
                            "try", "{", "    LoadSave(\"save.dat\");", "}", "catch { Log(\"error\"); }",
                            "Console.WriteLine(\"Done\");"
                        },
                        Logged("error", 5, 6),
                        "Test failed: it logs, but only the word error. No file name, no exception type."),
                    new FixOption("Delete the try and catch", FixQuality.Wrong,
                        new[] { "LoadSave(\"save.dat\");", "Console.WriteLine(\"Done\");" },
                        Crash(),
                        "Test failed: the whole app now crashes on a missing file.")
                },
                "Assert.IsTrue(log.Contains(\"save.dat\"));",
                new[]
                {
                    "The error happens on line 3. Does anyone hear about it?",
                    "Look at the catch block: it has no code inside.",
                    "Catch the specific exception and write it to the log."
                },
                "An empty catch hides failures. Catch the specific exception, log it, and decide what to do. At work: silent failures only show up as customer complaints.",
                "Investigate: what did the Log Reader record?",
                "Why does nobody see the error?");
        }

        // LoadSave fails, the empty catch swallows it, and the log stays empty.
        static List<TraceEvent> Original()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(3),
                TraceEvent.TextSet(3, "LoadSave", Failure),
                TraceEvent.LineExecuted(5),
                TraceEvent.LogOpened(5),
                TraceEvent.LineExecuted(6),
                TraceEvent.OutputAppended(6, "Done")
            };
        }

        static List<TraceEvent> Logged(string entry, int logLine, int printLine)
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(3),
                TraceEvent.TextSet(3, "LoadSave", Failure),
                TraceEvent.LineExecuted(5),
                TraceEvent.LineExecuted(logLine),
                TraceEvent.LogAppended(logLine, entry),
                TraceEvent.LineExecuted(printLine),
                TraceEvent.OutputAppended(printLine, "Done")
            };
        }

        static List<TraceEvent> Crash()
        {
            return new List<TraceEvent>
            {
                TraceEvent.LineExecuted(1),
                TraceEvent.ExceptionThrown(1, "FileNotFoundException")
            };
        }
    }
}
