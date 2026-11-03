// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "TankGameModeBase.generated.h"

class APawnTurret;
class APawnTank;
class APlayerControllerBase;

/**
 * 
 */
UCLASS()
class TOONTANKS_API ATankGameModeBase : public AGameModeBase
{
	GENERATED_BODY()

public:
	ATankGameModeBase();
	
	void ActorDied(AActor* DeadActor);

protected:
	virtual void BeginPlay() override;

	UFUNCTION(BluePrintImplementableEvent)
	void GameStart();

	UFUNCTION(BluePrintImplementableEvent)
	void GameOver(bool bPlayerWon);

private:
	APawnTank* PlayerTank;
	int32 TargetTurrets = 0;
	APlayerControllerBase* PlayerControllerRef = nullptr;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Game Loop", meta = (AllowPrivateAccess = true))
	int32 StartDelay = 3;
	
	void HandleGameStart();
	void HandleGameOver(bool bPlayerWon);
	int32 GetTargetTurretCount();
};
