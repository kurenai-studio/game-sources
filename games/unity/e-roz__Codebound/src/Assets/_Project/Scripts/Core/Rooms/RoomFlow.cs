using System;
using System.Collections.Generic;

namespace Codebound.Core
{
    // Everything the flow panel shows for the current step. The UI only draws this.
    public sealed class RoomFlowScreen
    {
        static readonly string[] NoOptions = new string[0];

        public string Prompt { get; internal set; } = string.Empty;
        public string Body { get; internal set; } = string.Empty;
        public string Notice { get; internal set; } = string.Empty;
        public Verdict? Verdict { get; internal set; }
        public string VerdictTitle { get; internal set; } = string.Empty;
        public IReadOnlyList<Verdict?> OptionMarks { get; internal set; } = new Verdict?[0];
        public IReadOnlyList<string> Options { get; internal set; } = NoOptions;
        public string NextLabel { get; internal set; }
        public bool NextEnabled { get; internal set; }
        public bool HintVisible { get; internal set; }
        public string HintLabel { get; internal set; } = string.Empty;
        public bool CanReplay { get; internal set; }
    }

    // Turns the player's clicks (pick, next, hint) into RoomSession calls and writes the words the panel shows.
    public sealed class RoomFlow
    {
        readonly RoomSession _session;
        readonly KeepState _state;
        readonly Dictionary<RoomStep, Verdict?[]> _marks = new Dictionary<RoomStep, Verdict?[]>();
        string _notice = string.Empty;
        Verdict? _verdict;
        int _predicted;
        int _lastFix;

        public RoomFlow(RoomSession session, KeepState state)
        {
            _session = session ?? throw new ArgumentNullException(nameof(session));
            _state = state ?? throw new ArgumentNullException(nameof(state));
            _session.StepChanged += _ => Refresh();
        }

        public event Action Changed;
        public event Action<int> Completed;
        public event Action LeaveRequested;

        public RoomSession Session => _session;
        // Used by a room's ending text. Empty names fall back to "Apprentice", as everywhere else in the game.
        public string PlayerName { get; set; } = "Apprentice";
        public RoomFlowScreen Screen => Build();

        public void Refresh() => Changed?.Invoke();

        public void Pick(int index)
        {
            switch (_session.Step)
            {
                case RoomStep.Predict:
                    _predicted = index;
                    var right = index == _session.Room.Predict.CorrectIndex;
                    _verdict = right ? Verdict.Correct : Verdict.Wrong;
                    _notice = right
                        ? "Good prediction. Run the code to watch it happen."
                        : "That is not what this code does. Run it and watch what really happens.";
                    _session.SubmitPrediction(index);
                    break;
                case RoomStep.Hypothesis:
                    var hypothesis = _session.Room.Hypotheses[index];
                    _verdict = hypothesis.Verdict;
                    _notice = hypothesis.Feedback;
                    MarksFor(RoomStep.Hypothesis, _session.Room.Hypotheses.Count)[index] = hypothesis.Verdict;
                    _session.ChooseHypothesis(index);
                    break;
                case RoomStep.Fix:
                    _lastFix = index;
                    ClearFeedback();
                    _session.ChooseFix(index);
                    break;
                default:
                    return;
            }
            Refresh();
        }

        public void Next()
        {
            switch (_session.Step)
            {
                case RoomStep.Ticket:
                    ClearFeedback();
                    _session.Begin();
                    break;
                case RoomStep.Observe:
                    if (_session.Trace.HasNext) return;
                    ClearFeedback();
                    _session.FinishObserving();
                    break;
                case RoomStep.Investigate:
                    ClearFeedback();
                    _session.FinishInvestigating();
                    break;
                case RoomStep.Debrief:
                    _session.Finish();
                    Completed?.Invoke(_session.Stars);
                    break;
                case RoomStep.Complete:
                    LeaveRequested?.Invoke();
                    return;
                default:
                    return;
            }
            Refresh();
        }

        // Called when the chosen fix has finished replaying: the test runs by itself and the verdict shows.
        public void FixReplayFinished()
        {
            if (_session.Step != RoomStep.Prove || _session.FixTrace.HasNext) return;

            var fix = _session.CurrentFix;
            _verdict = fix.Verdict;
            _notice = fix.TestMessage;
            if (!fix.TestPasses) MarksFor(RoomStep.Fix, _session.Room.Fixes.Count)[_lastFix] = fix.Verdict;
            _session.RunTest();
            Refresh();
        }

        public void Hint()
        {
            if (!HintAllowed) return;

            _verdict = null;
            _notice = _session.TryUseHint(out var hint) ? $"Hint {_session.HintsUsed}: {hint}" : "No more hints.";
            Refresh();
        }

