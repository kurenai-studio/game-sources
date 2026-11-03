// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "BreakerDoor.h"
#include "Demon.h"
#include "StuckInsideCharacter.h"
#include "Switch.h"
#include "WindowShutters.h"
#include "StuckInside/StuckInsideGS.h"
#include "GameFramework/GameModeBase.h"
#include "StuckInsideGameMode.generated.h"

UCLASS(minimalapi)
class AStuckInsideGameMode : public AGameModeBase
{
	GENERATED_BODY()

protected:
	float Breaker = 1.f;

	UPROPERTY(BlueprintReadOnly)
	bool GameStarted = false;

	void ResetGame();

	UFUNCTION(BlueprintImplementableEvent)
	void EventResetGame(const TArray<APlayerController*>& PlayerControllers);

public:
	AStuckInsideGameMode();
	UPROPERTY(EditAnywhere)
	TSubclassOf<APawn> LobbyClass;
	UPROPERTY(EditAnywhere)
	TSubclassOf<AStuckInsideCharacter> Survivors;
	UPROPERTY(EditAnywhere)
	TSubclassOf<ADemon> Demon;

	UPROPERTY(EditAnywhere)
	float MaxPowerUsageTimeBeforeBreaker = 1.5f;

	UFUNCTION(Server,Reliable,BlueprintCallable)
	void onAllPlayersReady();

	virtual void HandleStartingNewPlayer_Implementation(APlayerController* NewPlayer) override;

	UPROPERTY()
	AStuckInsideGS* SIGameState;
	
	UPROPERTY()
	TArray<AWindowShutters*> Windows;
	
	UPROPERTY()
	TArray<ASwitch*> BreakerSwitches;
	
	UPROPERTY()
	ABreakerDoor* BreakerDoor;

	void BeginPlay() override;
	
	void KillPlayer(AStuckInsideCharacter* Character);

	void Tick(float DeltaSeconds) override;
};



