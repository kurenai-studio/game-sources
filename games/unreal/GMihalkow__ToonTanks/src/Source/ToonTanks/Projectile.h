// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "Projectile.generated.h"

class USoundBase;

UCLASS()
class TOONTANKS_API AProjectile : public AActor
{
	GENERATED_BODY()

private:
	UPROPERTY(EditAnywhere)
	TSubclassOf<class UCameraShakeBase> _hitCameraShake = nullptr;

	UPROPERTY(EditAnywhere)
	USoundBase* _hitSound = nullptr;

	UPROPERTY(EditAnywhere)
	USoundBase* _launchSound = nullptr;

	UPROPERTY(VisibleAnywhere)
	class UParticleSystemComponent* _trail;

	UPROPERTY(EditAnywhere)
	class UParticleSystem* _hitEffectBlueprint;

	UPROPERTY(VisibleAnywhere)
	UStaticMeshComponent* _mesh = nullptr;

	UPROPERTY(VisibleAnywhere)
	class UProjectileMovementComponent* _movement = nullptr;

	UPROPERTY(EditAnywhere)
	float _damage = 5.f;

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
	UFUNCTION()
	void OnHit(UPrimitiveComponent* hitComponent, AActor* otherActor, UPrimitiveComponent* other, FVector impulse, const FHitResult& hit);
};