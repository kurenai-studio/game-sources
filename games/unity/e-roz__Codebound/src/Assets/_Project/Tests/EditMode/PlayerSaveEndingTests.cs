using Codebound.Core;
using NUnit.Framework;
using UnityEngine;

namespace Codebound.Tests
{
    public class PlayerSaveEndingTests
    {
        [Test]
        public void NewSave_HasNotSeenTheEnding()
        {
            Assert.IsFalse(new PlayerSave().endingSeen);
        }

        [Test]
        public void OldSaveWithoutTheField_LoadsAsNotSeen()
        {
            var save = JsonUtility.FromJson<PlayerSave>("{\"version\":1,\"playerName\":\"Jean\",\"lookId\":0,\"progress\":[]}");

            Assert.IsFalse(save.endingSeen);
            Assert.IsTrue(save.IsValid());
        }

        [Test]
        public void EndingSeen_SurvivesSaveAndLoad()
        {
            var save = new PlayerSave { playerName = "Jean", endingSeen = true };

            var loaded = JsonUtility.FromJson<PlayerSave>(JsonUtility.ToJson(save));

            Assert.IsTrue(loaded.endingSeen);
        }
    }
}
