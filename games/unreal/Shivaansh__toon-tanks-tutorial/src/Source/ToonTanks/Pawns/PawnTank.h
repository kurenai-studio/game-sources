// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "PawnBase.h"
#include "PawnTank.generated.h"

/**
 * 
 */

class USpringArmComponent;
class UCameraComponent;

UCLASS()
class TOONTANKS_API APawnTank : public APawnBase
{
	GENERATED_BODY()

public:
	APawnTank();
	// Sets default values for this pawn's properties

	// Called every frame
	virtual void Tick(float DeltaTime) override;

	// Called to bind functionality to input
	virtual void SetupPlayerInputComponent(class UInputComponent *PlayerInputComponent) override;

private:

	UPROPERTY(VisibleAnywhere, BluePrintReadOnly, Category = "Components", meta = (AllowPrivateAccess = "true")) 
	UCameraComponent* Camera = nullptr;

	UPROPERTY(VisibleAnywhere, BluePrintReadOnly, Category = "Components", meta = (AllowPrivateAccess = "true")) 
	USpringArmComponent* SpringArm = nullptr;

	UPROPERTY(EditAnywhere, BluePrintReadWrite, Category = "Movement", meta = (AllowPrivateAccess = "true")) 
	float MoveSpeed = 100.0f;

	UPROPERTY(EditAnywhere, BluePrintReadWrite, Category = "Movement", meta = (AllowPrivateAccess = "true")) 
	float RotateSpeed = 100.0f;

	FVector MoveDirection;
	FQuat RotationDirection;

	APlayerController* PlayerControllerRef;

	void CalculateMovement(float value);	
	void CalculateRotation(float value);

	void Move();
	void Rotate();

protected:

	virtual void BeginPlay() override;

	virtual void HandleDestruction() override;

};
