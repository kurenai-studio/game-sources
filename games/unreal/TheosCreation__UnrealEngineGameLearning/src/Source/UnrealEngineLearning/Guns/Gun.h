// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "Gun.generated.h"

UCLASS()
class UNREALENGINELEARNING_API AGun : public AActor
{
	GENERATED_BODY()
	
public:	
	// Sets default values for this actor's properties
	AGun();

	void BeginFiring();
	void EndFiring();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

private:
	void Fire();

	UPROPERTY(VisibleAnywhere)
	USkeletalMeshComponent* GunMesh;

	UPROPERTY(EditDefaultsOnly)
	UParticleSystem* MuzzleFlash;

	UPROPERTY(EditDefaultsOnly)
	USoundBase* FireSound;

	UPROPERTY(EditDefaultsOnly)
	float Damage = 10.f;

	UPROPERTY(EditDefaultsOnly)
	float RateOfFire = 10.f;

	UPROPERTY(VisibleAnywhere)
	bool IsFiring = false;

	float LastFireTime = -1000.f;

	UPROPERTY(EditDefaultsOnly, Category = "Projectile")
	TSubclassOf<class AProjectile> ProjectileClass;
};
