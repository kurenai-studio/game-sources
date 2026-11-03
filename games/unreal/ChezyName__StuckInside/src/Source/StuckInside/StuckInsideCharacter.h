// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "Interactable.h"
#include "Components/SpotLightComponent.h"
#include "GameFramework/Character.h"
#include "StuckInsideCharacter.generated.h"

class UInputComponent;
class USkeletalMeshComponent;
class USceneComponent;
class UCameraComponent;
class UMotionControllerComponent;
class UAnimMontage;
class USoundBase;

UCLASS(config=Game)
class AStuckInsideCharacter : public ACharacter
{
	GENERATED_BODY()

	/** Pawn mesh: 1st person view (arms; seen only by self) */
	UPROPERTY(VisibleDefaultsOnly, Category=Mesh)
	USkeletalMeshComponent* GlobalMesh;

	/** First person camera */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = Camera, meta = (AllowPrivateAccess = "true"))
	UCameraComponent* FirstPersonCameraComponent;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = Camera, meta = (AllowPrivateAccess = "true"))
	USpotLightComponent* Flashlight;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Child, meta = (AllowPrivateAccess = "true"))
	float InteractionRange = 150;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Child, meta = (AllowPrivateAccess = "true"))
	float WalkSpeed = 350;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Child, meta = (AllowPrivateAccess = "true"))
	float SprintSpeed = 600;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Child, meta = (AllowPrivateAccess = "true"))
	float SprintChargeReduction = 2.5;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Child, meta = (AllowPrivateAccess = "true"))
	float SprintRecharge = 0.75;

public:
	AStuckInsideCharacter();

	UPROPERTY(BlueprintReadOnly)
	FString InteractableText = "";
	UPROPERTY(BlueprintReadOnly)
	AInteractable* Interactable = nullptr;

protected:
	virtual void BeginPlay();

public:
	/** Base turn rate, in deg/sec. Other scaling may affect final turn rate. */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category=Camera)
	float BaseTurnRate;

	/** Base look up/down rate, in deg/sec. Other scaling may affect final rate. */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category=Camera)
	float BaseLookUpRate;

protected:

	/** Handles moving forward/backward */
	void MoveForward(float Val);

	/** Handles stafing movement, left and right */
	void MoveRight(float Val);

	UFUNCTION(Server,Reliable)
	void startSprint();

	UFUNCTION(Server,Reliable)
	void endSprint();

	bool Sprinting = false;
	bool canSprint = true;

	UPROPERTY(Replicated)
	float SprintCharge = 100;

	void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;
	
	/**
	 * Called via input to turn at a given rate.
	 * @param Rate	This is a normalized rate, i.e. 1.0 means 100% of desired turn rate
	 */
	void TurnAtRate(float Rate);

	/**
	 * Called via input to turn look up/down at a given rate.
	 * @param Rate	This is a normalized rate, i.e. 1.0 means 100% of desired turn rate
	 */
	void LookUpAtRate(float Rate);

	UFUNCTION(Server,Reliable)
	void Interact();

	UFUNCTION(Server,Reliable)
	void ToggleFlashlight();

	UFUNCTION(NetMulticast,Reliable)
	void onFlashlightToggle();
	
protected:
	// APawn interface
	virtual void SetupPlayerInputComponent(UInputComponent* InputComponent) override;
	// End of APawn interface

	/* 
	 * Configures input for touchscreen devices if there is a valid touch interface for doing so 
	 *
	 * @param	InputComponent	The input component pointer to bind controls to
	 * @returns true if touch controls were enabled.
	 */

	virtual void Tick(float DeltaSeconds) override;

public:
	/** Returns Mesh1P subobject **/
	USkeletalMeshComponent* GetMesh() const { return GlobalMesh; }
	/** Returns FirstPersonCameraComponent subobject **/
	UCameraComponent* GetFirstPersonCameraComponent() const { return FirstPersonCameraComponent; }

	UFUNCTION(BlueprintImplementableEvent)
	void onFlashlightToggleBP();

	UFUNCTION(BlueprintCallable)
	float getSprint(){ return SprintCharge; }
};

