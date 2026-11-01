#pragma once
#include "CoreMinimal.h"
#include "GameFramework/SaveGame.h"
#include "Models/HorizonStatistics.h"
#include "SeagullStatisticsIntent.generated.h"
/** Immutable original online-round batch. No regional host is part of durable identity. */
UCLASS()
class USeagullStatisticsIntent : public USaveGame
{
    GENERATED_BODY()
public:
    UPROPERTY() FString ProjectHash;
    UPROPERTY() FString UserId;
    UPROPERTY() FString OperationId;
    UPROPERTY() FString LocalIntentId;
    UPROPERTY() TArray<FHorizonStatisticUpdate> Updates;
    static FString Slot(const FString& ApiKey,const FString& UserId);
    static USeagullStatisticsIntent* Load(const FString& ApiKey,const FString& UserId,bool& Blocked);
    bool IsValidFor(const FString& ApiKey,const FString& User) const;
    bool SamePayload(const USeagullStatisticsIntent* Other) const;
    bool Persist(const FString& ApiKey) const;
    bool Finalize(const FString& ApiKey,const FString& NewOperationId);
    bool Confirm(const FString& ApiKey) const;
};
