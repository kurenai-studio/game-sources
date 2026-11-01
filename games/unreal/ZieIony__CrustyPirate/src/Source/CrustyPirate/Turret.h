// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "PaperZDCharacter.h"
#include "DestructiblePiece.h"
#include "Turret.generated.h"

class UPaperZDAnimSequence;
class ABullet;
class AParticle;

/**
 * 
 */
UCLASS()
class CRUSTYPIRATE_API ATurret : public APaperZDCharacter
{
	GENERATED_BODY()

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	int MaxHitPoints = 100;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	int CurrentHitPoints = MaxHitPoints;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float attackCooldownInSeconds = 10;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ABullet> BulletClass;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	USceneComponent* BulletSpawnLocation;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AParticle> ParticleClass;

#pragma region destructible pieces
	UPROPERTY(EditAnywhere)
	TSubclassOf<ADestructiblePiece> DestructiblePiece;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ADestructiblePiece> DestructiblePiece2;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ADestructiblePiece> DestructiblePiece3;
#pragma endregion

	FTimerHandle stunTimer;
	FTimerHandle attackCooldownTimer;

	bool canAttack = false;

	ATurret();

	virtual void BeginPlay() override;

	virtual void Tick(float dt) override;

	bool getIsAlive();

	void attack();

	void onAttackCooldownTimerTimeout();

	UFUNCTION(BlueprintCallable)
	void SpawnBullet();

	void takeDamage(int damageAmount);

	void destroyAndSpawnPieces();
};
