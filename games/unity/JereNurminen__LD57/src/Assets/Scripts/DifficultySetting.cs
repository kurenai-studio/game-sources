using UnityEngine;

public enum Difficulty
{
    Easy,
    Medium,
    Hard
}

[System.Serializable]
public class DifficultySettings<T>
{
    public T easy;
    public T medium;
    public T hard;

    private Difficulty difficulty;

    public void SetDifficulty(Difficulty difficulty)
    {
        this.difficulty = difficulty;
    }

    public T GetValue()
    {
        switch (difficulty)
        {
            case Difficulty.Easy:
                return easy;
            case Difficulty.Medium:
                return medium;
            case Difficulty.Hard:
                return hard;
            default:
                Debug.LogWarning("Unknown difficulty level. Defaulting to Medium.");
                return medium;
        }
    }

    // Implicit conversion operator to return the value for the current difficulty
    public static implicit operator T(DifficultySettings<T> settings)
    {
        return settings.GetValue();
    }
}
