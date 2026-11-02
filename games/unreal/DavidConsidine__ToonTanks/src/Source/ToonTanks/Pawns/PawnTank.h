// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "PawnBase.h"
#include "PawnTank.generated.h"

class USpringArmComponent;
class UCameraComponent;

UCLASS()
class TOONTANKS_API APawnTank : public APawnBase
{
	GENERATED_BODY()
	
public:
	APawnTank();
	
	// Called every frame
    virtual void Tick(float DeltaTime) override;
	// Called to bind functionality to input
	virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;

	bool GetPlayerAlive();

protected:	
    // Called when the game starts or when spawned
    virtual void BeginPlay() override;

	virtual void HandleDestruction() override;

private:
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Components", meta = (AllowPrivateAccess = "true"))
    USpringArmComponent* SpringArm;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Components", meta = (AllowPrivateAccess = "true"))
    UCameraComponent* Camera;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Movement", meta = (AllowPrivateAccess = "true"))
	float MoveSpeed = 100.0f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Movement", meta = (AllowPrivateAccess = "true"))
	float RotateSpeed = 100.0f;

	FVector MoveDirection;
	FQuat RotationDirection;

	APlayerController* PlayerControllerRef;
	FHitResult TraceHitResult;

	bool bAlive = true;

	UFUNCTION()
    void CalculateMoveInput(float Value);
	UFUNCTION()
    void CalculateRotateInput(float Value);
	UFUNCTION()
    void Move();
	UFUNCTION()
    void Rotate();
};
