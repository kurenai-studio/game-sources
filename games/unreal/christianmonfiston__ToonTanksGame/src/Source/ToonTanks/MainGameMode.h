// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "Kismet/GameplayStatics.h"
#include "Coin.h"
#include "Sound/SoundBase.h"
#include "MainGameMode.generated.h"

/**
 * 
 */
UCLASS()
class TOONTANKS_API AMainGameMode  : public AGameModeBase
{
	GENERATED_BODY()

protected: 

	virtual void BeginPlay() override; 

public: 
	virtual void Tick(float DeltaTime);




public: 
	AMainGameMode();

public: 

	void DebugMessage(); 

public: 

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		class USoundBase* BackgroundSound; 

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		class ACoin* Coin; 

	

};
