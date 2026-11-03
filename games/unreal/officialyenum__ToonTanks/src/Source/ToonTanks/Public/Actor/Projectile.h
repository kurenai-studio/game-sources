// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "Projectile.generated.h"

class UProjectileMovementComponent;

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

private:
	UPROPERTY(EditDefaultsOnly, Category= "Combat")
	UStaticMeshComponent* ProjectileMesh;
	UPROPERTY(EditDefaultsOnly, Category= "Combat")
	float Damage = 5.0f;
	UPROPERTY(VisibleAnywhere, Category= "Movement", meta=(AllowPrivateAccess = "true"))
	UProjectileMovementComponent* ProjectileMovementComponent;

	UPROPERTY(EditDefaultsOnly, Category= "Combat")
	UParticleSystem* HitParticles;

	UPROPERTY(VisibleAnywhere, Category= "Combat", meta=(AllowPrivateAccess = "true"))
	UParticleSystemComponent* TrailParticleComponent;

	UPROPERTY(EditAnywhere, Category= "Combat", meta=(AllowPrivateAccess = "true"))
	TSubclassOf<class UCameraShakeBase> HitCameraShakeClass;
	
	UFUNCTION()
	void OnHit(UPrimitiveComponent *HitComponent, AActor *OtherActor, UPrimitiveComponent *OtherComp, FVector NormalImpulse, const FHitResult& Hit);
};
