using System;
using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class TracePlayerTests
    {
        [Test]
        public void Step_PlaysEventsInOrder_AndStopsAtEnd()
        {
            var room = Room11.Create();
            var player = new TracePlayer(room.Trace);

            Assert.IsTrue(player.HasNext);
            Assert.AreEqual(TraceEventType.LineExecuted, player.Step().Type);
            Assert.AreEqual(TraceEventType.VariableDeclared, player.Step().Type);
            Assert.AreEqual(2, player.Position);

            player.RunToEnd();
            Assert.IsFalse(player.HasNext);
            Assert.IsNull(player.Step());
        }

        [Test]
        public void Reset_ReturnsToStart_AndRaisesEvent()
        {
            var player = new TracePlayer(Room11.Create().Trace);
            var resets = 0;
            player.WasReset += () => resets++;
            player.RunToEnd();

            player.Reset();

            Assert.AreEqual(0, player.Position);
            Assert.IsTrue(player.HasNext);
            Assert.AreEqual(1, resets);
        }

        [Test]
        public void RunToEnd_RaisesExactlyElevenEvents_ForRoom11()
        {
            var player = new TracePlayer(Room11.Create().Trace);
            var played = 0;
            player.EventPlayed += _ => played++;

            player.RunToEnd();

            Assert.AreEqual(11, played);
        }
    }

    public class Room11DataTests
    {
        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room11.Create();

        [Test]
        public void Code_HasFourLines_AndEveryEventLineIsInRange()
        {
            Assert.AreEqual(4, _room.CodeLines.Count);
            Assert.IsTrue(_room.Trace.All(e => e.Line >= 1 && e.Line <= 4));
        }

        [Test]
        public void TraceMatchesPlan_ReferenceCopyShowsOneObject()
        {
            Assert.AreEqual(11, _room.Trace.Count);
            Assert.AreEqual(1, _room.Trace.Count(e => e.Type == TraceEventType.ObjectCreated));
            Assert.AreEqual("1", _room.Trace.Last().Text);
        }

        [Test]
        public void ExactlyOneBestFix_AndOneCorrectHypothesis()
        {
            Assert.AreEqual(3, _room.Fixes.Count);
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Best));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.SymptomOnly));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Wrong));
            Assert.AreEqual(3, _room.Hypotheses.Count);
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.IsCorrect));
        }

        [Test]
        public void CorrectPrediction_IsTheOptionOne()
        {
            Assert.AreEqual(4, _room.Predict.Options.Count);
            Assert.AreEqual("1", _room.Predict.Options[_room.Predict.CorrectIndex]);
        }

        [Test]
        public void HasThreeHints_AndDebrief_AndSupportCode()
        {
            Assert.AreEqual(RoomSession.MaxHints, _room.Hints.Count);
            Assert.IsFalse(string.IsNullOrWhiteSpace(_room.Debrief));
            Assert.IsFalse(string.IsNullOrWhiteSpace(_room.Goal));
            StringAssert.Contains("class Chest", _room.SupportCode);
        }

        [Test]
        public void EveryFix_HasConsequenceAndTestMessage()
        {
            foreach (var fix in _room.Fixes)
            {
                Assert.IsNotEmpty(fix.Consequence.ToList());
                Assert.IsFalse(string.IsNullOrWhiteSpace(fix.TestMessage));
            }
        }
    }

    public class RoomSessionTests
    {
        RoomSession _session;

        [SetUp]
        public void SetUp() => _session = new RoomSession(Room11.Create());

        void ToHypothesis()
        {
            _session.Begin();
            _session.SubmitPrediction(1);
            _session.Trace.RunToEnd();
            _session.FinishObserving();
            _session.FinishInvestigating();
        }

        void ToFix()
        {
            ToHypothesis();
            _session.ChooseHypothesis(2);
        }

        [Test]
        public void StartsAtTicket()
        {
            Assert.AreEqual(RoomStep.Ticket, _session.Step);
        }

        [Test]
        public void OutOfOrderActions_Throw()
        {
            Assert.Throws<InvalidOperationException>(() => _session.ChooseFix(0));
            Assert.Throws<InvalidOperationException>(() => _session.SubmitPrediction(1));
            _session.Begin();
            Assert.Throws<InvalidOperationException>(() => _session.ChooseFix(0));
            Assert.Throws<InvalidOperationException>(() => _session.RunTest());
            Assert.Throws<InvalidOperationException>(() => _session.Finish());
        }

        [Test]
        public void FinishObserving_NeedsWholeReplay()
        {
            _session.Begin();
            _session.SubmitPrediction(1);
            Assert.Throws<InvalidOperationException>(() => _session.FinishObserving());

            _session.Trace.RunToEnd();
            _session.FinishObserving();

            Assert.AreEqual(RoomStep.Investigate, _session.Step);
        }

        [Test]
        public void WrongHypothesis_StaysOnHypothesis()
        {
            ToHypothesis();

            Assert.IsFalse(_session.ChooseHypothesis(0));
            Assert.AreEqual(RoomStep.Hypothesis, _session.Step);
            Assert.IsTrue(_session.ChooseHypothesis(2));
            Assert.AreEqual(RoomStep.Fix, _session.Step);
        }

        [Test]
        public void SymptomOnlyFix_FailsAndSendsPlayerBack()
        {
            ToFix();

            var fix = _session.ChooseFix(1);
            Assert.AreEqual(FixQuality.SymptomOnly, fix.Quality);
            Assert.IsNotEmpty(fix.Consequence.ToList());
            Assert.IsFalse(_session.RunTest());

            Assert.AreEqual(RoomStep.Fix, _session.Step);
            Assert.AreEqual(1, _session.WrongFixes);
            StringAssert.Contains("Sword", _session.CurrentFix.TestMessage);
            Assert.AreEqual(0, _session.Stars);
        }

        [Test]
        public void WrongFix_ThrowsNullReferenceInConsequence()
        {
            ToFix();

            _session.ChooseFix(2);

            Assert.AreEqual(TraceEventType.ExceptionThrown, _session.FixTrace.Events.Last().Type);
            Assert.IsFalse(_session.RunTest());
            Assert.IsFalse(_session.IsComplete);
        }

        [Test]
        public void PerfectRun_GivesThreeStars()
        {
            ToFix();
            _session.ChooseFix(0);
            Assert.IsTrue(_session.RunTest());
            _session.Finish();

            Assert.IsTrue(_session.IsComplete);
            Assert.AreEqual(3, _session.Stars);
        }

        [Test]
        public void OneHint_StillThreeStars_TwoHints_TwoStars()
        {
            ToHypothesis();
            Assert.IsTrue(_session.TryUseHint(out _));
            _session.ChooseHypothesis(2);
            _session.ChooseFix(0);
            _session.RunTest();
            _session.Finish();
            Assert.AreEqual(3, _session.Stars);

            var second = new RoomSession(Room11.Create());
            second.Begin();
            second.SubmitPrediction(1);
            second.Trace.RunToEnd();
            second.FinishObserving();
            second.FinishInvestigating();
            second.TryUseHint(out _);
            second.TryUseHint(out _);
            second.ChooseHypothesis(2);
            second.ChooseFix(0);
            second.RunTest();
            second.Finish();
            Assert.AreEqual(2, second.Stars);
        }

        [Test]
        public void WrongPrediction_OrWrongHypothesis_GivesOneStar()
        {
            _session.Begin();
            Assert.IsFalse(_session.SubmitPrediction(0));
            _session.Trace.RunToEnd();
            _session.FinishObserving();
            _session.FinishInvestigating();
            _session.ChooseHypothesis(2);
            _session.ChooseFix(0);
            _session.RunTest();
            _session.Finish();
            Assert.AreEqual(1, _session.Stars);

            var other = new RoomSession(Room11.Create());
            other.Begin();
            other.SubmitPrediction(1);
            other.Trace.RunToEnd();
            other.FinishObserving();
            other.FinishInvestigating();
            other.ChooseHypothesis(1);
            other.ChooseHypothesis(2);
            other.ChooseFix(0);
            other.RunTest();
            other.Finish();
            Assert.AreEqual(1, other.Stars);
        }

        [Test]
        public void Hints_ComeInOrder_AndRunOut()
        {
            ToHypothesis();

            Assert.IsTrue(_session.TryUseHint(out var first));
            StringAssert.Contains("How many chests", first);
            Assert.IsTrue(_session.TryUseHint(out _));
            Assert.IsTrue(_session.TryUseHint(out _));
            Assert.IsFalse(_session.TryUseHint(out var none));
            Assert.IsNull(none);
            Assert.AreEqual(3, _session.HintsUsed);
        }

        [Test]
        public void Hint_BeforeInvestigating_Throws()
        {
            _session.Begin();
            Assert.Throws<InvalidOperationException>(() => _session.TryUseHint(out _));
        }

        [Test]
        public void StepChanged_FiresOnEachTransition()
        {
            var steps = new System.Collections.Generic.List<RoomStep>();
            _session.StepChanged += steps.Add;

            _session.Begin();
            _session.SubmitPrediction(1);

            CollectionAssert.AreEqual(new[] { RoomStep.Predict, RoomStep.Observe }, steps);
        }
    }
}
