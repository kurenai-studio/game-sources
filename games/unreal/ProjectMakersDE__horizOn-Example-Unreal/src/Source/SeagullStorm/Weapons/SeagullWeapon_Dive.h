#pragma once

#include "CoreMinimal.h"
#include "Weapons/SeagullWeaponBase.h"
#include "SeagullWeapon_Dive.generated.h"

UCLASS()
class USeagullWeapon_Dive : public USeagullWeaponBase
{
	GENERATED_BODY()

public:
	USeagullWeapon_Dive();
	virtual void Fire() override;

	float Range = 120.f;
};
