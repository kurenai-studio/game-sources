// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Pawn.h"
#include "BasePawn.generated.h"

UCLASS()
class TOONTANKS_API ABasePawn : public APawn
{
	GENERATED_BODY()

protected:
	// Constructor
	ABasePawn();

	void RotateTurret(const FVector& LookAtTarget) const;
	void Fire();
	virtual void HandleDestruction();
public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;
private:
	UPROPERTY(VisibleAnywhere, Category= "Pawn Components", meta=(AllowPrivateAccess = "true"))
	class UCapsuleComponent* CapsuleComp;
	UPROPERTY(VisibleAnywhere, Category= "Pawn Components", meta=(AllowPrivateAccess = "true"))
	UStaticMeshComponent* BaseMesh;
	UPROPERTY(VisibleAnywhere, Category= "Pawn Components", meta=(AllowPrivateAccess = "true"))
	UStaticMeshComponent* TurretMesh;
	UPROPERTY(VisibleAnywhere, Category= "Pawn Components", meta=(AllowPrivateAccess = "true"))
	USceneComponent* ProjectileSpawnPoint;
	
	UPROPERTY(EditAnywhere, Category= "FX", meta=(AllowPrivateAccess = "true"))
	UParticleSystem* ExplodeParticle;
	UPROPERTY(EditAnywhere, Category= "FX", meta=(AllowPrivateAccess = "true"))
	USoundBase* ExplodeSfx;
	UPROPERTY(EditAnywhere, Category= "FX", meta=(AllowPrivateAccess = "true"))
	USoundBase* FireSfx;

	UPROPERTY(EditDefaultsOnly, Category="Combat")
	TSubclassOf<class AProjectile> ProjectileClass;
	UPROPERTY(EditDefaultsOnly, Category="Combat")
	TSubclassOf<class UCameraShakeBase> DeathCameraShakeClass;
};
