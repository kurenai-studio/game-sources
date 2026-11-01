// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Pawn.h"
#include "BasePawn.generated.h"

class USoundBase;

UCLASS()
class TOONTANKS_API ABasePawn : public APawn
{
	GENERATED_BODY()

public:
	// Sets default values for this pawn's properties
	ABasePawn();

private:

	UPROPERTY(EditAnywhere)
	class UParticleSystem* _deathEffect = nullptr;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Base Pawn Configuration", meta = (AllowPrivateAccess = "true"))
	class UCapsuleComponent* _capsule = nullptr;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Base Pawn Configuration", meta = (AllowPrivateAccess = "true"))
	UStaticMeshComponent* _body = nullptr;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Base Pawn Configuration", meta = (AllowPrivateAccess = "true"))
	UStaticMeshComponent* _turret = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "Combat Configuration")
	TSubclassOf<class AProjectile> _projectileBlueprint;

protected:
	UPROPERTY(EditAnywhere)
	USoundBase* _deathSound = nullptr;

	UPROPERTY()
	class AToonTanksGameMode* _gameMode;
	
	class UHealth* _health = nullptr;

	virtual void BeginPlay() override;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Base Pawn Configuration", meta = (AllowPrivateAccess = "true"))
	USceneComponent* _projectileSpawnPoint = nullptr;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, meta = (AllowPrivateAccess = "true"))
	float _speed = 10.f;

	void RotateTurretTowards(const FVector& target, float speed = 5.f);

	void Fire();

	UFUNCTION()
	virtual void OnDeath();
};
