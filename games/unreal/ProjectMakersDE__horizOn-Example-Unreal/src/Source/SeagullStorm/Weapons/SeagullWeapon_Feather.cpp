#include "Weapons/SeagullWeapon_Feather.h"
#include "Weapons/SeagullProjectile.h"
#include "Player/SeagullPlayerPawn.h"
#include "Core/SeagullStormGameMode.h"
#include "Audio/SeagullAudioManager.h"
#include "SeagullStorm.h"
#include "Enemies/SeagullEnemyBase.h"
#include "EngineUtils.h"

USeagullWeapon_Feather::USeagullWeapon_Feather()
{
	WeaponType = ESeagullWeaponType::Feather;
	Damage = 20.f;
	Cooldown = 0.8f;
}

void USeagullWeapon_Feather::Fire()
{
	AActor* Owner = GetOwner();
	if (!Owner) return;

	ASeagullPlayerPawn* Player = Cast<ASeagullPlayerPawn>(Owner);
	if (!Player) return;

	UWorld* World = GetWorld();
	if (!World) return;

	FVector SpawnLoc = Owner->GetActorLocation();
	FVector2D Dir = Player->LastMoveDirection;
    float NearestDistance = FMath::Square(420.f);
    for (TActorIterator<ASeagullEnemyBase> It(World); It; ++It)
    {
        if (It->IsDead()) continue;
        const FVector ToEnemy = It->GetActorLocation() - SpawnLoc;
        const float Distance = ToEnemy.SizeSquared();
        if (Distance < NearestDistance)
        {
            NearestDistance = Distance;
            Dir = FVector2D(ToEnemy.X, ToEnemy.Y).GetSafeNormal();
        }
    }

	for (int32 i = 0; i < ProjectileCount; i++)
	{
		// Spread projectiles slightly if multiple
		float AngleOffset = 0.f;
		if (ProjectileCount > 1)
		{
			AngleOffset = (i - (ProjectileCount - 1) * 0.5f) * 10.f;
		}

		float BaseAngle = FMath::Atan2(Dir.Y, Dir.X);
		float FinalAngle = BaseAngle + FMath::DegreesToRadians(AngleOffset);
		FVector Direction(FMath::Cos(FinalAngle), FMath::Sin(FinalAngle), 0.f);

		FActorSpawnParameters Params;
		Params.Owner = Owner;
		Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

		ASeagullProjectile* Proj = World->SpawnActor<ASeagullProjectile>(ASeagullProjectile::StaticClass(), SpawnLoc, Direction.Rotation(), Params);
		if (Proj)
		{
			Proj->InitProjectile(Direction, GetEffectiveDamage(), 600.f);
		}
	}

	// Play SFX
	ASeagullStormGameMode* GM = Cast<ASeagullStormGameMode>(World->GetAuthGameMode());
	if (GM && GM->AudioManager && GM->AudioManager->SFX_Feather)
	{
		GM->AudioManager->PlaySFX(GM->AudioManager->SFX_Feather, World);
	}
}
