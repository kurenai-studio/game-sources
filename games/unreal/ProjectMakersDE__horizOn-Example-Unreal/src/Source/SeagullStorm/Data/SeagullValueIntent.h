#pragma once
#include "CoreMinimal.h"
#include "GameFramework/SaveGame.h"
#include "SeagullValueIntent.generated.h"

/** One durable server operation, scoped to project and player across regional hosts. */
UCLASS()
class USeagullValueIntent : public USaveGame
{
    GENERATED_BODY()
public:
    UPROPERTY() FString ProjectHash;
    UPROPERTY() FString UserId;
    UPROPERTY() FString Kind;
    UPROPERTY() FString OfferKey;
    UPROPERTY() FString ValueKey;
    UPROPERTY() FString Reason;
    UPROPERTY() FString OperationId;
    UPROPERTY() int64 Amount = 0;
    UPROPERTY() int64 OfferDefinitionVersion = 0;
    UPROPERTY() int32 SendCount = 0;
    static FString Project(const FString& ApiKey);
    static FString Slot(const FString& ApiKey, const FString& User);
    static USeagullValueIntent* Load(const FString& ApiKey, const FString& User, bool& bBlocked);
    bool Persist(const FString& ApiKey) const;
    bool Confirm(const FString& ApiKey) const;
    bool IsValidFor(const FString& ApiKey, const FString& User) const;
    bool SamePayload(const USeagullValueIntent* Other) const;
};
