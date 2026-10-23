namespace OrbitDefender.Core;

public static class GameSettings
{
    public const int WindowWidth = 1280;
    public const int WindowHeight = 720;
    public const int StarCount = 90;

    public const float PlayerSpeed = 430f;
    public const float PlayerWidth = 56f;
    public const float PlayerHeight = 34f;
    public const int PlayerStartLives = 3;

    public const float ShotSpeed = 650f;
    public const float ShotCooldownSeconds = 0.22f;

    public const float BaseAsteroidSpeed = 125f;
    public const float AsteroidSpawnBaseSeconds = 1.1f;
    public const float MinimumSpawnSeconds = 0.32f;
    public const int LevelScoreStep = 350;

    public const int MaxHighScores = 10;
    public const string DefaultPilotName = "Andrin";
}
