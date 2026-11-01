#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "Core/SeagullTypes.h"
#include "SeagullWeaponManager.generated.h"

class USeagullWeaponBase;
class USeagullWeapon_Feather;
class USeagullWeapon_Screech;
class USeagullWeapon_Dive;
class USeagullWeapon_Gust;
class USeagullConfigCache;

UCLASS()
class USeagullWeaponManager : public UActorComponent
{
	GENERATED_BODY()

public:
	USeagullWeaponManager();

	virtual void BeginPlay() override;

	void UnlockWeapon(ESeagullWeaponType Type);
	void UpgradeWeapon(ESeagullWeaponType Type);
	USeagullWeaponBase* GetWeapon(ESeagullWeaponType Type) const;

	float DamageMultiplier = 1.0f;

	void UpdateDamageMultipliers();

	// Config reference for applying stats to weapons unlocked mid-run
	UPROPERTY()
	USeagullConfigCache* ConfigCacheRef = nullptr;

private:
	UPROPERTY()
	USeagullWeapon_Feather* FeatherWeapon = nullptr;

	UPROPERTY()
	USeagullWeapon_Screech* ScreechWeapon = nullptr;

	UPROPERTY()
	USeagullWeapon_Dive* DiveWeapon = nullptr;

	UPROPERTY()
	USeagullWeapon_Gust* GustWeapon = nullptr;
};
