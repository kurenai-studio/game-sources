// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/BoxComponent.h"
#include "Mover.h"




#include "TriggerComponent.generated.h"

/**
 * 
 */
UCLASS(ClassGroup = (Custom), meta = (BlueprintSpawnableComponent))

class DUNGEONESCAPE_API UTriggerComponent : public UBoxComponent
{
	GENERATED_BODY()
	
public:

	UTriggerComponent();

protected:

	virtual void BeginPlay() override;

public:

	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

	UPROPERTY(EditAnywhere)
	bool IsPressurePlate = false;

	UPROPERTY(VisibleAnywhere)
	int32 ActivatorCount = 0;

	UPROPERTY(EditAnywhere)
	AActor* MoverActor;
	UMover* Mover;

	UPROPERTY(VisibleAnywhere)
	bool IsTriggered = false;

	UFUNCTION()
	void OnOverlapBegin(UPrimitiveComponent* OverlappedComp, AActor* OtherActor, UPrimitiveComponent* OtherComp, int32 OtherBodyIndex, bool bFromSweep, const FHitResult& SweepResult);

	UFUNCTION()
	void OnOverlapEnd(UPrimitiveComponent* OverlappedComp, AActor* OtherActor, UPrimitiveComponent* OtherComp, int32 OtherBodyIndex);

	void Trigger(bool NewTrigggerValue);

	//Move the pressure plate
	FVector StartLocation;
	FVector EndLocation;
	FVector FinalLocation;
	UPROPERTY(EditAnywhere)
	FVector MoveOffset = { 0.0f, 0.0f, -5.0f };

	bool ReachedTarget;
};
