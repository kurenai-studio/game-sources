// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Interactable.h"
#include "PhysicsEngine/PhysicsConstraintComponent.h"
#include "Door.generated.h"

/**
 * 
 */
UCLASS()
class STUCKINSIDE_API ADoor : public AInteractable
{
	GENERATED_BODY()
		
	UPROPERTY(EditDefaultsOnly,meta=(AllowPrivateAccess))
	UStaticMeshComponent* Door;

	UPROPERTY(EditDefaultsOnly,meta=(AllowPrivateAccess))
	UPhysicsConstraintComponent* Hinge;

	UPROPERTY(EditDefaultsOnly,meta=(AllowPrivateAccess))
	float MaxRotation = 90;

	UPROPERTY(EditDefaultsOnly,meta=(AllowPrivateAccess))
	float DoorSpeed = 250;
	
	bool isOpen = false;

	FRotator toRot = FRotator(0,0,0);
	
	virtual void Interact(ACharacter* Character) override;
	virtual void BeginPlay() override;
	virtual void Tick(float DeltaSeconds) override;
public:
	ADoor();

	UStaticMeshComponent* GetDoor(){ return Door; }
};
