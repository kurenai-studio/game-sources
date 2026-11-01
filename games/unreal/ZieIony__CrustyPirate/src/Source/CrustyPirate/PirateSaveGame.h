// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/SaveGame.h"
#include "GameSaveData.h"
#include "PirateSaveGame.generated.h"

/**
 * 
 */
UCLASS()
class CRUSTYPIRATE_API UPirateSaveGame : public USaveGame
{
	GENERATED_BODY()
	
public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FGameSaveData gameSaveData;
};
