public static class LevelSelectionData
{
    // Default level Level 1 hoga.
    public static int SelectedLevel { get; private set; } = 1;

    public static void SelectLevel(int levelNumber)
    {
        if (levelNumber < 1 || levelNumber > 3)
        {
            return;
        }

        SelectedLevel = levelNumber;
    }
}