// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "BasePawn.h"
#include "Tank.generated.h"

class USpringArmComponent;
class UCameraComponent;

UCLASS()
class TOONTANKS_API ATank : public ABasePawn
{
	GENERATED_BODY()

public:
	// Sets default values for this pawn's properties
	ATank();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:
	// Called every frame
	virtual void Tick(float DeltaTime) override;

	// Called to bind functionality to input
	virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;
	virtual void HandleDestruction() override;
	APlayerController* GetTankPlayerController() const { return TankPlayerController; }

	bool bAlive = true;
private:
	UPROPERTY(VisibleAnywhere, Category= "Pawn Components")
	UCameraComponent* Camera;
	UPROPERTY(VisibleAnywhere, Category= "Pawn Components")
	USpringArmComponent* SpringArm;

	UPROPERTY(EditAnywhere, Category="Tank Movement")
	float TankSpeed = 200.f;
	UPROPERTY(EditAnywhere, Category="Tank Movement")
	float TurnSpeed = 45.f;
	UPROPERTY(EditAnywhere, Category="Tank Movement")
	float TurretTurnSpeed = 45.f;

	void Move(float Value);
	void Turn(float Value);

	APlayerController* TankPlayerController;
};
