// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "Health.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FHealthOnDeathEvent);

UCLASS(ClassGroup = (Custom), meta = (BlueprintSpawnableComponent))
class TOONTANKS_API UHealth : public UActorComponent
{
	GENERATED_BODY()

private:
	UPROPERTY(EditAnywhere)
	float _maxHealth = 100.f;

	float _currentHealth = 0.f;

public:

	UPROPERTY()
	FHealthOnDeathEvent onDeathEvent;
	// Sets default values for this component's properties
	UHealth();

	bool IsDead() const;

protected:
	// Called when the game starts
	virtual void BeginPlay() override;

public:
	// Called every frame
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

private:
	UFUNCTION()
	void DamageTaken(AActor* damagedActor, float damage, const UDamageType* type, AController* instigator, AActor* causer);
};
