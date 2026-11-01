#pragma once
#include "CoreMinimal.h"
#include "Models/HorizonStatistics.h"
#include "SeagullStatisticsSession.generated.h"
class USeagullGameInstance;
class UHorizonSubsystem;
class USeagullStatisticsIntent;
/** One atomic batch per online round. All retry actions are explicit and retain the saved original. */
UCLASS()
class USeagullStatisticsSession : public UObject
{
    GENERATED_BODY()
public:
    void Initialize(USeagullGameInstance* Owner);
    void Refresh();
    bool CanStartOnlineRound();
    bool RecordRound(int64 Kills,int64 BestScore);
    void RetryOriginal();
    FHorizonStatisticsSnapshot Snapshot() const;
    FString GetStatus();
    bool IsBusy();
    bool HasPending();
private:
    UPROPERTY() USeagullGameInstance* Instance=nullptr;
    UPROPERTY() USeagullStatisticsIntent* Pending=nullptr;
    UPROPERTY() USeagullStatisticsIntent* InFlight=nullptr;
    FString Context,Status=TEXT("Explicitly refresh to load server statistics.");
    uint64 Generation=0;
    bool bBusy=false;
    UHorizonSubsystem* Begin();
    FString CurrentContext() const;
    void Sync();
    bool Current(const FString& Expected,uint64 Epoch) const;
    void Send(UHorizonSubsystem* SDK,USeagullStatisticsIntent* Intent);
    bool Compatible(const FHorizonStatisticsSnapshot& State) const;
};
