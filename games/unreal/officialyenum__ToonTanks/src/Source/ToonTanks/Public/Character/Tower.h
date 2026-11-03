// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "BasePawn.h"
#include "Tower.generated.h"

class ATank;

UCLASS()
class TOONTANKS_API ATower : public ABasePawn
{
	GENERATED_BODY()

public:
	// Sets default values for this pawn's properties
	ATower();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:
	// Called every frame
	virtual void Tick(float DeltaTime) override;

	// Called to bind functionality to input
	virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;
	virtual void HandleDestruction() override;
private:
	UPROPERTY(EditAnywhere, Category="Tower Params");
	float FireRange = 100.f;
	
	ATank* Tank;

	FTimerHandle FireRateTimerHandle;
	float FireRate = 1.5f;
	float MaxFireRate = 3.f;
	void CheckFireCondition();

	bool InFireRange() const;
};
