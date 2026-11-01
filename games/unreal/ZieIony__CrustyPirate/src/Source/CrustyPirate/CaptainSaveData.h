#pragma once

#include "CoreMinimal.h"

#include "CaptainSaveData.generated.h"

USTRUCT(BlueprintType)
struct FCaptainSaveData {
	GENERATED_USTRUCT_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FTransform transform;
};
