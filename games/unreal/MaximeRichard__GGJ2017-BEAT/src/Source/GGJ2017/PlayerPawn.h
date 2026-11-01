// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "PlayerProjectile.h"
#include "GameFramework/Pawn.h"
#include "PlayerPawn.generated.h"

UCLASS()
class GGJ2017_API APlayerPawn : public APawn
{
	GENERATED_BODY()

public:
	// Sets default values for this pawn's properties
	APlayerPawn();

	void Shoot();

	void Shield();

	void ReleaseShield();

	UPROPERTY(EditAnywhere)
	FVector ShootingOffset = FVector(0.f);

	void SpawnProjectile();

	void OnLoseLife();

	// Called when the game starts or when spawned
	virtual void BeginPlay() override;
	
	// Called every frame
	virtual void Tick( float DeltaSeconds ) override;

	// Called to bind functionality to input
	virtual void SetupPlayerInputComponent(class UInputComponent* InputComponent) override;

	UFUNCTION(BlueprintCallable, Category = "Beat")
	void OnBeat();

	UPROPERTY(BlueprintReadWrite)
	TSubclassOf<APlayerProjectile> Projectile;
	
	bool CanShoot = false;
	bool Shielded = false;

	UPROPERTY(EditAnywhere)
	float ShootWindowTime = 0.25f;

	UPROPERTY(EditAnywhere)
	float CurrentShootWindowTime = 0.f;

	UPROPERTY(BlueprintReadWrite)
	int LifePoints = 4;

	void GameOver();
};
