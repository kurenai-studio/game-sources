// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "BasePawn.h"
#include "InputActionValue.h"
#include "ToonTanksPlayerController.h"
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

	// Called every frame
	virtual void Tick(float DeltaTime) override;

	void HandleDestruction();
	
	// Called to bind functionality to input
	virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;

	AToonTanksPlayerController* GetTankPlayerController() const;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Enhanced Input");
	class UInputMappingContext* MappingContext;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Enhanced Input");
	class UInputAction* MoveAction;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Enhanced Input");
	class UInputAction* TurnAction;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Enhanced Input");
	class UInputAction* FireAction;

	UPROPERTY(EditAnywhere, Category = "Movement", BlueprintReadWrite)
	float Speed = 500;

	UPROPERTY(EditAnywhere, Category = "Movement", BlueprintReadWrite)
	float TurnRate = 150;

	bool bAlive = true;

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

private:
	UPROPERTY(VisibleAnywhere, Category = "Components")
	class USpringArmComponent* SpringArm;

	UPROPERTY(VisibleAnywhere, Category = "Components")
	class UCameraComponent* Camera;

	void Move(const FInputActionValue& Value);
	void Turn(const FInputActionValue& Value);
	void Fire(const FInputActionValue& Value);

	AToonTanksPlayerController* TankPlayerController;
};
