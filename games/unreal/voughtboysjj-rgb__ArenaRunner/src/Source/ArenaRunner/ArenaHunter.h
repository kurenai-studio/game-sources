// Copyright (c) 2026 Arena Runner contributors. MIT licensed.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "ArenaHunter.generated.h"

class USphereComponent;
class UStaticMeshComponent;

/**
 * "Hunter": a slow, relentless orb that chases the player and damages them on contact.
 *
 * Hunters are slower than the player's walk speed, so they can always be outrun —
 * they exist to push you around the arena while you collect cores.
 */
UCLASS()
class ARENARUNNER_API AArenaHunter : public AActor
{
	GENERATED_BODY()

public:
	AArenaHunter();

	virtual void Tick(float DeltaSeconds) override;

	void SetTarget(AActor* InTarget) { Target = InTarget; }

	void SetChaseSpeed(float InSpeed) { ChaseSpeed = InSpeed; }

	/** Damage dealt per contact (the character applies its own hit cooldown). */
	void SetContactDamage(float InDamage) { ContactDamage = InDamage; }

protected:
	virtual void BeginPlay() override;

	UFUNCTION()
	void OnSphereOverlap(UPrimitiveComponent* OverlappedComponent, AActor* OtherActor,
		UPrimitiveComponent* OtherComp, int32 OtherBodyIndex, bool bFromSweep,
		const FHitResult& SweepResult);

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Hunter")
	TObjectPtr<USphereComponent> Sphere;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Hunter")
	TObjectPtr<UStaticMeshComponent> CoreMesh;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Hunter")
	TObjectPtr<UStaticMeshComponent> RingMesh;

	UPROPERTY(EditDefaultsOnly, Category = "Hunter|Stats")
	float ChaseSpeed = 300.f;

	UPROPERTY(EditDefaultsOnly, Category = "Hunter|Stats")
	float ContactDamage = 14.f;

	/** Height above the floor the orb floats at. */
	UPROPERTY(EditDefaultsOnly, Category = "Hunter|Stats")
	float HoverHeight = 110.f;

	UPROPERTY(EditDefaultsOnly, Category = "Hunter|Stats")
	float BobAmplitude = 10.f;

private:
	TWeakObjectPtr<AActor> Target;
	float Elapsed = 0.f;
	float BaseZ = 110.f;
};
