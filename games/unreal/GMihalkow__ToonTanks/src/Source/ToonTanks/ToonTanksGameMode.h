// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "ToonTanksGameMode.generated.h"

/**
 *
 */
UCLASS()
class TOONTANKS_API AToonTanksGameMode : public AGameModeBase
{
	GENERATED_BODY()

private:
	UPROPERTY(EditDefaultsOnly)
	float _startGameDelay = 3.f;

	int _defeatedTowersCount = 0;

	class ATank* _tank = nullptr;

	UPROPERTY(EditAnywhere)
	TSubclassOf<class ATower> _towerBlueprint;
	
	class AToonTanksPlayerController* _playerController = nullptr;

	bool _playerDied = false;

	int _targetTowersCount = 0;

	void OnGameStart();

protected:
	virtual void BeginPlay() override;

	int GetAllTowersCount() const;

public:
	void OnActorDied(const AActor* actor);

	bool PlayerDied() const;

	UFUNCTION(BlueprintImplementableEvent)
	void StartGame();

	UFUNCTION(BlueprintImplementableEvent)
	void GameOver(bool hasWon);
};
