// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Pawn.h"
#include "BasePawn.generated.h"

UCLASS()
class TOONTANKS_API ABasePawn : public APawn
{
	GENERATED_BODY()

public:
	// Sets default values for this pawn's properties
	ABasePawn();
	void HandleDestruction();

protected:
	void RotateTurret(FVector LookAtTarget);
	void Fire();

private:
	UPROPERTY(VisibleAnywhere, BLueprintReadWrite, Category = "Coliders", meta = (AllowPrivateAccess = "true"))
	class UCapsuleComponent *CapsuleComp;

	UPROPERTY(VisibleAnywhere, BLueprintReadWrite, Category = "Meshes", meta = (AllowPrivateAccess = "true"))
	UStaticMeshComponent *BaseMesh;

	UPROPERTY(VisibleAnywhere, BLueprintReadWrite, Category = "Meshes", meta = (AllowPrivateAccess = "true"))
	UStaticMeshComponent *TurretMesh;

	UPROPERTY(VisibleAnywhere, BLueprintReadWrite, Category = "ShootPoint", meta = (AllowPrivateAccess = "true"))
	USceneComponent *ProjectileSpawnPoint;

	UPROPERTY(EditDefaultsOnly, BLueprintReadWrite, Category = "Combat", meta = (AllowPrivateAccess = "true"))
	TSubclassOf<class AProjectile> ProjectileClass;

	UPROPERTY(EditAnywhere, Category = "Combat")
	class UParticleSystem *DeathParticles;

	UPROPERTY(EditAnywhere, Category = "Combat")
	class USoundBase *HitSound;
	// UPROPERTY(EditAnywhere,BLueprintReadWrite, meta = (AllowPrivateAccess="true"))
	// float Speed = 12.2;

	UPROPERTY(EditAnywhere, Category = "Combat")
	TSubclassOf<class UCameraShakeBase> DeathCameraShakeClass;
};
