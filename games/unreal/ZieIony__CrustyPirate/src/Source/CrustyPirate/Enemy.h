// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Captain.h"
#include "CoreMinimal.h"
#include <Delegates/DelegateCombinations.h>
#include "Particle.h"
#include "EnemySaveData.h"

#include "Enemy.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnHealthChanged, float, NewHealth);

class USphereComponent;
class UBoxComponent;
class ACaptain;
class UPaperZDAnimSequence;

/**
 *
 */
UCLASS()
class CRUSTYPIRATE_API AEnemy: public APaperZDCharacter {
	GENERATED_BODY()

private:
	bool isFacingUpperLedge = false;
	bool isOnLedge = false;
	bool isFacingWall = false;
	bool inAttackRange = false;

public:
	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	UBoxComponent* PlayerDetectionBox;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	USphereComponent* PlayerFollowSphere;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	UBoxComponent* UpperLedgeDetectionBox;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	UBoxComponent* LedgeDetectionBox;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	UBoxComponent* WallDetectionBox;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	UBoxComponent* AttackDetectionBox;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	UBoxComponent* AttackCollisionBox;

#pragma region dialogue
	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	UPaperFlipbookComponent* DialogueComponent;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	UPaperFlipbook* ExclamationFlipbook;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	UPaperFlipbook* DeadFlipbook;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	UPaperFlipbook* QuestionFlipbook;
#pragma endregion

#pragma region loot
	UPROPERTY(EditAnywhere)
	TSubclassOf<ACollectibleItem> LootClass;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	int LootCount = 3;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ACollectibleItem> LootClass2;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	int LootCount2 = 1;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float LaunchLootForce = 1;
#pragma endregion

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	ACaptain* FollowTarget;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	UPaperZDAnimSequence* AttackAnimSequence;

	FZDOnAnimationOverrideEndSignature OnAttackOverrideEndDelegate;

	UPROPERTY(BlueprintAssignable)
	FOnHealthChanged OnHealthChangedEvent;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float lostInterestDelaySeconds = 5;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float attackCooldownInSeconds = 3;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	int MaxHitPoints = 100;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	int hitPoints = MaxHitPoints;

	bool canMove = true;
	bool isStunned = false;
	bool canAttack = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	int attackDamage = 25;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float attackStunDuration = 0.3f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float attackStunForce = 10000.0f;

	FTimerHandle lostInterestTimer;
	FTimerHandle stunTimer;
	FTimerHandle attackCooldownTimer;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	TSubclassOf<AParticle> DustClass;

	AEnemy();

	virtual void BeginPlay() override;

	virtual void Tick(float dt) override;

	UFUNCTION()
	void PlayerDetectorOverlapBegin(
		UPrimitiveComponent* overlappedComponent,
		AActor* otherActor,
		UPrimitiveComponent* otherComponent,
		int32 otherBodyIndex,
		bool fromSweep,
		const FHitResult& sweepResults
	);

	UFUNCTION()
	void PlayerDetectorOverlapEnd(
		UPrimitiveComponent* overlappedComponent,
		AActor* otherActor,
		UPrimitiveComponent* otherComponent,
		int32 otherBodyIndex
	);

	UFUNCTION()
	void PlayerFollowOverlapEnd(
		UPrimitiveComponent* overlappedComponent,
		AActor* otherActor,
		UPrimitiveComponent* otherComponent,
		int32 otherBodyIndex
	);

	UFUNCTION()
	void UpperLedgeDetectorOverlapBegin(
		UPrimitiveComponent* overlappedComponent,
		AActor* otherActor,
		UPrimitiveComponent* otherComponent,
		int32 otherBodyIndex,
		bool fromSweep,
		const FHitResult& sweepResults
	);

	UFUNCTION()
	void UpperLedgeDetectorOverlapEnd(
		UPrimitiveComponent* overlappedComponent,
		AActor* otherActor,
		UPrimitiveComponent* otherComponent,
		int32 otherBodyIndex
	);

	UFUNCTION()
	void LedgeDetectorOverlapBegin(
		UPrimitiveComponent* overlappedComponent,
		AActor* otherActor,
		UPrimitiveComponent* otherComponent,
		int32 otherBodyIndex,
		bool fromSweep,
		const FHitResult& sweepResults
	);

	UFUNCTION()
	void LedgeDetectorOverlapEnd(
		UPrimitiveComponent* overlappedComponent,
		AActor* otherActor,
		UPrimitiveComponent* otherComponent,
		int32 otherBodyIndex
	);

	UFUNCTION()
	void WallDetectorOverlapBegin(
		UPrimitiveComponent* overlappedComponent,
		AActor* otherActor,
		UPrimitiveComponent* otherComponent,
		int32 otherBodyIndex,
		bool fromSweep,
		const FHitResult& sweepResults
	);

	UFUNCTION()
	void WallDetectorOverlapEnd(
		UPrimitiveComponent* overlappedComponent,
		AActor* otherActor,
		UPrimitiveComponent* otherComponent,
		int32 otherBodyIndex
	);

	UFUNCTION()
	void AttackDetectorOverlapBegin(
		UPrimitiveComponent* overlappedComponent,
		AActor* otherActor,
		UPrimitiveComponent* otherComponent,
		int32 otherBodyIndex,
		bool fromSweep,
		const FHitResult& sweepResults
	);

	UFUNCTION()
	void AttackDetectorOverlapEnd(
		UPrimitiveComponent* overlappedComponent,
		AActor* otherActor,
		UPrimitiveComponent* otherComponent,
		int32 otherBodyIndex
	);

	bool getIsAlive();

	void updateDirection(float moveDirection);

	void updateHP(int newHP);

	void takeDamage(int damageAmount, float stunDuration, float stunForce, AActor* otherActor);

	void spawnLoot();

	void onLostInterestTimerTimeout();

	void stopFollowing();

	void stun(float durationInSeconds);

	void onStunTimerTimeout();

	void attack();

	void onAttackCooldownTimerTimeout();

	void onAttackOverrideAnimEnd(bool completed);

	UFUNCTION()
	void AttackBoxOverlapBegin(
		UPrimitiveComponent* overlappedComponent,
		AActor* otherActor,
		UPrimitiveComponent* otherComponent,
		int32 otherBodyIndex,
		bool fromSweep,
		const FHitResult& sweepResults
	);

	UFUNCTION(BlueprintCallable)
	void EnableAttackCollisionBox(bool enable);

	void playDialogue(DialogueType type, bool force = false);

	UFUNCTION()
	void onDialogueFinishedPlaying();

	UFUNCTION(BlueprintCallable)
	void SpawnRunDust();

	FEnemySaveData getSaveData();

	void setSaveData(FEnemySaveData& saveData);

	static AEnemy* spawn(UWorld* world, FEnemySaveData& saveData);
};
