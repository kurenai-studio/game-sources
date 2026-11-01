#pragma once
#include "CoreMinimal.h"
#include "Pickups/SeagullPickup.h"
#include "SeagullPickup_Health.generated.h"

UCLASS()
class ASeagullPickup_Health : public ASeagullPickup
{
    GENERATED_BODY()
public:
    ASeagullPickup_Health();
    virtual void OnPickedUp(ASeagullPlayerPawn* Player) override;
};
