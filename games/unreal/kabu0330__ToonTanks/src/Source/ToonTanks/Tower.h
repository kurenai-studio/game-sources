// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "BasePawn.h"
#include "Tower.generated.h"

/**
 * 
 */
UCLASS()
class TOONTANKS_API ATower : public ABasePawn
{
	GENERATED_BODY()
	
public:
	ATower();
	~ATower();

	virtual void HandleDestruction() override;

protected:
	virtual void BeginPlay() override;
	virtual void Tick(float DeltaTime) override;

private:
	class ATank* Tank;

	UPROPERTY(EditDefaultsOnly, Category = "Combat", meta = (AllowPrivateAccess = "true"))
	float FireRange = 500.0f;

	FTimerHandle FireRateTimerHandle;
	float FireRate = 2.0f;
	void CheckFireCondition();

	bool InFireRange();
};
