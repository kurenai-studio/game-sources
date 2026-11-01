#include "Weapons/SeagullWeapon_Dive.h"
#include "Player/SeagullPlayerPawn.h"
#include "Player/SeagullHealthComponent.h"
#include "Enemies/SeagullEnemyBase.h"
#include "Core/SeagullStormGameMode.h"
#include "Audio/SeagullAudioManager.h"
#include "EngineUtils.h"
#include "SeagullStorm.h"

USeagullWeapon_Dive::USeagullWeapon_Dive()
{
	WeaponType = ESeagullWeaponType::Dive;
	Damage = 50.f;
	Cooldown = 3.0f;
}

void USeagullWeapon_Dive::Fire()
{
	ASeagullPlayerPawn* Player = Cast<ASeagullPlayerPawn>(GetOwner());
	if (!Player) return;

	UWorld* World = GetWorld();
	if (!World) return;

	FVector Start = Player->GetActorLocation();
	FVector2D Dir = Player->LastMoveDirection;
	FVector DashDir(Dir.X, Dir.Y, 0.f);
	DashDir.Normalize();

	FVector End = Start + DashDir * Range;

	// Damage enemies along the dash path
	for (TActorIterator<ASeagullEnemyBase> It(World); It; ++It)
	{
		ASeagullEnemyBase* Enemy = *It;
		if (!Enemy || Enemy->IsDead()) continue;

		FVector EnemyPos = Enemy->GetActorLocation();
		FVector ClosestPoint = FMath::ClosestPointOnSegment(EnemyPos, Start, End);
		float Dist = FVector::Dist(EnemyPos, ClosestPoint);

		if (Dist < 40.f) // Hit width
		{
			Enemy->TakeDamageAmount(static_cast<int32>(GetEffectiveDamage()));
		}
	}

	// Teleport player to end position
	Player->SetActorLocation(End);

	// Play SFX
	ASeagullStormGameMode* GM = Cast<ASeagullStormGameMode>(World->GetAuthGameMode());
	if (GM && GM->AudioManager && GM->AudioManager->SFX_Dive)
	{
		GM->AudioManager->PlaySFX(GM->AudioManager->SFX_Dive, World);
	}
}
