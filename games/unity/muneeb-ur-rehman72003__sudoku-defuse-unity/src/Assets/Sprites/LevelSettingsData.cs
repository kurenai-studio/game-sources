public static class LevelSettingsData
{
    public static int GetStartingTime()
    {
        switch (LevelSelectionData.SelectedLevel)
        {
            case 2:
                return 240; // 4 minutes

            case 3:
                return 180; // 3 minutes

            default:
                return 300; // Level 1: 5 minutes
        }
    }

    public static int GetMaximumStrikes()
    {
        switch (LevelSelectionData.SelectedLevel)
        {
            case 3:
                return 2;

            default:
                return 3;
        }
    }

    public static string GetLevelName()
    {
        switch (LevelSelectionData.SelectedLevel)
        {
            case 2:
                return "FIELD OPERATION";

            case 3:
                return "FINAL DEFUSAL";

            default:
                return "TRAINING MISSION";
        }
    }
}