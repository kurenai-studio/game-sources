// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "BasePawn.h"
#include "Turret.generated.h"

/**
 * 
 */
UCLASS()
class TOONTANKS_API ATurret : public ABasePawn
{
	GENERATED_BODY()

protected:
	virtual void BeginPlay() override;

public:
	virtual void Tick(float DeltaTime) override;

public:
	void HandleDestruction();

private:
	void CheckFireCondition();
	bool IsInRange();

private:
	class ATank* Tank;

	FRotator InitialRotator;

	UPROPERTY(EditAnywhere, Category = "Combat")
	float Range = 500.0f;

	FTimerHandle FireRateTimerHandle;

	UPROPERTY(EditAnywhere, Category = "Combat")
	float FireRate = 2.f;
};
