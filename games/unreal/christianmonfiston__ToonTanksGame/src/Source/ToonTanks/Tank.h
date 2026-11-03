// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/CapsuleComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Components/BoxComponent.h"
#include "BasePawn.h"
#include "Components/PrimitiveComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/InputComponent.h"
#include "Math/UnrealMathUtility.h"
#include "Engine/World.h"
#include "Components/SphereComponent.h"
#include "Projectile.h"
#include "GameFramework/PlayerController.h"
#include "Camera/CameraComponent.h"
#include "Blueprint/UserWidget.h"
#include "Sound/SoundBase.h"
#include "Particles/ParticleSystem.h"
#include "GameFramework/SpringArmComponent.h"
#include "Coin.h"
#include "GameFramework/ProjectileMovementComponent.h"
#include "HealthComponent.h"
#include "DrawDebugHelpers.h"
#include "Tank.generated.h"

/**
 * 
 */
UCLASS()
class TOONTANKS_API ATank : public ABasePawn
{
	GENERATED_BODY()

protected: 

	virtual void BeginPlay() override; 

public: 
	virtual void Tick(float DeltaTime) override; 

public: 
	ATank(); 

public: 
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Components")
		class UCapsuleComponent* MainComponent;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Components")
		class UCapsuleComponent* MainCapsule;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Components")
		class UCapsuleComponent* SecondaryCapsule;


	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Components")
		class USceneComponent* ProjectileSpawnPoint;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Components")
		class UStaticMeshComponent* TankMesh; 

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Components")
		class UStaticMeshComponent* TankPrimaryMesh;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Components")
		class UBoxComponent* BoxComp;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		TSubclassOf <AProjectile> ProjectileClass;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		class USceneComponent* ProjectileSpawn;

	UPROPERTY(VisibleAnywhere, Category = Movement)
		class UProjectileMovementComponent* ProjectileMovementComponent;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		class USphereComponent* CollisionComp;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		class USoundBase* ProjectileSound; 

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		class UParticleSystem* ProjectileTrail; 

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		TSubclassOf<ACoin> CoinClass;

public: 

	UFUNCTION()
	void Debug();

	UPROPERTY(EditAnywhere)
	FVector ActorLocation; 

public: 

	virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;

	UFUNCTION(BlueprintCallable)
		void MoveForward(float Value); 

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		float TankTurnRate; 

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		FVector TankLocation = GetActorLocation(); 

	UFUNCTION(BlueprintCallable)
		void RotateTurret(float Axis);


	UFUNCTION(BlueprintCallable)
		void DisplayDeltaSeconds(); 

	

	UFUNCTION(BlueprintCallable)
		void Fire(); 

	UFUNCTION()
		void DrawLine();

	UFUNCTION()
		void ActorDrawLine(); 

	UPROPERTY(EditAnywhere)
		FVector VisualizeActor; 

public: 

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		FVector Start; 

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		FVector End; 

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		FHitResult HitResult; 


	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		AProjectile* ProjectileTesting; 
	
	UPROPERTY()
		class USceneComponent* ProjectilePoint; 

	UPROPERTY(EditAnywhere); 
	AProjectile* Projectile; 

	UFUNCTION()
		void ActorSpawn(); 

public:


	UFUNCTION()
		void OnComponentBeginOverlap(UPrimitiveComponent* OverlappedComp, AActor* OtherActor, UPrimitiveComponent* OtherComp, int32 OtherBodyIndex, bool bFromSweep, const FHitResult& SweepResult);


public:
	
		void RotateAttackTurret(FVector LookAtTarget);

		APlayerController* PlayerControllerRef; 

		UPROPERTY(EditAnywhere, BlueprintReadWrite)
		ACoin* CoinInScene; 

		//Gamepad functions
		void GamepadMoveForward(float AxisValue); 
		void GamepadRotate(float AxisValue); 
		void GamepadShoot(); 
		void GamepadRotateSecondaryMesh(float AxisValue); 



};
