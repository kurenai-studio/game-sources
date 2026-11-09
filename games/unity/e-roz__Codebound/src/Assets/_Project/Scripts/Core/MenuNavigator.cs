using System;

namespace Codebound.Core
{
    public class MenuNavigator
    {
        MenuScreen _origin = MenuScreen.Title;

        public MenuScreen Current { get; private set; } = MenuScreen.Title;

        public event Action<MenuScreen> ScreenChanged;

        public void Show(MenuScreen screen)
        {
            if (screen == Current) return;
            if (ReturnsToOrigin(screen) && !ReturnsToOrigin(Current)) _origin = Current;
            Current = screen;
            ScreenChanged?.Invoke(screen);
        }

        public void HandleBack()
        {
            switch (Current)
            {
                case MenuScreen.Title:
                    Show(MenuScreen.ConfirmQuit);
                    break;
                case MenuScreen.KeepRooms:
                    Show(MenuScreen.KeepWings);
                    break;
                case MenuScreen.KeepWings:
                    Show(MenuScreen.KeepMenu);
                    break;
                case MenuScreen.KeepMenu:
                    Show(MenuScreen.KeepWings);
                    break;
                case MenuScreen.ConfirmTitle:
                    Show(MenuScreen.KeepMenu);
                    break;
                case MenuScreen.Settings:
                case MenuScreen.Credits:
                case MenuScreen.Placeholder:
                    Show(_origin);
                    break;
                default:
                    Show(MenuScreen.Title);
                    break;
            }
        }

        static bool ReturnsToOrigin(MenuScreen screen) =>
            screen == MenuScreen.Settings || screen == MenuScreen.Credits || screen == MenuScreen.Placeholder;
    }
}
