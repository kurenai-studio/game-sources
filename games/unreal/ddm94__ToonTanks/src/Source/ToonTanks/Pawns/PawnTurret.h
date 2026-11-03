// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "PawnBase.h"
#include "PawnTurret.generated.h"

/**
 * Access Modifier
 * 
 * Private: most secure - nothing outside of the class can access a property marked as private
 * Public: least secure - allows any class with a valid reference to the second class then access these properties which were declared inside
 * Protected: unique - properties that need to be hidden from outside classes but need to be available in derived child classes
 */

class APawnTank;

UCLASS()
class TOONTANKS_API APawnTurret : public APawnBase
{
	GENERATED_BODY()

public:
	// Called every frame
	virtual void Tick(float DeltaTime) override;

	virtual void HandleDestruction() override;

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

private:

	// Allows to bind and unbind our timer which will be either looping or called at certain intervals
	FTimerHandle FireRateTimerHandle;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Combat", meta = (AllowPrivateAccess = "true"))
	float FireRate = 2.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Combat", meta = (AllowPrivateAccess = "true"))
	float FireRange = 500.f;

	APawnTank* PlayerPawn;

	void CheckFireCondition();

	float ReturnDistanceToPlayer();
};
