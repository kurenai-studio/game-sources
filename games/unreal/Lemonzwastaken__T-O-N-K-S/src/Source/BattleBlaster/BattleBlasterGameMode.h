// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"

#include "Tank.h"
#include "ScreenMessage.h"

#include "BattleBlasterGameMode.generated.h"

class USoundBase;

/**
 *
 */
UCLASS()
class BATTLEBLASTER_API ABattleBlasterGameMode : public AGameModeBase
{
	GENERATED_BODY()

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;
	virtual void Tick(float DeltaTime) override;


public:

	ABattleBlasterGameMode();

	UPROPERTY(EditAnywhere)
	float CameraBlendTime = 1.5f;

	AActor* IntroCameraTarget;

	bool bGameStarted = false;

	void StartGame();


	UPROPERTY(EditAnywhere)
	TSubclassOf<UScreenMessage> ScreenMessageClass;

	UScreenMessage* ScreenMessageWidget;

	UPROPERTY(EditAnywhere)
	float GameOverDelay = 3.0f;

	ATank* Tank;
	int32 TowerCount;

	UPROPERTY(EditAnywhere)
	int32 CountdownDelay = 3;

	int32 CountdownSeconds;

	FTimerHandle CountdownTimerHandle;

	void ActorDied(AActor* DeadActor);

	void OnGameOverTimerTimeout();
	void OnCountDownTimerTimeout();

	int32 ComboCount = 0;

	FTimerHandle ComboTimerHandle;

	void AddCombo();
	void ResetCombo();
	void UpdateComboMessage();

	bool IsVictory = false;

	UPROPERTY(EditAnywhere, Category = "UI")
	TSubclassOf<class UStartScreen> StartScreenClass;

	class UStartScreen* StartScreenWidget;

	UFUNCTION()
	void OnStartScreenFadedOut();

	FTimerHandle PostFadeTimerHandle;

	void ShowGetReadyMessage();

	bool bWaitingForFinalRestart = false;

	UPROPERTY(EditAnywhere, Category = "Combo")
	float ComboResetTime = 4.0f;

	UPROPERTY(EditDefaultsOnly, Category = "Pickup")
	TSubclassOf<class AHealthPickup> HealthPickupClass;

	UPROPERTY(EditDefaultsOnly, Category = "Pickup")
	float HealthPickupDropChance = 0.5f;


	//SOUNDS

	UPROPERTY(EditDefaultsOnly, Category = "Sound")
	USoundBase* GameStartSound;

	UPROPERTY(EditDefaultsOnly, Category = "Sound")
	USoundBase* CountDownTickSound;

	UPROPERTY(EditDefaultsOnly, Category = "Sound")
	USoundBase* GoSound;


	UPROPERTY(EditDefaultsOnly, Category = "Sound")
	USoundBase* VictorySound;

	UPROPERTY(EditDefaultsOnly, Category = "Sound")
	USoundBase* DefeatSound;


};

