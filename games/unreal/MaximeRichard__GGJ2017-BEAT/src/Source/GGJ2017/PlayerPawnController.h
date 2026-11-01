// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "PlayerPawn.h"
#include "GameFramework/PlayerController.h"
#include "PlayerPawnController.generated.h"

/**
 * 
 */
UCLASS()
class GGJ2017_API APlayerPawnController : public APlayerController
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category = "Controls")
	void BindControls();

private:

	APlayerPawn* PlayerPawn = nullptr;
	
	
};
