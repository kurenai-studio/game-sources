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

private:
	UPROPERTY(EditAnywhere)
	float _aggroRange = 100.f;

	UPROPERTY(EditAnywhere)
	float _shootInterval = 2.f;

	class ATank* _target = nullptr;

	FTimerHandle _timerHandle;

	void OnShootTimer();

protected:
	virtual void BeginPlay() override;

	bool TargetIsInRange();

	virtual void OnDeath() override;

public:
	virtual void Tick(float DeltaTime) override;
};
