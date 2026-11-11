using System.Collections.Generic;

public interface IDifficultyConfigurable
{
    List<Difficulty> GetAllowedDifficulties();
    void SetAllowedDifficulties(List<Difficulty> difficulties);

    void SetDifficulty(Difficulty difficulty);
}