        bool HintAllowed => _session.Step == RoomStep.Investigate || _session.Step == RoomStep.Hypothesis ||
                            _session.Step == RoomStep.Fix;

        RoomFlowScreen Build()
        {
            var room = _session.Room;
            var screen = new RoomFlowScreen
            {
                Notice = _notice,
                Verdict = _verdict,
                VerdictTitle = _verdict.HasValue ? Title(_verdict.Value) : string.Empty,
                HintVisible = HintAllowed,
                HintLabel = $"Hint ({_session.HintsUsed}/{RoomSession.MaxHints})"
            };

            switch (_session.Step)
            {
                case RoomStep.Ticket:
                    screen.Prompt = "Read the ticket and the code.";
                    screen.Body = $"Goal: {room.Goal}\nYou will predict what the code does before it runs.";
                    Next(screen, "Start", true);
                    break;
                case RoomStep.Predict:
                    screen.Prompt = room.Predict.Prompt;
                    screen.Options = room.Predict.Options;
                    break;
                case RoomStep.Observe:
                    var done = !_session.Trace.HasNext && _session.Trace.Position > 0;
                    screen.CanReplay = true;
                    screen.Prompt = "Press Run and watch the Keep.";
                    screen.Body = ObserveBody(done);
                    Next(screen, "Investigate", done);
                    break;
                case RoomStep.Investigate:
                    var lines = _state.WatchLines();
                    screen.CanReplay = true;
                    screen.Prompt = room.InvestigatePrompt;
                    screen.Body = lines.Count == 0
                        ? "Step through the code to fill the watch list."
                        : "WATCH\n" + string.Join("\n", lines);
                    Next(screen, "I found the cause", true);
                    break;
                case RoomStep.Hypothesis:
                    screen.Prompt = room.HypothesisPrompt;
                    screen.Options = Texts(room.Hypotheses.Count, i => room.Hypotheses[i].Text);
                    screen.OptionMarks = MarksFor(RoomStep.Hypothesis, room.Hypotheses.Count);
                    break;
                case RoomStep.Fix:
                    screen.Prompt = $"Pick a fix. Goal: {room.Goal}";
                    screen.Options = Texts(room.Fixes.Count, i => room.Fixes[i].Change);
                    screen.OptionMarks = MarksFor(RoomStep.Fix, room.Fixes.Count);
                    break;
                case RoomStep.Prove:
                    screen.CanReplay = true;
                    screen.Prompt = "Your fix is replaying. The test runs when it ends.";
                    screen.Body = "Test:\n" + room.TestCode;
                    break;
                case RoomStep.Debrief:
                    screen.Prompt = "Test passed!";
                    screen.Body = room.Debrief;
                    Next(screen, "Finish", true);
                    break;
                case RoomStep.Complete:
                    screen.Prompt = $"Room complete! Stars {_session.Stars} / {UnlockRules.MaxStarsPerRoom}";
                    screen.Body = room.HasEnding ? room.Ending.Replace("{name}", PlayerName) : room.Debrief;
                    if (room.HasEnding)
                    {
                        // The story ending stands alone: no leftover verdict or test message under it.
                        screen.Notice = string.Empty;
                        screen.Verdict = null;
                        screen.VerdictTitle = string.Empty;
                    }
                    Next(screen, "Back to Keep", true);
                    break;
            }
            return screen;
        }

        void ClearFeedback()
        {
            _verdict = null;
            _notice = string.Empty;
        }

        Verdict?[] MarksFor(RoomStep step, int count)
        {
            if (!_marks.TryGetValue(step, out var marks)) _marks[step] = marks = new Verdict?[count];
            return marks;
        }

        static string Title(Verdict verdict)
        {
            switch (verdict)
            {
                case Verdict.Correct: return "CORRECT!";
                case Verdict.Close: return "CLOSE, BUT NOT YET";
                default: return "NOT QUITE";
            }
        }

        string ObserveBody(bool done)
        {
            var guess = _session.Room.Predict.Options[_predicted];
            if (!done) return $"You predicted {guess}. Run the code to see the real answer.";
            var result = _state.Error.Length > 0 ? $"it crashed with {_state.Error}"
                : _state.Output.Length > 0 ? $"it printed {_state.Output}"
                : "the Keep shows the answer";
            return _session.PredictionCorrect
                ? $"You predicted {guess}, and {result}. Nice."
                : $"You predicted {guess}, but {result}. Find out why.";
        }

        static void Next(RoomFlowScreen screen, string label, bool enabled)
        {
            screen.NextLabel = label;
            screen.NextEnabled = enabled;
        }

        static string[] Texts(int count, Func<int, string> text)
        {
            var result = new string[count];
            for (var i = 0; i < count; i++) result[i] = text(i);
            return result;
        }
    }
}
