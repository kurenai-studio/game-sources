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
UPROPERTY(VisibleAnywhere , BlueprintReadWrite , Category = "Model elements" , meta = (AllowPrivateAccess = "true"))
	UStaticMeshComponent* BulletComponent;

UPROPERTY(VisibleAnywhere , BlueprintReadWrite , Category = "Projectile Movement" , meta = (AllowPrivateAccess = "true"))
	class UProjectileMovementComponent* ProjectileMovementComponent; 
UPROPERTY(EditAnywhere)
	float Damage = 50.f;
UPROPERTY(EditAnywhere , Category = "Combat")
	class UParticleSystem* HitParticles;
UPROPERTY(VisibleAnywhere , Category = "Mesh")
	class UParticleSystemComponent* SmokeTrail;
UPROPERTY(EditAnywhere , Category = "Combat")
	class USoundBase* LaunchSound;
UPROPERTY(EditAnywhere , Category = "Combat")
	USoundBase* HitSound;
UPROPERTY(EditAnywhere , Category = "Combat")
	TSubclassOf<class UCameraShakeBase> HitCameraShakeClass;
	
UFUNCTION()
	void OnHit(UPrimitiveComponent* HitComp , AActor* OtherActor , UPrimitiveComponent* OtherComp , FVector NormalImpulse , const FHitResult& Hit);
};
