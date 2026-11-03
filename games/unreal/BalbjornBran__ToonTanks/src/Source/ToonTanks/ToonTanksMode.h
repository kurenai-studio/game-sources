// Created by Balbjorn Bran.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "ToonTanksMode.generated.h"

/**
 * 
 */
UCLASS()
class TOONTANKS_API AToonTanksMode : public AGameModeBase
{
	GENERATED_BODY()

public:
	void ActorDied(AActor* DeadActor);

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "GameMode")
	float StartDelay = 2.f;
	
protected:
	virtual void BeginPlay() override;

	
	UFUNCTION(BlueprintImplementableEvent)
	void StartGame();

	UFUNCTION(BlueprintImplementableEvent)
	void GameOver(bool bWonGame);
	
	
private:
	class ATank* PlayerTank;
	class ATankController* PlayerTankController;
	void HandleGameStart();
	int32 NumTowersAlive = 0;

	int32 GetTowersAlive();
};
