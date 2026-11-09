using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    public class MenuNavigatorTests
    {
        [Test]
        public void StartsOnTitle()
        {
            Assert.AreEqual(MenuScreen.Title, new MenuNavigator().Current);
        }

        [Test]
        public void Show_ChangesScreen_AndRaisesEventOnce()
        {
            var navigator = new MenuNavigator();
            var raised = 0;
            MenuScreen last = MenuScreen.Title;
            navigator.ScreenChanged += s => { raised++; last = s; };

            navigator.Show(MenuScreen.Settings);

            Assert.AreEqual(MenuScreen.Settings, navigator.Current);
            Assert.AreEqual(1, raised);
            Assert.AreEqual(MenuScreen.Settings, last);
        }

        [Test]
        public void Show_SameScreen_DoesNotRaiseEvent()
        {
            var navigator = new MenuNavigator();
            var raised = 0;
            navigator.ScreenChanged += _ => raised++;

            navigator.Show(MenuScreen.Title);

            Assert.AreEqual(0, raised);
        }

        [Test]
        public void HandleBack_OnTitle_OpensQuitConfirm()
        {
            var navigator = new MenuNavigator();

            navigator.HandleBack();

            Assert.AreEqual(MenuScreen.ConfirmQuit, navigator.Current);
        }

        [Test]
        public void HandleBack_OnQuitConfirm_ReturnsToTitle()
        {
            var navigator = new MenuNavigator();
            navigator.Show(MenuScreen.ConfirmQuit);

            navigator.HandleBack();

            Assert.AreEqual(MenuScreen.Title, navigator.Current);
        }

        [TestCase(MenuScreen.Settings)]
        [TestCase(MenuScreen.Credits)]
        [TestCase(MenuScreen.ConfirmNewGame)]
        [TestCase(MenuScreen.NameLook)]
        [TestCase(MenuScreen.Placeholder)]
        public void HandleBack_OnAnyPanel_ReturnsToTitle(MenuScreen screen)
        {
            var navigator = new MenuNavigator();
            navigator.Show(screen);

            navigator.HandleBack();

            Assert.AreEqual(MenuScreen.Title, navigator.Current);
        }

        [Test]
        public void HandleBack_FollowsTheKeepMapScreens()
        {
            var navigator = new MenuNavigator();

            navigator.Show(MenuScreen.KeepWings);
            navigator.HandleBack();
            Assert.AreEqual(MenuScreen.KeepMenu, navigator.Current);

            navigator.HandleBack();
            Assert.AreEqual(MenuScreen.KeepWings, navigator.Current);

            navigator.Show(MenuScreen.KeepRooms);
            navigator.HandleBack();
            Assert.AreEqual(MenuScreen.KeepWings, navigator.Current);

            navigator.Show(MenuScreen.KeepMenu);
            navigator.Show(MenuScreen.ConfirmTitle);
            navigator.HandleBack();
            Assert.AreEqual(MenuScreen.KeepMenu, navigator.Current);
        }

        [Test]
        public void SettingsOpenedFromKeepMenu_GoesBackToKeepMenu()
        {
            var navigator = new MenuNavigator();
            navigator.Show(MenuScreen.KeepMenu);
            navigator.Show(MenuScreen.Settings);

            navigator.HandleBack();

            Assert.AreEqual(MenuScreen.KeepMenu, navigator.Current);
        }

        [Test]
        public void SettingsOpenedFromTitle_StillGoesBackToTitle()
        {
            var navigator = new MenuNavigator();
            navigator.Show(MenuScreen.KeepMenu);
            navigator.Show(MenuScreen.Settings);
            navigator.HandleBack();
            navigator.Show(MenuScreen.Title);
            navigator.Show(MenuScreen.Settings);

            navigator.HandleBack();

            Assert.AreEqual(MenuScreen.Title, navigator.Current);
        }

        [Test]
        public void PlaceholderShownFromRoomList_GoesBackToRoomList()
        {
            var navigator = new MenuNavigator();
            navigator.Show(MenuScreen.KeepRooms);
            navigator.Show(MenuScreen.Placeholder);

            navigator.HandleBack();

            Assert.AreEqual(MenuScreen.KeepRooms, navigator.Current);
        }
    }
}
