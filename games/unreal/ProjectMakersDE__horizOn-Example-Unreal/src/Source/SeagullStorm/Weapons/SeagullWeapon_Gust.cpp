#include "Weapons/SeagullWeapon_Gust.h"
#include "Enemies/SeagullEnemyBase.h"
#include "Core/SeagullStormGameMode.h"
#include "Audio/SeagullAudioManager.h"
#include "EngineUtils.h"
#include "SeagullStorm.h"

USeagullWeapon_Gust::USeagullWeapon_Gust()
{
	WeaponType = ESeagullWeaponType::Gust;
	Damage = 10.f;
	Cooldown = 2.5f;
}

void USeagullWeapon_Gust::Fire()
{
	AActor* Owner = GetOwner();
	if (!Owner) return;

	UWorld* World = GetWorld();
	if (!World) return;

	FVector Center = Owner->GetActorLocation();
	float RadiusSq = EffectRadius * EffectRadius;

	for (TActorIterator<ASeagullEnemyBase> It(World); It; ++It)
	{
		ASeagullEnemyBase* Enemy = *It;
		if (!Enemy || Enemy->IsDead()) continue;

		FVector EnemyPos = Enemy->GetActorLocation();
		float DistSq = FVector::DistSquared(Center, EnemyPos);

		if (DistSq <= RadiusSq)
		{
			// Damage
			Enemy->TakeDamageAmount(static_cast<int32>(GetEffectiveDamage()));

			// Knockback
			FVector KBDir = (EnemyPos - Center).GetSafeNormal();
			Enemy->SetActorLocation(EnemyPos + KBDir * KnockbackForce);
		}
	}

	// Play SFX
	ASeagullStormGameMode* GM = Cast<ASeagullStormGameMode>(World->GetAuthGameMode());
	if (GM && GM->AudioManager && GM->AudioManager->SFX_Gust)
	{
		GM->AudioManager->PlaySFX(GM->AudioManager->SFX_Gust, World);
	}
}
