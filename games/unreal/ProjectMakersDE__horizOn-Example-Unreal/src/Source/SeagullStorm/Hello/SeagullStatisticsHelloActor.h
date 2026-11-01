#pragma once
#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "SeagullStatisticsHelloActor.generated.h"
class USeagullStatisticsPanel;
/** Standalone Hello variant; add to a base GameMode level. No saved batch is posted on startup. */
UCLASS()
class ASeagullStatisticsHelloActor : public AActor
{
    GENERATED_BODY()
public:
    virtual void BeginPlay() override;
private:
    UPROPERTY() USeagullStatisticsPanel* Panel=nullptr;
    bool bAuthStarted=false;
    UFUNCTION() void Connected();
    void Authenticated(bool Success,bool Restored);
};
