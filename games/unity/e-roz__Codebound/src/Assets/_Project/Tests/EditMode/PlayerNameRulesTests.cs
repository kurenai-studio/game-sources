using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class PlayerNameRulesTests
    {
        [Test]
        public void Clean_TrimsAndCollapsesSpaces()
        {
            Assert.AreEqual("jean cruz", PlayerNameRules.Clean("  jean   cruz  "));
        }

        [Test]
        public void Clean_KeepsEnyeAndAccents()
        {
            Assert.AreEqual("Ñoel", PlayerNameRules.Clean("Ñoel"));
            Assert.AreEqual("Peña", PlayerNameRules.Clean("Peña"));
        }

        [Test]
        public void Clean_DropsEmoji()
        {
            Assert.AreEqual("Jean", PlayerNameRules.Clean("Jean😀"));
        }

        [Test]
        public void Clean_DropsDisallowedSymbols()
        {
            Assert.AreEqual("Jenb", PlayerNameRules.Clean("Je@n#<b>"));
        }

        [Test]
        public void Clean_KeepsAllowedPunctuation()
        {
            Assert.AreEqual("Ann-Marie O'Neil", PlayerNameRules.Clean("Ann-Marie O'Neil"));
            Assert.AreEqual("J. Cruz", PlayerNameRules.Clean("J. Cruz"));
        }

        [Test]
        public void Clean_KeepsDigits()
        {
            Assert.AreEqual("Player 1", PlayerNameRules.Clean("Player 1"));
        }

        [Test]
        public void Clean_TreatsTabsAndNewlinesAsSpaces()
        {
            Assert.AreEqual("Jean Cruz", PlayerNameRules.Clean("Jean\tCruz"));
            Assert.AreEqual("Jean Cruz", PlayerNameRules.Clean("Jean\nCruz"));
        }

        [TestCase(null)]
        [TestCase("")]
        [TestCase("     ")]
        [TestCase("😀😀")]
        [TestCase("@#$%")]
        public void Clean_EmptyOrUnusable_ReturnsFallback(string raw)
        {
            Assert.AreEqual(PlayerNameRules.FallbackName, PlayerNameRules.Clean(raw));
        }

        [Test]
        public void Clean_TruncatesToMaxLength()
        {
            Assert.AreEqual("abcdefghijklmnop", PlayerNameRules.Clean("abcdefghijklmnopqrstuvwxyz"));
            Assert.AreEqual(PlayerNameRules.MaxLength, PlayerNameRules.Clean("abcdefghijklmnopqrstuvwxyz").Length);
        }

        [Test]
        public void Clean_TruncationDoesNotLeaveTrailingSpace()
        {
            Assert.AreEqual("abcdefghijklmno", PlayerNameRules.Clean("abcdefghijklmno qrs"));
        }

        [TestCase('a', true)]
        [TestCase('Ñ', true)]
        [TestCase('5', true)]
        [TestCase('-', true)]
        [TestCase('\'', true)]
        [TestCase('.', true)]
        [TestCase(' ', true)]
        [TestCase('@', false)]
        [TestCase('<', false)]
        [TestCase('\n', false)]
        [TestCase('\t', false)]
        public void IsAllowedChar_MatchesTheRules(char c, bool expected)
        {
            Assert.AreEqual(expected, PlayerNameRules.IsAllowedChar(c));
        }
    }
}
