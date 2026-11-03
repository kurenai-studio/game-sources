// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "BasePawn.h"

#include "Tank.generated.h"

/**
 *  Tank Class
 */
UCLASS()
class TOONTANKS_API ATank : public ABasePawn
{
	GENERATED_BODY()

public:
	// Sets default values for this pawn's properties
	ATank();

	// Called to bind functionality to input
	virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;

	void HandleDestruction();

	APlayerController* GetTankPlayerController() const { return TankPlayerController; }

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

private:
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, meta = (AllowPrivateAccess = "true"), Category = "Tank Pawn Toon")
		class USpringArmComponent* SpringArmComp;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, meta = (AllowPrivateAccess = "true"), Category = "Tank Pawn Toon")
		class UCameraComponent* CamComp;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, meta = (AllowPrivateAccess = "true"), Category = "Movement Gameplay")
		float TankSpeed = 500;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, meta = (AllowPrivateAccess = "true"), Category = "Movement Gameplay")
		float TurnRate = 100;

	APlayerController* TankPlayerController;


	void Move(float Value);
	void Turn(float Value);

public: 
	// Called every frame
	virtual void Tick(float DeltaTime) override;
};
