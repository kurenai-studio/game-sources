// Copyright (c) 2026 Arena Runner contributors. MIT licensed.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameStateBase.h"
#include "ArenaGameState.generated.h"

/** Replicated state that the HUD reads from. */
UCLASS()
class ARENARUNNER_API AArenaGameState : public AGameStateBase
{
	GENERATED_BODY()

public:
	UPROPERTY(BlueprintReadOnly, Category = "Arena")
	int32 Score = 0;

	UPROPERTY(BlueprintReadOnly, Category = "Arena")
	int32 BestScore = 0;

	UPROPERTY(BlueprintReadOnly, Category = "Arena")
	int32 Wave = 1;

	/** Cores collected in the current wave. */
	UPROPERTY(BlueprintReadOnly, Category = "Arena")
	int32 Collected = 0;

	/** Total cores spawned for the current wave. */
	UPROPERTY(BlueprintReadOnly, Category = "Arena")
	int32 TotalCollectibles = 0;
};
