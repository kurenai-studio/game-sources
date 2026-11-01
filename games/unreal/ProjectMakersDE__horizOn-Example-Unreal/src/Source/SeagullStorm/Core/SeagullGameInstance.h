#pragma once

#include "CoreMinimal.h"
#include "Engine/GameInstance.h"
#include "Data/SeagullSaveData.h"
#include "Models/HorizonNewsEntry.h"
#include "SeagullGameInstance.generated.h"

class USeagullConfigCache;
class USeagullHorizonManager;
class UHorizonSubsystem;
class USeagullStatisticsSession;

UCLASS()
class USeagullGameInstance : public UGameInstance
{
	GENERATED_BODY()

public:
	virtual void Init() override;

	UHorizonSubsystem* GetHorizonSubsystem() const;
	USeagullHorizonManager* GetHorizonManager();
	USeagullConfigCache* GetConfigCache();
    USeagullStatisticsSession* GetStatisticsSession();

	UPROPERTY()
	FSeagullSaveData SaveData;

	bool bConfigLoaded = false;
	bool bSaveLoaded = false;
	bool bCloudSaveReady = false;
	bool bPracticeMode = false;
	FString SaveOwnerId;
	uint64 SessionGeneration = 0;

	void BeginPractice();
	void BeginOnlineSession(bool bKnownNewPlayer = false);
	void PersistPracticeSave();
	bool CanMutateProgress();

	bool bNewsLoaded = false;
	TArray<FHorizonNewsEntry> CachedNews;

	// Track consecutive wave-1 deaths for warn log
	int32 ConsecutiveWave1Deaths = 0;

private:
    UPROPERTY() USeagullStatisticsSession* StatisticsSession=nullptr;
	UPROPERTY()
	USeagullHorizonManager* HorizonManager = nullptr;

	UPROPERTY()
	USeagullConfigCache* ConfigCache = nullptr;
};
