using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class RoomFlowTests
    {
        KeepState _state;
        RoomSession _session;
        RoomFlow _flow;

        [SetUp]
        public void SetUp()
        {
            _state = new KeepState();
            _session = new RoomSession(Room11.Create());
            _session.Trace.EventPlayed += _state.Apply;
            _flow = new RoomFlow(_session, _state);
        }

        void ReplayMainTrace() => _session.Trace.RunToEnd();

        // What the scene does: the fix replays, then tells the flow it has finished.
        void ReplayFix()
        {
            _session.FixTrace.RunToEnd();
            _flow.FixReplayFinished();
        }

        void ToHypothesis(int prediction = 1)
        {
            _flow.Next();
            _flow.Pick(prediction);
            ReplayMainTrace();
            _flow.Next();
            _flow.Next();
        }

        void ToFix()
        {
            ToHypothesis();
            _flow.Pick(2);
        }

        [Test]
        public void Goal_IsShownOnTheTicket_AndWhenPickingAFix()
        {
            StringAssert.Contains("Vault B stays empty", _flow.Screen.Body);

            ToFix();

            StringAssert.Contains("Goal: Vault A keeps the Sword. Vault B stays empty.", _flow.Screen.Prompt);
        }

        [Test]
        public void Ticket_OffersStart_AndNoOptions()
        {
            var screen = _flow.Screen;

            Assert.AreEqual("Start", screen.NextLabel);
            Assert.IsTrue(screen.NextEnabled);
            Assert.IsEmpty(screen.Options.ToList());
            Assert.IsFalse(screen.HintVisible);
        }

        [Test]
        public void Predict_ShowsFourOptions_AndNoNextButton()
        {
            _flow.Next();

            var screen = _flow.Screen;
            Assert.AreEqual(4, screen.Options.Count);
            Assert.AreEqual("What does line 4 print?", screen.Prompt);
            Assert.IsNull(screen.NextLabel);
        }

        [Test]
        public void Observe_NextWaitsForFullReplay_ThenReportsPrediction()
        {
            _flow.Next();
            _flow.Pick(0);

            Assert.IsTrue(_flow.Screen.CanReplay);
            Assert.IsFalse(_flow.Screen.NextEnabled);
            StringAssert.Contains("predicted 0", _flow.Screen.Body);

            _flow.Next();
            Assert.AreEqual(RoomStep.Observe, _session.Step);

            ReplayMainTrace();
            Assert.IsTrue(_flow.Screen.NextEnabled);
            StringAssert.Contains("but it printed 1", _flow.Screen.Body);
        }

        [Test]
        public void WatchList_NamesBothGuardsPointingAtChestOne()
        {
            _flow.Next();
            _flow.Pick(1);
            ReplayMainTrace();
            _flow.Next();

            var body = _flow.Screen.Body;
            StringAssert.Contains("vaultA -> chest #1", body);
            StringAssert.Contains("vaultB -> chest #1", body);
            Assert.IsTrue(_flow.Screen.HintVisible);
        }

        [Test]
        public void WrongHypothesis_ShowsWrongVerdict_AndStaysPut()
        {
            ToHypothesis();

            _flow.Pick(0);

            Assert.AreEqual(RoomStep.Hypothesis, _session.Step);
            Assert.AreEqual(Verdict.Wrong, _flow.Screen.Verdict);
            Assert.AreEqual("NOT QUITE", _flow.Screen.VerdictTitle);
            StringAssert.Contains("only one chest", _flow.Screen.Notice);
        }

        [Test]
        public void CloseHypothesis_ShowsCloseVerdict_AndCostsTheFirstTryStars()
        {
            ToHypothesis();

            _flow.Pick(1);

            Assert.AreEqual(Verdict.Close, _flow.Screen.Verdict);
            Assert.AreEqual("CLOSE, BUT NOT YET", _flow.Screen.VerdictTitle);
            Assert.AreEqual(RoomStep.Hypothesis, _session.Step);
            Assert.AreEqual(1, _session.WrongHypotheses);
        }

        [Test]
        public void TriedHypotheses_AreMarked()
        {
            ToHypothesis();

            _flow.Pick(0);
            _flow.Pick(1);

            var marks = _flow.Screen.OptionMarks;
            Assert.AreEqual(Verdict.Wrong, marks[0]);
            Assert.AreEqual(Verdict.Close, marks[1]);
            Assert.IsNull(marks[2]);
        }

        [Test]
        public void Prediction_ShowsVerdictAtOnce()
        {
            _flow.Next();
            _flow.Pick(0);
            Assert.AreEqual(Verdict.Wrong, _flow.Screen.Verdict);

            var other = new RoomFlow(new RoomSession(Room11.Create()), new KeepState());
            other.Next();
            other.Pick(1);
            Assert.AreEqual(Verdict.Correct, other.Screen.Verdict);
        }

        [Test]
        public void SymptomFix_ShowsCloseAfterTheTest_AndIsMarked()
        {
            ToFix();
            _flow.Pick(1);
            ReplayFix();

            Assert.AreEqual(Verdict.Close, _flow.Screen.Verdict);
            Assert.AreEqual(Verdict.Close, _flow.Screen.OptionMarks[1]);
            Assert.IsNull(_flow.Screen.OptionMarks[0]);
        }

        [Test]
        public void NullFix_ShowsWrongAfterTheTest()
        {
            ToFix();
            _flow.Pick(2);
            ReplayFix();

            Assert.AreEqual(Verdict.Wrong, _flow.Screen.Verdict);
        }

        [Test]
        public void BestFix_ShowsCorrectOnDebrief()
        {
            ToFix();
            _flow.Pick(0);
            ReplayFix();

            Assert.AreEqual(RoomStep.Debrief, _session.Step);
            Assert.AreEqual(Verdict.Correct, _flow.Screen.Verdict);
        }

        [Test]
        public void Hint_ReplacesTheVerdict()
        {
            ToHypothesis();
            _flow.Pick(0);

            _flow.Hint();

            Assert.IsNull(_flow.Screen.Verdict);
        }

        [Test]
        public void Verdict_ClearsWhenTheNextStageStarts()
        {
            _flow.Next();
            _flow.Pick(1);
            ReplayMainTrace();
            Assert.AreEqual(Verdict.Correct, _flow.Screen.Verdict);

            _flow.Next();

            Assert.IsNull(_flow.Screen.Verdict);
        }

        [Test]
        public void CorrectHypothesis_MovesToFix_AndKeepsFeedback()
        {
            ToHypothesis();

            _flow.Pick(2);

            Assert.AreEqual(RoomStep.Fix, _session.Step);
            Assert.AreEqual(3, _flow.Screen.Options.Count);
            StringAssert.Contains("Two names, one chest", _flow.Screen.Notice);
        }

        [Test]
        public void WrongFix_TestRunsByItself_AndReturnsToFixWithMessage()
        {
            ToFix();

            _flow.Pick(1);
            Assert.AreEqual(RoomStep.Prove, _session.Step);
            Assert.IsNull(_flow.Screen.NextLabel);

            ReplayFix();

            Assert.AreEqual(RoomStep.Fix, _session.Step);
            StringAssert.Contains("Sword", _flow.Screen.Notice);
            Assert.AreEqual(1, _session.WrongFixes);
        }

        [Test]
        public void FixReplayFinished_BeforeTheReplayEnds_DoesNothing()
        {
            ToFix();
            _flow.Pick(0);
            _session.FixTrace.Step();

            _flow.FixReplayFinished();

            Assert.AreEqual(RoomStep.Prove, _session.Step);
            Assert.IsNull(_flow.Screen.Verdict);
        }

        [Test]
        public void PickingAgainAfterAFailedFix_ClearsTheOldBanner()
        {
            ToFix();
            _flow.Pick(2);
            ReplayFix();
            Assert.AreEqual(Verdict.Wrong, _flow.Screen.Verdict);

            _flow.Pick(0);

            Assert.IsNull(_flow.Screen.Verdict);
            Assert.AreEqual(RoomStep.Prove, _session.Step);
        }

        [Test]
        public void BestFix_PassesAndFinishesWithStars()
        {
            var completedStars = -1;
            _flow.Completed += stars => completedStars = stars;
            ToFix();

            _flow.Pick(0);
            ReplayFix();
            Assert.AreEqual(RoomStep.Debrief, _session.Step);
            StringAssert.Contains("Test passed", _flow.Screen.Notice);

            _flow.Next();

            Assert.AreEqual(3, completedStars);
            StringAssert.Contains("Stars 3 / 3", _flow.Screen.Prompt);
            Assert.AreEqual("Back to Keep", _flow.Screen.NextLabel);
        }

        [Test]
        public void BackToKeep_RaisesLeaveRequested()
        {
            var left = false;
            _flow.LeaveRequested += () => left = true;
            ToFix();
            _flow.Pick(0);
            ReplayFix();
            _flow.Next();

            _flow.Next();

            Assert.IsTrue(left);
        }

        [Test]
        public void Hint_ShowsInNotice_AndRunsOut()
        {
            ToHypothesis();

            _flow.Hint();
            StringAssert.StartsWith("Hint 1:", _flow.Screen.Notice);
            Assert.AreEqual("Hint (1/3)", _flow.Screen.HintLabel);

            _flow.Hint();
            _flow.Hint();
            _flow.Hint();
            Assert.AreEqual("No more hints.", _flow.Screen.Notice);
        }

        [Test]
        public void ActionsInWrongStep_AreIgnored()
        {
            _flow.Pick(0);
            _flow.Hint();

            Assert.AreEqual(RoomStep.Ticket, _session.Step);
            Assert.AreEqual(0, _session.HintsUsed);
        }

        [Test]
        public void Changed_FiresWhenStepChanges()
        {
            var count = 0;
            _flow.Changed += () => count++;

            _flow.Next();

            Assert.Greater(count, 0);
        }

        [Test]
        public void ReplayAllowed_OnlyWhileWatching()
        {
            Assert.IsFalse(_flow.Screen.CanReplay);
            _flow.Next();
            Assert.IsFalse(_flow.Screen.CanReplay);
            _flow.Pick(1);
            Assert.IsTrue(_flow.Screen.CanReplay);
        }
    }
}
