// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
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
private:
	UFUNCTION()
	void OnHit(UPrimitiveComponent* hitComp, AActor* otherActor, UPrimitiveComponent* otherComp, FVector normalImpulse, const FHitResult& hit);

private:
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Components", meta = (AllowPrivateAccess = "true"))
	class UStaticMeshComponent* BaseMesh = nullptr;

	UPROPERTY(VisibleAnywhere, Category = "Components")
	class UProjectileMovementComponent* ProjectileMovementComp = nullptr;
	
	UPROPERTY(VisibleAnywhere, Category = "Components")
	class UParticleSystemComponent* SmokeTrail = nullptr;

	UPROPERTY(VisibleAnywhere, Category = "Combat")
	float Damage = 50.0f;

	UPROPERTY(EditAnywhere, Category="Combat")
	class UParticleSystem* HitParticle = nullptr;

	UPROPERTY(EditAnywhere, Category = "Combat")
	class USoundBase* LaunchSound = nullptr;

	UPROPERTY(EditAnywhere, Category = "Combat")
	class USoundBase* HitSound = nullptr;

	UPROPERTY(EditAnywhere, Category="Combat")
	TSubclassOf<class UCameraShakeBase> HitCameraShakeClass = nullptr;
};
