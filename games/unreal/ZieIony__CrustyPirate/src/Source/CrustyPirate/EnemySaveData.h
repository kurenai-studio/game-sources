#pragma once

#include "CoreMinimal.h"

#include "EnemySaveData.generated.h"

class AEnemy;

USTRUCT(BlueprintType)
struct FEnemySaveData {
	GENERATED_USTRUCT_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	int32 health;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FTransform transform;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	TSubclassOf<AEnemy> type;
};
