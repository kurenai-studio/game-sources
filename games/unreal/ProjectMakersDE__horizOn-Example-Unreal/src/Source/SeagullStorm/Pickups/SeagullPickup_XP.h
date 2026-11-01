#pragma once

#include "CoreMinimal.h"
#include "Pickups/SeagullPickup.h"
#include "SeagullPickup_XP.generated.h"

UCLASS()
class ASeagullPickup_XP : public ASeagullPickup
{
	GENERATED_BODY()

public:
	ASeagullPickup_XP();

	virtual void Tick(float DeltaTime) override;
	virtual void OnPickedUp(ASeagullPlayerPawn* Player) override;

	int32 XPAmount = 10;
};
