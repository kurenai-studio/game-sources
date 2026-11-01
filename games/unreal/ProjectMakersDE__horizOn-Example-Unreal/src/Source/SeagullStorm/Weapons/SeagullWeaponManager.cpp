#include "Weapons/SeagullWeaponManager.h"
#include "Weapons/SeagullWeapon_Feather.h"
#include "Weapons/SeagullWeapon_Screech.h"
#include "Weapons/SeagullWeapon_Dive.h"
#include "Weapons/SeagullWeapon_Gust.h"
#include "Data/SeagullConfigCache.h"
#include "SeagullStorm.h"

USeagullWeaponManager::USeagullWeaponManager()
{
	PrimaryComponentTick.bCanEverTick = false;
}

void USeagullWeaponManager::BeginPlay()
{
	Super::BeginPlay();

	AActor* Owner = GetOwner();
	if (!Owner) return;

	// Create all weapon components (only feather starts unlocked)
	FeatherWeapon = NewObject<USeagullWeapon_Feather>(Owner);
	FeatherWeapon->RegisterComponent();
	FeatherWeapon->Unlock();

	ScreechWeapon = NewObject<USeagullWeapon_Screech>(Owner);
	ScreechWeapon->RegisterComponent();

	DiveWeapon = NewObject<USeagullWeapon_Dive>(Owner);
	DiveWeapon->RegisterComponent();

	GustWeapon = NewObject<USeagullWeapon_Gust>(Owner);
	GustWeapon->RegisterComponent();

	UpdateDamageMultipliers();
}

void USeagullWeaponManager::UnlockWeapon(ESeagullWeaponType Type)
{
	USeagullWeaponBase* Weapon = GetWeapon(Type);
	if (Weapon)
	{
		Weapon->Unlock();

		// Apply config stats so mid-run unlocks use Remote Config values
		if (ConfigCacheRef)
		{
			switch (Type)
			{
				case ESeagullWeaponType::Feather:
				{
					Weapon->SetStats(ConfigCacheRef->FeatherStats.Damage, ConfigCacheRef->FeatherStats.Cooldown);
					USeagullWeapon_Feather* F = Cast<USeagullWeapon_Feather>(Weapon);
					if (F) F->ProjectileCount = ConfigCacheRef->FeatherStats.Projectiles;
					break;
				}
				case ESeagullWeaponType::Screech:
				{
					Weapon->SetStats(ConfigCacheRef->ScreechStats.Damage, ConfigCacheRef->ScreechStats.Cooldown);
					USeagullWeapon_Screech* S = Cast<USeagullWeapon_Screech>(Weapon);
					if (S) S->Radius = ConfigCacheRef->ScreechStats.Range;
					break;
				}
				case ESeagullWeaponType::Dive:
				{
					Weapon->SetStats(ConfigCacheRef->DiveStats.Damage, ConfigCacheRef->DiveStats.Cooldown);
					USeagullWeapon_Dive* D = Cast<USeagullWeapon_Dive>(Weapon);
					if (D) D->Range = ConfigCacheRef->DiveStats.Range;
					break;
				}
				case ESeagullWeaponType::Gust:
				{
					Weapon->SetStats(ConfigCacheRef->GustStats.Damage, ConfigCacheRef->GustStats.Cooldown);
					USeagullWeapon_Gust* G = Cast<USeagullWeapon_Gust>(Weapon);
					if (G) G->KnockbackForce = ConfigCacheRef->GustStats.Knockback;
					break;
				}
			}
		}

		// Apply damage multiplier to newly unlocked weapon
		Weapon->DamageMultiplier = DamageMultiplier;
	}
}

void USeagullWeaponManager::UpgradeWeapon(ESeagullWeaponType Type)
{
	USeagullWeaponBase* Weapon = GetWeapon(Type);
	if (Weapon)
	{
		Weapon->Level++;
	}
}

USeagullWeaponBase* USeagullWeaponManager::GetWeapon(ESeagullWeaponType Type) const
{
	switch (Type)
	{
		case ESeagullWeaponType::Feather: return FeatherWeapon;
		case ESeagullWeaponType::Screech: return ScreechWeapon;
		case ESeagullWeaponType::Dive: return DiveWeapon;
		case ESeagullWeaponType::Gust: return GustWeapon;
	}
	return nullptr;
}

void USeagullWeaponManager::UpdateDamageMultipliers()
{
	if (FeatherWeapon) FeatherWeapon->DamageMultiplier = DamageMultiplier;
	if (ScreechWeapon) ScreechWeapon->DamageMultiplier = DamageMultiplier;
	if (DiveWeapon) DiveWeapon->DamageMultiplier = DamageMultiplier;
	if (GustWeapon) GustWeapon->DamageMultiplier = DamageMultiplier;
}
