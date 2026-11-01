#pragma once

#include "CoreMinimal.h"

#include "CollectibleSaveData.generated.h"

class ACollectibleItem;

USTRUCT(BlueprintType)
struct FCollectibleSaveData {
	GENERATED_USTRUCT_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FTransform transform;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	TSubclassOf<ACollectibleItem> type;
};
