#include "Core/SeagullStormGameState.h"
#include "Data/SeagullConfigCache.h"
#include "Player/SeagullPlayerPawn.h"
#include "Player/SeagullHealthComponent.h"
#include "Player/SeagullXPComponent.h"
#include "Weapons/SeagullWeaponManager.h"
#include "Weapons/SeagullWeaponBase.h"
#include "GameFramework/FloatingPawnMovement.h"
#include "SeagullStorm.h"
#include "Kismet/GameplayStatics.h"

void ASeagullStormGameState::InitRun(USeagullConfigCache* Config)
{
	ConfigCacheRef = Config;

	CurrentWave = 0;
	CurrentScore = 0;
	CurrentLevel = 1;
	PendingLevelUpChoices = 0;
	KillCount = 0;
	TotalXPCollected = 0;
	CurrentXP = 0;
	bBossSpawned = false;
	bRunActive = true;

	TimeRemaining = Config ? static_cast<float>(Config->RunDurationSeconds) : 180.f;
	XPToNextLevel = CalculateXPToNextLevel();

	RunStats = FSeagullRunStats();
	RunStartTime = UGameplayStatics::GetRealTimeSeconds(GetWorld());

	// Start with feather weapon
	ActiveWeapons.Empty();
	ActiveWeapons.Add(ESeagullWeaponType::Feather);
	WeaponLevels.Empty();
	WeaponLevels.Add(ESeagullWeaponType::Feather, 1);
}

void ASeagullStormGameState::TickTimer(float DeltaTime)
{
	if (!bRunActive) return;

	TimeRemaining -= DeltaTime;
	RunStats.Duration += DeltaTime;

	if (TimeRemaining <= 0.f)
	{
		TimeRemaining = 0.f;
		OnTimerExpired.Broadcast();
	}
}

void ASeagullStormGameState::AddScore(int32 Amount)
{
	CurrentScore += Amount;
	RunStats.Score = CurrentScore;
	OnScoreChanged.Broadcast(CurrentScore);
}

void ASeagullStormGameState::AddKill()
{
	KillCount++;
	RunStats.Kills = KillCount;
	AddScore(1); // 1 point per kill (Score = kills + XP collected + survival time)
}

void ASeagullStormGameState::AddXP(int32 Amount)
{
	if (!bRunActive || Amount <= 0) return;
	const bool HadPendingChoices = PendingLevelUpChoices > 0;
	CurrentXP += Amount;
	TotalXPCollected += Amount;
	RunStats.XPCollected = TotalXPCollected;

	// Check for level up
	while (CurrentXP >= XPToNextLevel)
	{
		CurrentXP -= XPToNextLevel;
		CurrentLevel++;
		RunStats.LevelReached = CurrentLevel;
		XPToNextLevel = CalculateXPToNextLevel();
		OnLevelUp.Broadcast(CurrentLevel);
		++PendingLevelUpChoices;

		UE_LOG(LogSeagullStorm, Log, TEXT("Level up! Now level %d"), CurrentLevel);
	}
	if (!HadPendingChoices && PendingLevelUpChoices > 0) OnTriggerLevelUpChoices.Broadcast();
}

void ASeagullStormGameState::AdvanceWave()
{
	CurrentWave++;
	RunStats.WavesReached = CurrentWave;
	OnWaveChanged.Broadcast(CurrentWave);
	UE_LOG(LogSeagullStorm, Log, TEXT("Wave %d started"), CurrentWave);
}

TArray<FSeagullLevelUpChoice> ASeagullStormGameState::GetLevelUpChoices(int32 Count) const
{
	TArray<FSeagullLevelUpChoice> Result;
	if (!ConfigCacheRef || ConfigCacheRef->LevelUpPool.Num() == 0) return Result;

	// Weighted random selection
	TArray<FSeagullLevelUpChoice> Pool = ConfigCacheRef->LevelUpPool;

	// Filter out weapons already at max or already owned (for "new" weapons)
	TArray<FSeagullLevelUpChoice> FilteredPool;
	for (const FSeagullLevelUpChoice& Choice : Pool)
	{
		if (Choice.Type == TEXT("weapon_new"))
		{
			// Check if already unlocked
			ESeagullWeaponType WType = ESeagullWeaponType::Feather;
			if (Choice.Id == TEXT("screech_new")) WType = ESeagullWeaponType::Screech;
			else if (Choice.Id == TEXT("dive_new")) WType = ESeagullWeaponType::Dive;
			else if (Choice.Id == TEXT("gust_new")) WType = ESeagullWeaponType::Gust;

			if (!ActiveWeapons.Contains(WType))
			{
				if (Choice.Weight > 0) FilteredPool.Add(Choice);
			}
		}
		else
		{
			if (Choice.Weight > 0) FilteredPool.Add(Choice);
		}
	}

	if (FilteredPool.Num() == 0) return Result;

	// Calculate total weight
	int32 TotalWeight = 0;
	for (const auto& C : FilteredPool) TotalWeight += C.Weight;

	// Pick N unique choices
	TArray<int32> UsedIndices;
	for (int32 i = 0; i < Count && UsedIndices.Num() < FilteredPool.Num(); i++)
	{
		int32 Roll = FMath::RandRange(0, TotalWeight - 1);
		int32 Accumulated = 0;
		for (int32 j = 0; j < FilteredPool.Num(); j++)
		{
			if (UsedIndices.Contains(j)) continue;
			Accumulated += FilteredPool[j].Weight;
			if (Roll < Accumulated)
			{
				Result.Add(FilteredPool[j]);
				UsedIndices.Add(j);
				TotalWeight -= FilteredPool[j].Weight;
				break;
			}
		}
	}

	return Result;
}

