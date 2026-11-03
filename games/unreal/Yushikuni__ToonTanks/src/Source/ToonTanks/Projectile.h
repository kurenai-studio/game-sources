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

private:

	UPROPERTY(VisibleAnywhere, Category = "Projectile Capsule Component")
		class UCapsuleComponent* CapsuleComp;

	UPROPERTY(VisibleAnywhere, Category = "Projectile Mesh")
		UStaticMeshComponent* ProjectileMesh;

	UPROPERTY(VisibleAnywhere, Category = "Projectile Movement")
		class UProjectileMovementComponent* ProjectileMovementComp;

	UPROPERTY(VisibleAnywhere, Category = "Projectile Movement")
		float InitialSpeed;

	UPROPERTY(VisibleAnywhere, Category = "Projectile Movement")
		float MaxSpeed;

	UPROPERTY(EditAnywhere, Category = "Projectile Damage")
		float Damage = 50.f;

	UPROPERTY(EditAnywhere, Category = "Projectile Movement")
		class UParticleSystem* HitParticles;

	UPROPERTY(VisibleAnywhere, Category = "Projectile Movement")
		class UParticleSystemComponent* SmokeTrail;

	UPROPERTY(Editanywhere, Category = "Projectile Damage")
		class USoundBase* LaunchSound;

	UPROPERTY(Editanywhere, Category = "Projectile Damage")
		USoundBase* HitSound;

	UPROPERTY(Editanywhere, Category = "Projectile Damage")
		TSubclassOf<class UCameraShakeBase> HitCameraShakeClass;

	//functions	
	UFUNCTION()
		void OnOverlapBegin(class UPrimitiveComponent* OverlappedComp, class AActor* OtherActor, class UPrimitiveComponent* OtherComp, int32 OtherBodyIndex, bool bFromSweep, const FHitResult& SweepResult);
	UFUNCTION()
		void OnOverlapEnd(class UPrimitiveComponent* OverlappedComp, class AActor* OtherActor, class UPrimitiveComponent* OtherComp, int32 OtherBodyIndex);

public:
	// Called every frame
	virtual void Tick(float DeltaTime) override;

	AController* InstigatorController;

private:
	UPROPERTY(VisibleAnywhere, Category = "Owner Actor")
	AActor* OwnerActor;
};
