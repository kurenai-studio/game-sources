using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class Room15Tests
    {
        static KeepState Play(System.Collections.Generic.IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state;
        }

        RoomDefinition _room;

        [SetUp]
        public void SetUp() => _room = Room15.Create();

        [Test]
        public void Library_KnowsRoom15()
        {
            Assert.IsTrue(RoomLibrary.Has("1-5"));
            Assert.IsTrue(RoomLibrary.TryCreate("1-5", out var room));
            Assert.AreEqual("The Empty Chest", room.Title);
            Assert.IsFalse(RoomLibrary.Has("1-7"));
        }

        [Test]
        public void Data_FollowsThePlan()
        {
            Assert.AreEqual(3, _room.CodeLines.Count);
            Assert.AreEqual(7, _room.Trace.Count);
            Assert.AreEqual("The program crashes with an error", _room.Predict.Options[_room.Predict.CorrectIndex]);
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.IsCorrect));
            Assert.AreEqual(1, _room.Hypotheses.Count(h => h.Verdict == Verdict.Close));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Best));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.SymptomOnly));
            Assert.AreEqual(1, _room.Fixes.Count(f => f.Quality == FixQuality.Wrong));
            Assert.AreEqual(RoomSession.MaxHints, _room.Hints.Count);
            Assert.IsTrue(_room.HasSupportCode);
            Assert.IsTrue(_room.Fixes.All(f => f.CodeLines.Count <= 5));
            Assert.IsTrue(_room.Trace.All(e => e.Line >= 1 && e.Line <= 3));
        }

        [Test]
        public void OriginalTrace_VaultIsNull_AndTheProgramCrashes()
        {
            var state = Play(_room.Trace);

            Assert.IsTrue(state.Guards[0].IsNull);
            Assert.AreEqual(0, state.Chests.Count);
            Assert.AreEqual("NullReferenceException", state.Error);
            CollectionAssert.AreEqual(new[] { "vault -> null" }, state.WatchLines().ToList());
        }

        [Test]
        public void BestFix_CreatesTheChest_AndStoresTheGem()
        {
            var state = Play(_room.Fixes[0].Consequence);

            Assert.IsFalse(state.Guards[0].IsNull);
            Assert.AreEqual(1, state.Chests.Count);
            CollectionAssert.AreEqual(new[] { "Gem" }, state.Chests[0].Items.ToList());
            Assert.AreEqual(string.Empty, state.Error);
        }

        [Test]
        public void SymptomFix_DoesNotCrash_ButStoresNothing()
        {
            var state = Play(_room.Fixes[1].Consequence);

            Assert.AreEqual(string.Empty, state.Error);
            Assert.IsTrue(state.Guards[0].IsNull);
            Assert.AreEqual(0, state.Chests.Count);
        }

        [Test]
        public void WrongFix_StillCrashes()
        {
            Assert.AreEqual("NullReferenceException", Play(_room.Fixes[2].Consequence).Error);
        }

        [Test]
        public void SymptomFix_ShowsClose_AndWrongFixShowsWrong_ThroughTheFlow()
        {
            var state = new KeepState();
            var session = new RoomSession(_room);
            session.Trace.EventPlayed += state.Apply;
            var flow = new RoomFlow(session, state);
            flow.Next();
            flow.Pick(2);
            session.Trace.RunToEnd();
            flow.Next();
            flow.Next();
            flow.Pick(1);
            Assert.AreEqual(Verdict.Close, flow.Screen.Verdict);
            flow.Pick(2);

            flow.Pick(1);
            session.FixTrace.RunToEnd();
            flow.FixReplayFinished();
            Assert.AreEqual(Verdict.Close, flow.Screen.Verdict);

            flow.Pick(2);
            session.FixTrace.RunToEnd();
            flow.FixReplayFinished();
            Assert.AreEqual(Verdict.Wrong, flow.Screen.Verdict);
        }

        [Test]
        public void PerfectRun_ThroughTheFlow_GivesThreeStars()
        {
            var state = new KeepState();
            var session = new RoomSession(_room);
            session.Trace.EventPlayed += state.Apply;
            var flow = new RoomFlow(session, state);

            flow.Next();
            flow.Pick(2);
            session.Trace.RunToEnd();
            StringAssert.Contains("and it crashed with NullReferenceException. Nice.", flow.Screen.Body);
            flow.Next();
            StringAssert.Contains("vault -> null", flow.Screen.Body);
            Assert.AreEqual("Investigate: what does vault point to?", flow.Screen.Prompt);
            flow.Next();
            Assert.AreEqual("Why does the program crash?", flow.Screen.Prompt);
            flow.Pick(2);
            StringAssert.Contains("The Gem ends up in a vault", flow.Screen.Prompt);
            flow.Pick(0);
            session.FixTrace.RunToEnd();
            flow.FixReplayFinished();
            flow.Next();

            Assert.AreEqual(3, session.Stars);
        }
    }
}
