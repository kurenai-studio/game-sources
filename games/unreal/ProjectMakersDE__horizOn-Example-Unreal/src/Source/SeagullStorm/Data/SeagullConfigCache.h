#pragma once

#include "CoreMinimal.h"
#include "Core/SeagullTypes.h"
#include "SeagullConfigCache.generated.h"

UCLASS()
class USeagullConfigCache : public UObject
{
	GENERATED_BODY()

public:
	void ParseFromConfigs(const TMap<FString, FString>& Configs);

	// Gameplay
	int32 RunDurationSeconds = 180;
	bool bBossWaveEnabled = true;
	int32 CoinDivisor = 10;
	int32 XPPerKillBase = 10;
	float XPLevelCurve = 1.4f;

	// Validated Actions (only used when built with HORIZON_WITH_VALIDATED_ACTIONS=1)
	bool bValidatedActionsEnabled = true;
	FString ValidatedCoinsKey;
	FString ValidatedRunsBoard = TEXT("default");

	// Wave System
	float WaveIntervalSeconds = 15.f;
	int32 WaveEnemyCountBase = 5;
	float WaveEnemyCountGrowth = 1.3f;
	int32 WaveBossHP = 500;

	// Enemy Stats
	FSeagullEnemyStats CrabStats;
	FSeagullEnemyStats JellyfishStats;
	FSeagullEnemyStats PirateStats;

	// Weapon Stats
	FSeagullWeaponStats FeatherStats;
	FSeagullWeaponStats ScreechStats;
	FSeagullWeaponStats DiveStats;
	FSeagullWeaponStats GustStats;

	// Hub Upgrades
	TArray<int32> UpgradeSpeedCosts;
	TArray<float> UpgradeSpeedValues;
	int32 UpgradeSpeedMax = 4;

	TArray<int32> UpgradeDamageCosts;
	TArray<float> UpgradeDamageValues;
	int32 UpgradeDamageMax = 4;

	TArray<int32> UpgradeHPCosts;
	TArray<int32> UpgradeHPValues;
	int32 UpgradeHPMax = 3;

	TArray<int32> UpgradeMagnetCosts;
	TArray<float> UpgradeMagnetValues;
	int32 UpgradeMagnetMax = 2;

	// Levelup
	int32 LevelUpChoices = 3;
	TArray<FSeagullLevelUpChoice> LevelUpPool;

	// Helpers
	int32 GetUpgradeCost(const FString& UpgradeKey, int32 CurrentLevel) const;
	float GetUpgradeValue(const FString& UpgradeKey, int32 Level) const;
	int32 GetUpgradeMax(const FString& UpgradeKey) const;

private:
	int32 ParseInt(const TMap<FString, FString>& Configs, const FString& Key, int32 Default) const;
	float ParseFloat(const TMap<FString, FString>& Configs, const FString& Key, float Default) const;
	bool ParseBool(const TMap<FString, FString>& Configs, const FString& Key, bool Default) const;
	TArray<int32> ParseIntArray(const FString& Value) const;
	TArray<float> ParseFloatArray(const FString& Value) const;
	void ParseLevelUpPool(const FString& Value);
};
