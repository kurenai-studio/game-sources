// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"

#include "FUCreditsDataStruct.generated.h"

/**
 *
 */
USTRUCT(BlueprintType)
struct CRUSTYPIRATE_API FUCreditsDataStruct: public FTableRowBase {
    GENERATED_USTRUCT_BODY()

public:
    UPROPERTY(EditAnywhere, BlueprintReadOnly)
    FString Label;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FString Value;
};
