using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class MainMenuRulesTests
    {
        [Test]
        public void Continue_IsEnabledOnlyWhenASaveExists()
        {
            Assert.IsTrue(MainMenuRules.IsContinueEnabled(true));
            Assert.IsFalse(MainMenuRules.IsContinueEnabled(false));
        }

        [Test]
        public void NewGame_NeedsConfirmOnlyWhenASaveExists()
        {
            Assert.IsTrue(MainMenuRules.NewGameNeedsConfirm(true));
            Assert.IsFalse(MainMenuRules.NewGameNeedsConfirm(false));
        }
    }
}
