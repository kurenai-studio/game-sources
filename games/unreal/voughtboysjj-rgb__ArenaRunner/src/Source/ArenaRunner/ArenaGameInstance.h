// Copyright (c) 2026 Arena Runner contributors. MIT licensed.

#pragma once

#include "CoreMinimal.h"
#include "Engine/GameInstance.h"
#include "ArenaGameInstance.generated.h"

/**
 * Survives level travel. Keeps a short history of recent runs so a menu or
 * post-game screen can show the last few scores.
 */
UCLASS()
class ARENARUNNER_API UArenaGameInstance : public UGameInstance
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category = "Arena")
	void AddRunScore(int32 Score);

	UFUNCTION(BlueprintCallable, Category = "Arena")
	int32 GetBestRunScore() const;

	UFUNCTION(BlueprintCallable, Category = "Arena")
	TArray<int32> GetRecentScores() const { return RecentScores; }

	/** Total number of runs finished this session. */
	UFUNCTION(BlueprintCallable, Category = "Arena")
	int32 GetRunsPlayed() const { return RunsPlayed; }

private:
	UPROPERTY()
	TArray<int32> RecentScores;

	int32 RunsPlayed = 0;

	static constexpr int32 MaxRecentScores = 5;
};