void ASeagullStormGameState::ApplyLevelUpChoice(const FSeagullLevelUpChoice& Choice)
{
	// Get the player pawn's weapon manager to apply actual weapon changes
	ASeagullPlayerPawn* PlayerPawn = nullptr;
	USeagullWeaponManager* WM = nullptr;
	if (GetWorld())
	{
		PlayerPawn = Cast<ASeagullPlayerPawn>(UGameplayStatics::GetPlayerPawn(GetWorld(), 0));
		if (PlayerPawn)
		{
			WM = PlayerPawn->WeaponManager;
		}
	}

	if (Choice.Type == TEXT("weapon_new"))
	{
		ESeagullWeaponType WType = ESeagullWeaponType::Feather;
		if (Choice.Id == TEXT("screech_new")) WType = ESeagullWeaponType::Screech;
		else if (Choice.Id == TEXT("dive_new")) WType = ESeagullWeaponType::Dive;
		else if (Choice.Id == TEXT("gust_new")) WType = ESeagullWeaponType::Gust;

		if (!ActiveWeapons.Contains(WType))
		{
			ActiveWeapons.Add(WType);
			WeaponLevels.Add(WType, 1);

			// Actually unlock the weapon on the player's weapon manager
			if (WM)
			{
				WM->UnlockWeapon(WType);
			}
		}
	}
	else if (Choice.Type == TEXT("weapon_upgrade"))
	{
		ESeagullWeaponType WType = ESeagullWeaponType::Feather;
		if (Choice.Id.Contains(TEXT("feather"))) WType = ESeagullWeaponType::Feather;

		int32* Level = WeaponLevels.Find(WType);
		if (Level) (*Level)++;

		// Actually upgrade the weapon on the player's weapon manager
		if (WM)
		{
			WM->UpgradeWeapon(WType);

			// feather_speed: reduce cooldown by 20% (fire rate +20%)
			// Generic upgrades: Level++ handled by GetEffectiveDamage (+15% per level)
			if (Choice.Id == TEXT("feather_speed"))
			{
				USeagullWeaponBase* Weapon = WM->GetWeapon(WType);
				if (Weapon) Weapon->Cooldown *= 0.8f;
			}
		}
	}
	else if (Choice.Type == TEXT("stat_boost"))
	{
		if (PlayerPawn)
		{
			if (Choice.Id == TEXT("move_speed"))
			{
				// Increase movement speed by ~10%
				PlayerPawn->BaseSpeed *= 1.1f;
				if (PlayerPawn->MovementComponent)
				{
					PlayerPawn->MovementComponent->MaxSpeed = PlayerPawn->BaseSpeed;
				}
				UE_LOG(LogSeagullStorm, Log, TEXT("Stat boost: move_speed -> %.0f"), PlayerPawn->BaseSpeed);
			}
			else if (Choice.Id == TEXT("max_hp"))
			{
				// Increase max HP by 20 and heal to new max
				if (PlayerPawn->HealthComponent)
				{
					int32 NewMax = PlayerPawn->HealthComponent->MaxHP + 20;
					PlayerPawn->HealthComponent->SetMaxHP(NewMax);
					PlayerPawn->HealthComponent->Heal(NewMax);
					UE_LOG(LogSeagullStorm, Log, TEXT("Stat boost: max_hp -> %d"), NewMax);
				}
			}
			else if (Choice.Id == TEXT("xp_magnet"))
			{
				// Increase pickup radius by ~30%
				if (PlayerPawn->XPComponent)
				{
					PlayerPawn->XPComponent->PickupRadius *= 1.3f;
					UE_LOG(LogSeagullStorm, Log, TEXT("Stat boost: xp_magnet -> %.0f"), PlayerPawn->XPComponent->PickupRadius);
				}
			}
		}
	}
}

int32 ASeagullStormGameState::CalculateXPToNextLevel() const
{
	int32 Base = 50;
	float Curve = 1.4f;
	if (ConfigCacheRef)
	{
		Base = ConfigCacheRef->XPPerKillBase * 5; // Base XP = 50
		Curve = ConfigCacheRef->XPLevelCurve;
	}
	return FMath::Max(1, static_cast<int32>(FMath::Max(1, Base) * FMath::Pow(static_cast<float>(CurrentLevel), FMath::Clamp(Curve, 0.1f, 3.f))));
}

void ASeagullStormGameState::ResolveLevelUpChoice()
{
    PendingLevelUpChoices = FMath::Max(0, PendingLevelUpChoices - 1);
    if (bRunActive && PendingLevelUpChoices > 0) OnTriggerLevelUpChoices.Broadcast();
}
