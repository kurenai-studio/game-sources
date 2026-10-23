namespace OrbitDefender.Core;

public sealed class GameSession
{
    public int Score { get; private set; }
    public int Lives { get; private set; }
    public int Level { get; private set; }
    public double SurvivalSeconds { get; private set; }

    public float SpawnIntervalSeconds =>
        MathF.Max(GameSettings.MinimumSpawnSeconds, GameSettings.AsteroidSpawnBaseSeconds - ((Level - 1) * 0.08f));

    public float AsteroidSpeedMultiplier => 1f + ((Level - 1) * 0.13f);

    public bool IsGameOver => Lives <= 0;

    public void Reset()
    {
        Score = 0;
        Lives = GameSettings.PlayerStartLives;
        Level = 1;
        SurvivalSeconds = 0;
    }

    public void AddScore(int points)
    {
        if (points <= 0)
        {
            return;
        }

        Score += points;
        Level = Math.Max(1, (Score / GameSettings.LevelScoreStep) + 1);
    }

    public void RemoveLife()
    {
        Lives = Math.Max(0, Lives - 1);
    }

    public void AddSurvivalTime(double deltaSeconds)
    {
        if (deltaSeconds <= 0)
        {
            return;
        }

        SurvivalSeconds += deltaSeconds;
    }
}
