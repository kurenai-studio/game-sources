// Copyright (c) 2026 Arena Runner contributors. MIT licensed.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/SaveGame.h"
#include "ArenaSaveGame.generated.h"

/** Tiny save object used to persist the best score between sessions. */
UCLASS()
class ARENARUNNER_API UArenaSaveGame : public USaveGame
{
	GENERATED_BODY()

public:
	UPROPERTY(BlueprintReadOnly, Category = "Save")
	int32 BestScore = 0;
};
