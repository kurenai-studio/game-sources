using System.IO;
using Codebound.App;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class SaveProgressTests
    {
        string _directory;
        SaveService _service;

        [SetUp]
        public void SetUp()
        {
            _directory = Path.Combine(Path.GetTempPath(), "codebound-tests-" + System.Guid.NewGuid());
            Directory.CreateDirectory(_directory);
            _service = new SaveService(_directory);
        }

        [TearDown]
        public void TearDown()
        {
            if (Directory.Exists(_directory)) Directory.Delete(_directory, true);
        }

        [Test]
        public void NewSave_StartsWithNoProgress()
        {
            Assert.IsEmpty(new PlayerSave().progress);
        }

        [Test]
        public void Progress_SurvivesSaveAndLoad()
        {
            var save = new PlayerSave { playerName = "Jean", lookId = 1 };
            UnlockRules.Record(save.progress, "1-1", 3);
            UnlockRules.Record(save.progress, "1-2", 1);

            _service.Save(save);

            Assert.IsTrue(_service.TryLoad(out var loaded));
            Assert.AreEqual(3, UnlockRules.GetStars(loaded.progress, "1-1"));
            Assert.AreEqual(1, UnlockRules.GetStars(loaded.progress, "1-2"));
            Assert.AreEqual(0, UnlockRules.GetStars(loaded.progress, "1-3"));
        }

        [Test]
        public void OldSaveWithoutProgress_StillLoads_AsNothingCompleted()
        {
            File.WriteAllText(Path.Combine(_directory, "save.json"),
                "{\"version\":1,\"playerName\":\"Jean\",\"lookId\":0}");

            Assert.IsTrue(_service.TryLoad(out var loaded));
            Assert.IsNotNull(loaded.progress);
            Assert.AreEqual(0, UnlockRules.GetStars(loaded.progress, "1-1"));
        }
    }
}
