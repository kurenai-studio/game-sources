#pragma once

#include "CoreMinimal.h"
#include "SeagullEnemySpawner.generated.h"

class USeagullConfigCache;
class ASeagullEnemyBase;

UCLASS()
class USeagullEnemySpawner : public UObject
{
	GENERATED_BODY()

public:
	void Initialize(USeagullConfigCache* Config);
	void Tick(float DeltaTime, UWorld* World);
	void SpawnBoss(UWorld* World);
	void Reset();

private:
	float WaveInterval = 15.f;
	int32 WaveEnemyCountBase = 5;
	float WaveEnemyCountGrowth = 1.3f;
	int32 CurrentWave = 0;
	float WaveTimer = 0.f;

	UPROPERTY()
	USeagullConfigCache* ConfigCache = nullptr;

	void SpawnWave(UWorld* World);
	FVector GetSpawnPosition(UWorld* World) const;
	TSubclassOf<ASeagullEnemyBase> GetEnemyClassForWave(int32 Wave) const;
};
