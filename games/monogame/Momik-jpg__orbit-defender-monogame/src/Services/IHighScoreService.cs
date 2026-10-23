using OrbitDefender.Models;

namespace OrbitDefender.Services;

public interface IHighScoreService
{
    IReadOnlyList<HighScoreEntry> Load();
    bool Record(string playerName, int score, int level);
}
