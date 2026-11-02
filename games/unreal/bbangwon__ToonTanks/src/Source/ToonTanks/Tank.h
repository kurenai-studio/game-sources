// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "BasePawn.h"
#include "Tank.generated.h"

/**
 * 
 */
UCLASS()
class TOONTANKS_API ATank : public ABasePawn
{
	GENERATED_BODY()

public:
	ATank();

	// Called to bind functionality to input
	virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;

	// Called every frame
	virtual void Tick(float DeltaTime) override;

	void HandleDestruction();

	APlayerController* GetTankPlayerController() const { return TankPlayerController; }

	bool bAlive = true;

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;


private:
	UPROPERTY(VisibleAnywhere, Category="Components")
	class USpringArmComponent* SpringArm;

	UPROPERTY(VisibleAnywhere, Category = "Components")
	class UCameraComponent* Camera;

	UPROPERTY(VisibleAnywhere, Category = Input)
	class UInputMappingContext* DefaultContext;

	UPROPERTY(VisibleAnywhere, Category = Input)
	class UInputAction* MoveForwardAction;

	UPROPERTY(VisibleAnywhere, Category = Input)
	class UInputAction* TurnAction;

	UPROPERTY(VisibleAnywhere, Category = Input)
	class UInputAction* RotateTurretAction;

	UPROPERTY(VisibleAnywhere, Category = Input)
	class UInputAction* FireAction;

	UPROPERTY(EditAnywhere, Category = Movement)
	float Speed = 200.f;

	UPROPERTY(EditAnywhere, Category = Movement)
	float TurnRate = 45.f;

	void Move_Enhanced(const struct FInputActionValue& Value);
	void Move(float Value);

	void Turn_Enhanced(const struct FInputActionValue& Value);
	void Turn(float Value);

	void Fire_Enhanced(const struct FInputActionValue& Value);

	APlayerController* TankPlayerController;
};
