#include "Enemies/SeagullEnemySpawner.h"
#include "Enemies/SeagullEnemy_Crab.h"
#include "Enemies/SeagullEnemy_Jellyfish.h"
#include "Enemies/SeagullEnemy_Pirate.h"
#include "Enemies/SeagullEnemy_Boss.h"
#include "Core/SeagullStormGameState.h"
#include "Core/SeagullGameInstance.h"
#include "Data/SeagullConfigCache.h"
#include "Core/SeagullTypes.h"
#include "Horizon/SeagullHorizonManager.h"
#include "Kismet/GameplayStatics.h"
#include "SeagullStorm.h"

void USeagullEnemySpawner::Initialize(USeagullConfigCache* Config)
{
	ConfigCache = Config;
	CurrentWave = 0;
	WaveTimer = WaveInterval; // The first wave starts immediately.

	if (Config)
	{
		WaveInterval = Config->WaveIntervalSeconds;
		WaveEnemyCountBase = Config->WaveEnemyCountBase;
		WaveEnemyCountGrowth = Config->WaveEnemyCountGrowth;
		WaveTimer = WaveInterval;
	}
}

void USeagullEnemySpawner::Tick(float DeltaTime, UWorld* World)
{
	if (!World) return;

	// Stop spawning new waves once timer has expired (boss fight phase)
	ASeagullStormGameState* GS = World->GetGameState<ASeagullStormGameState>();
	if (GS && GS->IsTimerExpired()) return;

	WaveTimer += DeltaTime;
	if (WaveTimer >= WaveInterval)
	{
		WaveTimer = 0.f;
		SpawnWave(World);
	}
}

void USeagullEnemySpawner::SpawnWave(UWorld* World)
{
	CurrentWave++;

	ASeagullStormGameState* GS = World->GetGameState<ASeagullStormGameState>();
	if (GS)
	{
		GS->AdvanceWave();

		// Record breadcrumb
		USeagullGameInstance* GI = Cast<USeagullGameInstance>(UGameplayStatics::GetGameInstance(World));
		if (GI)
		{
			USeagullHorizonManager* HM = GI->GetHorizonManager();
			if (HM)
			{
				HM->RecordBreadcrumb(TEXT("state"), FString::Printf(TEXT("wave_%d"), CurrentWave));
				HM->SetCrashCustomKey(TEXT("wave"), FString::FromInt(CurrentWave));
				HM->SetCrashCustomKey(TEXT("score"), FString::FromInt(GS->CurrentScore));
			}
		}
	}

	int32 EnemyCount = FMath::Clamp(static_cast<int32>(WaveEnemyCountBase * FMath::Pow(WaveEnemyCountGrowth, static_cast<float>(CurrentWave - 1))), 1, 80);

	for (int32 i = 0; i < EnemyCount; i++)
	{
		TSubclassOf<ASeagullEnemyBase> EnemyClass = GetEnemyClassForWave(CurrentWave);
		FVector SpawnPos = GetSpawnPosition(World);

		FActorSpawnParameters Params;
		Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

		ASeagullEnemyBase* Enemy = World->SpawnActor<ASeagullEnemyBase>(EnemyClass, SpawnPos, FRotator::ZeroRotator, Params);
		if (Enemy && ConfigCache)
		{
			// Apply config stats
			if (Enemy->EnemyType == ESeagullEnemyType::Crab)
				Enemy->InitFromStats(ConfigCache->CrabStats);
			else if (Enemy->EnemyType == ESeagullEnemyType::Jellyfish)
				Enemy->InitFromStats(ConfigCache->JellyfishStats);
			else if (Enemy->EnemyType == ESeagullEnemyType::Pirate)
				Enemy->InitFromStats(ConfigCache->PirateStats);
		}
	}

	UE_LOG(LogSeagullStorm, Log, TEXT("Spawned wave %d with %d enemies"), CurrentWave, EnemyCount);
}

void USeagullEnemySpawner::SpawnBoss(UWorld* World)
{
	if (!World) return;

	FVector SpawnPos = GetSpawnPosition(World);
	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

	ASeagullEnemy_Boss* Boss = World->SpawnActor<ASeagullEnemy_Boss>(ASeagullEnemy_Boss::StaticClass(), SpawnPos, FRotator::ZeroRotator, Params);
	if (Boss && ConfigCache)
	{
		FSeagullEnemyStats BossStats;
		BossStats.HP = ConfigCache->WaveBossHP;
		BossStats.Speed = 30.f;
		BossStats.Damage = 30;
		BossStats.XPDrop = 100;
		Boss->InitFromStats(BossStats);
	}

	UE_LOG(LogSeagullStorm, Log, TEXT("Boss spawned!"));
}

void USeagullEnemySpawner::Reset()
{
	CurrentWave = 0;
	WaveTimer = 0.f;
}

FVector USeagullEnemySpawner::GetSpawnPosition(UWorld* World) const
{
	// Spawn from screen edges
	float HalfW = SeagullConstants::ArenaWidth * 0.5f;
	float HalfH = SeagullConstants::ArenaHeight * 0.5f;

	int32 Edge = FMath::RandRange(0, 3);
	float X, Y;

	switch (Edge)
	{
		case 0: X = FMath::FRandRange(-HalfW, HalfW); Y = -HalfH; break; // Top
		case 1: X = FMath::FRandRange(-HalfW, HalfW); Y = HalfH; break;  // Bottom
		case 2: X = -HalfW; Y = FMath::FRandRange(-HalfH, HalfH); break; // Left
		default: X = HalfW; Y = FMath::FRandRange(-HalfH, HalfH); break;  // Right
	}

	return FVector(X, Y, 0.f);
}

TSubclassOf<ASeagullEnemyBase> USeagullEnemySpawner::GetEnemyClassForWave(int32 Wave) const
{
	// Wave-based enemy selection per design doc
	TArray<TSubclassOf<ASeagullEnemyBase>> Available;
	Available.Add(ASeagullEnemy_Crab::StaticClass());

	if (Wave >= 3) Available.Add(ASeagullEnemy_Jellyfish::StaticClass());
	if (Wave >= 5) Available.Add(ASeagullEnemy_Pirate::StaticClass());

	return Available[FMath::RandRange(0, Available.Num() - 1)];
}
