#pragma once

#include "CoreMinimal.h"
#include "Weapons/SeagullWeaponBase.h"
#include "SeagullWeapon_Screech.generated.h"

UCLASS()
class USeagullWeapon_Screech : public USeagullWeaponBase
{
	GENERATED_BODY()

public:
	USeagullWeapon_Screech();
	virtual void Fire() override;

	float Radius = 80.f;
};
