// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "ToonTanksPlayerController.generated.h"

struct FInputActionValue;
class UInputMappingContext;
class UInputAction;
class ATank;

UCLASS()
class TOONTANKS_API AToonTanksPlayerController : public APlayerController
{
public:
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Player Input|Contex")
	TObjectPtr<UInputMappingContext> InputMappingContext;
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Player Input|Combat")
	TObjectPtr<UInputAction> ActionFire;
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Player Input|Move")
	TObjectPtr<UInputAction> ActionMoveForward;
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Player Input|Move")
	TObjectPtr<UInputAction> ActionMoveRotate;

	void SetPlayerEnabledState(bool bPlayerEnabled);

protected:
	virtual void OnPossess(APawn* aPawn) override;
	virtual void OnUnPossess() override;

private:
	GENERATED_BODY()
	void HandleFire();
	void HandleMove(const FInputActionValue& InputAction);

	UPROPERTY()
	TObjectPtr<UEnhancedInputComponent> EnhancedInputComponent = nullptr;
	UPROPERTY()
	TObjectPtr<ATank> Tank = nullptr;
};
