using System;
using System.IO;
using Codebound.App;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class SettingsServiceTests
    {
        string _dir;

        [SetUp]
        public void SetUp()
        {
            _dir = Path.Combine(Path.GetTempPath(), "codebound-tests-" + Guid.NewGuid().ToString("N"));
        }

        [TearDown]
        public void TearDown()
        {
            if (Directory.Exists(_dir)) Directory.Delete(_dir, true);
        }

        [Test]
        public void Load_NoFile_UsesDefaultVolumes()
        {
            var service = new SettingsService(_dir);

            service.Load();

            Assert.AreEqual(SettingsData.DefaultVolume, service.Settings.musicVolume);
            Assert.AreEqual(SettingsData.DefaultVolume, service.Settings.sfxVolume);
        }

        [Test]
        public void SetVolumes_SaveThenLoadInNewInstance_PersistsValues()
        {
            var first = new SettingsService(_dir);
            first.SetMusicVolume(0.25f);
            first.SetSfxVolume(0.5f);
            first.Save();

            var second = new SettingsService(_dir);
            second.Load();

            Assert.AreEqual(0.25f, second.Settings.musicVolume, 0.0001f);
            Assert.AreEqual(0.5f, second.Settings.sfxVolume, 0.0001f);
        }

        [Test]
        public void SetVolume_OutOfRange_IsClamped()
        {
            var service = new SettingsService(_dir);

            service.SetMusicVolume(1.5f);
            service.SetSfxVolume(-0.3f);

            Assert.AreEqual(1f, service.Settings.musicVolume);
            Assert.AreEqual(0f, service.Settings.sfxVolume);
        }

        [Test]
        public void SetVolume_RaisesChangedOncePerCall()
        {
            var service = new SettingsService(_dir);
            var count = 0;
            service.Changed += () => count++;

            service.SetMusicVolume(0.1f);
            service.SetSfxVolume(0.2f);

            Assert.AreEqual(2, count);
        }

        [Test]
        public void Load_CorruptFile_FallsBackToDefaults()
        {
            Directory.CreateDirectory(_dir);
            File.WriteAllText(Path.Combine(_dir, "settings.json"), "not json {{{");
            var service = new SettingsService(_dir);

            Assert.DoesNotThrow(() => service.Load());

            Assert.AreEqual(SettingsData.DefaultVolume, service.Settings.musicVolume);
            Assert.AreEqual(SettingsData.DefaultVolume, service.Settings.sfxVolume);
        }

        [Test]
        public void Load_OutOfRangeValuesInFile_AreClamped()
        {
            Directory.CreateDirectory(_dir);
            File.WriteAllText(Path.Combine(_dir, "settings.json"), "{\"musicVolume\":5,\"sfxVolume\":-2}");
            var service = new SettingsService(_dir);

            service.Load();

            Assert.AreEqual(1f, service.Settings.musicVolume);
            Assert.AreEqual(0f, service.Settings.sfxVolume);
        }

        [Test]
        public void Save_CreatesMissingDirectory()
        {
            var service = new SettingsService(_dir);

            service.Save();

            Assert.IsTrue(File.Exists(Path.Combine(_dir, "settings.json")));
        }
    }
}
