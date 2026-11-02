// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "AIController.h"

#include "EnemyAIController.generated.h"

UCLASS()
class BATTLEBLASTER_API AEnemyAIController : public AAIController
{
	GENERATED_BODY()

public:
	AEnemyAIController();

	UPROPERTY(EditAnywhere)
	float RepathInterval = 1.0f;

	UPROPERTY(EditAnywhere)
	float AcceptanceRadius = 800.0f;

	UPROPERTY(EditAnywhere, Category = "Randomization")
	float SurroundRadius = 500.0f;

	UPROPERTY(EditAnywhere, Category = "Randomization")
	float RepathIntervalVariance = 0.25f;

	void RequestImmediateRepath();

protected:
	virtual void BeginPlay() override;

private:
	void ChasePlayer();

	FVector SurroundOffset;
	FTimerHandle RepathTimerHandle;
};