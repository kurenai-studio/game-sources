using JGM.Gameplay.Wallet;
using NUnit.Framework;

namespace JGM.Tests
{
    public class PlayerWalletTest
    {
        private PlayerWallet playerWallet;

        [SetUp]
        public void SetUp()
        {
            playerWallet = new PlayerWallet(0);
        }

        [TestCase(0)]
        [TestCase(22)]
        [TestCase(500)]
        [TestCase(-600)]
        [TestCase(5000)]
        public void CreateWallet_CoinsValueIsDefault(int startingCoins)
        {
            playerWallet = new PlayerWallet(startingCoins);
            int expected = startingCoins;
            if (expected < 0)
            {
                expected = 0;
            }
            Assert.AreEqual(expected, playerWallet.Coins);
        }

        [Test]
        public void AddCoins_CoinsValueIsCorrectlySet()
        {
            playerWallet.AddCoins(57);
            Assert.AreEqual(57, playerWallet.Coins);
        }

        [Test]
        public void RemoveCoins_CoinsValueIsCorrectlySet()
        {
            playerWallet = new PlayerWallet(500);
            playerWallet.RemoveCoins(50);
            Assert.AreEqual(450, playerWallet.Coins);
            playerWallet.RemoveCoins(450);
            Assert.AreEqual(0, playerWallet.Coins);
            playerWallet.RemoveCoins(250);
            Assert.AreEqual(0, playerWallet.Coins);
        }

        [Test]
        public void Restart_CoinsValueIsDefault()
        {
            playerWallet = new PlayerWallet(144);
            playerWallet.AddCoins(200);
            playerWallet.RemoveCoins(100);
            playerWallet.AddCoins(200);
            playerWallet.Restart();
            Assert.AreEqual(144, playerWallet.Coins);
        }
    }
}