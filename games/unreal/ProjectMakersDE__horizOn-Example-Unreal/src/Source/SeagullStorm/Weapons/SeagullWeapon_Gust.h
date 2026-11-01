#pragma once

#include "CoreMinimal.h"
#include "Weapons/SeagullWeaponBase.h"
#include "SeagullWeapon_Gust.generated.h"

UCLASS()
class USeagullWeapon_Gust : public USeagullWeaponBase
{
	GENERATED_BODY()

public:
	USeagullWeapon_Gust();
	virtual void Fire() override;

	float KnockbackForce = 60.f;
	float EffectRadius = 100.f;
};
