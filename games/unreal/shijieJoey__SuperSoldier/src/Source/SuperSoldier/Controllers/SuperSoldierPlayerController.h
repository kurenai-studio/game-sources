// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "SuperSoldierPlayerController.generated.h"

/**
 * 
 */
UCLASS()
class SUPERSOLDIER_API ASuperSoldierPlayerController : public APlayerController
{
	GENERATED_BODY()

protected:
	virtual void BeginPlay() override;
	UFUNCTION(BlueprintImplementableEvent)
	void HandleEndGameScreen(bool bPlayerWin);
	UFUNCTION(BlueprintPure)
	float GetRestartDelay() const;
	UFUNCTION(BlueprintCallable)
	void RestartCurrentLevel();

public:
	virtual void GameHasEnded(class AActor* EndGameFocus = nullptr, bool bIsWinner = false) override;

private:
	UPROPERTY(EditAnywhere)
	TSubclassOf<class UUserWidget> HUDClass;
	UPROPERTY(EditAnywhere)
	TSubclassOf<class UUserWidget> EndGameScreenClass;
	UPROPERTY()
	UUserWidget* HUD;

	UPROPERTY(EditAnywhere)
	float RestartDelay = 5.f;

};
