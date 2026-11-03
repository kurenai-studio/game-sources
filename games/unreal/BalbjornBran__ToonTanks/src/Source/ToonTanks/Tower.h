// Created by Balbjorn Bran.

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

	// Overriding the Tick function
	virtual void Tick(float DeltaTime) override;

	virtual void HandleDestruction() override; 

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;


private:
	class ATank* Tank_Ref;

	UPROPERTY(EditDefaultsOnly, Category = "Combat")
	float FireRange = 300.f;

	FTimerHandle FireTimerHandle;
	float FireRate = 2.f;
	void checkFireCondition();

	bool InFireRange();
};
