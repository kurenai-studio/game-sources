// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "TankGameModeBase.generated.h"

class APawnTurret;
class APawnTank;
class APlayerControllerBase;

UCLASS()
class TOONTANKS_API ATankGameModeBase : public AGameModeBase
{
	GENERATED_BODY()
protected:
    virtual void BeginPlay() override;
    
public:
    void ActorDied(AActor* DeadActor);
    UFUNCTION(BlueprintImplementableEvent)
    void GameStart();
    UFUNCTION(BlueprintImplementableEvent)
    void GameOver(bool PlayerWon);
    
private:
    int32 TargetTurrets = 0;

    APlayerControllerBase* PlayerControllerRef;
    
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Game Loop", meta = (AllowPrivateAccess = "true"))
    int StartDelay = 3;
    
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Player", meta = (AllowPrivateAccess = "true"))
    APawnTank* PlayerTank;

    int32 GetTargetTurretCount();
    void HandleGameStart();
    void HandleGameOver(bool PlayerWon);
};
