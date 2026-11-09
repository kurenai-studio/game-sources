using System.Collections.Generic;

namespace Codebound.Core
{
    public sealed class PredictQuestion
    {
        public PredictQuestion(string prompt, IReadOnlyList<string> options, int correctIndex, string explanation)
        {
            Prompt = prompt;
            Options = options;
            CorrectIndex = correctIndex;
            Explanation = explanation;
        }

        public string Prompt { get; }
        public IReadOnlyList<string> Options { get; }
        public int CorrectIndex { get; }
        public string Explanation { get; }
    }

    public enum Verdict
    {
        Correct,
        Close,
        Wrong
    }

    public sealed class Hypothesis
    {
        public Hypothesis(string text, Verdict verdict, string feedback)
        {
            Text = text;
            Verdict = verdict;
            Feedback = feedback;
        }

        public string Text { get; }
        public Verdict Verdict { get; }
        public bool IsCorrect => Verdict == Verdict.Correct;
        public string Feedback { get; }
    }

    public enum FixQuality
    {
        Best,
        SymptomOnly,
        Wrong
    }

    public sealed class FixOption
    {
        public FixOption(string change, FixQuality quality, IReadOnlyList<string> codeLines,
            IReadOnlyList<TraceEvent> consequence, string testMessage)
        {
            Change = change;
            CodeLines = codeLines;
            Quality = quality;
            Consequence = consequence;
            TestMessage = testMessage;
        }

        public string Change { get; }
        public IReadOnlyList<string> CodeLines { get; }
        public FixQuality Quality { get; }
        public IReadOnlyList<TraceEvent> Consequence { get; }
        public string TestMessage { get; }
        public bool TestPasses => Quality == FixQuality.Best;

        public Verdict Verdict =>
            Quality == FixQuality.Best ? Verdict.Correct : Quality == FixQuality.SymptomOnly ? Verdict.Close : Verdict.Wrong;
    }

    public sealed class RoomDefinition
    {
        public RoomDefinition(string id, string title, string ticket, string goal, IReadOnlyList<string> codeLines,
            string supportCode, IReadOnlyList<TraceEvent> trace, PredictQuestion predict,
            IReadOnlyList<Hypothesis> hypotheses, IReadOnlyList<FixOption> fixes, string testCode,
            IReadOnlyList<string> hints, string debrief,
            string investigatePrompt = "Investigate: which chest does each guard point to?",
            string hypothesisPrompt = "Why does Vault B have a sword?", string ending = "")
        {
            Ending = ending ?? string.Empty;
            InvestigatePrompt = investigatePrompt;
            HypothesisPrompt = hypothesisPrompt;
            Id = id;
            Title = title;
            Ticket = ticket;
            Goal = goal;
            CodeLines = codeLines;
            SupportCode = supportCode;
            Trace = trace;
            Predict = predict;
            Hypotheses = hypotheses;
            Fixes = fixes;
            TestCode = testCode;
            Hints = hints;
            Debrief = debrief;
        }

        public string Id { get; }
        public string Title { get; }
        public string Ticket { get; }
        public string Goal { get; }
        public IReadOnlyList<string> CodeLines { get; }
        public string SupportCode { get; }
        public IReadOnlyList<TraceEvent> Trace { get; }
        public PredictQuestion Predict { get; }
        public IReadOnlyList<Hypothesis> Hypotheses { get; }
        public IReadOnlyList<FixOption> Fixes { get; }
        public string TestCode { get; }
        public IReadOnlyList<string> Hints { get; }
        public string Debrief { get; }
        public string InvestigatePrompt { get; }
        public string HypothesisPrompt { get; }
        public bool HasSupportCode => !string.IsNullOrEmpty(SupportCode);
        // Closing story text shown on the Complete screen instead of the debrief. "{name}" becomes the player's name.
        public string Ending { get; }
        public bool HasEnding => Ending.Length > 0;
    }
}
