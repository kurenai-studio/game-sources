#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameStateBase.h"
#include "Core/SeagullTypes.h"
#include "SeagullStormGameState.generated.h"

class USeagullConfigCache;

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnRunTimerExpired);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnWaveChanged, int32, NewWave);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnScoreChanged, int32, NewScore);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnLevelUp, int32, NewLevel);
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnTriggerLevelUpChoices);

UCLASS()
class ASeagullStormGameState : public AGameStateBase
{
	GENERATED_BODY()

public:
	void InitRun(USeagullConfigCache* Config);
	void TickTimer(float DeltaTime);

	void AddScore(int32 Amount);
	void AddKill();
	void AddXP(int32 Amount);
	void AdvanceWave();

	bool IsTimerExpired() const { return TimeRemaining <= 0.f; }

	TArray<FSeagullLevelUpChoice> GetLevelUpChoices(int32 Count) const;
	void ApplyLevelUpChoice(const FSeagullLevelUpChoice& Choice);
	void ResolveLevelUpChoice();
	int32 PendingLevelUpChoices = 0;

	// Run state
	UPROPERTY()
	int32 CurrentWave = 0;

	UPROPERTY()
	int32 CurrentScore = 0;

	UPROPERTY()
	int32 CurrentLevel = 1;

	UPROPERTY()
	float TimeRemaining = 180.f;

	UPROPERTY()
	int32 KillCount = 0;

	UPROPERTY()
	int32 TotalXPCollected = 0;

	UPROPERTY()
	int32 CurrentXP = 0;

	UPROPERTY()
	int32 XPToNextLevel = 50;

	UPROPERTY()
	FSeagullRunStats RunStats;

	bool bBossSpawned = false;
	bool bRunActive = false;

	// Active weapons tracking
	TArray<ESeagullWeaponType> ActiveWeapons;
	TMap<ESeagullWeaponType, int32> WeaponLevels;

	// Events
	UPROPERTY(BlueprintAssignable)
	FOnRunTimerExpired OnTimerExpired;

	UPROPERTY(BlueprintAssignable)
	FOnWaveChanged OnWaveChanged;

	UPROPERTY(BlueprintAssignable)
	FOnScoreChanged OnScoreChanged;

	UPROPERTY(BlueprintAssignable)
	FOnLevelUp OnLevelUp;

	UPROPERTY(BlueprintAssignable)
	FOnTriggerLevelUpChoices OnTriggerLevelUpChoices;

private:
	UPROPERTY()
	USeagullConfigCache* ConfigCacheRef = nullptr;

	float RunStartTime = 0.f;

	int32 CalculateXPToNextLevel() const;
};
