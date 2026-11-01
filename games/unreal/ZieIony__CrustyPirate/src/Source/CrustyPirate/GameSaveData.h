#pragma once

#include "CoreMinimal.h"
#include "CaptainSaveData.h"
#include "EnemySaveData.h"
#include "CollectibleSaveData.h"

#include "GameSaveData.generated.h"

USTRUCT(BlueprintType)
struct FGameSaveData {
	GENERATED_USTRUCT_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FCaptainSaveData captainData;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	TArray<FEnemySaveData> enemyData;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	TArray<FCollectibleSaveData> collectibleData;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	int PlayerHP = 100;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	int CoinsCollected = 0;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	int DiamondsCollected = 0;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	bool IsDoubleJumpUnlocked = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	int CurrentLevelIndex = 0;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	int MapsCollected = 0;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	int KeysOwned = 0;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	int SwordsOwned = 0;
};
