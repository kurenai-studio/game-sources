// Copyright (c) 2026 Arena Runner contributors. MIT licensed.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "ArenaCollectible.generated.h"

class AArenaGameMode;
class USphereComponent;
class UStaticMeshComponent;

/**
 * "Energy Core" pickup: a spinning gem inside a halo.
 * Purely visual + overlap logic, the game mode handles scoring.
 */
UCLASS()
class ARENARUNNER_API AArenaCollectible : public AActor
{
	GENERATED_BODY()

public:
	AArenaCollectible();

	virtual void Tick(float DeltaSeconds) override;

	void SetOwningGameMode(AArenaGameMode* InGameMode) { OwningGameMode = InGameMode; }
	void SetOrbitPhase(float InPhase) { OrbitPhase = InPhase; }

protected:
	virtual void BeginPlay() override;

	UFUNCTION()
	void OnSphereOverlap(UPrimitiveComponent* OverlappedComponent, AActor* OtherActor,
		UPrimitiveComponent* OtherComp, int32 OtherBodyIndex, bool bFromSweep,
		const FHitResult& SweepResult);

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Core")
	TObjectPtr<USphereComponent> Sphere;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Core")
	TObjectPtr<UStaticMeshComponent> GemMesh;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Core")
	TObjectPtr<UStaticMeshComponent> HaloMesh;

	UPROPERTY(EditDefaultsOnly, Category = "Core")
	float SpinSpeed = 165.f;

	UPROPERTY(EditDefaultsOnly, Category = "Core")
	float BobHeight = 16.f;

	UPROPERTY(EditDefaultsOnly, Category = "Core")
	float BobSpeed = 2.1f;

private:
	UPROPERTY(Transient)
	TObjectPtr<AArenaGameMode> OwningGameMode;

	FVector StartLocation = FVector::ZeroVector;
	float OrbitPhase = 0.f;
	float Elapsed = 0.f;
	bool bCollected = false;
};
