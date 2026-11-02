// Copyright (c) 2026 Arena Runner contributors. MIT licensed.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "ArenaGameMode.generated.h"

class AArenaCharacter;
class AArenaCollectible;
class AArenaHunter;
class AArenaGameState;
class UArenaSaveGame;

/**
 * Arena Runner game mode. Owns the run loop:
 *
 *  StartRun() -> builds the arena -> spawns the wave of Energy Cores ->
 *  player collects them all (or dies) -> wave cleared / game over -> restart.
 *
 * The GameMode constructs the whole level procedurally with engine primitive meshes,
 * so it works in an empty map (see README: "Set up the map in 60 seconds").
 */
UCLASS()
class ARENARUNNER_API AArenaGameMode : public AGameModeBase
{
	GENERATED_BODY()

public:
	AArenaGameMode();

	virtual void BeginPlay() override;

	/** Called by a collectible when the player touches it. */
	void HandleCollectibleCollected(AArenaCollectible* Collectible);

	/** Called by the character when its health reaches zero. */
	void HandlePlayerDied();

	/** Where the player should stand. Used by the character on BeginPlay. */
	FVector GetPlayerSpawnLocation() const;

	AArenaGameState* GetArenaGameState() const;
	AArenaCharacter* GetArenaCharacter() const;

protected:
	// ---- Arena layout -----------------------------------------------------

	UPROPERTY(EditDefaultsOnly, Category = "Arena|Layout")
	float ArenaRadius = 1900.f;

	UPROPERTY(EditDefaultsOnly, Category = "Arena|Layout")
	float WallHeight = 520.f;

	UPROPERTY(EditDefaultsOnly, Category = "Arena|Layout")
	int32 WallSegments = 40;

	/** Seconds the game over screen stays up before the run restarts. */
	UPROPERTY(EditDefaultsOnly, Category = "Arena|Flow")
	float RestartDelay = 3.0f;

	// ---- Waves ------------------------------------------------------------

	UPROPERTY(EditDefaultsOnly, Category = "Arena|Wave")
	float BaseCollectibleCount = 6.f;

	UPROPERTY(EditDefaultsOnly, Category = "Arena|Wave")
	float CollectiblesPerWave = 2.f;

	UPROPERTY(EditDefaultsOnly, Category = "Arena|Wave")
	int32 MaxCollectiblesPerWave = 18;

	UPROPERTY(EditDefaultsOnly, Category = "Arena|Wave")
	int32 ScorePerCollectible = 25;

	UPROPERTY(EditDefaultsOnly, Category = "Arena|Wave")
	int32 WaveClearBonus = 100;

	// ---- Hunters (the chasing hazard) -------------------------------------

	/** First wave that spawns hunters. Wave 1 is a warm-up. */
	UPROPERTY(EditDefaultsOnly, Category = "Arena|Hunters")
	int32 FirstHunterWave = 2;

	UPROPERTY(EditDefaultsOnly, Category = "Arena|Hunters")
	int32 MaxHunters = 6;

	UPROPERTY(EditDefaultsOnly, Category = "Arena|Hunters")
	float HunterBaseSpeed = 290.f;

	UPROPERTY(EditDefaultsOnly, Category = "Arena|Hunters")
	float HunterSpeedPerWave = 12.f;

	/** Hunters stay slower than WalkSpeed so they can always be outrun. */
	UPROPERTY(EditDefaultsOnly, Category = "Arena|Hunters")
	float HunterMaxSpeed = 410.f;

	UPROPERTY(EditDefaultsOnly, Category = "Arena|Hunters")
	float HunterContactDamage = 14.f;

private:
	void BuildArena();
	void CreateArenaFloor();
	void CreateArenaWalls();
	void CreateBorderMarkers();
	void CreateLighting();

	void StartRun();
	void StartWave();
	void SpawnHunters(int32 WaveNumber);
	void ClearWave();
	void EndRun(float Delay);
	void Notify(const FString& Message, FLinearColor Color, float Duration = 2.5f);
	void SaveBestScore();

	FCollisionQueryParams GetArenaQueryParams() const;

	UPROPERTY(Transient)
	TArray<TObjectPtr<AArenaCollectible>> ActiveCollectibles;

	UPROPERTY(Transient)
	TArray<TObjectPtr<AArenaHunter>> ActiveHunters;

	UPROPERTY(Transient)
	TObjectPtr<UArenaSaveGame> SaveGame;

	FVector SpawnLocation = FVector(0.f, 0.f, 120.f);
	FRotator SpawnRotation = FRotator::ZeroRotator;

	FTimerHandle RestartTimer;
	FTimerHandle WaveTimer;
};
