// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "GunBase.generated.h"

UCLASS()
class SUPERSOLDIER_API AGunBase : public AActor
{
	GENERATED_BODY()
	
public:	
	// Sets default values for this actor's properties
	AGunBase();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

	void PullTrigger();

	void SetActualMesh(class ACharacter* OwnerCharacter);

private:
	void InitializeComponents();
	void MuzzleAnimation();
	void ImpactAnimation(FVector Location, FRotator Rotation);
	bool Aim(FHitResult& HitResult, FVector& ShootDirection);
	AController* GetOwnerController() const;

	// Components
	UPROPERTY(VisibleAnywhere)
	USceneComponent* Root;
	UPROPERTY(VisibleAnywhere)
	USkeletalMeshComponent* Mesh;
	UPROPERTY(VisibleAnywhere)
	USkeletalMeshComponent* ActualMesh;
	// Decorations
	UPROPERTY(EditAnywhere)
	UParticleSystem* MuzzleFlash;
	UPROPERTY(EditAnywhere)
	UParticleSystem* ImpactEffect;
	UPROPERTY(EditAnywhere)
	USoundBase* MuzzleSound;
	UPROPERTY(EditAnywhere)
	USoundBase* ImpactSound;
	UPROPERTY(EditAnywhere)
	FString MuzzleSocketName = "MuzzleFlashSocket";
	// Stats
	UPROPERTY(EditAnywhere)
	float MaxShootRange = 5000.f;
	UPROPERTY(EditAnywhere)
	float Damage = 20.f;
	UPROPERTY(EditAnywhere)
	bool OriginGun = false;
};
