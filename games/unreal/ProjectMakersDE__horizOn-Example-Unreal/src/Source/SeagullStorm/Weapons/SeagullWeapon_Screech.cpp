#include "Weapons/SeagullWeapon_Screech.h"
#include "Enemies/SeagullEnemyBase.h"
#include "Core/SeagullStormGameMode.h"
#include "Audio/SeagullAudioManager.h"
#include "EngineUtils.h"
#include "SeagullStorm.h"

USeagullWeapon_Screech::USeagullWeapon_Screech()
{
	WeaponType = ESeagullWeaponType::Screech;
	Damage = 15.f;
	Cooldown = 2.0f;
}

void USeagullWeapon_Screech::Fire()
{
	AActor* Owner = GetOwner();
	if (!Owner) return;

	UWorld* World = GetWorld();
	if (!World) return;

	FVector Center = Owner->GetActorLocation();
	float RadiusSq = Radius * Radius;

	// Damage all enemies within radius
	for (TActorIterator<ASeagullEnemyBase> It(World); It; ++It)
	{
		ASeagullEnemyBase* Enemy = *It;
		if (!Enemy || Enemy->IsDead()) continue;

		float DistSq = FVector::DistSquared(Center, Enemy->GetActorLocation());
		if (DistSq <= RadiusSq)
		{
			Enemy->TakeDamageAmount(static_cast<int32>(GetEffectiveDamage()));
		}
	}

	// Play SFX
	ASeagullStormGameMode* GM = Cast<ASeagullStormGameMode>(World->GetAuthGameMode());
	if (GM && GM->AudioManager && GM->AudioManager->SFX_Screech)
	{
		GM->AudioManager->PlaySFX(GM->AudioManager->SFX_Screech, World);
	}
}
