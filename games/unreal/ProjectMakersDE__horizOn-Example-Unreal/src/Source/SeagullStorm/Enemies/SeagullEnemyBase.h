#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "Core/SeagullTypes.h"
#include "SeagullEnemyBase.generated.h"

class UPaperFlipbook;
class UPaperFlipbookComponent;
class USphereComponent;
class USeagullCutoutRigComponent;

UCLASS()
class ASeagullEnemyBase : public AActor
{
	GENERATED_BODY()

public:
	ASeagullEnemyBase();

	virtual void BeginPlay() override;
	virtual void Tick(float DeltaTime) override;

	void InitFromStats(const FSeagullEnemyStats& Stats);
	void TakeDamageAmount(int32 Amount);
	bool IsDead() const { return CurrentHP <= 0; }

	UPROPERTY(VisibleAnywhere)
	USphereComponent* CollisionComponent;

	UPROPERTY(VisibleAnywhere)
	UPaperFlipbookComponent* SpriteComponent;

	UPROPERTY(VisibleAnywhere)
	USeagullCutoutRigComponent* CutoutRig = nullptr;

	ESeagullEnemyType EnemyType = ESeagullEnemyType::Crab;
	int32 MaxHP = 30;
	int32 CurrentHP = 30;
	float MoveSpeed = 40.f;
	int32 ContactDamage = 10;
	int32 XPDrop = 10;

protected:
	virtual void MoveTowardPlayer(float DeltaTime);
	virtual void OnDeath();

	// Loads walk/death flipbooks from canonical /Game/Flipbooks paths.
	// Called from subclass constructors (null-guarded; assets are editor-created).
	void LoadFlipbooks(const TCHAR* WalkPath, const TCHAR* DeathPath);

	UPROPERTY()
	UPaperFlipbook* WalkFlipbook = nullptr;

	UPROPERTY()
	UPaperFlipbook* DeathFlipbook = nullptr;

	float DeathDespawnDelay = 0.45f;

	float AttackCooldown = 1.0f;
	float AttackTimer = 0.f;
	float HitFlashTimer = 0.f;
	float VisualFacing = 1.f;

	AActor* GetPlayerPawn() const;

	UFUNCTION()
	void OnOverlapBegin(UPrimitiveComponent* OverlappedComp, AActor* OtherActor,
		UPrimitiveComponent* OtherComp, int32 OtherBodyIndex,
		bool bFromSweep, const FHitResult& SweepResult);
};
