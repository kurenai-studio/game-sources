// Copyright (c) 2026 Arena Runner contributors. MIT licensed.

#include "ArenaGameInstance.h"

void UArenaGameInstance::AddRunScore(int32 Score)
{
	++RunsPlayed;
	RecentScores.Insert(Score, 0);
	if (RecentScores.Num() > MaxRecentScores)
	{
		RecentScores.SetNum(MaxRecentScores);
	}
}

int32 UArenaGameInstance::GetBestRunScore() const
{
	int32 Best = 0;
	for (const int32 Score : RecentScores)
	{
		Best = FMath::Max(Best, Score);
	}
	return Best;
}
