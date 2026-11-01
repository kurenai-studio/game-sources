// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "AIController.h"
#include "SuperSoldierAIController.generated.h"

/**
 * 
 */
UCLASS()
class SUPERSOLDIER_API ASuperSoldierAIController : public AAIController
{
	GENERATED_BODY()
	
protected:

	virtual void BeginPlay() override;

public:

	bool IsDead() const;

private:

	UPROPERTY(EditAnywhere)
	UBehaviorTree* AIBehavior;

};
