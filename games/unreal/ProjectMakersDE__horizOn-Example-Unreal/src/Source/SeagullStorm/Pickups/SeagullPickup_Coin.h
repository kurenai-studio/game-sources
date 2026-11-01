#pragma once

#include "CoreMinimal.h"
#include "Pickups/SeagullPickup.h"
#include "SeagullPickup_Coin.generated.h"

UCLASS()
class ASeagullPickup_Coin : public ASeagullPickup
{
	GENERATED_BODY()

public:
	ASeagullPickup_Coin();

	virtual void OnPickedUp(ASeagullPlayerPawn* Player) override;
};
