// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "Components/CapsuleComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Components/BoxComponent.h"
#include "GameFramework/ProjectileMovementComponent.h"
#include "Components/PrimitiveComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/InputComponent.h"
#include "Particles/ParticleSystem.h"

#include "Sound/SoundBase.h"
#include "Camera/CameraComponent.h"
#include "Kismet/GameplayStatics.h"
#include "Camera/CameraComponent.h"
#include "Components/SphereComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "DrawDebugHelpers.h"
#include "Projectile.generated.h"

UCLASS()
class TOONTANKS_API AProjectile : public AActor
{
	GENERATED_BODY()
	
public:	
	// Sets default values for this actor's properties
	AProjectile();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

public: 
	

	UPROPERTY(EditAnywhere)
		class UStaticMeshComponent* ProjectileMesh; 


	UFUNCTION()
		void Testing(); 

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		AProjectile* Projectile;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		class UBoxComponent* BoxComponent; 



public:  

	UPROPERTY(EditAnywhere)
		class UProjectileMovementComponent* ProjectileMovement; 

	UFUNCTION()
		void ShootProjectile();

	UFUNCTION()
		void OnHit(UPrimitiveComponent* HitComp, AActor* OtherActor, UPrimitiveComponent* OtherComp, FVector NormalImpulse, const FHitResult& Hit);  

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		class UParticleSystem* ProjectileTrailEmitter;

public: 

	UPROPERTY(VisibleAnywhere)
		float Time; 

	

};
