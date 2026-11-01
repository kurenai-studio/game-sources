// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "BasePawn.h"
#include "Tank.generated.h"

UCLASS()
class TOONTANKS_API ATank : public ABasePawn
{
	GENERATED_BODY()

private:
	UPROPERTY(EditAnywhere)
	TSubclassOf<class UCameraShakeBase> _deathCameraShake = nullptr;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Tank Configuration", meta = (AllowPrivateAccess = "true"))
	class USpringArmComponent* _spring = nullptr;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Tank Configuration", meta = (AllowPrivateAccess = "true"))
	class UCameraComponent* _camera = nullptr;

	UPROPERTY(EditAnywhere, Category = "Tank Configuration")
	FName _moveForwardAxis;

	UPROPERTY(EditAnywhere, Category = "Tank Configuration")
	FName _turnAxis;

	UPROPERTY(EditAnywhere, Category = "Tank Configuration")
	FName _fireAction;

	UPROPERTY(EditAnywhere, Category = "Tank Configuration")
	float _turnRate = 100.f;

	FVector _movementDirection = FVector::ZeroVector;

	APlayerController* _controller = nullptr;

	FHitResult _hitResult;

public:
	// Sets default values for this pawn's properties
	ATank();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

	virtual void OnDeath() override;

private:
	void Move(float value);

	void Turn(float value);

public:
	// Called every frame
	virtual void Tick(float DeltaTime) override;

	// Called to bind functionality to input
	virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;
};
