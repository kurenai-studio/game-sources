#include "Weapons/SeagullWeaponBase.h"
#include "Player/SeagullPlayerPawn.h"

USeagullWeaponBase::USeagullWeaponBase()
{
	PrimaryComponentTick.bCanEverTick = true;
}

void USeagullWeaponBase::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	if (!bUnlocked) return;

	CooldownTimer -= DeltaTime;
	if (CooldownTimer <= 0.f)
	{
		Fire();
		if (ASeagullPlayerPawn* Player = Cast<ASeagullPlayerPawn>(GetOwner())) Player->PlayAttackPose();
		CooldownTimer = Cooldown;
	}
}

void USeagullWeaponBase::SetStats(float InDamage, float InCooldown)
{
	Damage = InDamage;
	Cooldown = InCooldown;
}
