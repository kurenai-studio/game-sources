// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "ToonTankGameMode.generated.h"

class AToonTankPlayerController;
class ATank;
/**
 * 
 */
UCLASS()
class TOONTANKS_API AToonTankGameMode : public AGameModeBase
{
	GENERATED_BODY()
	
public:	
	void ActorDied(AActor* DeadActor);
protected:
	virtual void BeginPlay() override;

	UFUNCTION(BlueprintImplementableEvent)
	void StartGame();
	
	UFUNCTION(BlueprintImplementableEvent)
	void GameOver(bool bWonGame);
private:
	ATank* Tank;
	AToonTankPlayerController* ToonTankPlayerController;

	float StartDelay = 3.f;

	void HandleGameStart();

	int32 TargetTowers = 0;
	int32 GetTargetTowerCount() const;
};
