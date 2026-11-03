using NUnit.Framework;
using QapaqInqa.Core;

namespace QapaqInqa.Core.Tests
{
    public class RecordsTests
    {
        [Test]
        public void AFreshStoreHasNoRecordsAndOnlyTheFirstLevelOpen()
        {
            var records = new Records(new MemoryStore());
            Assert.That(records.BestScore, Is.EqualTo(0));
            Assert.That(records.BestTime(0), Is.EqualTo(0f));
            Assert.That(records.BestRunTime, Is.EqualTo(0f));
            Assert.That(records.LevelsReached, Is.EqualTo(1));
            Assert.That(records.IsUnlocked(0), Is.True);
            Assert.That(records.IsUnlocked(1), Is.False);
            Assert.That(records.IsUnlocked(-1), Is.False);
        }

        [Test]
        public void OnlyBetterScoresAndTimesAreWrittenAndSaved()
        {
            var store = new MemoryStore();
            var records = new Records(store);
            Assert.That(records.SubmitScore(500), Is.True);
            Assert.That(records.SubmitScore(400), Is.False);
            Assert.That(records.SubmitScore(500), Is.False, "a tie is not a new best");
            Assert.That(records.BestScore, Is.EqualTo(500));

            Assert.That(records.SubmitClear(0, 42.5f), Is.True);
            Assert.That(records.SubmitClear(0, 50f), Is.False);
            Assert.That(records.SubmitClear(0, 40f), Is.True);
            Assert.That(records.BestTime(0), Is.EqualTo(40f));
            Assert.That(store.SaveCount, Is.EqualTo(3), "score once, the first clear, the faster clear");

            Assert.That(records.SubmitRunTime(300f), Is.True);
            Assert.That(records.SubmitRunTime(320f), Is.False);
            Assert.That(records.BestRunTime, Is.EqualTo(300f));
        }

        [Test]
        public void ClearingALevelOpensTheNextButNeverPastTheLast()
        {
            var records = new Records(new MemoryStore());
            records.SubmitClear(0, 10f);
            Assert.That(records.LevelsReached, Is.EqualTo(2));
            records.SubmitClear(0, 9f);
            Assert.That(records.LevelsReached, Is.EqualTo(2));
            records.SubmitClear(Levels.All.Count - 1, 10f);
            Assert.That(records.LevelsReached, Is.EqualTo(Levels.All.Count));
            Assert.Throws<System.ArgumentOutOfRangeException>(() => records.SubmitClear(Levels.All.Count, 1f));
        }

        [Test]
        public void RecordsSurviveANewRecordsObjectOnTheSameStore()
        {
            var store = new MemoryStore();
            new Records(store).SubmitScore(1234);
            new Records(store).SubmitClear(1, 33.3f);
            var again = new Records(store);
            Assert.That(again.BestScore, Is.EqualTo(1234));
            Assert.That(again.BestTime(1), Is.EqualTo(33.3f));
            Assert.That(again.IsUnlocked(2), Is.True);
        }

        [TestCase(0f, "--:--")]
        [TestCase(5.04f, "0:05.0")]
        [TestCase(65.25f, "1:05.3")]
        [TestCase(599.96f, "10:00.0")]
        public void TimesAreShownAsMinutesSecondsAndTenths(float seconds, string text)
        {
            Assert.That(Records.FormatTime(seconds), Is.EqualTo(text));
        }

        [Test]
        public void SettingsAreClampedPersistedAndReloaded()
        {
            var store = new MemoryStore();
            var settings = new Settings(store);
            Assert.That(settings.MusicVolume, Is.EqualTo(7));
            Assert.That(settings.EffectsVolume, Is.EqualTo(8));
            Assert.That(settings.ScreenShake, Is.True);
            Assert.That(settings.ShowTimer, Is.True);

            settings.StepMusic(+5);
            settings.StepEffects(-20);
            settings.ToggleShake();
            settings.ToggleTimer();
            Assert.That(settings.MusicVolume, Is.EqualTo(Settings.MaxVolume));
            Assert.That(settings.EffectsVolume, Is.EqualTo(0));
            Assert.That(settings.MusicGain, Is.EqualTo(1f));
            Assert.That(settings.EffectsGain, Is.EqualTo(0f));

            var reloaded = new Settings(store);
            Assert.That(reloaded.MusicVolume, Is.EqualTo(Settings.MaxVolume));
            Assert.That(reloaded.EffectsVolume, Is.EqualTo(0));
            Assert.That(reloaded.ScreenShake, Is.False);
            Assert.That(reloaded.ShowTimer, Is.False);
            Assert.That(store.SaveCount, Is.EqualTo(4));
        }

        [Test]
        public void HealthTakesHitsWithMercyTimeAndHealsUpToItsMax()
        {
            var health = new Health(3);
            Assert.That(health.TryHurt(1), Is.True);
            Assert.That(health.TryHurt(1), Is.False, "still flashing");
            Assert.That(health.Hearts, Is.EqualTo(2));
            health.Tick(Tuning.HurtInvulnerability);
            Assert.That(health.TryHurt(5), Is.True);
            Assert.That(health.Hearts, Is.EqualTo(0));
            Assert.That(health.IsDead, Is.True);
            Assert.That(health.Heal(1), Is.False, "no healing the fallen");

            health.Restore();
            Assert.That(health.Hearts, Is.EqualTo(3));
            Assert.That(health.Heal(1), Is.False, "already full");
            health.Tick(5f);
            health.TryHurt(1);
            Assert.That(health.Heal(1), Is.True);
            Assert.That(health.Hearts, Is.EqualTo(3));
        }
    }
}
