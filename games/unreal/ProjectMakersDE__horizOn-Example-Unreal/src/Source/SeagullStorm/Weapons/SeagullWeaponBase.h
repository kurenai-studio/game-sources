#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "Core/SeagullTypes.h"
#include "SeagullWeaponBase.generated.h"

UCLASS(Abstract)
class USeagullWeaponBase : public UActorComponent
{
	GENERATED_BODY()

public:
	USeagullWeaponBase();

	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

	virtual void Fire() PURE_VIRTUAL(USeagullWeaponBase::Fire, );

	void SetStats(float InDamage, float InCooldown);
	void Unlock() { bUnlocked = true; }
	bool IsUnlocked() const { return bUnlocked; }

	ESeagullWeaponType WeaponType = ESeagullWeaponType::Feather;
	float Damage = 20.f;
	float Cooldown = 0.8f;
	int32 Level = 1;
	float DamageMultiplier = 1.0f;

protected:
	bool bUnlocked = false;
	float CooldownTimer = 0.f;

	float GetEffectiveDamage() const { return Damage * DamageMultiplier * (1.0f + (Level - 1) * 0.15f); }
};
