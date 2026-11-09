using UnityEngine;

public static class LevelProgressData
{
    private const string UnlockedLevelKey =
        "HighestUnlockedLevel";

    public static int HighestUnlockedLevel
    {
        get
        {
            return PlayerPrefs.GetInt(
                UnlockedLevelKey,
                1
            );
        }
    }

    public static bool IsLevelUnlocked(
        int levelNumber
    )
    {
        return levelNumber <=
               HighestUnlockedLevel;
    }

    public static void UnlockNextLevel(
        int completedLevel
    )
    {
        int nextLevel =
            completedLevel + 1;

        if (nextLevel > 3)
        {
            return;
        }

        if (nextLevel <=
            HighestUnlockedLevel)
        {
            return;
        }

        PlayerPrefs.SetInt(
            UnlockedLevelKey,
            nextLevel
        );

        PlayerPrefs.Save();
    }
}