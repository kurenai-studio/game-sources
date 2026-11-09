using System;
using System.IO;
using Codebound.App;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class SaveServiceTests
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

        static PlayerSave MakeSave(string name = "Jean", int look = 1) =>
            new PlayerSave { playerName = name, lookId = look };

        [Test]
        public void HasSave_NoFile_ReturnsFalse()
        {
            var service = new SaveService(_dir);

            Assert.IsFalse(service.HasSave());
        }

        [Test]
        public void Save_CreatesMissingDirectory_AndHasSaveIsTrue()
        {
            var service = new SaveService(_dir);

            service.Save(MakeSave());

            Assert.IsTrue(Directory.Exists(_dir));
            Assert.IsTrue(service.HasSave());
        }

        [Test]
        public void SaveThenLoad_RoundTripsNameAndLook()
        {
            var service = new SaveService(_dir);
            service.Save(MakeSave("Jean", 2));

            var loaded = service.TryLoad(out var save);

            Assert.IsTrue(loaded);
            Assert.AreEqual("Jean", save.playerName);
            Assert.AreEqual(2, save.lookId);
        }

        [Test]
        public void Save_OverwritesExistingSave()
        {
            var service = new SaveService(_dir);
            service.Save(MakeSave("First", 1));

            service.Save(MakeSave("Second", 2));

            service.TryLoad(out var save);
            Assert.AreEqual("Second", save.playerName);
            Assert.AreEqual(2, save.lookId);
        }

        [Test]
        public void Save_InvalidSave_Throws()
        {
            var service = new SaveService(_dir);

            Assert.Throws<ArgumentException>(() => service.Save(MakeSave("   ")));
            Assert.Throws<ArgumentException>(() => service.Save(null));
            Assert.IsFalse(service.HasSave());
        }

        [Test]
        public void Delete_RemovesSave()
        {
            var service = new SaveService(_dir);
            service.Save(MakeSave());

            service.Delete();

            Assert.IsFalse(service.HasSave());
        }

        [Test]
        public void Delete_NoFile_DoesNotThrow()
        {
            var service = new SaveService(_dir);

            Assert.DoesNotThrow(() => service.Delete());
        }

        [Test]
        public void CorruptFile_IsTreatedAsNoSave_AndBackedUp()
        {
            Directory.CreateDirectory(_dir);
            File.WriteAllText(Path.Combine(_dir, "save.json"), "not json {{{");
            var service = new SaveService(_dir);

            Assert.IsFalse(service.HasSave());
            Assert.IsFalse(service.TryLoad(out var save));

            Assert.IsNull(save);
            Assert.IsTrue(service.BackedUpCorruptSave);
            Assert.IsTrue(File.Exists(Path.Combine(_dir, "save.corrupt.json")));
            Assert.IsFalse(File.Exists(Path.Combine(_dir, "save.json")));
        }

        [Test]
        public void EmptyJsonObject_IsNotAValidSave()
        {
            Directory.CreateDirectory(_dir);
            File.WriteAllText(Path.Combine(_dir, "save.json"), "{}");
            var service = new SaveService(_dir);

            Assert.IsFalse(service.HasSave());
        }

        [Test]
        public void HasSave_CorruptFile_DoesNotMoveTheFile()
        {
            Directory.CreateDirectory(_dir);
            File.WriteAllText(Path.Combine(_dir, "save.json"), "garbage");
            var service = new SaveService(_dir);

            service.HasSave();

            Assert.IsTrue(File.Exists(Path.Combine(_dir, "save.json")));
            Assert.IsFalse(service.BackedUpCorruptSave);
        }
    }
}
