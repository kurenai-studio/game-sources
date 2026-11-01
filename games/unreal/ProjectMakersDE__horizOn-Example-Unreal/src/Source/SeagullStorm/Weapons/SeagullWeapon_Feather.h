#pragma once

#include "CoreMinimal.h"
#include "Weapons/SeagullWeaponBase.h"
#include "SeagullWeapon_Feather.generated.h"

UCLASS()
class USeagullWeapon_Feather : public USeagullWeaponBase
{
	GENERATED_BODY()

public:
	USeagullWeapon_Feather();
	virtual void Fire() override;

	int32 ProjectileCount = 1;
};
