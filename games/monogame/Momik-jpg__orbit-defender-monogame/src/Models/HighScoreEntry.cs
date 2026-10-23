namespace OrbitDefender.Models;

public sealed class HighScoreEntry
{
    public string PlayerName { get; init; } = string.Empty;
    public int Score { get; init; }
    public int Level { get; init; }
    public DateTime CreatedAtUtc { get; init; }
}
