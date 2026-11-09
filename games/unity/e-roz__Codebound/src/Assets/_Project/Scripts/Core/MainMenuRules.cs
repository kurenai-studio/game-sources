namespace Codebound.Core
{
    public static class MainMenuRules
    {
        public static bool IsContinueEnabled(bool hasSave) => hasSave;

        public static bool NewGameNeedsConfirm(bool hasSave) => hasSave;
    }
}
