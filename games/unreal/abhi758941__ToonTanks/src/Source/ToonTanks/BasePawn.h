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

	UFUNCTION()
	void HandleDestruction();

protected:
	UFUNCTION()
		void RotateTurret(FVector LookAtTarget);
	UFUNCTION(BlueprintCallable)
		void Fire();
public:
private:
UPROPERTY(VisibleAnywhere , BlueprintReadWrite , Category = "Model elements" , meta = (AllowPrivateAccess = "true"))	
	class UCapsuleComponent* CapsuleComp;
UPROPERTY(VisibleAnywhere , BlueprintReadWrite , Category = "Model elements" , meta = (AllowPrivateAccess = "true"))
	UStaticMeshComponent* BaseMesh;
UPROPERTY(VisibleAnywhere , BlueprintReadWrite , Category = "Model elements" , meta = (AllowPrivateAccess = "true"))	
	UStaticMeshComponent* TurretMesh;
UPROPERTY(VisibleAnywhere , BlueprintReadWrite , Category = "Model elements" , meta = (AllowPrivateAccess = "true"))
	USceneComponent* ProjectileSpawnPoint;
UPROPERTY(EditAnywhere , BlueprintReadWrite , Category = "Movement" , meta = (AllowPrivateAccess = "true"))
	float InterpSpeed = 100.f;
UPROPERTY(EditAnywhere , Category = "Death")
	class UParticleSystem* DeathParticles;
UPROPERTY(EditAnywhere , Category = "Combat")
	class USoundBase* DeathSound;
UPROPERTY(EditAnywhere , Category = "Combat")
	TSubclassOf<class UCameraShakeBase> DeathCameraShakeClass;
UPROPERTY(EditDefaultsOnly , Category = "Combat")
	TSubclassOf<class AProjectile> ProjectileClass;
};
