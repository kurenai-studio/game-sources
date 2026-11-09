using System;

namespace Codebound.Core
{
    public enum RoomStep
    {
        Ticket,
        Predict,
        Observe,
        Investigate,
        Hypothesis,
        Fix,
        Prove,
        Debrief,
        Complete
    }

    public sealed class RoomSession
    {
        public const int MaxHints = 3;

        public RoomSession(RoomDefinition room)
        {
            Room = room ?? throw new ArgumentNullException(nameof(room));
            Trace = new TracePlayer(room.Trace);
        }

        public event Action<RoomStep> StepChanged;

        public RoomDefinition Room { get; }
        public TracePlayer Trace { get; }
        public RoomStep Step { get; private set; } = RoomStep.Ticket;
        public bool PredictionCorrect { get; private set; }
        public int WrongHypotheses { get; private set; }
        public int WrongFixes { get; private set; }
        public int HintsUsed { get; private set; }
        public FixOption CurrentFix { get; private set; }
        public TracePlayer FixTrace { get; private set; }

        public bool IsComplete => Step == RoomStep.Complete;

        public int Stars
        {
            get
            {
                if (!IsComplete) return 0;
                if (!PredictionCorrect || WrongHypotheses > 0) return 1;
                return HintsUsed <= 1 ? 3 : 2;
            }
        }

        public void Begin()
        {
            Require(RoomStep.Ticket);
            MoveTo(RoomStep.Predict);
        }

        public bool SubmitPrediction(int optionIndex)
        {
            Require(RoomStep.Predict);
            if (optionIndex < 0 || optionIndex >= Room.Predict.Options.Count)
                throw new ArgumentOutOfRangeException(nameof(optionIndex));

            PredictionCorrect = optionIndex == Room.Predict.CorrectIndex;
            MoveTo(RoomStep.Observe);
            return PredictionCorrect;
        }

        public void FinishObserving()
        {
            Require(RoomStep.Observe);
            if (Trace.HasNext) throw new InvalidOperationException("Watch the whole replay first.");
            MoveTo(RoomStep.Investigate);
        }

        public void FinishInvestigating()
        {
            Require(RoomStep.Investigate);
            MoveTo(RoomStep.Hypothesis);
        }

        public bool ChooseHypothesis(int index)
        {
            Require(RoomStep.Hypothesis);
            if (index < 0 || index >= Room.Hypotheses.Count) throw new ArgumentOutOfRangeException(nameof(index));

            if (!Room.Hypotheses[index].IsCorrect)
            {
                WrongHypotheses++;
                return false;
            }

            MoveTo(RoomStep.Fix);
            return true;
        }

        public FixOption ChooseFix(int index)
        {
            Require(RoomStep.Fix);
            if (index < 0 || index >= Room.Fixes.Count) throw new ArgumentOutOfRangeException(nameof(index));

            CurrentFix = Room.Fixes[index];
            FixTrace = new TracePlayer(CurrentFix.Consequence);
            MoveTo(RoomStep.Prove);
            return CurrentFix;
        }

        // A failing test sends the player back to choose again; a passing one moves on to the debrief.
        public bool RunTest()
        {
            Require(RoomStep.Prove);
            if (CurrentFix.TestPasses)
            {
                MoveTo(RoomStep.Debrief);
                return true;
            }

            WrongFixes++;
            MoveTo(RoomStep.Fix);
            return false;
        }

        public void Finish()
        {
            Require(RoomStep.Debrief);
            MoveTo(RoomStep.Complete);
        }

        public bool TryUseHint(out string hint)
        {
            if (Step != RoomStep.Investigate && Step != RoomStep.Hypothesis && Step != RoomStep.Fix)
                throw new InvalidOperationException($"Hints are not available during {Step}.");

            if (HintsUsed >= Room.Hints.Count)
            {
                hint = null;
                return false;
            }

            hint = Room.Hints[HintsUsed++];
            return true;
        }

        void Require(RoomStep expected)
        {
            if (Step != expected)
                throw new InvalidOperationException($"This action needs step {expected} but the room is at {Step}.");
        }

        void MoveTo(RoomStep next)
        {
            Step = next;
            StepChanged?.Invoke(next);
        }
    }
}
